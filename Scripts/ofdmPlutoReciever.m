clc; clear; close all;

addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Config\");
addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Classes");

%% Parametreler
params = getParams();
    
%% Nesneleri oluştur
preambleBuilder   = OFDMPreambleBuilder(params);
frameDataBuilder  = FrameDataBuilder(params);
modMapper         = ModulationMapper(params);
rxProc            = OFDMRXProcessor(params, preambleBuilder);
plutoRX           = OFDMPlutoRX(params);
scopeManager      = OFDMScopeManager(params);

%% Pluto RX
rxBuffer = plutoRX.receiveFrames();
plutoRX.release();

%% LLTF frekans domain referansı
lltf_time = preambleBuilder.generateLLTF();
lltf_freq = fft(lltf_time);
knownLLTF = zeros(64,1);
knownLLTF(7:59) = preambleBuilder.generateLLTFFreq();

%% TX tarafı referans
txBits      = frameDataBuilder.generatePayloadBits();
knownPilots = frameDataBuilder.generatePilotSymbols(params.TotalSymbols);

%% RX İşleme
[rxFrames, rxBits, rxSymbols, totalDetectedFrames] = rxProc.process(rxBuffer, knownLLTF, knownPilots, params.PilotCarrierIndices, modMapper);

%% Frame bazlı analiz ve çizimler
for i = 1:length(rxFrames)
    rxFrame = rxFrames{i};
    rxBitsFrame    = rxBits{i};
    rxSymbolsFrame = rxSymbols{i};
    
    % CFO hesapla
    [~, estCFO_Hz] = rxProc.syncFunc.cfoEst(rxFrame);
    scopeManager.updateCFOEstimate(i, estCFO_Hz);
    
    % Kanal tahmin MSE (aktif data carriers)
    H_est = rxProc.syncFunc.chanEst(rxFrame, knownLLTF);
    
    % Aktif data carrier indices (DC null + pilots + guard çıkarılıyor)
    dataCarrierIndices = setdiff(1:params.FFTLength, [1:6, 60:64, 33, params.PilotCarrierIndices.']);
    
    H_est_active = H_est(dataCarrierIndices);
    
    mseValue = mean( abs(H_est_active - 1).^2 + eps );
    
    scopeManager.updateChannelMSE(i, mseValue);
    
    % BER hesapla
    N = min(length(rxBitsFrame), length(txBits));
    bitErrors = sum( rxBitsFrame(1:N) ~= txBits(1:N) );
    berValue = bitErrors / N;
    
    fprintf('📊 Frame %4d — BER: %.4f   CFO: %.2f Hz   Chan MSE: %.4e\n', ...
        i, berValue, estCFO_Hz, mseValue);
    
    scopeManager.updateBER(i, berValue);
    
    % Her 10 frame'de constellation çiz
    if mod(i,10) == 0
        scopeManager.plotConstellation(rxSymbolsFrame);
    end
end

%% SONUÇ
fprintf('\n==== SONUÇ ====\n');
fprintf('Toplam tespit edilen frame (Schmidl & Cox): %d\n', totalDetectedFrames);
fprintf('İşlenen geçerli frame sayısı: %d\n', length(rxFrames));
fprintf('Ortalama BER: %.6f\n', mean(scopeManager.berHistory));
