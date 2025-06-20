classdef OmniImageLoader < handle    %OMNIIMAGELOADER An image stack loader class.
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
    %   
    %   % Open folder with specific extensions
    %   loader.openImageFolder('/path/to/folder', {'.tif', '.jpg'})
    %   % or
    %   loader.openImageFolder('/path/to/folder', [".tif", ".jpg"])
    
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

        function openImageFolder(obj, folderPath, ext_name_list)
            % Get list of files with specified extensions in the selected directory
            % ext_name_list: cell array of extensions (e.g., {'.tif', '.tiff', '.dcimg'})
            %               or string array (e.g., [".tif", ".tiff", ".dcimg"])
            %               If not provided, defaults to {'.tif', '.tiff', '.dcimg'}
            
            if nargin < 3 || isempty(ext_name_list)
                ext_name_list = {'.tif', '.tiff', '.dcimg'};
            end
            
            % Convert to cell array if string array is provided
            if isstring(ext_name_list)
                ext_name_list = cellstr(ext_name_list);
            end
            
            % Ensure extensions start with a dot
            for i = 1:length(ext_name_list)
                if ~startsWith(ext_name_list{i}, '.')
                    ext_name_list{i} = ['.' ext_name_list{i}];
                end
            end
            
            % Get files for each extension
            all_files = [];
            for i = 1:length(ext_name_list)
                ext = ext_name_list{i};
                pattern = ['*' ext];
                files = dir(fullfile(folderPath, pattern));
                all_files = [all_files; files];
            end
            
            % Sort by filename
            if ~isempty(all_files)
                [~, idx] = sort({all_files.name});
                all_files = all_files(idx);
            end

            % Check if there are no images
            if isempty(all_files)
                ext_list_str = strjoin(ext_name_list, ', ');
                error('No images with extensions [%s] found in the selected directory.', ext_list_str);
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

