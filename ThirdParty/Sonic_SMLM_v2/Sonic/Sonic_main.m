function [X,Y,F,imW] = Sonic_main(foldername,threshold)

Pnum = 0;
Px = zeros(120000000,1);
Py = zeros(120000000,1);
Pf = zeros(120000000,1);
filelist = dir([foldername '\*.dcimg']);
for fiN = 1:length(filelist)
    filename = [foldername '\' filelist(fiN).name]
    [framedata,totalframes]= dcimgmatlab(1, filename);
    imW = size(framedata,1);
    [imdata,totalframes,imW] = dcimg_read(filename);
    imbg = imgaussfilt(min(imdata,[],3),3)*1.2;
    immin = mean(mean(mean(imdata(:,:,totalframes))));
    for f=1:totalframes
%         imRAW = dcimg_read_single(filename,f);
        imbgf = imbg*(mean(mean(mean(imdata(:,:,f))))/immin)-200;
        imRAW = imdata(:,:,f) - imbgf;   %%% bg
        imRAW(imRAW<0) = 0;
        [peak_id, peak_x, peak_y] = Sonic_clean(imRAW,threshold,imbgf);
        ROI = Sonic_ROI(imRAW,peak_id,3);
        [PX, PY] = Sonic_localization(ROI,peak_x, peak_y);
        n = length(PX);
        Px((Pnum+1):(Pnum+n)) = PX;
        Py((Pnum+1):(Pnum+n)) = PY;
        Pf((Pnum+1):(Pnum+n)) = f+(fiN-1)*totalframes;
        Pnum = Pnum + n;
        % imwrite(uint16(imRAW), '','writemode','append');
        clear imRAW ROI PX PY framedata peak_id peak_x peak_y
        clear dcimg_read_single Sonic_clean Sonic_ROI Sonic_localization
    end
end
X = Px(1:Pnum);
Y = Py(1:Pnum);
F = Pf(1:Pnum);
clear Px Py Pf

end