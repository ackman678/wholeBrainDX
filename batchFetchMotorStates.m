function batchFetchMotorStates(filelist,region, datafilename, stimuliIndices, makePlots)
%batchFetchMotorStates - A wrapper and output generator for getting information on active pixel fraction per location during the movie, after 'locationData' data structure has been returned and saved into 'region' from wholeBrain_activeFraction.m
%Examples:
% >> batchFetchMotorStates(filelist);
% >> batchFetchMotorStates({filename},region);
% >> batchFetchMotorStates(filelist,[],[],{'motor.onsets' 'motor.state.active' 'motor.state.quiet'});
% >> batchFetchMotorStates({fnm},region,[],{'motor.state.active' 'motor.state.quiet' 'sleep'});
% >> batchFetchMotorStates({filename},region,'dMotorStates.txt',[2 3]);
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
%stimuliIndices - integer vector of stimulus indices or a cell array of strings of stimulus descriptions for selecting stimuli in your region.stimuli data structure
%
%Output:
%Right now this function will automatically write to a space-delimited txt file outputs, a 'region.location/active period type' based dataset 'dLocationProps.txt'
%And these outputs will be appended if the file already exists.
%
% See also wholeBrain_motorSignal, mySpikeDetect, batchFetchStimResponseProps, batchFetchMotorStates, detectMotorStates, rateChannels, makeMotorStateStimParams, printStats
%
%James B. Ackman, 2016-03-24 15:24:50

%-----------------------------------------------------------------------------------------
%- Set up options and default parameters
%-----------------------------------------------------------------------------------------


if nargin< 5 || isempty(makePlots); makePlots = 0; end 
if nargin< 4 || isempty(stimuliIndices); stimuliIndices = []; end 
if nargin< 3 || isempty(datafilename), 
	datafilename = 'dMotorStates.txt';
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
functionHandles.workers = {@filename @matlab_filename @motorTimeFractionAll @stimulusDesc @motorTimeFraction @motorFreq_permin @nstimuli @stimOn @stimOff @Duration_s @Area_mVs @ISI_s};
functionHandles.main = @wholeBrain_getMovementStats;
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

fetchMotorStates(filelist,makePlots)

%---Generic main function loop-------------------
%Provide valid function handle
mainfcnLoop(filelist, region, datafilename, functionHandles, fid, stimuliIndices)
fclose(fid);





function fetchMotorStates(filelist,makePlots)
if nargin < 2 || isempty(makePlots), makePlots = 1; end
fnms = filelist(:,1); %assuming **first column** has your dummy files for this script...

