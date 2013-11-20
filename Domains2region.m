function region = Domains2region(domains, CC,STATS,region,hemisphereIndices)
%region = Domains2region(domains, CC,STATS,region)
%convert domain assignments from a 3D connected components array to calciumdx region data structure that can be used for rasterplots, and all down stream analysis functions
% need CC, connected components and STATS, the structure returned by regionprops and dummy 'region' file with any regions.coords and .names that you might want to use to label the domains
% James B. Ackman 2013-01-04 22:39:23

if nargin < 5 || isempty(hemisphereIndices), hemisphereIndices = [2 3]; end  %index location of the hemisphere region outlines in the 'region.location' calciumdx struct

region.onsets = {};
region.offsets = {};
region.contours = {};
region.location = []

for i = 1:length(domains)
	onsets = [];
	offsets = [];
	%maxampl = [];  %TODO:
	%meanampl = []; %TODO:
	
	
	OrigIndex = unique(domains(i).OrigDomainIndex);
	
	for j = 1:length(OrigIndex)
		onsets = [onsets ceil(STATS(OrigIndex(j)).BoundingBox(3))];
		offsets = [offsets ceil(STATS(OrigIndex(j)).BoundingBox(3))+(ceil(STATS(OrigIndex(j)).BoundingBox(6))-1)];
	end
	region.onsets{i} = onsets;
	region.offsets{i} = offsets;
	
%	i=1
%	j=1
	BW = zeros(CC.ImageSize(1:2));
	BW(domains(i).PixelInd) = 1;
	[BP2,L] = bwboundaries(BW,'noholes');
	boundary = BP2{1};
	locatmp = [boundary(:,2) boundary(:,1)];
	region.contours{i} = locatmp;
	
	CC2 = bwconncomp(BW);
	STATS2 = regionprops(CC2,'Centroid');
	centrInd = sub2ind(CC.ImageSize(1:2),round(STATS2(1).Centroid(2)),round(STATS2(1).Centroid(1)));
	
	region.location(i) = 1;
	
	for j=1:length(hemisphereIndices)
		sz = CC.ImageSize(1:2);
		regionMask1 = poly2mask(region.coords{hemisphereIndices(j)}(:,1),region.coords{hemisphereIndices(j)}(:,2),sz(1),sz(2));
		%regionMask2 = poly2mask(region.coords{hemisphereIndices(2)}(:,1),region.coords{hemisphereIndices(2)}(:,2),sz(1),sz(2));
		%figure; imshow(regionMask1); 	figure; imshow(regionMask2);
		
		if ~isempty(intersect(find(regionMask1), centrInd))
			region.location(i) = hemisphereIndices(j);
		end		
	end
end 

region.traces = ones(length(domains),CC.ImageSize(3));  %make dummy traces for now. TODO
