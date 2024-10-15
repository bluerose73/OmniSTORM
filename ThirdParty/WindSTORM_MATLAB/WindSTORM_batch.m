clc
clear
close all;
addpath('functions');

% WindSTORM_batch V1.0 Beta, by Hongqiang Ma @ PITT, sep 2019
% Note: The size of the image must be one of the following:
% 64x64; 128x128; 256x256; 512x512; 1024x1024.

%% Input parameters for the data set using the input dialog box
prompt = {'Enter data path name',...
    'Estimated average emitter intensity','Kernel width of the PSF'...
    'Count to photons ratio of the camera','Base line of the camera'};
title = 'Input';
dims = [1 50];
definput = {'.\data','10000','1.4','2','100'};
answer = inputdlg(prompt,title,dims,definput);
PathName = char(answer{1}); % the pathname of the dataset
Intensity = str2num(answer{2}); % estimated average emitter intensity of the dataset
Sigma = str2num(answer{3}); % the kernel width of the PSF of the system
Count2photon = str2num(answer{4}); % count to photons ratio of the camera
Baseline = str2num(answer{5}); % base line of the camera
%% Examples on the defined parameters on the testing dataset


%% Read image
minIntensity = Intensity/4;   % a global threshold set to eliminate very weak emitters

%% extract all tif files in the path
f_list = dir([PathName, '\*.tif']);

for fn=1:length(f_list)
    fn
Filename = f_list(fn).name;
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
clear result 
end




