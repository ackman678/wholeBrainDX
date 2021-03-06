function Iarr2avi(Iarr, frStart, frEnd, filename, useFFmpeg, q)
%Iarr2avi - Make avi movie
%PURPOSE -- Make avi movie from from 8 bit indexed array. Use in conjunction with output from timeColorMapProj.m
%USAGE -- 	Iarr2avi(Iarr,1638,1757, 'filename.tif');
% Iarr - indexed movie array, output Iarr from timeColorMapProj)
% frStart - integer, start frame
% frEnd - integer, end frame
% filename - string, the 'filename.tif' that the data come from and the string from which the output filename will be formatted
% useFFmpeg - binary, flag to indicate whether ffmpeg should be used if found on local system
% q - numeric value between 1-31 to indicate video mjpeg compression quality for ffmpeg. 1 is very high quality (bigger file), 31 is very low quality (smaller file).
%
% See also timeColorMapProj.m, Iarr2montage.m, myMovie2avi.m
%
%James B. Ackman 2014-07-28 08:06:40

if nargin < 6 || isempty(q), q = 15; end
if nargin < 5 || isempty(useFFmpeg), useFFmpeg = 1; end

sz=size(Iarr);
if nargin < 3 || isempty(frEnd), frEnd=sz(3); end
if nargin < 2 || isempty(frStart), frStart=1; end
if sz(3) < 2
	error('Need an array to make time projection')
end

if nargin < 4 || isempty(filename), 
	error('Must input filename. e.g. "filename.tif"')
else
	filename = [filename(1:length(filename)-4) '-fr' num2str(frStart) '-' num2str(frEnd) '-' datestr(now,'yyyymmdd-HHMMSS') '-dFoF' '.avi']; 
end

rgbColors = jet(256);
totalframes = frStart:frEnd;
M(numel(totalframes)) = struct('cdata',[],'colormap',[]);

%Transform the indexed array into a matlab specific 'movie' data structure that can be written as an motion JPEG .avi to disk.
k=0;
for fr = totalframes
	k=k+1;
	M(k) = im2frame(Iarr(:,:,fr),rgbColors);
end
writeMovie(M,filename,useFFmpeg,q)
