function imd = RL_bigss(im,psf,NUMIT, useGPU)

H = fftn(fftshift(psf));


if useGPU
    H = gpuArray(H);
    im = gpuArray(im);
    J2 = gpuArray(im);
    J3 = zeros(size(im), "single", "gpuArray");
    J4 = zeros(size(im,1)*size(im,2),2, "single", "gpuArray");
else
    J2 = im;
    J3 = zeros(size(im), "single");
    J4 = zeros(size(im,1)*size(im,2),2, "single");
end

lambda = 0;
for k = 1:NUMIT   
    if k > 2
        lambda = (J4(:,1).'*J4(:,2))/(J4(:,2).'*J4(:,2) +eps);
        lambda = max(min(lambda,1),0);
    end
    Y = max(J2 + lambda*(J2 - J3),0);
    CC = fftn(im./real(ifftn(H.*fftn(Y)))+eps);    
    J3 = J2;
    J2 = max(Y.*real(ifftn(conj(H).*CC)),0); 
    J4 = [J2(:)-Y(:) J4(:,1)];

end

if useGPU
    Y = gather(Y);
end

imd = Y;
end