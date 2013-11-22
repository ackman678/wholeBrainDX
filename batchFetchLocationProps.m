function batchFetchLocationProps(filelist,region, datafilename, useStimuli, stimuliIndices)
%batchFetchLocationProps - A wrapper and output generator for getting information on active pixel fraction per location during the movie, after 'locationData' data structure has been returned and saved into 'region' from wholeBrain_activeFraction.m
%Examples:
% >> batchFetchLocationProps(filelist);
% >> batchFetchLocationProps({filename},region);
% >> batchFetchLocationProps(filelist,[],[], 'true', {'motor.state.active' 'motor.state.quiet'});
% >> batchFetchLocationProps({fnm},region,[], 'true', {'motor.state.active' 'motor.state.quiet' 'drug.state.control' 'drug.state.isoflurane'});
% >> batchFetchLocationProps({filename},region,'dLocationProps.txt', 'true', [2 3]);
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
	datafilename = 'dLocationProps.txt';
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
functionHandles.workers = {@filename @matlab_filename @region_name @actvFraction @maxFraction @minFraction @meanFraction @sdFraction @meanActvFraction @sdActvFraction @actvFrames @actvTimeFraction @nonActvFrames @nonActvTimeFraction @stimulusDesc @nstimuli @stimOn @stimOff @nMaskPixels @nPixelsActiveTotal @nPixelsActive @nPixelsActivePerSec};
functionHandles.main = @wholeBrain_getActiveFractionStats;
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
%start loop through files-----------------------------------------------------------------

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

	if strcmp(useStimuli,'true') & isempty(stimuliIndices) & isfield(region,'stimuli'); 
		stimuliIndices=1:numel(region.stimuli);
	elseif strcmp(useStimuli,'true') & iscellstr(stimuliIndices) & isfield(region,'stimuli')  %if the input is a cellarray of strings
			ind = [];
			for i = 1:length(region.stimuli)
				for k = 1:length(stimuliIndices)
					if strcmp(region.stimuli{i}.description,stimuliIndices{k})
						ind = [ind i];
					end
				end
			end
			stimuliIndices = ind; %assign indices 
	elseif strcmp(useStimuli,'true') & isnumeric(stimuliIndices) & isfield(region,'stimuli')
		return
	elseif ~isfield(region,'stimuli') || strcmp(useStimuli,'false')
		stimuliIndices = [];
	else
		error('Bad input to useStimuli, stimuliIndices, or region.stimuli missing')
	end
	
%	rowinfo = [name1 name2];  %cat cell array of strings
%	rowinfo = filelist(j,:);
    sprintf(fnms{j})    

    disp('--------------------------------------------------------------------')
	%myEventProps(region,rowinfo);
	functionHandles.main(region, functionHandles.workers, datafilename, stimuliIndices)
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


%-----------------------------------------------------------------------------------------
%dataFunctionHandle
function output = wholeBrain_getActiveFractionStats(region, functionHandles, datafilename, stimuliIndices)
%script to fetch the active and non-active pixel fraction period durations
%for all data and all locations
%2013-04-09 11:35:04 James B. Ackman
%Want this script to be flexible to fetch data for any number of location Markers as well as duration distributions for both non-active and active periods.  
%Should get an extra location signal too-- for combined locations/hemisphere periods.
%2013-04-11 18:00:23  Added under the batchFetchLocation generalized wrapper table functions

locationMarkers = unique(region.location);
varin.datafilename=datafilename;
varin.region=region;

if ~isempty(stimuliIndices)
	%SignalMatrix = zeros(length(locationMarkers),size(region.locationData.data(1).activeFractionByFrame,2));  %for making a combined actvFraction location signal
	for locationIndex = 1:length(locationMarkers)
		locationName = region.locationData.data(locationIndex).name;
		%START For loop here by stimulus.stimuliParams-------------------------------
		for numStim = stimuliIndices
			for nstimuli=1:numel(region.stimuli{numStim}.stimulusParams)
				varin.nstimuli = nstimuli;
				varin.stimulusdesc = region.stimuli{numStim}.description;
				varin.on = region.stimuli{numStim}.stimulusParams{nstimuli}.frame_indices(1);
				varin.off = region.stimuli{numStim}.stimulusParams{nstimuli}.frame_indices(end);
				varin.locationName=locationName;
				varin.locationIndex=locationIndex;
				printStats(functionHandles, varin) 
			end
		end
		%END For loop here by stimulus.stimuliParams-------------------------------
	%    SignalMatrix(locationIndex,:) = rawSignal; %for making a combined actvFraction location signal
	end
else
	for locationIndex = 1:length(locationMarkers)
		locationName = region.locationData.data(locationIndex).name;
		varin.nstimuli = '';
		varin.stimulusdesc = '';
		varin.on = 1;
		varin.off = numel(region.locationData.data(locationIndex).nPixelsByFrame);
		varin.locationName=locationName;
		varin.locationIndex=locationIndex;
		printStats(functionHandles, varin) 
	end
