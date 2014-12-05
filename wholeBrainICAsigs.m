function [allResults] = wholeBrainICAsigs(fnm,ica_sig,ICuse,stimuli,stimDesc,usezscore,zflag)
%wholeBrainICAsigs(fnm,ica_filters,ICuse)
% Plots spatial activation components returned from ICA
% Examples
%	wholeBrainICAsigs(fnm,ica_sig,[1 2],stimuli,stimDesc);    
% INPUTS
% fnm -- string, filename of the tiff movie
% ica_filters -- spatial independent components
% ICuse -- numeric vector of indices for which independent components to use
% stimuli -- region.stimuli
% stimDesc -- cell array of strings for the stimuli(numStim).description. Can be more than one string.
% usezscore -- logical, default is 1. Choice of whether to scale map values as z-scores (units of standard deviation)
% zflag -- logical, default is 0. Choice of whether to compute the z-scores as sample standard deviation or population standard deviation.
% 2014-11-05 09:39:23 James B. Ackman

if nargin < 4 || isempty(stimuli), stimuli = []; end
if nargin < 5 || isempty(stimDesc), 
	stimDesc = [];
	if ~isempty(stimuli)
		try
			for i = 1:length(stimuli)
				stimDesc{i} = stimuli{i}.description;
			end
		catch exception
			error('stimuli structure not formatted correctly, see makeFrameStimParams.m')
			% rethrow(exception)
		end
	end
end

if nargin < 6 || isempty(usezscore), usezscore = 1; end
if nargin < 7 || isempty(zflag), zflag = 0; end

if usezscore
	zsig = ica_sig(ICuse,:);
	zsig = zscore(zsig',zflag); %zscore will scale the matrix so that each column has mean 0 and standard deviation of 1. If flag = 0 (default), sample standard deviations are computed. If flag = 1, population standard deviation is computed. 
	ica_sig = zsig';
	titleStr = 'z-score';
else
	ica_sig = ica_sig(ICuse,:);
	titleStr = 'dF/F energy';
end



for i = 1:length(ICuse)
	allResults(i).sig = ica_sig(i,:);
	allResults(i).maxSig = max(allResults(i).sig(:));
	allResults(i).minSig = min(allResults(i).sig(:));
	allResults(i).filename = fnm;
	allResults(i).handles.axesTitle = ['IC' num2str(ICuse(i)) ' ' titleStr];
end

handles.ylims = [min(vertcat(allResults.minSig)) max(vertcat(allResults.maxSig))];  %calculate max clim value for all plots
 
plotFigure(allResults, handles, stimuli, stimDesc);




function plotFigure(results, handles, stimuli, stimDesc)
%--------Setup figure---------
if numel(results) < 10, 
	cols = 1;
else
	cols = 3;
end
% mycolors = [0.8 0.8 0.8; 0.8 0.8 0.8; 0.8 0.8 0.8; 0.8 0.8 0.8; 0.8 0.8 0.8];

if ~isempty(stimuli), mycolors = lines(length(stimuli)); end

[rows, cols] = setupPlotMatrix(numel(results), cols);  %setup figure window with 3 columns default

handles.figHandle = figure;
updateFigBackground(handles);

%--Plot figure----------------
for i = 1:numel(results)
	ax(i) = subplot(rows,cols,i);
	[pathstr, fname, ext] = fileparts(results(i).filename);
	handles.axesTitle = {fname results(i).handles.axesTitle};
	minY = handles.ylims(1); maxY = handles.ylims(2);
	if ~isempty(stimuli)
		for j = 1:length(stimDesc)
			plotStimuli([],stimuli,minY,maxY,mycolors,stimDesc{j})
			hold on
		end
	end
	plot(results(i).sig,'k-'); title(handles.axesTitle,'Interpreter','none'); ylim([minY maxY]); xlim([0 length(results(i).sig)])
end

linkaxes(ax,'x')  
xlabel('Time (image frame no.)');   
zoom xon 

%--
fnm = results(1).filename;
fnm2 = [fnm(1:end-4) '_' datestr(now,'yyyymmdd-HHMMSS') '_' 'wholeBrainICAsigs' '.mat'];
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
set(handles.figHandle, 'PaperType', 'usletter');
set(handles.figHandle, 'PaperPositionMode', 'auto');

