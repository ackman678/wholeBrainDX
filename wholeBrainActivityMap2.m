function wholeBrainActivityMap2(region, plotType)
%wholeBrainActivityMap(region, plotType)
% Example
%	wholeBrainActivityMap(region,1)
% INPUTS
% region -- region formatted data structure (as from CalciumDX, domains2region, etc) that includes CC and STATS data structures returned from wholeBrain_segmentation.m and wholeBrain_kmeans.m
% plotType -- an integer of 1, 2, or 3 indicating the type of plot you want 
%	1: plot all detected components (true positive activity domains and false positive artifacts)
%	2: plot without false positive artifacts tagged in the STATS.descriptor variable in region.STATS
%	3: plot only the false positive artifacts

% James B. Ackman 2013-10-10 14:31:28


CC = region.domainData.CC;  
STATS = region.domainData.STATS;  
sz=region.domainData.CC.ImageSize;
if (nargin < 2 || isempty(plotType)) && isfield(STATS, 'descriptor'), plotType = 1; end

%-----------main-----------------
BW = makeBlankArray(sz);

switch plotType
case 1
	A3 = makeBinaryPixelArray(BW,CC);
case 2
	A3 = makeBinaryPixelArrayTagged(BW, CC, STATS, '')
case 3
	A3 = makeBinaryPixelArrayTagged(BW, CC, STATS, 'artifact')
otherwise
	return
end

figure;
normA3count = A3count./mx1;
imagesc(normA3count);
mx = max(normA3count(:));
disp(['mx normA3 = ' num2str(mx)])
title(['Signal px count norm to max sig count. MaxSig=' num2str(mx)]); colorbar('location','eastoutside'); axis image


%-----------functions-------------

function BW = makeBlankArray(sz)
tmp = zeros(sz,'uint8');
BW = logical(tmp);
clear tmp;

function A3 = makeBinaryPixelArray(BW, CC)
for i = 1:CC.NumObjects  
	A3(CC.PixelIdxList{i}) = 1;  
end

function A3 = makeBinaryPixelArrayTagged(BW, CC, STATS, tag)
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
A3count = sum(A3(:,:,startFrame:endFrame),3);
mx1=max(A3count(:));  


function makeSubplot(img,handles,axesTitle, maxSig) 
set(handles.figHandle,'CurrentAxes',axesHandle)
imagesc(img);
title([axesTitle num2str(maxSig)]); colorbar('location','eastoutside'); axis image
