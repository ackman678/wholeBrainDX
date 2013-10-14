function wholeBrainActivityMap(region, removArtifacts)
%wholeBrainActivityMap(region, removArtifacts)
% Example
%	wholeBrainActivityMap(region)
% James B. Ackman 2013-10-10 14:31:28

CC = region.domainData.CC;  
STATS = region.domainData.STATS;  
sz=region.domainData.CC.ImageSize;

if (nargin < 2 || isempty(removArtifacts)) && isfield(STATS, 'descriptor'), removArtifacts = 1; end

tmp = zeros(sz,'uint8');
A3 = logical(tmp);
clear tmp;


clims = [0 max([mxA3norm mxA4norm])];


switch removArtifacts
case 1
	A4 = A3;
	for i = 1:CC.NumObjects  
		if ~strcmp(STATS(i).descriptor, 'artifact')  
			A3(CC.PixelIdxList{i}) = 1;  
		else
			A4(CC.PixelIdxList{i}) = 1;  
		end  
	end

	nSigPx = numel(find(A3));
	nNoisePx = numel(find(A4));

disp([num2str(nSigPx) ' true positive active pixels'])
disp([num2str(nNoisePx) ' false positive active pixels'])

	A3count = sum(A3,3);
	mx1=max(A3count(:));  
	disp(['mx1 = ' num2str(mx1)])

	A4count = sum(A4,3);
	mx2=max(A4count(:));  
	disp(['mx2 = ' num2str(mx2)])

	normA3count = A3count./mx1;
	mxA3norm = max(normA3count(:));
	disp(['mx normA3 = ' num2str(mxA3norm)])

	normA4count = A4count./mx1;
	mxA4norm = max(normA4count(:));
	disp(['mx normA4 = ' num2str(mxA4norm)])
	clims = [0 max([mxA3norm mxA4norm])];

	figure;
	subplot(1,2,1)
	imagesc(normA3count,clims);
	title(['Signal px count norm to max sig count. MaxSig=' num2str(mxA3norm)]); colorbar('location','eastoutside'); axis image

	subplot(1,2,2)
	imagesc(normA4count,clims);
	title(['Noise px count norm to max sig count. MaxNoise=' num2str(mxA4norm)]); colorbar('location','eastoutside'); axis image

case 2
	for i = 1:CC.NumObjects  
		A3(CC.PixelIdxList{i}) = 1;  
	end

	A3count = sum(A3,3);
	mx1=max(A3count(:));  

	figure;
	normA3count = A3count./mx1;
	imagesc(normA3count);
	mx = max(normA3count(:));
	disp(['mx normA3 = ' num2str(mx)])
	title(['Signal px count norm to max sig count. MaxSig=' num2str(mx)]); colorbar('location','eastoutside'); axis image

end



function handles = setupPlot(figHandle,nRows,nCols)
if nargin < 1 || isempty(figHandle), figHandle = figure; end
if nargin < 2 || isempty(nRows), nRows = 1; end
if nargin < 3 || isempty(nCols), nCols = 1; end

handles.figHandle = figHandle;

for i = 1:nRows
handles.ax(i) = subplot(
end

for i = 1:nCols

end
