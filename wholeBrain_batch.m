function wholeBrain_batch(filename)
%wholeBrain_batch - A batch processing script for wholeBrain paper
%Examples:
% >> wholeBrain_batch('files.txt')
%
%**USE**
%Must provide one input:
%
%(1) table name with desired filenames (space delimited txt file, with full filenames in first column)
%files.txt should have TIFF movie filenames in first column, dummy region matlab filenames in second column
%can have an extra columns with descriptor/factor information for the file. This will be the rowinfo that is attached to each measure observation in the following script.
%depends on  readtext.m file script from matlab central -  readtext('files.txt',' ');
%
% Check the workflow sequence below at wholeBrain_workflow(). Briefly it is:
%	1. Segmentation
%	2. Detection
%	3. Format domain data structures
%	4. Get active fraction signals
%	5. Get correlation matrix and plots
%	6. Get cortical - motor corr results and plots
%	7. Get spatial correlation results and plots
%	8. Make contour activity maps
%	9. Batch fetch datasets
%
%Output:
%Everything is automatically saved. 
%	* A list of processed .mat files with data structures will be saved at filesOutput_*YYYYMMDD-HHMMSS*.txt.
%	* A bunch of .png and .eps figures will be automatically saved with [fnm *YYYYMMDD-HHMMSS*] format.
%	* Output data from batchFetch* functions will be appended to:
%		* 'dDomainProps.txt'
%		* 'dLocationProps.txt'
%		* 'dLocationPropsFreq.txt'
%		* 'dCorr.txt'
%		* 'dMotorCorr.txt'
%		* 'dSpatialCorr.txt'
%
%James B. Ackman, 2013-11-19 12:06:20  

filelist = readtext(filename,' ');
datafilename = ['filesOutput_' datestr(now,'yyyymmdd-HHMMSS') '.txt'];
mainfcnLoop(filelist,datafilename)


function mainfcnLoop(filelist,datafilename)
%start loop through files-----------------------------------------------------------------
if size(filelist,2) > 1
	fnms = filelist(:,2);  %Second column is dummy region matfiles
	fnms2 = filelist(:,1); %First column is the original .tif filename
else
	error('TIFF movie filename required in 1st column, region dummy filename required in 2rd column of space-delimited filelist')
end

for j=1:numel(fnms)
	load(fnms{j},'region');  %load the dummy file containing parcellations, motor signal, etc
	[pathstr, name, ext] = fileparts(fnms2{j});  
	region.filename = [name ext]; %set the .tif file name

	[pathstr, name, ext] = fileparts(fnms{j});
	region.matfilename = [name ext]; 
	
    sprintf(fnms{j})    
    disp('--------------------------------------------------------------------')
    disp(['Processing ' num2str(j) '/' num2str(numel(fnms)) ' files...'])
	fnm = wholeBrain_workflow(fnms2{j},region);
	appendCellArray2file(datafilename,{fnm})
    close all
end


function appendCellArray2file(filename,output)
%---Generic output function-------------
tmp=output;
fid = fopen(filename,'a');
for i=1:numel(tmp); tmp{i} = num2str(tmp{i}); end  %this will be to 4 decimal points (defaut for 'format short'). Can switch to 'format long' before running this loop if need more precision.
tmp2=tmp';
fprintf(fid,[repmat('%s\t',1,size(tmp2,1)-1),'%s\n'],tmp2{:});  %tab delimited
%fprintf(fid,[repmat('%s ',1,size(tmp2,1)-1),'%s\n'],tmp2{:});  %space delimited
fclose(fid);


function fnm = wholeBrain_workflow(fnm,region)
%==1==Segmentation============================
%fnm = '120518_07.tif';
%load('120518_07_dummyHemis2.mat');

tic;              
hemisphereIndices = [2 3];  %region.coord locations of 'cortex.L' and 'cortex.R'
backgroundRemovRadius = round(681/region.spaceres);  % default is 681 µm radius for the circular structured element used for background subtraction.
makeMovies = 1;
[A2, A] = wholeBrain_segmentation(fnm,backgroundRemovRadius,region,hemisphereIndices,0,makeMovies);         
toc;  

%==2==Detection============================
tic;             
[A3, CC, STATS] = wholeBrain_kmeans(A2,A,[4 3],makeMovies,fnm,region,hemisphereIndices);        %3clusters and using motorSignal with sqDistance for kmeans
fnm2 = [fnm(1:length(fnm)-4) '_' datestr(now,'yyyymmdd-HHMMSS') '.mat'];
toc;        
save([fnm2(1:length(fnm2)-4) '_connComponents_BkgndSubtr60' '.mat'],'A2','A3','CC','STATS','-v7.3')  

