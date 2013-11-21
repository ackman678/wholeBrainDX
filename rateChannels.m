function rateChannels = rateChannels(region,cActvFraction)
%rateChannels(region)
%Fetches a series of moving average timeseries for Cortical and/or Motor Activity Signals
%Author - James B. Ackman 2013-11-20 15:59:22  

y = region.motorSignal;
if nargin<2 || isempty(cActvFraction),
	x = [];
	N = length(y);
else
	x = cActvFraction; 
	N = length(x);
end

[motorOnsets,spkChan] = getMotorOnsets(region);

%   figure; plot(spkChan, 'or')  %TESTING
%   spkChan = fliplr(spkChan);  %to reverse spkChan to run the rolling window backwards
%   hold on; plot(spkChan, 'ob')  %TESTING  

maxlagsAll = 50:50:500;  
rateChannels = getCorticalRateChannel(maxlagsAll,x,region);
rateChannels = getMotorRateChannel(rateChannels,maxlagsAll,y,region);

myColors = jet(length(maxlagsAll));      
hFig = figure;
scrsize = get(0,'screensize');
set(hFig,'Position',scrsize);
set(hFig,'color',[1 1 1]);
set(hFig,'PaperType','usletter');
set(hFig,'PaperPositionMode','auto'); 

if ~isempty(x)
	ax(1) = subplot(4,1,1); xlim([ 0 N]);    
	plot(x,'-k'); ylabel('Active fraction'); grid minor    
	ax(2) = subplot(4,1,2); xlim([0 N]);     
	plot(y,'-k'); ylabel('Motor activity'); grid minor    
	hold on;    
	plot(motorOnsets, y(motorOnsets),'or')  
	ax(3) = subplot(4,1,3); xlim([ 0 N]); hold all; ylabel('Avg actvFraction'); grid minor    
	ax(4) = subplot(4,1,4); xlim([ 0 N]); hold all; ylabel('Avg motor activity (uV)'); grid minor    

	for i = 1:length(maxlagsAll)    
		plot(ax(3),rateChannels(i).x, '-', 'Color', myColors(i,:)); 
		h(1).leg{i} = num2str(maxlagsAll(i));    
	end  

	for i = 1:length(maxlagsAll)    
		plot(ax(4),rateChannels(i).y, '-', 'Color', myColors(i,:));    
		h(2).leg{i} = num2str(maxlagsAll(i));    
	end    

	linkaxes(ax,'x'); zoom xon    
	clickableLegend(ax(3),h(1).leg,[]);    
	clickableLegend(ax(4),h(2).leg,[]);    
	set(ax,'YGrid','off')  

else

	ax(1) = subplot(2,1,1); xlim([0 N]);     
	plot(y,'-k'); ylabel('Motor activity'); grid minor    
	hold on;    
	plot(motorOnsets, y(motorOnsets),'or')  

	ax(2) = subplot(2,1,2); xlim([ 0 N]); hold all; ylabel('Avg motor activity (uV)'); grid minor    

	for i = 1:length(maxlagsAll)    
		plot(ax(2),rateChannels(i).y, '-', 'Color', myColors(i,:));    
		h(1).leg{i} = num2str(maxlagsAll(i));    
	end    

	linkaxes(ax,'x'); zoom xon    
	clickableLegend(ax(2),h(1).leg,[]);    
	set(ax,'YGrid','off')  
end



function rateChannels = getCorticalRateChannel(maxlagsAll,x,region)
for i = 1:length(maxlagsAll);  
    maxlags = maxlagsAll(i);
    maxlagsTime = maxlags .* region.timeres;  
    
    if ~isempty(x)
		data = x';  
		filtData = filtfilt(ones(1,maxlags)/maxlags,1,data);  
		rateChannels(i).x = filtData';
    else 
		rateChannels(i).x = [];
    end

end 



function rateChannels = getMotorRateChannel(rateChannels,maxlagsAll,y,region)
for i = 1:length(maxlagsAll);  
    maxlags = maxlagsAll(i);
    maxlagsTime = maxlags .* region.timeres;  

    data = y';  
    filtData = filtfilt(ones(1,maxlags)/maxlags,1,data);  
    rateChannels(i).y = filtData';

	%rateChannels(i).y = fliplr(rateChannels(i).y);  %if you run the rolling window backwards  
end 



function [motorOnsets,spkChan] = getMotorOnsets(region,stimIdx)
if nargin < 2 || isempty(stimIdx), stimIdx = 1; end %assuming this is the channel with 'motor.onsets'
spkChan = zeros(1, length(region.motorSignal));  

for i = 1:length(region.stimuli{stimIdx}.stimulusParams)  
    ind = round(region.stimuli{stimIdx}.stimulusParams{i}.stimulus_times(1) / region.timeres / 1e06);  
    spkChan(1,ind) = 1;   
end  
motorOnsets = find(spkChan);  
