clc
clear
close all


folder_path = "C:\Users\25447\Desktop\shengjie\superresolution\data\high density SMLM-crop";
max_frames = 200;
scale = 4;
num_resolution_sample = 5;

output_dir = folder_path + "-deconv-first";
mkdir(output_dir);
log_file = fopen(fullfile(output_dir, "log.txt"), "w");

files = dir(folder_path);
for k = 1:length(files)
    filename = files(k).name;
    if strcmp(filename, '.') || strcmp(filename, '..')
        continue;
    end
    file_path = fullfile(folder_path, filename);
    [~,name,ext] = fileparts(filename);

    img_stack = read_img_auto(file_path, max_frames);

    num_frames = size(img_stack, 3);
    stride = floor(num_frames / num_resolution_sample);
    for i = 1:num_resolution_sample
        [res(i), gain(i), offset(i)] = frc_pcfo(img_stack(:, :, i * stride));
    end
    res = mean(res);
    gain = mean(gain);
    offset = mean(offset);
    sigma = res / 2.35;

    sr_start = tic;
    [sr_img, std_img, sr_img_stack] = deconv_temporalstd(img_stack, scale, sigma, "fourier", 1);
    sr_interval = toc(sr_start);

    fprintf(log_file, "[ %s ]\n", filename);
    fprintf(log_file, "time = %f\n", sr_interval);
    fprintf(log_file, "resolution = %f\n\n", res);
    
    save_tiff(sr_img, fullfile(output_dir, name + "." + "tif"));
    save_tiff(std_img, fullfile(output_dir, name + "-std." + "tif"));
    save_tiff(sr_img_stack(:, :, 1:20), fullfile(output_dir, name + "-stack." + "tif"));
end