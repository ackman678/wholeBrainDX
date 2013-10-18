function [A3proj,frames] = wholeBrainActivityMapProj(region, frames, plotType)
%wholeBrainActivityMapProj(region, frames, plotType)
% Examples
%	[A3proj,frames] = wholeBrainActivityMapProj(region);
%	A3proj = wholeBrainActivityMapProj(region, [], 1);
%	[A3proj,frames] = wholeBrainActivityMapProj(region, [300 1800], 2);
% INPUTS
% region -- region formatted data structure (as from CalciumDX, domains2region, etc) that includes CC and STATS data structures returned from wholeBrain_segmentation.m and wholeBrain_kmeans.m
% frames -- frames should be a vector containing two integers, the startFrame and endFrame for the range you want to plot
% plotType -- an integer of 1, 2, or 3 indicating the type of plot you want 
%	1: plot all detected components (true positive activity domains and false positive artifacts)
%	2: plot without false positive artifacts tagged in the STATS.descriptor variable in region.STATS
%	3: plot only the false positive artifacts
% James B. Ackman 2013-10-10 14:31:28

%sumProjectArray() function here could be changed to other Array projections to different types of images (amplitude instead of pixel frequency, distances/optical flow transforms. mean domain membership size, duration)

CC = region.domainData.CC;  
STATS = region.domainData.STATS;  
sz=region.domainData.CC.ImageSize;

if (nargin < 2 || isempty(plotType)), plotType = 1; end
if (nargin < 3 || isempty(frames)), frames = [1 sz(3)]; end

%-----------main-----------------
BW = makeBlankArray(sz);
frTxt = ['fr' num2str(frames(1)) ':' num2str(frames(2))];

switch plotType
case 1
	A3 = makeBinaryPixelArray(BW,CC);
	nSigPx = numel(find(A3));
	disp([num2str(nSigPx) ' whole movie detected active pixels'])

	A3proj = sumProjectArray(A3,frames);

	nSigPx2 = sum(A3proj(:));
	disp([num2str(nSigPx2) ' ' frTxt ' detected active pixels'])
	disp([num2str(round(nSigPx2/(diff(frames)*region.timeres))) ' active pixels/sec'])
	
	disp(['Fraction of total: ' num2str(nSigPx2/nSigPx)])
case 2
	A3 = makeBinaryPixelArrayTagged(BW, CC, STATS, '');
	nSigPx = numel(find(A3));
	disp([num2str(nSigPx) ' whole movie true positive active pixels'])

	A3proj = sumProjectArray(A3,frames);

	nSigPx2 = sum(A3proj(:));
	disp([num2str(nSigPx2) ' ' frTxt ' true positive active pixels'])
	disp([num2str(round(nSigPx2/(diff(frames)*region.timeres))) ' active pixels/sec'])
	disp(['Fraction of total: ' num2str(nSigPx2/nSigPx)])
case 3
	A3 = makeBinaryPixelArrayTagged(BW, CC, STATS, 'artifact');
	nNoisePx = numel(find(A3));
	disp([num2str(nNoisePx) ' whole movie false positive active pixels'])

	A3proj = sumProjectArray(A3,frames);

	nNoisePx2 = sum(A3proj(:));
	disp([num2str(nNoisePx2) ' ' frTxt ' false positive active pixels'])
	disp([num2str(round(nNoisePx2/(diff(frames)*region.timeres))) ' active pixels/sec'])
	disp(['Fraction of total: ' num2str(nNoisePx2/nNoisePx)])
otherwise
	return
end

%-----------functions-------------

function BW = makeBlankArray(sz)
tmp = zeros(sz,'uint8');
BW = logical(tmp);
clear tmp;

function A3 = makeBinaryPixelArray(A3, CC)
for i = 1:CC.NumObjects  
	A3(CC.PixelIdxList{i}) = 1;  
end

function A3 = makeBinaryPixelArrayTagged(A3, CC, STATS, tag)
%tag should be 'artifact' if you want to plot artifacts or '' if you want to plot with artifacts removed.
if (nargin < 3 || isempty(tag)), tag = ''; end
for i = 1:CC.NumObjects  
	if strcmp(STATS(i).descriptor, tag)  
		A3(CC.PixelIdxList{i}) = 1;  
	end
end

function A3count = sumProjectArray(A3,frames)
%frames should be a vector containing two integers, the startFrame and endFrame for the range you want to plot
if (nargin < 2 || isempty(frames)), frames = [1 size(A3,3)]; end
A3count = sum(A3(:,:,frames(1):frames(2)),3); 
