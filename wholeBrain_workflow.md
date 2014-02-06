Date: 2014-02-04 10:51:07  
Author: James B. Ackman  
Tags: analysis, wholeBrain, programming, matlab 

# wholeBrain workflow

## Prep files

* (1) Open AVG-raw.tif image (saved previously with dFoF.avi for each raw .tif movie) and made cortex.L and cortex.R outlines for each file and saved as roi set .zip file from ImageJ. The following macro code snippets can be copied and run from the ImageJ macro interpreter in Fiji to ease this process:  

	```javascript
	//Flip ImageJ ROI horizontally
	//# Get max xcoord value for horizontal roi flip
	print ("\\Clear");
	getSelectionCoordinates(x,y);
	v = x;
	for (i=0; i<v.length; i++) print(v[i]);  
	//Sort and print array, get max x value
	arr = x;
	sortedValues = Array.copy(arr);
	Array.sort(sortedValues);
	Array.reverse(sortedValues);
	mx = sortedValues[0];
	print("sorted array:");
	v = sortedValues;
	for (i=0; i<v.length; i++) print(v[i]);  
	print("max value:");
	print(mx);
	//#Make array with new flipped xcoord values:
	print("new values:")
	v = Array.copy(arr);
	for (i=0; i<v.length; i++) {
	  //print(v[i]);
	  dx = mx - v[i];
	  v[i] = v[i] + 2*dx;  
	  print(v[i]);
	}
	//#Make new selection based on the flipped coords: 
	makeSelection("polygon", v, y);


	//Move ImageJ ROI horizontally
	dx = 25; //no. of pixels to move ROI
	dy = 5;
	getSelectionCoordinates(x,y);
	for (i=0; i<x.length; i++) {
	  x[i] = x[i] + dx;
	  y[i] = y[i] + dy;  
	  //print(x[i]);
	}
	makeSelection("polygon", x, y);


	//Scale ImageJ ROI
	factor = 1.97; //scaling factor
	//factor = getNumber("Factor", 0.5);
	getSelectionCoordinates(x,y);
	for (i=0; i<x.length; i++) {
		x[i] = (x[i] * factor) - 640;
		y[i] = (y[i] * factor) - 540;
	}
	makeSelection("polygon", x, y);
	```


