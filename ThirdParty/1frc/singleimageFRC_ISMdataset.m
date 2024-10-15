% This m-file is for read in of RCM data from czi files for single-image
% FRC analysis of ISM
%
% needs DIPimage, https://diplib.org/
% needs pcfo, ftp://qiftp.tudelft.nl/rieger/outgoing/pcfo
%
% Sjoerd Stallinga, TU Delft, 2024

clear 
close all

addpath('C:\Program Files\DIPimage 2.9\common\dipimage');
dip_initialise;

%% 
% read in Airyscan/ISM data

datafilename = 'chromosomes airyscan.czi'; % raw data from the 32 detector elements
a = bfopen(datafilename); % open datafile
b = a{1}; % extract variable with image data
allimages_ISM = cell2mat(permute(b(:,1),[3 2 1])); % extract image data
clear b

% metadata_orig = a{2}; % extract original metadata
% metadataKeys = metadata_orig.keySet().iterator();
% for i=1:metadata_orig.size()
%   key = metadataKeys.nextElement();
%   value = metadata_orig.get(key);
%   fprintf('%s = %s\n', key, value)
% end
% learned items: objective is 63x/1.40 oil DIC objective, RI=1.518, 
% lambda_ex = 488 nm (probably), filter BP 495-550, taken lambda_em = 520 nm
metadata = a{4}; % extract OME metadata
pixelsize = 1e3*double(metadata.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER)); % pixelsize in nm
axialdistance = 1e3*double(metadata.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER)); % axial spacing in nm
NA = 1.40; % numerical aperture
lambda = 520; % emission wavelength
clear a

allimages_ISM_unknown = double(allimages_ISM(:,:,2:2:20)); % take second unknown image and set apart
allimages_ISM = allimages_ISM(:,:,1:2:size(allimages_ISM,3)); % take odd entries
Nx = size(allimages_ISM,1);
Ny = size(allimages_ISM,2);
numims = size(allimages_ISM,3);
Nd = 32; % # detector elements
Nz = numims/Nd;
allimages_ISM = reshape(allimages_ISM,[Nx Ny Nz Nd]);
allimages_ISM = double(allimages_ISM);

%%
% make shift estimation to figure out location of the 32 elements

doshiftestimation = 0;

if doshiftestimation
  
  fprintf('...make shift estimation for channel alignment\n')

  all_shift_vectors = zeros(Nd,Nz,2);
  for jz = 1:Nz
    fprintf(strcat('focus layer #',num2str(jz),'\n'))
    imageref = squeeze(allimages_ISM(:,:,jz,1));
    for jd = 1:Nd
      fprintf(strcat('detector element #',num2str(jd),'\n'))
      tempim = squeeze(allimages_ISM(:,:,jz,jd));
      driftvec = findshift(imageref,tempim,'iter');
      all_shift_vectors(jd,jz,:) = driftvec;
    end
  end
  
  % save shift estimates
  savefilename = 'shift_estimation_AiryScan.mat';
  save(outputdatadir,savefilename,'all_shift_vectors');

  % make plot of retrieved detector geometry
  mean_all_shift_vectors = squeeze(mean(all_shift_vectors,2));
  std_all_shift_vectors = squeeze(std(all_shift_vectors,[],2));
  figure
  errorbarxy(mean_all_shift_vectors(:,1),mean_all_shift_vectors(:,2),std_all_shift_vectors(:,1),std_all_shift_vectors(:,2),{'--ro','r','r'})
    
end

%%
% find match between shift estimates and known detector geometry

% load shift estimates
loadfilename = strcat(outputdatadir,'shift_estimation_AiryScan.mat');
load(loadfilename,'all_shift_vectors');
mean_all_shift_vectors = squeeze(mean(all_shift_vectors,2));
std_all_shift_vectors = squeeze(std(all_shift_vectors,[],2));

% Bravais lattice of all detector elements
scalepar = 1.0;
bravais_basisvector_1 = scalepar*[0 2/sqrt(3)];
bravais_basisvector_2 = scalepar*[1 1/sqrt(3)];
all_lattice_indices = [1 -3; 2 -3;...
  -1 -2; 0 -2; 1 -2; 2 -2; 3 -2;...
  -2 -1; -1 -1; 0 -1; 1 -1; 2 -1; 3 -1;...
  -2 0; -1 0; 0 0; 1 0; 2 0; 3 0;...
  -3 1; -2 1; -1 1; 0 1; 1 1; 2 1;...
  -3 2; -2 2; -1 2; 0 2; 1 2;...
  -2 3; -1 3;];
