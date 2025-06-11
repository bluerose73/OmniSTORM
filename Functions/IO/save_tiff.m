% Save a double / uint16 image to uint16 tiff
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
% function save_tiff(img, filename)
%     % Check for out-of-bound values before casting
%     min_val = min(img, [], "all");
%     max_val = max(img, [], "all");
%     if min_val < 0 || max_val > 65535
%         warning('Image data contains values outside the uint16 range [0, 65535]. Clipping will occur.');
%     end
% 
%     img = uint16(img);
% 
%     % Save the image stack
%     num_frames = size(img, 3);
%     imwrite(img(:, :, 1), filename);
%     for i = 2:num_frames
%         imwrite(img(:, :, i), filename, "WriteMode", "append");
%     end
% end
