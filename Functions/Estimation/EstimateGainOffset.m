function [gain, offset] = EstimateGainOffset(image)
    [gain, offset] = pcfo(image, 0.9, 0, [3 3], 0);
end

