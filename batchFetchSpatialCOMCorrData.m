function batchFetchSpatialCOMCorrData(filelist,region, datafilename, datasetSelector)
%batchFetchSpatialCOMCorrData - A wrapper and output generator for getting information on active pixel fraction per location during the movie, after 'locationData' data structure has been returned and saved into 'region' from wholeBrain_activeFraction.m
%Examples:
% >> batchFetchSpatialCOMCorrData(filelist);
% >> batchFetchSpatialCOMCorrData({filename},region);
% >> batchFetchSpatialCOMCorrData({filename},region,'dMotorCorr.txt');
%
%**USE**
%Must provide one input:
%
%(1) table with desired filenames (space delimited txt file, with full filenames in first column)
%files.txt should have matlab filenames in first column.
%can have an extra columns with descriptor/factor information for the file. This will be the rowinfo that is attached to each measure observation in the following script.
%filelist = readtext('files.txt',' '); %grab readtext.m file script from matlab central
%or
%(2) a single filename (filename of your region .mat file) as a cell array, i.e.  {filename}
%
%Options:
%filelist={filename}; % cell array of strings, can pass just a single filename and a single already loaded region structure, if only getting values for a single file.
%region - datastructure, if you just want to do a single file loaded into workspace
%datafilename - string, append data to prexisting table with filename 'datafilename'
%datasetSelector - integer, %if there is more than one corr_pairs dataset, this will select which one to use
%
%Output:
%Right now this function will automatically write to a space-delimited txt file outputs, a 'region.location/active period type' based dataset 'dLocationProps.txt'
%And these outputs will be appended if the file already exists.
%Data values
% filename - raw data .tif filename if provided in filelist
% matlab_filename - filename for the currently analysed .mat matlab region data structure
% node1 and node2 are the pair names
% rvalue - pearson's correlation coefficient value
% pvalue - pvalue returned along with the pvalue from corrcoef()
% dist_px - euclidean distance in pixels of the distance between the centroids for the two node locations
%
% See also batchFetchCorrPairs.m, batchFetchCorrProps.m, batchFetchLocationProps.m, batchFetchDomainProps.m, wholeBrain_getActiveFractionPeriods.m, wholeBrain_activeFraction.m, batchFetchStimResponseProps, batchFetchCalciumEventProps.m
%
%James B. Ackman, 2013-11-13 22:36:55

if nargin< 4 || isempty(datasetSelector), datasetSelector = 1; end   %if there is more than one corr_pairs dataset, this will select which one to use
if nargin< 3 || isempty(datafilename), 
	datafilename = 'dCorticalCorr.txt';
	matlabUserPath = userpath;  
	matlabUserPath = matlabUserPath(1:end-1);  
	datafilename = fullfile(matlabUserPath,datafilename);
else
	[pathstr, name, ext] = fileparts(datafilename);   %test whether a fullfile path was specified	
	if isempty(pathstr)  %if one was not specified, save the output datafilename into the users matlab home startup directory
		matlabUserPath = userpath;  
		matlabUserPath = matlabUserPath(1:end-1);  
		datafilename = fullfile(matlabUserPath,datafilename);		
	end
end
if nargin< 2 || isempty(region); region = []; end

%---**functionHandles.workers and functionHandles.main must be valid functions in this program or in matlabpath to provide an array of function_handles
functionHandles.workers = {@filename @matlab_filename @CorrType @node1 @node2 @rvalue @pvalue};
functionHandles.main = @wholeBrain_getCorrStats;
%tableHeaders = {'filename' 'matlab.filename' 'region.name' 'roi.number' 'nrois' 'roi.height.px' 'roi.width.px' 'xloca.px' 'yloca.px' 'xloca.norm' 'yloca.norm' 'freq.hz' 'intvls.s' 'onsets.s' 'durs.s' 'ampl.df'};
%filename %roi no. %region.name %roi size %normalized xloca %normalized yloca %region.stimuli{numStim}.description %normalized responseFreq %absolutefiringFreq(dFreq) %meanLatency %meanAmpl %meanDur

