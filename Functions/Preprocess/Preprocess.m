% Returns
%   result: background subtracted image stack
%   background: estimated background stack
function [result, background] = Preprocess(inputImage, config)
    result = single(inputImage);
    background = zeros(size(inputImage), "single");
    if config.preprocess.usePhotonCount
        result = (result - config.params.offset) / config.params.gain;
        result(result < 0) = 0;
    end
    
    if config.preprocess.interFrameDifference
        result = InterFrameDifference(result);
    end

    if gpuDeviceCount > 0 && config.process.useGPU
        useGPU = true;
    else
        useGPU = false;
    end

    if config.preprocess.backgroundRemoval == "WindSTORM"
        [result, background] = BgSub(result);
        % disp('windstorm background')
    elseif config.preprocess.backgroundRemoval == "Temporal Min"
        [result, background] = BgSubTemporalMin(result, useGPU);
        % disp('Temporal Min background')
    else
        % disp('None background')
    end
end