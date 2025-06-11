% Evaluates decorr resolution estimation
% using simulation images generated with the tool
% SMIS (https://github.com/DominiqueBourgeois/SMIS)

clear
close all

% Input parameters
img_stack_path = "E:\omnistorm\simulation\basic_storm\Test_ch1.tif";
num_frames_to_use = 20;
true_resolution = 270.01; % FWHM in nanometer
pixel_size = 100;
% End of input parameters

img_stack = read_tiff_frame_range(img_stack_path, 1, num_frames_to_use);

for i = 1:num_frames_to_use
    est_resolution(i) = EstimateResolution(img_stack(:, :, i)) * pixel_size;
end

err = est_resolution - true_resolution;

MAE = mean(abs(err));
avg_est_res = mean(est_resolution);
