function thresh = EstimateThreshold(imageStack)
    % Estimate threshold by 1/4 of the 90% intensity
    nFrames = size(imageStack, 3);
    step = max(floor(nFrames / 5), 1);
    sampledImageStack = imageStack(:, :, 1:step:nFrames);
    pixels = sampledImageStack(:);
    sorted = sort(pixels);
    thresh = sorted(floor(0.9 * numel(sorted))) / 4;
end