function [T, SM] = otsuthresh(h)
%otsuthresh Otsu's optimum threshold given a histogram
%[T,SM] = otsuthresh(h) computes an optimum threshold, T, in the range [0,1] using Otsu's method for a given histogram, h, which should be a column vector

%Normalize the histogram
h = h/sum(h);
h = h(:); %h must be a column vector

%Representation of all possible intensities for the given dynamic range in the histogram (256 for 8bit)
i = (1:numel(h))';

%Values of P1 for all values of k
P1 = cumsum(h);

%Values of the mean for all values of k
m=cumsum(i.*h);

%Image mean
mG = m(end);

%Between class variance
sigSq = ((mG*P1 - m).^2)./(P1.*(1 - P1) + eps);

%Find max of sig squared. The index where the max occurs is the optimum threshold. There may be several contiguous max values. Average them to obtain the final threshold.
maxSigSq = max(sigSq);
T = mean(find(sigSq == maxSigSq));

%Normalize the threshold to range [0,1]. 1 is subtracted for matlab indexing starting at 1 since image intensities start at 0.
T = (T - 1)/(numel(h) - 1);

%Calculate the Separability measure
SM = maxSigSq / (sum(((i - mG).^2) .* h) + eps);
