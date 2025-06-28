classdef OFDMRXProcessor < handle
    properties
        params
        syncFunc
        ofdmDemod
    end
    
    methods
        function obj = OFDMRXProcessor(params, preambleBuilder)
            obj.params = params;
            obj.syncFunc = OFDMSyncFunctions(params, preambleBuilder);
            
            % OFDM Demodulator nesnesi burada yaratılıyor (TX tarafı ile uyumlu)
            obj.ofdmDemod = comm.OFDMDemodulator( ...
                'FFTLength',            params.FFTLength, ...
                'NumGuardBandCarriers', params.NumGuardBandCarriers, ...
                'RemoveDCCarrier',      true, ...
                'PilotOutputPort',      true, ...
                'PilotCarrierIndices',  params.PilotCarrierIndices, ...
                'CyclicPrefixLength',   params.CyclicPrefixLength, ...
                'NumSymbols',           params.NumDataSymbols + 1);
        end
        
        function [allRxFrames, allRxBits, allRxSymbols, totalDetectedFrames] = process(obj, rxBuffer, knownLLTF, knownPilots, PilotCarrierIndices, modMapper)
            N_blocks = size(rxBuffer,2);
    
            allRxFrames = {};
            allRxBits = {};
            allRxSymbols = {};
            totalFrames = 0;
            totalDetectedFrames = 0;  

            for i = 1:N_blocks
                rxData = rxBuffer(:,i);
        
                [rxFrames, ~, ~, ~, ~] = obj.syncFunc.packetDetect(rxData);
                
                totalDetectedFrames = totalDetectedFrames + obj.syncFunc.lastDetectedFrameCount;

                for j = 1:length(rxFrames)
                    rxFrame = rxFrames{j};
            
                    % CFO Correction
                    [frameCorrected, ~] = obj.syncFunc.cfoEst(rxFrame);

                    H_est = obj.syncFunc.chanEst(frameCorrected, knownLLTF);

                    symbolLen = obj.params.FFTLength + obj.params.CyclicPrefixLength;
                    totalInputLen = symbolLen * (obj.params.NumDataSymbols + 1);

                    dataPart = frameCorrected(321 : 320 + totalInputLen);

                    [rxDataSym, rxPilotSym] = obj.ofdmDemod(dataPart);

                    resetState = true;  % her frame başında reset!
                    rxDataEq = obj.syncFunc.chanEq(rxDataSym, rxPilotSym, H_est, knownPilots, PilotCarrierIndices, resetState);

                    % Demodulation
                    rxBitsMatrix = modMapper.demodulate(rxDataEq(:, 2:end));  % 48x45
                    rxBits = reshape(rxBitsMatrix, [], 1);                    % 2160x1

                    % Save frame + bits + symbols
                    totalFrames = totalFrames + 1;
                    allRxFrames{totalFrames}  = rxFrame;
                    allRxBits{totalFrames}    = rxBits;
                    allRxSymbols{totalFrames} = rxDataEq(:);  % flatten → for constellation
            
                end
            end
    
            fprintf('OFDMRXProcessor → toplam %d frame işlendi.\n', totalFrames);
        end


    end
end
