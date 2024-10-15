% This m-file is for read in of RCM data from nd2 files for single-image
% FRC analysis of RCM
%
% needs DIPimage, https://diplib.org/
% needs pcfo, ftp://qiftp.tudelft.nl/rieger/outgoing/pcfo
%
% Sjoerd Stallinga, TU Delft, 2024

clear all
close all

addpath('C:\Program Files\DIPimage 2.9\common\dipimage');
dip_initialise;

%% 
% read in RCM data

datafilename = 'Chromosomes RCM Ti2001.nd2';
a = bfopen(datafilename); % open datafile
b = a{1}; % extract variable with image data
allimages_RCM = cell2mat(permute(b(:,1),[3 2 1])); % extract image data
clear b

% metadata_orig = a{2}; % extract original metadata
% metadataKeys = metadata_orig.keySet().iterator();
% for i=1:metadata_orig.size()
%   key = metadataKeys.nextElement();
%   value = metadata_orig.get(key);
%   fprintf('%s = %s\n', key, value)
% end
% learned items: objective is Plan Apo lambda 100x/1.45 oil, camera is
% Hamamatsu Flash 4.0, which has 6.5 mu pixel size, with 1.5x tube lens
% effective M=150 giving pixel size 43.4 nm
% RI=1.515, no info on wavelengths, assume lambda_ex=488 nm and
% lambda_em=520 nm
metadata = a{4}; % extract OME metadata
pixelsize = 1e3*double(metadata.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER)); % pixelsize in nm
axialdistance = 1e3*double(metadata.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER)); % axial spacing in nm
NA = 1.45; % numerical aperture
lambda = 520; % emission wavelength
clear a

Nx = size(allimages_RCM,1);
Ny = size(allimages_RCM,2);
Nz = size(allimages_RCM,3);
allimages_RCM = double(allimages_RCM);

%%
% single image gain calibration

dogaincalibration = 0;

if dogaincalibration
  fprintf('...gain and offset estimation for obtaining image data in detected photon counts\n')
  
  % original pcfo method
  gainstore = zeros(Nz,1);
  offsetstore = zeros(Nz,1);
  for jz = 1:Nz
    k_thres = 0.9; % parameter settings for the pcfo function
    AvoidCross = 1; % parameter settings for the pcfo function
    doPlot = 0; % parameter settings for the pcfo function
    Tiles = [3 3]; % parameter settings for the pcfo function
    RNStd = 1.0; % readout noise std
    tempim = squeeze(allimages_RCM(:,:,jz));
    [gainest,offsetest] = pcfo(tempim,k_thres,RNStd,AvoidCross,doPlot,Tiles)
    gainstore(jz) = gainest;
    offsetstore(jz) = offsetest;
  end
  
  % take median for typical gain and offset estimate
  % median instead of mean is more outlier robust
  gain = median(gainstore(:));
  offset = median(offsetstore(:));
  
  % save gain and offset estimates
  savefilename = 'gain_offset_estimation_RCM.mat';
  save(savefilename,'gainstore','offsetstore');
  
  % correct for empty 4th image in stack and then compute std's
  gainstore(4) = [];
  offsetstore(4) = [];
  stdgain = std(gainstore);
  stdoffset = std(offsetstore);
else
  gain = 2.51;
  offset = 97.4;
end

allimages_RCM = (allimages_RCM-offset)/gain;

% %%
% % test strange numbers 4th image in stack
% % 4th image appears empty!
% 
% tempim = allimages_RCM(:,:,4);
% figure
% imagesc(tempim)
% axis square
% colorbar

%%
% make image splits

fprintf('...make random binomial image splits\n')
  
numsplits = 10; % # different splits for sufficient statistics
allimages_RCM_split = zeros(Nx,Ny,Nz,2,numsplits);

for jsplit = 1:numsplits
  fprintf(strcat('random split #',num2str(jsplit),'\n'))
  for jz = 1:Nz
    tempim = squeeze(allimages_RCM(:,:,jz));
    [imsplitA,imsplitB] = cBinomialSplit(tempim);
    allimages_RCM_split(:,:,jz,1,jsplit) = imsplitA;
    allimages_RCM_split(:,:,jz,2,jsplit) = imsplitB;
  end
end

%%
% compute single image FRC values

fprintf('...compute FRC curves\n')
  
