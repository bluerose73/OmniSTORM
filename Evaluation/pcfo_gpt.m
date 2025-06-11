function [gain, offset] = pcfo_gpt(im, blockSize)
    % estimateGainOffset Estimate camera gain and offset from a single image.
    %
    %   [gain, offset] = estimateGainOffset(im, blockSize) estimates the gain 
    %   (ADU/photon) and offset of a detector from the single input image im.
    %
    %   The method divides the image into non-overlapping blocks of size 
    %   blockSize-by-blockSize, computes the mean and variance of each block,
    %   and then fits the relationship
    %
    %       Var = gain * (Mean - offset)
    %
    %   which can be rewritten as:
    %
    %       Var = gain * Mean + intercept,    where intercept = -gain * offset.
    %
    %   The gain is given by the slope of the linear fit, and the offset is
    %   computed as -intercept/gain.
    %
    %   If blockSize is not provided, a default value of 64 is used.
    %
    %   Example:
    %       im = imread('myImage.tif');
    %       [gain, offset] = estimateGainOffset(im);
    %
    %   Author: Your Name
    %   Date:   Today's Date
    
        if nargin < 2
            blockSize = 64; % default block size if not provided
        end
    
        % Convert image to double for numerical precision.
        im = double(im);
        [nr, nc] = size(im);
        
        % Determine the number of complete blocks in each dimension.
        nBlockRows = floor(nr / blockSize);
        nBlockCols = floor(nc / blockSize);
        
        % Preallocate arrays to store the block means and variances.
        means = zeros(nBlockRows * nBlockCols, 1);
        vars  = zeros(nBlockRows * nBlockCols, 1);
        
        idx = 1;
        for i = 1:nBlockRows
            for j = 1:nBlockCols
                % Extract the current block.
                block = im((i-1)*blockSize+1 : i*blockSize, ...
                           (j-1)*blockSize+1 : j*blockSize);
                % Compute the mean and variance.
                means(idx) = mean(block(:));
                % Use the population variance (normalizing by N) so that shot noise
                % (which is Poisson distributed) is properly estimated.
                vars(idx) = var(block(:), 1);
                idx = idx + 1;
            end
        end
    
        % Now we have a set of (mean, variance) pairs. We fit a straight line:
        % variance = gain * mean + intercept.
        p = polyfit(means, vars, 1);
        gain = p(1);
        intercept = p(2);
        
        % From the definition intercept = -gain * offset.
        offset = -intercept / gain;
    end
    