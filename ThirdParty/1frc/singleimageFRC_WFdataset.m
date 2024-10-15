% This script is for testing 1FRC on WF dataset.
%
% needs DIPimage, https://diplib.org/
%
% Sjoerd Stallinga, TU Delft, 2024

clear 
close all

addpath('C:\Program Files\DIPimage 2.9\common\dipimage');
dip_initialise;

%% 
% read in data

gainoffsetest = 0; % make single image gain/offset estimate
lambda = 612; % emission wavelength in nm
numsets = 16; % # datasets
allmag = [repmat(10,1,4) repmat(60,1,12)];
allNA = [repmat(0.25,1,4) repmat(0.70,1,12)];
camerapixelsize = 6.45e3; % camera pixel size in nm
allgain = [0.207 0.201 0.217 0.210 0.817 0.959 0.972 0.220 0.205 0.208 0.230 0.208 0.086 0.184 0.220 0.218]; % values found pcfo 
alloffset = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]; % dark image supplied, so zero offset
sigma_rn = 8.0; % rms readout noise, from https://www.digitalimagingsystems.co.uk/hardware/orca_er.html 

ids = [2:8 12 13 15 16]; % this is the selection that finally appeared in NM2013

for jset = ids
  datafilename = strcat('Data',num2str(jset),'.ics');
  pixelsize = camerapixelsize/allmag(jset);
  NA = allNA(jset);

  fprintf('...read in image data\n')
  a = bfopen(datafilename); % open datafile
  b = a{1,1}; % extract variables with image data
  allimages_raw = cell2mat(permute(b(:,1),[3 2 1])); % extract image data
  clear a b
  
  % read dark image
  datafilename = 'dark.ics';
  a = bfopen(datafilename); % open datafile
  b = a{1,1}; % extract variables with image data
  darkimset = cell2mat(permute(b(:,1),[3 2 1]));
  darkim = mean(darkimset,3);
  darkimvar = var(double(darkimset),[],3);
  sigma_rn_check = sqrt(mean(darkimvar(:)))/median(allgain); % this checks out as close to the reported value of 8e rms readout noise

  % extract dimensions, make square array if needed
  allimages_raw = double(allimages_raw);
  [Nx,Ny,numframes] = size(allimages_raw);
  for jf = 1:numframes
    allimages_raw(:,:,jf) = allimages_raw(:,:,jf)-darkim;
  end
  if Nx==Ny
    N = Nx;
  else
    if Nx>Ny
      N = Ny;
      allimages_raw = allimages_raw(1:N,:,:);
    else
      N = Nx;
      allimages_raw = allimages_raw(:,1:N,:);
    end
  end
  
  % make plots for inspecting
  mean_images = squeeze(mean(allimages_raw,3));
  var_images = squeeze(var(allimages_raw,0,3));
  allftimages = zeros(size(allimages_raw));
  for jf = 1: numframes
    tempim = allimages_raw(:,:,jf);
    allftimages(:,:,jf) = fftshift(fft2(tempim));
  end
  mean_ftimages = abs(squeeze(mean(allftimages,3)));
  var_ftimages = squeeze(var(allftimages,0,3));
  figure
  subplot(2,2,1)
  imagesc(mean_images)
  axis square
  axis off
  colorbar
  subplot(2,2,2)
  imagesc(var_images)
  axis square
  axis off
  colorbar
  subplot(2,2,3)
  imagesc(log(1+mean_ftimages)/log(10))
  axis square
  axis off
  colorbar
  subplot(2,2,4)
  imagesc(log(1+var_ftimages)/log(10))
  axis square
  axis off
  colorbar
    
  % single image gain/offset estimation
  fprintf('...gain/offset correction\n')
  if gainoffsetest
    k_thres = 0.9; % OTF cut-off
    rnstd = sigma_rn; % std readout noise
    tiles = [3 3];
    makeplot = 0;
    [gainstore_pcfo,offsetstore_pcfo] = pcfo_fftfix(allimages_raw,k_thres,rnstd,tiles,makeplot);
  
    % compute statistical parameters
    gain_median = median(gainstore);
    gain_mean = mean(gainstore);
    gain_std = std(gainstore);
    offset_median = median(offsetstore);
    offset_mean = mean(offsetstore);
    offset_std = std(offsetstore);
    crosspar_median = median(crossparstore);
    crosspar_mean = mean(crossparstore);
    crosspar_std = std(crossparstore);
    gain = gain_median;
    allgain(jset) = gain;
    offset = offset_median;
    alloffset(jset) = offset; 
    allimages_raw = (allimages_raw-offset)/gain;
  else
    gain = allgain(jset);
    offset = alloffset(jset);
    allimages_raw = (allimages_raw-offset)/gain;
  end
  
  % loop over frames, apply single image FRC method
  % modify to 2FRC between n and n+1 vs. add and split for these pairs, let
  % n=1,2,...,numframes, with numframes=20
  
  fprintf('...compute 2FRC and 1FRC curves and FRC resolution values\n')
  
  sample_image = allimages_raw(:,:,1);
  smoothfac = 7;
  Nfrc = floor((N-1)/sqrt(2)); 
  FRC2curves = zeros(Nfrc,numframes);
  FRC2resolutions = zeros(numframes,1);
  FRC1curves = zeros(Nfrc,numframes);
  FRC1resolutions = zeros(numframes,1);
  for jf = 1:numframes
    fprintf('frame %i\n',jf)
    tempim = allimages_raw(:,:,jf);
    jfnext = mod(jf,numframes)+1;
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
  savefilename = strcat('FRCresults',dataset,'_id',num2str(jset),'.mat');
  if gainoffsetest
    save(savefilename,'gainstore','offsetstore','crossparstore','lambda','NA','pixelsize',...
      'sample_image',...
      'FRC2curves','FRC2resolutions','FRC1curves','FRC1resolutions',...
      'meanFRC2curves','stdFRC2curves','meanFRC2resolutions','stdFRC2resolutions',...
      'meanFRC1curves','stdFRC1curves','meanFRC1resolutions','stdFRC1resolutions');
  else
    save(savefilename,'gain','offset','lambda','NA','pixelsize',...
      'sample_image',...
      'FRC2curves','FRC2resolutions','FRC1curves','FRC1resolutions',...
      'meanFRC2curves','stdFRC2curves','meanFRC2resolutions','stdFRC2resolutions',...
      'meanFRC1curves','stdFRC1curves','meanFRC1resolutions','stdFRC1resolutions');
  end

