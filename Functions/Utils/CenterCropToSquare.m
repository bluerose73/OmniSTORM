function croppedImage = CenterCropToSquare(image)
    % centerCropToSquare - Center-crops a single-channel image to make it square
    %
    % Syntax:
    %   croppedImage = centerCropToSquare(image)
    %
    % Input:
    %   image - A 2D matrix representing the input image.
    %
    % Output:
    %   croppedImage - The center-cropped square image.

    % Get the dimensions of the input image
    [rows, cols] = size(image);

    % Determine the size of the square crop (the smaller of the two dimensions)
    cropSize = min(rows, cols);

    % Calculate the start indices for cropping
    rowStart = floor((rows - cropSize) / 2) + 1;
    colStart = floor((cols - cropSize) / 2) + 1;

    % Perform the center crop
    croppedImage = image(rowStart:rowStart + cropSize - 1, colStart:colStart + cropSize - 1);
end