* (2) Opened up the AVG-raw.tif image for each of the following in `calciumdx` and saved a dummy file with single region named 'field' encompassing whole field of view and a single manual dummy roi (so the file saves correctly) to save a 'dummyHemis.mat' file for each.  Be sure to know the spatial and temporal resolutions of your data before progressing with this step (region.spaceres and region.timeres).
* (3) Make space-delimited filelist names 'files.txt' of the raw .tif movie filenames (1st column) and matching dummy filenames and save in same directory as your dummyHemis.mat files and the raw movie files.
* (4) Bootup local copy of matlab and cd into the directory containing the files. Setup region file and add ImageJ roi coordinate outlines for the hemispheres.  Do the following for each file independently, change fnms to the appropriate filenames.

	```matlab
	%matlab
	addpath(genpath('~/Documents/MATLAB/sigTOOL'))
	addpath(genpath('~/Documents/MATLAB/physioDX'))

	filelist = readtext('files.txt',' ');
	fnms = filelist(:,2);  %Second column is dummy region matfiles

	%To make dummyHemis for 1st run through
	for i = 1:numel(fnms)
		fnm = fnms{i};
		load(fnm) 
		disp(['Please load Rois.zip file for ' fnm])
		region = myReadImageJROIregionAdd(region,'false');	
		region.stimuli = [];  
		region.motorSignal = [];  
		region.nframes = 3000;  	
		save(fnm,'region') 
	end

	%To make dummyAreas for 2nd run through
	for i = 1:numel(fnms)
		fnm = fnms{i};
		load(fnm);
		disp(['Please load Rois.zip file for ' fnm])
		region = myReadImageJROIregionAdd(region,'false');	

		strOrder = {'field' 'cortex.L' 'cortex.R' 'V1.L' 'V1.R' 'V2M.R' 'V2M.L' 'V2L.R' 'V2L.L' 'A1.L' 'A1.R' 'barrel.L' 'barrel.R' 'AS.L' 'AS.R' 'PPC.L' 'PPC.R' 'LS.L' 'LS.R' 'FL.L' 'FL.R' 'HL.L' 'HL.R' 'T.L' 'T.R' 'RSA.L' 'RSA.R' 'M1.L' 'M1.R' 'M2.L' 'M2.R'};
		names2 = region.name;
		coords2 = region.coords;
		for i = 1:length(strOrder)
			idx=find(strcmp(region.name,strOrder{i}));
			names2{i} = region.name{idx};
			coords2{i} = region.coords{idx};
		end
		if length(strOrder) ~= length(region.name)
			error('strOrder not same length as region.name') 
		end
		region.name=names2;
		region.coords=coords2;
		fnm = [fnm(1:end-9) 'Areas.mat'];
		save(fnm,'region') 
	end	

	%Grep find and replace 'dummyHemis' for 'dummyAreas' in 'files.txt'	

	filelist = readtext('files.txt',' ');
	fnms = filelist(:,2);  %Second column is dummy region matfiles

	%====Domain Tagging 2014-01-24 15:34:35==============================
	%Do domain artifact detection tagging and duration plotting
	%Do batches of files that you may want to have the same xy positions on the blackout list
	%
	% Option 1: If each recording is the same exact FOV, can do domainTagging for one with artifacts, and use borders for rest of movies in a for loop
	% Option 2: Or can do multiple movies and manually concatentate the borders together for a merged set of borders
	% 		* Could also implement an xy shift strategy for the border coords for movie to movie shifts in FOV, but probably safer to do over for each shift in movie FOV
	%


	% For individual files:
	k = 1;  %Change no. to the fnms in list you want to use. 
	disp(['Please load the region d2r data file for ' fnms{k}])
	%load previous region data file with domains tagged or use domainTaggingGui to fetch data().frame() xy centroid locations for artifacts
	[filename, pathname] = uigetfile({'*d2r.mat'}, 'Choose region data file to open');
	f = fullfile(pathname,filename);
	load(f);
	domainTaggingGui(region)
	
	load(fnms{k},'region')   %load new dummyAreas file
	if exist('taggedCentrBorders','var')
		if isfield(region, 'taggedCentrBorders')
			region.taggedCentrBorders = [region.taggedCentrBorders taggedCentrBorders];
		else
			region.taggedCentrBorders = taggedCentrBorders;
		end
		save(fnms{k},'region')  %save new dummyAreas file with the marked borders for tagging
	end
	
	% For a bunch of files:
	for k = 1:numel(fnms)
	%	for k = [1 6 7 8]
	%		clear data

		disp(['Please load the region d2r data file for ' fnms{k}])
		%load previous region data file with domains tagged or use domainTaggingGui to fetch data().frame() xy centroid locations for artifacts
		[filename, pathname] = uigetfile({'*d2r.mat'}, 'Choose region data file to open');
		fnm = fullfile(pathname,filename);
		load(fnm);
		domainTaggingGui(region)	
		h = gcf;
		waitfor(h)
		save(fnm,'region')
	
	%Optional, domainsPatchesPlot (doesn't work on hpc):  
	%	for plotType = [1 3 4 5];
	%		fnm2 = [fnm(1:end-4) 'domainPatchesPlot' datestr(now,'yyyymmdd-HHMMSS') '.mat'];
	%		DomainPatchesPlot(region.domainData.domains, region.domainData.CC, region.domainData.STATS,plotType,[],1,region)
	%		print(gcf, '-dpng', [fnm2(1:end-4) '-' datestr(now,'yyyymmdd-HHMMSS') '.png']);      
	%		print(gcf, '-depsc', [fnm2(1:end-4) '-' datestr(now,'yyyymmdd-HHMMSS') '.eps']);
	%		end
	end	
	```

