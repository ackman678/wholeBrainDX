function I = percentile2i(h, P)
%percentile2i Computes an inteneisty value given a percentile
% I= percentile2i(h,p) Given a percentile, P, and a histogram, H, this function coputes an intensity, I, representing the Pth percentile and returnes the value in I. P must be in the range [0,1] and I is returned a s avalue in the range [0,1].
%
%Example:
%h is a uiform histrogram of an 8bit image. 
%I=percentile2i(h,0.5)
%gives output I=0.5. To convert to the integer 8bit range [0,255], let I=floor(255*I).

%Check value of P.
if P < 0 || P >1
	error('The precentile must be im the range [0,1].')
end

%Normalized the histogram to unit area. If it is already normalized the following computation has no effect.
h = h/sum(h);

%Cumulative distribution
C = cumsum(h);

%Calculations
idx = find(C >= P, 1, 'first');
%Subtract 1 from idx because indexing starts at 1, but intensiteis start at 0. Also, normalize to the range [0,1].
I = (idx - 1)/(numel(h) - 1);
