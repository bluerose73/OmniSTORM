function imo = radial_line_simulation(imW,sigma,brightness,bg,emitterNUM,fnum,filename)

delete('radial_line_simulation.tif')

for f=1:fnum    
    f
    %% generate ground truth localiztion list 
    % can change this part for various patterns
    im = zeros(imW,imW);
    xp = rand(emitterNUM,1)*imW;
    yp = rand(emitterNUM,1)*imW;
    [theta,rho] = cart2pol(xp,yp);
    a = round(theta/(pi/2)*18);
    for m=1:2:17
        rho(a==m) = 1000;
    end
    theta(rho>imW-21) = [];
    rho(rho>imW-21) = [];

    [xp,yp] = pol2cart(theta,rho);
    xp = xp + 10;
    yp = yp + 10;
    
    
    %% convolve the position with PSF
    [X,Y] = meshgrid(-9:9);
    for n=1:length(xp)
    ROI = brightness/(2*pi*sigma*sigma)*exp(-((Y-(xp(n)-round(xp(n)))).^2+(X-(yp(n)-round(yp(n)))).^2)/(2*sigma*sigma));
    im(round(xp(n))-9:round(xp(n))+9, round(yp(n))-9:round(yp(n))+9)  = im(round(xp(n))-9:round(xp(n))+9, round(yp(n))-9:round(yp(n))+9) + ROI;
    end

    %% add backround and poisson noise 
    im = poissrnd(im+bg);
    imo(:,:,f) = im;
    imwrite(uint16(im),filename,'writemode','append');
end
end