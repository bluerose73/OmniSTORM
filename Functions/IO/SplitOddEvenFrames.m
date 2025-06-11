function [oddFramesLoader, evenFramesLoader] = SplitOddEvenFrames(imageLoader, cacheDir)
%SPLITODDEVENFRAMES Split the frames of an image loader into odd and even frames
%   cacheDir: Directory to save the split images
%   Returns two OmniImageLoader objects, one for odd frames and one for even frames

    % Create cache directory if it doesn't exist
    if ~exist(cacheDir, 'dir')
        mkdir(cacheDir);
    end
    if ~exist(fullfile(cacheDir, 'odd_frames'), 'dir')
        mkdir(fullfile(cacheDir, 'odd_frames'));
    end
    if ~exist(fullfile(cacheDir, 'even_frames'), 'dir')
        mkdir(fullfile(cacheDir, 'even_frames'));
    end
    
    BATCH_SIZE = 2000;
    
    % Save odd and even frames to cache
    for start = 1:BATCH_SIZE:imageLoader.totalFrames
        endFrame = min(start + BATCH_SIZE - 1, imageLoader.totalFrames);
        frames = imageLoader.readFrameRange(start, endFrame - start + 1);
        
        oddFrames = frames(:, :, 1:2:end);
        evenFrames = frames(:, :, 2:2:end);
        
        oddFramesPath = fullfile(cacheDir, 'odd_frames', sprintf('%05d-%05d.tif', start, endFrame));
        evenFramesPath = fullfile(cacheDir, 'even_frames', sprintf('%05d-%05d.tif', start, endFrame));

        save_tiff(oddFrames, oddFramesPath);
        save_tiff(evenFrames, evenFramesPath);
    end

    % Create image loaders for odd and even frames
    oddFramesLoader = OmniImageLoader();
    oddFramesLoader.openImageFolder(fullfile(cacheDir, 'odd_frames'));
    evenFramesLoader = OmniImageLoader();
    evenFramesLoader.openImageFolder(fullfile(cacheDir, 'even_frames'));
    
end

