clc
clear
close all


file_path = "..\data\high density SMLM\V.tif";
max_frames = 200;
scale = 4;

img = read_img_auto(file_path, max_frames);

[res, gain, offset] = frc_pcfo(img);
sigma = res / 2.35;

sr_start = tic;
[sr_img, sr_img_stack] = deconv_temporalstd(img, scale, sigma, "fourier");
sr_interval = toc(sr_start);