all_lattice_vectors = zeros(size(all_lattice_indices));
for jinds = 1:size(all_lattice_indices,1)
  latvec = all_lattice_indices(jinds,1)*bravais_basisvector_1+all_lattice_indices(jinds,2)*bravais_basisvector_2;
  all_lattice_vectors(jinds,:) = latvec;
end

% make plot of retrieved detector geometry
figure
set(gcf,'units','pixels');
set(gcf,'Position',[100 160 450 450]);
box on 
hold on
errorbarxy(mean_all_shift_vectors(:,1),mean_all_shift_vectors(:,2),std_all_shift_vectors(:,1),std_all_shift_vectors(:,2),{'--ro','r','r'})
xlim([-6 6])
ylim([-6 6])
axis square
set(gca,'FontSize',12)

figure
set(gcf,'units','pixels');
set(gcf,'Position',[100 160 450 450]);
box on 
hold on
plot(mean_all_shift_vectors(:,1),mean_all_shift_vectors(:,2),'-ro')
plot(all_lattice_vectors(:,1),all_lattice_vectors(:,2),'kx')
xlim([-6 6])
ylim([-6 6])
axis square
set(gca,'FontSize',12)

% manually shift found shift vectors towards right lattice point
mean_all_shift_vectors(22,1) = mean_all_shift_vectors(22,1)+1/2;
mean_all_shift_vectors(23,1) = mean_all_shift_vectors(23,1)+1;
mean_all_shift_vectors(24,1) = mean_all_shift_vectors(24,1)+1/2;
mean_all_shift_vectors(29,1) = mean_all_shift_vectors(29,1)+1;
mean_all_shift_vectors(30,1) = mean_all_shift_vectors(30,1)+1/2;
mean_all_shift_vectors(30,2) = mean_all_shift_vectors(30,2)-1;
mean_all_shift_vectors(31,2) = mean_all_shift_vectors(31,2)-1;
mean_all_shift_vectors(32,2) = mean_all_shift_vectors(32,2)-3/2;

% make plot of retrieved detector geometry
figure
box on 
hold on
plot(mean_all_shift_vectors(:,1),mean_all_shift_vectors(:,2),'-ro')
plot(all_lattice_vectors(:,1),all_lattice_vectors(:,2),'kx')
xlim([-4 4])
ylim([-4 4])
axis square
set(gca,'FontSize',12)

% make match between the elements of alldriftvecs and the right lattice
% indices
true_lattice_indices = zeros(size(all_lattice_indices));
true_lattice_vectors = zeros(size(all_lattice_vectors));
for jd = 1:size(all_shift_vectors,1)
  disties = sqrt((all_lattice_vectors(:,1)-mean_all_shift_vectors(jd,1)).^2+(all_lattice_vectors(:,2)-mean_all_shift_vectors(jd,2)).^2);
  [minval, minind] = min(disties);
  true_lattice_indices(jd,:) = all_lattice_indices(minind,:);
  true_lattice_vectors(jd,:) = all_lattice_vectors(minind,:);
end

%%
% single image gain calibration

fprintf('...gain and offset correction for obtaining image data in detected photon counts\n')
  
dogaincalibration = 0;

if dogaincalibration
  
  % original pcfo method
  gainstore = zeros(Nz,1);
  offsetstore = zeros(Nz,1);
  for jz = 1:Nz
    k_thres = 0.9; % parameter settings for the pcfo function
    AvoidCross = 1; % parameter settings for the pcfo function
    doPlot = 0; % parameter settings for the pcfo function
    Tiles = [3 3]; % parameter settings for the pcfo function
    RNStd = 0.0; % readout noise std
    jd = 1; % central detector element
    tempim = squeeze(allimages_ISM(:,:,jz,jd));
    [gainest,offsetest] = pcfo(tempim,k_thres,RNStd,AvoidCross,doPlot,Tiles);
    gainstore(jz) = gainest;
    offsetstore(jz) = offsetest;
  end
  % take median for typical gain and offset estimate
  % median instead of mean is more outlier robust
  gain = median(gainstore(:));
  offset = median(offsetstore(:));
  stdgain = std(gainstore);
  stdoffset = std(offsetstore);

  % save gain and offset estimates
  savefilename = 'gain_offset_estimation_AiryScan.mat';
  save(savefilename,'gainstore','offsetstore');
