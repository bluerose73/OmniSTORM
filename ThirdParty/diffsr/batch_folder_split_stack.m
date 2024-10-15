% Split image stack in half: odd indices and even indices.
% Then we can use them to generate 2 super resolution images for FRC
% resolution

clc
clear
close all

folder_path = "..\data\line-preprocess-no-abs";
output_dir = folder_path + "-split";


mkdir(output_dir);
files = dir(folder_path);
for k = 1:length(files)
    filename = files(k).name;
    if strcmp(filename, '.') || strcmp(filename, '..')
        continue;
    end
    file_path = fullfile(folder_path, filename);
    [~,name,ext] = fileparts(filename);
    if ext ~= ".tif" && ext ~= ".dcimg"
        continue;
    end

    % process one image
    img = read_img_auto(file_path);
    odd_frames = img(:, :, 1:2:end);
    even_frames = img(:, :, 2:2:end);

    save_tiff(odd_frames, fullfile(output_dir, name + "-odd.tif"));
    save_tiff(even_frames, fullfile(output_dir, name + "-even.tif"))
end