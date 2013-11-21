function [index] = detectMotorOnsets(region)

%James B. Ackman 2013-04-01 - 2013-11-20 15:38:03

decY2 = region.motorSignal;

hFig = figure;
scrsize = get(0,'screensize');
set(hFig,'Position',scrsize);
set(hFig,'color',[1 1 1]);
set(hFig,'PaperType','usletter');
set(hFig,'PaperPositionMode','auto');
           
ax(1) = subplot(2,1,1);        
plot(decY2,'-'); ylabel('motor activity (uV)'); title('bp/rect/dec/motor signal')    
xlabel('Time (image frame no.)');     

mdn=median(abs(decY2));    
sd1=mdn/0.6745;    
thr = 2*sd1;    
line([0 length(decY2)],[thr thr],'LineStyle','--','color','r');    
thr = 1*sd1;    
line([0 length(decY2)],[thr thr],'LineStyle','--','color','g');    
legend({'decY2' '2sd mdn' '1sd mdn'})    

dfY2 = diff(decY2);  
mdn=median(abs(dfY2));    
sd1=mdn/0.6745;    
%sd1 = abs(std(dfY2));  
thr = 2*sd1;    

ax(2) = subplot(2,1,2)  
plot([dfY2 0], '-')  
line([0 length(decY2)],[thr thr],'LineStyle','--','color','r');  
line([0 length(decY2)],[-thr -thr],'LineStyle','--','color','r');    
thr = 1*sd1;    
line([0 length(decY2)],[thr thr],'LineStyle','--','color','g');    
line([0 length(decY2)],[-thr -thr],'LineStyle','--','color','g');    

deadTime = 500;  
[index thr] = mySpikeDetect(dfY2, 5, 2*sd1, deadTime);  % dead time for spikes and artifacts in msec  
%line([0 x1(end)],[thr thr],'LineStyle','--','color','r');  
hold on;  
plot(index, dfY2(index),'or')  
%xlim([0 xaxisMax])  
%index1=index;  
legend({'diff(decY2)' '2sd mdn' '1sd mdn' ['spkDet,' num2str(deadTime) 'msWin']})    

zoom xon     
linkaxes(ax,'x')