* (5) Optional:  
	* Run `sigTOOL` from matlab and use `Batch Import` in the sigTOOL gui to convert each Spike2.smr file into a .kcl data file for use with sigTOOL for simultaneously acquired signals like motorSignal from photodiode or electrophysiology signals.  
		* Export motor signal from spike2, make filtered signal for dummyfile, and detect motor active periods and save in dummyfile for each movie  
		* Add other stimuli info to dummy file, using makeMotorStateStimParams.m and makeDrugStateStimParams.m  
		* Save region fnm  

	```matlab
	fnm = fnms{11};  %***change to desired filename***
	load(fnm,'region')

	mySTOpen  %open each .kcl file	
	fhandle = 1;
	myBatchFilter(fhandle,1,[], 1,8,'ellip', 'band') %bandpass1 - 20Hz. The motor signal is in this band, with a little bit of respiratory rate signal (but attenuated).

	chanNum = 3;
	region = wholeBrain_motorSignal(fhandle, region, chanNum);
	print(gcf,'-dpng',[fnm(1:end-4) 'motorSignal' datestr(now,'yyyymmdd-HHMMSS') '.png'])            
	print(gcf,'-depsc',[fnm(1:end-4) 'motorSignal' datestr(now,'yyyymmdd-HHMMSS') '.eps']) 
	save(fnm,'region')

	%Detect and add motor.onsets to region.stimuli
	[index] = detectMotorOnsets(region);
	region = makeStimParams(region, index, 'motor.onsets'); 
	print(gcf,'-dpng',[fnm(1:end-4) 'motorSignal' datestr(now,'yyyymmdd-HHMMSS') '.png'])            
	print(gcf,'-depsc',[fnm(1:end-4) 'motorSignal' datestr(now,'yyyymmdd-HHMMSS') '.eps']) 

	%Detect and add motor.states to region.stimuli
	rateChan = rateChannels(region);
	print(gcf,'-dpng',[fnm(1:end-4) 'motorSignalDetect' datestr(now,'yyyymmdd-HHMMSS') '.png'])        
	print(gcf,'-depsc',[fnm(1:end-4) 'motorSignalDetect' datestr(now,'yyyymmdd-HHMMSS') '.eps']) 

	%rateChannels(5).y is the 250fr lag returned from the moving average rate channel code above for filtfilt on decY2  
	deltaspacing = 100; %in seconds  
	[motorOns, motorOffs] = detectMotorStates(region, rateChan(5).y, deltaspacing);   
	%make manual corrections using gui if needed, i.e. motorOns(1) = 1; motorOffs(1) = 123; motorOffs(4) = 3000;

	region = makeMotorStateStimParams(region, motorOns, motorOffs);
	save(fnm,'region')

	print(gcf,'-dpng',[fnm(1:end-4) 'motorSignalDetect' datestr(now,'yyyymmdd-HHMMSS') '.png'])        
	print(gcf,'-depsc',[fnm(1:end-4) 'motorSignalDetect' datestr(now,'yyyymmdd-HHMMSS') '.eps']) 

	%---------------------------------------------------------------------------
	%**Optional, if a drug movie
	region = makeDrugStateStimParams(region, [1], [3000], 'isoflurane') %where the frame indices inputs are drugOns and drugOffs
	save(fnm,'region')
	```


## Run batch analysis

* (6) Sync dummy and data files to NAS data server from local computer and to matlab location for analysis (either local PC or HPC).
* (7) Run the batch script. Perform within the folder containing the data files and 'files.txt':    

	```matlab
	matlabpool close force local
	matlabpool open 8          
	diary on
	disp(datestr(now,'yyyymmdd-HHMMSS'))
	handles.makeMovies = 'all';
	%handles.makeMovies = 'some';
	wholeBrain_batch('files.txt',handles)
	disp(datestr(now,'yyyymmdd-HHMMSS'))
	diary off
	```

* (8) Optional: Run the batch script for multiple experiments, using a 'files.txt' inside each experiment folder:  

	```matlab
	% Multiple directories
	matlabpool close force local
	matlabpool open 8
	dirpath = '/scratch2/netid/';
	dirnames = {'folder1/'  'folder2/'  'folder3/'};
	beginT = datestr(now,'yyyymmdd-HHMMSS');
	for i = 1:length(dirnames)
	currdir = fullfile(dirpath,dirnames{i});
	cd(currdir)
	diary on
	disp(datestr(now,'yyyymmdd-HHMMSS'))
	wholeBrain_batch('files.txt')
	disp(datestr(now,'yyyymmdd-HHMMSS'))
	diary off
	end
	endT = datestr(now,'yyyymmdd-HHMMSS');
	disp(['Job start: ' beginT])
	disp(['Job end: ' endT])
	```



