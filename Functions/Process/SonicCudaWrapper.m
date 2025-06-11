function [X, Y, F, intensity] = SonicCudaWrapper(inputImage, background, config)
    inputImage = single(inputImage);
    inputImage(inputImage<0) = 0;
    background = single(background);
    threshold = config.params.threshold;
    ignore_border_px = 15;

    [X, Y, F] = sonic_cuda(inputImage, background, threshold, ignore_border_px);
    
    Pnum = numel(X);
    intensity = ones(Pnum, 1);
end
