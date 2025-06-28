classdef OFDMFHSSTransmitter < handle
    
    properties
        params
        txObj
        preambleBuilder
        frameDataBuilder
        modulationMapper
        ofdmFrameGen
        txFrame

        centerFreqs
        durations
        
        frameTime
        framesPerSecond
        
        resetCycleCount
        totalTargetTime
        
        driftAccum
        cycleCounter
        
        globalStart
        globalTarget
        globalErrorOffset % <-- yeni property (başlangıç globalError offset)
    end
    
    methods
        function obj = OFDMFHSSTransmitter(params, centerFreqs, durations)
            % Constructor
            obj.params = params;
            
            % --- Nesneleri oluştur
            obj.preambleBuilder   = OFDMPreambleBuilder(params);
            obj.frameDataBuilder  = FrameDataBuilder(params);
            obj.modulationMapper  = ModulationMapper(params);
            obj.ofdmFrameGen      = OFDMFrameGenerator(params, obj.frameDataBuilder, obj.modulationMapper);
            obj.txObj             = OFDMPlutoTX(params);
            
            % --- TX frame oluştur
            obj.txFrame = obj.ofdmFrameGen.generateOFDMFrame(obj.preambleBuilder);
            
            % --- FHSS ayarları
            obj.centerFreqs = centerFreqs;
            obj.durations   = durations;
            
            obj.frameTime   = params.SamplesPerFrame / params.BasebandSampleRate;
            obj.framesPerSecond = floor(1 / obj.frameTime);
            
            obj.resetCycleCount = 10;
            obj.totalTargetTime = sum(durations);
            
            obj.driftAccum   = 0;
            obj.cycleCounter = 0;
            
            obj.globalStart = tic;
            obj.globalTarget = 0;
            obj.globalErrorOffset = 0; % başlangıçta 0
        end
        
        function start(obj, jammerDetectionObj)
            disp('🚀 [CLASS] FHSS OFDM TX Başlatıldı... (Ctrl+C ile çıkabilirsiniz)');
            
            % --- Önce pattern loop başlat
            obj.startPatternLoop(jammerDetectionObj);
            
            % --- Pattern loop 2 olduğunda → buraya geliyoruz → gönderim başlıyor
            while true
                obj.cycleCounter = obj.cycleCounter + 1;
                cycleStart = tic;
                
                for k = 1:length(obj.centerFreqs)
                    obj.txObj.tx.CenterFrequency = obj.centerFreqs(k);
                    targetDuration = obj.durations(k);
                    
                    elapsedTime = 0;
                    tic;
                    frameCounter = 0;
                    
                    fprintf('📡 Band %d @ %.3f GHz — hedef %.1f saniye...\n', ...
                        k, obj.centerFreqs(k)/1e9, targetDuration);
                    
                    while elapsedTime < targetDuration
                        obj.txObj.transmitFrame(obj.txFrame);
                        frameCounter = frameCounter + 1;
                        elapsedTime = toc;
                    end
                    
                    fprintf('✅ Band %d — toplam %d frame gönderildi — süre: %.3f saniye\n\n', ...
                        k, frameCounter, elapsedTime);
                end
                
                % Drift hesapla
                actualCycleTime = toc(cycleStart);
                cycleDrift = actualCycleTime - obj.totalTargetTime;
                obj.driftAccum = obj.driftAccum + cycleDrift;
                
                obj.globalTarget = obj.globalTarget + obj.totalTargetTime;
                
                globalElapsed = toc(obj.globalStart);
                globalError = globalElapsed - obj.globalTarget;
                
                % İlk cycle’da globalErrorOffset ölç
                if obj.cycleCounter == 1
                    obj.globalErrorOffset = globalError;
                    fprintf('📍 Initial globalErrorOffset recorded: %.3f s\n', obj.globalErrorOffset);
                end
                
                % "Gerçek" global error (offset sonrası)
                realGlobalError = globalError - obj.globalErrorOffset;
                
                fprintf('🔍 Cycle %d — actual: %.3f s — target: %.3f s — drift: %.3f s (accum drift: %.3f s)\n', ...
                    obj.cycleCounter, actualCycleTime, obj.totalTargetTime, cycleDrift, obj.driftAccum);
                
                fprintf('🌍 Global Time: %.3f s — Global Target: %.3f s — Real Global Error: %.3f s\n\n', ...
                    globalElapsed, obj.globalTarget, realGlobalError);
                
                % Frame-based Correction (LIMITED)
                if mod(obj.cycleCounter, obj.resetCycleCount) == 0
                    previousDrift = obj.driftAccum;
                    correctionPause = obj.driftAccum + realGlobalError;

                    % Kaç frame skip edeceğini hesapla
                    frameSkip = round(correctionPause / obj.frameTime);

                    % --- Max frame skip limit
                    maxFrameSkip = 100; % ~400 ms düzeltme hakkı

                    frameSkipToApply = min(frameSkip, maxFrameSkip);

                    if frameSkipToApply > 0
                        fprintf('🕒 FRAME-BASED CORRECTION: %d/%d frame SKIP ediliyor (drift=%.3f s)...\n', ...
                            frameSkipToApply, frameSkip, correctionPause);

                        for skipIdx = 1:frameSkipToApply
                            pause(obj.frameTime); % akışı bozmadan bekle
                        end

                        obj.globalTarget = obj.globalTarget + frameSkipToApply * obj.frameTime;

                        % Eğer daha fazla correction kalıyorsa → birikmeye bırak
                        remainingCorrection = frameSkip - frameSkipToApply;
                        if remainingCorrection > 0
                            obj.driftAccum = remainingCorrection * obj.frameTime;
                            fprintf('🔄 Remaining correction deferred: %.3f s (frames left: %d)\n', ...
                                obj.driftAccum, remainingCorrection);
                        else
                            obj.driftAccum = 0;
                        end
                    else
                        fprintf('✅ No correction needed (drift too small).\n');
                        obj.driftAccum = 0;
                    end

                    fprintf('📏 Correction sonrası kontrol — önceki drift: %.3f s → yeni drift: %.3f s\n\n', ...
                        previousDrift, obj.driftAccum);
                end
            end
        end
    end
    
    methods (Static)
        function startPatternLoop(jammerDetectionObj)
            disp('🟢 Pattern loop başlatıldı (2 gelene kadar bekleniyor)...');
            idx_pat = 3; % Başlangıç index
            
            while true
                currentPat = jammerDetectionObj.params.pattern(idx_pat);
                pause(1);
                fprintf('📡 Aktif Jammer Bandı: %d\n', currentPat);
                
                if currentPat == 2
                    disp('✅ Pattern 2 algılandı — gönderim başlatılıyor...');
                    break;
                end
                
                idx_pat = idx_pat + 1;
                if idx_pat > numel(jammerDetectionObj.params.pattern)
                    idx_pat = 1;
                end
            end
        end
    end
end
