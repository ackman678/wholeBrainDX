function region = wholeBrain_SpatialCOMCorr(fnm,region,names)
%wholeBrain_SpatialCOMCorr - Generate cross-correlation plots and values for Cortical Spatial Center of Mass corr between hemispheres
%Examples:
% region = wholeBrain_SpatialCOMCorr(fnm,region)
% region = wholeBrain_SpatialCOMCorr(fnm,region,st)
%**USE**
% fnm - .mat filename, from which filenames for plots will be saved (nothing will be overwritten) 
% region - region data structure with region.locationData.data structure returned from wholeBrain_activeFraction.m
% st - a structure array, st containing the cell arrays, str that contain the region.locations that you want to concatentate to make plots and autocorr and xcorr with the motorSignal
%Output:
%region - will print correlation results to command line. Return region data structure with corr data at region.userdata.spatialMLCorr. Will also display corr plots with activeFraction traces.
%
% See also wholeBrain_activeFraction.m, batchFetchCorrData, wholeBrain_corrData, wholeBrainActivityMapFig, wholeBrain_actvFractionMotorPlot
%
%James B. Ackman, 2013-11-15 16:19:06

%Cortical Spatial Center of Mass corr between hemispheres

%Check for data structure inputs:
if isfield(region,'locationData')
	data = region.locationData.data; 
else
	error('region.locationData not found')
end

%Setup defaults: 
if nargin < 3 || isempty(names)
	names = {region.locationData.data.name};
end

if isfield(region,'userdata') & isfield(region.userdata,'spatialMLCorr')
	datasetSelector = length(region.userdata.spatialMLCorr) + 1;
	datasetSelector = length(region.userdata.spatialAPCorr) + 1;
else	
	datasetSelector = 1;
end	

region.userdata.spatialMLCorr{datasetSelector}.pvalCorrMatrix = zeros(length(names),length(names));  
region.userdata.spatialMLCorr{datasetSelector}.rvalCorrMatrix = zeros(length(names),length(names));   
region.userdata.spatialMLCorr{datasetSelector}.names = names;

region.userdata.spatialAPCorr{datasetSelector}.pvalCorrMatrix = zeros(length(names),length(names));  
region.userdata.spatialAPCorr{datasetSelector}.rvalCorrMatrix = zeros(length(names),length(names));   
region.userdata.spatialAPCorr{datasetSelector}.names = names;


i = (1:length(names))';
j = ones(length(names),1);
region.userdata.spatialMLCorr{datasetSelector}.corr_pairs{1} = [i j];  

[r,p]=corrcoef(decY2,decY2);
region.userdata.spatialMLCorr{datasetSelector}.pvalCorrMatrix(1,1) = p(2,1);
region.userdata.spatialMLCorr{datasetSelector}.rvalCorrMatrix(1,1) = r(2,1);

%Make the plots:
strcmp({data.name},'cortex.L')
for j = 1:numel(st)  
    str = st(j).str; 

	figure;   
	y1 = data(1).meanActivePixelLocaNormML;  
	y2 = data(2).meanActivePixelLocaNormML;  
	ax(1) = subplot(2,1,1);  
	plot(y1(~isnan(y1)&~isnan(y2)),'-'); xlabel('frame no.'); ylabel('Norm ML dist');   
	hold all  
	plot(y2(~isnan(y1)&~isnan(y2)),'-'); xlabel('frame no.'); ylabel('Norm ML dist');   
	legend({data(1).name data(2).name})  
	disp('===xy pearson corr coef===')    
	[r,p]=corrcoef(y1(~isnan(y1)&~isnan(y2)),y2(~isnan(y1)&~isnan(y2)))  
	disp(['p(2,1) = ' num2str(p(2,1))])  

	ax(2) = subplot(2,1,2);  
	y1 = data(1).meanActivePixelLocaNormAP;  
	y2 = data(2).meanActivePixelLocaNormAP;  
	plot(y1(~isnan(y1)&~isnan(y2)),'-'); xlabel('frame no.'); ylabel('Norm AP dist');   
	hold all  
	plot(y2(~isnan(y1)&~isnan(y2)),'-'); xlabel('frame no.'); ylabel('Norm AP dist');   
	linkaxes(ax,'x')  
	zoom xon  
	legend({data(1).name data(2).name})  
	disp('===xy pearson corr coef===')    
	[r,p]=corrcoef(y1(~isnan(y1)&~isnan(y2)),y2(~isnan(y1)&~isnan(y2)))  
	disp(['p(2,1) = ' num2str(p(2,1))]) 


end
