function [Im] = Iarr2montage(Iarr, frStart, frEnd, Iter, filename, nrow, ncol)
%Iarr2montage - Make time based montage from 8 bit indexed array
%PURPOSE -- Make time based montage from indexed array. Calls matlab builtin function 'montage'
%USAGE -- 	[Im] = Iarr2montage(Iarr,1638,1757, 5);
%			Iarr2montage(Iarr,1638,1757, [], 'filename.tif');
%			Iarr2montage(Iarr,1638,1757, [], 'filename.tif', [], 6);
% Iarr - indexed movie array, output Iarr from timeColorMapProj)
% frStart - integer, start frame
% frEnd - integer, end frame
% Iter - integer, frame iterator for montage (defaults to 1, but probably should be set for every 5 or 10 frames)
% filename - string, the 'filename.tif' that the data come from and the string from which the output filename will be formatted
% nrow - number of rows for the montage, default is to let builtin montage calculate for approx square montage
% ncol - number of cols for the montage, default is to let builtin montage calculate for approx square montage
%
% See also timeColorMapProj.m, Iarr2avi.m
%
%James B. Ackman 2014-07-27 20:39:50

sz=size(Iarr);
if nargin < 6 || isempty(nrow), 
	dim(1)=[NaN]; 
else
	dim(1)=nrow;
end
if nargin < 7 || isempty(ncol), 
	dim(2)=[NaN]; 
else
	dim(2)=ncol;
end
if nargin < 4 || isempty(Iter), Iter=1; end
if nargin < 3 || isempty(frEnd), frEnd=sz(3); end
if nargin < 2 || isempty(frStart), frStart=1; end
if sz(3) < 2
	error('Need an array to make time projection')
end

if nargin < 5 || isempty(filename), 
	filename = [];
else
	filename = [filename(1:length(filename)-4) '-fr' num2str(frStart) '-' num2str(frEnd) '-' datestr(now,'yyyymmdd-HHMMSS') '-montage' '.png']; 
end

rgbColors = jet(256);
totalframes = frStart:Iter:frEnd;
rgbA = zeros(sz(1), sz(2), 3, numel(totalframes));

k=0;
for fr = totalframes
    k=k+1;
    RGB=ind2rgb(Iarr(:,:,fr),rgbColors);
    rgbA(:,:,:,k) = RGB;
end

h = montage(rgbA, 'Size', dim);
Im = get(h, 'CData');

if ~isempty(filename)
	imwrite(Im,filename,'png')
end
