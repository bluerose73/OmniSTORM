%FRC   Compute FRC curve from 2 images
%
% First a Tukey window is applied to the 2 images, and subsequently the FRC
% curve is computed from the Fourier Transforms of the two images. The
% maximum frequency for which the FRC is computed is sqrt(1/2).
%
% SYNOPSIS:
%   frc_out = frc(in1,in2)
%
% NOTES:
%   Non-square images are zero padded to make them square.

% (C) Copyright 2012               Quantitative Imaging Group
%     All rights reserved          Faculty of Applied Physics
%                                  Delft University of Technology
%                                  Lorentzweg 1
%                                  2628 CJ Delft
%                                  The Netherlands
% Robert Nieuwenhuizen, Oct 2012

function frc_out = frcbis(in1, in2)

if nargin ~=2
   error('Need 2 input arguments.');
end
if ~isa(in1,'dip_image')
    in1 = mat2im(in1);
end
if ~isa(in2,'dip_image')
    in2 = mat2im(in2);
end


sz = imsize(in1);
if any(imsize(in2) ~= sz)
    error('Image 1 and image 2 have different image sizes.');
end

if (~sum(in1)) || (~sum(in2))
    frc_out = radialsum(0*in1);
    return;
end

% Compute mask in x-direction
nfac = 8;                                                   % Image width / Width of edge region
x_im = xx(sz(1),sz(2))/sz(1);
mask = 0.5-0.5*cos(pi*nfac*x_im);          
mask(abs(x_im)<((nfac-2)/(nfac*2))) = 1;

% Check that input images are square and mask
if sz(1) == sz(2)
    mask = mask*rot90(mask);
    
    % Mask input images
    in1 = mask*in1;
    in2 = mask*in2;
else
    warning('frc:nonsquare','Images are not square.');
   
    % Compute mask in y-direction
    y_im = yy(sz(1),sz(2))/sz(2);
    mask_y = 0.5-0.5*cos(pi*nfac*y_im);          
    mask_y(abs(y_im)<((nfac-2)/(nfac*2))) = 1;
    mask = mask*mask_y;
    clear mask_y
    
    % Mask input images
    in1 = mask*in1;
    in2 = mask*in2;
    
    % Make images square through zero padding
    in1 = extend(in1,[max(sz) max(sz)]);
    in2 = extend(in2,[max(sz) max(sz)]);
end

% Fourier transform input images
in1 = ft(in1);
in2 = ft(in2);

% Compute fourier ring correlation curve
frc_num = real(radialsum(in1.*conj(in2)));                                  % Numerator
in1 = abs(in1).^2;
in2 = abs(in2).^2;
frc_denom = sqrt(abs(radialsum(in1).*radialsum(in2)));                      % Denominator
frc_out = double(frc_num)./double(frc_denom);                               % FRC
frc_out(isnan(frc_out)) = 0;                                                % Remove NaNs