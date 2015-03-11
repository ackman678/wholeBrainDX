function wholeBrain_displayActiveFractionPeriods(data,region)
%script to fetch the active and non-active pixel fraction period durations
%for all data and all locations
%2013-04-09 11:35:04 James B. Ackman
%Want this script to be flexible to fetch data for any number of location Markers as well as duration distributions for both non-active and active periods.  
%Should get an extra location signal too-- for combined locations/hemisphere periods.

locationMarkers = {data.name};
disp(['name ' 'period.type ' 'maxDuration.s ' 'minDuration.s ' 'medianDuration.s ' 'meanDuration.s ' 'sdDuration.s ' 'sumDuration.s'])

SignalMatrix = zeros(length(locationMarkers),size(data(1).activeFractionByFrame,2));
for locationIndex = 1:length(locationMarkers)
    locationName = data(locationIndex).name;
    rawSignal = data(locationIndex).activeFractionByFrame;
    
    pulseSignal = makeActivePulseSignal(rawSignal);
    plotTitles{1} = ['active fraction by frame for ' locationName]; plotTitles{2} = 'active periods to positive pulse'; plotTitles{3} = 'derivative of active pulse';
    [onsets, offsets] = getPulseOnsetsOffsets(rawSignal,pulseSignal,plotTitles,locationName);
    printStats(onsets,offsets,locationName,region,'active')
    
    pulseSignal = makeNonActivePulseSignal(rawSignal);
    plotTitles{1} = ['active fraction by frame for ' locationName]; plotTitles{2} = 'Non-active periods to positive pulse'; plotTitles{3} = 'derivative of non-active pulse';
    [onsets, offsets] = getPulseOnsetsOffsets(rawSignal,pulseSignal,plotTitles,locationName);
    printStats(onsets,offsets,locationName,region,'non.active')
    
    SignalMatrix(locationIndex,:) = rawSignal;
end
locationName = 'all';
CombinedSignal = max(SignalMatrix,[],1);  %combine active periods to find combined active and non-active durations

pulseSignal = makeActivePulseSignal(CombinedSignal);
plotTitles{1} = ['active fraction by frame for ' locationName]; plotTitles{2} = 'active periods to positive pulse'; plotTitles{3} = 'derivative of active pulse';
[onsets, offsets] = getPulseOnsetsOffsets(CombinedSignal,pulseSignal,plotTitles,locationName);
printStats(onsets,offsets,locationName,region,'active')

pulseSignal = makeNonActivePulseSignal(CombinedSignal);
plotTitles{1} = ['active fraction by frame for ' locationName]; plotTitles{2} = 'Non-active periods to positive pulse'; plotTitles{3} = 'derivative of non-active pulse';
[onsets, offsets] = getPulseOnsetsOffsets(CombinedSignal,pulseSignal,plotTitles,locationName);
printStats(onsets,offsets,locationName,region,'non.active')



function stats = printStats(onsets,offsets,locationName,region,periodType)
mx = max((offsets-onsets).*region.timeres);
mn = min((offsets-onsets).*region.timeres);
md = median((offsets-onsets).*region.timeres);
mu = mean((offsets-onsets).*region.timeres);
sd = std((offsets-onsets).*region.timeres);
sm = sum((offsets-onsets).*region.timeres);
disp([locationName ' ' periodType ' ' num2str(mx) ' ' num2str(mn) ' ' num2str(md) ' ' num2str(mu) ' ' num2str(sd) ' ' num2str(sm)])


function pulseSignal = makeActivePulseSignal(rawSignal)
pulseSignal = rawSignal;
pulseSignal(rawSignal>0) = 1;


function pulseSignal = makeNonActivePulseSignal(rawSignal)
pulseSignal = rawSignal;
pulseSignal(rawSignal>0) = -1;
pulseSignal(pulseSignal>-1) = 1;
pulseSignal(pulseSignal<1) = 0;



function [wvonsets, wvoffsets] = getPulseOnsetsOffsets(rawSignal,pulseSignal,plotTitles,locationName)

if nargin < 4 || isempty(locationName), locationName = 'unknown location'; end
if nargin < 3 || isempty(plotTitles), plotTitles{1} = ['active fraction by frame for ' locationName]; plotTitles{2} = 'active periods to positive pulse'; plotTitles{3} = 'derivative of active pulse'; end

x = pulseSignal;
sig = rawSignal;
%ax = axesHandles;

figure, 
ax(1)=subplot(3,1,1);
plot(sig); title(plotTitles{1})

ax(2)=subplot(3,1,2);
plot(x); title(plotTitles{2})		

ax(3)=subplot(3,1,3);
dx = diff(x);
dx2 = [dx 0];  %because diff makes the vector one data point shorter.
plot(dx2); title(plotTitles{3})		
linkaxes(ax,'x')
zoom xon

wvonsets = find(dx > 0);
wvoffsets = find(dx < 0);

%figure out if an offset was at last frame of movie (no. of onsets and offsets not equal)
if wvonsets(1) > wvoffsets(1)
   wvonsets = [1 wvonsets];
end

if wvoffsets(end) < wvonsets(end)
   wvoffsets = [wvoffsets size(sig,2)];
end



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


%figure out if an offset was at last frame of movie (no. of onsets and offsets not equal)
% if numel(idx1) ~= numel(idx2)
%     button = questdlg('Number of onsets not equal to number of offsets (Event may be at start or end of movie). Automatically Fix?');
%     %     errordlg('Number of onsets not equal to number of offsets. Final offset set to last xpoint, in case wave was at end of movie.')
%     if strcmp(button,'Yes')
%         if idx1(1) > idx2(1)
%             idx1 = [1 idx1];
%         end
%         
%         if idx2(end) < idx1(end)
%            idx2 = [idx2 size(x,2)];
%         end
%     end
% end