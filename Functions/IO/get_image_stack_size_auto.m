function [height, width, numFrames] = get_image_stack_size_auto(imagePath)
%GET_NUM_FRAMES_AUTO Get number of frames of a TIF or DCIMG file.
    [~,~,ext] = fileparts(imagePath);
    if ext == ".tif"
        info = imfinfo(imagePath);  % Replace 'filename.tif' with your file path
        numFrames = numel(info);         % Number of frames in the TIFF image
        height = info(1).Height;
        width = info(1).Width;
    elseif ext == ".dcimg"
        [height, width, numFrames] = dcimg_get_size(imagePath);
    else
        error('Unsupported image format. "%s"', filename);
    end
end

