% Evaluates camera gain / offset estimation
% using simulation images generated with the tool
% SMIS (https://github.com/DominiqueBourgeois/SMIS)

% In SMIS EMCCD Setup, gain (ADU / photon) = QE * Gain * e_over_p / e_over_ADU 
%                      offset              = offset

clear
close all
clc

% Input parameters
img_stack_path = "C:\Users\25447\Desktop\shengjie\simulation\results\STORM 2D Alexa647 NoReadoutNoise\Test_ch1.tif";
num_frames_to_use = 10;
true_gain = 24;
true_offset = 500;
% End of input parameters

img_stack = read_tiff(img_stack_path);

for i = 1:num_frames_to_use
    [est_gain(i), est_offset(i)] = EstimateGainOffset(img_stack(:, :, i));
end

err_gain = est_gain - true_gain;
err_offset = est_offset - true_offset;

MAE_gain = mean(abs(err_gain))
MAE_offset = mean(abs(err_offset))