%% 16-QAM + Conv Coding (K=7, Rate 1/2) + OFDM + AWGN Kanal
clc; clear; close all;

%% Parametreler
frameLength = 3000;
numFrames = 1000;
Nfft = 64;
cpLen = 16;
M = 64;
kmod = log2(M);
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
    'SignalPower', 1); 

BER_coded = zeros(1, length(SNR_dB_vec));
BER_uncoded = zeros(1, length(SNR_dB_vec));

for si = 1:length(SNR_dB_vec)
    SNR_dB = SNR_dB_vec(si);
    awgnChan.SNR = SNR_dB;
    noiseVar = 1 / (10^(SNR_dB / 10));

    errC = 0; validC = 0;
    errU = 0;
    
    for fr = 1:numFrames
        reset(convEncoder);
        reset(vitDecoder);
        
        %% --- KODLAMALI OFDM ---
        data = randi([0 1], frameLength, 1);
        data_t = [data; zeros(tailLen,1)];
        enc = convEncoder(data_t);

        pad = mod(kmod - mod(length(enc), kmod), kmod);
        encP = [enc; zeros(pad,1)];
        dataSym = bi2de(reshape(encP, kmod, []).', 'left-msb');
        modSym = qammod(dataSym, M, 'UnitAveragePower', true);

        % OFDM
        padOfdm = mod(Nfft - mod(length(modSym), Nfft), Nfft);
        modSymP = [modSym; zeros(padOfdm,1)];
        ofdmSym = reshape(modSymP, Nfft, []);
        tx = ifft(ofdmSym) * sqrt(Nfft);
        txCP = [tx(end - cpLen + 1:end,:); tx];
        txVec = txCP(:);

        % Normalize güç ve kanal
        txVec = txVec / sqrt(mean(abs(txVec).^2));
        rxVec = awgnChan(txVec);

        % OFDM çöz
        rxMat = reshape(rxVec, Nfft + cpLen, []);
        rxNoCP = rxMat(cpLen+1:end,:);
        rxF = fft(rxNoCP) / sqrt(Nfft);
        rxData = rxF(:);

        % Soft LLR
        llr = qamdemod(rxData, M, 'UnitAveragePower', true, 'OutputType', 'approxllr');
        llr = llr / noiseVar;

        dec = vitDecoder(llr);
        drop = vitDecoder.TracebackDepth;
        validDec = dec(drop+1 : min(drop+frameLength, length(dec)));
        ref = data(1:length(validDec));

        errC = errC + sum(validDec ~= ref);
        validC = validC + length(validDec);
        
        %% --- KODLAMASIZ OFDM ---
        dataU = randi([0 1], frameLength, 1);
        padU = mod(kmod - mod(length(dataU), kmod), kmod);
        dataUP = [dataU; zeros(padU,1)];
        dataSymU = bi2de(reshape(dataUP, kmod, []).', 'left-msb');
        modSymU = qammod(dataSymU, M, 'UnitAveragePower', true);

        padOfdmU = mod(Nfft - mod(length(modSymU), Nfft), Nfft);
        modSymUP = [modSymU; zeros(padOfdmU,1)];
        ofdmSymU = reshape(modSymUP, Nfft, []);
        txU = ifft(ofdmSymU) * sqrt(Nfft);
        txUCP = [txU(end - cpLen + 1:end,:); txU];
        txVecU = txUCP(:);

        txVecU = txVecU / sqrt(mean(abs(txVecU).^2));
        rxVecU = awgnChan(txVecU);

        rxMatU = reshape(rxVecU, Nfft + cpLen, []);
        rxNoCPU = rxMatU(cpLen+1:end,:);
        rxFU = fft(rxNoCPU) / sqrt(Nfft);
        rxDataU = rxFU(:);

        llrU = qamdemod(rxDataU, M, 'UnitAveragePower', true, 'OutputType', 'approxllr');
        bitsU = double(llrU < 0);
        errU = errU + sum(bitsU(1:frameLength) ~= dataU);
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
legend('Coded K=7, R=1/2 — 16QAM-OFDM', 'Uncoded 16QAM-OFDM', 'Location','southwest');
title('Coded vs Uncoded — 16-QAM-OFDM — AWGN Kanal');
