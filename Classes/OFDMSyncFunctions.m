classdef OFDMSyncFunctions < handle
    properties
        params
        FFTLength
        CyclicPrefixLength
        symLen
        frameLen
        LSTF
        LLTF
        lastDetectedFrameCount   
    end
    
    methods
        function obj = OFDMSyncFunctions(params, preambleBuilder)
            obj.params = params;
            obj.FFTLength = params.FFTLength;
            obj.CyclicPrefixLength = params.CyclicPrefixLength;
            obj.symLen = obj.FFTLength + obj.CyclicPrefixLength;
            obj.frameLen = params.frameLength;
            
            fullPreamble = preambleBuilder.generatePreamble();
            
            obj.LSTF = fullPreamble(1:160);
            obj.LLTF = fullPreamble(161:160+160);
        end
        
        function [rxFrames, locs, metric, baseline, adaptiveThreshScalar] = packetDetect(obj, rxData)
            N = 16;
            metric = zeros(length(rxData)-2*N,1);

            for k = 1:length(metric)
                P = sum(rxData(k:k+N-1) .* conj(rxData(k+N:k+2*N-1)));
                R = sum(abs(rxData(k+N:k+2*N-1)).^2);
                metric(k) = abs(P)^2 / (R^2 + eps);
            end

            baseline = movmean(metric, 1000);
            adaptiveThreshScalar = median(metric) + 0.80 * (max(metric) - median(metric));

            [~, locs] = findpeaks(metric, ...
                'MinPeakHeight', adaptiveThreshScalar, ...
                'MinPeakDistance', 3600);

            fprintf('%d adet çerçeve tespit edildi.\n', length(locs));

            rxFrames = {};
            validCount = 0;

            for i = 1:length(locs)
                startIdx = locs(i);
                endIdx = startIdx + obj.frameLen - 1;
                if endIdx <= length(rxData)
                    validCount = validCount + 1;
                    rxFrames{validCount} = rxData(startIdx:endIdx);
                end
            end

            fprintf('%d adet geçerli çerçeve kesildi.\n', validCount);

            newFrames = {};
            validCountNew = 0;

            for i = 1:validCount
                frame = rxFrames{i};
                known = obj.LLTF(1:obj.symLen);

                m = abs(xcorr(frame, known)).^2;
                padding = length(frame) - obj.symLen + 1;
                c_cor = m(padding:end);

                [~, peak1] = max(c_cor);
                c_cor(peak1) = 0;
                [~, peak2] = max(c_cor);

                if abs(peak2 - peak1) == obj.FFTLength
                    p = min([peak1 peak2]);
                    LLTF_Start_est = p - obj.symLen;
                    LSTF_Start_est = LLTF_Start_est - length(obj.LSTF);
                    trueStart = locs(i) + LSTF_Start_est;
                    trueEnd = trueStart + obj.frameLen - 1;

                    if trueStart > 0 && trueEnd <= length(rxData)
                        validCountNew = validCountNew + 1;
                        newFrames{validCountNew} = rxData(trueStart:trueEnd);
                    else
                        warning('Frame hizalaması sınır dışında! Atlanıyor.');
                    end
                else
                    warning('Fine timing başarısız. Frame atlandı.');
                end
            end

            rxFrames = newFrames;
            fprintf('Fine timing tamamlandı. %d geçerli frame.\n', numel(rxFrames));
            obj.lastDetectedFrameCount = length(locs);
        end
        
        function [frameCorrected, estCFO] = cfoEst(obj, rxFrame)
            % Güncellenmiş CFO tahmini ve düzeltme fonksiyonu
            % LLTF'den CFO tahmini + residual için daha sağlam yapı

            fs = obj.params.BasebandSampleRate;
            idx = 160;

            if idx + 2*obj.FFTLength - 1 <= length(rxFrame)
                % LLTF iki symbol
                s1 = rxFrame(idx : idx+obj.FFTLength -1);
                s2 = rxFrame(idx+obj.FFTLength : idx+2*obj.FFTLength -1);

                % Phase difference from LLTF
                phaseDiff = angle(sum(conj(s1) .* s2));
                % CFO in Hz
                estCFO = phaseDiff / (2 * pi * obj.FFTLength / fs);

                % Apply static correction to entire frame
                n = (0:length(rxFrame)-1).';
                frameCorrected = rxFrame .* exp(-1j * 2 * pi * estCFO * n / fs);

                % Info print (optional)
                % fprintf('CFO estimate: %.2f Hz\n', estCFO);
            else
                warning('CFO tahmini yapılamadı (frame uzunluğu yetersiz).');
                estCFO = 0;
                frameCorrected = rxFrame;
            end
        end

        
        function H_est = chanEst(obj, frame, knownLLTF)
            % LLTF CP sonrası index
            idx = 160;  

            s1 = frame(idx : idx + obj.params.FFTLength - 1);
            s2 = frame(idx + obj.params.FFTLength : idx + 2*obj.params.FFTLength - 1);
    
            % Average FFT
            H_est = (fft(s1) + fft(s2)) / 2 ./ knownLLTF;
        end

        
        function rxDataEq = chanEq(obj, rxDataSym, rxPilotSym, H_est, knownPilots, PilotCarrierIndices, resetState)

            NumOFDMSymbols = size(rxDataSym,2);
            dataCarrierIndices = setdiff(1:obj.FFTLength, [1:6, 60:64, 33, PilotCarrierIndices.']);
            rxDataEq = zeros(size(rxDataSym));

            % İlk symbol
            rxDataEq(:,1) = rxDataSym(:,1) ./ H_est(dataCarrierIndices);

            % Fine tracking değişkenleri
            persistent finePhaseAcc fineGainAcc prevPhase

            % Eğer resetState aktifse → sıfırla
            if resetState
                finePhaseAcc = 0;
                fineGainAcc  = 0;
                prevPhase    = 0;
            end

            % Modulation order
            modType = obj.params.Modulation;
            switch modType
                case 'BPSK'
                    M = 2;
                case 'QPSK'
                    M = 4;
                case '8PSK'
                    M = 8;
                case {'16PSK','16QAM'}
                    M = 16;
                case '64QAM'
                    M = 64;
                otherwise
                    error('Unsupported modulation type: %s', modType);
            end

            % Loop
            for k = 2:NumOFDMSymbols
                alpha = (k <= 4) * 0.5 + (k > 4) * 0.1;

                rxPilots = rxPilotSym(:,k);
                known = knownPilots(:,k);
                H_pilot = rxPilots ./ known;

                H_interp = interp1(PilotCarrierIndices, H_pilot, 1:obj.FFTLength, 'linear', 'extrap').';
                H_est = (1-alpha) * H_est + alpha * H_interp;

                eqSym = rxDataSym(:,k) ./ H_est(dataCarrierIndices);

                % 🌟 Gain correction → sadece QAM için uygula!
                if ismember(modType, [16, 64])
                    gainError = mean(abs(H_pilot)) - 1;
                    fineGainAcc = 0.95 * fineGainAcc + 0.05 * gainError;
                    eqSym = eqSym ./ (1 + fineGainAcc);
                end

                % 🚀 Decision Directed update
                switch modType
                    case 'BPSK'
                        decSym = sign(real(eqSym));
                    case 'QPSK'
                        decSym = sign(real(real(eqSym))) + 1j * sign(real(imag(eqSym)));
                    case {'8PSK','16PSK'}
                        decInt = pskdemod(eqSym, M);
                        decSym = pskmod(decInt, M);
                    case {'16QAM','64QAM'}
                        decInt = qamdemod(eqSym, M, 'UnitAveragePower', true);
                        decSym = qammod(decInt, M, 'UnitAveragePower', true);
                    otherwise
                        error('Unsupported modulation type: %s', modType);
                end

                H_dd = rxDataSym(:,k) ./ decSym;
                H_interp_full = H_interp;
                H_interp_full(dataCarrierIndices) = H_dd;
                H_est = (1-alpha) * H_est + alpha * H_interp_full;

                % 📌 Pilot phase-based fine phase correction
                pilotPhase = angle(mean(rxPilots .* conj(known)));
                phaseDiff = mod(pilotPhase - prevPhase + pi, 2*pi) - pi;
                prevPhase = pilotPhase;

                finePhaseAcc = 0.95 * finePhaseAcc + 0.05 * phaseDiff;

                rxDataEq(:,k) = eqSym * exp(-1j * finePhaseAcc);
            end
        end
    end
end
