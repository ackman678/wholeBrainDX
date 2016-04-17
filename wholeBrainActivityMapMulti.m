function results = wholeBrainActivityMapMulti(varargin)
%wholeBrainActivityMapFigMulti(region, frames, plotType, figType, stimuliToPlot)
% Fetches the normalized pixel activation frequency images or other maps for a series of wholeBrain movies and plots multi panel figure with same scale
% Examples
%	filelist = readtext('filesP3.txt',' ');    
%   filelist2 = readtext('filesP8.txt',' ');    
%	results = wholeBrainActivityMapMulti(filelist);
% 	results = wholeBrainActivityMapMulti(filelist, filelist2, 'domainDur');
% INPUTS
% filelist -- cell array of strings, full path names to the region domains2region, *d2r*.mat files. The default for a single filelist provided is to make a figure comparing one mapType image per file in filelist. If multiple filelists are provided (must be provided before the string for mapType) then the mean image for each filelist will be computed the number of plots compared in the figure will be equal to the number of filelists provided. **Currently no alignment or scaling is performed** so this will only work if all recordings in each filelist have the exact same coordinates and scale. 
% mapType -- string, switch to change summary map type.  'pixelFreq', 'domainFreq', 'domainDur', 'domainDiam', or 'domainAmpl'.

% James B. Ackman 2014-06-11 15:19:20

%======Setup parameters==============================
lenVarargin = length(varargin);
handles.mapType = 'domainFreq';

if lenVarargin < 1 || isempty(varargin{1}), 
    error('At least one filelist must be input...');
else
    f(1).filelist = varargin{1};
end

for i=2:lenVarargin
	if ~isstr(varargin{i}) & iscell(varargin{i})
		f(i).filelist = varargin{i};
	elseif isstr(varargin{i})
		handles.mapType = varargin{i};
	else
		error('Bad input')
	end
end

% Currently unused args 2014-06-12 08:05:14, to implement follow template in wholeBrainActivityMapFig.m 
% if nargin < 1 || isempty(filelist), error('filelist not input'); end
% if (nargin < 2 || isempty(frames)), frames = []; end
% if (nargin < 3 || isempty(plotType)), plotType = 2; end
% if (nargin < 4 || isempty(figType)), figType = 1; end
% if nargin < 5 || isempty(levels)
% 	levels = [];
% end
%
% if (nargin < 6 || isempty(stimuliToPlot)) && ~isempty(region.stimuli) && figType > 2, 
% 	stimuliToPlot=1:numel(region.stimuli); 
% end
%
% if nargin < 7 || isempty(handles)
% 	handles.figHandle = figure;
% 	handles.axesHandle = subplot(1,1,1);
% 	handles.clims = [];
% else
% 	if ~isfield(handles,'axesHandle')
% 		if isfield(handles,'axes1')
% 			handles.axesHandle = handles.axes1;
% 		else
% 			error('handles.axes1 not found')
% 		end
% 	end
% 	if ~isfield(handles,'figHandle')
% 		axes(handles.axesHandle);
% 		handles.figHandle = gcf;
% 	end	
% 	if ~isfield(handles,'clims')
% 		handles.clims = [];
% 	end
% end
% if nargin < 8 || isempty(mapType), mapType = 'domainFreq'; end

if numel(f) == 1
	results = getMap(f(1).filelist, handles);
	handles.clims = [0 max(vertcat(results.maxSig))];  %calculate max clim value for all plots
	plotFigure(results, handles);
else
	for i = 1:numel(f)
		results = getMap(f(i).filelist, handles);
		sz=size(results(1).A3proj);
		A3 = zeros(sz(1), sz(2), numel(results));

		for j = 1:numel(results)
			A3(:,:,j) = results(j).A3proj;
		end
		allResults(i).A3proj = mean(A3,3);
		allResults(i).maxSig = max(allResults(i).A3proj(:));
		allResults(i).filename = '';
		allResults(i).handles = results(j).handles;
	end
	handles.clims = [0 max(vertcat(allResults.maxSig))];  %calculate max clim value for all plots
	plotFigure(allResults, handles);
	results=allResults;
