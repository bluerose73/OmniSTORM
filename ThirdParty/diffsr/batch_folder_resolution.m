clc
clear
close all


folder_path = "C:\Users\25447\Desktop\shengjie\superresolution\data\high density SMLM-crop";
max_frames = 200;
max_num_resolution_sample = 5;

output_dir = folder_path;
mkdir(output_dir);
log_file = fopen(fullfile(output_dir, "resolution-decorr.txt"), "w");


files = dir(folder_path);
for k = 1:length(files)
    filename = files(k).name;
    if strcmp(filename, '.') || strcmp(filename, '..')
        continue;
    end
    file_path = fullfile(folder_path, filename);
    [~,name,ext] = fileparts(filename);
    if ext == ".txt"
        continue;
    end

    img_stack = read_img_auto(file_path, max_frames);

    num_frames = size(img_stack, 3);
    num_resolution_sample = min(num_frames, max_num_resolution_sample);
    stride = floor(num_frames / num_resolution_sample);
    for i = 1:num_resolution_sample
        res(i) = decorr_resolution(img_stack(:, :, i * stride));
    end
    res = mean(res);
    sigma = res / 2.35;


    fprintf(log_file, "[ %s ]\n", filename);
    fprintf(log_file, "resolution = %f\n\n", res);
end