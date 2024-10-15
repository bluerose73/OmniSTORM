function [result, X, Y, F, intensity, drift] = ProcessSMLM(inputImage, background, config)
    if config.process.sparse.localization == "Sonic"
        [X, Y, F, intensity] = SonicWrapper(inputImage, background, config);
    elseif config.process.sparse.localization == "WindSTORM"
        [X, Y, F, intensity] = WindSTORMWrapper(inputImage, background, config);
    else
        error("unknown localization method " + config.process.sparse.localization)
    end

    if config.process.sparse.aim
        localizations(:, 1) = F;
        localizations(:, 2) = X;
        localizations(:, 3) = Y;
        [locAIM, drift] = AIM(localizations, config.process.sparse.aimTrackInterval);
        F = locAIM(:, 1);
        X = locAIM(:, 2);
        Y = locAIM(:, 3);
    else
        drift = [];
    end
    
    result = RenderLocalizationToImage(X, Y, F, intensity, size(inputImage, 1), config);
end