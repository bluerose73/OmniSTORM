clc
clear
close all
 
delete('V_decompose.tif')
 
for f=1:20
    imr(:,:,f) = double(imread('..\data\lines.tif', f));
end

psf_sigma = 10;

num = 0;
for m=1:1
    m
    % res = func_1frc(imr(:,:,m))
    for n=1:20
        num = num+1;
        % imd = (imr(:,:,m)-imr(:,:,n));
        imd = imr(:,:,n);
        imd(imd<0)=0;

        imd2 = interpft(imd,512,1);
        imd3 = interpft(imd2,512,2);
        % imd3(imd3<100)=0;
        % %  res = func_1frc(imd3)
        h = fspecial('gaussian', 81, 8);
        imdsr = deconvlucy(imd3,h,20);
        imwrite(uint16(imdsr / max(imdsr, [], "all") * 60000), 'sr_oversampling.tif','WriteMode','append')
        imsr(:,:,num) = imdsr;
    end
end
imstd=std(imsr,[],3);
imavg =mean(imsr,3); 
h = fspecial('gaussian',61,5);
final_imsr1 = deconvlucy(imstd,h,10);
final_imsr2 = deconvlucy(imavg,h,10);
imwrite(uint16(final_imsr1 / max(final_imsr2, [], "all") * 60000), 'sr.tif')
% res_std = func_1frc(imstd)
% res_avg = func_1frc(imavg)