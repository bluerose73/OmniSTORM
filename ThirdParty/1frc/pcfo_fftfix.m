function [gain_est,offset_est] = pcfo_fftfix(image_in,k_thresh,rnstd,tiles,makeplot)
% This function uses the noise only high-spatial frequency content of an
% image to estimate gain and offset of the image, an essential camera
% calibration step. It follows the Rieger-Heintzman method.
%
% input parameters:
% image_in = Nx x Ny x Nframes stack of images, each Nx x Ny slice is assumed
% to have the same gain and offset
% nyquistratio = ratio Nyquist rate/ sampling rate, = 1 for Nyquist
% sampling, <1 for oversampling
% rnstd = standard deviation of Gaussian readout noise, in photo-electrons
% sigmafac = std of Gaussian filtering for robustness promoting smoothing
% filter, not executed in case sigmafac <1 pixel
% makeplot = flag for making diagnostic plots
%
% output parameters:
% gain_est = Nreps x 1 vector of estimated gain
% offset_est = Nreps x 1 vector of estimated offset
% NB: image_in can be converted to detected photons by 
% image_out = (image_in-offset)/gain
%
% copyright Sjoerd Stallinga, TU Delft, 2022

[Nx,Ny,Nframes] = size(image_in);
tilesx = tiles(1);
tilesy = tiles(2);
filfac = 1-pi*k_thresh^2/4; % area in Fourier space where there is no image signal

% loop over Nreps images in stack
gain_est = ones(Nframes,1);
offset_est = zeros(Nframes,1);

for jrep = 1:Nframes
  if mod(jrep,100)==0
    fprintf('jrep=%i\n',jrep)
  end
  Btmporig = image_in(:,:,jrep);
  
  % compute mean signal and noise variance from high spatial frequency content
  xx = 1:Nx;
  xx = (xx-floor(Nx/2)-1)/(Nx/2);
  yy = 1:Ny;
  yy = (yy-floor(Ny/2)-1)/(Ny/2);
  [Y,X] = meshgrid(yy,xx);
  r = sqrt(X.^2+Y.^2);
  Mfilterkernel = double(r>k_thresh)/sqrt(filfac*Nx*Ny); % this is the proper normalization
  ftBtmp = fftshift(fft2(Btmporig));
  ftBtmp_hp = Mfilterkernel.*ftBtmp;
  noisevar_tot = mean(abs(ftBtmp_hp(:)).^2);
  imsig_tot = mean(Btmporig(:));
      
  % loop over tiles, compute the mean signal and noise variance per tile
  imsig = zeros(tilesx,tilesy);
  noisevar = zeros(tilesx,tilesy);
  for jtx = 1:tilesx
    for jty = 1:tilesy
      jtxmin = floor((jtx-1)*Nx/tilesx)+1;
      jtxmax = floor(jtx*Nx/tilesx);
      jtxmax = min(jtxmax,Nx);
      jtymin = floor((jty-1)*Ny/tilesy)+1;
      jtymax = floor(jty*Ny/tilesy);
      jtymax = min(jtymax,Ny);
      Btile = Btmporig(jtxmin:jtxmax,jtymin:jtymax);
  
      % double and mirror to suppress Fourier cross
      Bint = [Btile fliplr(Btile)];
      Btmp = [Bint; flipud(Bint)];
    
      % compute mean signal and noise variance from high spatial frequency content
      [Nxtile,Nytile] = size(Btmp);
      xx = 1:Nxtile;
      xx = (xx-floor(Nxtile/2)-1)/(Nxtile/2);
      yy = 1:Nytile;
      yy = (yy-floor(Nytile/2)-1)/(Nytile/2);
      [Y,X] = meshgrid(yy,xx);
      r = sqrt(X.^2+Y.^2);
      Mfilterkernel = double(r>k_thresh)/sqrt(filfac*Nxtile*Nytile); % this is the proper normalization
      ftBtmp = fftshift(fft2(Btmp));
      ftBtmp_hp = Mfilterkernel.*ftBtmp;
      noisevar(jtx,jty) = mean(abs(ftBtmp_hp(:)).^2);
      imsig(jtx,jty) = mean(Btmp(:));
    end
  end
  
  % compute gain and offset by linear regression
  noisevar = noisevar(:);
  imsig = imsig(:);
  parmatRR = mean(imsig(:).^2);
  parmatRS = mean(imsig(:));
  parmatSS = 1;
  parvecR = mean(imsig(:).*noisevar(:));
  parvecS = mean(noisevar(:));
  parmat = [parmatRR parmatRS; parmatRS parmatSS];
  parvec = [parvecR; parvecS];
  params_est = parmat\parvec;
  gain_est(jrep) = params_est(1);
%   gain_est(jrep) = (noisevar_tot-params_est(2))/imsig_tot; % compute gain from total image improves robustness
  offset_est(jrep) = -params_est(2)/gain_est(jrep)+gain_est(jrep)*rnstd^2;

  if makeplot
    jrepmax = 10;
    if jrep<jrepmax
      figure
      set(gcf,'units','pixels');
      set(gcf,'Position',[200 150 600 400]);
      plot(imsig,noisevar,'ro')
      hold on
      Npoints = 100;
      imsigline = min(imsig)+(max(imsig)-min(imsig))*((1:Npoints)-1)/Npoints;
      noisevarline = params_est(1)*imsigline+params_est(2);
      plot(imsigline,noisevarline,'k-')
      box on
      xlim([0 1.2*max(imsig)])
      ylim([0 1.2*max(noisevar)])
      xlabel('image signal')
      ylabel('noise variance')
    end
  end
end

% compute statistical parameters
gain_mean = mean(gain_est);
gain_std = std(gain_est);
offset_mean = mean(offset_est);
offset_std = std(offset_est);

% output mean and standard deviation
fprintf('gain = %5.3f +/- %5.3f\n',gain_mean,gain_std)
fprintf('offset = %5.3f +/- %5.3f\n',offset_mean,offset_std)

end
