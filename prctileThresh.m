function I = prctileThresh(h, pthr)
%prctileThresh = Calc intensity value from an image histogram given a percentile
% I = prctileThresh(h,pthr) Given a percentile, pthr, and a histogram, h, find the intensity, I, at the Pth percentile
%
%INPUTS -
% h, histogram vector
% pthr, numeric in range [0,1].
%
%OUTPUTS - 
%I, numeric in the range [0,1].
%
% [#Gonzalez:2009]: Digital Image Processing Using MATLAB, 2nd edition, by R.C. Gonzalez, R.E. Woods, and S.L. Eddins, Gatesmark Publishing, 2009. p. 567
%See also prctile, otsuthresh, graythresh.

if pthr < 0 || pthr >1
	error('pthr must be in the range [0,1].')
end

%Normalize the histogram area.
h = h/sum(h);

C = cumsum(h);

idx = find(C >= pthr, 1, 'first');
%Shift the indexing by 1 and normalize to the range [0,1].
I = (idx - 1)/(numel(h) - 1);
