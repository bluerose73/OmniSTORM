% Benchmark dcimg reader performance

close all
clear
clear mex

filepath = 'data\SW480_153310_c1_006.dcimg';


% img1 = read_dcimg(filepath);

tic

img2 = dcimg_read_frame_range(filepath, 1, 1000);

toc

tic

img2 = dcimg_read_frame_range(filepath, 1, 1000);

toc