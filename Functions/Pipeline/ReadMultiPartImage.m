% Reads an image stack that is stored in many files,
% Like image_001.tif image_002.tif, ...
% Accepted formats are *.tif and *.dcimg
function result = ReadMultiPartImage(folderPath)
    tifFiles = dir(fullfile(folderPath, '*.tif'));
    dcimgFiles = dir(fullfile(folderPath, '*.dcimg'));
    allFiles = [tifFiles; dcimgFiles];
    [~, sortedIndex] = sort({allFiles.name});
    sortedFiles = allFiles(sortedIndex);

    % TODO(Shengjie)
    % This image reading can be further optimized
    % by pre-allocating "result".
    frameCnt = 0;
    for i = 1: length(sortedFiles)
        partPath = fullfile(folderPath, sortedFiles(i).name);
        imagePart = read_img_auto(partPath);
        result(:, :, 1 + frameCnt: frameCnt + size(imagePart, 3)) = imagePart;
        frameCnt = frameCnt + size(imagePart, 3);
    end

    result = double(result);
end