for j=1:numel(fnms)
    load(fnms{j});  %load the dummy file at fnms{j} containing parcellations, motor signal, etc
    sprintf(fnms{j})    
    nframes = numel(region.motorSignal);

    if region.motorSignal(1) >= region.motorSignalGroupParams.groupRawThresh
        region.motorSignal(1) = region.motorSignalGroupParams.groupRawMedian;
    end

    if region.motorSignal(end) >= region.motorSignalGroupParams.groupRawThresh
        region.motorSignal(end) = region.motorSignalGroupParams.groupRawMedian;
    end

	[spks,~,~] = detectMotorOnsets(region, region.motorSignalGroupParams.nsd, region.motorSignalGroupParams.groupRawThresh, region.motorSignalGroupParams.groupDiffThresh, makePlots);
	region = makeStimParams(region, spks, 'motor.onsets', 1); 

	rateChan = rateChannels(region,[],makePlots,[],region.motorSignalGroupParams.rateChanMaxlagsAll(region.motorSignalGroupParams.rateChanNum));

    x = rateChan(1).y;
    xbar = region.motorSignalGroupParams.rateChanMean;
    x(x<xbar) = 0;
    dfY = [diff(x) 0];

    ons = find(dfY > xbar); ons = ons+1;
    offs = find(dfY < -xbar);
    if ~isempty(ons)
	    if ons(1) > offs(1)
	        offs = offs(2:end);
	    end
	end
	
	% disp(['num ons =' num2str(numel(ons))]) %TESTING
	% disp(['num offs =' num2str(numel(offs))]) %TESTING

	% if no. of onsets not equal to offsets, try removing the first offset (in case detected in beginning of movie)
    if numel(ons) ~= numel(offs)
        offs = [offs numel(x)];
    end

    % if no. of onsets are still not equal to offsets, try the next smoothened rateChan trace
    if numel(ons) ~= numel(offs)
        error('Number of onsets not equal to number of offsets')
    end

    idx1=[];
    idx2=[];
    for i=1:length(ons)
        %disp(ons(i))
        tf = ismember(spks,ons(i):offs(i));
        ind = find(tf);
        if isempty(ind)
            idx1 = [idx1 ons(i)];
            idx2 = [idx2 offs(i)];
        else
            idx1 = [idx1 spks(ind(1))];
            if ind(end) ~= ind(1)
                idx2 = [idx2 spks(ind(end))];
            else
                %idx2 = [idx2 spks(ind(end))+1];  %add max([val length(trace)]) algorithm
                idx2 = [idx2 offs(i)];
            end
        end
    end

	if makePlots
		hFig = figure;
	    scrsize = get(0,'screensize');
	    set(hFig,'Position',scrsize);
	    set(hFig,'color',[1 1 1]);
	    set(hFig,'PaperType','usletter');
	    set(hFig,'PaperPositionMode','auto');

	    thrN = region.motorSignalGroupParams.groupRawThresh;
	    nsd=region.motorSignalGroupParams.nsd;
	    
	    plot(region.motorSignal,'-'); ylabel('motor activity (V)'); title('bp/rect/dec/motor signal')    
	    xlabel('Time (image frame no.)');     
	    line([0 length(region.motorSignal)],[thrN thrN],'LineStyle','--','color','r');       
	    legend({'region.motorSignal' [num2str(nsd) 'sd mdn']})  
	    hold on  
		plot(idx1, region.motorSignal(idx1),'or')
		plot(idx2, region.motorSignal(idx2),'ok')
		zoom xon

		% fnm = fnms{j};
		% print(gcf,'-dpng',[fnm(1:end-4) 'motorSignal-cat' datestr(now,'yyyymmdd-HHMMSS') '.png'])            
		% print(gcf,'-depsc',[fnm(1:end-4) 'motorSignal-cat' datestr(now,'yyyymmdd-HHMMSS') '.eps']) 
	end

    region = makeMotorStateStimParams(region, idx1, idx2, 1);

    save(fnms{j},'region','-v7.3');  %load the dummy file at fnms{j} containing parcellations, motor signal, etc
end





function mainfcnLoop(filelist, region, datafilename, functionHandles, fid, stimuliIndices)
%start loop through files-----------------------------------------------------------------

if nargin < 6 || isempty(stimuliIndices), stimuliIndices=[]; end

if nargin< 2 || isempty(region); 
    region = []; loadfile = 1; 
else
    loadfile = 0;
end

fnms = filelist(:,1);  %assuming **first column** has your dummy files for this script...
fnms2 = filelist(:,2);  %assuming **second column** has your movie tif filenames for this script...

for j=1:numel(fnms)
    if loadfile > 0
        load(fnms{j},'region');
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
	
    sprintf(fnms{j})    

    disp('--------------------------------------------------------------------')
	functionHandles.main(region, functionHandles.workers, datafilename, fid, stimuliIndices)
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
function output = wholeBrain_getMovementStats(region, functionHandles, datafilename, fid, stimuliIndices)
%script to fetch the active and non-active pixel fraction period durations
%for all data and all locations
%2013-04-09 11:35:04 James B. Ackman
%Want this script to be flexible to fetch data for any number of location Markers as well as duration distributions for both non-active and active periods.  
%Should get an extra location signal too-- for combined locations/hemisphere periods.
%2013-04-11 18:00:23  Added under the batchFetchLocation generalized wrapper table functions

varin.datafilename=datafilename;
varin.region=region;

if isempty(stimuliIndices) & isfield(region,'stimuli'); 
	stimuliIndices=1:numel(region.stimuli);
