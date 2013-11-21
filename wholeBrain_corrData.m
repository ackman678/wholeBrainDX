function region = wholeBrain_corrData(fnm, region, exclude)
%wholeBrain_corrData - Generate Pearson correlation matrix for all pairs of locations in the region data structure.
%Examples:
% region = wholeBrain_corrData(region)
% region = wholeBrain_corrData(region,{'cortex.L' 'cortex.R' 'SC.L' 'SC.R'})
%**USE**
% region - region data structure with region.locationData.data structure returned from wholeBrain_activeFraction.m
% exclude - cellstr array, list of locations to exclude from the corr matrix
%Output:
%region - will return region data structure with corr data at region.userdata.corr. Will also display corr matrix plot and rasterplot of activeFraction traces.
%
% See also wholeBrain_activeFraction.m, batchFetchCorrData
%
%James B. Ackman, 2013-11-15 11:27:43


if nargin < 3 || isempty(exclude), exclude = {'cortex.L' 'cortex.R'}; end

data = region.locationData.data;  
names = {region.locationData.data.name};
for i = 1:length(exclude)
	names = names(~strcmp(names,exclude(i)));
end
X = zeros(length(data(1).activeFractionByFrame), length(names));  
for i = 1:length(names)  
	X(:,i) = data(strcmp(names,names(i))).activeFractionByFrame';    
end    
[r,p]=corrcoef(X); 

if isfield(region,'userdata') & isfield(region.userdata,'corr')
	datasetSelector = length(region.userdata.corr) + 1;
	region.userdata.corr{datasetSelector}.pvalCorrMatrix = p;  
	region.userdata.corr{datasetSelector}.rvalCorrMatrix = r;  
	[i,j] = find(tril(r,-1) ~= 0);  %this will take all pairs, no threshold for comparison  
	region.userdata.corr{datasetSelector}.corr_pairs{1} = [i j];  
	region.userdata.corr{datasetSelector}.names = names;
else
	datasetSelector = 1;
	region.userdata.corr{datasetSelector}.pvalCorrMatrix = p;  
	region.userdata.corr{datasetSelector}.rvalCorrMatrix = r;  
	[i,j] = find(tril(r,-1) ~= 0);  %this will take all pairs, no threshold for comparison  
	region.userdata.corr{datasetSelector}.corr_pairs{1} = [i j];  
	region.userdata.corr{datasetSelector}.names = names;
end

%--Raster plot----
handles.figHandle = figure;
%scrsize = get(0,'screensize');
%set(handles.figHandle,'Position',scrsize);
set(handles.figHandle,'color',[1 1 1]);
%set(handles.figHandle,'PaperType','usletter');
%set(handles.figHandle,'PaperPositionMode','auto');%         numplots = numel(stimuli{numStim}.stimulusParams);

myColors = jet(256);
myColors(1,:) = [1 1 1];
colormap(myColors);
imagesc(X')
title('activeFraction raster plot')
colorbar
names = region.userdata.corr{datasetSelector}.names;
set(gca,'YTick',[1:length(names)])
set(gca,'YTickLabel',names)    

print(gcf, '-dpng', [fnm(1:end-4) 'ActvRaster' datestr(now,'yyyymmdd-HHMMSS') '.png']);       
print(gcf, '-depsc', [fnm(1:end-4) 'ActvRaster' datestr(now,'yyyymmdd-HHMMSS') '.eps']); 





%--Corr matrix plot
figure;
datasetSelector = 1; %usually 1, unless multiple datasets of corr exist from multiple runs
r = region.userdata.corr{datasetSelector}.rvalCorrMatrix;
r(r==1) = 0;
imagesc(r)
colorbar    
caxis('auto')    
axis image    
title('rho, caxis auto')

names = region.userdata.corr{datasetSelector}.names;
set(gca,'YTick',[1:length(names)])
set(gca,'YTickLabel',names)    
XTick = get(gca,'XTick');  
set(gca,'XTickLabel',names(XTick)) %Plot just a few XTick labels, otherwise they get garbled and there is no great way to rotate labels in matlab for image axes...

print(gcf, '-dpng', [fnm(1:end-4) 'corrMatrix' datestr(now,'yyyymmdd-HHMMSS') '.png']);       
print(gcf, '-depsc', [fnm(1:end-4) 'corrMatrix' datestr(now,'yyyymmdd-HHMMSS') '.eps']); 



