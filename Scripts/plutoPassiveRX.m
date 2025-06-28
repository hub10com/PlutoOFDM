clc; clear;

addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Config\");
addpath("C:\Users\emreb\OneDrive\Belgeler\MATLAB\PlutoOFDM\Classes");

params = getParams();

rxObj = OFDMPlutoRX(params);

rxBuffer = rxObj.receiveFrames();  % MATLAB vektör — offline kullanılacak

rxObj.release();
