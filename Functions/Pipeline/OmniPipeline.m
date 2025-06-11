classdef OmniPipeline < handle
    %OMNIPIPELINE A pipeline for super-resolution processing
    %   Example usage:
    %   imageLoader = OmniImageLoader("path/to/image.tif");
    %   config = app.UI2Config();
    %   pipeline = OmniPipeline(imageLoader, config);
    %   while ~pipeline.isFinished
    %       pipeline.step();
    %   [SRImage, X, Y, F, intensity, drift] = pipeline.fetchResult();
    
    properties
        % input
        imageLoader
        config

        % state
        state = "initial"   % A counter of current step
        isFinished = false  % A flag to indicate if the pipeline has finished

        % progress indicators
        stepMessage % A indicator of what the pipeline is doing in the current step
        estimatedTotalSteps  % The total number of steps in the pipeline. Note that this is an estimate. Use isFinished to check if the pipeline has finished.

        % constants
        BATCH_SIZE = 100;
        PREALLOC_LOCALIZATIONS = 120000000;

        % intermediate results
        inputImage
        preprocessedImage
        startFrame         = 1
        numFramesToLoad    = 0
        numLocalizations   = 0
        
        % final results
        SRImage
        X
        Y
        F
        intensity
        drift
        background
    end
    
    methods
        function obj = OmniPipeline(imageLoader, config)
            %OMNIPIPELINE Construct an instance of this class
            %   Takes a OmniImageLoader and a config struct as input
            %   Refer OmniSTORM.mlapp UI2Config() for the config struct
            arguments
                imageLoader (1, 1) OmniImageLoader
                config (1, 1) struct
            end

            if config.params.range.enabled
                % Create a new OmniImageLoaderRangeView object
                obj.imageLoader = OmniImageLoaderRangeView(imageLoader, config.params.range.start, config.params.range.end);
                disp("Using a range view of the image loader");
                disp("Start frame: " + config.params.range.start);
                disp("End frame: " + config.params.range.end);
            else
                % Use the original image loader
                obj.imageLoader = imageLoader;
            end

            obj.config = config;
            obj.estimatedTotalSteps = obj.estimateTotalSteps();
        end
        
        function step(obj)
            %STEP Run one step of the pipeline
            %   One step is a flexible definition, depending on the super-resolution
            %   algorithm. For example, in most localization-based super-resolution
            %   algorithms, one step is 100 frames.

            if obj.isFinished
                error("Pipeline is finished. Cannot run step anymore.");
            end

            cfg = obj.config;

            if cfg.process.method == "Deconvolution"
                obj.deconvolutionStep();
            elseif cfg.process.method == "Localization"
                obj.localizationStep();
            else
                error("Unknown process type");
            end

        end

        function [SRImage, X, Y, F, intensity, drift, background] = fetchResult(obj)
            %FETCHRESULT Fetch the result of the pipeline
            %   Call this function after the pipeline is finished to get the result
            %   Pipeline is finished when isFinished is true
            SRImage = obj.SRImage;
            X = obj.X;
            Y = obj.Y;
            F = obj.F;
            intensity = obj.intensity;
            drift = obj.drift;
            background = obj.background;
        end
    end

    methods (Access = private)

        function totalSteps = estimateTotalSteps(obj)
            %ESTIMATETOTALSTEPS Estimate the total number of steps in the pipeline

            imgLoader = obj.imageLoader;
            cfg = obj.config;

            if cfg.process.method == "Deconvolution"
                totalSteps = 5;
            elseif cfg.process.method == "Localization"
                disp("total frames: " + imgLoader.totalFrames);
                totalSteps = ceil(imgLoader.totalFrames / obj.BATCH_SIZE) + 5;
            else
                error("Unknown process type");
            end
        end

        function deconvolutionStep(obj)
            %DECONVOLUTIONSTEP Run one step of the deconvolution pipeline
            %   Deconvolution loads all frames at once.
            %   This is because the temporal analysis requires all frames.
            %   In addition, deconvolution is slow,
            %   so if the frame number is too large to fit in memory,
            %   it is better not to run deconvolution.

            cfg = obj.config;
            imgLoader = obj.imageLoader;

            switch obj.state
                case "initial"
                    obj.stepMessage = "Loading all frames";
                    obj.state = "loading";
                case "loading"
                    obj.inputImage = imgLoader.readFrameRange(1, imgLoader.totalFrames);
                    obj.stepMessage = "Preprocessing";
                    obj.state = "preprocessing";
                case "preprocessing"
                    [obj.preprocessedImage, bg] = Preprocess(obj.inputImage, cfg);
                    if cfg.log.saveBackground
                        obj.background = bg;
                    end
                    obj.stepMessage = "Running deconvolution";
                    obj.state = "deconvolution";
                case "deconvolution"
                    obj.SRImage = ProcessDeconvolution(obj.preprocessedImage, cfg);
                    obj.stepMessage = "Post processing";
                    obj.state = "postprocessing";
                case "postprocessing"
                    obj.SRImage = Postprocess(obj.SRImage, cfg);
                    obj.X         = [];
                    obj.Y         = [];
                    obj.F         = [];
                    obj.intensity = [];
                    obj.drift     = [];
                    obj.isFinished = true;
                    obj.stepMessage = "Finished";
                    obj.state = "finished";
            end
        end

        function localizationStep(obj)
            %LOCALIZATIONSTEP Run one step of the localization pipeline
            % Localization-based methods load frames in a batch.

            cfg = obj.config;
            imgLoader = obj.imageLoader;
            numPreAlloc = obj.PREALLOC_LOCALIZATIONS;

            switch obj.state
                case "initial"
                    obj.stepMessage = "Allocating memory";
                    obj.state = "allocating";
                
                case "allocating"
                    obj.X = zeros(numPreAlloc, 1);
                    obj.Y = zeros(numPreAlloc, 1);
                    obj.F = zeros(numPreAlloc, 1);
                    obj.intensity = zeros(numPreAlloc, 1);
                    obj.startFrame = obj.startFrame - obj.BATCH_SIZE; % compensate for the first batch
                    [obj.startFrame, obj.numFramesToLoad] = obj.getNextBatchRange();
                    obj.stepMessage = obj.getProcessingFramesMessage();
                    obj.state = "localization";
                    if cfg.log.saveBackground
                        obj.background = zeros(imgLoader.height, imgLoader.width, imgLoader.totalFrames, "single");
                    end

                case "localization"
                    obj.inputImage = imgLoader.readFrameRange(obj.startFrame, obj.numFramesToLoad);

                    [obj.preprocessedImage, bg]= Preprocess(obj.inputImage, cfg);
                    if cfg.log.saveBackground
                        obj.background(:, :, obj.startFrame : obj.startFrame + obj.numFramesToLoad - 1) = bg;
                    end
                    [batchX, batchY, batchF, batchIntensity] = ProcessLocalization(obj.preprocessedImage, bg, cfg);
                    batchF = batchF + obj.startFrame - 1;
                    n = length(batchX);
                    obj.X((obj.numLocalizations+1):(obj.numLocalizations+n)) = batchX;
                    obj.Y((obj.numLocalizations+1):(obj.numLocalizations+n)) = batchY;
                    obj.F((obj.numLocalizations+1):(obj.numLocalizations+n)) = batchF;
                    obj.intensity((obj.numLocalizations+1):(obj.numLocalizations+n)) = batchIntensity;
                    obj.numLocalizations = obj.numLocalizations + n;

                    if obj.startFrame + obj.numFramesToLoad - 1 == imgLoader.totalFrames
                        obj.X         = obj.X(1:obj.numLocalizations);
                        obj.Y         = obj.Y(1:obj.numLocalizations);
                        obj.F         = obj.F(1:obj.numLocalizations);
                        obj.intensity = obj.intensity(1:obj.numLocalizations);
                        obj.stepMessage = "Drift correction";
                        obj.state = "drift-correction";
                    else
                        [obj.startFrame, obj.numFramesToLoad] = obj.getNextBatchRange();
                        obj.stepMessage = obj.getProcessingFramesMessage();
                    end

                case "drift-correction"
                    if cfg.process.sparse.aim
                        localizations(:, 1) = obj.F;
                        localizations(:, 2) = obj.X;
                        localizations(:, 3) = obj.Y;
                        [locAIM, obj.drift] = AIM(localizations, cfg.process.sparse.aimTrackInterval);
                        obj.F = locAIM(:, 1);
                        obj.X = locAIM(:, 2);
                        obj.Y = locAIM(:, 3);
                    else
                        obj.drift = [];
                    end
                    obj.stepMessage = "Rendering";
                    obj.state = "rendering";

                case "rendering"
                    obj.SRImage = RenderLocalizationToImage(obj.X, obj.Y, obj.F, obj.intensity, size(obj.inputImage, 1), size(obj.inputImage, 2), cfg);
                    obj.stepMessage = "Post processing";
                    obj.state = "postprocessing";
                    
                case "postprocessing"
                    obj.SRImage = Postprocess(obj.SRImage, cfg);
                    obj.isFinished = true;
                    obj.stepMessage = "Finished";
                    obj.state = "finished";
            end
        end

        function [startFrame, numFramesToLoad] = getNextBatchRange(obj)
            %GETNEXTBATCHRANGE Get the next batch range
            %   Returns the start frame and the number of frames to load in the next batch

            imgLoader = obj.imageLoader;
            batchSize = obj.BATCH_SIZE;

            startFrame = obj.startFrame + batchSize;
            numFramesToLoad = min(batchSize, imgLoader.totalFrames - startFrame + 1);
        end

        function message = getProcessingFramesMessage(obj)
            %GETPROCESSINGFRAMESMESSAGE Get the message of the current frames-processing step
            %   Returns a string indicating the frames being processed

            imgLoader = obj.imageLoader;

            message = "Processing frames " + obj.startFrame + ...
                " to " + (obj.startFrame + obj.numFramesToLoad - 1) + ...
                " of total " + imgLoader.totalFrames;
        end
    end
end

