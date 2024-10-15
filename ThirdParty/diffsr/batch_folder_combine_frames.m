% Combine contiguous 5 frames into one, by averaging.

clc
clear
close all

folder_path = "..\data\high density SMLM";
output_dir = folder_path + "-5in1";
window_size = 5;


mkdir(output_dir);
files = dir(folder_path);
for k = 1:length(files)
    filename = files(k).name;
    if strcmp(filename, '.') || strcmp(filename, '..')
        continue;
    end
    file_path = fullfile(folder_path, filename);
    [~,name,ext] = fileparts(filename);

    img = read_img_auto(file_path);

    result = combine_frames(img, window_size);

    save_tiff(result, fullfile(output_dir, name + "." + "tif"));
end