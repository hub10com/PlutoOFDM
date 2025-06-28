classdef OFDMPlutoRX < handle
    properties
        params
        rx
    end
    
    methods
        function obj = OFDMPlutoRX(params)
            obj.params = params;
            
            obj.rx = sdrrx('Pluto', ...
                'RadioID',            'usb:0', ...
                'CenterFrequency',    params.CenterFrequency, ...
                'BasebandSampleRate', params.BasebandSampleRate, ...
                'GainSource',         'Manual', ...
                'Gain',               params.RxGain, ...
                'SamplesPerFrame',    params.SamplesPerFrame, ...
                'OutputDataType',     'double');
        end
        
        function rxBuffer = receiveFrames(obj)
            % rxBuffer boyutu: 65536 x N (numRXsampleblock)
            rxBuffer = zeros(obj.params.SamplesPerFrame, obj.params.numRXSampleBlock);
            
            disp(['📡 ', num2str(obj.params.numRXSampleBlock), ' frame alınıyor...']);
            
            for i = 1:obj.params.numRXSampleBlock
                rxData = obj.rx();  % Pluto'dan 65536 örnek al
                rxBuffer(:, i) = rxData;  % Her frame bir kolon
            end
            
            disp('✅ Alım tamamlandı. Boyut: ' + string(size(rxBuffer,1)) + ' x ' + string(size(rxBuffer,2)));
        end

        function rxData = receiveOneFrame(obj)
            rxData = obj.rx();
        end
        
        function setCenterFrequency(obj, freqHz)
            obj.rx.CenterFrequency = freqHz;
            fprintf('⚙️ Pluto Center Frequency %.3f MHz olarak ayarlandı.\n', freqHz/1e6);
        end
        
        function release(obj)
            release(obj.rx);
        end
    end
end
