% This script is for simulating 1FRC, in particular the impact of errors in
% gain/offset estimation and readout noise.
%
% Sjoerd Stallinga, TU Delft, 2024

close all
clear all

addpath('C:\Program Files\DIPimage 2.9\common\dipimage');
dip_initialise;

% parameters
pixelsize = 1;
rnstd = 0.0; % Gaussian readout noise
k_thresh = 0.9; % ratio nyquist rate/ sampling rate = 4*pixelsize*NA/lambda
gain = 2.0;
offset = 100;
avsig = 250;

% object
fprintf('... object and image\n')
% Aob = double(imread('cameraman.tif'));
Aob = sum(double(imread('strawberries.jpg')),3);
Aob = Aob(1:256,1:256);
% Aob = Aob(2:end,2:end); % check even/odd
Aob = Aob/mean(Aob(:));
[N,~] = size(Aob);

% image by low-pass filtering with incoherent otf
[X,Y] = meshgrid(1:N,1:N);
X = (X-floor(N/2)-1)/(N/2);
Y = (Y-floor(N/2)-1)/(N/2);
r = sqrt(X.^2+Y.^2);
otf = (2/pi)*acos(r/k_thresh)-(r/k_thresh).*sqrt(1-(r/k_thresh).^2)/2;
otf = double(r<k_thresh).*otf;
otf = real(otf);
ftAob = fftshift(fft2(Aob));
Aim = abs(ifft2(ifftshift(otf.*ftAob)));

% remove rim pixels to emulate an experimental dataset with discontinuity
% due to periodic boundary conditions (FT with a "Fourier cross")
% the width is taken as 3*lambda/NA
rimwidth = round(12/k_thresh);
Aim = Aim(rimwidth:end-rimwidth,rimwidth:end-rimwidth);
[N,~] = size(Aim);

% generate noisy images
fprintf('... noisy camera images\n')
numframes = 10;
allimages = zeros(N,N,numframes);
for jrep = 1:numframes
  Btemp = poissrnd(avsig*Aim); % Poisson noise
  Btemp = Btemp+rnstd*randn(size(Btemp)); % Gaussian noise
  Btemp = offset+gain*Btemp; % camera offset and gain
  allimages(:,:,jrep) = Btemp;
end

% get 1FRC and 2FRC
fprintf('... 1FRC and 2FRC\n')
gain_est = (1+0.0)*gain;
offset_est = offset-0.0*avsig;
rnstd_est = 1.0*rnstd;
relgain = gain/gain_est;
reloffs = (offset-offset_est)/gain_est/avsig;
relrnstd = (relgain^2*rnstd^2-rnstd_est^2)/avsig;
sumrnstd = (relgain^2*rnstd^2+rnstd_est^2)/avsig;
FRC1level = (relgain*(relgain-1)-reloffs+relrnstd)/(relgain*(relgain+1)+reloffs+sumrnstd);

smoothfac = 7;
Nfrc = ceil((N-1)/sqrt(2)); 
FRC2curves = zeros(Nfrc,numframes);
FRC2resolutions = zeros(numframes,1);
FRC1curves = zeros(Nfrc,numframes);
FRC1resolutions = zeros(numframes,1);
for jf = 1:numframes
  fprintf('frame %i\n',jf)
  tempim = allimages(:,:,jf);
  tempim = (tempim-offset_est)/gain_est;
  jfnext = mod(jf,numframes)+1;
  tempimnext = allimages(:,:,jfnext);
  tempimnext = (tempimnext-offset_est)/gain_est;
  FRCcurve = frcbis(tempim,tempimnext); % compute 2FRC curve
  FRCcurve = movmean(FRCcurve,smoothfac); % moving average to smooth curve for display purposes
  FRC2curves(:,jf) = FRCcurve';
  [FRCres,~,~] = frctoresolution(FRCcurve,N); % compute 2FRC resolution
  FRC2resolutions(jf) = FRCres*pixelsize;
  tempimsum = tempim+tempimnext; % sum image
  tempimsum = tempimsum+2*rnstd_est^2; % add rms readout noise for compensating impact of Gaussian readout noise
  [tempim1,tempim2] = cBinomialSplit(tempimsum); % make the split
  tempim1 = tempim1-rnstd_est^2; % subtract rms readout noise for compensating impact of Gaussian readout noise
  tempim2 = tempim2-rnstd_est^2; % subtract rms readout noise for compensating impact of Gaussian readout noise
  FRCcurve = frcbis(tempim1,tempim2); % compute 1FRC curve
  FRCcurve = movmean(FRCcurve,smoothfac); % moving average to smooth curve for display purposes
  [FRCres,~,~] = frctoresolution(FRCcurve,N); % compute FRC 1resolution
  FRC1curves(:,jf) = FRCcurve';
  FRC1resolutions(jf) = FRCres*pixelsize;
