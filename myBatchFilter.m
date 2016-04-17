function channels=myBatchFilter(fhandle,channelsToFilter,fname, Fc, N, filterName, filterType)
%channels=myBatchFilter(fhandle,channelsToFilter,fname)

%fhandle is the figure handle for a sigTOOL figure object
%channelsToFilter is an optional vector of channel numbers from that figure you want to filter (1 or more)
%example
%channels = myBatchFilter(1,[2 4])
%channels = myBatchFilter(1,1,[],10)
%channels = myBatchFilter(1,1,[],10,5,'butter')
%channels = myBatchFilter(1,1,[],8,5,'ellip')

% scHistory m-file generated from sigTOOL.
% Author: Malcolm Lidierth © 2006 King's College London
% myBatchFilter by James B. Ackman, 2010-2013

if nargin < 4 || isempty(Fc), Fc = 300; end   %default good if signal of interest is neural spikes
if nargin < 5 || isempty(N), N = 5; end   
if nargin < 6 || isempty(filterName), filterName = 'ellip'; end   %default good if signal of interest is neural spikes
if nargin < 7 || isempty(filterType), filterType = 'high'; end   %default good if signal of interest is neural spikes

channels=getappdata(fhandle, 'channels');
Fs=getSampleRate(channels{channelsToFilter(1)});
sz=numel(channels);

%{
% Standard call to open file specified by first input argument
if nargin>=1
fhandle=sigTOOL(varargin{1});
else
error('%s: no input file was specified', mfilename())
end
%}
Hd=designFilt(Fs,Fc,N, filterName, filterType);
j=sz+1;

if nargin < 2
    for i=2:sz
        if ~isempty(channels{i})
            scFilter(fhandle, i, j, 1, Hd);
            j=j+1;
        end
    end
    % delete(fhandle);
else
    for i=1:length(channelsToFilter)
        if ~isempty(channels{channelsToFilter(i)})
            scFilter(fhandle, channelsToFilter(i), j, 1, Hd);

			clear channels
			channels=getappdata(fhandle, 'channels');
			channels{j}.hdr.title= [filterName filterType num2str(Fc) ',' num2str(N)];
			setappdata(fhandle, 'channels', channels);
			% % Refresh the channel manager
 			scChannelManager(fhandle, true); %comment out for 2014b temporary fix
			% % Include the new channel in the display
			scDataViewDrawChannelList(fhandle);
            
             if nargin > 2 && ~isempty(fname)
                 clear channels
                 channels=getappdata(fhandle, 'channels');
                 data.adc=channels{j}.adc(:,1);
                 data.tim=channels{j}.tim;
                 data.mrk=channels{j}.mrk;
                 hdr=channels{j}.hdr;
                 
                 vname=['chan' num2str(j)];
                 eval(sprintf('%s=data;',vname));
                 save(fname,vname,'-v6','-append');
                 
                 vname=['head' num2str(j)];
                 eval(sprintf('%s=hdr;',vname));
                 save(fname,vname,'-v6','-append');
             end
            
            j=j+1;
        end
    end
end

clear channels
channels=getappdata(fhandle, 'channels');

return
end

%--------------------------------------------------------------------------
function Hd=designFilt(Fs,Fc,N, filterName, filterType)
%Fs: sampling frequency
%Fc: filter cutoff frequency
%N: filter order

if nargin < 2 || isempty(Fc), Fc = 300; end   %default good if signal of interest is neural spikes
if nargin < 4 || isempty(filterName), filterName = 'ellip'; end   %default good if signal of interest is neural spikes
if nargin < 5 || isempty(filterType), filterType = 'high'; end   %default good if signal of interest is neural spikes
if nargin < 3 || isempty(N), 
	if strcmp(filterName,'ellip')
	N = 2;   %default recommended from sigTool for high band pass spike signals
	else
	N = 5; %default for butterworth highpass
	end
end


if strcmp(filterName,'butter')
% Butterworth Highpass filter designed using FDESIGN.HIGHPASS.
%------Butter filter------------------------------------
% % All frequency values are in Hz.
% % Fs=12500;
% % Fs=getSampleRate(channels{2});
% N  = 5;    % Order
% Fc = 300;  % Cutoff Frequency
% 
% % Construct an FDESIGN object and call its BUTTER method.
 h  = fdesign.highpass('N,F3dB', N, Fc, Fs);
 Hd = design(h, 'butter');
%-------------------------------------------------------
elseif strcmp(filterName, 'ellip')
%------Elliptical filter--------------------------------
%N = 2;
%Fc = 300;
%Fch = 3000;   %high cutoff frequency for biological signals  %default for spike signals in sigTOOL
%[z,p,k] = ellip(N,0.1,40,[Fc Fch]/(Fs/2));  %default for spike signals in sigTOOL
%[sos,g] = zp2sos(z,p,k);       % Convert to SOS form
%Hd = dfilt.df2tsos(sos,g);    % Create a dfilt object

%N = 5; Fc = 8; Fs = 25000; 

if strcmp(filterType,'band')
	Fch = 20;
	Rp = 1; Rs = 80;
	[z,p,k] = ellip(N,Rp,Rs,[Fc Fch]/(Fs/2));
	[sos,g] = zp2sos(z,p,k);       % Convert to SOS form
	Hd = dfilt.df2tsos(sos,g);    % Create a dfilt object
else
	Rp = 1; Rs = 80;
	[z,p,k] = ellip(N,Rp,Rs,[Fc]/(Fs/2),filterType);
	[sos,g] = zp2sos(z,p,k);       % Convert to SOS form
	Hd = dfilt.df2tsos(sos,g);    % Create a dfilt object

	%--For viewing the filter design, uncomment the following two lines--
	%hFv = fvtool(Hd); set(hFv,'Analysis','magnitude', 'Fs', Fs) 
	%set(gca,'XLim',[0 0.05],'YLim',[-100 0]); title(['ellip; Fc, N ' num2str(Fc) ', ' num2str(N)])
end

else
	error('not a valid filter name')
	return
end

end
%--------------------------------------------------------------------------
