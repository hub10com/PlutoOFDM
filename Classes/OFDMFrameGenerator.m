classdef OFDMFrameGenerator < handle
    properties
        params
        ofdmMod
        frameDataBuilder
        modulationMapper
    end
    
    methods
        % 🚀 Constructor
        function obj = OFDMFrameGenerator(params, frameDataBuilder, modulationMapper)
            obj.params = params;
            obj.frameDataBuilder = frameDataBuilder;
            obj.modulationMapper = modulationMapper;
            
            obj.ofdmMod = comm.OFDMModulator( ...
                'FFTLength',            params.FFTLength, ...
                'NumGuardBandCarriers', params.NumGuardBandCarriers, ...
                'InsertDCNull',         true, ...
                'PilotInputPort',       true, ...
                'PilotCarrierIndices',  params.PilotCarrierIndices, ...
                'CyclicPrefixLength',   params.CyclicPrefixLength, ...
                'NumSymbols',           params.TotalSymbols);
        end
        
        function txFrame = generateOFDMFrame(obj, preambleBuilder)
            % --- HEADER ---
            headerBits = obj.frameDataBuilder.generateHeaderBits();
            headerSymbols = pskmod(headerBits, 2);  % BPSK header
    
            % --- PAYLOAD ---
            payloadBits = obj.frameDataBuilder.generatePayloadBits();
            payloadSymbols = obj.modulationMapper.modulate(payloadBits);
    
            % --- Hesap ---
            bitsPerSymbol = obj.frameDataBuilder.getBitsPerSymbol();
            numPayloadSymbols = length(payloadBits) / (bitsPerSymbol * obj.params.NumDataCarriers);
    
            % Info
            fprintf('HeaderSymbols = %d, PayloadSymbols = %.2f OFDM symbols, Expected NumDataSymbols = %d\n', ...
                length(headerSymbols), numPayloadSymbols, obj.params.NumDataSymbols);
    
            % --- FrameData ---
            modAll = [headerSymbols; payloadSymbols];
        
            TotalSymbols = 1 + round(numPayloadSymbols);  % 1 header + payload
    
            % reshape doğru şekilde
            frameData = reshape(modAll, obj.params.NumDataCarriers, TotalSymbols);
    
            % --- Pilots ---
            pilotSymbols = obj.frameDataBuilder.generatePilotSymbols(TotalSymbols);
    
            % --- OFDM Modulation ---
            txOFDMSignal = obj.ofdmMod(frameData, pilotSymbols);
    
            % --- Preamble ---
            preamble = preambleBuilder.generatePreamble();
    
            % --- Final Frame ---
            txFrame = [preamble; txOFDMSignal];
        end
    end
end
