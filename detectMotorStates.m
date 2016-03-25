function [motorOns, motorOffs] = detectMotorStates(region, y, deltaspacing, handles, manualRefine, makePlots)
%detectMotorStates -- Convert motor period onsets and offsets as frame indices to stimuli and append to stimulusParams
%detect slow oscillatory signals in the motor photodiode signal, y. Detects motor onsets and offsets for active periods. The complement is motor quiet periods. 
%James Ackman, 2013-05-02 14:31:11
%need to have 'region' data structure loaded into workspace
% INPUTS: 
%	region - struct, a valid region data structure, see calciumdx
%	y - the low pass filtered, moving average motor signal you want to detect the states with. 
%	deltaspacing - since numeric, rolling window detection spacing in seconds. Should be set to approximately half of the time interval for the signal you want to detect
%	handles - numeric vector of motor state offset times as frame indices.
% 
% Examples: 
%	[motorOns, motorOffs] = 	detectMotorStates(region, rateChannels(5).y, deltaspacing);
%	detectMotorStates(region, y, 100);
%
% See also: batchmakeStimParamsWaveonsets, getStimParams, myFrameTriggerDetect, calciumdx, myBatchFilter, groupMotorStates, batchFetchMotorStates
%
% Author: James B. Ackman 2013-05-06 12:49:44
%based on calciumdxDetectWaves.m by James B. Ackman
% legacy code 2016-03-24 15:56:01, superceded by groupMotorStates.m and batchFetchMotorStates.m by JBA

if nargin < 6 || isempty(makePlots), makePlots = 1; end
if nargin < 5 || isempty(manualRefine), manualRefine = 'true'; makePlots = 1; end
if nargin < 4 || isempty(handles), handles = []; end  %in case this is being called multiple times for multiple plots
if nargin < 3 || isempty(deltaspacing), deltaspacing = 30; end  %deltaspacing in secs

locationIndex = 1; %dummy holder for now

data = y;

mpd=round(deltaspacing/region.timeres); %wave onsets
[pks, idx] = findpeaks(data,'minpeakdistance',mpd,'threshold',0);

if makePlots
    if ~isempty(handles)
    	ax = handles.axes_current;
    else
    	hFig = figure;
    	scrsize = get(0,'screensize');
    	set(hFig,'Position',scrsize);
    	set(hFig,'color',[1 1 1]);
    	set(hFig,'PaperType','usletter');
    	set(hFig,'PaperPositionMode','auto');
    	handles.hFig = hFig;
    end

    ax(1) = subplot(2,1,1);    
    plot(region.motorSignal,'-k'); ylabel('Motor activity (uV)'); grid minor

    ax(2) = subplot(2,1,2);
    handles.axes_current = ax(2);
    handles.ax = ax;
    plot(ax(2), data(1,:));
    hold on;
    plot(ax(2), idx,data(idx),'ok');
    %hold off;
    %a(2) = subplot(2,1,2);
    %imagesc(dfoverf(region.traces));
    %linkaxes(a,'x')
end


pks = [1 idx size(data,2)];
minima = [];
for pkind = 1:(length(pks) - 1)
    datasegment = data(pks(pkind):pks(pkind+1));
    datasegmentMinima = find(datasegment == min(datasegment));
    datasegmentMinimum = fix(median(datasegmentMinima));
    minima = [minima (pks(pkind) + datasegmentMinimum-1)];
end


wvonsets = [];
%thresholdlevel = 0.05;
thresholdlevel = 0.5;
for pkind = 1:(length(minima) - 1)
    thresh = abs(data(minima(pkind)) - data(idx(pkind))) * thresholdlevel;
    datasegment = find(data(minima(pkind):idx(pkind)) > thresh+data(minima(pkind)));
    if isempty(datasegment)
        stn = 0;
    else
        stn = datasegment(1);
    end
    stn = stn + minima(pkind)-1;
    wvonsets = [wvonsets stn];
end


wvoffsets = [];
%thresholdlevel = 0.20;
thresholdlevel = 0.50;
for pkind = 1:(length(idx))
    thresh = abs(data(minima(pkind+1)) - data(idx(pkind))) * thresholdlevel;
    datasegment = find(data(idx(pkind):minima(pkind+1)) < thresh+data(minima(pkind+1)));
    if isempty(datasegment)
        stn = 0;
    else
        stn = datasegment(1);
    end
    stn = stn + idx(pkind)-1;
    wvoffsets = [wvoffsets stn];
end

if makePlots
    plot(ax(2), minima,data(minima),'or');
    plot(ax(2), wvonsets,data(wvonsets),'og');
    plot(ax(2), wvoffsets,data(wvoffsets),'ob');
    hold off

    ylabel('Motor activity filt (uV)'); grid minor
    xlabel('Time (movie fr)')
    linkaxes(ax,'x'); zoom xon    
    set(ax,'YGrid','off') 
end

idx1 = wvonsets;
idx2 = wvoffsets;


%figure out if an offset was at last frame of movie (no. of onsets and offsets not equal)
if numel(idx1) ~= numel(idx2)
    button = questdlg('Number of onsets not equal to number of offsets (Event may be at end of movie). Set final offset to last frame of movie?');
    %     errordlg('Number of onsets not equal to number of offsets. Final offset set to last datapoint, in case wave was at end of movie.')
    if strcmp(button,'Yes')
        idx2=[idx2 size(data,2)];
    end
end

%region.wavedata{locationIndex}.waveonsets=idx1;
%region.wavedata{locationIndex}.waveoffsets=idx2;
%region.wavedata{locationIndex}.wavepeaks=idx;

motorOns=idx1;
motorOffs=idx2;

if strcmp(manualRefine,'true')
	[motorOns,motorOffs] = DetectMotorStatesRefine(data,motorOns,motorOffs,idx,minima,handles);
end
