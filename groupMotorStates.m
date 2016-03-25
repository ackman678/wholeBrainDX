function groupMotorStates(filelist,makePlots)
%groupMotorStates - Group motor movement signals together (e.g. concatenate recordings by animal) and estimate statistics for motor onset and state transition thresholds
%Examples:
% >> groupMotorStates(filelist);
%
%**USE**
%Must provide one input:
%
%(1) table with desired filenames (space delimited txt file, with full filenames in first column)
%files.txt should have matlab filenames in first column.
%can have an extra columns with descriptor/factor information for the file. This will be the rowinfo that is attached to each measure observation in the following script.
%filelist = readtext('files.txt',' '); %grab readtext.m file script from matlab central
%
% See also wholeBrain_motorSignal, mySpikeDetect, batchFetchStimResponseProps, batchFetchMotorStates, detectMotorStates, rateChannels, makeMotorStateStimParams
%
%James B. Ackman, 2016-03-24 15:25:12


%function groupBatch(filelist)
%the following assumes that the filelist cell array you've provided has no column headers and 3 columns, where column1 is your .tif movie filename, column2 is the fullpath filename to dummyAreas.mat, column3 is a unique animal grouping factor: i.e. recording date tagged with animal number (e.g. 120518_1)
%filelist = readtext('files.txt',' ');

if nargin < 2 || isempty(makePlots), makePlots = 1; end
if size(filelist,2) < 3
	error('filelist not formatted correctly for catMotorTraces')
else
	dataFnms = filelist(:,2);
	groupingFactor = filelist(:,3);
end

groupNames = unique(groupingFactor);
ngroups = length(groupNames);
groupnum = 0; 
while groupnum < ngroups
	groupnum = groupnum + 1;
	fnms = dataFnms(strcmp(groupNames(groupnum), groupingFactor));
	handles = catMotorTraces(fnms)
end


function handles = catMotorTraces(fnms,printFig)
if nargin < 2 || isempty(printFig), printFig = 0; end
maxframes = 6000; %holder variable for maximum no. of frames in movie. 
nmovies = length(fnms);
catTrace = NaN(maxframes,nmovies);
for j=1:nmovies
    load(fnms{j});  %load the dummy file at fnms{j} containing parcellations, motor signal, etc
    sprintf(fnms{j})    
    nframes = numel(region.motorSignal);
    catTrace(1:nframes,j) = region.motorSignal;
end

npts = numel(find(~isnan(catTrace)));
catTrace2 = zeros(npts,1);
ind1=1;
for j=1:nmovies
    ind = find(~isnan( catTrace(:,j) ));
    indLast = ind(end);
    ind2 = ind1+indLast-1;
    catTrace2(ind1:ind2,1) = catTrace(1:indLast,j);
    ind1=ind2+1;
end

catTrace2 = catTrace2';
region.motorSignal = catTrace2;  %assign grouped motor trace to a dummy region data structure temporarily to get grouped stats below

%Detect and add motor.onsets to region.stimuli
nsd=2;
[spks,groupRawThresh,groupDiffThresh] = detectMotorOnsets(region,nsd,[],[],0);
region = makeStimParams(region, spks, 'motor.onsets', 1); 

handles.groupRawThresh = groupRawThresh; %save this threshold of raw motor trace for detection of id. file motor onsets later
handles.groupDiffThresh = groupDiffThresh; %save this threshold on derivative of motor trace for detection of id. file motor onsets later
handles.nsd = nsd; %save no. of sd used for reference
handles.groupRawMedian = median(catTrace2);
handles.groupRawMean = mean(catTrace2);
handles.groupRawSD = std(catTrace2);

if printFig
	hFig = figure;
    scrsize = get(0,'screensize');
    set(hFig,'Position',scrsize);
    set(hFig,'color',[1 1 1]);
    set(hFig,'PaperType','usletter');
    set(hFig,'PaperPositionMode','auto');
    
    plot(catTrace2,'-'); ylabel('motor activity (uV)'); title('bp/rect/dec/motor signal')    
    xlabel('Time (image frame no.)');     
    line([0 length(catTrace2)],[thrN thrN],'LineStyle','--','color','r');       
    line([0 length(catTrace2)],[thr1 thr1],'LineStyle','--','color','g');    
    legend({'catTrace2' [num2str(nsd) 'sd mdn'] '1sd mdn'})  
    hold on  
	plot(spks, catTrace2(spks),'og')

	fnm = fnms{j};
	print(gcf,'-dpng',[fnm(1:end-4) 'motorSignal-cat' datestr(now,'yyyymmdd-HHMMSS') '.png'])            
	print(gcf,'-depsc',[fnm(1:end-4) 'motorSignal-cat' datestr(now,'yyyymmdd-HHMMSS') '.eps']) 