elseif iscellstr(stimuliIndices) & isfield(region,'stimuli')  %if the input is a cellarray of strings
		ind = [];
		for i = 1:length(region.stimuli)
			for k = 1:length(stimuliIndices)
				if strcmp(region.stimuli{i}.description,stimuliIndices{k})
					ind = [ind i];
				end
			end
		end
		stimuliIndices = ind; %assign indices 
elseif isnumeric(stimuliIndices) & isfield(region,'stimuli')
	return
else
	error('Bad input to useStimuli, stimuliIndices, or region.stimuli missing')
end

%START loop here by stimulus.stimuliParams to make a stimulus period based dataset------------------------
for numStim = stimuliIndices
	varin.numStim = numStim;
	varin.stimulusdesc = region.stimuli{numStim}.description;
	% disp(varin.stimulusdesc) %TESTING
	for nstimuli=1:numel(region.stimuli{numStim}.stimulusParams)
		varin.nstimuli = nstimuli;
		varin.on = region.stimuli{numStim}.stimulusParams{nstimuli}.frame_indices(1);
		varin.off = region.stimuli{numStim}.stimulusParams{nstimuli}.frame_indices(end);
		printStats(functionHandles, varin, fid) 
	end
end
%END loop here by stimulus.stimuliParams-------------------------------




function out = filename(varin) 
%movie .tif filename descriptor string
out = varin.region.filename;


function out = matlab_filename(varin)
%analysed .mat file descriptor string
out = varin.region.matfilename;


function out = motorTimeFractionAll(varin)
%fraction of complete motor signal above threshold
idx = find(varin.region.motorSignal >= varin.region.motorSignalGroupParams.groupRawThresh);
out = numel(idx)/varin.region.nframes;


function out = stimulusDesc(varin)
%stimulus name
out = varin.stimulusdesc;


function out = motorTimeFraction(varin)
%fraction of motor signal above threshold for stimulus type
tf = false(1,varin.region.nframes);	
for i=1:numel(varin.region.stimuli{varin.numStim}.stimulusParams)
	t1 = varin.region.stimuli{varin.numStim}.stimulusParams{i}.frame_indices(1);
	t2 = varin.region.stimuli{varin.numStim}.stimulusParams{i}.frame_indices(end);
	tf(t1:t2) = 1; 
end
tmpSignal = varin.region.motorSignal;
tmpSignal(~tf) = 0;
idx = find(tmpSignal >= varin.region.motorSignalGroupParams.groupRawThresh);
out = numel(idx)/varin.region.nframes;


function out = motorFreq_permin(varin)
%overall stimulus frequency for movie, events per minute
out = (numel(varin.region.stimuli{varin.numStim}.stimulusParams) / (varin.region.nframes*varin.region.timeres)) * 60;


function out = nstimuli(varin)
%stimulus number
out = varin.nstimuli;


function out = stimOn(varin) 
%stimulus onset frame
out = varin.on;


function out = stimOff(varin)
%stimulus offset frame
out = varin.off;


function out = Duration_s(varin)
%duration of stimulus in seconds
out = (varin.off-varin.on+1).*varin.region.timeres;


function out = Area_mVs(varin)
%area under curve (mV*s). Multiplied by 1000 below to convert to mV (otherwise default values in volts too small)
% disp(varin.nstimuli) %TESTING
onset = varin.on;
offset = min([max([varin.on+1 varin.off]) varin.region.nframes]);
%out = trapz((onset:offset)*varin.region.timeres, varin.region.motorSignal(onset:offset) * 1000);
out = trapz((onset:offset)*varin.region.timeres, (varin.region.motorSignal(onset:offset) / varin.region.motorSignalGroupParams.groupRawMax)*1000);


function out = ISI_s(varin)
%stimulus onset ISI-------------------------------------------------------
len = numel(varin.region.stimuli{varin.numStim}.stimulusParams);
if varin.nstimuli+1 <= len
	out = (varin.region.stimuli{varin.numStim}.stimulusParams{varin.nstimuli+1}.frame_indices(1) - varin.on)*varin.region.timeres;
else
	out = NaN;
end
