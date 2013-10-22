function wholeBrain_actvFractionMotorPlot(region,signal1,signal2,plotType,titleStr1,titleStr2,ylabel1,ylabel2)
% wholeBrain_actvFractionMotorPlot(region,signal1,signal2)

%James B. Ackman 2013-10-22 10:22:57

if nargin < 4 || isempty(plotType), plotType = 1; end

if nargin < 5 || isempty(titleStr1), titleStr1 = 'actvFraction, both hemis'; end

if nargin < 6 || isempty(titleStr2), titleStr2 = 'bp/rect/dec/motor signal'; end

if nargin < 7 || isempty(ylabel1), ylabel1 = 'Fraction of px active'; end

if nargin < 8 || isempty(ylabel2), ylabel2 = 'motor activity (uV)'; end

cActvFraction = signal1;
decY2 = signal2;
stimuli = region.stimuli;

hFig = figure;
scrsize = get(0,'screensize');
set(hFig,'Position',scrsize);
set(hFig,'color',[1 1 1]);
set(hFig,'PaperType','usletter');
set(hFig,'PaperPositionMode','auto');%         numplots = numel(stimuli{numStim}.stimulusParams);
%handles.figHandle = h;

%		 mycolors = [0.8 0.8 1.0; 0.8 1.0 0.8; 1.0 0.8 0.8; 0.6 0.6 1.0; 0.6 1.0 0.6; 1.0 0.6 0.6; 0.4 0.4 1.0; 0.4 1.0 0.4; 1.0 0.4 0.4];        
mycolors = [0.8 0.8 0.8; 0.8 0.8 0.8; 0.8 0.8 0.8; 0.8 0.8 0.8; 0.8 0.8 0.8];


switch plotType

	case 1

	ax(1) = subplot(2,1,1);
	minY = min(cActvFraction); maxY = max(cActvFraction);
	plotStimuli(region,stimuli,minY,maxY,mycolors)
	hold on
	plot(cActvFraction,'k-');    ylabel(ylabel1); title(titleStr1); ylim([minY maxY]); xlim([0 length(cActvFraction)])      

	ax(2) = subplot(2,1,2);      
	minY = min(decY2); maxY = max(decY2);
	plotStimuli(region,stimuli,minY,maxY,mycolors)
	hold on
	plot(decY2,'k-'); ylabel(ylabel2); title(titleStr2); ylim([minY maxY]); xlim([0 length(cActvFraction)])
	linkaxes(ax,'x')  
	xlabel('Time (image frame no.)');   
	zoom xon   


case 2


	x = cActvFraction; 
	y = decY2;
	N = length(x);    
	stimIdx = 1;  
	spkChan = zeros(1, length(y));  
	
	for i = 1:length(region.stimuli{stimIdx}.stimulusParams)  
	    ind = round(region.stimuli{stimIdx}.stimulusParams{i}.stimulus_times(1) / region.timeres / 1e06);  
	    spkChan(1,ind) = 1;   
	end  
	motorOnsets = find(spkChan);  
	
	clear rateChannels    
%	maxlagsAll = 50:50:500;  
	maxlagsAll = [50 250];
	
	for i = 1:length(maxlagsAll);  
	    maxlags = maxlagsAll(i);
	    maxlagsTime = maxlags .* region.timeres;    
	
	    data = x';  
%	    filtData = filtfilt(ones(1,maxlags)/maxlags,1,data);  
		filtData = filter(ones(1,maxlags)/maxlags,1,data);  
	    rateChannels(i).x = filtData';
	
	    data = y';  
%	    filtData = filtfilt(ones(1,maxlags)/maxlags,1,data);  
		filtData = filter(ones(1,maxlags)/maxlags,1,data);  
	    rateChannels(i).y = filtData';
	end    
	
	myColors = jet(length(maxlagsAll));    
	clear h    
	ax(1) = subplot(4,1,1); xlim([0 N]);  
	minY = min(x); maxY = max(x);
	plotStimuli(region,stimuli,minY,maxY,mycolors)
	hold on
	plot(x,'-k'); ylabel('Active fraction'); 
%	grid minor; 
	ylim([minY maxY])   

	ax(2) = subplot(4,1,2); xlim([0 N]);     
	minY = min(y); maxY = max(y);
	plotStimuli(region,stimuli,minY,maxY,mycolors)
	hold on
	plot(y,'-k'); ylabel('Motor activity'); 
%	grid minor; 
	ylim([minY maxY])     
	plot(motorOnsets, y(motorOnsets),'or')  

	ax(3) = subplot(4,1,3); xlim([0 N]); hold all; ylabel('Avg actvFraction'); 
%	grid minor;
	minY = min(rateChannels(1).x); maxY = max(rateChannels(1).x);
	plotStimuli(region,stimuli,minY,maxY,mycolors)
	hold on
	
	for i = 1:length(maxlagsAll)    
	    plot(ax(3),rateChannels(i).x, '-', 'Color', myColors(i,:)); %title('corrcoef r-val')    
	    h(1).leg{i} = num2str(maxlagsAll(i));    
	end  
	ylim([minY maxY])
	
	ax(4) = subplot(4,1,4); xlim([0 N]); hold all; ylabel('Avg motor activity (uV)');
	minY = min(rateChannels(1).y); maxY = max(rateChannels(1).y);
	plotStimuli(region,stimuli,minY,maxY,mycolors)
	hold on
	
	for i = 1:length(maxlagsAll)    
	    plot(ax(4),rateChannels(i).y, '-', 'Color', myColors(i,:)); %title('corrcoef r-val')    
	    h(2).leg{i} = num2str(maxlagsAll(i));    
	end    
	ylim([minY maxY])
	
	linkaxes(ax,'x'); zoom xon    
%	clickableLegend(ax(3),h(1).leg,[]);    
%	clickableLegend(ax(4),h(2).leg,[]);    
	set(ax,'YGrid','off') 

end


function plotStimuli(region,stimuli,minY,maxY,mycolors)
for numStim = 1:length(stimuli)
	if strcmp(stimuli{numStim}.description,'motor.state.active')
%		 mycolors = [0.8 0.8 1.0; 0.8 1.0 0.8; 1.0 0.8 0.8; 0.6 0.6 1.0; 0.6 1.0 0.6; 1.0 0.6 0.6; 0.4 0.4 1.0; 0.4 1.0 0.4; 1.0 0.4 0.4];        

			for i=1:numel(stimuli{numStim}.stimulusParams)
				x1=(stimuli{numStim}.stimulusParams{i}.frame_indices(1)/stimuli{numStim}.stimulusParams{i}.frame_times(1))*stimuli{numStim}.stimulusParams{i}.stimulus_times(1);
				x2=(stimuli{numStim}.stimulusParams{i}.frame_indices(end)/stimuli{numStim}.stimulusParams{i}.frame_times(end))*stimuli{numStim}.stimulusParams{i}.stimulus_times(end);
				x = [x1; x1; x2; x2];
				y = [minY; maxY; maxY; minY];
				h1(i) = patch(x,y,mycolors(numStim,:));  % fill
	%             set(h1(i),'EdgeColor',mycolors(numStim,:));  %outline
				set(h1(i),'EdgeColor',mycolors(numStim,:));  %outline
	%             set(h1(i),'FaceAlpha',0.1,'EdgeAlpha',0.1)  %looks great but matlab does not export transparency well
%				set(h1(i),'DisplayName',stimuli{numStim}.description{1})
			end
	end
end
