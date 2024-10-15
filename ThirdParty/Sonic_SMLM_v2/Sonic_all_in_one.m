clc
clear
close all
addpath(genpath('./AIM'))
addpath(genpath('./Sonic'))

datapath = 'I:\06-27-2024_STORM';   % user need to set up the data path
resultpath = [datapath '_result'];
mkdir(resultpath)
threshold = 10;

folderlist = dir(datapath);

for foN = 1:length(folderlist)-2
    foldername = [datapath '\' folderlist(foN+2).name]
    [X,Y,F,imW] = Sonic_main(foldername,threshold);
    
    Localizations(:,1) = F;
    Localizations(:,2) = X;
    Localizations(:,3) = Y;

    % AIM drift correction
    trackInterval = 200; 
    [LocAIM, AIM_Drift] = AIM(Localizations, trackInterval);

    foldername = [resultpath '\' folderlist(foN+2).name]
    Sonic_save(X,Y,F,AIM_Drift,foldername,imW,5);

    clear Localizations LocAIM AIM_Drift X Y F
end


