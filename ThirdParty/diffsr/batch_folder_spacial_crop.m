clc
clear
close all


folder_path = "..\data\lines_compare";
max_frames = 20;

output_dir = folder_path + "-crop";
mkdir(output_dir);
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

    img = read_img_auto(file_path, max_frames);
    height = size(img, 1);
    width = size(img, 2);
    save_tiff(img(1:height/2, 1:width/2, :), fullfile(output_dir, name + "." + "tif"))
end