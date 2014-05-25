function [A2, A, thresh, Amin] = wholeBrain_segmentation(fnm,backgroundRemovRadius,region,hemisphereIndices,showFigure,makeMovies,thresh,pthr,sigma)
%PURPOSE -- segment functional domains in wholeBrain calcium imaging movies into ROIs
%USAGE -- A2 = wholeBrain_segmentation(fnm,[],region)
%James B. Ackman
%2012-12-20
%updated, improved algorithm with gaussian smooth 2013-02-01 by J.B.A.
%modified 2013-03-28 14:25:44 by J.B.A.
% Optimized and simplified algoritm 2014-05-21 16:06:48 by J.B.A.

if nargin < 9 || isempty(sigma), sigma = 56.75/region.spaceres; end  %sigma is the standard deviation in pixels of the gaussian for smoothing. It is 56.75µm at 11.35µm/px dimensions to give a **5px sigma**. gaussSmooth.m multiplies the sigma by 2.25 standard deviations for the filter size by default.
if nargin < 8 || isempty(pthr), pthr = 0.99; end
if nargin < 7 || isempty(thresh), 
	makeThresh = 1; 
else
	makeThresh = 0;
end
if nargin < 6 || isempty(makeMovies), makeMovies = 1; end
if nargin < 5 || isempty(showFigure), showFigure = 0; end %default is to not show the figures (faster)
if nargin < 4 || isempty(hemisphereIndices), hemisphereIndices = find(strcmp(region.name,'cortex.L') | strcmp(region.name,'cortex.R')); end  %index location of the hemisphere region outlines in the 'region' calciumdx struct
if nargin < 3 || isempty(region), region = myOpen; end  %to load the hemisphere region outlines from 'region' calciumdx struct
if nargin < 2 || isempty(backgroundRemovRadius)
	%radius in pixels, should be a few times larger than the biggest object of interest in the image
	backgroundRemovRadius = round(681/region.spaceres);  % default is 681 µm radius for the circular structured element used for background subtraction. This was empirically determined during testing with a range of sizes in spring 2013 on 120518–07.tif and 120703–01.tif. At 11.35 µm/px this would be a 60px radius.
end

nPixelThreshold = 50; %round(6.4411e+03/(region.spaceres^2));  %for bwareaopen in loop where salt and pepper noise is removed, getting rid of objects less than 6441.1 µm^2 (50 px with pixel dimensions at 11.35 µm^2)
edgeSmooth = ceil(22.70/region.spaceres); %22.70µm at 11.35um/px to give 2px smooth for the morphological dilation.
edgeSmooth2 = ceil(34.050/region.spaceres);  %34.0500 at 11.35um/px to give 3px smooth for the second morphological dilation after detection

%{
%Open the time series if not passed as a dF/F double array as an input
if nargin < 1 || isempty(A)  
	[data, series1] = myOpenOMEtiff;
	A = double(series1);
	Amean = mean(A,3);
	for i = 1:size(A,3)
		A(:,:,i) = (A(:,:,i) - Amean)./Amean;
	end
end
%}

if nargin < 1 || isempty(fnm)
    if exist('pathname','var')
        [filename, pathname] = uigetfile({'*.tif'}, 'Choose image to open',pathname);
        if ~ischar(filename)
            return
        end
    else
        [filename, pathname] = uigetfile({'*.tif'}, 'Choose image to open');
        if ~ischar(filename)
            return
        end
    end
    fnm = [pathname filename];
    save('calciumdxprefs.mat', 'pathname','filename')
end

[pathstr, name, ext] = fileparts(fnm);
fnm2 = [name '_wholeBrain_segmentation_' datestr(now,'yyyymmdd-HHMMSS') '.avi']; 

%Read in the primary or first movie file:  
[~, series1] = myOpenOMEtiff(fnm);
A = double(series1);
clear series1

%Find out whether there are extra movie files that need to be concatenated together with the first one (regular tiffs have 2+GB limit in size):  
if isfield(region,'extraFiles')
	if ~isempty(region.extraFiles)
		C = textscan(region.extraFiles,'%s', ' ');  %region.extraFiles should be a single space-delimited character vector of additional movie filenames		
		for i = 1:numel(C{1})		
			if ~strcmp(fnm,C{1}{i})  %if the current filename is not the first one proceed with concatenation				
				fn=fullfile(pathstr,C{1}{i});
				[~, series1] = myOpenOMEtiff(fn);
				A = cat(3, A, double(series1));
				clear series1
			end
		end
	end
end

sz = size(A);
szXY = sz(1:2);
szZ=sz(3);

%TESTING-------------
%se = strel('disk',backgroundRemovRadius); 
%parfor fr=1:szZ
%    I = A(:,:,fr);  %get frame  %original  
%    %Perform tophat filtering (background subtraction)  
%    background = imopen(I,se);  %make sure backgroundRemovRadius strel object is bigger than the biggest objects (functional domains) that you want to detect in the image  
%    I2 = I - background;  %subtract background  
%    A(:,:,fr) = I2;  
%end  
%END TESTING---------

