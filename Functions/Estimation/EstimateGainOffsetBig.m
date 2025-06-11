function [gain, offset] = EstimateGainOffsetBig(imageStack)
    desiredSize = 1024;
    
    imgHeight = size(imageStack, 1);
    imgWidth = size(imageStack, 2);
    nFrames = size(imageStack, 3);

    % nGridRows = ceil(desiredSize / imgHeight);
    % nGridCols = ceil(desiredSize / imgWidth);
    nGridRows = 3;
    nGridCols = 3;
    nFramesRequired = nGridRows * nGridCols;

    if nFrames < nFramesRequired
        disp("EstimateGainOffsetBig: Not enough frames in the image stack. Expected " + string(nFramesRequired) + " frames, but got " + string(nFrames) + " frames.");
        disp("Using less frames for estimation. The result may be inaccurate.");

        % Find the largest square number less than nFrames
        nGridRows = floor(sqrt(nFrames));
        nGridCols = nGridRows;
    end

    stitchedImageHeight = nGridRows * imgHeight;
    stitchedImageWidth = nGridCols * imgWidth;

    stitchedImage = zeros(stitchedImageHeight, stitchedImageWidth);

    % Fill the stitchedImage with frames from imageStack
    frameIndex = 1;
    for row = 1:nGridRows
        for col = 1:nGridCols
            stitchedImage((row-1)*imgHeight+1:row*imgHeight, (col-1)*imgWidth+1:col*imgWidth) = imageStack(:,:,frameIndex);
            frameIndex = frameIndex + 1;
        end
    end

    [gain, offset] = pcfo(stitchedImage, 1);
end