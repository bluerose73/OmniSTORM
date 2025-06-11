function result = my_interpolate(img, scale, method)
    if scale == 1
        result = img;
        return
    end
    if method == "fourier"
        [height, width] = size(img);
        sr_height = height * scale;
        sr_width = width * scale;
        result = interpft(img, sr_height, 1);
        result = interpft(result, sr_width, 2);
    elseif method == "bicubic"
        result = imresize(img, scale, "bicubic");
    end
end