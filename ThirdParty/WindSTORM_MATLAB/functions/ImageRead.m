function [imRAW,imW,imH] = ImageRead(Filename,Baseline,Count2photon)
% ------------------------------------------------------------------------------------
% Read image stack from a file and tansfer it from digital counts to physical photons.
%
% Input:    Filename         file name
%           Baseline         baseline of the camera
%           Count2photon     the transfer ratio from digital counts to physical photons
%
% Output:   imRAW            the raw image with unit of photons
%           imW              image width
%           imH              image height
% 
% By Hongqiang Ma @ PITT July 2018
% ------------------------------------------------------------------------------------

info = imfinfo(Filename);
imW = info.Width;
imH = info.Height;
imF = length(info);

imRAW = zeros(imH,imW,imF);

for f = 1:imF
    imRAW(:,:,f) = (imread(Filename,f)-Baseline)*Count2photon;
end
end