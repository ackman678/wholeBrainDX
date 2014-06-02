function [region, cM, lags] = wholeBrain_MotorSignalCorr(fnm,region,st,exclude, makePlots, rsFactor)
%wholeBrain_MotorSignalCorr - Generate cross-correlation plots and values for region.locations with motor signal
%Examples:
% region = wholeBrain_MotorSignalCorr(fnm,region)
% region = wholeBrain_MotorSignalCorr(fnm,region,st)
%**USE**
% fnm - .mat filename, from which filenames for plots will be saved (nothing will be overwritten) 
% region - region data structure with region.locationData.data structure returned from wholeBrain_activeFraction.m
% st - a structure array, st containing the cell arrays, str that contain the region.locations that you want to concatentate to make plots and autocorr and xcorr with the motorSignal
% exclude - 
% makePlots -
% rsFactor - resampling factor if comparing multiple recordings that are of different sampling rates.
%Output:
%region - will print correlation results to command line. Return region data structure with corr data at region.userdata.motorCorr. Will also display corr plots with activeFraction traces.
%
% See also wholeBrain_activeFraction.m, batchFetchCorrData, wholeBrain_corrData, wholeBrainActivityMapFig, wholeBrain_actvFractionMotorPlot
%
%James B. Ackman, 2013-11-15 16:19:06

%Cortical - motor signal xcorr

%Setup defaults: 
if nargin < 6 || isempty(rsFactor), rsFactor = 1; end

%Check for/Make motor signal:
if isfield(region,'motorSignal')
	if rsFactor ~=1
		decY2 = resample(region.motorSignal,1,rsFactor); 
	else
		decY2 = region.motorSignal; 
	end
else
	error('region.motorSignal not found')
end

if nargin < 5 || isempty(makePlots), makePlots = 0; end

%Cortical signal:
if nargin < 3 || isempty(st)
	clear st  
	st(1).str = {'HL.L' 'HL.R' 'T.L' 'T.R' 'FL.L' 'FL.R'};    
	st(2).str = {'M1.L' 'M1.R' 'M2.L' 'M2.R'};    
	st(3).str = {'barrel.L' 'barrel.R' 'AS.L' 'AS.R'};    
	st(4).str = {'barrel.L' 'barrel.R'};    
	st(5).str = {'RSA.L' 'RSA.R'};    
	st(6).str = {'PPC.L' 'PPC.R'};    
	st(7).str = {'V1.L' 'V1.R'};    
	st(8).str = {'V2L.L' 'V2L.R' 'V2M.L' 'V2M.R'};    
	st(9).str = {'V2L.L' 'V2L.R' 'V2M.L' 'V2M.R' 'V1.L' 'V1.R'};    
	st(10).str = {'cortex.L' 'cortex.R'};
end

if nargin < 4 || isempty(exclude), 
	exclude = [];
	names{1} = 'motorSignal'; 
	for i = 1:length(st)
		names{i+1} = sprintf([repmat('%s-',1,size(st(i).str,2)-1),'%s'],st(i).str{:});  %format the string to have dashes inbetween
	end
else
%	exclude = {'cortex.L' 'cortex.R'}; 
	names = {'motorSignal' region.locationData.data.name};
	clear st
	for i = 1:length(exclude)
		names = names(~strcmp(names,exclude(i)));
	end
	for i = 1:length(names)-1
		st(i).str = names{i+1}
	end
end

if isfield(region,'userdata') & isfield(region.userdata,'motorCorr')
	datasetSelector = length(region.userdata.motorCorr) + 1;
else	
	datasetSelector = 1;
end	
region.userdata.motorCorr{datasetSelector}.pvalCorrMatrix = ones(length(names),1);  %in case active regions are missing and we can't reject null hypothesis of no correlation.
region.userdata.motorCorr{datasetSelector}.rvalCorrMatrix = zeros(length(names),1);   
region.userdata.motorCorr{datasetSelector}.names = names;
i = (1:length(names))';
j = ones(length(names),1);
region.userdata.motorCorr{datasetSelector}.corr_pairs{1} = [i j];  

[r,p]=corrcoef(decY2,decY2);
region.userdata.motorCorr{datasetSelector}.pvalCorrMatrix(1,1) = p(2,1);
region.userdata.motorCorr{datasetSelector}.rvalCorrMatrix(1,1) = r(2,1);

szZ = length(decY2);
cM = zeros(numel(st), 2*szZ-1);

