classdef JammerDetection < handle
    properties
        params
        rxObj
        threshold_dBm
    end

    methods
        function obj = JammerDetection(params, rxObj)
            obj.params = params;
            obj.rxObj = rxObj;
        end

        function calibrate(obj)
            % --- Dummy RX (ilk slow frame önleme)
            dummyCount = 10;
            fprintf("🔄 Dummy RX frame alınıyor (%d frame, ilk RX latency stabilizasyon)...\n", dummyCount);
            for k = 1:dummyCount
                obj.rxObj.receiveOneFrame();
            end

            % --- Ortalama frame süresi ve RX süresi ölçülüyor
            testFrameCount = 20;
            fprintf("⏱️ Ortalama frame ve RX süresi ölçülüyor (%d frame)...\n", testFrameCount);

            rxTimeTotal = 0;
            tic;
            for i = 1:testFrameCount
                t1 = tic;
                y = obj.rxObj.receiveOneFrame();
                rxTime = toc(t1);
                rxTimeTotal = rxTimeTotal + rxTime;

                Y = fftshift(fft(y) / obj.params.SamplesPerFrame);
                P = abs(Y).^2;
                avgPwrWatt = max(mean(P), 1e-15);
                P_dBm = 10 * log10(avgPwrWatt) + 30;

                if ~obj.params.EnablePlot
                    fprintf("🔹 Frame %d - Güç: %.2f dBm (RX time: %.3f ms)\n", i, P_dBm, rxTime * 1e3);
                end
            end
            elapsedTest = toc;
            measuredFrameTime = elapsedTest / testFrameCount;
            meanRxTime = rxTimeTotal / testFrameCount;

            fprintf("📏 Ortalama TOTAL frame süresi: %.3f ms\n", measuredFrameTime * 1e3);
            fprintf("📏 Ortalama sadece RX süresi: %.3f ms\n", meanRxTime * 1e3);

            % --- Hedef frame sayısı (tam 5 saniye için)
            targetDuration = obj.params.CalibrationDuration;
            numFrames = ceil(targetDuration / measuredFrameTime);

            fprintf("🟣 İlk Kalibrasyon başlatıldı — %d frame (~%.1f saniye hedef)...\n", numFrames, numFrames * measuredFrameTime);

            % --- Kalibrasyon loop
            powerVec = zeros(1, numFrames);

            if obj.params.EnablePlot
                figure('Name','Jammer Tespiti - Kalibrasyon');
                hBar = bar(0,0,'FaceColor','flat');
                xlabel('Tek Bant');
                ylabel('Güç (dBm)');
                title(sprintf('🟣 İlk Kalibrasyon (%d Frame)', numFrames));
                ylim([-100 0]);
                grid on;
                drawnow;
            end

            tic;
            for i = 1:numFrames
                y = obj.rxObj.receiveOneFrame();
                Y = fftshift(fft(y) / obj.params.SamplesPerFrame);
                P = abs(Y).^2;
                avgPwrWatt = max(mean(P), 1e-15);
                P_dBm = 10 * log10(avgPwrWatt) + 30;

                powerVec(i) = P_dBm;

                if obj.params.EnablePlot
                    hBar.CData = [0.5 0 0.5];
                    set(hBar,'YData',P_dBm);
                    drawnow;
                    pause(0.01);
                else
                    fprintf("🔹 Frame %d - Güç: %.2f dBm\n", i, P_dBm);
                end
            end
            elapsedTime = toc;
            fprintf("🕒 Kalibrasyon toplam süre: %.3f s — Ortalama frame süresi: %.3f ms\n", ...
                elapsedTime, (elapsedTime/numFrames)*1e3);

            fprintf("🟣 İlk Kalibrasyon tamamlandı.\n");

            % --- GMM ile threshold hesapla
            obj.threshold_dBm = fitGMMtoPowerVecJammer(powerVec); % ← GMM çağrısı

            % --- Temiz ortam kalibrasyonu
            fprintf("🧪 Temiz ortam kalibrasyonu başlatıldı...\n");
            jamFreeFound = false;
            jammerFreeThreshold = 10;
            noJammerCount = 0;

            if obj.params.EnablePlot
                title('🔄 Kalibrasyon: Temiz Ortam Aranıyor...');
            end

            for i = 1:(numFrames/10)
                y = obj.rxObj.receiveOneFrame();
                Y = fftshift(fft(y) / obj.params.SamplesPerFrame);
                P = abs(Y).^2;
                avgPwrWatt = max(mean(P), 1e-15);
                P_dBm = 10 * log10(avgPwrWatt) + 30;

                if obj.params.EnablePlot
                    hBar.CData = [1 1 0];
                    set(hBar,'YData',P_dBm);
                    drawnow;
                    pause(0.01);
                else
                    fprintf("🔸 Frame %d - Güç: %.2f dBm\n", i, P_dBm);
                end

                if P_dBm < obj.threshold_dBm
                    noJammerCount = noJammerCount + 1;
                    if noJammerCount >= jammerFreeThreshold
                        jamFreeFound = true;
                        fprintf("✅ Temiz ortam bulundu (Frame %d).\n", i);
                        break;
                    end
                else
                    noJammerCount = 0;
                end
            end

            if ~jamFreeFound
                warning("⚠️ Kalibrasyon başarısız. Jammer etkisinde başlıyoruz.");
            end
        end

        function runDetection(obj)
            numFrames = obj.params.numDetectionFrames;
            jammerCount = 0;

            if obj.params.EnablePlot
                figure('Name','Jammer Detection - Real-time');
                hBar = bar(0,0,'FaceColor','flat');
                xlabel('Tek Bant');
                ylabel('Güç (dBm)');
                title(sprintf('Gerçek Zamanlı Enerji Tespiti (Eşik = %.1f dBm)', obj.threshold_dBm));
                ylim([-100 0]);
                grid on;
                drawnow;
            end

            tic;
            for idx = 1:numFrames
                y = obj.rxObj.receiveOneFrame();
                Y = fftshift(fft(y) / obj.params.SamplesPerFrame);
                P = abs(Y).^2;
                avgPwrWatt = max(mean(P), 1e-15);
                P_dBm = 10 * log10(avgPwrWatt) + 30;

                if obj.params.EnablePlot
                    if P_dBm > obj.threshold_dBm
                        hBar.CData = [1 0 0];
                    else
                        hBar.CData = [0.2 0.6 0.8];
                    end
                    set(hBar,'YData',P_dBm);
                    drawnow;
                    pause(0.01);
                end

                % Jammer kontrol
                if P_dBm > obj.threshold_dBm
                    jammerCount = jammerCount + 1;
                    fprintf("🚨 Frame %d - JAMMER tespit edildi! Güç: %.2f dBm\n", idx, P_dBm);
                else
                    jammerCount = 0;
                    fprintf("✅ Frame %d - Jammer tespit edilmedi. Güç: %.2f dBm\n", idx, P_dBm);
                end

                if jammerCount >= obj.params.JammerFrameCount
                    disp("🔥🔥🔥 Sürekli JAMMER tespit edildi!");
                    obj.rxObj.release();
                    return;
                end
            end
            elapsedTime = toc;
            fprintf("🕒 Detection toplam süre: %.3f s — Ortalama frame süresi: %.3f ms\n", ...
                elapsedTime, (elapsedTime/numFrames)*1e3);

            obj.rxObj.release();
        end

        function release(obj)
            obj.rxObj.release();
        end
    end
end
