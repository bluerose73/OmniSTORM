% Evaluates camera gain / offset estimation
% using simulation images generated with the tool
% SMIS (https://github.com/DominiqueBourgeois/SMIS)

% In SMIS EMCCD Setup, gain (ADU / photon) = QE * Gain * e_over_p / e_over_ADU 
%                      offset              = offset

clear
close all

% img_stack_path = "E:\omnistorm\simulation\basic_storm\Test_ch1.tif";
% num_frames_to_use = 100;
% true_gain = 24;
% true_offset = 500;

% Input parameters
% img_stack_path = "E:\omnistorm\simulation\basic_palm_microtubules\Test_ch1.tif";
% num_frames_to_use = 100;
% true_gain = 0.12;
% true_offset = 500;
% End of input parameters


img_stack_path = "E:\omnistorm\simulation\qpalm_emos4b\11d_ch1.tif";
num_frames_to_use = 100;
true_gain = 0.12;
true_offset = 500;

img_stack = read_tiff_frame_range(img_stack_path, 700, num_frames_to_use);
% print image stack size: 80, 60, 100
disp("Image stack size: " + mat2str(size(img_stack)));

img_var = var(double(img_stack(:)));
disp("Image variance: " + string(img_var));
img_mean_calibrated = mean(double(img_stack(:) - 500));
disp("Offset-calibrated image mean: " + string(img_mean_calibrated));

img_stack = double(img_stack);

%% calc normal gain offset
% img1 = img_stack(:, :, 1);
% % imagesc(img1);
% % img1 = CenterCropToSquare(img1);
% [gain, offset] =  pcfo(img1, 1.1);
% disp("NORMAL: gain = " + string(gain) + ", offset = " + string(offset));

% %% calc temporal sum gain offset
% img_combined = sum(img_stack(:, :, 1:100), 3);
% [gain, offset] =  pcfo(img_combined, 1.1);
% disp("SUM: gain = " + string(gain) + ", offset = " + string(offset));


%% calc more gain offset

num_samples = 20;

for i = 1:num_samples
    [est_gain(i), est_offset(i)] = EstimateGainOffset(img_stack(:, :, i + 80));
end


err_gain = est_gain - true_gain;
err_offset = est_offset - true_offset;

MAE_gain = mean(abs(err_gain))
MAE_offset = mean(abs(err_offset))

mean_est_gain = mean(est_gain)
mean_est_offset = mean(est_offset)


% for i = 1:num_samples
%     [est_gain(i), est_offset(i)] = EstimateGainOffsetStack(img_stack(:, :, (i - 1) * 10 + 1 : i * 10));
% end

% err_gain = est_gain - true_gain;
% err_offset = est_offset - true_offset;

% MAE_gain = mean(abs(err_gain))
% MAE_offset = mean(abs(err_offset))

% mean_est_gain = mean(est_gain)
% mean_est_offset = mean(est_offset)