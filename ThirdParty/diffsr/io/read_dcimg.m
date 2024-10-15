function image_stack = read_dcimg(filename, max_frames)
    if nargin < 2
        max_frames = 1e9;
    end
    filename = char(filename);

    % Determine the number of frames
    [num_frames, rows, cols] = dcimg_get_size(filename);
    num_frames = min([num_frames, max_frames]);
    
    % Preallocate the 3D array
    sample_frame = dcimg_read_frame(filename, 1);
    image_stack = zeros(rows, cols, num_frames, class(sample_frame));
    
    % Read each frame and store it in the 3D array
    for k = 1:num_frames
        image_stack(:,:,k) = dcimg_read_frame(filename, k);
    end 

end