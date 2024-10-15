% Remove background of an image stack,
% by subtracting temporal min.
% Good for sparse molecules.

function result = background_removal_temporal_min(image_stack)
    blurred = imgaussfilt(image_stack, 2);
    temporal_min = min(blurred, [], 3);
    result = image_stack - temporal_min * 1.1;
    result = max(result, 0);
end