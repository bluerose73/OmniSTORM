function result = RenderLocalizationToImage(X, Y, F, intensity, imSize, config)
    % TODO: assumes square image
    zoom = config.process.scale;
    
    X(X>imSize) = imSize;
    X(X<1) = 1;
    Y(Y>imSize) = imSize;
    Y(Y<1) = 1;
    
    imSR = zeros(imSize*zoom,imSize*zoom);

    result = imSR;

    for n=1:length(X)
        if isnan(X(n)) || isnan(Y(n))
            continue
        end
        imSR(round(X(n)*zoom),round(Y(n)*zoom)) = imSR(round(X(n)*zoom),round(Y(n)*zoom)) + 1;
    end

    result = imSR;
end