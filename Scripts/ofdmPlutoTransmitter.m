clc; clear;

addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Config\");
addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Classes");

% --- Parametreler ---
params = getParams();

% --- Nesneler ---
preambleBuilder   = OFDMPreambleBuilder(params);
frameDataBuilder  = FrameDataBuilder(params);
modulationMapper  = ModulationMapper(params);
ofdmFrameGen      = OFDMFrameGenerator(params, frameDataBuilder, modulationMapper);
txObj             = OFDMPlutoTX(params);

% --- Frame üretimi ve gönderim ---
txFrame = ofdmFrameGen.generateOFDMFrame(preambleBuilder);

txObj.startTransmission(txFrame);

disp('✅ OFDM frame gönderildi.');
