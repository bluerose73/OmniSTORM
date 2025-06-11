classdef OmniImageLoader < handle
    %OMNIIMAGELOADER An image stack loader class.
    %   Supports:
    %   - single-file and multi-file image stack.
    %   - TIFF and DCIMG formats.
    %   
    %   Open an image stack by openImage(),
    %   or open a folder of image frames by openImageFolder().
    %   Then, load a range of frames using
    %   readFrameRange().
    %
    %   Example:
    %   loader = OmniImageLoader()
    %   loader.openImage('image.tif')
    %   numFrames = loader.totalFrames
    %   
    %   % Load all frames
    %   imageStack = loader.readFrameRange(1, totalFrames)
    %   % Load frames 100 - 200
    %   imageStack = loader.readFrameRange(100, 100)
    
    properties
        height
        width
        totalFrames
        imagePathList % List of path to each image file
        numFramesList % List of num_frames for each image file
    end
    
    methods
        
        function openImage(obj, imagePath)
            obj.imagePathList = string(imagePath);
            [obj.height, obj.width, obj.totalFrames] = get_image_stack_size_auto(imagePath);
            obj.numFramesList = obj.totalFrames;
        end

        function openImageFolder(obj, folderPath)
            % Get list of all .tif and .dcimg files in the selected directory
            tif_files = dir(fullfile(folderPath, '*.tif'));
            dcimg_files = dir(fullfile(folderPath, '*.dcimg'));
            
            % Combine the file structs and sort by filename
            all_files = [tif_files; dcimg_files];
            [~, idx] = sort({all_files.name});
            all_files = all_files(idx);

            % Check if there are no images
            if isempty(all_files)
                error('No .tif or .dcimg images found in the selected directory.');
            end

            % Get full paths of all image files
            obj.imagePathList = string(fullfile({all_files.folder}, {all_files.name}));
            
            % Get number of frames for each image file
            numFiles = numel(all_files);
            obj.numFramesList = zeros(1, numFiles);
            for i = 1:numFiles
                [obj.height, obj.width, obj.numFramesList(i)]...
                    = get_image_stack_size_auto(fullfile(all_files(i).folder, all_files(i).name));
            end
            
            % Calculate total frames
            obj.totalFrames = sum(obj.numFramesList);
        end

        function imageStack = readFrameRange(obj, startFrame, numFrames)
            if startFrame + numFrames - 1 > obj.totalFrames
            error(['Requested frame range exceeds the total number of frames. ', ...
                   'Total frames: %d, Start frame: %d, Number of frames: %d.'], ...
                   obj.totalFrames, startFrame, numFrames);
            end

            if startFrame <= 0 || numFrames <= 0
                error('startFrame and numFrames must be positive integers.');
            end
            
            fileId = 1;
            while startFrame > obj.numFramesList(fileId)
                startFrame = startFrame - obj.numFramesList(fileId);
                fileId = fileId + 1;
            end

            % Read from the first file
            numFramesFirstFile = min(numFrames, obj.numFramesList(fileId) - startFrame + 1);
            imageStackFirstFile = read_frame_range_auto( ...
                obj.imagePathList(fileId), startFrame, numFramesFirstFile);
            if numFramesFirstFile == numFrames
                imageStack = imageStackFirstFile;
                return
            end

            % Read the rest files
            imageStack = zeros(size(imageStackFirstFile, 1), size(imageStackFirstFile, 2), numFrames, 'like', imageStackFirstFile);
            imageStack(:, :, 1:numFramesFirstFile) = imageStackFirstFile;
            numFramesRead = numFramesFirstFile;

            while numFramesRead < numFrames
                fileId = fileId + 1;
                framesToRead = min(numFrames - numFramesRead, obj.numFramesList(fileId));
                imageStackCurrentFile = read_frame_range_auto( ...
                    obj.imagePathList(fileId), 1, framesToRead);
                imageStack(:, :, numFramesRead + 1:numFramesRead + framesToRead) = imageStackCurrentFile;
                numFramesRead = numFramesRead + framesToRead;
            end
        end
    end
end