else
  gain = 4.48; % 1FRC is near perfect for gain=5, this may be the true setting
  offset = 0.0; % estimation gives value very close to zero (0.0139), this is what we will set it to
end

%%
allimages_ISM = (allimages_ISM-offset)/gain;
maxval = max(allimages_ISM(:));
minval = min(allimages_ISM(:));

minpixval = 0;
allimages_ISM = max(allimages_ISM,minpixval);

%%
% make ISM reconstruction by the shift by 1/2 and add principle

fprintf('...make ISM reconstruction\n')

% make confocal reconstruction as reference by just adding all the
% detector signals
reconstruction_confocal = sum(allimages_ISM,4);

% image shift scale factor, this has been optimized for the highest FRC
% the optimum is in between 0.5 and 1.0 x lattice_vector, safe to take
% value 1 as this is expected from theory 
reconstruction_ISM = zeros(Nx,Ny,Nz);
selecz = 1:Nz;

for jd = 1:Nd
  lattice_vector = true_lattice_vectors(jd,:);
  fprintf(strcat('detector element #',num2str(jd),'\n'))
  for jz = selecz
    tempim = squeeze(allimages_ISM(:,:,jz,jd));
    addim = im2mat(shift(tempim,lattice_vector));
    reconstruction_ISM(:,:,jz) = reconstruction_ISM(:,:,jz)+addim;
  end
end

%%
% rotate to same orientation as RCM dataset
% then crop to same 1024x1024 squared area as RCM dataset
% correct from 1024x1024 to 43.3333/42.5713=1.0179 larger area of 1042x1042
% to compensate for difference in pixel size

reconstruction_ISM = rot90(reconstruction_ISM);
reconstruction_confocal = rot90(reconstruction_confocal);
xstart = 60;
ystart = 45;
cropx = xstart:xstart+1041;
cropy = ystart:ystart+1041;
reconstruction_ISM = reconstruction_ISM(cropx,cropy,:);
reconstruction_confocal = reconstruction_confocal(cropx,cropy,:);
[Nx,Ny,Nz] = size(reconstruction_ISM);

%%
% make image splits

fprintf('...make random binomial image splits\n')

numsplits = 10; % # different splits for sufficient statistics
reconstruction_ISM_split = zeros(Nx,Ny,Nz,2,numsplits);
reconstruction_confocal_split = zeros(Nx,Ny,Nz,2,numsplits);

for jsplit = 1:numsplits
  fprintf(strcat('random split #',num2str(jsplit),'\n'))
  for jz = 1:Nz
    tempim = squeeze(reconstruction_ISM(:,:,jz));
    [imsplitA,imsplitB] = cBinomialSplit(tempim);
    reconstruction_ISM_split(:,:,jz,1,jsplit) = imsplitA;
    reconstruction_ISM_split(:,:,jz,2,jsplit) = imsplitB;
    tempim = squeeze(reconstruction_confocal(:,:,jz));
    [imsplitA,imsplitB] = cBinomialSplit(tempim);
    reconstruction_confocal_split(:,:,jz,1,jsplit) = imsplitA;
    reconstruction_confocal_split(:,:,jz,2,jsplit) = imsplitB;
  end
end

%%
% compute single image FRC values

fprintf('...compute FRC curves\n')
  
