% This script is for testing 1FRC on WF dataset.
%
% needs DIPimage, https://diplib.org/
%
% Sjoerd Stallinga, TU Delft, 2024

clear all
close all

addpath('C:\Program Files\DIPimage 2.9\common\dipimage');
dip_initialise;

%%

% read in averaged dark image
loadfilename = 'overalldarkimresults.mat';
load(loadfilename,'mean_meandarkims','mean_stddarkims','mean_rnstd')

% read in image data
alldatasets = {'100X_ex_80ms_filter_c3_H_SNR_1',...
               '100X_ex_170ms_filter_cy3b_H_SNR_1'};
numdatasets = numel(alldatasets);

% microscope and dye data, from manual test slide:
% DAPI 358 † 461 †
% Alexa Fluor® 488 phalloidin 505 512
% MitoTracker® Red CMXRos 579 ‡ 599 ‡
% last two channels are imaged as "cy3" and "cy3b"
lambda_cy3 = 512;
lambda_cy3b = 599;
alllambda = [512 599];
allNA = [1.5 1.5];
allmag = [100 100];
camerapixelsize = 6.5*1e3;
allpixelsize = camerapixelsize./allmag;
allcutoff = 2*allNA./alllambda;
allkthr = 2*allcutoff.*allpixelsize; % degree of oversampling/undersampling

% cropsizes 
cropsizes = [3200 3200];
cropcenterx = [1600 1600];
cropcentery = [1600 1600];

% read in all data, inspect, and compute 1FRC and 2FRC
for jd = 1:numdatasets
  dataset = alldatasets{jd};
  fprintf(strcat(dataset,'\n'))
  fprintf('...read in image data\n')
  datafilename = strcat(dataset,'_MMStack_Default.ome.tif');
  imheader = imfinfo(datafilename);
  numframes = length(imheader);
  N = imheader.Width; % assume square images
  allimages_raw = zeros(N,N,numframes);
  for jframe = 1:numframes
    allimages_raw(:,:,jframe) = imread(datafilename,jframe);
  end
  pixelsize = allpixelsize(jd);
  lambda = alllambda(jd);
  NA = allNA(jd);
   
  % gain/offset correction
  gain = 3.0;
  offset = 100;
  sigma_rn = 1.66;
  for jframe = 1:numframes
    allimages_raw(:,:,jframe) = (allimages_raw(:,:,jframe)-mean_meandarkims)/gain;
  end

  % crop datasets
  cropx = (cropcenterx(jd)-cropsizes(jd)/2+1):(cropcenterx(jd)+cropsizes(jd)/2);
  cropy = (cropcentery(jd)-cropsizes(jd)/2+1):(cropcentery(jd)+cropsizes(jd)/2);
  numframes = 10;
  allimages_raw = allimages_raw(cropx,cropy,1:numframes);
  N = size(allimages_raw,1);
  
  % inspect sample image
  sample_image = allimages_raw(:,:,1);
  figure
  imagesc(sample_image)
  axis square
  colorbar

  % compute 2FRC and 1FRC
  fprintf('...compute 2FRC and 1FRC curves and FRC resolution values\n')
  smoothfac = 7;
  Nfrc = floor((N-1)/sqrt(2)); % check
  FRC2curves = zeros(Nfrc,numframes);
  FRC2resolutions = zeros(numframes,1);
  FRC1curves = zeros(Nfrc,numframes);
  FRC1resolutions = zeros(numframes,1);
  for jf = 1:numframes
    jfnext = mod(jf,numframes)+1;
    fprintf('frame %i and %i\n',jf,jfnext)
    tempim = allimages_raw(:,:,jf);
    tempimnext = allimages_raw(:,:,jfnext);
    FRCcurve = frcbis(tempim,tempimnext); % compute 2FRC curve
    FRCcurve = movmean(FRCcurve,smoothfac); % moving average to smooth curve for display purposes
    FRC2curves(:,jf) = FRCcurve;
    [FRCres,~,~] = frctoresolution(FRCcurve,N); % compute 2FRC resolution
    FRC2resolutions(jf) = FRCres*pixelsize;
    tempimsum = tempim+tempimnext; % sum image
    tempimsum = tempimsum+2*sigma_rn^2; % add rms readout noise for compensating impact of Gaussian readout noise
    [tempim1,tempim2] = cBinomialSplit(tempimsum); % make the split
    tempim1 = tempim1-sigma_rn^2; % subtract rms readout noise for compensating impact of Gaussian readout noise
    tempim2 = tempim2-sigma_rn^2; % subtract rms readout noise for compensating impact of Gaussian readout noise
    FRCcurve = frcbis(tempim1,tempim2); % compute 1FRC curve
    FRCcurve = movmean(FRCcurve,smoothfac); % moving average to smooth curve for display purposes
    [FRCres,~,~] = frctoresolution(FRCcurve,N); % compute FRC 1resolution
    FRC1curves(:,jf) = FRCcurve;
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

  % store results
  savefilename = strcat('FRCresults',dataset,'.mat');
  save(savefilename,'gain','offset','lambda','NA','pixelsize',...
      'sample_image',...
      'FRC2curves','FRC2resolutions','FRC1curves','FRC1resolutions',...
      'meanFRC2curves','stdFRC2curves','meanFRC2resolutions','stdFRC2resolutions',...
      'meanFRC1curves','stdFRC1curves','meanFRC1resolutions','stdFRC1resolutions');

