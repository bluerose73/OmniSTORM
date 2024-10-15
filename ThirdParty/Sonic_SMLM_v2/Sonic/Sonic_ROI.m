function ROI = Sonic_ROI(im,peak_id,r)

imW = size(im,1);
ROI = zeros(7,7,length(peak_id));

for i = -r : r
    for j = -r : r
        shift = i*imW + j;
        ROI(i+r+1,j+r+1,:) = im(peak_id+shift);
    end
end

clear im
end