Nfrc = round((Nx-1)/sqrt(2));
allfrccurves_ISM = zeros(Nz,Nfrc,numsplits);
allfrcres_ISM = zeros(Nz,numsplits);
allfrccurves_confocal = zeros(Nz,Nfrc,numsplits);
allfrcres_confocal = zeros(Nz,numsplits);
for jsplit = 1:numsplits
  fprintf(strcat('random split #',num2str(jsplit),'\n'))
  for jz = selecz
    image1 = reconstruction_ISM_split(:,:,jz,1,jsplit);
    image2 = reconstruction_ISM_split(:,:,jz,2,jsplit);

    frccurve = frcbis(mat2im(image1),mat2im(image2));
    smoothfac = 7;
    frccurve = movmean(frccurve,smoothfac); % moving average to smooth curve for display purposes
    allfrccurves_ISM(jz,:,jsplit) = frccurve; % no pre-allocation to adjust #columns to frccurve
    [allfrcres_ISM(jz,jsplit),~,~] = frctoresolution(frccurve,Nx);
    
    image1 = reconstruction_confocal_split(:,:,jz,1,jsplit);
    image2 = reconstruction_confocal_split(:,:,jz,2,jsplit);

    frccurve = frcbis(mat2im(image1),mat2im(image2));
    smoothfac = 7;
    frccurve = movmean(frccurve,smoothfac); % moving average to smooth curve for display purposes
    allfrccurves_confocal(jz,:,jsplit) = frccurve; % no pre-allocation to adjust #columns to frccurve
    [allfrcres_confocal(jz,jsplit),~,~] = frctoresolution(frccurve,Nx);
  end
end

allfrcres_ISM = pixelsize*allfrcres_ISM;
allfrcres_confocal = pixelsize*allfrcres_confocal;

%%
% SSNR analysis

fprintf('...compute SSNR\n')

% compute ring averaged power spectrum
numbins = round(sqrt(Nx*Ny)/2); % number of bins for the ring averaging needed to estimate the SSNR
offs = [floor(Nx/2)+1-(Nx+1)/2,floor(Ny/2)+1-(Ny+1)/2]; % indexing of zero spatial frequency
pixelszs = [1/Nx/pixelsize,1/Ny/pixelsize]; % pixel sizes in Fourier space
signalpower_ISM_avg = zeros(Nx,Ny,Nz);
signalpower_ISM_avg_ring = zeros(numbins,Nz);
noisepower_ISM_avg = zeros(Nx,Ny,Nz);
noisepower_ISM_avg_ring = zeros(numbins,Nz);
signalpower_confocal_avg = zeros(Nx,Ny,Nz);
signalpower_confocal_avg_ring = zeros(numbins,Nz);
noisepower_confocal_avg = zeros(Nx,Ny,Nz);
noisepower_confocal_avg_ring = zeros(numbins,Nz);
for jz = 1:Nz
  tempim = reconstruction_ISM(:,:,jz);
  fttempim = fftshift(fft2(tempim));
  signalpower = abs(fttempim).^2;
  noisepower = sum(tempim(:))*ones(size(signalpower));
  [signalpower_ISM_avg(:,:,jz),signalpower_ISM_avg_ring(:,jz),~,~] = radialavgmat(signalpower,numbins,offs,pixelszs);
  [noisepower_ISM_avg(:,:,jz),noisepower_ISM_avg_ring(:,jz),~,~] = radialavgmat(noisepower,numbins,offs,pixelszs);
  tempim = reconstruction_confocal(:,:,jz);
  fttempim = fftshift(fft2(tempim));
  signalpower = abs(fttempim).^2;
  noisepower = sum(tempim(:))*ones(size(signalpower));
  [signalpower_confocal_avg(:,:,jz),signalpower_confocal_avg_ring(:,jz),~,~] = radialavgmat(signalpower,numbins,offs,pixelszs);
  [noisepower_confocal_avg(:,:,jz),noisepower_confocal_avg_ring(:,jz),~,~] = radialavgmat(noisepower,numbins,offs,pixelszs);
end

% compute SSNR
epsy = 1e2*eps;
SSNRest_ISM = signalpower_ISM_avg./noisepower_ISM_avg-1;
SSNRest_ISM_ring = signalpower_ISM_avg_ring./noisepower_ISM_avg_ring-1;
SSNRest_ISM(isnan(SSNRest_ISM)) = epsy;
SSNRest_ISM_ring(isnan(SSNRest_ISM_ring)) = epsy;
SSNRest_ISM(isinf(SSNRest_ISM)) = epsy;
SSNRest_ISM_ring(isinf(SSNRest_ISM_ring)) = epsy;
SSNRest_ISM(SSNRest_ISM<epsy) = epsy;
SSNRest_ISM_ring(SSNRest_ISM_ring<epsy) = epsy;
SSNRest_confocal = signalpower_confocal_avg./noisepower_confocal_avg-1;
SSNRest_confocal_ring = signalpower_confocal_avg_ring./noisepower_confocal_avg_ring-1;
SSNRest_confocal(isnan(SSNRest_confocal)) = epsy;
SSNRest_confocal_ring(isnan(SSNRest_confocal_ring)) = epsy;
SSNRest_confocal(isinf(SSNRest_confocal)) = epsy;
SSNRest_confocal_ring(isinf(SSNRest_confocal_ring)) = epsy;
SSNRest_confocal(SSNRest_confocal<epsy) = epsy;
SSNRest_confocal_ring(SSNRest_confocal_ring<epsy) = epsy;

