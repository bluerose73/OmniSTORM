function sr_img = my_deconvolution(img, sigma)

    psf = fspecial('gaussian', 11, sigma);
    psf = single(psf);

    global g_conv_method

    if g_conv_method == "deconvlucy"
        psf = fspecial('gaussian', 11, sigma);
        psf = single(psf);
        sr_img = deconvlucy(img, psf, 10);
    elseif g_conv_method == "bigss"
        psf = fspecial('gaussian', size(img, 1), sigma);
        psf = single(psf);
        sr_img = RL_bigss(img, psf, 10, true);
    end

    

end