%Make the plots:
for j = 1:numel(st)  
    str = st(j).str;  
    cActvFraction = zeros(1,region.domainData.CC.ImageSize(3));  
    for i = 1:numel(str)
		matchInd = find(strcmp({region.locationData.data.name},str{i}));
		if isempty(matchInd)
			break
		end      
        y1 = region.locationData.data(strcmp({region.locationData.data.name},str{i})).activeFractionByFrame;  
        %y1 = region.locationData.data(1).activeFractionByFrame;    
        cActvFraction = cActvFraction + y1;  
    end
    
	if isempty(matchInd)
		continue
	end      
      
    cActvFraction = cActvFraction ./ numel(str);

	if rsFactor ~=1
		cActvFraction = resample(cActvFraction,1,rsFactor); 
	end

    titleStr = str;  

    %-----Cortical -motor signal xcorr Plot code--------------------------------------
    x = cActvFraction - mean(cActvFraction);   %detrend the signals
    y = decY2 - mean(decY2);      %detrend the signals
	[c_sig,lags] = xcorr(x,y,'coeff');
	cM(j,:) = c_sig;   %Add these Rxy corr values for output     

	if makePlots > 0
		figure;        
		myColors = [0.3 0.3 0.3; 0 0.5 1];        
		set(gcf,'DefaultAxesColorOrder',myColors)        
		ax(1)=subplot(2,2,1);        
		[c_ww,lags] = xcorr(x,'coeff');        
		plot(lags,c_ww); title(['combined actvFraction']);    xlabel('lag (frame)'); ylabel('{R}_{x}')      

		ax(2)=subplot(2,2,2);        
		plot(lags,c_sig); title(['xcorr (x, y)']);     xlabel('lag (frame)'); ylabel('{R}_{xy}')

		ax(3)=subplot(2,2,3);        
		[c_ww,lags] = xcorr(y,'coeff');        
		plot(lags,c_ww); title(['motor activity']);    xlabel('lag (frame)'); ylabel('{R}_{y}')  

		ax(4)=subplot(2,2,4);        
		[c_ww,lags] = xcorr(y,x,'coeff');        
		plot(lags,c_ww); title(['xcorr (y, x)']);     xlabel('lag (frame)'); ylabel('{R}_{yx}')        
		hold all      
		
		m1 = mean(x);        
		sd1 = std(x);         
		m2 = mean(y);        
		sd2 = std(y);       

		ww = m1 + (sd1.*randn(numel(x),1));        
		ww2 = m2 + (sd2.*randn(numel(x),1));      

		[c_ww,lags] = xcorr(ww,ww2,'coeff');        
		plot(lags,c_ww)      

		axis(ax,'tight','square')        
		set(ax,'XGrid','on','YGrid','on')        
		set(ax,'YLim', [0 1])        
		%set(ax,'XLim', [-1500 1500])        
		%set(ax,'XLim', [-250 250])   

		annotation('textbox', [.03 .8, .1, .1], 'String', titleStr);
		print(gcf,'-dpng',[fnm(1:end-4) 'motorSignalXCorr' datestr(now,'yyyymmdd-HHMMSS') '.png'])            
		print(gcf,'-depsc',[fnm(1:end-4) 'motorSignalXCorr' datestr(now,'yyyymmdd-HHMMSS') '.eps'])    
	end

	disp('===xy pearson corr coef===')    
	disp(titleStr)
	[r,p]=corrcoef(x,y), disp(['p(2,1) = ' num2str(p(2,1))])  
	region.userdata.motorCorr{datasetSelector}.pvalCorrMatrix(j+1,1) = p(2,1);
	region.userdata.motorCorr{datasetSelector}.rvalCorrMatrix(j+1,1) = r(2,1);

	if makePlots > 0
		%---Cortical - motor signal activeFraction plot code------------------------------  
		wholeBrain_actvFractionMotorPlot(region,cActvFraction,decY2,1,titleStr)  
		%Print fig-- print doesn't like the legend outside of axes for some reason, doesn't print...!      
		print(gcf,'-dpng',[fnm(1:end-4) 'motorSignalDetect' datestr(now,'yyyymmdd-HHMMSS') '.png'])            
		print(gcf,'-depsc',[fnm(1:end-4) 'motorSignalDetect' datestr(now,'yyyymmdd-HHMMSS') '.eps'])   
	
		%---Power spectrum--- 
		Fs = 1/region.timeres;
		PxxM = myPSD(x,1,Fs);
		title(titleStr)
		print(gcf,'-dpng',[fnm(1:end-4) 'PSD' datestr(now,'yyyymmdd-HHMMSS') '.png'])            
		print(gcf,'-depsc',[fnm(1:end-4) 'PSD' datestr(now,'yyyymmdd-HHMMSS') '.eps'])   
    end
end 

if makePlots > 0
	titleStr='motorXcorrLags';
	imagesc(cM)
	colorbar
	names = region.userdata.motorCorr{datasetSelector}.names;
	names = names(~strcmp(names,'motorSignal'));
	set(gca,'YTick',[1:length(names)])
	set(gca,'YTickLabel',names)

	xticklabels = -szZ:25:szZ;  %make it centered around lag zero with 100 fr spacing
	xticks = linspace(1, size(cM, 2), numel(xticklabels));
	set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
	set(gca,'XLim',[-250 250] + szZ)  %set xlim to within 250fr of zeroth lag
	title(titleStr)
	zoom xon
	fnm2 = [fnm(1:length(fnm)-4) '_' titleStr '_' datestr(now,'yyyymmdd-HHMMSS')];    
	print(gcf,'-dpng',[fnm2 '.png'])            
	print(gcf,'-depsc',[fnm2 '.eps'])   
end

if makePlots > 0
Fs = 1/region.timeres;
PxxM = myPSD(y,1,Fs);
title('motorSignal')
print(gcf,'-dpng',[fnm(1:end-4) 'PSD' datestr(now,'yyyymmdd-HHMMSS') '.png'])            
print(gcf,'-depsc',[fnm(1:end-4) 'PSD' datestr(now,'yyyymmdd-HHMMSS') '.eps'])   
end