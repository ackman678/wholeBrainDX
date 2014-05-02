function myMovie2avi(A,fnm,graylevels)
%PURPOSE -- Save a motion jpeg avi file from a matlab array
%Need the a movie (A or A2) or binary array (A3) returned from for example wholeBrain_segmentation or wholeBrain_detect.m
%Need a filename, fnm
%Need to specify number of graylevels if not a binary array (e.g. 256 gray levels for a dF/F signal movie)
%USAGE -- myMovie2avi(A3,fnm)
%James B. Ackman 2/20/2013

if nargin < 3 || isempty(graylevels), graylevels = 8; end %default graylevels is good for a converted binary signal.  %change to 256 for 8 bit signals.

if nargin < 2 || isempty(fnm),
	fnm2 = [datestr(now,'yyyymmdd-HHMMSS') '.avi']; 
else
	fnm2 = [fnm(1:length(fnm)-4) datestr(now,'yyyymmdd-HHMMSS') '.avi']; 
end

Iarr=mat2gray(A);   %scale the whole array A

%--BEGIN optional---
% If you want to boost the contrast for all those pixels within your hemisphere masks uncomment the following
%bothMasksArr = repmat(bothMasks,[1 1 szZ]);
%tmp = Iarr(bothMasksArr);
%LOW_HIGH = stretchlim(tmp);
%for fr=1:szZ
%
%Iarr(:,:,fr) = imadjust(Iarr(:,:,fr),LOW_HIGH,[]);
%end
%---END optional---

[I2arr, map] = gray2ind(Iarr, graylevels); %convert the whole array to indexed

%Transform the binary array into a matlab specific 'movie' data structure that can be written as an motion JPEG .avi to disk.
for fr=1:size(A,3)
	M(fr) = im2frame(I2arr(:,:,fr),map);
end

%write the motion JPEG .avi to disk using auto-generated datestring based filename
vidObj = VideoWriter(fnm2)
open(vidObj)
for i =1:numel(M)
	writeVideo(vidObj,M(i));
end
close(vidObj)
