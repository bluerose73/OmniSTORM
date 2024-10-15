% Post deconvolution of the temporal std image

clc
clear
close all


folder_path = "..\data\high density SMLM-crop-deconv";
max_frames = 200;

output_dir = folder_path + "-post";
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

    img = imread(file_path);

    res = 
    sigma = res / 2.35;

    sr_start = tic;
    psf = fspecial('gaussian', ceil(sigma * 10 + 1), sigma);
    sr_img = deconvlucy(img, psf, 20);
    sr_interval = toc(sr_start);

    fprintf(log_file, "[ %s ]\n", filename);
    fprintf(log_file, "time = %f\n", sr_interval);
    fprintf(log_file, "resolution = %f\n\n", res);
    
    save_tiff(sr_img, fullfile(output_dir, name + "-post." + "tif"));
end