tableHeaders = cellfun(@func2str, functionHandles.workers, 'UniformOutput', false);
%---Generic opening function---------------------
setupHeaders = exist(datafilename,'file');
if setupHeaders < 1
	%write headers to file----
	fid = fopen(datafilename,'a');
	appendCellArray2file(datafilename,tableHeaders,fid)
else
	fid = fopen(datafilename,'a');
end

%---Generic main function loop-------------------
%Provide valid function handle
mainfcnLoop(filelist, region, datafilename, functionHandles, datasetSelector, fid)


function mainfcnLoop(filelist, region, datafilename, functionHandles, datasetSelector, fid, useStimuli, stimuliIndices)
%start loop through files-----------------------------------------------------------------

if nargin < 5 || isempty(datasetSelector), datasetSelector=[]; end
if nargin < 7 || isempty(useStimuli), useStimuli=[]; end
if nargin < 8 || isempty(stimuliIndices), stimuliIndices=[]; end

if nargin< 2 || isempty(region); 
    region = []; loadfile = 1; 
else
    loadfile = 0;
end

fnms = filelist(:,1);

if size(filelist,1) > 1 && size(filelist,2) > 1
	fnms2 = filelist(:,2);
end

for j=1:numel(fnms)
    if loadfile > 0
        matfile=load(fnms{j});
        region=matfile.region;
    end
    
    if ~isfield(region,'filename')    
		if size(filelist,2) > 1 && ~isfield(region,'filename')
			[pathstr, name, ext] = fileparts(fnms2{j});
			region.filename = [name ext];  %2012-02-07 jba
		else
			region.filename = ['.tif'];
		end
    end
	[pathstr, name, ext] = fileparts(fnms{j});
	region.matfilename = [name ext];  %2012-02-07 jba    
	
%	rowinfo = [name1 name2];  %cat cell array of strings
%	rowinfo = filelist(j,:);
    sprintf(fnms{j})    

    disp('--------------------------------------------------------------------')
	%myEventProps(region,rowinfo);
	functionHandles.main(region, functionHandles.workers, datafilename, datasetSelector, fid, useStimuli, stimuliIndices)
	if ismac | ispc
		h = waitbar(j/numel(fnms));
	else
		disp([num2str(j) '/' num2str(numel(fnms))])		
    end
end
%data=results;
if ismac | ispc
	close(h)
end


function output = wholeBrain_getCorrStats(region, functionHandles, datafilename, functionHandles, datasetSelector, fid, useStimuli, stimuliIndices)
varin.datafilename=datafilename;
varin.region=region;
varin.datasetSelector = datasetSelector;

varin.CorrType = 'spatialML';
[edgeData, names] = getEdgeDataML(varin);
varin.edgeData = edgeData;
varin.names = names;
%The following code will save a dataframe of this adjacency dataset:
for i = 1:size(edgeData,1)  %Plot the pairs in order based on their sorted edgeAesthetic and color their connections with the colormap  
	varin.idx = i;
	printStats(functionHandles, varin, fid)
end 

varin.CorrType = 'spatialAP';
[edgeData, names] = getEdgeDataAP(varin);
varin.edgeData = edgeData;
varin.names = names;
%The following code will save a dataframe of this adjacency dataset:
for i = 1:size(edgeData,1)  %Plot the pairs in order based on their sorted edgeAesthetic and color their connections with the colormap  
	varin.idx = i;
	printStats(functionHandles, varin, fid)
end


function out = filename(varin) 
%movie .tif filename descriptor string
out = varin.region.filename;


function out = matlab_filename(varin)
%analysed .mat file descriptor string
out = varin.region.matfilename;

function output = CorrType(varin)
output = varin.CorrType;

function out = node1(varin)
name1 = varin.names{varin.edgeData(varin.idx,1)};  
out = name1;


