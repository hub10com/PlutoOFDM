%% BPSK-OFDM + Conv Coding (K=7, Rate 1/2) + AWGN Kanal
clc; clear; close all;

%% Parametreler
frameLength = 3000;
numFrames = 1000;
Nfft = 64;
cpLen = 16;
SNR_dB_vec = [0 10 20];

K = 7;
tailLen = 2 * (K - 1);
trellis = poly2trellis(K, [171 133]);
puncturePat = [1;1];

convEncoder = comm.ConvolutionalEncoder( ...
    trellis, ...
    'PuncturePatternSource', 'Property', ...
    'PuncturePattern', puncturePat);

vitDecoder = comm.ViterbiDecoder( ...
    trellis, ...
    'InputFormat', 'Unquantized', ...
    'PuncturePatternSource', 'Property', ...
    'PuncturePattern', puncturePat, ...
    'TracebackDepth', 35);

awgnChan = comm.AWGNChannel( ...
    'NoiseMethod', 'Signal to noise ratio (SNR)', ...
    'SignalPower', 1); % OFDM çıkış gücü 1 olacak şekilde ayarlanacak

BER_coded = zeros(size(SNR_dB_vec));
BER_uncoded = zeros(size(SNR_dB_vec));

for si = 1:length(SNR_dB_vec)
    SNR_dB = SNR_dB_vec(si);
    awgnChan.SNR = SNR_dB;
    
    errC = 0; validC = 0;
    errU = 0;
    
    for fr = 1:numFrames
        reset(convEncoder);
        reset(vitDecoder);
        
        %% KODLAMALI BPSK-OFDM
        data = randi([0 1], frameLength, 1);
        data_t = [data; zeros(tailLen,1)];
        enc = convEncoder(data_t);
        
        pad = mod(Nfft - mod(length(enc), Nfft), Nfft);
        encP = [enc; zeros(pad,1)];
        bpsk = 1 - 2 * encP;
        
        ofdmSym = reshape(bpsk, Nfft, []);
        tx = ifft(ofdmSym, Nfft) * sqrt(Nfft);
        txCP = [tx(end - cpLen + 1:end,:); tx];
        txVec = txCP(:);
        
        if fr == 1 && si == 1
            disp('OFDM sembol ortalama gücü:');
            disp(mean(abs(txVec).^2))
        end
        
        % Gücü normalize et ve AWGN kanala gönder
        txVec_norm = txVec / sqrt(mean(abs(txVec).^2));
        rxVec = awgnChan(txVec_norm);
        
        rxMat = reshape(rxVec, Nfft+cpLen, []);
        rxNoCP = rxMat(cpLen+1:end,:);
        rxF = fft(rxNoCP, Nfft) / sqrt(Nfft);
        
        noiseVar = 1 / (10^(SNR_dB/10)); % SignalPower=1 olduğu için doğrudan geçerli
        llr = 2 * real(rxF(:)) / noiseVar;
        
        dec = vitDecoder(llr);
        
        drop = vitDecoder.TracebackDepth;
        startIdx = drop + 1;
        endIdx = min(startIdx + frameLength - 1, length(dec));
        
        if startIdx <= length(dec)
            validBits = dec(startIdx:endIdx);
            ref = data(1:length(validBits));
            errC = errC + sum(validBits ~= ref);
            validC = validC + length(validBits);
        end
        
        %% KODLAMASIZ BPSK-OFDM
        data2 = randi([0 1], frameLength, 1);
        bpsk2 = 1 - 2 * data2;
        pad2 = mod(Nfft - mod(length(bpsk2), Nfft), Nfft);
        bpsk2P = [bpsk2; zeros(pad2,1)];
        
        ofdm2 = reshape(bpsk2P, Nfft, []);
        tx2 = ifft(ofdm2, Nfft) * sqrt(Nfft);
        tx2CP = [tx2(end - cpLen + 1:end,:); tx2];
        tx2Vec = tx2CP(:);
        
        tx2Vec_norm = tx2Vec / sqrt(mean(abs(tx2Vec).^2));
        rx2Vec = awgnChan(tx2Vec_norm);
        
        rx2Mat = reshape(rx2Vec, Nfft+cpLen, []);
        rx2NoCP = rx2Mat(cpLen+1:end,:);
        rx2F = fft(rx2NoCP, Nfft) / sqrt(Nfft);
        
        dec2 = real(rx2F(:)) < 0;
        errU = errU + sum(dec2(1:frameLength) ~= data2);
    end
    
    BER_coded(si) = errC / validC;
    BER_uncoded(si) = errU / (frameLength * numFrames);
    
    fprintf('SNR=%2d dB → Coded BER=%.6f | Uncoded BER=%.6f\n', ...
        SNR_dB, BER_coded(si), BER_uncoded(si));
end

figure;
semilogy(SNR_dB_vec, BER_coded, '-o', 'LineWidth', 2); hold on;
semilogy(SNR_dB_vec, BER_uncoded, '-s', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
legend('Coded K=7, R=1/2 — BPSK-OFDM', 'Uncoded BPSK-OFDM', 'Location','southwest');
title('Coded vs Uncoded — BPSK-OFDM — AWGN Kanal');
