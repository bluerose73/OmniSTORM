% Demo script to showcase the use of 1FRC
%
% needs DIPimage, https://diplib.org/
% needs pcfo from
%
% Bernd Rieger, TU Delft, 2024

% expect the actual computation to be quick even on a laptop (apart from the readind)
% less than 1 second for 1024x1024 sized image

clear
close all

%% reading of image
% this example is one image from the 20 repeats of ID 5 from Fig 3c
% the below example does not take into account the effect of readnoise
% which is present for this data of an old OrcaER CCD.
% %Newer sCMOS/EMCCD images can be used this way.
org_in = readim('input_WF.ics');
org_in = org_in(0:1023,0:1023); % ensure that the input is square. This is important for the FRC evaluation. Otherwise the pixels in Fourier space become anisotropic even though the input is isotropic.
sz = imsize(org_in);
pixelsize = 107.5; %backprojected pixel size in nanometer

%% correct for gain and offset if not already done
% a gain and offset corrected input image is needed for 1FRC to split the
% data true to Poissonian statistics

dark = readim('avg_darkimg.ics');
dark = dark(0:1023,0:1023);
in = org_in - dark;
[gain_pcfo] = pcfo(in,0.9,0,0,0);
%or use if no dark image is avialable
%[gain_pcfo,offset_pcfo] = pcfo(in,0.9,0,[3 3],0);
%in = org_in - offset_pcfo;

in = in /gain_pcfo;

%% compute 1FRC
in_int32 = int32(round(im2mat(in))); 
% convert to a native matlab array, not a dip_image type for speed.
% The input to 1FRC must be of type integer to allow for the bionomial splitting.
% the C code expect "int32" datatype. If your data is e.g. int8 aor int16 you still need to convert it or change the C code.

[tmp1,tmp2] = cBinomialSplit(in_int32); % compute the split.
FRCcurve = frcbis(tmp1, tmp2); % compute 1FRC curve
[FRCres,~,~] = frctoresolution(FRCcurve, sz(1)); % compute FRC intersection
fprintf('1FRC resolution: %5.0f [nm] (from one run)\n', FRCres*pixelsize)

%% accounting for the readnoise problem of 8 rms e- of this old OcraER
sigma_rn = 8;
tmp = in_int32+2*sigma_rn^2; % add rms readout noise for compensating impact of Gaussian readout noise
[tmp1,tmp2] = cBinomialSplit(tmp); % make the split
tmp1 = tmp1-sigma_rn^2; % subtract rms readout noise for compensating impact of Gaussian readout noise
tmp2 = tmp2-sigma_rn^2; % subtract rms readout noise for compensating impact of Gaussian readout noise
FRCcurve_noise = frcbis(tmp1,tmp2);
[FRCres,~,~] = frctoresolution(FRCcurve_noise, sz(1)); % compute FRC intersection
fprintf('1FRC resolution: %5.0f [nm] (from one run with accounting for readnoise)\n', FRCres*pixelsize)

Nfrc = numel(FRCcurve);
qr = ((0:(Nfrc-1))/Nfrc)/sqrt(2)/pixelsize;
figure
hold on
FRC_smooth = movmean(FRCcurve,7); % moving average to smooth curve for display purposes
FRC_smoothN = movmean(FRCcurve_noise,7); % moving average to smooth curve for display purposes
plot(1e3*qr,FRC_smooth,'r-')
plot(1e3*qr,FRC_smoothN,'k-')
legend('1FRC','1FRC readnoise corrected')
xlabel('Spatial frequency [1/mu]')
ylabel('1 FRC')
hold off

%% 1FRC resolution has a statistical spread
% you will see that running the code repeatetly, will give slightly
% different resolution values, due to the statistical nature of the
% splitting. Running it a few times and taking the average could be what
% you want.

N=10;
res = zeros(N,1);
for ii=1:N
    [tmp1,tmp2] = cBinomialSplit(in_int32); % compute the split.
    FRCcurve = frcbis(tmp1, tmp2); % compute 1FRC curve
    [FRCres,~,~] = frctoresolution(FRCcurve, sz(1)); % compute FRC intersection
    res(ii) = FRCres*pixelsize;
end
fprintf('%d repeats -> 1 FRC resolution: %5.1f +-%5.2f [nm]\n',N, mean(res),std(res))

