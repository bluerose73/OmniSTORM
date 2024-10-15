clc
clear
close all

imW = 128;
zoom = 5;
filename = 'Microtubule_EPFL_WindSTORM.csv';
results = csvread(filename,1,0);
imSR1 = zeros(imW*zoom,imW*zoom);
imSR2 = zeros(imW*zoom,imW*zoom);
for n=1:length(results)
    f = results(n,2);
    x = results(n,4);
    y = results(n,3);
    x= round(x*zoom);
    y= round(y*zoom);
    if mod(f,2)==0
        imSR1(x,y) = imSR1(x,y) + 1;
    else 
        imSR2(x,y) = imSR2(x,y) + 1;
    end
end
imwrite(uint16(imSR1),[filename(1:end-4) '_FRCstack.tif'])
imwrite(uint16(imSR2),[filename(1:end-4) '_FRCstack.tif'],'WriteMode','append')