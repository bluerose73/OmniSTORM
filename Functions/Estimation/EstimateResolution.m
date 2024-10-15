function resolution = EstimateResolution(img)
    Nr = 50;
    Ng = 10;
    r = linspace(0,1,Nr);
    
    % apodize image edges with a cosine function over 20 pixels
    image = double(img);

    image = apodImRect(image,20);
    % compute resolution
    
    [kcMax,A0] = getDcorr(gpuArray(image),r,Ng); gpuDevice(1);

    resolution = 2 / kcMax;
end

