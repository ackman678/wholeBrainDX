function region = wholeBrain_motorSignal(fhandle, region, chanNum)
%wholeBrain_motorSignal(fhandle, region, chanNum)
%fhandle - sigtool handle
%region - dummy file structure
% Author - James B. Ackman 2013-11-20 04:34:16

if nargin < 3 || isempty(chanNum), chanNum = 3; end %assumes the band pass filtered photodiode signal is on channel 3

channels=getappdata(fhandle, 'channels');  %sigtool function
Fs=getSampleRate(channels{1});  %25000 samples/sec.  %sigtool function
Fs_imaging = 1/region.timeres;  %typically around 5 samples (frames)/sec  
x = 1:length(channels{chanNum}.adc(:,1));
y = channels{chanNum}.adc(:,1)'; 

%--Decimate the signal
%Want to get sampling rate of motor signal equal to that of our imaging signal for downstream correlation analyses
%e.g. Ratio of Fs_ephs / Fs_imaging = 25000/5 = 5000;
%Decimate does a lowpass filter with a cutoff freq, Fc of 0.8*(Fs/2)/r, where r is the decimation factor. Ours is 5000, but the help says if the factor is more than 13 then better results are achieved by calling decimate several times.
%
%So to get a factor of 5000 reduction we can run 4 times, with r = 10, 10, 10, 5.

r =  Fs / Fs_imaging; %typically 5000 if Fs = 25000, and Fs_imaging = 5;
ri = floor(log10(r));  % this gives no. of decimation iterations with a decimation factor of 10  (10^ri = r) ==> log10(10^ri) = log10(r);
rRem = r/(10^ri); %this gives the decimation factor for the last iteration. e.g. if ri = 3, the decimation factors would be 10*10*10*rRem.  

if rem(rRem, 1) ~=0  %test whether remainder is an integer and if not fix the last two decimation factors, so that if ri was 3, the new factors would be 10*10*(10/(nrRem/rRem))*nrRem
	nrRem = ceil(rRem); 
	while mod(nrRem,rRem) ~= 0
		nrRem=nrRem+1;
	end
	ri = ri-1;
	rRem(1) = (10/(nrRem/rRem));
	rRem(2) = nrRem;
end

rectY = abs(y);    %rectify the signal
decY = rectY;
for i = 1:ri
	decY = decimate(decY,10);  
end
for i = 1:length(rRem)
	decY = decimate(decY,rRem(i));  
end
decX = 1:length(decY);  

hFig = figure;
scrsize = get(0,'screensize');
set(hFig,'Position',scrsize);
set(hFig,'color',[1 1 1]);
set(hFig,'PaperType','usletter');
set(hFig,'PaperPositionMode','auto');       
ax(1) = subplot(3,1,1);      
dsplot(x/Fs, y, [], hFig, ax(1));      
ax(2) = subplot(3,1,2);      
dsplot(x/Fs, rectY, [], hFig, ax(2));     
ax(3) = subplot(3,1,3);      
plot(decX/Fs_imaging,decY,'-')  
linkaxes(ax,'x')  
zoom xon

if isfield(region,'nframes')
	decY2=decY(1:region.nframes); 
else 
	decY2 = decY;
	error('region.nframes not found, motor signal likely not same length as movie')
end

decY2(decY2<0) = 0;
region.motorSignal = decY2;
