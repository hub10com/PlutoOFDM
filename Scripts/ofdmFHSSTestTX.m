clc; clear;

addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Config\");
addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Classes");

% --- Parametreler ---
params = getParams();

% --- Nesneler ---
preambleBuilder   = OFDMPreambleBuilder(params);
frameDataBuilder  = FrameDataBuilder(params);
modulationMapper  = ModulationMapper(params);
ofdmFrameGen      = OFDMFrameGenerator(params, frameDataBuilder, modulationMapper);

% --- Frekans listesi (GHz) ---
freqListGHz = [2.404, 2.416];

disp("🚀 FHSS yayın başlatıldı (transmitRepeat)... CTRL+C ile durdurabilirsin.");

while true
    for fGHz = freqListGHz
        
        % Pluto TX objesini baştan oluştur
        txObj = OFDMPlutoTX(params);
        txObj.tx.CenterFrequency = fGHz * 1e9;
        
        % Frame üret
        txFrame = ofdmFrameGen.generateOFDMFrame(preambleBuilder);
        
        % transmitRepeat başlat
        txObj.startTransmission(txFrame);
        
        % Bilgi mesajı
        fprintf('📡 TX CF: %.3f GHz — 1 saniye yayında...\n', fGHz);
        
        % 1 saniye bekle (yayında kalsın)
        pause(1.0);
        
        % Pluto TX release (en güvenli yol)
        txObj.release();
    end
end
