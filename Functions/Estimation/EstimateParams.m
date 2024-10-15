function params = EstimateParams(imageStack, config)
    params = config.params;
    
    if params.decorr
        params.resolutionPx = EstimateResolution(imageStack(:, :, 1));
    end

    if params.estimateGainOffset
        [params.gain, params.offset] = EstimateGainOffset(imageStack(:, :, 1));
    end

    if params.estimateThreshold
        params.threshold = EstimateThreshold(imageStack);
    end
end

