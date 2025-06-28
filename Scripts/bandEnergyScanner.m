%% spectrumScanner.m
clc; clear;

addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Config\");
addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Classes\");

%% Parametreler
params = getParams();

params.BasebandSampleRate = 4e6;  % 4 MHz
params.SamplesPerFrame    = 4096; % 4096 örnek

%% Pluto RX nesnesi
plutoRX = OFDMPlutoRX(params);

%% Band planı (MHz cinsinden)
bandEdges = [
    2400, 2404;
    2404, 2408;
    2408, 2412;
    2412, 2416;
    2416, 2420
];

numBands = size(bandEdges,1);

% Band ortalama merkez frekansları (Hz cinsinden)
centerFreqs = mean(bandEdges, 2) * 1e6;  % MHz → Hz

%% Başlangıç mesajı
disp('🚀 Spectrum Scanner Başladı...');

%% Grafik hazırlığı
figure('Name', 'Dinamik Spectrum Tarayıcı', 'NumberTitle', 'off');
hBar = bar(1:numBands, zeros(1,numBands));
ylim([-100, 0]); % dBm skala
xticks(1:numBands);

bandLabels = {
    'Bant 1'
    'Bant 2'
    'Bant 3'
    'Bant 4'
    'Bant 5'
};
xticklabels(bandLabels);

ylabel('Ortalama Güç (dBm)');
title('📊 Anlık Spektrum Tarama (20 MHz toplam)', 'FontSize', 14);
grid on;
%% Sürekli tarama döngüsü
while true
    bandPowers_dBm = zeros(1, numBands);
    
    for b = 1:numBands
        % Pluto merkez frekansı ayarla
        plutoRX.setCenterFrequency(centerFreqs(b));
        
        pause(0.002); % frekans değişimi sonrası PLL otursun (~2 ms yeterli olur)
        
        % 4096 örnek al
        y = plutoRX.receiveOneFrame();
        
        % FFT + Güç hesabı
        Y = fftshift(fft(y) / params.SamplesPerFrame);
        P = abs(Y).^2;
        
        avgPwrWatt = max(mean(P), 1e-15);
        P_dBm = 10 * log10(avgPwrWatt) + 30;
        
        bandPowers_dBm(b) = P_dBm;
        
        fprintf('📡 Band %d (%.1f - %.1f MHz) — Güç: %.2f dBm\n', ...
            b, bandEdges(b,1), bandEdges(b,2), P_dBm);
    end
    
    % Grafik güncelle
    set(hBar, 'YData', bandPowers_dBm);
    drawnow;
    
    % Döngüyü yavaşlatmak için opsiyonel bekleme
    % pause(0.01); % örneğin 10 ms bekleyebilirsin
end

%% Donanımı bırakmak için (çıkmak için ctrl+C)
% plutoRX.release();