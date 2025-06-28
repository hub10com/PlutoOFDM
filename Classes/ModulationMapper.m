classdef ModulationMapper < handle
    properties
        params
        ModulationType  
        M               
    end
    
    methods
        % 🚀 Constructor
        function obj = ModulationMapper(params)
            obj.params = params;
            obj.ModulationType = params.Modulation;  % otomatik al
            
            switch obj.ModulationType
                case 'BPSK'
                    obj.M = 2;
                case 'QPSK'
                    obj.M = 4;
                case '8PSK'
                    obj.M = 8;
                case '16PSK'
                    obj.M = 16;
                case '16QAM'
                    obj.M = 16;
                case '64QAM'
                    obj.M = 64;
                otherwise
                    error('Unsupported modulation type: %s', obj.ModulationType);
            end
        end
        
        % 🚀 Modülasyon
        function symbols = modulate(obj, bits)
            bitsPerSymbol = log2(obj.M);
            
            switch obj.ModulationType
                case 'BPSK'
                    symbols = pskmod(bits, obj.M);
                    
                case {'QPSK', '8PSK', '16PSK'}
                    % Bits'i gruplara böl, integer yap, sonra modüle et
                    bitsGrouped = reshape(bits, bitsPerSymbol, []).';
                    symbols = pskmod( bi2de(bitsGrouped), obj.M );
                    
                case {'16QAM', '64QAM'}
                    bitsGrouped = reshape(bits, bitsPerSymbol, []).';
                    symbols = qammod( bi2de(bitsGrouped), obj.M, 'InputType', 'integer', 'UnitAveragePower', true );
                    
                otherwise
                    error('Unsupported modulation type: %s', obj.ModulationType);
            end
        end
        
        % 🚀 Demodülasyon
        function bits = demodulate(obj, symbols)
            bitsPerSymbol = log2(obj.M);
            
            switch obj.ModulationType
                case 'BPSK'
                    bits = pskdemod(symbols, obj.M);
                    bits = mod(bits, 2);  % 0-1 bit'e dönüştür
                    
                case {'QPSK', '8PSK', '16PSK'}
                    % Demodüle et, integer → bits dizisine geri çevir
                    intSymbols = pskdemod(symbols, obj.M);
                    bits = de2bi(intSymbols, bitsPerSymbol).';
                    bits = bits(:);
                    
                case {'16QAM', '64QAM'}
                    intSymbols = qamdemod(symbols, obj.M, 'OutputType', 'integer', 'UnitAveragePower', true);
                    bits = de2bi(intSymbols, bitsPerSymbol).';
                    bits = bits(:);
                    
                otherwise
                    error('Unsupported modulation type: %s', obj.ModulationType);
            end
        end
    end
end