end

% compute mean and std
meanFRC2curves = mean(FRC2curves,2);
stdFRC2curves = std(FRC2curves,[],2);
meanFRC2resolutions = mean(FRC2resolutions(~isnan(FRC2resolutions)),1);
stdFRC2resolutions = std(FRC2resolutions(~isnan(FRC2resolutions)),[],1);
meanFRC1curves = mean(FRC1curves,2);
stdFRC1curves = std(FRC1curves,[],2);
meanFRC1resolutions = mean(FRC1resolutions(~isnan(FRC1resolutions)),1);
stdFRC1resolutions = std(FRC1resolutions(~isnan(FRC1resolutions)),[],1);

%%
% find spatial frequencies corresponding to the ring averages
fprintf('... make plots\n')
Nfrc = size(FRC1curves,1);
qr = ((0:(Nfrc-1))/Nfrc)/sqrt(2)*4/k_thresh;

% make plots of FRC curves
cutofffac = 1.0;
allcols = {'r','g','b'};
allfacecolors = [1.0 0.2 0.0;0.0 1.0 0.2;0.2 0.0 1.0];
FRC1curve_mean = meanFRC1curves';
FRC1curve_std = stdFRC1curves';
FRC1area = [FRC1curve_mean-FRC1curve_std;2*FRC1curve_std];
FRC2curve_mean = meanFRC2curves';
FRC2curve_std = stdFRC2curves';
FRC2area = [FRC2curve_mean-FRC2curve_std;2*FRC2curve_std];
  
figure
set(gcf,'units','pixels');
set(gcf,'Position',[400 300 400 350]);
box on
hold on
jcol = 1;
plot(qr(1:round(cutofffac*Nfrc)),FRC1curve_mean(1:round(cutofffac*Nfrc)),allcols{jcol},'LineWidth',0.5)
jcol = 3;
plot(qr(1:round(cutofffac*Nfrc)),FRC2curve_mean(1:round(cutofffac*Nfrc)),allcols{jcol},'LineWidth',0.5)
plot(qr,ones(size(qr))*FRC1level,'--m','LineWidth',0.5)
jcol = 1;
harea1FRC = area(qr(1:round(cutofffac*Nfrc))',FRC1area(:,1:round(cutofffac*Nfrc))','FaceAlpha',0.3,'LineWidth',0.2);
harea1FRC(1).FaceColor = 'w';
harea1FRC(2).FaceColor = allfacecolors(jcol,:);
harea1FRC(1).EdgeColor = allcols{jcol};
harea1FRC(2).EdgeColor = allcols{jcol};
jcol = 3;
harea2FRC = area(qr(1:round(cutofffac*Nfrc))',FRC2area(:,1:round(cutofffac*Nfrc))','FaceAlpha',0.3,'LineWidth',0.2);
harea2FRC(1).FaceColor = 'w';
harea2FRC(2).FaceColor = allfacecolors(jcol,:);
harea2FRC(1).EdgeColor = allcols{jcol};
harea2FRC(2).EdgeColor = allcols{jcol};
plot(qr,ones(size(qr))*1/7,'--k','LineWidth',0.5)
rectangle('Position',[0 -0.2 3.0 1.2],'LineWidth',0.2)
xlim([0 3])
xticks([0 0.5 1 1.5 2 2.5 3])
ylim([-0.2 1.0])
yticks([-0.2 0 0.2 0.4 0.6 0.8 1.0])
xlabel('spatial frequency [NA/{\lambda}]')
ylabel('FRC')
axis square
set(gca,'FontSize',12)
set(gca,'XColor','k')
set(gca,'LineWidth',0.5)
legend({'1FRC','2FRC','1FRC plateau'},'Location','NorthEast');