%Make deltaF/F movie
Amean = mean(A,3);
for i = 1:size(A,3)
	%     A(:,:,i) = (A(:,:,i) - region.image)./region.image;
		A(:,:,i) = (A(:,:,i) - Amean)./Amean;
end
Amin2D = min(A,[],3);
Amin = min(Amin2D(:));
A = A + abs(Amin);  %Scale deltaF array so everything is positive valued

bothMasks= false(sz(1),sz(2));
for nRoi=1:length(hemisphereIndices)
	regionMask = poly2mask(region.coords{hemisphereIndices(nRoi)}(:,1),region.coords{hemisphereIndices(nRoi)}(:,2),sz(1),sz(2));
	%regionMask2 = poly2mask(region.coords{hemisphereIndices(2)}(:,1),region.coords{hemisphereIndices(2)}(:,2),sz(1),sz(2));
	%figure; imshow(regionMask1); 	figure; imshow(regionMask2);
	bothMasks = bothMasks|regionMask;  %makes a combined image mask of the two hemispheres
end

%------Make pixelindex lists for background component removal within for loop below-----------
borderJitter = ceil(113.5/region.spaceres); %for making image border outline 10 px wide (at 11.35 µm/px) to intersect 
x = [borderJitter sz(2)-borderJitter sz(2)-borderJitter borderJitter borderJitter];  %make image border outline borderJitter px wide (at 11.35 µm/px) to intersect 
y = [borderJitter borderJitter sz(1)-borderJitter sz(1)-borderJitter borderJitter];  %make image border outline borderJitter px wide (at 11.35 µm/px) to intersect 
ImageBordermask = poly2mask(x,y,sz(1),sz(2));  %make image border mask
%figure, imshow(mask)
imageBorderIndices = find(~ImageBordermask);
backgroundIndices = find(~bothMasks);

%{
% from orig in dec 2012, no longer needed
bwBorders = bwperim(bothMasks);
%figure, imshow(bwBorders);
se = strel('square',5);
bwBorders = imdilate(bwBorders,se);
%	figure, imshow(bwBorders)
%hemisphereBorders = find(bwBorders);
%}

M(size(A,3)) = struct('cdata',[],'colormap',[]);
F(size(A,3)) = struct('cdata',[],'colormap',[]);
A2=false(size(A));
Iarr=zeros(size(A));
G=zeros(size(A));
bothMasks3D = repmat(bothMasks,[1 1 szZ]);
%ImageBordermask3D = repmat(~ImageBordermask,[1 1 szZ]);
%imageBorderIndices = find(ImageBordermask3D);
%clear ImageBordermask3D

%------Start core for loop-------------------------
%figure;
%levels = zeros(1,szZ);

se = strel('disk',backgroundRemovRadius);
seSm1 = strel('disk',edgeSmooth); %smooth edges, has not much effect with gaussSmooth used above
seSm2 = strel('disk',edgeSmooth2);

parfor fr = 1:szZ;
	I = A(:,:,fr);
	
	background = imopen(I,se);  %make sure backgroundRemovRadius strel object is bigger than the biggest objects (functional domains) that you want to detect in the image
	I2 = I - background;  %subtract background
%	figure; imshow(I2,[]); title('I2')
	
%	Iarr(:,:,fr) = I2;
	
	I2 = gaussSmooth(I2,sigma,'same');
%		figure, imshow(img2,[])
	Iarr(:,:,fr) = I2;
	%Adjust filtered image contrast, estimate Otsu's threshold, then binarize the frame, and remove single pixel noise
%	I3 = imadjust(I2);  %increase image contrast, saturating 1% of data at both low and high intensities.
%	I3 = I2;

	sx = fspecial('sobel');
	sy = sx';
	gx = imfilter(I2,sx,'replicate');
	gy = imfilter(I2,sy,'replicate');
	grad = sqrt(gx.*gx + gy.*gy);
	G(:,:,fr) = grad;
end	


%======BEGIN Calculate threshold==========================================================
%	grad = grad/max(grad(:));
mxG = max(G,[],3);
mx = max(mxG(:));
G = G/mx;

%	grad(~bothMasks) = 0; %Make all edges outside of hemispheres to black level pixels so they don't influence the histogram calculation
G(~bothMasks3D) = 0;
if showFigure > 0; figure; imshow(G(:,:,1),[]); end

%	[h, ~] = imhist(grad); %For indexed images, imhist returns the histogram counts for each colormap entry so the length of counts is the same as the length of the colormap.

[h, ~] = imhist(reshape(G,numel(G),1));

