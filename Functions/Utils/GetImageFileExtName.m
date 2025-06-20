function ext_name_list = GetImageFileExtName(config)
%GETIMAGEFILEEXTNAME Get a string list of image file extension name from
%config

ext_name_list = string([]);

if config.filetype.tiff
    ext_name_list(end + 1) = ".tif";
    ext_name_list(end + 1) = ".tiff";
end

if config.filetype.dcimg
    ext_name_list(end + 1) = ".dcimg";
end

end