%rsync -av -e ssh jba38@louise.hpc.yale.edu:~/data/120518i/120518_09....mat ~/Desktop  

%==3==Format domain data structures============================
domains = DomainSegmentationAssignment(CC,STATS, 'false');  

region.domainData.domains = domains;      
region.domainData.CC = CC;      
region.domainData.STATS = STATS;  

if ~isfield(region.domainData.STATS, 'descriptor')      
	for i = 1:length(region.domainData.STATS)    
		region.domainData.STATS(i).descriptor = '';      
	end      
end      

locationIndices = find(~strcmp(region.name,'field') & ~strcmp(region.name,'craniotomy'));  %because region.location may be empty to this point (usually gets tagged only as a lut for cells are grid rois)
region = Domains2region(domains, region.domainData.CC,region.domainData.STATS,region,locationIndices)

fnm = fnm2;  
fnm = [fnm(1:end-4) '_d2r' '.mat'];       
save(fnm,'region')  


%==4==Get active fraction signals=============================
sz=region.domainData.CC.ImageSize;        

tmp = zeros(sz,'uint8');        
A3 = logical(tmp);        
clear tmp;      

for i = 1:region.domainData.CC.NumObjects      
	if ~strcmp(region.domainData.STATS(i).descriptor, 'artifact')    
		A3(region.domainData.CC.PixelIdxList{i}) = 1;      
	end          
end      

data = wholeBrain_activeFraction(A3,region);   

region.locationData.data = data;    
save(fnm,'region')    

disp('-----')

wholeBrain_activeFraction(A3,region,[2 3]); %Assuming 'cortex.L' and 'cortex.R' are at positons 2 & 3 in region.name, print just these traces instead of all locations
fnm2 = [fnm(1:end-4) 'actvFraction' datestr(now,'yyyymmdd-HHMMSS') '.mat'];
print(gcf, '-dpng', [fnm2(1:end-4) '-' datestr(now,'yyyymmdd-HHMMSS') '.png']);      
print(gcf, '-depsc', [fnm2(1:end-4) '-' datestr(now,'yyyymmdd-HHMMSS') '.eps']);   

%==5==More Plots=========================
%--Single contour activity map-----
wholeBrainActivityMapFig(region,[],2,1);  
fnm2 = [fnm(1:end-4) 'ActivityMapFigContour' datestr(now,'yyyymmdd-HHMMSS') '.mat'];              
print(gcf, '-dpng', [fnm2(1:end-4) '.png']);                  
print(gcf, '-depsc', [fnm2(1:end-4) '.eps']); 
disp('complete: wholeBrainActivityMapFig(region,[],2,1);')

wholeBrainActivityMapFig(region,[],2,1,0);
fnm2 = [fnm(1:end-4) 'ActivityMapFigRawProj' datestr(now,'yyyymmdd-HHMMSS') '.mat'];              
print(gcf, '-dpng', [fnm2(1:end-4) '.png']);                  
print(gcf, '-depsc', [fnm2(1:end-4) '.eps']);
disp('complete: wholeBrainActivityMapFig(region,[],2,1,0);')


%--Drug state contour activity maps if applicable
if isfield(region,'stimuli');
	stimuliIndices = {'drug.state.control' 'drug.state.isoflurane'};
	ind = [];
	for i = 1:length(region.stimuli)
		for k = 1:length(stimuliIndices)
			if strcmp(region.stimuli{i}.description,stimuliIndices{k})
				ind = [ind i];
			end
		end
	end
	if ~isempty(ind)
		wholeBrainActivityMapFig(region,[],2,5,20,ind); 
		fnm2 = [fnm(1:end-4) 'ActivityMapFigDrug' datestr(now,'yyyymmdd-HHMMSS') '.mat'];        
		print(gcf, '-dpng', [fnm2(1:end-4) '.png']);            
		print(gcf, '-depsc', [fnm2(1:end-4) '.eps']);  
	end	
	%--Motor state contour activity maps if applicable		
	stimuliIndices = {'motor.state.active' 'motor.state.quiet'};
	ind = [];
	for i = 1:length(region.stimuli)
		for k = 1:length(stimuliIndices)
			if strcmp(region.stimuli{i}.description,stimuliIndices{k})
				ind = [ind i];
			end
		end
	end
	if ~isempty(ind)
		wholeBrainActivityMapFig(region,[],2,5,20,ind); 
		fnm2 = [fnm(1:end-4) 'ActivityMapFigMotor' datestr(now,'yyyymmdd-HHMMSS') '.mat'];        
		print(gcf, '-dpng', [fnm2(1:end-4) '.png']);            
		print(gcf, '-depsc', [fnm2(1:end-4) '.eps']);  		
	end
end 

