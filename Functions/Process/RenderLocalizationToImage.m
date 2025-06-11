function result = RenderLocalizationToImage(X, Y, F, intensity, height, width, config)
    % TODO: assumes square image
    zoom = config.process.scale;
    
    X(X>height) = height;
    X(X<1) = 1;
    Y(Y>width) = width;
    Y(Y<1) = 1;
    
    imSR = zeros(height*zoom,width*zoom, "uint16");

    for n=1:length(X)
        if isnan(X(n)) || isnan(Y(n))
            continue
        end
        imSR(round(X(n)*zoom),round(Y(n)*zoom)) = imSR(round(X(n)*zoom),round(Y(n)*zoom)) + 1;
    end

    result = imSR;
end