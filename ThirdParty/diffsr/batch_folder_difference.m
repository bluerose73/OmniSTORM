% Background removal + pair-wise frame difference

clc
clear
close all

folder_path = "..\data\line-preprocess";
output_dir = folder_path + "-no-abs";


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

    % process one image
    img = read_img_auto(file_path);
    img = background_removal_temporal_min(img);
    result = pairwise_frame_difference(img);

    save_tiff(result, fullfile(output_dir, name + "-pairwise-diff." + "tif"));
end