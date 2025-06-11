% Estimate gain offset from a stack of 10 images
%   The pcfo function estimates the gain and offset by fitting a line to the variance / mean of the noise in the image
%   The noise is extracted from image by a high-pass filter
%   In a single frame, it is possible that the high-frequency signal of the image is strong,
%   which can lead to difficulties in separating the noise from the signal
%   By summing multiple frames, the high-frequency signal is reduced, and the noise can be estimated more accurately
function [gain, offset] = EstimateGainOffsetStack(img_stack)
    NUM_FRAMES_TO_USE = 10;
    img_stack = double(img_stack);
    img_combined = sum(img_stack(:, :, 1:NUM_FRAMES_TO_USE), 3);
    [gain, offset] = pcfo(img_combined, 0.9);
    gain = gain / NUM_FRAMES_TO_USE;
    offset = offset / NUM_FRAMES_TO_USE;
end

