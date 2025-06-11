% PCFO = Calculates the photon conversion factor as well as the ADU offset
%    from one image only
%
% SYNOPSIS:
%   [gain, offset] = pcfo(image_stack, k_thres, RNStd, AvoidCross, doPlot, Tiles)
%
%   k_thres: spatial frequencies k>k_thres are used for noise computation
%        in the discrete Fourier domain.
%        Possible values [0, sqrt(2)] as the 'corners' of a rectangular image have freq > 1
%        k_thres is specified as a fraction of the maximal sampling frequency in the Fourier Domain. 
%   RNStd : camera readout noise std in ADUs. I.e. the StdDev of a dark image.
%   AvoidCross: Binary flag stating whether the X- and Y-only frequencies should be avoided.
%   doPlot: Plot the noise fit for offset determination
%
% DEFAULTS:
%   k_thres = 0.9
%   RNStd = 0;
%   AvoidCross = 1
%   doPlot = 0
%
% EXAMPLE:
%   a = readim;
%   psf = gaussf(deltaim,2);%not really a point spread function of a microscope
%   ap = convolve(a,psf);
%   apn = noise(ap,'poisson',1,0)*3.8 + 50;
%   [g,o] = pcfo(apn)
%
% LITERATURE:
%   R. Heintzmann, P.K. Relich, R.P.J. Nieuwenhuizen, K.A. Lidke, and B. Rieger, "Calibrating photon counts from a single image," arXiv:1611.05654 (2018)
%
% Requires matlab toolbox DIPimage to run (free academic download from www.diplib.org)

% Original Authors
% (C) Copyright 2004-2016               
%     All rights reserved               Faculty of Applied Sciences
%                                       Delft University of Technology
%                                       Delft, The Netherlands
%                                       &
%                                       Institute of Physical Chemistry, 
%                                       Friedrich Schiller University,
%                                       Jena, Germany
% Bernd Rieger & Rainer Heintzmann

% Modified by Shengjie Ma (2025)
% The original pcfo function splits one image into patches, and use the
% patches to estimate gain / offset.
% The updated temporal pcfo uses multiple frames of image taken by the same
% camera to replace patches

function [gain, offset] = TemporalPCFO(image_stack, kthres, RNStd, AvoidCross, doPlot)
if nargin <2; kthres = 0.9; end
if nargin <3; RNStd = 0;end
if nargin <4; AvoidCross = 1;end
if nargin <5; doPlot =0;end

% test if DIPimage is installed
o = which('readim');
if isempty(o)
    error('DIPimage not installed or not on the path.');
end

%% this part computes the noise variance and sum intensites per tile
n = 1;
numFrames = size(image_stack, 3);
if numFrames < 2
    error('image_stack has less than 2 frames.');
end

for f = 1:numFrames
    myTile = image_stack(:, :, f);
    myTile = mat2im(myTile);
    
    if (prod(size(myTile)) > 0) %just in case, should not happen
        NumPixelsInBin(n) = prod(size(myTile));
        [TotalVar(n), TotalInt(n)] = noisevariance(myTile, kthres, AvoidCross); % this does not need any information on offset or readout noise
        n=n+1;
    end
end
%% linear regression on the mean-variance plot to find the variance offset
maxFitBin = n-1;%range for the linear regression

[Voffset, slope, vv] = RWLSPoisson(TotalInt(1:maxFitBin), TotalVar(1:maxFitBin), NumPixelsInBin(1:maxFitBin));  % iteratively updates the variance of the variance estimate
offset = -Voffset/slope;  % Use result from the fit, mapped into the offset along x where variance is zero

%% compute the noise variance on the full image, correct for the variance offset to find the gain
[AllTotalVar, AllTotalInt] = noisevariance(in, kthres, AvoidCross);
gain = (AllTotalVar-Voffset)/AllTotalInt; % Estimate this again from the whole image to reduce the tile effect
offset = RNStd^2/gain + offset;  % account for the readout noise effect


%%
if doPlot
    offset2 = TotalInt(1) - TotalVar(1)/slope;   % The point on the x-axis where the variance is zero
    figure
    plot(TotalInt,TotalVar,'b*');hold on;
    myYFit=(TotalInt-offset)*slope;
    plot(TotalInt,myYFit,'r')
    plot(TotalInt,myYFit-sqrt(vv),'r:')
    plot(TotalInt,myYFit+sqrt(vv),'r:')
    g=gca;
    set(g,'FontSize',12)
    xlabel('Mean Intensity [ADU]');
    ylabel('Noise Variance [ADU]');
    title('Mean Variance Plot');
    s=sprintf('offset: %0.4g ADU\nslope: %0.2g',offset2,slope);
    ax = axis;
    axis([0 ax(2) 0 ax(4)])
    text(ax(2)/10,ax(4)*0.8,s,'FontSize',11)
    hold off
    drawnow;
    fprintf('offset: %0.4g ADU, slope: %0.2g\n',offset2,slope);  % show what the fit results into
end
return;


