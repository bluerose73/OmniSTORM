% This script is for testing 1FRC on STED dataset.
%
% needs DIPimage, https://diplib.org/
%
% Sjoerd Stallinga, TU Delft, 2024

clear all
close all

addpath('C:\Program Files\DIPimage 2.9\common\dipimage');
dip_initialise;

%% 
% read in data

dataset = '2021_10_05_XSTED_NileRed_variation_excitation_power_MLampe'; % data STED Heileman lab
datafilename = strcat(dataset,'.lif');
gain = 1; % gain very nearly equal to 1 from single image gain/offset estimation
offset = 0; % offset very nearly equal to 0 from single image gain/offset estimation
lambda = 580; % emission wavelength, reported in metadata
jchannel = 2; % there are three channels in this dataset, only channel 2 and 3 are relevant as they contain repeated images with same setting Idep
switch jchannel
  case 2
    pixelsize = 19.9; % pixel size in nm, channel 2
    NA = 1.4; % NA channel 2
    Idep = [0.10 25 25 25 25 50 50 50 50 100 100 100 100]; % tabulated depletion powers in % of max power
    Iexc = [6 20 20 20 20 20 20 20 20 20 20 20 20]; % tabulated excitation powers in % of max power
  case 3
    pixelsize = 19.6; % pixel size in nm, channel 3
    NA = 1.4; % NA channel 3
    Idep = [0.10 25 25 25 25 50 50 50 50 100 100 100 100]; % tabulated depletion powers in % of max power
    Iexc = [6 20 20 20 20 20 20 20 20 20 20 20 20]; % tabulated excitation powers in % of max power
end
  
fprintf('...read in image data\n')

a = bfopen(datafilename); % open datafile
metadata_orig = a{1,2}; % extract original metadata
metadataKeys = metadata_orig.keySet().iterator();
for i=1:metadata_orig.size()
  key = metadataKeys.nextElement();
  value = metadata_orig.get(key);
  fprintf('%s = %s\n', key, value)
end
metadata = a{4}; % extract OME metadata

a = bfopen(datafilename); % open datafile
b = a{jchannel,1}; % extract variables with image data
allimages_raw = cell2mat(permute(b(:,1),[3 2 1])); % extract image data
clear a b

% extract dimensions, make square array if needed
allimages_raw = double(allimages_raw);
[Nx,Ny,numframes] = size(allimages_raw);
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

%%
% single image gain/offset estimation
fprintf('...gain/offset correction\n')
allimages_raw = (allimages_raw-offset)/gain;

% loop over frames, apply single image FRC method
fprintf('...compute single and double image FRC curves and FRC resolution values\n')

% confocal reference
image_confocal = allimages_raw(:,:,1);
ints_confocal = sum(image_confocal,[1 2])/N^2;
numsplits = 5;
Nfrc = floor((N-1)/sqrt(2)); % check
allFRC_confocal_curves = zeros(Nfrc,numsplits);
allFRC_confocal_resolutions = zeros(numsplits,1);
for js = 1:numsplits
  [tempim1,tempim2] = cBinomialSplit(image_confocal); % make the split
  FRCcurve = frcbis(tempim1,tempim2); % compute FRC curve
  smoothfac = 7;
  FRCcurve = movmean(FRCcurve,smoothfac); % moving average to smooth curve for display purposes
  [FRCres,~,~] = frctoresolution(FRCcurve,N); % compute FRC resolution
  allFRC_confocal_curves(:,js) = FRCcurve;
  allFRC_confocal_resolutions(js) = FRCres*pixelsize;
