function result = Postprocess(inputImage, config)
    result = inputImage;
    if config.postprocess.adjustContrast
        result = double(result);
        result = max(result, 0);
        result = result / max(result, [], "all");
        result = imadjust(result);
    end
end