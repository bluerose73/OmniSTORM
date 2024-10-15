function RunMultiPart(inputFolder, outputFolder, config)
    inputImage = ReadMultiPartImage(inputFolder);
    config.params = EstimateParams(inputImage, config);
    ConfigSanityCheck(inputImage, config);

    result = FullPipeline(inputImage, config);

    mkdir(outputFolder);
    save_tiff(result, fullfile(outputFolder, "super-resolution.tif"));
end