%%
% save results

fprintf('...save data\n')

savefilename = strcat(outputdatadir,'ISMresults_store_gain4p48');
save(savefilename,'reconstruction_ISM','reconstruction_confocal',...
  'allfrccurves_ISM','allfrcres_ISM','allfrccurves_confocal','allfrcres_confocal',...
  'signalpower_ISM_avg','signalpower_ISM_avg_ring','noisepower_ISM_avg','noisepower_ISM_avg_ring',...
  'signalpower_confocal_avg','signalpower_confocal_avg_ring','noisepower_confocal_avg','noisepower_confocal_avg_ring',...
  'SSNRest_ISM','SSNRest_ISM_ring','SSNRest_confocal','SSNRest_confocal_ring',...
  'gain','offset','pixelsize','axialdistance','lambda','NA')

%%
% plot FRC curves

[Nx,Ny,Nz] = size(reconstruction_ISM);
numbins = size(SSNRest_ISM_ring,1);
Nfrc = size(allfrccurves_ISM,2);
numsplits = size(allfrccurves_ISM,3);
spatfreq = (0:(Nfrc-1))/sqrt(2)/pixelsize/Nfrc;
centralslice = (Nz+1)/2;
allz = ((1:Nz)-centralslice)*axialdistance;
qxy = (0:(Nfrc-1))/sqrt(2)/pixelsize/Nfrc;
mean_allfrccurves_ISM = mean(allfrccurves_ISM,3);
mean_allfrccurves_confocal = mean(allfrccurves_confocal,3);
mean_allfrcres_ISM = mean(allfrcres_ISM,2);
mean_allfrcres_confocal = mean(allfrcres_confocal,2);
std_allfrcres_ISM = std(allfrcres_ISM,[],2);
std_allfrcres_confocal = std(allfrcres_confocal,[],2);