function out = node2(varin)
name2 = varin.names{varin.edgeData(varin.idx,2)};
out = name2;


function out = rvalue(varin)
out = varin.edgeData(varin.idx,3);


function out = pvalue(varin)
out = varin.edgeData(varin.idx,4);


function out = dist_px(varin)
out = varin.edgeData(varin.idx,5); 


function [edgeData, names] = getEdgeDataML(varin)
region = varin.region;
datasetSelector = varin.datasetSelector;
data = region.userdata.spatialMLCorr{datasetSelector}.corr_pairs{1};

%--setup roi height width ratio--------------
%The following is important for getting the distances right if the data pixel dimensions are not equivalent
%And below the scripts will assume wherever 'rXY' is used, that it is szX (m dimension) which must be scaled up.
%the following assumes that the modulus of raster scanned data is 0 (equally divisible image size) and that for CCD images the ratio of image dimensions is either equivalent or not equally divisible
%-- end setup roi height width ratio---------
%--START loop to get edgeData----------------
edgeList=[];
pvalues = [];
rvalues = [];
names = region.userdata.spatialMLCorr{datasetSelector}.names;
% i = 1;
for i = 1:size(data,1)
	name1 = names{data(i,1)};
	name2 = names{data(i,2)};

	edgeList = [edgeList; data(i,:)];	
	if isfield(region.userdata.spatialMLCorr{datasetSelector},'pvalCorrMatrix')
		output1 = getPvalues(i,data,region.userdata.spatialMLCorr{datasetSelector});
		output2 = getRvalues(i,data,region.userdata.spatialMLCorr{datasetSelector});
		pvalues = [pvalues; output1];
		rvalues = [rvalues; output2];
	else
		error('pvalCorrMatrix not found')		
	end
	%             end
end
edgeData = [edgeList rvalues pvalues];
edgeData = sortrows(edgeData,3);   %sort the Nx5 list of pairs on lowest to highest rvalue
%--END loop to get edgeData----------------


function [edgeData, names] = getEdgeDataAP(varin)
region = varin.region;
datasetSelector = varin.datasetSelector;
data = region.userdata.spatialAPCorr{datasetSelector}.corr_pairs{1};

%--setup roi height width ratio--------------
%The following is important for getting the distances right if the data pixel dimensions are not equivalent
%And below the scripts will assume wherever 'rXY' is used, that it is szX (m dimension) which must be scaled up.
%the following assumes that the modulus of raster scanned data is 0 (equally divisible image size) and that for CCD images the ratio of image dimensions is either equivalent or not equally divisible
%-- end setup roi height width ratio---------
%--START loop to get edgeData----------------
edgeList=[];
pvalues = [];
rvalues = [];
names = region.userdata.spatialAPCorr{datasetSelector}.names;
% i = 1;
for i = 1:size(data,1)
	name1 = names{data(i,1)};
	name2 = names{data(i,2)};

	edgeList = [edgeList; data(i,:)];	
	if isfield(region.userdata.spatialAPCorr{datasetSelector},'pvalCorrMatrix')
		output1 = getPvalues(i,data,region.userdata.spatialAPCorr{datasetSelector});
		output2 = getRvalues(i,data,region.userdata.spatialAPCorr{datasetSelector});
		pvalues = [pvalues; output1];
		rvalues = [rvalues; output2];
	else
		error('pvalCorrMatrix not found')		
	end
	%             end
end
edgeData = [edgeList rvalues pvalues];
edgeData = sortrows(edgeData,3);   %sort the Nx5 list of pairs on lowest to highest rvalue
%--END loop to get edgeData----------------


function output = getPvalues(pairNum,data,input)
i = data(pairNum,1);
j = data(pairNum,2);
output = input.pvalCorrMatrix(i,j);


function output = getRvalues(pairNum,data,input)
i = data(pairNum,1);
j = data(pairNum,2);
output = input.rvalCorrMatrix(i,j);
