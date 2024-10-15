clc
clear
close all

src_path = "..\data\high density SMLM";
tgt_path = "..\data\high density SMLM-oneframe";
max_frames = 1;


files = dir(src_path);
for k = 1:length(files)
    filename = files(k).name;
    if strcmp(filename, '.') || strcmp(filename, '..')
        continue;
    end
    src_img_path = fullfile(src_path, filename);
    img = read_img_auto(src_img_path, max_frames);

    [~, name, ~] = fileparts(filename);
    tgt_img_path = fullfile(tgt_path, name + ".tif");
    jmg = read_img_auto(tgt_img_path, max_frames);

    if ~isequal(img, jmg)
        error('image unequal %s', filename);
    end
end