Nfrc = round((Nx-1)/sqrt(2));
allfrccurves_RCM = zeros(Nz,Nfrc,numsplits);
allfrcres_RCM = zeros(Nz,numsplits);
for jsplit = 1:numsplits
  fprintf(strcat('random split #',num2str(jsplit),'\n'))
  for jz = 1:Nz
    image1 = allimages_RCM_split(:,:,jz,1,jsplit);
    image2 = allimages_RCM_split(:,:,jz,2,jsplit);

    frccurve = frcbis(mat2im(image1),mat2im(image2));
    smoothfac = 7;
    frccurve = movmean(frccurve,smoothfac); % moving average to smooth curve for display purposes
    allfrccurves_RCM(jz,:,jsplit) = frccurve; % no pre-allocation to adjust #columns to frccurve
    [allfrcres_RCM(jz,jsplit),~,~] = frctoresolution(frccurve,Nx);
  end
end
allfrcres_RCM = pixelsize*allfrcres_RCM;

%%
% SSNR analysis

fprintf('...compute SSNR\n')

% compute ring averaged power spectrum
numbins = round(sqrt(Nx*Ny)/2); % number of bins for the ring averaging needed to estimate the SSNR
offs = [floor(Nx/2)+1-(Nx+1)/2,floor(Ny/2)+1-(Ny+1)/2]; % indexing of zero spatial frequency
pixelszs = [1/Nx/pixelsize,1/Ny/pixelsize]; % pixel sizes in Fourier space
signalpower_RCM_avg = zeros(Nx,Ny,Nz);
signalpower_RCM_avg_ring = zeros(numbins,Nz);
noisepower_RCM_avg = zeros(Nx,Ny,Nz);
noisepower_RCM_avg_ring = zeros(numbins,Nz); 
for jz = 1:Nz
  tempim = allimages_RCM(:,:,jz);
  fttempim = fftshift(fft2(tempim));
  signalpower = abs(fttempim).^2;
  noisepower = sum(tempim(:))*ones(size(signalpower));
  [signalpower_RCM_avg(:,:,jz),signalpower_RCM_avg_ring(:,jz),~,~] = radialavgmat(signalpower,numbins,offs,pixelszs);
  [noisepower_RCM_avg(:,:,jz),noisepower_RCM_avg_ring(:,jz),~,~] = radialavgmat(noisepower,numbins,offs,pixelszs);
end

% compute SSNR
epsy = 1e2*eps;
SSNRest_RCM = signalpower_RCM_avg./noisepower_RCM_avg-1;
SSNRest_RCM_ring = signalpower_RCM_avg_ring./noisepower_RCM_avg_ring-1;
SSNRest_RCM(isnan(SSNRest_RCM)) = epsy;
SSNRest_RCM_ring(isnan(SSNRest_RCM_ring)) = epsy;
SSNRest_RCM(isinf(SSNRest_RCM)) = epsy;
SSNRest_RCM_ring(isinf(SSNRest_RCM_ring)) = epsy;
SSNRest_RCM(SSNRest_RCM<epsy) = epsy;
SSNRest_RCM_ring(SSNRest_RCM_ring<epsy) = epsy;

%%
% save results

fprintf('...save data\n')

savefilename = 'RCMresults_store.mat';
save(savefilename,'allimages_RCM','allfrccurves_RCM','allfrcres_RCM',...
  'signalpower_RCM_avg','signalpower_RCM_avg_ring',...
  'noisepower_RCM_avg','noisepower_RCM_avg_ring',...
  'SSNRest_RCM','SSNRest_RCM_ring','gain','offset','pixelsize','axialdistance','lambda','NA')

%%
% make plots
[Nx,Ny,Nz] = size(allimages_RCM);
numbins = size(SSNRest_RCM_ring,1);
Nfrc = size(allfrccurves_RCM,2);
numsplits = size(allfrccurves_RCM,3);

selecz = 7:16;

%%
% plot FRC curves

spatfreq = (0:(Nfrc-1))/sqrt(2)/pixelsize/Nfrc;
centralslice = 11;
allz = ((1:Nz)-centralslice)*axialdistance;
mean_allfrccurves_RCM = mean(allfrccurves_RCM,3);
mean_allfrcres_RCM = mean(allfrcres_RCM,2);
std_allfrcres_RCM = std(allfrcres_RCM,[],2);

