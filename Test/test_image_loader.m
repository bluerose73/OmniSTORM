imageloader = OmniImageLoader();

dcimg_path = 'data\SW480_153310_c1_006.dcimg';

tiff_folder_path = 'data\1_hd';

tiff_single_frame_file_path = 'data\1_hd\00001.tif';

imageloader.openImage(tiff_single_frame_file_path);

imageloader.height
imageloader.width
imageloader.totalFrames
imageloader.imagePathList
imageloader.numFramesList

img = imageloader.readFrameRange(1, 1);
class(img)
size(img)
img(1:3, 1:3, 1)
imagesc(img(:, :, 1))

% 
% 
% imageloader.openImage(dcimg_path);
% 
% imageloader.height
% imageloader.width
% imageloader.totalFrames
% imageloader.imagePathList
% imageloader.numFramesList
% 
% img = imageloader.readFrameRange(1, 10);
% class(img)
% size(img)
% img(1:3, 1:3, 1)
% imagesc(img(:, :, 1))
% 
% imageloader.openImageFolder(tiff_folder_path);
% 
% imageloader.height
% imageloader.width
% imageloader.totalFrames
% imageloader.imagePathList(1:3)
% imageloader.numFramesList(1:3)
% img = imageloader.readFrameRange(1, 10);
% class(img)
% size(img)
% img(1:3, 1:3, 1)
% imagesc(img(:, :, 1))
