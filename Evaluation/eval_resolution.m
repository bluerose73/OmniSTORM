% Evaluates decorr resolution estimation
% using simulation images generated with the tool
% SMIS (https://github.com/DominiqueBourgeois/SMIS)

% Input parameters
img_stack_path = "C:\Users\25447\Desktop\shengjie\simulation\results\STORM 2D Alexa647 PixelSize100\Test_ch1.tif";
num_frames_to_use = 30;
true_resolution = 270.01; % FWHM in nanometer
pixel_size = 100;
% End of input parameters

img_stack = read_tiff(img_stack_path);

for i = 1:num_frames_to_use
    est_resolution(i) = EstimateResolution(img_stack(:, :, i)) * pixel_size;
end

err = est_resolution - true_resolution;

MAE = mean(abs(err))