% Single-image FRC resolution estimation and gain / offset estimation

function [resolution, gain_pcfo, offset_pcfo] = frc_pcfo(img)

% FRC requires the image to be square
[height, width] = size(img);
if height ~= width
    crop_size = min([height, width]);
    img = img(1:crop_size, 1:crop_size);
end

org_in = mat2im(img);
sz = imsize(org_in);

[gain_pcfo,offset_pcfo] = pcfo(org_in,0.9,0,[3 3],0);
in = org_in - offset_pcfo;

in = in /gain_pcfo;

in_int32 = int32(round(im2mat(in))); 
% convert to a native matlab array, not a dip_image type for speed.
% The input to 1FRC must be of type integer to allow for the bionomial splitting.
% the C code expect "int32" datatype. If your data is e.g. int8 aor int16 you still need to convert it or change the C code.

[tmp1,tmp2] = cBinomialSplit(in_int32); % compute the split.
FRCcurve = frcbis(tmp1, tmp2); % compute 1FRC curve
[resolution,~,~] = frctoresolution(FRCcurve, sz(1)); % compute FRC intersection

end