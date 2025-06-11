% Deconv-TemporalSTD super-resolution method
% Args:
%   img_stack (3d array): input image
%   sigma (scalar): standard deviation of gaussian psf
%   scale (scalar): width and hight will be scaled `scale` times
%   interp: "fourier" or "bicubic"

% Step 1: Interpolation
% Step 2: Deconvolve each frame
% Step 3: Temporal STD
% Step 4: Deconvolve the aggregated image.
%         Assume the resolution has been reduced by half.

function [final_sr_img, aggregated_img, sr_img_stack, deconv_img_stack] = deconv_temporalstd(img_stack, scale, sigma, interp)
    if nargin < 4
        interp = "fourier";
    end

    img_stack = single(img_stack);
    img_stack = img_stack - 300;
    img_stack(img_stack < 0) = 0;
    [height, width, n_frames] = size(img_stack);
    sr_height = height * scale;
    sr_width = width * scale;
    sr_img_stack = zeros([sr_height, sr_width, n_frames], "single");
    deconv_img_stack = zeros([height, width, n_frames], "single");
    
    for f = 1:n_frames
        img = img_stack(:,:,f);
        img = my_deconvolution(img, sigma);
        deconv_img_stack(:, :, f) = img;

        sr_img = my_interpolate(img, scale, interp);
        sr_img_stack(:, :, f) = sr_img;
    end

    img_to_save = sr_img_stack / max(sr_img_stack, [], "all");
    % imadjust(img_to_save);
    img_to_save = uint16(img_to_save * 65535);
    save_tiff(img_to_save, 'C:\Users\bluerose73\desktop\img_stack.tif');

    aggregated_img.std = std(sr_img_stack, [], 3);
    aggregated_img.mean = mean(sr_img_stack, 3);
    
    post_sigma = sigma / 2 * scale;
    sr_psf = fspecial('gaussian', ceil(post_sigma * 10 + 1), post_sigma);
    
    final_sr_img.std = deconvlucy(aggregated_img.std, sr_psf, 20);
    final_sr_img.mean = deconvlucy(aggregated_img.mean, sr_psf, 20);
end

               

