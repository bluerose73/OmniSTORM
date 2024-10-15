function sr_img = my_deconvolution(img, sigma)
    psf = fspecial('gaussian', ceil(sigma * 10 + 1), sigma);
    sr_img = deconvlucy(img, psf, 20);
end