%DomainPatchesPlot(region.domainData.domains, region.domainData.CC, region.domainData.STATS,1,[],1)   %DomainPatchesPlot won't work on a linux server because of a segmentation fault with drawing alpha transparency in matlab
%fnm2 = [fnm(1:end-4) 'DomainPatchesPlot' datestr(now,'yyyymmdd-HHMMSS') '.mat'];              
%print(gcf, '-dpng', [fnm2(1:end-4) '.png']);                  
%print(gcf, '-depsc', [fnm2(1:end-4) '.eps']);

%--Maximum intensity projections of movie--
	
%-------Make movie array with with raw intensity values within the functional ROIs--------    
A4 = A;    
A4(~A3) = 0;  %A3 is binary movie from above with any 'artifact' tagged domains removed (usually none on first batch analysis pass)
%A4=mat2gray(A4);    
bw = max(A3,[],3);
	
%----Maxproj of detected domains -----
A5 = max(A4,[],3);
tmp = A5(bw);
LOW_HIGH = stretchlim(tmp);
%A6 = imadjust(A5,LOW_HIGH,[]);
A6 = mat2gray(A5);
figure;  
imagesc(A6); title('maxproj of raw detected domains array'); colorbar('location','eastoutside'); axis image   
fnm2 = [fnm(1:length(fnm)-4) '_maxProj1_' datestr(now,'yyyymmdd-HHMMSS')];    
print('-dpng', [fnm2 '.png'])
print('-depsc', [fnm2 '.eps']) 

%----Maxproj of raw dFoF array -----
A5 = max(A,[],3);
%A6 = imadjust(A5,LOW_HIGH,[]);   
A6 = mat2gray(A5);
figure;  
imagesc(A6); title('maxproj of dFoF movie array detected adjust'); colorbar('location','eastoutside'); axis image   
fnm2 = [fnm(1:length(fnm)-4) '_maxProj2_' datestr(now,'yyyymmdd-HHMMSS')];    
print('-dpng', [fnm2 '.png'])
print('-depsc', [fnm2 '.eps']) 

%----Maxproj of raw dFoF array -----
figure;  
%A6 = imadjust(A5);
A6 = mat2gray(A5);
imagesc(A6); title('maxproj of dFoF movie array raw adjust'); colorbar('location','eastoutside'); axis image   
fnm2 = [fnm(1:length(fnm)-4) '_maxProj3_' datestr(now,'yyyymmdd-HHMMSS')];    
print('-dpng', [fnm2 '.png'])
print('-depsc', [fnm2 '.eps']) 


%==6==Batch fetch datasets=======================
batchFetchDomainProps({fnm},region,'dDomainProps.txt');
batchFetchLocationProps({fnm},region,'dLocationProps.txt', 'true', {'motor.state.active' 'motor.state.quiet' 'drug.state.control' 'drug.state.isoflurane'});
batchFetchLocationPropsFreq({fnm},region,'dLocationPropsFreq.txt', 'true', {'motor.state.active' 'motor.state.quiet' 'drug.state.control' 'drug.state.isoflurane'});	


%==7==Get spatial correlation results and plots==============
region = wholeBrain_SpatialCOMCorr(fnm,region,{'cortex.L' 'cortex.R'},1);
batchFetchSpatialCOMCorrData({fnm},region,'dCorticalCorr.txt',1);

%==8==Get temporal correlation results and plots for cortical hemispheres=================
region = wholeBrain_CorticalActiveFractionCorr(fnm,region,{'cortex.L' 'cortex.R'});
batchFetchCorticalCorrData({fnm},region,'dCorticalCorr.txt',1);
save(fnm,'region');

%===If region contains coords for more than just 'field', 'cortex.L', and 'cortex.R' proceed to fetch data and plots making use of these parcellations (functional correlation matrices, motor corr, etc)
if length(region.name) > 3

	%==9==Get correlation matrix and plots======================== 
	exclude = {'cortex.L' 'cortex.R'};
	region = wholeBrain_corrData(fnm, region, exclude);  %will also print and save corr matrix and raster plot of the traces (activeFraction) that went into the corr matrix
	save(fnm,'region');

	%==10==Get cortical - motor corr results and plots=============
	if isfield(region,'motorSignal')
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
	
		region = wholeBrain_MotorSignalCorr(fnm,region,st);
		save(fnm,'region');
	end

	%==11==Batch fetch remaining datasets=============
	batchFetchCorrData({fnm},region,'dCorr.txt',1);
	batchFetchMotorCorrData({fnm},region,'dMotorCorr.txt',1);

else
	if isfield(region,'motorSignal')
		st(1).str = {'cortex.L' 'cortex.R'};	
		wholeBrain_MotorSignalCorr(fnm,region,st);
	end
end
