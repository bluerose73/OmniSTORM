% Save a double / uint16 image to uint16 tiff

function save_tiff(img, filename)
    if class(img) == "double"
        img = uint16(img / max(img, [], "all") * 65535);
    end
    if class(img) == "single"
        img = uint16(img / max(img, [], "all") * 65535);
    end
    if class(img) ~= "uint16"
        warning('Unsupported img format "%s"', class(img));
    end
    num_frames = size(img, 3);
    imwrite(img(:, :, 1), filename);
    for i = 2:num_frames
        imwrite(img(:, :, i), filename, "WriteMode","append");
    end
end