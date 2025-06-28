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

%% Frame bazlı analiz (grafiksiz)
totalBitErrors = 0;
berHistory = zeros(1, length(rxFrames));

for i = 1:length(rxFrames)
    rxFrame = rxFrames{i};
    rxBitsFrame    = rxBits{i};
    
    % CFO hesapla
    [~, estCFO_Hz] = rxProc.syncFunc.cfoEst(rxFrame);
    
    % BER hesapla
    N = min(length(rxBitsFrame), length(txBits));
    bitErrors = sum( rxBitsFrame(1:N) ~= txBits(1:N) );
    berValue = bitErrors / N;
    
    % Toplam hata biriktir
    totalBitErrors = totalBitErrors + bitErrors;
    berHistory(i) = berValue;
    
    % Konsola yazdır
    fprintf('📊 Frame %4d — BER: %.6f   BitError: %d   CFO: %.2f Hz\n', ...
        i, berValue, bitErrors, estCFO_Hz);
end

%% SONUÇ
fprintf('\n==== SONUÇ ====\n');
fprintf('Toplam tespit edilen frame (Schmidl & Cox): %d\n', totalDetectedFrames);
fprintf('İşlenen geçerli frame sayısı: %d\n', length(rxFrames));
fprintf('Toplam Bit Error: %d\n', totalBitErrors);
fprintf('Ortalama BER: %.6f\n', mean(berHistory));
