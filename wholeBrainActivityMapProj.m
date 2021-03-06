function [A3proj,frames] = wholeBrainActivityMapProj(region, frames, plotType, mapType)
%wholeBrainActivityMapProj(region, frames, plotType)
% Examples
%	[A3proj,frames] = wholeBrainActivityMapProj(region);
%	A3proj = wholeBrainActivityMapProj(region, [], 1);
%	[A3proj,frames] = wholeBrainActivityMapProj(region, [300 1800], 2);
% INPUTS
% region -- region formatted data structure (as from CalciumDX, domains2region, etc) that includes CC and STATS data structures returned from wholeBrain_segmentation.m and wholeBrain_detect.m
% frames -- frames should be a vector containing two integers, the startFrame and endFrame for the range you want to plot.
% plotType -- an integer of 1, 2, or 3 indicating the type of plot you want 
%	1: plot all detected components (true positive activity domains and false positive artifacts)
%	2: plot without false positive artifacts tagged in the STATS.descriptor variable in region.STATS
%	3: plot only the false positive artifacts
% James B. Ackman 2013-10-10 14:31:28

%sumProjectArray() function here could be changed to other Array projections to different types of images (amplitude instead of pixel frequency, distances/optical flow transforms. mean domain membership size, duration)

domains = region.domainData.domains;
CC = region.domainData.CC;  
STATS = region.domainData.STATS;  
sz=CC.ImageSize;


if (nargin < 2 || isempty(frames)), frames = [1 sz(3)]; end
if (nargin < 3 || isempty(plotType)), plotType = 1; end
if (nargin < 4 || isempty(mapType)), mapType = 'pixelFreq'; end

%-----------main-----------------
frTxt = ['fr' num2str(frames(1)) ':' num2str(frames(2))];

if (strcmp(mapType,'pixelFreq') | strcmp(mapType,'actvTimeFraction'))
	A3bw = makeBlankArray(sz);
else
	A3 = zeros(sz(1:2));
end

switch plotType
case 1
	switch mapType
		case 'pixelFreq'
			A3bw = makeBinaryPixelArray(A3bw,CC);
			nSigPx = numel(find(A3bw));
			disp([num2str(nSigPx) ' whole movie detected active pixels'])

			A3proj = sumProjectArray(A3bw,frames);

			nSigPx2 = sum(A3proj(:));
			disp([num2str(nSigPx2) ' ' frTxt ' detected active pixels'])
			disp([num2str(round(nSigPx2/(diff(frames)*region.timeres))) ' active pixels/sec'])

			disp(['Fraction of total: ' num2str(nSigPx2/nSigPx)])
		case {'domainFreq','domainDur','domainDiam','domainAmpl'}
			%TODO: makeother			
		otherwise
			warning('Unexpected mapType. No plot created.');
	end	
case 2
	switch mapType
		case 'pixelFreq'
			A3bw = makeBinaryPixelArrayTagged(A3bw, CC, STATS, '');
			nSigPx = numel(find(A3bw));
			disp([num2str(nSigPx) ' whole movie true positive active pixels'])

			A3proj = sumProjectArray(A3bw,frames);

			nSigPx2 = sum(A3proj(:));
			disp([num2str(nSigPx2) ' ' frTxt ' true positive active pixels'])
			disp([num2str(round(nSigPx2/(diff(frames)*region.timeres))) ' active pixels/sec'])
			disp(['Fraction of total: ' num2str(nSigPx2/nSigPx)])	
		
		case 'actvTimeFraction'
			A3bw = makeBinaryPixelArrayTagged(A3bw, CC, STATS, '');
			nSigPx = numel(find(A3bw));
			disp([num2str(nSigPx) ' whole movie true positive active pixels'])

			A3proj = sumProjectArray(A3bw,frames);

			nSigPx2 = sum(A3proj(:));
			disp([num2str(nSigPx2) ' ' frTxt ' true positive active pixels'])
			disp([num2str(round(nSigPx2/(diff(frames)*region.timeres))) ' active pixels/sec'])
			disp(['Fraction of total: ' num2str(nSigPx2/nSigPx)])	

			A3proj = A3proj ./ (diff(frames) + 1); 
			A3proj = A3proj .* ((diff(frames) + 1) .* region.timeres);
		case 'domainFreq'
			A3proj = makeBinaryPixelArrayTaggedDomainFreq(A3, CC, STATS, domains, '', frames);
			A3proj = A3proj ./ ((diff(frames) + 1) .* region.timeres .* (1/60)); %freq (min^-1s)
		case 'domainDur'
			A3proj = makeBinaryPixelArrayTaggedDomainDuration(A3, CC, STATS, domains, '', frames, region);
		case 'domainDiam'
			A3proj = makeBinaryPixelArrayTaggedDomainDiameter(A3, CC, STATS, domains, '', frames, region);
		case 'domainAmpl'	
			A3proj = makeBinaryPixelArrayTaggedDomainAmplitude(A3, CC, STATS, domains, '', frames);
		otherwise
			warning('Unexpected mapType. No plot created.');
	end		

