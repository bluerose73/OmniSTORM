function im = poisson_sim()
I = ones(64,64);

I(1:21,:) = 10;

I(22:43,:) = 20;

I(44:64,:) = 30;
 
I(11,10:5:54) = I(11,10:5:54) + 50;

I(32,10:5:54) = I(32,10:5:54) + 100;

I(54,10:5:54) = I(54,10:5:54) + 100;
 
PSF = fspecial('gaussian',13,2);

PSF = PSF*100;

blurred = imfilter(I,PSF,'symmetric','conv');

im = poissrnd(blurred);
end