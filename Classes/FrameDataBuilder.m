classdef FrameDataBuilder < handle
    properties
        params
    end
    
    methods
        function obj = FrameDataBuilder(params)
            obj.params = params;
        end
        
        function headerBits = generateHeaderBits(obj)
            headerBits = randi([0 1], obj.params.NumDataCarriers, 1);
        end
        
        function payloadBits = generatePayloadBits(obj)
            bitsPerSymbol = obj.getBitsPerSymbol();

            % Payload bits sayısı: data carriers * symbols * bits per symbol
            numBits = obj.params.NumDataCarriers * obj.params.NumDataSymbols * bitsPerSymbol;

            % Örnek mesaj:
            bitsPerChar = 8;
            numChars    = ceil(numBits / bitsPerChar);
            
            message = repmat('ABCDEFGHIJKLMNOPQRSTUVWXYZ', 1, numChars);
            bitStr  = reshape(dec2bin(message, bitsPerChar).', [], 1);
            msgBits = bitStr - '0';
            
            payloadBits = msgBits(1:numBits);
        end
        
        function Pilots = generatePilotSymbols(obj, numSymbols)
            if nargin < 2
                numSymbols = obj.params.NumDataSymbols;
            end

            pilotPattern = [1; -1; 1; 1];
            Pilots = repmat(pilotPattern, 1, numSymbols);
        end

        function bitsPerSymbol = getBitsPerSymbol(obj)
            switch obj.params.Modulation
                case 'BPSK'
                    bitsPerSymbol = 1;
                case 'QPSK'
                    bitsPerSymbol = 2;
                case '8PSK'
                    bitsPerSymbol = 3;
                case '16PSK'
                    bitsPerSymbol = 4;
                case '16QAM'
                    bitsPerSymbol = 4;
                case '64QAM'
                    bitsPerSymbol = 6;
                otherwise
                    error('Unsupported modulation type: %s', obj.params.Modulation);
            end
        end
    end
end
