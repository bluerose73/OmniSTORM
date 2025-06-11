function imageStack = read_frame_range_auto(filename, startFrame, numFrames)
    %READ_FRAME_RANGE_AUTO Summary of this function goes here
    %   Detailed explanation goes here
    [~,~,ext] = fileparts(filename);
    
    if ext == ".tif"
        imageStack = read_tiff_frame_range(filename, startFrame, numFrames);
    elseif ext == ".dcimg"
        imageStack = dcimg_read_frame_range(char(filename), startFrame, numFrames);
    else
        error('Unsupported image format. "%s"', filename);
    end
end

