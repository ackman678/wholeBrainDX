function openWholeBrainDomainsTraces(fnm,fnm2)
%openWholeBrainDomainsTraces - Opening function for plotWholeBrainDomainsTraces
%Examples:
% openWholeBrainDomainsTraces
% openWholeBrainDomainsTraces(fnm,fnm2)
%**USE**
% fnm - '_d2r.mat'  %d2r.mat file from wholeBrain_batch
% fnm2 - 'dFoF.avi' %.avi file from wholeBrain_segmentation.m or _kmeans.m
%
% See also plotWholeBrainDomainsTraces.m
%
%James B. Ackman, 2014-03-06 10:12:25

if nargin < 2 || isempty(fnm),
	disp(['Please load the region d2r data file'])
	%load previous region data file with domains tagged or use domainTaggingGui to fetch data().frame() xy centroid locations for artifacts
	[filename, pathname] = uigetfile({'*d2r.mat'}, 'Please load the region d2r data file');
	fnm = fullfile(pathname,filename);
end

if nargin < 3 || isempty(fnm2),
	disp(['Please load the .avi movie'])
	%load previous region data file with domains tagged or use domainTaggingGui to fetch data().frame() xy centroid locations for artifacts
	[filename, pathname] = uigetfile({'*.avi'}, 'Please load the .avi movie');
	fnm2 = fullfile(pathname,filename);
end

%--Create 8bit avi in ImageJ of dF/F movie first or use .avi from wholeBrain_segmentation.m
%--In matlab, use 'VideoReader' to make 8bit movie object structure and return frames from the .avi of the raw movie (so we can full frame res, array in memory locally)

vidObj = VideoReader(fnm2);   %change this to desired .avi to read in
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