figure
hold on
box on
plot(1e3*spatfreq,mean_allfrccurves_ISM','r')
plot(1e3*spatfreq,mean_allfrccurves_confocal','b')
plot(1e3*spatfreq,ones(size(spatfreq))*(1/7),'-k')
xlabel('axial position (nm)')
ylabel('FRC')
legend('ISM','confocal','1/7 threshold')
xlim([0 10])
ylim([-0.2 1.0])

figure
set(gcf,'units','pixels');
set(gcf,'Position',[800 360 500 400]);
box on
hold on
frcscale = [-0.2 1.0];
imagesc(allz,1e3*spatfreq,mean_allfrccurves_ISM',frcscale)
set(gca,'YDir','normal');
colormap parula
colorbar
contourset_frc = [0.143,0.143];
contour(allz,1e3*spatfreq,mean_allfrccurves_ISM',contourset_frc,'k','LineWidth',1,'ShowText','off');
xlabel('axial position (nm)')
ylabel('spatial frequency (1/{\mu}m)')
% title('FRC ISM')
set(gca,'FontSize',16)
xlim([-500 500])
ylim([0 8])
savefilename = 'FRCplot_ISM.svg';
saveas(gcf,savefilename)

figure
set(gcf,'units','pixels');
set(gcf,'Position',[800 320 500 400]);
box on
hold on
frcscale = [-0.2 1.0];
imagesc(allz,1e3*spatfreq,mean_allfrccurves_confocal',frcscale)
set(gca,'YDir','normal');
colormap parula
colorbar
contourset_frc = [0.143,0.143];
contour(allz,1e3*spatfreq,mean_allfrccurves_confocal',contourset_frc,'k','LineWidth',1,'ShowText','off');
xlabel('axial position (nm)')
ylabel('spatial frequency (1/{\mu}m)')
% title('FRC confocal')
xlim([-500 500])
ylim([0 8]) 
set(gca,'FontSize',16)
savefilename = 'FRCplot_confocal.svg';
saveas(gcf,savefilename)

figure
set(gcf,'units','pixels');
set(gcf,'Position',[800 280 440 400]);
box on
hold on
plot(allz,mean_allfrcres_ISM,'-or','MarkerSize',8,'LineWidth',2)
% errorbar(allz(selecz),mean_allfrcres_ISM,std_allfrcres_ISM,'-or')
xlabel('axial position (nm)')
ylabel('FRC-resolution (nm)')
xlim([-600 600])
ylim([0 300])
set(gca,'FontSize',16)
savefilename = 'FRCresolution_ISM.svg';
saveas(gcf,savefilename)

figure
set(gcf,'units','pixels');
set(gcf,'Position',[800 240 440 400]);
box on
hold on
plot(allz,mean_allfrcres_confocal,'-or','MarkerSize',8,'LineWidth',2)
% errorbar(allz(selecz),mean_allfrcres_confocal,std_allfrcres_confocal,'-or')
plot(allz,ones(size(allz))*(lambda/2/NA),'--k')
xlabel('axial position (nm)')
ylabel('FRC-resolution (nm)')
xlim([-600 600])
ylim([0 300])
set(gca,'FontSize',16)
savefilename = 'FRCresolution_confocal.svg';
saveas(gcf,savefilename)

% compute median plateau above diffraction limit
allfrcplateau = allfrccurves_confocal(:,spatfreq>2*NA/lambda,:);
frcplateau_confocal = median(allfrcplateau(:));
allfrcplateau = allfrccurves_ISM(:,spatfreq>2*NA/lambda,:);
frcplateau_ISM = median(allfrcplateau(:));

qxy = (0:(numbins-1))/sqrt(2)/pixelsize/numbins;
figure
set(gcf,'units','pixels');
set(gcf,'Position',[800 200 500 400]);
box on
hold on
ssnrscale = [0 6];
imagesc(allz,1e3*qxy,log(1+SSNRest_ISM_ring)/log(10),ssnrscale)
set(gca,'YDir','normal');
colormap parula
colorbar
contourset_ssnr = [log(1+2)/log(10),log(1+20)/log(10),log(1+200)/log(10)];
contour(allz,1e3*qxy,log(1+SSNRest_ISM_ring)/log(10),contourset_ssnr,'k','LineWidth',1,'ShowText','off');
xlabel('axial position (nm)')
ylabel('spatial frequency (1/{\mu}m)')
% title('SSNR ISM')
set(gca,'FontSize',16)
xlim([-500 500])
ylim([0 8])
savefilename = 'SSNRplot_ISM.svg';
saveas(gcf,savefilename)

figure
set(gcf,'units','pixels');
set(gcf,'Position',[800 160 500 400]);
box on
hold on
ssnrscale = [0 6];
imagesc(allz,1e3*qxy,log(1+SSNRest_confocal_ring)/log(10),ssnrscale)
set(gca,'YDir','normal');
colormap parula
colorbar
contourset_ssnr = [log(1+2)/log(10),log(1+20)/log(10),log(1+200)/log(10)];
contour(allz,1e3*qxy,log(1+SSNRest_confocal_ring)/log(10),contourset_ssnr,'k','LineWidth',1,'ShowText','off');
xlabel('axial position (nm)')
ylabel('spatial frequency (1/{\mu}m)')
set(gca,'FontSize',16)
xlim([-500 500])
ylim([0 8]) 
savefilename = 'SSNRplot_confocal.svg';
saveas(gcf,savefilename)

%% 
% make figures

for plotinset = [0 1]
% define crop region
if plotinset
  cropx = 561:870;
  cropy = 551:860;
  scalebarlength = 2;
else
  cropx = 1:Nx;
  cropy = 1:Ny;
  scalebarlength = 6;
end

% scale bar settings
width = 1000*(scalebarlength/(length(cropx))/pixelsize);
scalebarstring = strcat(num2str(scalebarlength),' {\mu}m');

for jz = selecz
  
  figure
  set(gcf,'units','pixels');
  set(gcf,'Position',[100 160 320 320]);
  imagesc(reconstruction_ISM(cropx,cropy,jz))
  colormap gray
  set(gca,'position',[0 0 1 1],'units','normalized')
  axis square
  axis off
  axis tight
  annotation('rectangle',[0.06 0.03 width 0.02],'FaceColor','white','Color','white');
  annotation('textbox',[0.04 0.09 3*width 0.06],'String',scalebarstring,'FontSize',16,'Edgecolor','none','Color','white');
  savefilename = strcat('ISMimage_jz',num2str(jz),'.svg');
  if plotinset
    savefilename = strcat('insetISMimage_jz',num2str(jz),'.svg');
  end
  saveas(gcf,savefilename)
  
  figure
  set(gcf,'units','pixels');
  set(gcf,'Position',[100 160 320 320]);
  imagesc(reconstruction_confocal(cropx,cropy,jz))
  colormap gray
  set(gca,'position',[0 0 1 1],'units','normalized')
  axis square
  axis off
  axis tight
  annotation('rectangle',[0.06 0.03 width 0.02],'FaceColor','white','Color','white');
  annotation('textbox',[0.04 0.09 3*width 0.06],'String',scalebarstring,'FontSize',16,'Edgecolor','none','Color','white');
  savefilename = strcat('confocalimage_jz',num2str(jz),'.svg');
  if plotinset
    savefilename = strcat('insetconfocalimage_jz',num2str(jz),'.svg');
  end
  saveas(gcf,savefilename)

end

end

%% 
% make movie files, through focus

for plotinset = [0 1]
% define crop region
if plotinset
  cropx = 561:870;
  cropy = 551:860;
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
writerObjISM = VideoWriter('ISM_throughfocus.avi');
writerObjISM.FrameRate = 1;
open(writerObjISM);

selecz = 1:Nz;
for jz = selecz
  figure(101)
  set(gcf,'units','pixels');
  set(gcf,'Position',[100 160 320 320]);
  imagesc(reconstruction_ISM(cropx,cropy,jz))
  colormap(mappy)
  set(gca,'position',[0 0 1 1],'units','normalized')
  axis square
  axis off
  axis tight
  if jz==min(selecz)
    annotation('rectangle',[0.06 0.03 width 0.02],'FaceColor','white','Color','white');
    annotation('textbox',[0.04 0.09 3*width 0.06],'String',scalebarstring,'FontSize',16,'Edgecolor','none','Color','white');
  end
  stringy = strcat('z = ',num2str(allz(jz)/1e3),'{\mu}m');
  if jz==min(selecz)
    glancm = annotation('textbox',[0.64 0.02 0.39 0.1],'String',stringy,'FontSize',16,'Edgecolor','none','Color','white');
  else
    glancm.String = stringy;
  end
  
  frame = getframe(gcf);
  writeVideo(writerObjISM,frame);
end 

close(writerObjISM);
clear writerObjISM

% create movie object
writerObjconfocal = VideoWriter('confocal_throughfocus.avi');
writerObjconfocal.FrameRate = 1;
open(writerObjconfocal);

for jz = selecz  
  figure(102)
  set(gcf,'units','pixels');
  set(gcf,'Position',[100 160 320 320]);
  imagesc(reconstruction_confocal(cropx,cropy,jz))
  colormap(mappy)
  set(gca,'position',[0 0 1 1],'units','normalized')
  axis square
  axis off
  axis tight
  if jz==min(selecz)
    annotation('rectangle',[0.06 0.03 width 0.02],'FaceColor','white','Color','white');
    annotation('textbox',[0.04 0.09 3*width 0.06],'String',scalebarstring,'FontSize',16,'Edgecolor','none','Color','white');
  end
  stringy = strcat('z = ',num2str(allz(jz)/1e3),'{\mu}m');
  if jz==min(selecz)
    glancm = annotation('textbox',[0.64 0.02 0.39 0.1],'String',stringy,'FontSize',16,'Edgecolor','none','Color','white');
  else
    glancm.String = stringy;
  end
  
  frame = getframe(gcf);
  writeVideo(writerObjconfocal,frame);
end

close(writerObjconfocal);
clear writerObjconfocal

end

