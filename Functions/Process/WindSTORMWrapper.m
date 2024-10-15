function [X, Y, F, intensity] = WindSTORMWrapper(inputImage, background, config)
    inputImage = double(inputImage);
    Sigma = config.params.resolutionPx / 2.35;
    minIntensity = config.params.threshold * 2 * pi * Sigma * Sigma;

    % wind deconvolution and peak finding
    [imDeconv, imPeak] = WindDeconv(inputImage, Sigma, background, minIntensity);
    
    % WindSTORM step 2: Emitter extraction and localization
    % emitter extraction
    [ROI, ROIsub ,IDs, x0, y0] = ExtractROIs(imDeconv, imPeak, inputImage, Sigma);
    
    % emitter localization
    [Y, X, intensity, F] = GradientFit(ROI, ROIsub, IDs, x0, y0);
end

