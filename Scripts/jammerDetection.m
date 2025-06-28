clear; clc; close all;

addpath('C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Utils');
addpath('C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Config');
addpath('C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Classes');

params = getParams();
params.SamplesPerFrame      = 4096;
params.BasebandSampleRate   = 4e6;

params.EnablePlot = false;  

plutoRX = OFDMPlutoRX(params);

jd = JammerDetection(params, plutoRX);

jd.calibrate();

jd.runDetection();