case 3
	switch mapType
		case 'pixelFreq'
			A3bw = makeBinaryPixelArrayTagged(A3bw, CC, STATS, 'artifact');
			nNoisePx = numel(find(A3bw));
			disp([num2str(nNoisePx) ' whole movie false positive active pixels'])

			A3proj = sumProjectArray(A3bw,frames);

			nNoisePx2 = sum(A3proj(:));
			disp([num2str(nNoisePx2) ' ' frTxt ' false positive active pixels'])
			disp([num2str(round(nNoisePx2/(diff(frames)*region.timeres))) ' active pixels/sec'])
			disp(['Fraction of total: ' num2str(nNoisePx2/nNoisePx)])
		case {'domainFreq','domainDur','domainDiam','domainAmpl'}
			%TODO: makeother
		otherwise
			warning('Unexpected mapType. No plot created.');
	end		

otherwise
	warning('Unexpected plotType vargin. No plot created.');
end

function BW = makeBlankArray(sz)
BW = false(sz);

%-----------functions-------------
function A3 = makeBinaryPixelArray(A3, CC)
for i = 1:CC.NumObjects  
	A3(CC.PixelIdxList{i}) = 1;  
end

function A3 = makeBinaryPixelArrayTagged(A3, CC, STATS, tag)
%tag should be 'artifact' if you want to plot artifacts or '' if you want to plot with artifacts removed.
if (nargin < 4 || isempty(tag)), tag = ''; end
for i = 1:CC.NumObjects  
	if strcmp(STATS(i).descriptor, tag)  
		A3(CC.PixelIdxList{i}) = 1;  
	end
end

function A3count = sumProjectArray(A3,frames)
%frames should be a vector containing two integers, the startFrame and endFrame for the range you want to plot
if (nargin < 2 || isempty(frames)), frames = [1 size(A3,3)]; end
A3count = sum(A3(:,:,frames(1):frames(2)),3); 

function A3 = makeBinaryPixelArrayTaggedDomainFreq(A3, CC, STATS, domains, tag, frames)
%tag should be 'artifact' if you want to plot artifacts or '' if you want to plot with artifacts removed.
if (nargin < 5 || isempty(tag)), tag = ''; end
for i = 1:CC.NumObjects  
	if strcmp(STATS(i).descriptor, tag) & ceil(STATS(i).BoundingBox(3)) >= frames(1) & ceil(STATS(i).BoundingBox(3)) <= frames(2)
		BW = zeros(CC.ImageSize(1:2));
		BW(domains(i).PixelInd) = 1;
		A3 = A3 + BW;
	end
end

function A3proj = makeBinaryPixelArrayTaggedDomainDuration(A3, CC, STATS, domains, tag, frames, region)
%tag should be 'artifact' if you want to plot artifacts or '' if you want to plot with artifacts removed.
framePeriod = region.timeres;
if (nargin < 5 || isempty(tag)), tag = ''; end

