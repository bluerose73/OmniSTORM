% This script is for testing 1FRC on TEM datasets.
%
% needs DIPimage, https://diplib.org/
% needs EMIODist2, https://nl.mathworks.com/matlabcentral/fileexchange/27021-imagic-mrc-dm-and-star-file-i-o
%
% Sjoerd Stallinga, TU Delft, 2024

clear all
close all

addpath('C:\Program Files\DIPimage 2.9\common\dipimage');
dip_initialise;

addpath(genpath('EMIODist2'));

%% 
% read in data

dataset = '190117_02_00081_UnderDefocus0.6um'; % data TEM Jakobi lab

datafilename = strcat(dataset,'.mrc');
[~,metadata] = ReadMRC(datafilename);
Nx = metadata.nx;
Ny = metadata.ny;
numframes = 50;
pixelsize = 0.495; 

allimages = zeros(Nx,Ny,numframes);
for jframe = 1:numframes
  if jframe<10
    imindtxt = strcat('0',num2str(jframe));
  else
    imindtxt = num2str(jframe);
  end
  datafilename = strcat(datadir,dataset,'_frameImage-',imindtxt,'.mrcs');
  allimages(:,:,jframe) = ReadMRC(datafilename);
end
N = min([Nx,Ny]);
allimages = allimages(1:N,1:N,1:numframes);

%%
% compute 2FRC and 1FRC by even/odd pairwise computation, assumes
% numframes is an even number.

fprintf('...compute 2FRC and 1FRC curves and FRC resolution values\n')

sample_image = allimages(:,:,1);
smoothfac = 7;
Nfrc = floor((N-1)/sqrt(2)); % check
FRC2curves = zeros(Nfrc,numframes/2);
FRC2resolutions = zeros(numframes/2,1);
FRC1curves = zeros(Nfrc,numframes/2);
FRC1resolutions = zeros(numframes/2,1);
for jf = 1:numframes/2
  fnext = mod(jf,numframes)+1;
  fprintf('frame %i and %i\n',jf,jfnext)
  fprintf('frame %i and %i\n',2*jf-1,2*jf)
  tempim = allimages(:,:,2*jf-1);
  tempimnext = allimages(:,:,2*jf);
  FRCcurve = frcbis(tempim,tempimnext); % compute 2FRC curve
  FRCcurve = movmean(FRCcurve,smoothfac); % moving average to smooth curve for display purposes
  FRC2curves(:,jf) = FRCcurve;
  [FRCres,~,~] = frctoresolution(FRCcurve,N); % compute 2FRC resolution
  FRC2resolutions(jf) = FRCres*pixelsize;
  tempimsum = tempim+tempimnext; % sum image
  [tempim1,tempim2] = cBinomialSplit(tempimsum); % make the split
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
savefilename = strcat('FRCresults_TEM_',dataset,'.mat');
save(savefilename,'pixelsize','sample_image',...
    'FRC2curves','FRC2resolutions','FRC1curves','FRC1resolutions',...
    'meanFRC2curves','stdFRC2curves','meanFRC2resolutions','stdFRC2resolutions',...
    'meanFRC1curves','stdFRC1curves','meanFRC1resolutions','stdFRC1resolutions');

%%
% make plots of the results

fprintf('...plot 1FRC and 2FRC curves\n')

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
maxval = round(max(sample_image(:)),0);
maxval = 5;
clims = [0,maxval];
imagesc(sample_image,clims)
colormap gray
axis square
axis off
colorbar
annotation('rectangle',[0.34 0.22 0.0441 0.02],'FaceColor','white','Color','white');
scalebarlength = 300;
Ang = char(197);
scalebarstring = strcat(num2str(scalebarlength),Ang);
annotation('textbox',[0.331 0.28 0.21 0.04],'String',scalebarstring,'FontSize',14,'Edgecolor','none','Color','white');
subplot(1,2,2)
box on
hold on
jcol = 1;
plot(qr(1:round(cutofffac*Nfrc)),FRC1curve_mean(1:round(cutofffac*Nfrc)),allcols{jcol},'LineWidth',0.5)
jcol = 3;
plot(qr(1:round(cutofffac*Nfrc)),FRC2curve_mean(1:round(cutofffac*Nfrc)),allcols{jcol},'LineWidth',0.5)
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
rectangle('Position',[0 -0.2 0.1 1.2],'LineWidth',0.2)
xlim([0 0.1])
xticks([0 0.02 0.04 0.06 0.08 0.1])
ylim([-0.2 1.0])
yticks([-0.2 0 0.2 0.4 0.6 0.8 1.0])
xlabel(strcat('spatial frequency [1/',Ang,']'))
ylabel('FRC')
text(-0.16,1.0,'a','FontSize',16)
text(-0.02,1.0,'b','FontSize',16)
axis square
set(gca,'FontSize',12)
set(gca,'XColor','k')
set(gca,'LineWidth',0.5)
legend({'1FRC','2FRC'},'Location','NorthEast');