if showFigure > 0; figure; imhist(grad); end
%	pthr = 0.99;
Q = prctileThresh(h,pthr);
%	markerImage = grad > Q;
markerImage = G > Q;
%	[level,est] = graythresh(grad);  %Otsu's threshold from Image Processing Toolbox  
%	markerImage = im2bw(grad,level);  %Make binary based on Otsu's threshold
if showFigure > 0; figure; imshow(markerImage,[]); end

%	fp = f.*markerImage; 
fp = Iarr.*markerImage; 

if showFigure > 0
figure, imshow(fp,[])  
figure, imhist(fp)
end
[hp, ~] = imhist(reshape(fp,numel(fp),1));

hp(1) = 0;
if showFigure > 0; figure; bar(hp,0); end
T = otsuthresh(hp);
%	T*(numel(hp) - 1)

if makeThresh < 1
	%If false, ignore the threshold, T, set above and use preexisting otsu threshold (for drug movies) passed as handle
	T = thresh;
end


%======BEGIN segmentation=================================================================
parfor fr = 1:szZ;

	bw = Iarr(:,:,fr) > T;
	if showFigure > 0; figure; imshow(bw); title([num2str(pthr) ' percentile']); end
	% 	levels(1,fr) = T;

	%Detect connected components in the frame and return ROI CC data structure----------------
	%CC = bwconncomp(bw);
	S = regionprops(bw, 'Area', 'Centroid', 'PixelIdxList');
	sa = [S.Area];

	vCentrs=vertcat(S.Centroid);
%	centrInd = sub2ind(sz, round(vCentrs(:,2))', round(vCentrs(:,1))', round(vCentrs(:,3))'); 
	centrInd = sub2ind(szXY, round(vCentrs(:,2))', round(vCentrs(:,1))'); 
	pxInd = {S.PixelIdxList};

	%sa = cellfun(@numel, pxInd);

	[~,ia] = setdiff(centrInd,backgroundIndices);

	%function C = inters2(pxIdxList)
	%C = intersect(pxIdxList,imageBorderIndices);
	%end
	%
	%IN = cellfun(@inters2, pxInd, 'UniformOutput', false);
	%lenIN = cellfun(@numel, IN);

	C1 = intersect(find(sa > nPixelThreshold), ia);
	%C2 = intersect(find(lenIN < 1), C1);

	%idxToKeep = S.PixelIdxList(sa > nPixelThreshold);
	idxToKeep = pxInd(C1);
	
	%imagebord intersect
	lenIN=zeros(1,numel(idxToKeep));
	for i=1:numel(lenIN)
	C = intersect(idxToKeep{i},imageBorderIndices);
	lenIN(1,i)=numel(C);
	end
	
	idxToKeep2=idxToKeep(lenIN < 1);
	idxToKeep2 = vertcat(idxToKeep2{:});

	bw2 = false(size(bw));
	bw2(idxToKeep2) = true;
	
	bw2 = imdilate(bw2,seSm1);	
	bw2 = imclose(bw2,seSm2);
	
	A2(:,:,fr) = bothMasks & bw2;
	%A2(:,:,fr) = bw2;
	%-----------------------------------------------------------------------------------------

	%Optional--Show the frame and prep for .avi movie making if desired
	if showFigure > 0
		imshow(label2rgb(L));	
		M(fr) = getframe;
	end
end

thresh = T;

%Optional--Export .avi movie if desired
%write the motion JPEG .avi to disk using auto-generated datestring based filename
if makeMovies
	Iarr=mat2gray(Iarr);   %scale the whole array
	bothMasksArr = repmat(bothMasks,[1 1 szZ]);
	tmp = Iarr(bothMasksArr);
	LOW_HIGH = stretchlim(tmp);
	for fr=1:szZ
		Iarr(:,:,fr) = imadjust(Iarr(:,:,fr),LOW_HIGH,[]);
	end
	[I2arr, map] = gray2ind(Iarr, 256); %convert the whole array to 8bit indexed
		
	for fr=1:szZ
		M(fr) = im2frame(I2arr(:,:,fr),map);  %setup the indexed raw dFoF movie

		I=mat2gray(A2(:,:,fr));  %makes each binary frame into gray image for gray2ind function
		[I2, map2] = gray2ind(I, 8); %figure; imshow(I2,map)
		F(fr) = im2frame(I2,map2);  %setup the binary segmented mask movie
	end

	fnm3 = [fnm2(1:length(fnm2)-4) '-dFoF' '.avi']; 
	disp(['Making ' fnm3 '-----------'])
	vidObj = VideoWriter(fnm3);
	open(vidObj);
	for i =1:numel(M)
		writeVideo(vidObj,M(i));
	end
	close(vidObj);

%write the motion JPEG .avi to disk using auto-generated datestring based filename
	fnm3 = [fnm2(1:length(fnm2)-4) '-mask' '.avi'];
	disp(['Making ' fnm3 '-----------']) 
	vidObj = VideoWriter(fnm3);
	open(vidObj);
	for i =1:numel(F)
		writeVideo(vidObj,F(i));
	end
	close(vidObj);
end
end
