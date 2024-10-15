% In batch folder mode, run full pipelines in background
function result = FullPipeline(inputImage, config)
    [result, background] = Preprocess(inputImage, config);
    [result, X, Y, F, intensity, drift] = Process(result, background, config);
    result = Postprocess(result, config);
end