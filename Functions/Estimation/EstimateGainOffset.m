function [gain, offset] = EstimateGainOffset(image)
    [gain, offset] = pcfo(image, 0.9);
end

