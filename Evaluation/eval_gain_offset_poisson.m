clear
close all

rows = 80;
cols = 60;

img = poisson_matrix(rows, cols, 24, 40);
img = img * 0.12;
img = img + 500;

%   k_thres = 0.9
%   RNStd = 0;
%   AvoidCross = 1
%   doPlot = 0
%   Tiles = [3 3]

[gain, offset] = pcfo(img, 1.1);


disp("gain = " + string(gain));
disp("offset = " + string(offset));