end



function results = getMap(filelist, handles)
%======Start main loop==============================
fnms = filelist(:,1);

if size(filelist,1) > 1 && size(filelist,2) > 1
	fnms2 = filelist(:,2);
end


for j=1:numel(fnms)
        matfile=load(fnms{j});
        region=matfile.region;

%	[pathstr, name, ext] = fileparts(fnms{j});

    sprintf(fnms{j})    
	
    disp('--------------------------------------------------------------------')
	% cM = getXCorrLagMatrix(region, varin);
	handles.clims = [];
	[A3proj,handles] = wholeBrainActivityMapFig(region,[],2,1,0,[],handles,handles.mapType,0);
	
	A3proj = cropMap(A3proj, region);
	results(j).A3proj = A3proj;
	results(j).filename = fnms{j};
	results(j).handles = handles;
	results(j).maxSig = max(A3proj(:));
	
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


function img = cropMap(img, region, hemisphereIndices);
if nargin < 3 || isempty(hemisphereIndices), 
	hemisphereIndices = find(strcmp(region.name,'cortex.L') | strcmp(region.name,'cortex.R')); 
	if isempty(hemisphereIndices)
		error('Provide valid region.name indices')
	end
end  %index location of the hemisphere region outlines in the 'region' calciumdx struct
sz = size(img);
bothMasks= false(sz(1),sz(2));
for nRoi=1:length(hemisphereIndices)
	regionMask = poly2mask(region.coords{hemisphereIndices(nRoi)}(:,1),region.coords{hemisphereIndices(nRoi)}(:,2),sz(1),sz(2));
	%regionMask2 = poly2mask(region.coords{hemisphereIndices(2)}(:,1),region.coords{hemisphereIndices(2)}(:,2),sz(1),sz(2));
	%figure; imshow(regionMask1); 	figure; imshow(regionMask2);
	bothMasks = bothMasks|regionMask;  %makes a combined image mask of the two hemispheres
end
img(~bothMasks) = 0;


function plotFigure(results, handles)
%--------Setup figure---------
[rows, cols] = setupPlotMatrix(numel(results), 3);  %setup figure window with 3 columns default
handles.figHandle = figure;
updateFigBackground(handles);
handles.frames =  [];
%--Plot figure----------------
for i = 1:numel(results)
	handles.axesHandle = subplot(rows,cols,i);
	[pathstr, fname, ext] = fileparts(results(i).filename);
	handles.axesTitle = {fname results(i).handles.axesTitle};
	handles.frames = results(i).handles.frames;
	wholeBrainActivityMapPlot(results(i).A3proj, results(i).maxSig, handles, []);
end
%--
fnm2 = [datestr(now,'yyyymmdd-HHMMSS') '_' 'ActivityMapFigRawProj-' handles.mapType '.mat'];
print(gcf, '-dpng', [fnm2(1:end-4) '.png']);
print(gcf, '-depsc', [fnm2(1:end-4) '.eps']);



function [rows, cols] = setupPlotMatrix(stimuliToPlot, cols)
numplots = numel(stimuliToPlot);
if nargin < 2 || isempty(cols), cols = 2; end
rows = ceil(numplots/cols);
if rem(numplots,cols) > 0
	rows = rows+1;
end


function updateFigBackground(handles);
set(handles.figHandle, 'color', 'w');
set(handles.figHandle, 'InvertHardCopy', 'off');   %so that black axes background will print
scrsize = get(0, 'screensize');
set(handles.figHandle, 'Position', scrsize);
%        set(handles.figHandle,'color',[1 1 1]);
set(handles.figHandle, 'PaperType', 'usletter');
set(handles.figHandle, 'PaperPositionMode', 'auto');%         numplots = numel(stimuli{numStim}.stimulusParams);
