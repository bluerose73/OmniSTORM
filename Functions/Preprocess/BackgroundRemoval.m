function [result, background] = BackgroundRemoval(inputImage)
    inputImage = double(inputImage);
    [result, background] = BgSub(inputImage);
end