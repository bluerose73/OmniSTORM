% Returns
%   result: background subtracted image stack
%   background: estimated background stack
function [result, background] = Preprocess(inputImage, config)
    result = double(inputImage);
    background = zeros(size(inputImage));
    if config.preprocess.usePhotonCount
        result = (result - config.params.offset) / config.params.gain;
        result(result < 0) = 0;
    end
    if config.preprocess.interFrameDifference
        result = InterFrameDifference(result);
    end
    if config.preprocess.backgroundRemoval
        [result, background] = BackgroundRemoval(result);
    end
end