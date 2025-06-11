classdef OmniImageLoaderRangeView < handle
    %OMNIIMAGELOADERRANGEVIEW An image stack loader class.
    %
    %   A ranged view of the OmniImageLoader class. Init by passing in an OmniImageLoader object and [start, end] frame range.
    %   It can supports readFrameRange() and has all the properties of OmniImageLoader.   
    %   However, it does not support openImage() and openImageFolder().
    
    properties
        % Properties inherited from OmniImageLoader
        height
        width
        totalFrames
        imagePathList % List of path to each image file
        numFramesList % List of num_frames for each image file

        % Properties specific to this class
        startFrame
        endFrame
        imageLoader % The OmniImageLoader object
    end
    
    methods
        function obj = OmniImageLoaderRangeView(imageLoader, startFrame, endFrame)
            % Constructor for the OmniImageLoaderRangeView class.
            % Initializes the object with the specified image loader and frame range.

            % Round to integer
            startFrame = round(startFrame);
            endFrame = round(endFrame);

            % Clamp to [1, totalFrames]
            totalFrames = imageLoader.totalFrames;
            origStart = startFrame;
            origEnd = endFrame;
            if startFrame < 1
                warning('startFrame (%d) < 1. Clamping to 1.', origStart);
                startFrame = 1;
            end
            if endFrame > totalFrames
                warning('endFrame (%d) > totalFrames (%d). Clamping to %d.', origEnd, totalFrames, totalFrames);
                endFrame = totalFrames;
            end
            if endFrame < 1
                warning('endFrame (%d) < 1. Clamping to 1.', origEnd);
                endFrame = 1;
            end
            if startFrame > totalFrames
                warning('startFrame (%d) > totalFrames (%d). Clamping to %d.', origStart, totalFrames, totalFrames);
                startFrame = totalFrames;
            end
            if startFrame > endFrame
                warning('startFrame (%d) > endFrame (%d). Keeping only 1 frame at startFrame.', startFrame, endFrame);
                endFrame = startFrame;
            end

            obj.imageLoader = imageLoader;
            obj.startFrame = startFrame;
            obj.endFrame = endFrame;

            % Set properties based on the image loader
            obj.height = imageLoader.height;
            obj.width = imageLoader.width;
            obj.totalFrames = endFrame - startFrame + 1;
            obj.imagePathList = imageLoader.imagePathList;
            obj.numFramesList = imageLoader.numFramesList;
        end

        function imageStack = readFrameRange(obj, startFrame, numFrames)
            % Map the requested range to the underlying imageLoader's frame indices
            % Clamp startFrame and numFrames to the available range in this view
            if nargin < 3
                error('readFrameRange requires startFrame and numFrames.');
            end

            % Clamp startFrame to [1, obj.totalFrames]
            if startFrame < 1
                warning('startFrame (%d) < 1. Clamping to 1.', startFrame);
                startFrame = 1;
            end
            if startFrame > obj.totalFrames
                error('startFrame (%d) > totalFrames (%d) in this view.', startFrame, obj.totalFrames);
            end

            % Clamp numFrames so we don't exceed the view's range
            maxFrames = obj.totalFrames - startFrame + 1;
            if numFrames > maxFrames
                warning('numFrames (%d) exceeds available frames in this view. Clamping to %d.', numFrames, maxFrames);
                numFrames = maxFrames;
            end
            if numFrames < 1
                error('numFrames must be >= 1.');
            end

            % Map to the underlying loader's frame indices
            globalStartFrame = obj.startFrame + startFrame - 1;
            imageStack = obj.imageLoader.readFrameRange(globalStartFrame, numFrames);
        end
    end
end

