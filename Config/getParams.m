function params = getParams()

    % --- OFDM Parametreleri ---
    params.FFTLength            = 64;
    params.CyclicPrefixLength   = 16;
    params.NumGuardBandCarriers = [6; 5];  
    params.NumDataCarriers      = 48;
    params.PilotCarrierIndices  = [12; 26; 40; 54];
    params.NumPilotCarriers     = length(params.PilotCarrierIndices);

    % --- Frame Parametreleri ---
    params.NumDataSymbols       = 45;  % Veri symbol sayısı
    params.TotalSymbols         = 1 + params.NumDataSymbols;  % 1 L-SIG + Veri
    params.SamplesPerFrame      = 65536;

    % --- Pluto SDR ---
    params.CenterFrequency      = 2.404e9;    % 2.410 GHz
    params.BasebandSampleRate   = 3e6;        % 3 MHz
    params.TxGain               = 0;          % dB
    params.RxGain               = 40;         % dB

    params.numRXSampleBlock     = 10;
    params.frameLength          = 4000;

    % --- Modülasyon Türü ---
    params.Modulation           = '64QAM';   % 'BPSK' | 'QPSK' | '16QAM' | '64QAM'

    params.pattern = [1 3 5 4 2];
    params.numDetectionFrames = 2000;
    params.CalibrationDuration = 10;     
    params.JammerFrameCount    = 10;    


    % --- Debug ---
    params.EnablePlot           = true;

end
