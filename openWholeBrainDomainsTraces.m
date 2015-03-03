function openWholeBrainDomainsTraces(fnm,fnm2,hemisphereIndices)
%openWholeBrainDomainsTraces - Opening function for plotWholeBrainDomainsTraces
%Examples:
% openWholeBrainDomainsTraces
% openWholeBrainDomainsTraces(fnm,fnm2)
%**USE**
% fnm - '_d2r.mat'  %d2r.mat file from wholeBrain_batch
% fnm2 - 'dFoF.avi' %.avi file from wholeBrain_segmentation.m or _detect.m
%
% See also plotWholeBrainDomainsTraces.m
%
%James B. Ackman, 2014-03-06 10:12:25

if nargin < 1 || isempty(fnm),
	if exist('calciumdxprefs.mat','file') == 2
        load('calciumdxprefs')
    else
        pathname = pwd;
    end

	disp(['Please load the region d2r data file'])
	%load previous region data file with domains tagged or use domainTaggingGui to fetch data().frame() xy centroid locations for artifacts
	[filename, pathname] = uigetfile({'*d2r.mat'}, 'Please load the region d2r data file', pathname);
	fnm = fullfile(pathname,filename);
    save('calciumdxprefs.mat', 'pathname','filename')
end

if nargin < 2 || isempty(fnm2),
	if exist('calciumdxprefs.mat','file') == 2
        load('calciumdxprefs')
    else
        pathname = pwd;
    end

	disp(['Please load the .avi movie'])
	%load previous region data file with domains tagged or use domainTaggingGui to fetch data().frame() xy centroid locations for artifacts
	[filename, pathname] = uigetfile({'*.avi'}, 'Please load the .avi movie', pathname);
	fnm2 = fullfile(pathname,filename);
    save('calciumdxprefs.mat', 'pathname','filename')
end

%--Create 8bit avi in ImageJ of dF/F movie first or use .avi from wholeBrain_segmentation.m
%--In matlab, use 'VideoReader' to make 8bit movie object structure and return frames from the .avi of the raw movie (so we can full frame res, array in memory locally)

disp([datestr(now,'yyyymmdd-HHMMSS') '-------------------------------------------------'])
disp(['mov1: ' fnm2])
disp(['mov2: ' fnm])

vidObj = VideoReader(fnm2);   %change this to desired .avi to read in
nFrames = vidObj.NumberOfFrames;
vidHeight = vidObj.Height;
vidWidth = vidObj.Width;
%--Preallocate movie structure----------------------------------------------------
mov(1:nFrames) = ...
	struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
		   'colormap', []);
%--Read one frame at a time, takes awhile if it's jpeg compressed avi-------------
parfor fr = 1:nFrames; %option:parfor
	mov(fr).cdata = read(vidObj, fr);
end

%--Make 8bit movie array----------------------------------------------------------
sz = size(mov(1).cdata);
A = zeros([sz(1) sz(2) nFrames], 'uint8');
parfor fr = 1:nFrames; %option:parfor
	[im,map] = frame2im(mov(fr));
	if isempty(map)            %Truecolor system
	  rgb = im;
	else                       %Indexed system
	  rgb = ind2rgb(im,map);   %Convert image data
	end	
	im1 = rgb2gray(rgb);
	im2= im2uint8(im1);
	A(:,:,fr) = im2;
end
clear mov vidObj im im1


%--Brighten/increase contrast for movie1 inside labeled regions--------------------
load(fnm,'region');
if nargin < 3 || isempty(hemisphereIndices), hemisphereIndices = find(strcmp(region.name,'cortex.L') | strcmp(region.name,'cortex.R') | strcmp(region.name,'OB.L') | strcmp(region.name,'OB.R') | strcmp(region.name,'SC.L') | strcmp(region.name,'SC.R')); end  %index location of the hemisphere region outlines in the 'region' calciumdx struct

if ~isempty(hemisphereIndices)
	bothMasks=false(sz(1),sz(2));
	for nRoi=1:length(hemisphereIndices)
		regionMask = poly2mask(region.coords{hemisphereIndices(nRoi)}(:,1),region.coords{hemisphereIndices(nRoi)}(:,2),sz(1),sz(2));
		%regionMask2 = poly2mask(region.coords{hemisphereIndices(2)}(:,1),region.coords{hemisphereIndices(2)}(:,2),sz(1),sz(2));
		%figure; imshow(regionMask1); 	figure; imshow(regionMask2);
		bothMasks = bothMasks|regionMask;  %makes a combined image mask of the two hemispheres
	end

	bothMasksArr = repmat(bothMasks,[1 1 nFrames]);
	tmp = A(bothMasksArr);
	LOW_HIGH = stretchlim(tmp);
	parfor fr=1:nFrames; %option:parfor
		A(:,:,fr) = imadjust(A(:,:,fr),LOW_HIGH,[]);
	end
	%[I2arr, map] = gray2ind(A, 256); %convert the whole array to 8bit indexed
	clear tmp
end


%--Prep plots and titles for gui--------------------------------------------------
%load(fnm3,'A3')
movieTitles{1} = 'dF/F+60px diskBkgndSubtr avi';  
movieTitles{2} = 'detect';   
movieTitles{3} = 'active fraction';  
movieTitles{4} = 'motor activity signal';

if isfield(region,'motorSignal')
	if ~isempty(region.motorSignal)
		decY2 = region.motorSignal;
		plot4(1).data=decY2;     %setup a default plot structure for the rectified/decimated photodiode motor signal  
		plot4(1).legendText = ['rectDecMotorSig'];  
		plot4(1).Fs=1;   %sampling rate (Hz).  Used to convert data point indices to appropriate time units.  Leave at '1' for no conversion (like plotting the indices, 'frames')  
		plot4(1).unitConvFactor = 1; 
	else
		plot4=[];
	end
else
	plot4=[];
end

%--Make binary mask movie------------------------------------------------------------------------
sz=region.domainData.CC.ImageSize;
A3 = false(sz);
for i = 1:region.domainData.CC.NumObjects
	if ~strcmp(region.domainData.STATS(i).descriptor, 'artifact')
		A3(region.domainData.CC.PixelIdxList{i}) = true;
	end
end
disp([num2str(region.domainData.CC.NumObjects) ' total domains'])

%--Run gui------------------------------------------------------------------------
plotWholeBrainDomainsTraces(A,A3,region,plot4,movieTitles,[])  	
