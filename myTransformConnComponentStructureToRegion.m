function region = myTransformConnComponentStructureToRegion(fnm,fnmRegionDummy)

%James B. Ackman (c) 1/13/2013

load(fnm)
load(fnmRegionDummy)

nDomains = length(STATS);
region.onsets = cell(1,nDomains);
region.offsets = cell(1,nDomains);
sz = CC.ImageSize;
region.traces = ones(nDomains,sz(3));

for i = 1:nDomains
   BoundingBox = STATS(i).BoundingBox;
   region.onsets{i} = [region.onsets{i} ceil(BoundingBox(3))];
   region.offsets{i} = [region.offsets{i} ceil(BoundingBox(3))+ceil(BoundingBox(6))-1];
   %add grouping centroid intersect lookback option here
end