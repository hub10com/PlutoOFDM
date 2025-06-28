classdef OFDMPlutoTX < handle
    properties
        params
        tx
        txFrame
        isTransmitting = false;
    end
    
    methods
        function obj = OFDMPlutoTX(params)
            obj.params = params;
            
            obj.tx = sdrtx('Pluto', ...
                'RadioID',            'usb:0', ...
                'CenterFrequency',    params.CenterFrequency, ...
                'BasebandSampleRate', params.BasebandSampleRate, ...
                'Gain',               params.TxGain);
        end
        
        function startTransmission(obj, txFrame)
            obj.txFrame = txFrame;
            transmitRepeat(obj.tx, obj.txFrame)
            obj.isTransmitting = true;
            disp('▶️ TX STARTED (transmitRepeat running)...');
        end

        function transmitFrame(obj, txFrame)
            % Sadece 1 frame gönder (blocking)
            obj.tx(txFrame);
        end
        
        function mute(obj)
            if obj.isTransmitting
                obj.tx.Gain = -89.75; % Pluto min TX Gain (praktik mute)
                disp('🔇 TX MUTED');
            end
        end
        
        function unmute(obj)
            if obj.isTransmitting
                obj.tx.Gain = obj.params.TxGain;
                disp('🔊 TX UNMUTED');
            end
        end
        
        function stopTransmission(obj)
            release(obj.tx);
            obj.isTransmitting = false;
            disp('⏹️ TX STOPPED (Pluto released)');
        end
        
        function release(obj)
            release(obj.tx);
            obj.isTransmitting = false;
            disp('🔻 TX Released');
        end
    end
end