end
% STED data
numIdeps = 3; % # data points depletion power
numreps = 4; % number of repeats
allimages_raw = reshape(allimages_raw(:,:,2:13),[N N numreps numIdeps]);
allimages_raw = permute(allimages_raw,[1 2 4 3]);
ints_sted = squeeze(sum(allimages_raw,[1 2]))/N^2;
all2FRC_sted_curves = zeros(Nfrc,numIdeps,numreps);
all2FRC_sted_resolutions = zeros(numIdeps,numreps);
all1FRC_sted_curves = zeros(Nfrc,numIdeps,numreps);
all1FRC_sted_resolutions = zeros(numIdeps,numreps);
for jp = 1:numIdeps
  for jr = 1:numreps
    jrnext = 1+mod(jr,numreps);
    tempim = allimages_raw(:,:,jp,jr);
    tempimnext = allimages_raw(:,:,jp,jrnext);
    FRCcurve = frcbis(tempim,tempimnext); % compute 2FRC curve
    FRCcurve = movmean(FRCcurve,smoothfac); % moving average to smooth curve for display purposes
    [FRCres,~,~] = frctoresolution(FRCcurve,N); % compute 2FRC resolution
    all2FRC_sted_curves(:,jp,jr) = FRCcurve;
    all2FRC_sted_resolutions(jp,jr) = FRCres*pixelsize;
    tempimsum = tempim+tempimnext; % sum image
    [tempim1,tempim2] = cBinomialSplit(tempimsum); % make the split
    FRCcurve = frcbis(tempim1,tempim2); % compute 1FRC curve
    FRCcurve = movmean(FRCcurve,smoothfac); % moving average to smooth curve for display purposes
    [FRCres,~,~] = frctoresolution(FRCcurve,N); % compute FRC 1resolution
    all1FRC_sted_curves(:,jp,jr) = FRCcurve;
    all1FRC_sted_resolutions(jp,jr) = FRCres*pixelsize;
  end
end

% store results
savefilename = strcat('FRCresults_STED_',dataset,'_jch',num2str(jchannel),'.mat');
save(savefilename,'gain','offset','lambda','NA','pixelsize',...
    'allimages_raw','image_confocal',...
    'ints_confocal','ints_sted',...
    'allFRC_confocal_curves','allFRC_confocal_resolutions',...
    'all2FRC_sted_curves','all2FRC_sted_resolutions',...
    'all1FRC_sted_curves','all1FRC_sted_resolutions');

%%
% plot results

fprintf('...plot single and double image FRC curves\n')

% compute mean and std
allmeanFRC_confocal_curves = mean(allFRC_confocal_curves,2);
allstdFRC_confocal_curves = std(allFRC_confocal_curves,[],2);
allmeanFRC_confocal_resolutions = mean(allFRC_confocal_resolutions);
allstdFRC_confocal_resolutions = std(allFRC_confocal_resolutions);
allmean2FRC_sted_curves = mean(all2FRC_sted_curves,3);
allstd2FRC_sted_curves = std(all2FRC_sted_curves,[],3);
allmean2FRC_sted_resolutions = mean(all2FRC_sted_resolutions,2);
allstd2FRC_sted_resolutions = std(all2FRC_sted_resolutions,[],2);
allmean1FRC_sted_curves = mean(all1FRC_sted_curves,3);
allstd1FRC_sted_curves = std(all1FRC_sted_curves,[],3);
allmean1FRC_sted_resolutions = mean(all1FRC_sted_resolutions,2);
allstd1FRC_sted_resolutions = std(all1FRC_sted_resolutions,[],2);
meanints_sted = mean(ints_sted,2);

% find spatial frequencies corresponding to the ring averages
Nfrc = size(all1FRC_sted_curves,1);
qr = ((0:(Nfrc-1))/Nfrc)/sqrt(2)/pixelsize;

% make plots of FRC curves
cutofffac = 1.0;
allcols = {'r','g','b'};
allfacecolors = [1.0 0.2 0.0;0.0 1.0 0.2;0.2 0.0 1.0];
figure
set(gcf,'units','pixels');
set(gcf,'Position',[150 150 500 350]);
box on
hold on

