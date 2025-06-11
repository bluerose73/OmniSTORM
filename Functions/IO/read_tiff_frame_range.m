function imageStack = read_tiff_frame_range(filename, startFrame, numFrames)
    info = imfinfo(filename);
    totalFrames = numel(info);

    if startFrame < 1 || startFrame > totalFrames
        error('Start frame is out of range.');
    end

    endFrame = min(startFrame + numFrames - 1, totalFrames);
    numFramesToRead = endFrame - startFrame + 1;

    % Pre-allocate the imageStack array
    sampleFrame = imread(filename, startFrame, 'Info', info);
    [height, width] = size(sampleFrame);
    imageStack = zeros(height, width, numFramesToRead, 'like', sampleFrame);

    % Assign the first frame to the imageStack
    imageStack(:, :, 1) = sampleFrame;

    for k = 2:numFramesToRead
        frame = imread(filename, startFrame + k - 1, 'Info', info);
        imageStack(:, :, k) = frame;
    end
end
