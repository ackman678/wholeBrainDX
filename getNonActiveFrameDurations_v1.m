function [idx1, idx2] = getNonActiveFrameDurations_v1(x)
%2013-04-08  James B. Ackman   
%This version is based on the calciumdxDetectWaves.m algorithm for onsets and offsets
%of signals.  This one works but not 100%, which should be possible since
%in the first few lines we convert the active pixel signals into square
%wave pulses. Coded a new one algorithm based on diff() the next day. Same
%function name.

% x = x(1).activeFractionByFrame; 
% y = x(2).activeFractionByFrame;

figure, 
ax(1)=subplot(3,1,1);
plot(x)
ax(2)=subplot(3,1,2);
x(x>0) = -1;	
plot(x)
ax(3)=subplot(3,1,3);
x(x>-1) = 1;
x(x<1) = 0;
plot(x)		
ylim([0 2])

%deltaspacing=10; %10secs in between waves
%mpd=round(deltaspacing/region.timeres); %wave onsets

mpd=2;
[pks, idx] = findpeaks(x,'minpeakdistance',mpd,'threshold',0);
% idx1=idx1+1; %because the onsets are offset by one frame from diff
% figure;
% plot(x(1,:));
% hold on;
% plot(idx1,x(idx1),'ok');
% hold off;

hold on;
plot(idx,x(idx),'ok');
hold off;
linkaxes(ax,'x')
zoom xon

pks = [1 idx size(x,2)];
minima = [];
for pkind = 1:(length(pks) - 1)
    xsegment = x(pks(pkind):pks(pkind+1));
    xsegmentMinima = find(xsegment == min(xsegment));
    xsegmentMinimum = fix(median(xsegmentMinima));
    minima = [minima (pks(pkind) + xsegmentMinimum-1)];
end
axes(ax(3))
hold on
plot(minima,x(minima),'or');

wvonsets = [];
thresholdlevel = 0.01;
for pkind = 1:(length(minima) - 1)
    thresh = abs(x(minima(pkind)) - x(idx(pkind))) * thresholdlevel;
    xsegment = find(x(minima(pkind):idx(pkind)) > thresh+x(minima(pkind)));
    if isempty(xsegment)
        stn = 0;
    else
        stn = xsegment(1);
    end
    stn = stn + minima(pkind)-1;
    wvonsets = [wvonsets stn];
end
axes(ax(3))
hold on
plot(wvonsets,x(wvonsets),'og');

wvoffsets = [];
thresholdlevel = 0.020;
for pkind = 1:(length(idx))
    thresh = abs(x(minima(pkind+1)) - x(idx(pkind))) * thresholdlevel;
    xsegment = find(x(idx(pkind):minima(pkind+1)) < thresh+x(minima(pkind+1)));
    if isempty(xsegment)
        stn = 0;
    else
        stn = xsegment(1);
    end
    stn = stn + idx(pkind)-1;
    wvoffsets = [wvoffsets stn];
end
axes(ax(3))
hold on
plot(wvoffsets,x(wvoffsets),'ob');

idx1 = wvonsets;
idx2 = wvoffsets;

%figure out if an offset was at last frame of movie (no. of onsets and offsets not equal)
if numel(idx1) ~= numel(idx2)
    button = questdlg('Number of onsets not equal to number of offsets (Event may be at end of movie). Set final offset to last frame of movie?');
    %     errordlg('Number of onsets not equal to number of offsets. Final offset set to last xpoint, in case wave was at end of movie.')
    if strcmp(button,'Yes')
        idx2=[idx2 size(x,2)];
    end
end