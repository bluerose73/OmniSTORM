function im = Sonic_simulation()

[X,Y] = meshgrid(1:32);
x = (32 - 22)*rand + 11;
y = 11+ 0.5*x;

im = 600*exp(-((X-x).^2+(Y-y).^2)/(2))+100;
im = poissrnd(im);
end
