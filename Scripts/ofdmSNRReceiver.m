%% ofdmSNRReceiver.m
clc; clear;

addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Config\");
addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Classes\");
addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Utils\");

%% Parametreler
params = getParams();

% SNR ölçüm için özel ayarlar
params.SamplesPerFrame = 4096;

%% RX Nesnesi
plutoRX = OFDMPlutoRX(params);

%% RX loop başlat
fs = params.BasebandSampleRate;
durationSeconds = 5;

frameTime = params.SamplesPerFrame / fs;
numFrames = ceil(durationSeconds / frameTime);
powerVec = zeros(1, numFrames);

disp("🚀 5 saniyelik RX başlatıldı...");

for i = 1:numFrames
    y = plutoRX.receiveOneFrame();
    
    Y = fftshift(fft(y) / params.SamplesPerFrame);
    P = abs(Y).^2;
    
    avgPwrWatt = max(mean(P), 1e-15);
    P_dBm = 10 * log10(avgPwrWatt) + 30;

    powerVec(i) = P_dBm;
    
    fprintf('📡 Frame %4d — Güç: %.2f dBm\n', i, P_dBm);
end

%% Donanımı bırak
plutoRX.release();
disp('✅ RX tamamlandı.');

%% GMM ile SNR hesapla
mu_sorted = fitGMMtoPowerVecSNR(powerVec);

P_noise_dBm  = mu_sorted(1);
P_signal_dBm = mu_sorted(2);

snr_dB = P_signal_dBm - P_noise_dBm;

fprintf("\n🎯 GMM SNR Hesaplandı:\n");
fprintf("  Ortam Gücü (Noise): %.2f dBm\n", P_noise_dBm);
fprintf("  Sinyal Gücü      : %.2f dBm\n", P_signal_dBm);
fprintf("  SNR              : %.2f dB\n", snr_dB);

