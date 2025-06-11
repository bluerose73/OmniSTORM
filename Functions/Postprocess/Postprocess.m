function result = Postprocess(inputImage, config)
    result = inputImage;
    % disp("pre-adjust");
    % disp(class(inputImage));
    % disp(max(result, [], "all"));
    % disp(min(result, [], "all"));
    if config.postprocess.adjustContrast
        result = imadjust(result);
    end
    % disp("Post-adjust");
    % disp(max(result, [], "all"));
    % disp(min(result, [], "all"));
end