function [PX, PY, PXZ, PYZ, AMP] = Sonic_localization(ROI,peak_x, peak_y)

fft_values = fft2(ROI);
ROI_size = size(ROI,1);

angX = angle(fft_values(1,2,:));

angX=angX-2*pi*(angX>0);

PX = (abs(angX)/(2*pi/ROI_size) + 1) - (ROI_size+1)/2;

angY = angle(fft_values(2,1,:));

angY=angY-2*pi*(angY>0);

PY = (abs(angY)/(2*pi/ROI_size) + 1) - (ROI_size+1)/2;

PX = PX(:) + peak_x;
PY = PY(:) + peak_y;
PXZ = fft_values(1,2,:)./fft_values(1,3,:);
PYZ = fft_values(2,1,:)./fft_values(3,1,:);
AMP = ROI((ROI_size+1)/2,(ROI_size+1)/2,:);

clear ROI peak_x peak_y fft_values angX angY
end