end
%{
%---START---use the combined actvFraction location signal----   
%2013-04-15 11:38:21 removed-- if new amalgam locations need to be added, then this should be separate from this script. Can do in data = wholeBrain_activeFraction.m if wanted. But the mean values for actvFraction and stats, when looped through many id. regions will be similar to the whole brain values anyways. By hemisphere is sufficient for now. 
locationName = 'all';
CombinedSignal = max(SignalMatrix,[],1);  %combine active periods to find combined active and non-active durations
actvFrac = sum(vertcat(region.locationData.data(:).activeFraction),1)/locationIndex;  %combine active fractions to calc combined stats 
actvFracFrame = sum(vertcat(region.locationData.data(:).activeFraction),1)/locationIndex;
region.locationData.data(locationIndex+1).activeFraction = actvFrac;
region.locationData.data(locationIndex+1).activeFractionByFrame = actvFracFrame;

pulseSignal = makeActivePulseSignal(CombinedSignal);
plotTitles{1} = ['active fraction by frame for ' locationName]; plotTitles{2} = 'active periods to positive pulse'; plotTitles{3} = 'derivative of active pulse';
[onsets, offsets] = getPulseOnsetsOffsets(CombinedSignal,pulseSignal,plotTitles,locationName);
varin.onsets=onsets;
varin.offsets=offsets;
varin.locationName=locationName;
varin.region=region;
varin.periodType='active';
varin.locationIndex=locationIndex+1;
printStats(functionHandles, varin)

pulseSignal = makeNonActivePulseSignal(CombinedSignal);
plotTitles{1} = ['active fraction by frame for ' locationName]; plotTitles{2} = 'Non-active periods to positive pulse'; plotTitles{3} = 'derivative of non-active pulse';
[onsets, offsets] = getPulseOnsetsOffsets(CombinedSignal,pulseSignal,plotTitles,locationName);
varin.onsets=onsets;
varin.offsets=offsets;
varin.periodType='non.active';
printStats(functionHandles, varin)
%---END---use the combined actvFraction location signal----
%}


function stats = printStats(functionHandles, varin)
output=cellfun(@(x)x(varin), functionHandles, 'UniformOutput', false); %cellfun example using a generic function  @x applied to the function cell array so that varin can be passed to each function
appendCellArray2file(varin.datafilename,output)
%functionHandles.workers = {@region_name @actvPeriodType ...
%@actvFraction @maxFraction @minFraction @meanFraction @sdFraction @meanActvFraction @sdActvFraction @actvFrames @actvTimeFraction @nonActvFrames @nonActvTimeFraction ...
%@maxDuration_s @minDuration_s @medianDuration_s @meanDuration_s @sdDuration_s @sumDuration_s};

%do for loop through functionHandles or cellfun
%S = cellfun(@str2func, {'sin' 'cos' 'tan'}, 'UniformOutput', false);  %cellfun example
%cellfun(@(x)x(2), S, 'UniformOutput', false) %cellfun example



function out = filename(varin) 
%movie .tif filename descriptor string
out = varin.region.filename;


function out = matlab_filename(varin)
%analysed .mat file descriptor string
out = varin.region.matfilename;


%------------active fraction stats functions---------------------
function out = region_name(varin)
%location name descriptor string
out = varin.locationName;


function out = actvPeriodType(varin)  
%active period type descriptor string
out = varin.periodType;


function out = actvFraction(varin)  
%fraction of all pixels active by location for one recording
data = varin.region.locationData.data;
out = data(varin.locationIndex).activeFraction;


function out = stimulusDesc(varin)
data = varin.region.locationData.data;
out = varin.stimulusdesc;


function out = nstimuli(varin)
data = varin.region.locationData.data;
out = varin.nstimuli;


function out = stimOn(varin) 
data = varin.region.locationData.data;
out = varin.on;


function out = stimOff(varin)
data = varin.region.locationData.data;
out = varin.off;


function out = nMaskPixels(varin)
data = varin.region.locationData.data;
out = data(varin.locationIndex).nPixels;


function out = nPixelsActiveTotal(varin)
data = varin.region.locationData.data;
out = sum(data(varin.locationIndex).nPixelsByFrame);


function out = nPixelsActive(varin)
data = varin.region.locationData.data;
out = sum(data(varin.locationIndex).nPixelsByFrame(varin.on:varin.off));


function out = nPixelsActivePerSec(varin)
data = varin.region.locationData.data;
out = sum(data(varin.locationIndex).nPixelsByFrame(varin.on:varin.off)) / (numel(varin.on:varin.off)*varin.region.timeres);


function out = maxFraction(varin)  
%maximum fraction of all pixels active at one time (default is by frame, TODO: change/add in future by binned time?)
data = varin.region.locationData.data;
out = max(data(varin.locationIndex).activeFractionByFrame);


