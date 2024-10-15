function [result, X, Y, F, intensity, drift] = Process(inputImage, background, config)
    disp("process start");
    result = inputImage;

    if config.process.method == "Deconvolution"
        result = ProcessDeconvolution(inputImage, config);
        X = [];
        Y = [];
        F = [];
        intensity = [];
        drift = [];
    elseif config.process.method == "Localization"
        [result, X, Y, F, intensity, drift] = ProcessSMLM(inputImage, background, config);
    else
        warn("Unknown process type");
    end

    disp("processe end");
end