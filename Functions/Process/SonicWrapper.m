function [X, Y, F, intensity] = SonicWrapper(inputImage, background, config)
    totalframes = size(inputImage, 3);
    inputImage = double(inputImage);
    threshold = config.params.threshold;
    Pnum = 0;

    Px = zeros(120000000,1);
    Py = zeros(120000000,1);
    Pf = zeros(120000000,1);


    for f=1:totalframes
        imbgf = background(:, :, f);
        imRAW = inputImage(:, :, f);
        imRAW(imRAW<0) = 0;
        [peak_id, peak_x, peak_y] = Sonic_clean(imRAW,threshold,imbgf);
        ROI = Sonic_ROI(imRAW,peak_id,3);
        [PX, PY] = Sonic_localization(ROI,peak_x, peak_y);
        n = length(PX);
        Px((Pnum+1):(Pnum+n)) = PX;
        Py((Pnum+1):(Pnum+n)) = PY;
        Pf((Pnum+1):(Pnum+n)) = f;
        Pnum = Pnum + n;
    end

    X = Px(1:Pnum);
    Y = Py(1:Pnum);
    F = Pf(1:Pnum);
    intensity = ones(Pnum, 1);
end