numIdeps = size(all1FRC_sted_curves,2);
for jp = numIdeps:-1:1
  FRC1curve_mean = allmean1FRC_sted_curves(:,jp)';
  FRC1curve_std = allstd1FRC_sted_curves(:,jp)';
  FRC1area = [FRC1curve_mean-FRC1curve_std;2*FRC1curve_std];
  FRC2curve_mean = allmean2FRC_sted_curves(:,jp)';
  FRC2curve_std = allstd2FRC_sted_curves(:,jp)';
  FRC2area = [FRC2curve_mean-FRC2curve_std;2*FRC2curve_std];
        
  jcol = 1;
  plot(1e3*qr(1:round(cutofffac*Nfrc)),FRC1curve_mean(1:round(cutofffac*Nfrc)),allcols{jcol},'LineWidth',0.5)
  jcol = 3;
  plot(1e3*qr(1:round(cutofffac*Nfrc)),FRC2curve_mean(1:round(cutofffac*Nfrc)),allcols{jcol},'LineWidth',0.5)
  jcol = 1;
  harea1 = area(1e3*qr(1:round(cutofffac*Nfrc))',FRC1area(:,1:round(cutofffac*Nfrc))','FaceAlpha',0.3,'LineWidth',0.2);
  harea1(1).FaceColor = 'w';
  harea1(2).FaceColor = allfacecolors(jcol,:);
  harea1(1).EdgeColor = allcols{jcol};
  harea1(2).EdgeColor = allcols{jcol};
  jcol = 3;
  harea2 = area(1e3*qr(1:round(cutofffac*Nfrc))',FRC2area(:,1:round(cutofffac*Nfrc))','FaceAlpha',0.3,'LineWidth',0.2);
  harea2(1).FaceColor = 'w';
  harea2(2).FaceColor = allfacecolors(jcol,:);
  harea2(1).EdgeColor = allcols{jcol};
  harea2(2).EdgeColor = allcols{jcol};
end

FRCcurve_mean = allmeanFRC_confocal_curves';
FRCcurve_std = allstdFRC_confocal_curves';
FRCarea = [FRCcurve_mean-FRCcurve_std;2*FRCcurve_std];
jcol = 1;
plot(1e3*qr(1:round(cutofffac*Nfrc)),FRCcurve_mean(1:round(cutofffac*Nfrc)),allcols{jcol},'LineWidth',0.5)
hareac = area(1e3*qr(1:round(cutofffac*Nfrc))',FRCarea(:,1:round(cutofffac*Nfrc))','FaceAlpha',0.3,'LineWidth',0.2);
hareac(1).FaceColor = 'w';
hareac(2).FaceColor = allfacecolors(jcol,:);
hareac(1).EdgeColor = allcols{jcol};
hareac(2).EdgeColor = allcols{jcol};

plot(1e3*qr,ones(size(qr))*1/7,'--k','LineWidth',0.5)
rectangle('Position',[0 -0.2 20.0 1.2],'LineWidth',0.2)
xlim([0 20.0])
ylim([-0.2 1.0])
xticks([0 4 8 12 16 20])
yticks([-0.2 0 0.2 0.4 0.6 0.8 1.0])
xlabel('spatial frequency [1/{\mu}m]')
ylabel('FRC')
set(gca,'FontSize',12)
legend('1FRC','2FRC')
savefilename = strcat(resultsdir,strcat('frccurves_sted_jch',num2str(jchannel),'.png'));
saveas(gcf,savefilename)

% Hell resolution formula
alpha = 1/7;
beta = 1.0;
Ideps = linspace(0,120,150);
STEDresformula = beta*(lambda/2/NA)./sqrt(1+alpha*Ideps); 

% decorrelation resolution Descloux et al
res_dcorr_confocal = 269.5545;
mean_res_dcorr_sted = [136.3175 112.5233 103.9679];
std_res_dcorr_sted = [1.6039 0.3549 8.3644];