figure
set(gcf,'units','pixels');
set(gcf,'Position',[800 300 500 400]);
box on
hold on
frcscale = [-0.2 1.0];
imagesc(allz,1e3*spatfreq,mean_allfrccurves_RCM',frcscale)
set(gca,'YDir','normal');
colormap parula
colorbar
contourset_frc = [0.143,0.143];
contour(allz,1e3*spatfreq,mean_allfrccurves_RCM',contourset_frc,'k','LineWidth',1,'ShowText','off');
xlabel('axial position (nm)')
ylabel('spatial frequency (1/{\mu}m)')
set(gca,'FontSize',16)
xlim([-500 500])
ylim([0 8])
savefilename = 'FRCplot_RCM.svg';
saveas(gcf,savefilename)

figure
set(gcf,'units','pixels');
set(gcf,'Position',[800 240 440 400]);
box on
hold on
plot(allz(selecz),mean_allfrcres_RCM(selecz),'-or','MarkerSize',8,'LineWidth',2)
xlabel('axial position (nm)')
ylabel('FRC-resolution (nm)')
set(gca,'FontSize',16)
xlim([-600 600])
ylim([0 300])
savefilename = 'FRCresolution_RCM.svg';
saveas(gcf,savefilename)

% compute median plateau above diffraction limit
allfrcplateau = allfrccurves_RCM(:,spatfreq>2*NA/lambda,:);
frcplateau_RCM = median(allfrcplateau(:));

qxy = (0:(numbins-1))/sqrt(2)/pixelsize/numbins;

figure
set(gcf,'units','pixels');
set(gcf,'Position',[800 160 500 400]);
box on
hold on
ssnrscale = [0 6];
imagesc(allz,1e3*qxy,log(1+SSNRest_RCM_ring)/log(10),ssnrscale)
set(gca,'YDir','normal');
colormap parula
colorbar
contourset_ssnr = [log(1+2)/log(10),log(1+20)/log(10),log(1+200)/log(10)];
contour(allz,1e3*qxy,log(1+SSNRest_RCM_ring)/log(10),contourset_ssnr,'k','LineWidth',1,'ShowText','off')
xlabel('axial position (nm)')
ylabel('spatial frequency (1/{\mu}m)')
set(gca,'FontSize',16)
xlim([-500 500])
ylim([0 8])
savefilename = 'SSNRplot_RCM.svg';
saveas(gcf,savefilename)

%%
% make movie file

for plotinset = [0 1]

%%
% make movie file, only unfiltered

for plotinset = [0 1]

% define crop region
if plotinset
  cropx = 541:840;
  cropy = 521:820;
  scalebarlength = 2;
else
  cropx = 1:Nx;
  cropy = 1:Ny;
  scalebarlength = 6;
end

% scale bar settings
width = 1000*(scalebarlength/(length(cropx))/pixelsize);
scalebarstring = strcat(num2str(scalebarlength),' {\mu}m');

% define RGB colormaps
channel = 2;
numcolors = 256;
mappy = zeros(numcolors,3);
mappy(:,channel) = ((1:numcolors)-1)/(numcolors-1);

% create movie object
writerObjRCM = VideoWriter('RCM_throughfocus.avi');
writerObjRCM.FrameRate = 1;
open(writerObjRCM);

for jz = selecz
    
  figure(102)
  set(gcf,'units','pixels');
  set(gcf,'Position',[200 260 320 320]);
  
  tempim = allimages_RCM(cropx,cropy,jz);
  tempim = tempim/max(tempim(:));
  imagesc(tempim)
  colormap(mappy)
  set(gca,'position',[0 0 1 1],'units','normalized')
  axis square
  axis off
  axis tight
  if jz==min(selecz)
    annotation('rectangle',[0.05 0.03 width 0.02],'FaceColor','white','Color','white');
    annotation('textbox',[0.04 0.09 3*width 0.06],'String',scalebarstring,'FontSize',16,'Edgecolor','none','Color','white');
  end
  stringy = strcat('z = ',num2str(allz(jz)/1e3),'{\mu}m');
  if jz==min(selecz)
    glancm = annotation('textbox',[0.64 0.02 0.39 0.1],'String',stringy,'FontSize',16,'Edgecolor','none','Color','white');
  else
    glancm.String = stringy;
  end
  
  frame = getframe(gcf);
  writeVideo(writerObjRCM,frame);
end
  
end

close(writerObjRCM);
clear writerObjRCM
