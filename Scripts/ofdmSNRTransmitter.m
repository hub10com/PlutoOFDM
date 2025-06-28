clc; clear;

addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Config\");
addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Classes\");

params = getParams();

preambleBuilder   = OFDMPreambleBuilder(params);
frameDataBuilder  = FrameDataBuilder(params);
modulationMapper  = ModulationMapper(params);
ofdmFrameGen      = OFDMFrameGenerator(params, frameDataBuilder, modulationMapper);
txObj             = OFDMPlutoTX(params);

txFrame = ofdmFrameGen.generateOFDMFrame(preambleBuilder);

% --- Frame süresi:
framesPerBurst = 200;

disp('🚀 Başlatıldı: 1 sn TX → 1 sn OFF döngüsü...');

for iter = 1:1000
    disp(['📡 TX ON (iter ' num2str(iter) ')']);
    for k = 1:framesPerBurst
        txObj.transmitFrame(txFrame);
    end

    disp('🛑 TX OFF');
    pause(1);
end

txObj.release();
