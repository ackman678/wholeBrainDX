function wholeBrainICAmaps(fnm,ica_filters,ICuse,clims,usezscore,zflag)
%wholeBrainICAmaps(fnm,ica_filters,ICuse)
% Plots spatial activation components returned from ICA
% Examples
%	wholeBrainICAmaps(fnm,ica_filters,[1 2]);    
% INPUTS
% fnm -- string, filename of the tiff movie
% ica_filters -- spatial independent components, an nIC x nx x ny array
% ICuse -- numeric vector of indices for which independent components to use
% clims -- numeric vector of length 1 or 2. If length 1, then it is the min clim. If length 2 then it is the [min max] clim.
% usezscore -- logical, default is 1. Choice of whether to scale map values as z-scores (units of standard deviation)
% zflag -- logical, default is 0. Choice of whether to compute the z-scores as sample standard deviation or population standard deviation.
% 2014-11-03 09:28:55 James B. Ackman

if nargin < 4 || isempty(clims), clims = []; end
if nargin < 5 || isempty(usezscore), usezscore = 1; end
if nargin < 6 || isempty(zflag), zflag = 0; end

ica_filters = shiftdim(ica_filters,1); %shift dim to the left so that ica_filters is now szX x szY x nIC
[szX,szY] = size(ica_filters(:,:,1));
npix = szX*szY;

if usezscore
	mapProj = reshape(ica_filters(:,:,ICuse),npix,length(ICuse));
	zsig = zscore(mapProj,zflag); %zscore will scale the matrix so that each column has mean 0 and standard deviation of 1. If flag = 0 (default), sample standard deviations are computed. If flag = 1, population standard deviation is computed. 
	zsig = reshape(zsig,szX,szY,length(ICuse));
	mapProj = zsig;
	titleStr = 'z-score';
else
	mapProj = ica_filters(:,:,ICuse);
	titleStr = 'dF/F energy';
end

for i = 1:length(ICuse)
	allResults(i).A3proj = mapProj(:,:,i);
	allResults(i).maxSig = max(allResults(i).A3proj(:));
	allResults(i).minSig = min(allResults(i).A3proj(:));
	allResults(i).filename = fnm;
	allResults(i).handles.frames = [];
	allResults(i).handles.axesTitle = ['IC' num2str(ICuse(i)) ' ' titleStr];
end

if isempty(clims)
	handles.clims = [min(vertcat(allResults.minSig)) max(vertcat(allResults.maxSig))];  %calculate max clim value for all plots
elseif length(clims) < 2
	handles.clims = [clims(1) max(vertcat(allResults.maxSig))];  %calculate max clim value for all plots
else
	handles.clims = clims; 
end

% 
plotFigure(allResults, handles);

function plotFigure(results, handles)
%--------Setup figure---------
if numel(results) < 3, 
	cols = 2;
else
	cols = 3;
end

[rows, cols] = setupPlotMatrix(numel(results), cols);  %setup figure window with 3 columns default
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
fnm = results(1).filename;
fnm2 = [fnm(1:end-4) '_' datestr(now,'yyyymmdd-HHMMSS') '_' 'wholeBrainICAmaps' '.mat'];
print(gcf, '-dpng', [fnm2(1:end-4) '.png']);
print(gcf, '-depsc', [fnm2(1:end-4) '.eps']);



function [rows, cols] = setupPlotMatrix(numplots, cols)
if nargin < 2 || isempty(cols), cols = 2; end
rows = floor(numplots/cols);
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

