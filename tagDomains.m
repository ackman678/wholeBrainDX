function region = tagDomains(region, taggedCentrBorders, desc)
%tagDomains - Locate domain centroids that are inside a list of polygonal borders and tag the domains with a descriptive string
%
%Examples:
% >> region = tagDomains(region,taggedCentrBorders)
% >> region = tagDomains(region,taggedCentrBorders,'artifact')
%
%**USE**
%region - datastructure, if you just want to do a single file loaded into workspace
%taggedCentrBorders - Cell array containing border coordinates returned from the Export function of domainTaggingGui or plotWholeBrainDomainsTraces
%
%Options:
%desc - string for description, defaults to 'artifact'
%
%Output:
% Returns the 'region' data structure
%
% See also domainTaggingGui, plotWholeBrainDomainsTraces, domainMarks2Descriptor, DomainPatchesPlot, Domains2region
%
%James B. Ackman, 2014-01-24 14:00:00  

if nargin < 3 || isempty(desc), desc = 'artifact'; end
handles.region = region;
handles.bord = taggedCentrBorders;
sz = handles.region.domainData.CC.ImageSize;

for ind = 1:length(handles.bord)
	x = handles.bord{ind}(:,1);  %use the data returned from giinput
	y = handles.bord{ind}(:,2);  %use the data returned from giinput
	mask = poly2mask(x,y,sz(1),sz(2));

	if ~isfield(handles.region.domainData.STATS, 'descriptor')
		for i = 1:length(handles.region.domainData.STATS)
			handles.region.domainData.STATS(i).descriptor = '';
		end
	end

	nDomains = length(handles.region.domainData.domains);
	for i = 1:nDomains
		centr = handles.region.domainData.STATS(i).Centroid;
		centr = round([centr(1) centr(2)]);
		if mask(centr(2),centr(1))
			handles.region.domainData.STATS(i).descriptor = 'artifact';
		end
	end
end
region = handles.region;
