function region = wholeBrain_CorticalActiveFractionCorr(fnm,region,names,xlimit)
%wholeBrain_CorticalActiveFractionCorr - Generate cross-correlation plots and values using active fraction signals for pairs of cortical areas
%Examples:
% region = wholeBrain_CorticalActiveFractionCorr(fnm,region)
% region = wholeBrain_CorticalActiveFractionCorr(fnm,region,st)
%**USE**
% fnm - .mat filename, from which filenames for plots will be saved (nothing will be overwritten) 
% region - region data structure with region.locationData.data structure returned from wholeBrain_activeFraction.m
% names - a cell array of 2 strings, e.g. {'cortex.L' 'cortex.R'} representing the two nodes you want to perform xcorr on
% xlimit - numeric, no. of frames (lags) to display in xcorr plot around the center
%Output:
%region - will print correlation results to command line. Return region data structure with corr data at region.userdata.corticalCorr. Will also display corr plots with activeFraction traces.
%
% See also wholeBrain_activeFraction.m, batchFetchCorrData, wholeBrain_corrData, wholeBrainActivityMapFig, wholeBrain_actvFractionMotorPlot
%
%James B. Ackman, 2013-11-15 16:19:06

%Cortical - cortical signal xcorr

%Setup defaults: 

if nargin < 4 || isempty(xlimit), xlimit = round(300/region.timeres); end  %1500 frames with a 0.2sec frame period    

if nargin < 3 || isempty(names)
	names = {'cortex.L' 'cortex.R'};
end

if isfield(region,'userdata') & isfield(region.userdata,'corticalCorr')
	datasetSelector = length(region.userdata.corticalCorr) + 1;
else	
	datasetSelector = 1;
end	

%Setup the signals:
data = region.locationData.data;
x = region.locationData.data(strcmp({region.locationData.data.name},names{1})).activeFractionByFrame;  
y = region.locationData.data(strcmp({region.locationData.data.name},names{2})).activeFractionByFrame; 

%Get the corr value:
[r,p]=corrcoef(x,y);
region.userdata.corticalCorr{datasetSelector}.pvalCorrMatrix = p;
region.userdata.corticalCorr{datasetSelector}.rvalCorrMatrix = r;
region.userdata.corticalCorr{datasetSelector}.corr_pairs{1} = [1 2];
region.userdata.corticalCorr{datasetSelector}.names = names;

%Make the plots:
figure;    
myColors = [0.3 0.3 0.3; 0 0.5 1];    
set(gcf,'DefaultAxesColorOrder',myColors)    
ax(1)=subplot(2,2,1);    
[c_ww,lags] = xcorr(x,'coeff');    
plot(lags,c_ww); title(['autocorr (' names{1} ')']);    xlabel('lag (frame)'); ylabel('{R}_{x}')    

ax(2)=subplot(2,2,2);    
[c_ww,lags] = xcorr(x,y,'coeff');    
plot(lags,c_ww); title(['xcorr (' names{1} ', ' names{2} ')']);     xlabel('lag (frame)'); ylabel('{R}_{xy}')    

ax(3)=subplot(2,2,3);    
[c_ww,lags] = xcorr(y,'coeff');    
plot(lags,c_ww); title(['autocorr (' data(2).name ')']);    xlabel('lag (frame)'); ylabel('{R}_{y}')

ax(4)=subplot(2,2,4);    
[c_ww,lags] = xcorr(y,x,'coeff');    
plot(lags,c_ww); title(['xcorr (' names{2} ', ' names{1} ')']);     xlabel('lag (frame)'); ylabel('{R}_{yx}')    
hold all    

m1 = mean(x);    
sd1 = std(x);     
m2 = mean(y);    
sd2 = std(y);     

ww = m1 + (sd1.*randn(length(x),1));    
ww2 = m2 + (sd2.*randn(length(x),1));    

[c_ww,lags] = xcorr(ww,ww2,'coeff');    
plot(lags,c_ww)    

axis(ax,'tight','square')    
set(ax,'XGrid','on','YGrid','on')    
set(ax,'YLim', [0 1])
set(ax,'XLim', [-xlimit xlimit])    
%set(ax,'XLim', [-250 250])   
print(gcf, '-dpng', [fnm(1:end-4) 'corticalXcorr' datestr(now,'yyyymmdd-HHMMSS') '.png']); 
print(gcf, '-depsc', [fnm(1:end-4) 'corticalXcorr' datestr(now,'yyyymmdd-HHMMSS') '.eps']);  

%---Power spectrum--- 
Fs = 1/region.timeres;
PxxM = myPSD(x,1,Fs);
title(names{1})
print(gcf,'-dpng',[fnm(1:end-4) 'PSD1' datestr(now,'yyyymmdd-HHMMSS') '.png'])            
print(gcf,'-depsc',[fnm(1:end-4) 'PSD1' datestr(now,'yyyymmdd-HHMMSS') '.eps'])   

%---Power spectrum--- 
Fs = 1/region.timeres;
PxxM = myPSD(y,1,Fs);
title(names{2})
print(gcf,'-dpng',[fnm(1:end-4) 'PSD2' datestr(now,'yyyymmdd-HHMMSS') '.png'])            
print(gcf,'-depsc',[fnm(1:end-4) 'PSD2' datestr(now,'yyyymmdd-HHMMSS') '.eps'])   
