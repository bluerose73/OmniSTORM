function result = ProcessDeconvolution(inputImage, config)
    scale = config.process.scale;
    interp = config.process.extraDense.interpolation;
    sigma = config.params.resolutionPx / 2.35;
    temporalAnalysis = config.process.extraDense.temporal;

    [final_sr_img, ~, ~, ~] = deconv_temporalstd(inputImage, ...
        scale, sigma, interp);

    if temporalAnalysis == "mean"
        result = final_sr_img.mean;
    elseif temporalAnalysis == "std"
        result = final_sr_img.std;
    end

end