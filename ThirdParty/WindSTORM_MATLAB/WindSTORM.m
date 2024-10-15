clc
clear
close all;
addpath('functions');

% WindSTORM V1.0 Beta, by Hongqiang Ma @ PITT, Jun 2018
% Note: The size of the image must be one of the following:
% 64x64; 128x128; 256x256; 512x512; 1024x1024.

%% Input parameters for the data set using the input dialog box
prompt = {'Enter data path name','Enter filename of the image sequence',...
    'Estimated average emitter intensity','Kernel width of the PSF'...
    'Count to photons ratio of the camera','Base line of the camera'};
title = 'Input';
dims = [1 50];
definput = {'.\data','EPFL_Microtubule_Alexa647.tif','10000','1.4','2','100'};
answer = inputdlg(prompt,title,dims,definput);
PathName = char(answer{1}); % the pathname of the dataset
Filename = char(answer{2}); % the file name
Intensity = str2num(answer{3}); % estimated average emitter intensity of the dataset
Sigma = str2num(answer{4}); % the kernel width of the PSF of the system
Count2photon = str2num(answer{5}); % count to photons ratio of the camera
Baseline = str2num(answer{6}); % base line of the camera
%% Examples on the defined parameters on the testing dataset
%----------Testing data set 1 (Reference data from---------------------%
%-------http://bigwww.epfl.ch/smlm/datasets/index.html?p=real-hd)------%
% PathName = '.\data';  % the pathname of the dataset
% Filename = 'EPFL_Microtubule_Alexa647.tif';  % the file name
% Intensity = 10000;  % estimated average emitter intensity of the dataset
% Sigma = 1.4; % the kernel width of the PSF of the system
% Count2photon = 2; % count to photons ratio of the camera
% Baseline = 100; % base line of the camera
%-----------------------------------------------------------------------%

%-----Testing data set 2 (Microtubles labeled with Alexa647)------------%
% PathName = '.\data';  % The testing data folder
% Filename = 'Cell_Microtubule_Alexa647.tif';  % the filename
% Intensity = 10000;  % estimated average emitter intensity of the dataset
% Sigma = 1.9; % the kernel width of the PSF of the system
% Count2photon = 0.45; % count to photons ratio of the camera
% Baseline = 100; % base line of the camera
%------------------------------------------------------------------------%

%-----Testing data set 3 (Microtubles labeled with mEoS3.2)--------------%
% PathName = '.\data';  % The testing data folder
% Filename = 'Cell_Microtubule_mEos32.tif';  % the file name
% Intensity = 1000;  % estimated average emitter intensity of the dataset
% Sigma = 1.5; % the kernel width of the PSF of the system
% Count2photon = 0.45; % count to photons ratio of the camera
% Baseline = 100; % base line of the camera
%------------------------------------------------------------------------%

%-----Testing data set 4 (Chromatin labeled with Alexa647)------------%
% PathName = '.\data';  % The testing data folder
% Filename = 'Tissue_Chromatin_Alexa647.tif';  % the file name
% Intensity = 10000;  % estimated average emitter intensity of the dataset
% Sigma = 1.9; % the kernel width of the PSF of the system
% Count2photon = 0.45; % count to photons ratio of the camera
% Baseline = 100; % base line of the camera
%------------------------------------------------------------------------%
%% Read image
minIntensity = Intensity/4;   % a global threshold set to eliminate very weak emitters
% read image
[imRAW,imW,imH] = ImageRead([PathName,'\',Filename],Baseline,Count2photon);
%% WindSTORM step 1: Wind Deconvolution
t1=clock; % start the timer

% background subtraction 
[imBS,imBG] = BgSub(imRAW); %(background:10~1000)
%[imBS,imBG] = BgSub_low(imRAW); %(background:1~10)

% wind deconvolution and peak finding
[imDeconv, imPeak] = WindDeconv(imBS,Sigma,imBG,minIntensity);

%% WindSTORM step 2: Emitter extraction and localization
% emitter extraction
[ROI,ROIsub,IDs,x0,y0] = ExtractROIs(imDeconv,imPeak,imBS,Sigma);

% emitter localization
[Xc, Yc, T, fn] = GradientFit(ROI,ROIsub,IDs,x0,y0);

t2=clock; % stop the timer
disp(['Total computation time is ',num2str(etime(t2,t1)),' seconds']);
disp(['Total localization number is ',num2str(length(Xc))]);

%% save results
result(:,1) = 1:length(Xc);
result(:,2) = fn;
result(:,3) = Xc;
result(:,4) = Yc;
result(:,5) = T;
dhead = '"id","frame","x [pix]","y [pix]","intensity [photon]"';
fid = fopen( [Filename(1:end-4) '_WindSTORM.csv'], 'w' );
fprintf( fid, '%s\n', dhead);
fclose( fid );
dlmwrite([Filename(1:end-4) '_WindSTORM.csv'],result,'-append');

%% image rendring
% imSR = zeros(imW*5,imH*5);
% for n=1:length(Xc)
%     if (Xc(n)<imW) && (Yc(n)<imH) && (Xc(n)>1) && (Yc(n)>1) 
%         imSR(round(Yc(n)*5),round(Xc(n)*5)) = imSR(round(Yc(n)*5),round(Xc(n)*5)) +1;
%     end
% end
% imSR = filter2(ones(3,3)/9,imSR);
% clims = [0 2];
% imagesc(imSR,clims)
% axis image, axis off
% colormap(gray), colorbar;


