function batchTest(filelist,region, datafilename, useStimuli, stimuliIndices)
% batchTest([],[],['dataTable_' datestr(now,'yyyymmdd-HHMMSS') '.txt'])
%batchFetchDomainProps - A wrapper and output generator for getting information on active pixel fraction per location during the movie, after 'locationData' data structure has been returned and saved into 'region' from wholeBrain_activeFraction.m
%Examples:
% >> batchFetchDomainProps(filelist);
% >> batchFetchDomainProps({filename},region);
% >> batchFetchDomainProps({filename},region,'dDomainProps.txt');
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
%useStimuli - string, 'true' | 'false'
%stimuliIndices - integer vector of stimulus indices or a cell array of strings of stimulus descriptions for selecting stimuli in your region.stimuli data structure
%
%Output:
%Right now this function will automatically write to a space-delimited txt file outputs, a 'region.location/active period type' based dataset 'dLocationProps.txt'
%And these outputs will be appended if the file already exists.
%
% See also wholeBrain_getActiveFractionPeriods.m, wholeBrain_activeFraction.m, batchFetchStimResponseProps, batchFetchCalciumEventProps.m
%
%James B. Ackman, 2013-04-11 12:17:14, updated 2013-11-13 10:08:46

%-----------------------------------------------------------------------------------------
%- Set up options and default parameters
%-----------------------------------------------------------------------------------------


if nargin< 5 || isempty(stimuliIndices); stimuliIndices = []; end 
if nargin< 4 || isempty(useStimuli); useStimuli = 'false'; end
if nargin< 3 || isempty(datafilename), 
	datafilename = 'dDomainProps.txt';
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
functionHandles.workers = {@filename @domainInd};
functionHandles.main = @wholeBrain_getDomainStats;
%tableHeaders = {'filename' 'matlab.filename' 'region.name' 'roi.number' 'nrois' 'roi.height.px' 'roi.width.px' 'xloca.px' 'yloca.px' 'xloca.norm' 'yloca.norm' 'freq.hz' 'intvls.s' 'onsets.s' 'durs.s' 'ampl.df'};
%filename %roi no. %region.name %roi size %normalized xloca %normalized yloca %region.stimuli{numStim}.description %normalized responseFreq %absolutefiringFreq(dFreq) %meanLatency %meanAmpl %meanDur

headers = cellfun(@func2str, functionHandles.workers, 'UniformOutput', false);
tableHeaders = headers;

%---Generic opening function---------------------
datafilename=setupDataTable(tableHeaders, datafilename);

%---Generic main function loop-------------------
%Provide valid function handle
mainfcnLoop(filelist, region, datafilename, functionHandles, useStimuli, stimuliIndices)




function datafilename=setupDataTable(tableHeaders, datafilename)
%---Generic table setup function---------------------
if nargin < 2 || isempty(datafilename), datafilename = ['dataTable_' datestr(now,'yyyymmdd-HHMMSS') '.txt']; end
if nargin < 1 || isempty(tableHeaders), error('Must provide tableHeaders cell array of strings'); end
%localpath_datafilename = ['./' datafilename];
%setupHeaders = exist(localpath_datafilename,'file');
setupHeaders = exist(datafilename,'file');
if setupHeaders < 1
	%write headers to file----
	appendCellArray2file(datafilename,tableHeaders)
end


function appendCellArray2file(filename,output)
%---Generic output function-------------
tmp=output;
fid = fopen(filename,'a');
for i=1:numel(tmp); tmp{i} = num2str(tmp{i}); end  %this will be to 4 decimal points (defaut for 'format short'). Can switch to 'format long' before running this loop if need more precision.
tmp2=tmp';
fprintf(fid,[repmat('%s\t',1,size(tmp2,1)-1),'%s\n'],tmp2{:});  %tab delimited
%fprintf(fid,[repmat('%s ',1,size(tmp2,1)-1),'%s\n'],tmp2{:});  %space delimited
fclose(fid);


function mainfcnLoop(filelist, region, datafilename, functionHandles, useStimuli, stimuliIndices)
functionHandles.main(region, functionHandles.workers, datafilename, stimuliIndices)


function output = wholeBrain_getDomainStats(region, functionHandles, datafilename, stimuliIndices)
varin.datafilename='140102_01.tif';
ObjectIndices = 1:10000;

for idx = ObjectIndices
	varin.idx = idx;
	printStats(functionHandles, varin) 	
end	


function stats = printStats(functionHandles, varin)
output=cellfun(@(x)x(varin), functionHandles, 'UniformOutput', false); %cellfun example using a generic function  @x applied to the function cell array so that varin can be passed to each function
appendCellArray2file(varin.datafilename,output)



function out = filename(varin) 
%movie .tif filename descriptor string
out = varin.datafilename;

function out = domainInd(varin)
%location name descriptor string
out = varin.idx;
