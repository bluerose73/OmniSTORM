function Sonic_save(X,Y,F,drift,filename,imSize,zoom)

Xd = X;
Yd = Y;

for n=1:round(length(X)*0.997)
    Xd(n) = X(n) - drift(F(n),1);
    Yd(n) = Y(n) - drift(F(n),2);
end

Xd(Xd>imSize-1) = imSize-1;
Xd(Xd<1) = 1;
Yd(Yd>imSize-1) = imSize-1;
Yd(Yd<1) = 1;

imSR = zeros(imSize*zoom,imSize*zoom);
for n=1:length(Xd)
    imSR(round(Xd(n)*zoom),round(Yd(n)*zoom)) = imSR(round(Xd(n)*zoom),round(Yd(n)*zoom)) + 1;
end
imwrite(uint16(imSR),[filename '_results.tif'])
save([filename '_results.mat'], 'X','Y','F','drift','Xd','Yd')
end