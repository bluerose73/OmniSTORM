clc
clear
close all


folder_path = "..\data\high density SMLM-5in1";
max_frames = 20;

output_dir = folder_path + "-20frame";
mkdir(output_dir);
files = dir(folder_path);
for k = 1:length(files)
    filename = files(k).name;
    if strcmp(filename, '.') || strcmp(filename, '..')
        continue;
    end
    file_path = fullfile(folder_path, filename);
    [~,name,ext] = fileparts(filename);

    img = read_img_auto(file_path, max_frames);
    save_tiff(img, fullfile(output_dir, name + "." + "tif"))
end