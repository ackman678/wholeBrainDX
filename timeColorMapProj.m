function [maxProj, Iarr, MnMx] = timeColorMapProj(A, frStart, frEnd, filename, nStdev, MnMx)
%timeColorMapProj - Make time based colored projection maps from raw deltaF/F movies
%PURPOSE -- Make a time lapse color map projection from a dF/F input array
%USAGE -- 	[maxProj, Iarr] = timeColorMapProj(A,1638,1757, [], [-3 7]);
%			[maxProj, ~] = timeColorMapProj(Iarr,1638,1757);
%			[maxProj, ~] = timeColorMapProj(A,1638,1757, 'filename.tif');
% A - movie array, preferably converted to dF/F over time already. Should be of type double or one that is already converted to 8bit (output Iarr from this script)
% Example movie read and dF/F conversion:  
	% [~, series1, filename] = myOpenOMEtiff;
	% A = double(series1);
	% %Make deltaF/F movie
	% Amean = mean(A,3);
	% for i = 1:size(A,3)
	%         A(:,:,i) = (A(:,:,i) - Amean)./Amean;
	% end
	% [maxProj, Iarr] = timeColorMapProj(A,1638,1757, filename);
% frStart - start frame
% frEnd - end frame
% filename - string, the 'filename.tif' that the data come from and the string from which the output filename will be formatted
% nStdev - two element vector of [-nStd +nStd] for number of stdev to set to min/max for converting a double Df/F array. 
% MnMx - two element vector of [-min +max] for actual values of min and max for converting a double Df/F array (convertDfArray() function below). e.g. can pass the values returned from one movie for usage in scaling a following movie (like before or after drug treatment).
%
% See also Iarr2montage.m, Iarr2avi.m
%
%James B. Ackman 2014-07-09 03:27:32
%Inspired by Time-Lapse_Color_Coder.ijm plugin written by Kota Miura for ImageJ

sz=size(A);
if nargin < 6 || isempty(MnMx), MnMx = []; end
if nargin < 5 || isempty(nStdev), nStdev = []; end
if nargin < 3 || isempty(frEnd), frEnd=sz(3); end
if nargin < 2 || isempty(frStart), frStart=1; end
if sz(3) < 2
	error('Need an array to make time projection')
end

if islogical(A)
	Iarr = convertBWArray(A);
elseif ~isinteger(A) || ~isempty(nStdev)
	mnA = min(A,[],3);
	mn = min(mnA(:));
	if mn < 0  %test if the double array input is a dF/F array (centered on zero)
		if isempty(nStdev), nStdev = [-3 7]; end
		[Iarr,MnMx] = convertDfArray(A,nStdev(1), nStdev(2), MnMx);
	else
		Iarr = convertDblArray(A);
	end
else
	Iarr=A;
end

if nargin < 4 || isempty(filename), 
	filename = [];
else
	filename = [filename(1:length(filename)-4) '-fr' num2str(frStart) '-' num2str(frEnd) '-' datestr(now,'yyyymmdd-HHMMSS') '.png']; 
end

rgbColors = jet(256);
frColors = zeros(size(rgbColors));
totalframes = frEnd - frStart + 1;
intensityfactor=repmat(((0:255)/255)',1,3);
rgbA = zeros(sz(1), sz(2), 3, totalframes);

for i = 0:totalframes-1
	fr=i+frStart;
	colorscale = floor((256 / totalframes) * i);
	frColors = repmat(rgbColors(colorscale+1,:),256,1);
	frColors = frColors .* intensityfactor;
	RGB=ind2rgb(Iarr(:,:,fr),frColors);
	rgbA(:,:,:,fr) = RGB;
end

maxProj = max(rgbA, [], 4);
imshow(maxProj);

if ~isempty(filename)
	imwrite(maxProj,filename,'png')
end


function [Iarr,MnMx] = convertDfArray(A,nStdMin,nStdMax,MnMx)
%Convert a DF/F array. A DF/F array is centered around zero, so the no. of negative and positive std dev can give Amin and Amax for mat2gray conversion.
if nargin < 3 || isempty(nStdMax), nStdMax = 7; end
if nargin < 2 || isempty(nStdMin), nStdMin = -3; end
if nargin < 4 || isempty(MnMx),
	stdDev = std(A(:)); 
	newMin=nStdMin*stdDev;
	newMax=nStdMax*stdDev;
	MnMx = [newMin newMax];
end
A2=mat2gray(A,MnMx);   %scale the whole array so that min = 0, max = 1
[Iarr, ~] = gray2ind(A2, 256); %convert the whole array to 8bit indexed


function Iarr = convertBWArray(A)
%Convert a logical array.
[Iarr, ~] = gray2ind(A, 256); %convert the whole array to 8bit indexed


function Iarr = convertDblArray(A,MnMx)
%Convert a double positive array. Optional contrast enhancement.
if nargin > 1 || ~isempty(MnMx),
	A2=mat2gray(A,MnMx);   %scale the whole array so that min = 0, max = 1
else
	A2=mat2gray(A);   %scale the whole array so that min = 0, max = 1
end
[Iarr, ~] = gray2ind(A2, 256); %convert the whole array to 8bit indexed
