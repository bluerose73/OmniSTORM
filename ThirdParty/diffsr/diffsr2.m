clc
clear
close all
 
delete('V_decompose.tif')
 
for f=1:20
    imr(:,:,f) = double(imread('..\data\lines.tif', f*5));
end
 
num = 0;
for m=1:19
    m
    for n=(m+1):20
        num = num+1;
        imd = abs(imr(:,:,m)-imr(:,:,n));
        imd(imd<0)=0;
        imd2 = interpft(imd,128,1);
        imd3 = interpft(imd2,128,2);
        imd3(imd3<100)=0;
        h = fspecial('gaussian',15,2);
        imdsr = deconvlucy(imd3,h,10);
        imsr(:,:,num) = imdsr;
    end
end
imstd=std(imsr,[],3);
imavg =mean(imsr,3); 
h = fspecial('gaussian',15,1);
final_imsr1 = deconvlucy(imstd,h,10);
final_imsr2 = deconvlucy(imavg,h,10);