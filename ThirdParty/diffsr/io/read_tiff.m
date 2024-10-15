function image_stack = read_tiff(filename, max_frames)
    if nargin < 2
        max_frames = 1e9;
    end

    % Determine the number of frames
    info = imfinfo(filename);
    num_frames = numel(info);
    num_frames = min([num_frames, max_frames]);
    
    % Preallocate the 3D array
    sample_image = imread(filename, 1);
    [rows, cols] = size(sample_image);
    image_stack = zeros(rows, cols, num_frames, class(sample_image));
    
    % Read each frame and store it in the 3D array
    for k = 1:num_frames
        image_stack(:,:,k) = imread(filename, k);
    end 

end