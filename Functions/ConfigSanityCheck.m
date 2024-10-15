% Raises error if config may lead to error
function ConfigSanityCheck(inputImageStack, config)
    nFrames = size(inputImageStack, 3);
    
    % Check AIM track interval
    multiplier = 2;
    if config.postprocess.frc
        multiplier = 4;
    end
    if config.process.sparse.aim && nFrames < config.process.sparse.aimTrackInterval * multiplier
        error("AIM Track Interval is too large. The upper bound is 1/" + string(multiplier) + " frame number");
    end

    % Check inter-frame difference
    if config.preprocess.interFrameDifference && nFrames > 100
        error("Inter-Frame Difference will be very slow when frame number is larger than 100. Please cancel it.");
    end
end