clc; clear; close all;

%% Klasörleri Ekle (Varsa)
addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Config\");
addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Classes\");

%% Parametreleri Yükle
params = getParams();

% Analiz için temel parametre ayarları
params.SamplesPerFrame    = 4096;          % Her frame kaç örnek alınıyor
params.BasebandSampleRate = 20e6;           % Örnekleme hızı (Hz)
params.CenterFrequency    = 2.410e9;       % Merkezi frekans (Hz)
params.RxGain             = 50;            % Alıcı kazancı (dB)

%% Pluto RX Nesnesi
plutoRX = OFDMPlutoRX(params);

%% Scope Manager Nesnesi
scopeManager = OFDMScopeManager(params);

%% Canlı Alım Döngüsü
disp('🚀 Canlı spektrum analizi başlatıldı. CTRL+C ile durdurabilirsiniz.');

while true
    % Pluto'dan bir frame al
    rxFrame = plutoRX.receiveOneFrame();
    
    % Spectrum'u güncelle
    scopeManager.plotSpectrum(rxFrame);
    
    % (İsteğe bağlı) Döngüyü biraz yavaşlatmak için küçük bekleme
    pause(0.05);  % 50 ms bekle (Hz güncelleme hızını kontrol etmek için)
end
