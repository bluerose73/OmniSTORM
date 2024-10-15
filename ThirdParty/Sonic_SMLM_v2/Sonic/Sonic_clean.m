function [peak_id, peak_x, peak_y] = Sonic_clean(im,threshold,imbg)

filter = -ones(11,11)/112;
filter(5:7,5:7) = 1/10;
filter(6,6) = 1/5;

im = imfilter(im, filter);

im(im<(threshold+4*sqrt(imbg))) = 0;
im(1:15,:) = 0;
im(:,1:15) = 0;
im(:,end-15:end) = 0;
im(end-15:end,:) = 0;
im = imregionalmax(im,8).*im;

filter2 = -ones(7,7);
filter2(4,4) = 1;

im = imfilter(im, filter2);
im(im<0) = 0;

[peak_x, peak_y] = find(im>0);
sz = size(im);
peak_id = sub2ind(sz,peak_x,peak_y);

clear im

end