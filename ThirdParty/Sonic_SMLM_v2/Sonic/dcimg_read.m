function [imdata,totalframes,imW] = dcimg_read(filename)

[totalframes, imH, imW] = dcimg_get_size(filename);
imdata = zeros(imH,imW,totalframes);
for f = 1:totalframes
    % Read each frame into the appropriate frame in memory.
    framedata = dcimg_read_frame(filename, f);
    framedatatrans = transpose (framedata);
    imdata(:,:,f)  = framedatatrans;
end

end