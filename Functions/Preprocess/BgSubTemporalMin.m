function [background_removed, background] = BgSubTemporalMin(imdata, use_gpu)
% BgSubTemporalMin - Removes background from image stack using min projection and Gaussian smoothing.
% 
% Inputs:
%   imdata - 3D image stack (height x width x frames)
%
% Outputs:
%   background_removed - 3D image stack with background subtracted
%   background         - 3D background estimate for each frame
    if use_gpu
        imdata = gpuArray(imdata);
    end

    % Estimate global background using temporal minimum and Gaussian blur
    static_bg = imgaussfilt(min(imdata, [], 3), 3) * 1.2;

    % Reference intensity (from last frame)
    ref_intensity = mean(imdata(:,:,end), 'all');

    % Compute mean intensity of each frame in one call
    frame_means = mean(imdata, [1 2]);  % size: [1, 1, totalframes]
    
    % Compute scaled backgrounds
    scales = frame_means / ref_intensity;        % size: [totalframes, 1]
    scaled_bg = static_bg .* scales - 200;  % size: [h, w, totalframes]
    scaled_bg(scaled_bg < 0) = 0;
    
    % Subtract scaled background and clip negatives to zero
    frame = imdata - scaled_bg;
    frame(frame < 0) = 0;

    if use_gpu
        scaled_bg = gather(scaled_bg);
        frame = gather(frame);
    end
    
    % Assign output
    background = scaled_bg;
    background_removed = frame;
end