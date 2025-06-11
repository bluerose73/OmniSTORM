loader = OmniImageLoader();
loader.openImage('data\high snr high density\sequence-as-stack-MT0.N1.HD-2D-Exp.tif');

totalframes = loader.totalFrames

imdata = loader.readFrameRange(1, totalframes);
imdata = single(imdata);

threshold = 100;

Pnum = 0;
Px = zeros(120000000,1);
Py = zeros(120000000,1);
Pf = zeros(120000000,1);

peak_num = 0;
peak_x_all = zeros(120000000,1);
peak_y_all = zeros(120000000,1);
bg_all = zeros(size(imdata), 'like', imdata);

imbg = imgaussfilt(min(imdata,[],3),3)*1.2;
immin = mean(mean(mean(imdata(:,:,totalframes))));
for f=1:totalframes
    imbgf = imbg*(mean(mean(mean(imdata(:,:,f))))/immin)-200;
    bg_all(:,:,f) = imbgf;
    imRAW = imdata(:,:,f) - imbgf;   %%% bg
    imRAW(imRAW<0) = 0;
    [peak_id, peak_x, peak_y] = Sonic_clean(imRAW,threshold,imbgf);

    m = length(peak_x);
    peak_x_all(peak_num+1:peak_num+m) = peak_x;
    peak_y_all(peak_num+1:peak_num+m) = peak_y;
    peak_num = peak_num + m;

    ROI = Sonic_ROI(imRAW,peak_id,3);
    [PX, PY] = Sonic_localization(ROI,peak_x, peak_y);
    n = length(PX);
    Px((Pnum+1):(Pnum+n)) = PX;
    Py((Pnum+1):(Pnum+n)) = PY;
    Pf((Pnum+1):(Pnum+n)) = f;
    Pnum = Pnum + n;
end

peak_x_all = peak_x_all(1:peak_num);
peak_y_all = peak_y_all(1:peak_num);


X = Px(1:Pnum);
Y = Py(1:Pnum);
F = Pf(1:Pnum);

mkdir("Test\data")
save_binary(peak_x_all, 'Test\data\peak_x.bin', 'int')
save_binary(peak_y_all, 'Test\data\peak_y.bin', 'int')
save_binary(X, 'Test\data\X.bin', 'float')
save_binary(Y, 'Test\data\Y.bin', 'float')
save_binary(F, 'Test\data\F.bin', 'int')
save_binary(imdata, 'Test\data\imdata.bin', 'float')
save_binary(bg_all, 'Test\data\bg.bin', 'float')