function [index, thrN, thrN2] = detectMotorOnsets(region,nsd,groupRawThresh,groupDiffThresh,printFig)
%detectMotorOnsets - A detect behavioral movement onsets in a rectified motor signal timeseries (e.g. bandpass, rectified, downsampled photodiode signal)
%Examples:
% >> [index] = detectMotorOnsets(region,[],2)
% >> [index] = detectMotorOnsets(region,groupThresh,[],1)
%
%**USE**
%Must provide one input:
%
%region - datastructure with 'region.motorSignal' timeseries
%
%Options:
%groupThresh %single numeric, of a previously calculated threshold to use (e.g. based on concatenated motor timeseries from a single animal)
%nsd %single numeric, number of standard deviations (on the median) to make threshold
%printFig, logical flag on whether to plot figures
% See also wholeBrain_motorSignal, mySpikeDetect, batchFetchStimResponseProps, batchFetchMotorStates, detectMotorStates, rateChannels, makeMotorStateStimParams
%
%James B. Ackman 2013-04-01 - 2016-03-24 12:06:03

decY2 = region.motorSignal;
if nargin < 5 || isempty(printFig), printFig = 0; end
if nargin < 2 || isempty(nsd), nsd = 1; end

mdn1=median(abs(decY2));
mad1=mad(abs(decY2)); %median absolute deviation
if nargin < 3 || isempty(groupRawThresh)
    sd1=mad1;
    % sd1=mad1/0.6745; %standard deviation estimate of background
	thrN = (nsd*sd1) + mdn1;
	thr1 = (1*sd1) + mdn1;
else
	thrN = groupRawThresh;
	thr1 = thrN/nsd;
end

dfY2 = diff(decY2);
mdn2=median(abs(dfY2));
mad2=mad(abs(dfY2));

if nargin < 4 || isempty(groupDiffThresh)
    sd2=mad2;    
    % sd2=mad2/0.6745;    
	thrN2 = (nsd*sd2) + mdn2; 
else
	thrN2 = groupDiffThresh; 
end

% figure; hist(decY2)
% figure; hist(dfY2)
% disp(['median abs(raw)= ' num2str(mdn1)])
% disp(['groupRawThresh= ' num2str(thrN)])
% disp(['median abs(diff)= ' num2str(mdn2)])
% disp(['groupDiffThresh= ' num2str(thrN2)])

deadTime = 500;  % dead time for spikes and artifacts is in msec  
[index, thrN2] = mySpikeDetect(dfY2, 1/region.timeres, thrN2, deadTime);

idx = find(decY2 >= thrN);
spks = index(ismember(index,idx-1) | ismember(index,idx-2)); %assume that the spike detected in the diff trace will occur within two frames of the motor signal going above thrN. 
index = spks;

if printFig
    hFig = figure;
    scrsize = get(0,'screensize');
    set(hFig,'Position',scrsize);
    set(hFig,'color',[1 1 1]);
    set(hFig,'PaperType','usletter');
    set(hFig,'PaperPositionMode','auto');
               
    ax(1) = subplot(2,1,1);        
    plot(decY2,'-'); ylabel('motor activity (V)'); title('bp/rect/dec/motor signal')    
    xlabel('Time (image frame no.)');     
    line([0 length(decY2)],[thrN thrN],'LineStyle','--','color','r');       
    line([0 length(decY2)],[thr1 thr1],'LineStyle','--','color','g');    
    legend({'decY2' [num2str(nsd) 'sd mdn'] '1sd mdn'})  
    hold on  

    ax(2) = subplot(2,1,2)  
    plot([dfY2 0], '-')  
    line([0 length(decY2)],[thrN2 thrN2],'LineStyle','--','color','r');  
    line([0 length(decY2)],[-thrN2 -thrN2],'LineStyle','--','color','r');    
    thr1 = thrN2/nsd;    
    line([0 length(decY2)],[thr1 thr1],'LineStyle','--','color','g');    
    line([0 length(decY2)],[-thr1 -thr1],'LineStyle','--','color','g');    

    hold on;  
    plot(index, dfY2(index),'or')  
    legend({'diff(decY2)' [num2str(nsd) 'sd mdn'] '1sd mdn' ['spkDet,' num2str(deadTime) 'msWin']})    
    
    zoom xon     
    linkaxes(ax,'x')    

    fnm = region.tmpName;
    title(fnm,'Interpreter','none')
    print(gcf,'-dpng',[fnm(1:end-4) 'motorSignal-cat' datestr(now,'yyyymmdd-HHMMSS') '.png'])            
    print(gcf,'-depsc',[fnm(1:end-4) 'motorSignal-cat' datestr(now,'yyyymmdd-HHMMSS') '.eps'])

end 
