function largeImage = tileImages(imageStack, n)
    % tileImages: Tiles a stack of images into a larger n x n image.
    % 
    % Inputs:
    %   - imageStack: A 3D array of size h x w x f, where f is the number of frames
    %   - n: The number of rows and columns for the tiled output
    %
    % Output:
    %   - largeImage: A 2D matrix representing the tiled image
    
    % Get the size of individual images
    [h, w, f] = size(imageStack);
    
    % Check if there are enough frames to fill the grid
    if f < n^2
        error('The number of frames (%d) is less than n^2 (%d).', f, n^2);
    end
    
    % Initialize the large image
    largeImage = zeros(h * n, w * n);
    
    % Fill in the large image with frames from the stack
    for i = 1:n^2
        % Determine row and column in the grid
        row = ceil(i / n);
        col = mod(i-1, n) + 1;
        
        % Calculate the position in the large image
        rowStart = (row - 1) * h + 1;
        rowEnd = row * h;
        colStart = (col - 1) * w + 1;
        colEnd = col * w;
        
        % Place the current image into the large image
        largeImage(rowStart:rowEnd, colStart:colEnd) = imageStack(:, :, i);
    end
end