function out = minFraction(varin)  
%minimum fraction of all pixels active at one time
data = varin.region.locationData.data;
out = min(data(varin.locationIndex).activeFractionByFrame);


function out = meanFraction(varin)
%mean active pixel fraction across *all* frames
data = varin.region.locationData.data;
out = mean(data(varin.locationIndex).activeFractionByFrame);


function out = sdFraction(varin)
%standard deviation active pixel fraction across *all* frames
data = varin.region.locationData.data;
out = std(data(varin.locationIndex).activeFractionByFrame);


function out = meanActvFraction(varin)
%mean pixel fraction across all the *active* frames
data = varin.region.locationData.data;
actvFramesIdx = find(data(varin.locationIndex).activeFractionByFrame);
out = mean(data(varin.locationIndex).activeFractionByFrame(actvFramesIdx));


function out = sdActvFraction(varin)
%standard deviation pixel fraction across all the *active* frames
data = varin.region.locationData.data;
actvFramesIdx = find(data(varin.locationIndex).activeFractionByFrame);
out = std(data(varin.locationIndex).activeFractionByFrame(actvFramesIdx));


function out = actvFrames(varin)
%number of active frames
data = varin.region.locationData.data;
out = numel(find(data(varin.locationIndex).activeFractionByFrame));


function out = actvTimeFraction(varin)
%fraction of total movie time the location is active
data = varin.region.locationData.data;
out = actvFrames(varin)/length(data(varin.locationIndex).activeFractionByFrame);


function out = nonActvFrames(varin)
%number of non-active frames
data = varin.region.locationData.data;
out = length(data(varin.locationIndex).activeFractionByFrame) - actvFrames(varin);


function out = nonActvTimeFraction(varin)
%fraction of total movie time the location is non-active
data = varin.region.locationData.data;
out = nonActvFrames(varin)/length(data(varin.locationIndex).activeFractionByFrame);


%------------actvPeriod duration stats functions---------------------
function out = maxDuration_s(varin)
out = max((varin.offsets-varin.onsets).*varin.region.timeres);


function out = minDuration_s(varin)
out = min((varin.offsets-varin.onsets).*varin.region.timeres);


function out = medianDuration_s(varin)
out = median((varin.offsets-varin.onsets).*varin.region.timeres);


function out = meanDuration_s(varin)
out = mean((varin.offsets-varin.onsets).*varin.region.timeres);


function out = sdDuration_s(varin)
out = std((varin.offsets-varin.onsets).*varin.region.timeres);


function out = sumDuration_s(varin)
out = sum((varin.offsets-varin.onsets).*varin.region.timeres);



%------------Find active period functions---------------
function pulseSignal = makeActivePulseSignal(rawSignal)
pulseSignal = rawSignal;
pulseSignal(rawSignal>0) = 1;


function pulseSignal = makeNonActivePulseSignal(rawSignal)
pulseSignal = rawSignal;
pulseSignal(rawSignal>0) = -1;
pulseSignal(pulseSignal>-1) = 1;
pulseSignal(pulseSignal<1) = 0;


function [wvonsets, wvoffsets] = getPulseOnsetsOffsets(rawSignal,pulseSignal,plotTitles,locationName,makePlots)
if nargin < 5 || isempty(makePlots), makePlots = 0; end
if nargin < 4 || isempty(locationName), locationName = 'unknown location'; end
if nargin < 3 || isempty(plotTitles), plotTitles{1} = ['active fraction by frame for ' locationName]; plotTitles{2} = 'active periods to positive pulse'; plotTitles{3} = 'derivative of active pulse'; end

x = pulseSignal;
sig = rawSignal;
%ax = axesHandles;
dx = diff(x);
dx2 = [dx 0];  %because diff makes the vector one data point shorter.

if makePlots > 0
	figure, 
	ax(1)=subplot(3,1,1);
	plot(sig); title(plotTitles{1})

	ax(2)=subplot(3,1,2);
	plot(x); title(plotTitles{2})		

	ax(3)=subplot(3,1,3);
	plot(dx2); title(plotTitles{3})		
	linkaxes(ax,'x')
	zoom xon
end
wvonsets = find(dx > 0);
wvoffsets = find(dx < 0);

%figure out if an offset was at last frame of movie (no. of onsets and offsets not equal)
if wvonsets(1) > wvoffsets(1)
   wvonsets = [1 wvonsets];
end

if wvoffsets(end) < wvonsets(end)
   wvoffsets = [wvoffsets size(sig,2)];
end

if makePlots > 0 
	axes(ax(1))
	hold on
	plot(wvonsets,sig(wvonsets),'og');
	plot(wvoffsets,sig(wvoffsets),'or');

	axes(ax(2))
	hold on
	plot(wvonsets,x(wvonsets),'og');
	plot(wvoffsets,x(wvoffsets),'or');

	axes(ax(3))
	hold on
	plot(wvonsets,dx2(wvonsets),'og');
	plot(wvoffsets,dx2(wvoffsets),'or');
end