roiBoundingBox = zeros(length(STATS),6);
for i = 1:length(STATS)
    roiBoundingBox(i,:) = STATS(i).BoundingBox;
end

durations = roiBoundingBox(:,6) * framePeriod;
A3proj = meanProjectArray(A3, CC, STATS, domains, durations, tag, frames);


function A3proj = makeBinaryPixelArrayTaggedDomainDiameter(A3, CC, STATS, domains, tag, frames, region)
%tag should be 'artifact' if you want to plot artifacts or '' if you want to plot with artifacts removed.
spaceres = region.spaceres;
if (nargin < 5 || isempty(tag)), tag = ''; end

roiBoundingBox = zeros(length(STATS),6);
for i = 1:length(STATS)
    roiBoundingBox(i,:) = STATS(i).BoundingBox;
end

diameters = mean([roiBoundingBox(:,4) roiBoundingBox(:,5)], 2) .* spaceres;
%A3proj = meanProjectArray(A3, CC, STATS, domains, diameters, tag, frames);
A3proj = medianProjectArray(A3, CC, STATS, domains, diameters, tag, frames, region);


function A3proj = makeBinaryPixelArrayTaggedDomainAmplitude(A3, CC, STATS, domains, tag, frames)
%tag should be 'artifact' if you want to plot artifacts or '' if you want to plot with artifacts removed.
if (nargin < 5 || isempty(tag)), tag = ''; end

roiMean=[STATS.MeanIntensity];
A3proj = meanProjectArray(A3, CC, STATS, domains, roiMean, tag, frames);


function A3proj = meanProjectArray(A3, CC, STATS, domains, signalMetric, tag, frames)
%frames should be a vector containing two integers, the startFrame and endFrame for the range you want to plot
sz = CC.ImageSize(1:2);
count = ones(sz(1),sz(2));
for i = 1:CC.NumObjects  
	if strcmp(STATS(i).descriptor, tag) & ceil(STATS(i).BoundingBox(3)) >= frames(1) & ceil(STATS(i).BoundingBox(3)) <= frames(2)
		sig = signalMetric(i);
		BW = false(sz(1),sz(2));
		BW2 = zeros(sz(1),sz(2));
		BW(domains(i).PixelInd) = true;
		BW2(domains(i).PixelInd) = sig;
		count = count + BW;
		A3 = A3 + BW2;
	end
end
A3proj = A3./count; 


function A3proj = medianProjectArray(A3, CC, STATS, domains, signalMetric, tag, frames, region, thr)
%frames should be a vector containing two integers, the startFrame and endFrame for the range you want to plot
%this function requires the statistics toolbox (nanmedian)
if nargin < 9 || isempty(thr), thr = 0.15; end
sz = CC.ImageSize;
A3 = NaN(sz(1),sz(2),CC.NumObjects);
hemisphereIndices = find(strcmp(region.name,'cortex.L') | strcmp(region.name,'cortex.R')); 
if ~isempty(hemisphereIndices)
	dim = max(region.coords{hemisphereIndices(1)}) - min(region.coords{hemisphereIndices(1)}) + 1;
	maxDiam = mean(dim * region.spaceres);
	thr = maxDiam - (thr*maxDiam);
else
	thr = mean(sz(1:2) * region.spaceres);
end
for i = 1:CC.NumObjects  
	if strcmp(STATS(i).descriptor, tag) & ceil(STATS(i).BoundingBox(3)) >= frames(1) & ceil(STATS(i).BoundingBox(3)) <= frames(2) & signalMetric(i) < thr
		BW = NaN(sz(1),sz(2));
		BW(domains(i).PixelInd) = signalMetric(i);
		A3(:,:,i) = BW;
	end
end
% A3proj = nanmedian(A3,3);
A3proj = nanmean(A3,3); %mean is more accurate for activity maps
A3proj(isnan(A3proj)) = 0;
