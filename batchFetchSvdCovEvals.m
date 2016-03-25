function batchFetchSvdCovEvals(infile, datafilename)
%batchFetchSvdCovEvals - A wrapper and output generator for getting information on principal component values from wholeBrain SVD
%Examples:
% >> batchFetchSvdCovEvals(filename);
% >> batchFetchSvdCovEvals({filename});
% >> batchFetchSvdCovEvals({filename},'dCovEvals.txt');
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
%This function will automatically write to a space-delimited txt file.
%And these outputs will be appended if the file already exists.
%
% See also wholeBrainSVD.m, batchFetchDomainProps.m
%
%James B. Ackman, 2014-06-19 14:07:16

%-----------------------------------------------------------------------------------------
%- Set up options and default parameters
%-----------------------------------------------------------------------------------------


filelist = readtext(infile,' ');

if nargin< 2 || isempty(datafilename), 
	datafilename = 'dCovEvals.txt';
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

%---**functionHandles.workers and functionHandles.main must be valid functions in this program or in matlabpath to provide an array of function_handles
functionHandles.workers = {@filename @matlab_filename @PercentVar @nPCs @nBadPCs};
functionHandles.main = @wholeBrain_getStats;
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
mainfcnLoop(filelist, datafilename, functionHandles, fid)
fclose(fid);


function mainfcnLoop(filelist, datafilename, functionHandles, fid)
%start loop through files-----------------------------------------------------------------
fnms = filelist(:,1);
fnms2 = filelist(:,2);

for j=1:numel(fnms2)

	load(fnms2{j},'CovEvals','covtrace','badPCs')
	[pathstr, name, ext] = fileparts(fnms2{j});
	region.pcafilename = [name ext];
	region.filename = fnms{j};

	percentvar = 100*sum(CovEvals)/covtrace;
	npcs = numel(CovEvals);
	nbadpcs = numel(badPCs);
	region.percentvar = percentvar;
	region.npcs = npcs;
	region.nbadpcs = nbadpcs;
	clear CovEvals 

    sprintf(fnms{j})    

    disp('--------------------------------------------------------------------')
	functionHandles.main(region, functionHandles.workers, datafilename, fid)
	if ismac | ispc
		h = waitbar(j/numel(fnms));
	else
		disp([num2str(j) '/' num2str(numel(fnms))])		
    end
end

if ismac | ispc
	close(h)
end




%-----------------------------------------------------------------------------------------
%dataFunctionHandle
function output = wholeBrain_getStats(region, functionHandles, datafilename, fid)
varin.datafilename=datafilename;
varin.region=region;
printStats(functionHandles, varin, fid)


function out = filename(varin) 
%movie .tif filename descriptor string
out = varin.region.filename;

function out = matlab_filename(varin)
%analysed .mat file descriptor string
out = varin.region.pcafilename;

function out = PercentVar(varin)
%location name descriptor string
out = varin.region.percentvar;

function out = nPCs(varin)
%location name descriptor string
out = varin.region.npcs;

function out = nBadPCs(varin)
%location name descriptor string
out = varin.region.nbadpcs;