end

%%
% plot FRC across all images

fprintf('...plot 1FRC and 2FRC curves\n')

numsets = 16;
gainoffsetest = 0;
allmeanFRC1resolutions = zeros(numsets,1);
allstdFRC1resolutions = zeros(numsets,1);
allmeanFRC2resolutions = zeros(numsets,1);
allstdFRC2resolutions = zeros(numsets,1);

% create movie object
writerObjfrcwf = VideoWriter(strcat('FRC_wfrun_',dataset,'.avi'));
writerObjfrcwf.FrameRate = 1;
open(writerObjfrcwf);

for jset = ids
  
  % load data and statistics
  loadfilename = strcat('FRCresults',dataset,'_id',num2str(jset),'.mat');
  if gainoffsetest
    load(loadfilename,'gainstore','offsetstore','crossparstore','lambda','NA','pixelsize',...
      'sample_image',...
      'FRC2curves','FRC2resolutions','FRC1curves','FRC1resolutions',...
      'meanFRC2curves','stdFRC2curves','meanFRC2resolutions','stdFRC2resolutions',...
      'meanFRC1curves','stdFRC1curves','meanFRC1resolutions','stdFRC1resolutions');
  else
    load(loadfilename,'gain','offset','lambda','NA','pixelsize',...
      'sample_image',...
      'FRC2curves','FRC2resolutions','FRC1curves','FRC1resolutions',...
      'meanFRC2curves','stdFRC2curves','meanFRC2resolutions','stdFRC2resolutions',...
      'meanFRC1curves','stdFRC1curves','meanFRC1resolutions','stdFRC1resolutions');
  end
  allmeanFRC1resolutions(jset) = meanFRC1resolutions;
  allstdFRC1resolutions(jset) = stdFRC1resolutions;
  allmeanFRC2resolutions(jset) = meanFRC2resolutions;
  allstdFRC2resolutions(jset) = stdFRC2resolutions;

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
  set(gcf,'Position',[100 100 900 350]);
  subplot(1,2,1)
  maxval = round(max(sample_image(:)),-3);
  clims = [0,maxval];
  imagesc(sample_image,clims)
  colormap gray
  axis square
  axis off
  colorbar
  % annotation('rectangle',[0.13 0.44 0.26 0.04],'FaceColor','white','Color','white'); 
  % full width scalebar->0.26=1024x6.45 mu/60 = 110.08 mu, hence 25 mu = 0.26*25/110.08=0.059
  % full width scalebar->0.26=1024x6.45 mu/10 = 660.48 mu, hence 100 mu = 0.26*100/660.48=0.0394
  if (jset<=4)||(jset>=17)
    annotation('rectangle',[0.33 0.22 0.0394 0.02],'FaceColor','white','Color','white');
    scalebarlength = 100.0;
    scalebarstring = strcat(num2str(scalebarlength),' {\mu}m');
    annotation('textbox',[0.30 0.29 0.21 0.04],'String',scalebarstring,'FontSize',14,'Edgecolor','none','Color','white');
  else
    annotation('rectangle',[0.32 0.22 0.059 0.02],'FaceColor','white','Color','white');
    scalebarlength = 25.0;
    scalebarstring = strcat(num2str(scalebarlength),' {\mu}m');
    annotation('textbox',[0.312 0.28 0.21 0.04],'String',scalebarstring,'FontSize',14,'Edgecolor','none','Color','white');
  end
  subplot(1,2,2)
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
  rectangle('Position',[0 -0.2 20.0 1.2],'LineWidth',0.2)
  if (jset<=3)||(jset>=16)
    xlim([0 1.0])
    xticks([0 0.2 0.4 0.6 0.8 1.0])
  else
    xlim([0 6.0])
    xticks([0 1 2 3 4 5 6])
  end
  ylim([-0.2 1.0])
  yticks([-0.2 0 0.2 0.4 0.6 0.8 1.0])
  xlabel('spatial frequency [1/{\mu}m]')
  ylabel('FRC')
  axis square
  set(gca,'FontSize',12)
  set(gca,'XColor','k')
  set(gca,'LineWidth',0.5)
  legend({'1FRC','2FRC'},'Location','NorthEast');
  savefilename = strcat('frcplots_wf_id',num2str(jset),'.png');
  saveas(gcf,savefilename)

  frame = getframe(gcf);
  writeVideo(writerObjfrcwf,frame);

end

close(writerObjfrcwf);
clear writerObjfrcwf

%%

figure
hold on
box on
errorbar(1:length(ids),allmeanFRC1resolutions(ids),allstdFRC1resolutions(ids),'or','LineWidth',1,'MarkerSize',5)
errorbar(1:length(ids),allmeanFRC2resolutions(ids),allstdFRC2resolutions(ids),'ob','LineWidth',1,'MarkerSize',5)
plot(1:length(ids),lambda/2./allNA(ids),'ok','LineWidth',1,'MarkerSize',5)
xlim([0 length(ids)+1])
ylim([0 2000])
xlabel('image ID')
ylabel('FRC resolution [nm]')
legend({'1FRC','2FRC','{\lambda}/2NA'},'Location','North');
set(gca,'FontSize',12)
savefilename = 'frcvalues_wf.png';
saveas(gcf,savefilename)

