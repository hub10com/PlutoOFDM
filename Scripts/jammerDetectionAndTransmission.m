%% mainFHSSJammerDetection.m
clc; clear; close all;

addpath('C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Classes\');
addpath('C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Utils');
addpath('C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Config');

%% RX Parametreleri (Jammer Detection için)
paramsRX = getParams();

paramsRX.SamplesPerFrame      = 4096;
paramsRX.BasebandSampleRate   = 4e6;  % 4 MHz RX — Jammer genişliği
paramsRX.CalibrationDuration  = 10;   % saniye
paramsRX.numDetectionFrames   = 300;
paramsRX.JammerFrameCount     = 5;
paramsRX.pattern              = [1 3 5 4 2];
paramsRX.EnablePlot           = false;

%% Pluto RX oluştur
plutoRX = OFDMPlutoRX(paramsRX);

%% JammerDetection objesi
jd = JammerDetection(paramsRX, plutoRX);

%% Kalibrasyon
jd.calibrate();

%% Detection
jd.runDetection();

%% TX Parametreleri (FHSS Gönderim için)
paramsTX = getParams();
paramsTX.BasebandSampleRate   = 3e6;   % 3 MHz TX bandwidth — FHSS gönderim için

%% FHSS Transmitter ayarları
centerFreqs = [2.404e9, 2.416e9];
durations   = [3, 2];  % saniye

%% FHSS Transmitter objesi
fhssTX = OFDMFHSSTransmitter(paramsTX, centerFreqs, durations);

%% Başlat (PatternLoop → gönderim)
fhssTX.start(jd);