end

%%
% plot FRC across all images

fprintf('...plot 1FRC and 2FRC curves\n')

refims = cell(numdatasets);
for jd = 1:numdatasets
  dataset = alldatasets{jd};

  % load data and statistics
  loadfilename = strcat('FRCresults',dataset,'.mat');
  load(loadfilename,'gain','offset','lambda','NA','pixelsize',...
      'sample_image',...
      'FRC2curves','FRC2resolutions','FRC1curves','FRC1resolutions',...
      'meanFRC2curves','stdFRC2curves','meanFRC2resolutions','stdFRC2resolutions',...
      'meanFRC1curves','stdFRC1curves','meanFRC1resolutions','stdFRC1resolutions');
  
  refims{jd} = sample_image;

  % output values to screen
  fprintf('2FRC = %6.2f +/- %6.2f nm\n',meanFRC2resolutions,stdFRC2resolutions)
  fprintf('1FRC = %6.2f +/- %6.2f nm\n',meanFRC1resolutions,stdFRC1resolutions)

  % find spatial frequencies corresponding to the ring averages
  Nfrc = size(FRC1curves,1);
  qr = ((0:(Nfrc-1))/Nfrc)/sqrt(2)/pixelsize;
  
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
  set(gcf,'Position',[100 100 400 350]);
  box on
  hold on
  jcol = 1;
  plot(1e3*qr(1:round(cutofffac*Nfrc)),FRC1curve_mean(1:round(cutofffac*Nfrc)),allcols{jcol},'LineWidth',0.5)
  jcol = 3;
  plot(1e3*qr(1:round(cutofffac*Nfrc)),FRC2curve_mean(1:round(cutofffac*Nfrc)),allcols{jcol},'LineWidth',0.5)
  jcol = 1;
  harea1FRC = area(1e3*qr(1:round(cutofffac*Nfrc))',FRC1area(:,1:round(cutofffac*Nfrc))','FaceAlpha',0.3,'LineWidth',0.2);
  harea1FRC(1).FaceColor = 'w';
  harea1FRC(2).FaceColor = allfacecolors(jcol,:);
  harea1FRC(1).EdgeColor = allcols{jcol};
  harea1FRC(2).EdgeColor = allcols{jcol};
  jcol = 3;
  harea2FRC = area(1e3*qr(1:round(cutofffac*Nfrc))',FRC2area(:,1:round(cutofffac*Nfrc))','FaceAlpha',0.3,'LineWidth',0.2);
  harea2FRC(1).FaceColor = 'w';
  harea2FRC(2).FaceColor = allfacecolors(jcol,:);
  harea2FRC(1).EdgeColor = allcols{jcol};
  harea2FRC(2).EdgeColor = allcols{jcol};
  plot(1e3*qr,ones(size(qr))*1/7,'--k','LineWidth',0.5)
  rectangle('Position',[0 -0.2 8.0 1.2],'LineWidth',0.2)
  xlim([0 8])
  xticks([0 2 4 6 8])
  ylim([-0.2 1.0])
  yticks([-0.2 0 0.2 0.4 0.6 0.8 1.0])
  xlabel('spatial frequency [1/{\mu}m]')
  ylabel('FRC')
  axis square
  set(gca,'FontSize',12)
  set(gca,'XColor','k')
  set(gca,'LineWidth',0.5)
  legend({'1FRC','2FRC'},'Location','NorthEast');
end

% color example image
cropsizes = [1600 1600];
cropcenterx = [1600 1600];
cropcentery = [1600+800 1600+800];
cropx = (cropcenterx(jd)-cropsizes(jd)/2+1):(cropcenterx(jd)+cropsizes(jd)/2);
cropy = (cropcentery(jd)-cropsizes(jd)/2+1):(cropcentery(jd)+cropsizes(jd)/2);
immy1 = refims{1};
immy2 = refims{2};
immy1 = immy1(cropx,cropy);
immy2 = immy2(cropx,cropy);
C = imfuse(immy1,immy2,'falsecolor','Scaling','independent','ColorChannels',[2 1 2]);
figure
set(gcf,'Position',[200 200 350 350]);
image(C)
axis square
axis off
set(gca,'position',[0 0 1 1],'units','normalized')
% full width scalebar->1=1600x65 nm = 104 mu, hence 10 mu = 1*10/104=0.0962
annotation('rectangle',[0.86 0.02 0.0962 0.02],'FaceColor','white','Color','white');
scalebarlength = 10.0;
scalebarstring = strcat(num2str(scalebarlength),' {\mu}m');
annotation('textbox',[0.81 0.07 0.20 0.06],'String',scalebarstring,'FontSize',14,'Edgecolor','none','Color','white');

