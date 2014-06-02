function [level, EM] = otsuthresh(h)
%otsuthresh Otsu's threshold given an image histogram
%[level,EM] = otsuthresh(h) computes a grayscale image intensity threshold in the range [0,1] using Otsu's method for a given image histogram, h
%
% Inputs:
% h, a column vector
%
% OUTPUT:
% level - threshold
% Reference:
% N. Otsu, "A Threshold Selection Method from Gray-Level Histograms," IEEE Transactions on Systems, Man, and Cybernetics, vol. 9, no. 1, pp. 62-66, 1979.
% [#Gonzalez:2009]: Digital Image Processing Using MATLAB, 2nd edition, by R.C. Gonzalez, R.E. Woods, and S.L. Eddins, Gatesmark Publishing, 2009.

%Normalize the histogram
h = h/sum(h);
h = h(:); 

i = (1:numel(h))';  %All possible intensities for the dynamic range in the histogram (256 for 8bit)
p = cumsum(h);
m=cumsum(i.*h);
mu = m(end);
sigSq = ((mu*p - m).^2)./(p.*(1 - p) + eps);

%Find max of sig squared. Optimum threshold will be at the max. If more than one contiguous max values, average to obtain final threshold.
maxval = max(sigSq);
level = mean(find(sigSq == maxval));

%Normalize the threshold to range [0,1]. 1 is subtracted since image intensities start at 0 instead of at the matlab index of 1.
level = (level - 1)/(numel(h) - 1);

%Calculate the effectiveness metric
EM = maxval / (sum(((i - mu).^2) .* h) + eps);