end

%Detect and add motor.states to region.stimuli
maxlagsAll = 50:10:150; 
rateChan = rateChannels(region,[],0,[],maxlagsAll);

if printFig
	print(gcf,'-dpng',[fnm(1:end-4) 'motorSignalDetect' datestr(now,'yyyymmdd-HHMMSS') '.png'])        
	print(gcf,'-depsc',[fnm(1:end-4) 'motorSignalDetect' datestr(now,'yyyymmdd-HHMMSS') '.eps']) 
end


if printFig
	hFig = figure;
	scrsize = get(0,'screensize');
	set(hFig,'Position',scrsize);
	set(hFig,'color',[1 1 1]);
	set(hFig,'PaperType','usletter');
	set(hFig,'PaperPositionMode','auto');
end
j = 0;
sw = 0;
while sw == 0
    j = j + 1;
    disp(j)
    x = rateChan(j).y;
    xbar = mean(x);
    xsd = std(x);
    x(x<xbar) = 0;
    dfY = [diff(x) 0];

	if printFig
	    ax(1) = subplot(2,1,1)  
	    %plot(x, '-')  
	    plot(decY2, '-')  
	    hold on; 
	    line([0 length(x)],[xbar xbar],'LineStyle','--','color','r');

	    ax(2) = subplot(2,1,2)  
	    plot(x, '-')  
	    hold on; 
	    line([0 length(x)],[xbar xbar],'LineStyle','--','color','r');
	    plot(dfY, '-k')

	    zoom xon     
	    linkaxes(ax,'x')
	end

    ons = find(dfY > xbar); ons = ons+1;
    offs = find(dfY < -xbar);
    if ons(1) > offs(1)
        offs = offs(2:end);
    end

	% if no. of onsets not equal to offsets, try removing the first offset (in case detected in beginning of movie)
    if numel(ons) ~= numel(offs)
        offs = [offs numel(x)];
    end

    % if no. of onsets are still not equal to offsets, try the next smoothened rateChan trace
    if numel(ons) ~= numel(offs)
        %error('Number of onsets not equal to number of offsets')
        warning('Number of onsets not equal to number of offsets, continue to next rateChan')
        continue
    end

    idx1=[];
    idx2=[];
    for i=1:length(ons)
        %disp(ons(i))
        tf = ismember(spks,ons(i):offs(i));
        ind = find(tf);
        if isempty(ind)
            idx1 = [idx1 ons(i)];
            idx2 = [idx2 offs(i)];
        else
            idx1 = [idx1 spks(ind(1))];
            if ind(end) ~= ind(1)
                idx2 = [idx2 spks(ind(end))];
            else
                %idx2 = [idx2 spks(ind(end))+1];  %add max([val length(trace)]) algorithm
                idx2 = [idx2 offs(i)];
            end
        end
    end
    sw = 1;

	if printFig
        plot(ax(1), ons, decY2(ons),'or')
        plot(ax(1), offs, decY2(offs),'ok')
        plot(ax(2), ons, x(ons),'or')
        plot(ax(2), offs, x(offs),'ok')
        hold off

        plot(ax(1), idx1, decY2(idx1),'og')
        plot(ax(1), idx2, decY2(idx2),'ob')
        hold off
    end
end

handles.rateChanNum = j;
handles.rateChanMean = xbar;
handles.rateChanSD = xsd;
handles.rateChanMaxlagsAll = maxlagsAll;

for j=1:nmovies
    load(fnms{j},'region');  %load the dummy file at fnms{j} containing parcellations, motor signal, etc
	region.motorSignalGroupParams = handles; 
    save(fnms{j},'region','-v7.3');  %load the dummy file at fnms{j} containing parcellations, motor signal, etc
end