% plot FRC as a function of depletion laser power
figure
set(gcf,'units','pixels');
set(gcf,'Position',[250 250 500 350]);
hold on
box on
Ideppy = [25 50 100];
errorbar(Ideppy,allmean1FRC_sted_resolutions,allstd1FRC_sted_resolutions,'or','LineWidth',1,'MarkerSize',5)
errorbar(Ideppy,allmean2FRC_sted_resolutions,allstd2FRC_sted_resolutions,'ob','LineWidth',1,'MarkerSize',5)
plot(Ideps,STEDresformula,'-k','LineWidth',1)
errorbar(Ideppy,mean_res_dcorr_sted,std_res_dcorr_sted,'om','LineWidth',1,'MarkerSize',5)
plot(0,res_dcorr_confocal,'om','LineWidth',1,'MarkerSize',5)
errorbar(0,allmeanFRC_confocal_resolutions,allstdFRC_confocal_resolutions,'or','LineWidth',1,'MarkerSize',5)
xlim([0 120])
ylim([0 300])
xlabel('depletion power [a.u.]')
ylabel('FRC resolution [nm]')
legend('1FRC','2FRC','STED formula','decorrelation')
set(gca,'FontSize',12)
savefilename = strcat(resultsdir,strcat('frcresolutions_sted_jch',num2str(jchannel),'.png'));
saveas(gcf,savefilename)

% make overview plot
figure
set(gcf,'units','pixels');
set(gcf,'Position',[300 300 500 350]);
tempim = allimages_raw(:,:,2,1);
maxval = round(max(tempim(:)),-2);
clims = [0,maxval];
imagesc(tempim,clims)
% colormap hot
colormap gray
axis square
axis off
colorbar
set(gca,'FontSize',12)
% annotation('rectangle',[0.165 0.34 0.566 0.04],'FaceColor','white','Color','white'); 
% full width scalebar->0.566=1024x19.9 nm = 20.38 mu, hence 5 mu = 0.566*5/20.38=0.139
annotation('rectangle',[0.57 0.14 0.139 0.02],'FaceColor','white','Color','white'); 
scalebarlength = 5.0;
scalebarstring = strcat(num2str(scalebarlength),' {\mu}m');
annotation('textbox',[0.578 0.205 0.21 0.04],'String',scalebarstring,'FontSize',14,'Edgecolor','none','Color','white');
savefilename = strcat('sted_overview_jch',num2str(jchannel),'.png');
saveas(gcf,savefilename)

% make plot of inset
cropy = 350:550;
cropx = 550:750;

figure
set(gcf,'units','pixels');
set(gcf,'Position',[850 150 500 350]);
tempim = image_confocal(cropx,cropy);
maxval = round(max(tempim(:)),-2);
clims = [0,maxval];
imagesc(image_confocal(cropx,cropy),clims)
colormap gray
axis square
axis off
colorbar
set(gca,'FontSize',16)
% annotation('rectangle',[0.164 0.14 0.566 0.04],'FaceColor','white','Color','white'); 
% full width scalebar->0.566=200x19.9 nm = 3.98 mu, hence 1 mu = 0.566/3.98=0.142
annotation('rectangle',[0.57 0.14 0.142 0.02],'FaceColor','white','Color','white'); 
scalebarlength = 1.0;
scalebarstring = strcat(num2str(scalebarlength),' {\mu}m');
annotation('textbox',[0.56 0.23 0.21 0.04],'String',scalebarstring,'FontSize',20,'Edgecolor','none','Color','white');
savefilename = strcat('sted_inset_confocal_jch',num2str(jchannel),'.png');
saveas(gcf,savefilename)

for jp = 1:numIdeps
  figure
  set(gcf,'units','pixels');
  set(gcf,'Position',[350 350 500 350]);
  tempim = allimages_raw(cropx,cropy,jp,1);
  maxval = round(max(tempim(:)),-2);
  clims = [0,maxval];
  imagesc(tempim,clims)
  colormap gray
  axis square
  axis off
  colorbar
  set(gca,'FontSize',16)
  savefilename = strcat('sted_inset_jch',num2str(jchannel),'_jp',num2str(jp),'.png');
  saveas(gcf,savefilename)
end
