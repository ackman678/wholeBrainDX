function region = wholeBrain_SpatialCOMCorr(fnm,region,names,makePlots)
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
if nargin < 4 || isempty(makePlots), makePlots = 0; end

if nargin < 3 || isempty(names)
	names = {region.locationData.data.name};
end

if isfield(region,'userdata') & isfield(region.userdata,'spatialMLCorr')
	datasetSelector = length(region.userdata.spatialMLCorr) + 1;
else	
	datasetSelector = 1;
end	

region.userdata.spatialMLCorr{datasetSelector}.pvalCorrMatrix = zeros(length(names),length(names));  
region.userdata.spatialMLCorr{datasetSelector}.rvalCorrMatrix = zeros(length(names),length(names));   
region.userdata.spatialMLCorr{datasetSelector}.names = names;

region.userdata.spatialAPCorr{datasetSelector}.pvalCorrMatrix = zeros(length(names),length(names));  
region.userdata.spatialAPCorr{datasetSelector}.rvalCorrMatrix = zeros(length(names),length(names));   
region.userdata.spatialAPCorr{datasetSelector}.names = names;

%Make the plots:
for i = 1:length(names)

	if sum(strcmp({data.name},names{i})) > 0
		y1 = data(strcmp({data.name},names{i})).meanActivePixelLocaNormML;  
		y3 = data(strcmp({data.name},names{i})).meanActivePixelLocaNormAP;
    else
		continue
    end
    
	for j = 1:length(names)	
		if sum(strcmp({data.name},names{j})) > 0
			y2 = data(strcmp({data.name},names{j})).meanActivePixelLocaNormML;  
			y4 = data(strcmp({data.name},names{j})).meanActivePixelLocaNormAP;
		else
			continue
		end	
		if makePlots
			figure;
			ax(1) = subplot(2,1,1);  
			plot(y1(~isnan(y1)&~isnan(y2)),'-'); xlabel('frame no.'); ylabel('Norm ML dist');   
			hold all  
			plot(y2(~isnan(y1)&~isnan(y2)),'-'); xlabel('frame no.'); ylabel('Norm ML dist');   
			legend({data(i).name data(j).name})  
		end
		disp(['===xy pearson corr coef spatialML ' names{i} ' x ' names{j} '==='])    
		tmp1 = y1(~isnan(y1)&~isnan(y2));
		tmp2 = y2(~isnan(y1)&~isnan(y2));
		disp(numel(tmp1))
		if numel(tmp1) > 1
			[r,p]=corrcoef(tmp1,tmp2)  
		else
			r = nan(2,2);
			p = nan(2,2);
		end
		disp(['p(2,1) = ' num2str(p(2,1))])  
		region.userdata.spatialMLCorr{datasetSelector}.pvalCorrMatrix(i,j) = p(2,1);
		region.userdata.spatialMLCorr{datasetSelector}.rvalCorrMatrix(i,j) = r(2,1);

		if makePlots
			ax(2) = subplot(2,1,2);    
			plot(y3(~isnan(y3)&~isnan(y4)),'-'); xlabel('frame no.'); ylabel('Norm AP dist');   
			hold all  
			plot(y4(~isnan(y3)&~isnan(y4)),'-'); xlabel('frame no.'); ylabel('Norm AP dist');   
			linkaxes(ax,'x')  
			zoom xon  
			legend({data(i).name data(j).name})
		end	  
		disp(['===xy pearson corr coef spatialAP ' names{i} ' x ' names{j} '==='])
		tmp1 = y3(~isnan(y3)&~isnan(y4));
		tmp2 = y4(~isnan(y3)&~isnan(y4));
		disp(numel(tmp1))
		if numel(tmp1) > 1
			[r,p]=corrcoef(tmp1,tmp2)  
		else
			r = nan(2,2);
			p = nan(2,2);
		end
		disp(['p(2,1) = ' num2str(p(2,1))]) 
		region.userdata.spatialAPCorr{datasetSelector}.pvalCorrMatrix(i,j) = p(1,2);
		region.userdata.spatialAPCorr{datasetSelector}.rvalCorrMatrix(i,j) = r(1,2);
	end
end

[i,j] = find(triu(region.userdata.spatialMLCorr{datasetSelector}.rvalCorrMatrix,1) ~= 0);  %this will take all pairs, no threshold for comparison  
region.userdata.spatialMLCorr{datasetSelector}.corr_pairs{1} = [i j];  

[i,j] = find(triu(region.userdata.spatialAPCorr{datasetSelector}.rvalCorrMatrix,1) ~= 0);  %this will take all pairs, no threshold for comparison  
region.userdata.spatialAPCorr{datasetSelector}.corr_pairs{1} = [i j];  
