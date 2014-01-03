function region = domainMarks2Descriptor(region, data, desc, dataInd)
% Add descriptor ('artifact') to tag domains in movie
% Uses region data file and 'data' returned from the export data function of plotWholeBrainTraces.m where the 'data' contains a list of tagged domains.
% James B. Ackman 2013-10-09

%setup defaults
if nargin < 4 || isempty(dataInd), dataInd = 2; end %default location from fetching the points from the matlab gui
if nargin < 3 || isempty(desc), desc = 'artifact'; end

if ~isfield(region.domainData.STATS, 'descriptor')
    for i = 1:length(region.domainData.STATS)
        region.domainData.STATS(i).descriptor = '';
    end
end

%----end setup defaults-------
sz=region.domainData.CC.ImageSize;
tmp = zeros(sz,'uint8');
BW = logical(tmp);
clear tmp;

for fr = 1:length(data(dataInd).frame);
	for j = 1:length(data(dataInd).frame(fr).badDomains.x)
		n = round(data(dataInd).frame(fr).badDomains.x(j));
		m = round(data(dataInd).frame(fr).badDomains.y(j));
		if m >= 1 & m <= sz(1) & n >=1 & n <= sz(2)
			BW(m,n,fr) = 1;
		end
	end
end

ind = find(BW);

nDomains = length(region.domainData.domains);


for i = 1:nDomains
	if ~isempty(intersect(region.domainData.CC.PixelIdxList{i},ind));
		region.domainData.STATS(i).descriptor = desc;
	end
end
