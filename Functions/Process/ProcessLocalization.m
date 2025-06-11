function [X, Y, F, intensity] = ProcessLocalization(inputImage, background, config)
    if gpuDeviceCount > 0 && config.process.useGPU && config.process.sparse.localization == "Sonic"
        [X, Y, F, intensity] = SonicCudaWrapper(inputImage, background, config);
    elseif config.process.sparse.localization == "Sonic"
        [X, Y, F, intensity] = SonicWrapper(inputImage, background, config);
    elseif config.process.sparse.localization == "WindSTORM"
        [X, Y, F, intensity] = WindSTORMWrapper(inputImage, background, config);
    else
        error("unknown localization method " + config.process.sparse.localization)
    end
end