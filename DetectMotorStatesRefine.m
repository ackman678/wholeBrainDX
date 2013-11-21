function [motorOns,motorOffs,motorPks,motorMins] = DetectMotorStatesRefine(data,motorOns,motorOffs,motorPeaks,motorMins,handles)

if ~isempty(handles)
	ax = handles.axes_current;
else
	hFig = figure;
	scrsize = get(0,'screensize');
	set(hFig,'Position',scrsize);
	set(hFig,'color',[1 1 1]);
	set(hFig,'PaperType','usletter');
	set(hFig,'PaperPositionMode','auto');
	ax = subplot(1,1,1);
end

axes(ax)
%waveonsets
idx = motorPeaks;
plot(data(1,:));
hold on;
cpksmenu = uicontextmenu;
uimenu(cpksmenu, 'Label', 'Move Peak', 'Callback', 'hevMoveWavePeak');
uimenu(cpksmenu, 'Label', 'Add wave, 3clicks', 'Callback', 'hevAddWaveOnsetPeakOffset');
plot(idx,data(idx),'ok','uicontextmenu',cpksmenu);

minima = motorMins;
hold on
plot(minima,data(minima),'or');

%waveonsets----------------------------------------------------------------
wvonsets = motorOns;

cmenu = uicontextmenu;
uimenu(cmenu, 'Label', 'Move onset', 'Callback', 'hevMoveWaveOnset');
uimenu(cmenu, 'Label', 'Add wave (3 clicks)', 'Callback', 'hevAddWaveOnsetPeakOffset');
uimenu(cmenu, 'Label', 'Delete wave', 'Callback', 'hevDeleteWave');
plot(wvonsets,data(wvonsets),'og','uicontextmenu',cmenu);

%waveoffsets---------------------------------------------------------------
wvoffsets = motorOffs;

coffmenu = uicontextmenu;
uimenu(coffmenu, 'Label', 'Move offset', 'Callback', 'hevMoveWaveOffset');
uimenu(coffmenu, 'Label', 'Add wave, 3clicks', 'Callback', 'hevAddWaveOnsetPeakOffset');
plot(wvoffsets,data(wvoffsets),'ob','uicontextmenu',coffmenu);
hold off

ylabel('Motor activity filt (uV)'); grid minor
xlabel('Time (movie fr)')
linkaxes(handles.ax,'x'); zoom xon    
set(handles.ax,'YGrid','off') 


hmsgbox= msgbox('Press right click to change/add  event positions, close this dialog when finished...','','help');
uiwait(hmsgbox)

chi=get(gca,'Children');
xdata=get(chi,'XData');
idx1 = xdata{2};
idx2 = xdata{1};
idx = xdata{4};

%figure out if an offset was at last frame of movie (no. of onsets and offsets not equal)
if numel(idx1) ~= numel(idx2)
    button = questdlg('Number of onsets not equal to number of offsets (Event may be at end of movie). Set final offset to last frame of movie?');
    if strcmp(button,'Yes')
        idx2=[idx2 region.nframes];
    end
end

motorOns=idx1;
motorOffs=idx2;
motorPks=idx;
disp(['motorOns: ' num2str(idx1)])
