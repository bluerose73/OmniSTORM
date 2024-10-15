% Read an image stack file into 3d array
% Automatically detects format based on filename

function image_stack = read_img_auto(filename, max_frames)
    if nargin < 2
        max_frames = 1e9;
    end
    
    [~,~,ext] = fileparts(filename);
    if ext == ".tif"
        image_stack = read_tiff(filename, max_frames);
    elseif ext == ".dcimg"
        image_stack = read_dcimg(filename, max_frames);
    else
        error('Unsupported image format. "%s"', filename);
    end
    
end