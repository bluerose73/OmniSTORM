clc
clear
close all

sigma = 1.928;

% 200 frames, fourier, with background suppression
image_stack = read_tiff('..\data\high density SMLM-5in1-200frame\MT_ROI_2.tif', 200);

image_stack = background_removal_temporal_min(image_stack);

[finalsr, aggsr, interp_stack, deconv_stack] = deconv_temporalstd(image_stack, 2, sigma, 'fourier');

save_tiff(finalsr.mean, '..\data\MT_ROI\MT_ROI_2.mean.final.tif');
save_tiff(finalsr.std, '..\data\MT_ROI\MT_ROI_2.std.final.tif');
save_tiff(aggsr.mean, '..\data\MT_ROI\MT_ROI_2.mean.tif');
save_tiff(aggsr.std, '..\data\MT_ROI\MT_ROI_2.std.tif');
save_tiff(interp_stack, '..\data\MT_ROI\MT_ROI_2.frame.interp.tif');
save_tiff(deconv_stack, '..\data\MT_ROI\MT_ROI_2.frame.deconv.tif');
disp('200 fourier done');


% % 200 frames, no scaling
% [finalsr, aggsr, interp_stack, ~] = deconv_temporalstd(image_stack, 1, sigma, 'fourier');
% 
% save_tiff(finalsr.mean, '..\data\MT_ROI_2.noscaling.mean.final.tif');
% save_tiff(finalsr.std, '..\data\MT_ROI_2.noscaling.std.final.tif');
% save_tiff(aggsr.mean, '..\data\MT_ROI_2.noscaling.mean.tif');
% save_tiff(aggsr.std, '..\data\MT_ROI_2.noscaling.std.tif');
% save_tiff(interp_stack, '..\data\MT_ROI_2.noscaling.frame.interp.tif');
% disp('200 no scaling done');
% 
% 
% % 200 frames, bicubic
% [finalsr, aggsr, interp_stack, ~] = deconv_temporalstd(image_stack, 4, sigma, 'bicubic');
% 
% save_tiff(finalsr.mean, '..\data\MT_ROI_2.bicubic.mean.final.tif');
% save_tiff(finalsr.std, '..\data\MT_ROI_2.bicubic.std.final.tif');
% save_tiff(aggsr.mean, '..\data\MT_ROI_2.bicubic.mean.tif');
% save_tiff(aggsr.std, '..\data\MT_ROI_2.bicubic.std.tif');
% save_tiff(interp_stack, '..\data\MT_ROI_2.bicubic.frame.interp.tif');
% disp('200 bicubic done');

% % 1000 frames
% image_stack = read_tiff('..\data\high density SMLM\MT_ROI_2.tif', 1000);
% 
% [finalsr, aggsr, interp_stack, deconv_stack] = deconv_temporalstd(image_stack, 1, sigma, 'fourier');
% 
% save_tiff(deconv_stack, '..\data\MT_ROI_2.1000.stack.tif')

% save_tiff(finalsr.mean, '..\data\MT_ROI_2.1000.mean.final.tif');
% save_tiff(finalsr.std, '..\data\MT_ROI_2.1000.std.final.tif');
% save_tiff(aggsr.mean, '..\data\MT_ROI_2.1000.mean.tif');
% save_tiff(aggsr.std, '..\data\MT_ROI_2.1000.std.tif');