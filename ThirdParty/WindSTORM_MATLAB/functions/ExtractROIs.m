function [ROI,ROIsub,IDs,x0,y0] = ExtractROIs(imDeconv,impeak,imBS,Sigma)
% ------------------------------------------------------------------------------------
% Extract the ROI of candidate emitters and calculate their initial
% position and subtract surrounding emitters
%
% Input:    imDeconv        the deconvolved image 
%           impeak          the emitter peak image 
%           imBS            the background subtracted image
%           Sigma           the Gaussain kernel width of the PSF 
%
% Output:   ROI             the extracted central emitters
%           ROIsub          the surrounding emitters to be deducted
%           IDs             the coordinates of the extracted emitter
%           x0              the initial x position of the extracted emitter
%           y0              the initial y position of the extracted emitter
%
% By Hongqiang Ma @ PITT July 2018
% ------------------------------------------------------------------------------------

[imW,imH,imF] = size(imBS);
imT = zeros(imW,imH,imF);
imX = zeros(imW,imH,imF);
imY = zeros(imW,imH,imF);
IDs1 = zeros(10000000,5);
AA = 0.2528*Sigma^2-1.2313*Sigma+1.7575;
SS = 0.1337*Sigma^2+0.4162*Sigma+0.8070;
ROIr = 7;
num = 0;
for f=1:imF
    imD = imDeconv(:,:,f);
    imP = impeak(:,:,f);
    im = imBS(:,:,f);

    imPsum = filter2(ones(3,3),imP);
    imD(imPsum>1) = imD(imPsum>1)*0.5; % seperate close emitters
    imDsum = filter2(ones(3,3),imD); % relative total emitter intensity 
    imSum = filter2(ones(3,3),im); % relative central emitter intensity
    
    % initial estimation of emitter intensity and position
    [row,col] = find(imP>0);
    T = col;
    A = col;
    xc = col;
    yc = col;
    for m = 1:length(row)
        xp = imD(row(m)-1,col(m)+1) + imD(row(m),col(m)+1) + imD(row(m)+1,col(m)+1);
        xo = imD(row(m)-1,col(m)) + imD(row(m),col(m)) + imD(row(m)+1,col(m));
        xn = imD(row(m)-1,col(m)-1) + imD(row(m),col(m)-1) + imD(row(m)+1,col(m)-1);

        yp = imD(row(m)+1,col(m)-1) + imD(row(m)+1,col(m)) + imD(row(m)+1,col(m)+1);
        yo = imD(row(m),col(m)-1) + imD(row(m),col(m)) + imD(row(m),col(m)+1);
        yn = imD(row(m)-1,col(m)-1) + imD(row(m)-1,col(m)) + imD(row(m)-1,col(m)+1);

        T(m) = imDsum(row(m),col(m));
        A(m) = imSum(row(m),col(m));
        xc(m) = (xp^2-xn^2)./(xp^2+xo^2+xn^2);
        yc(m) = (yp^2-yn^2)./(yp^2+yo^2+yn^2);
    end
    
    % estimate emitter intensity
    imOL = zeros(imW,imH);
    Tol = T;
    for m = 1:length(row)
        pROI = imP(row(m)-ROIr:row(m)+ROIr,col(m)-ROIr:col(m)+ROIr);
        pROI(ROIr+1,ROIr+1) = 0;
        [rowp,colp] = find(pROI>0);
        for mm = 1:length(rowp)
            Dist = (rowp(mm)-(ROIr+1+yc(m)))^2 + (colp(mm)-(ROIr+1+xc(m)))^2;
            imOL(row(m)+rowp(mm)-(ROIr+1),col(m)+colp(mm)-(ROIr+1)) = T(m)*AA*exp(-Dist/(2*SS*SS))+imOL(row(m)+rowp(mm)-(ROIr+1),col(m)+colp(mm)-(ROIr+1));
        end
    end
    for m = 1:length(row)
        Tol(m) = imOL(row(m),col(m));
        Dist = yc(m)^2 + xc(m)^2;
        Ar = (AA*exp(-Dist/(2*SS*SS)));
        T(m) = A(m)*T(m)*Ar/(T(m)*Ar+Tol(m))/Ar;
    end
    for m = 1:length(row)
        imT(row(m),col(m),f) = T(m);
        imX(row(m),col(m),f) = xc(m);
        imY(row(m),col(m),f) = yc(m);
    end
    
    id = num+1:num+length(row);
    IDs1(id,:) = [row,col,xc,yc f*ones(length(row),1)];
    num = num + length(row);
end

IDs = IDs1(1:num,:);
ROI = zeros(7,7,num);
ROIsub = zeros(7,7,num);
[X,Y] = meshgrid(1:(2*ROIr+1));
x0 = zeros(4,4,num);
y0 = zeros(4,4,num);

% surrounding emitter subtraction
for m=1:num
    ROI1 = imBS(IDs(m,1)-ROIr:IDs(m,1)+ROIr,IDs(m,2)-ROIr:IDs(m,2)+ROIr,IDs(m,5));
    tROI = imT(IDs(m,1)-ROIr:IDs(m,1)+ROIr,IDs(m,2)-ROIr:IDs(m,2)+ROIr,IDs(m,5));
    xROI = imX(IDs(m,1)-ROIr:IDs(m,1)+ROIr,IDs(m,2)-ROIr:IDs(m,2)+ROIr,IDs(m,5));
    yROI = imY(IDs(m,1)-ROIr:IDs(m,1)+ROIr,IDs(m,2)-ROIr:IDs(m,2)+ROIr,IDs(m,5));
    tROI(ROIr+1,ROIr+1) = 0;
    [rowp,colp] = find(tROI>0);
    ROI2 = zeros(2*ROIr+1,2*ROIr+1);
    for mm = 1:length(rowp)
        T = tROI(rowp(mm),colp(mm));
        xc = xROI(rowp(mm),colp(mm));
        yc = yROI(rowp(mm),colp(mm));
        ROI2 = ROI2 + T/(2*pi*Sigma*Sigma)*exp(-((Y-rowp(mm)-yc).^2+(X-colp(mm)-xc).^2)/(2*Sigma*Sigma));
    end
    ROI3 = ROI1-ROI2;
    ROI3(ROI3<0)=0;
    xc = xROI(ROIr+1,ROIr+1);
    yc = yROI(ROIr+1,ROIr+1);
    XX = round(xc);
    YY = round(yc);
    Xb = XX - xc;
    Yb = YY - yc;
    IDs(m,1) = IDs(m,1) + YY;
    IDs(m,2) = IDs(m,2) + XX;
    IDs(m,3) = Xb;
    IDs(m,4) = Yb;
    % ROI extraction
    ROI(:,:,m) = ROI3(ROIr+1+YY-3:ROIr+1+YY+3,ROIr+1+XX-3:ROIr+1+XX+3);
    ROIsub(:,:,m) = ROI2(ROIr+1+YY-3:ROIr+1+YY+3,ROIr+1+XX-3:ROIr+1+XX+3);
    x0(:,:,m) = IDs(m,3)*ones(4,4);
    y0(:,:,m) = IDs(m,4)*ones(4,4);
end
end