## Optional plots

plotWholeBrainDomainsTraces
: gui for comparing and assessing detection and for viewing movie with motor traces  

plotWholeBrainDomainsTraces:  

```matlab
%--Create 8bit avi in ImageJ of dF/F movie first or use .avi from wholeBrain_segmentation.m
%--In matlab, use 'VideoReader' to make 8bit movie object structure and return frames from the .avi of the raw movie (so we can full frame res, array in memory locally)

fnm = '_d2r.mat'  %d2r.mat file from wholeBrain_batch
fnm2 = 'dFoF.avi' %.avi file from wholeBrain_segmentation.m or _kmeans.m
vidObj = VideoReader(fnm2);   %TODO: change this to desired .avi to read in
nFrames = vidObj.NumberOfFrames;
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
%--Preallocate movie structure----------------------------------------------------
mov(1:nFrames) = ...
	struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
		   'colormap', []);
%--Read one frame at a time, takes awhile if it's jpeg compressed avi-------------
for fr = 1 : nFrames
	mov(fr).cdata = read(vidObj, fr);
end
%--Make 8bit movie array----------------------------------------------------------
sz = size(mov(1).cdata);
A = zeros([sz(1) sz(2) nFrames], 'uint8');
for fr = 1:nFrames
	[im,map] = frame2im(mov(fr));
	im1 = im(:,:,1);
	A(:,:,fr) = im1;
end
clear mov vidObj im im1
%--Prep plots and titles for gui--------------------------------------------------
load(fnm,'region')
%load(fnm3,'A3')
movieTitles{1} = 'dF/F+60px diskBkgndSubtr avi';  
movieTitles{2} = 'kmeans detect';   
movieTitles{3} = 'active fraction';  
movieTitles{4} = 'motor activity signal';
decY2 = region.motorSignal;
plot4(1).data=decY2;     %setup a default plot structure for the rectified/decimated photodiode motor signal  
plot4(1).legendText = ['rectDecMotorSig'];  
plot4(1).Fs=1;   %sampling rate (Hz).  Used to convert data point indices to appropriate time units.  Leave at '1' for no conversion (like plotting the indices, 'frames')  
plot4(1).unitConvFactor = 1; 
%--Make binary mask movie------------------------------------------------------------------------
sz=region.domainData.CC.ImageSize;        
tmp = zeros(sz,'uint8');        
A3 = logical(tmp);        
clear tmp;      
for i = 1:region.domainData.CC.NumObjects      
	if ~strcmp(region.domainData.STATS(i).descriptor, 'artifact')    
		A3(region.domainData.CC.PixelIdxList{i}) = 1;      
	end          
end
%--Run gui------------------------------------------------------------------------
plotWholeBrainDomainsTraces(A,A3,region,plot4,movieTitles,[])  	
```

domainTagginGui
: gui for marking domains

domainTagginGui:  

	domainTaggingGui(region) %will export region with STATS.descriptor for artifact domains tagging automatically





## Outline of wholeBrain_batch

* A, A2 = wholeBrainSegmentation
* A3, CC, STATS, wholeBrain_kmeans
* domains = DomainSegmentationAssigment(CC,STATS,'false')
* region = domains2region(domains,CC,STATS,region, hemiindices)
	
* wholeBrainActiveFraction
	* print activefraction traces
	* copy activefraction output
* Fetch region.userdata.corr using corrcoef for network correlations
* Fetch pearsons ML, AP correlations between hemispheres
* Fetch pearsons, autocorr, xcorr motor signal correlations
* plots
	* activeFraction from above
	* wholeBrainActivityMapFig
	* wholeBrain_actvFractionMotorPlot
	* corr matrix
* datasets
	* batchFetchDomainProps
	* batchFetchLocationProps
	* batchFetchLocationPropsFreq
	* batchFetchCorrData
	* batch output for motor - cortical signal xcorr  
	* batch output for ML, AP correlations  
