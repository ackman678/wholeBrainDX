function [A2, A, thresh, Amin] = wholeBrain_segmentation(fnm,backgroundRemovRadius,region,hemisphereIndices,showFigure,makeMovies,thresh,pthr,sigma)
%PURPOSE -- segment functional domains in wholeBrain calcium imaging movies into ROIs
%USAGE -- A2 = wholeBrain_segmentation(fnm,[],region)
%James B. Ackman
%2012-12-20
%updated, improved algorithm with watershed separation and gaussian smooth 2013-02-01 by J.B.A.
%modified 2013-03-28 14:25:44 by J.B.A.


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

nPixelThreshold = round(6.4411e+03/(region.spaceres^2));  %for bwareaopen in loop where salt and pepper noise is removed, getting rid of objects less than 6441.1 µm^2 (50 px with pixel dimensions at 11.35 µm^2)
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
[data, series1] = myOpenOMEtiff(fnm);
A = double(series1);
clear data series1

%Find out whether there are extra movie files that need to be concatenated together with the first one (regular tiffs have 2+GB limit in size):  
if isfield(region,'extraFiles')
	if ~isempty(region.extraFiles)
		C = textscan(region.extraFiles,'%s', ' ');  %region.extraFiles should be a single space-delimited character vector of additional movie filenames		
		for i = 1:numel(C{1})		
			if ~strcmp(fnm,C{1}{i})  %if the current filename is not the first one proceed with concatenation				
				fn=fullfile(pathstr,C{1}{i});
				[data, series1] = myOpenOMEtiff(fn);
				A = cat(3, A, double(series1));
				clear data series1
			end
		end
	end
end

sz = size(A);
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

bothMasks=logical(zeros(sz(1),sz(2)));
for nRoi=1:length(hemisphereIndices)
	regionMask = poly2mask(region.coords{hemisphereIndices(nRoi)}(:,1),region.coords{hemisphereIndices(nRoi)}(:,2),sz(1),sz(2));
	%regionMask2 = poly2mask(region.coords{hemisphereIndices(2)}(:,1),region.coords{hemisphereIndices(2)}(:,2),sz(1),sz(2));
	%figure; imshow(regionMask1); 	figure; imshow(regionMask2);
	bothMasks = bothMasks|regionMask;  %makes a combined image mask of the two hemispheres
end

%------Make pixelindex lists for background component removal within for loop below-----------
borderJitter = 113.5/region.spaceres; %for making image border outline 10 px wide (at 11.35 µm/px) to intersect 
x = [borderJitter sz(2)-borderJitter sz(2)-borderJitter borderJitter borderJitter];  %make image border outline borderJitter px wide (at 11.35 µm/px) to intersect 
y = [borderJitter borderJitter sz(1)-borderJitter sz(1)-borderJitter borderJitter];  %make image border outline borderJitter px wide (at 11.35 µm/px) to intersect 
ImageBordermask = poly2mask(x,y,sz(1),sz(2));  %make image border mask
%figure, imshow(mask)
imageBorderIndices = find(~ImageBordermask);
backgroundIndices = find(~bothMasks);

bwBorders = bwperim(bothMasks);
%figure, imshow(bwBorders);
se = strel('square',5);
bwBorders = imdilate(bwBorders,se);
%	figure, imshow(bwBorders)
hemisphereBorders = find(bwBorders);

M(size(A,3)) = struct('cdata',[],'colormap',[]);
F(size(A,3)) = struct('cdata',[],'colormap',[]);
A2=zeros(size(A),'int8');
A2=logical(A2);
szZ=sz(3);
Iarr=zeros(size(A));
G=zeros(size(A));
bothMasks3D = repmat(bothMasks,[1 1 szZ]);

%------Start core for loop-------------------------
%figure;
%levels = zeros(1,szZ);

switch makeThresh
case 1 %make otsu thresholds (normal)

for fr = 1:szZ;
	I = A(:,:,fr);
	
	se = strel('disk',backgroundRemovRadius);
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

	f = I2;
	sx = fspecial('sobel');
	sy = sx';
	gx = imfilter(f,sx,'replicate');
	gy = imfilter(f,sy,'replicate');
	grad = sqrt(gx.*gx + gy.*gy);
	G(:,:,fr) = grad;
end	
	
%	grad = grad/max(grad(:));
	mxG = max(G,[],3);
	mx = max(mxG(:));
	G = G/mx;

%	grad(~bothMasks) = 0; %Make all edges outside of hemispheres to black level pixels so they don't influence the histogram calculation
	G(~bothMasks3D) = 0;
	if showFigure > 0; figure; imshow(grad,[]); end

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

for fr = 1:szZ;
	f = Iarr(:,:,fr);
	bw = im2bw(f, T);
	if showFigure > 0; figure; imshow(bw); title([num2str(pthr) ' percentile']); end
% 	levels(1,fr) = T;

%	figure; imshow(bw,[]); title('bw')
	bw = bwareaopen(bw, nPixelThreshold);  %remove background single isolated pixel noise. 50 is matlab default value in documentation example for image with , removes all binary objects containing less than 50 pixels. 
%	figure; imshow(bw,[]); title('bwareaopen 50')

	se = strel('disk',edgeSmooth); %smooth edges, has not much effect with gaussSmooth used above
	bw2 = imdilate(bw,se);
	%bw2 = imfill(bw2,'holes');
	%figure, imshow(bw2,[]); title('fill')

	g3 = bw2;  %TESTING 2013-03-27 13:12:53

	%Detect connected components in the frame and return ROI CC data structure
	CC = bwconncomp(g3);  %
	L = labelmatrix(CC);  %Not used
	%figure; imshow(label2rgb(L));	
	STATS = regionprops(CC,'Centroid');  % 

	newPixelIdxList = {};
	count = 0;
	for i = 1:CC.NumObjects
		centrInd = sub2ind(CC.ImageSize(1:2),round(STATS(i).Centroid(2)),round(STATS(i).Centroid(1)));	
		if	(length(intersect(centrInd,backgroundIndices)) < 1) & (length(intersect(CC.PixelIdxList{i},imageBorderIndices)) < 1)    %maybe change this threshold, to more than one px intersect like a percentage
	%		if	(length(intersect(centrInd,backgroundIndices)) < 1) & (length(intersect(CC.PixelIdxList{i},imageBorderIndices)) < 1)    %maybe change this threshold, to more than one px intersect like a percentage
	%		if	(length(intersect(centrInd,backgroundIndices)) < 1) & (length(intersect(CC.PixelIdxList{i},imageBorderIndices)) < 1) & (length(intersect(CC.PixelIdxList{i},hemisphereBorders)) < 1)    %maybe change this threshold, to more than one px intersect like a percentage
			count = count+1;
			newPixelIdxList{count} = CC.PixelIdxList{i};
		end
	end
	CC.PixelIdxList = newPixelIdxList;
	CC.NumObjects = length(CC.PixelIdxList);

	%Make rgb label matrix from the CC ROIs
	L = labelmatrix(CC);
%	figure; imshow(label2rgb(L));	%TESTING

	w = L == 0;
	g4 = g3 & ~w;
	%figure, imshow(g4)

%	figure, imshow(g4&bothMasks)   %TESTING

	se = strel('disk',edgeSmooth2);
	g5 = imclose(g4,se);
	bwFrame = g5&bothMasks;
%	figure; imshow(bwFrame); title('bw close')   %TESTING
	%-------end new Algorithm-------------------------------------

	A2(:,:,fr) = bwFrame;
	
	%Optional--Show the frame and prep for .avi movie making if desired
	if showFigure > 0
		imshow(label2rgb(L));	
		M(fr) = getframe;
	end
	
end

case 0 %use preexisting otsu threshold (for drug movies)
	T = thresh;
for fr = 1:szZ;
	I = A(:,:,fr);
	
	se = strel('disk',backgroundRemovRadius);
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
	f = I2;
		bw = im2bw(f, T);
	if showFigure > 0; figure; imshow(bw); title([num2str(pthr) ' percentile']); end
 	levels(1,fr) = T;

%	figure; imshow(bw,[]); title('bw')
	bw = bwareaopen(bw, nPixelThreshold);  %remove background single isolated pixel noise. 50 is matlab default value in documentation example for image with , removes all binary objects containing less than 50 pixels. 
%	figure; imshow(bw,[]); title('bwareaopen 50')

	se = strel('disk',edgeSmooth); %smooth edges, has not much effect with gaussSmooth used above
	bw2 = imdilate(bw,se);
	%bw2 = imfill(bw2,'holes');
	%figure, imshow(bw2,[]); title('fill')

	g3 = bw2;  %TESTING 2013-03-27 13:12:53

	%Detect connected components in the frame and return ROI CC data structure
	CC = bwconncomp(g3);  %
	L = labelmatrix(CC);  %Not used
	%figure; imshow(label2rgb(L));	
	STATS = regionprops(CC,'Centroid');  % 

	newPixelIdxList = {};
	count = 0;
	for i = 1:CC.NumObjects
		centrInd = sub2ind(CC.ImageSize(1:2),round(STATS(i).Centroid(2)),round(STATS(i).Centroid(1)));	
		if	(length(intersect(centrInd,backgroundIndices)) < 1) & (length(intersect(CC.PixelIdxList{i},imageBorderIndices)) < 1)    %maybe change this threshold, to more than one px intersect like a percentage
	%		if	(length(intersect(centrInd,backgroundIndices)) < 1) & (length(intersect(CC.PixelIdxList{i},imageBorderIndices)) < 1)    %maybe change this threshold, to more than one px intersect like a percentage
	%		if	(length(intersect(centrInd,backgroundIndices)) < 1) & (length(intersect(CC.PixelIdxList{i},imageBorderIndices)) < 1) & (length(intersect(CC.PixelIdxList{i},hemisphereBorders)) < 1)    %maybe change this threshold, to more than one px intersect like a percentage
			count = count+1;
			newPixelIdxList{count} = CC.PixelIdxList{i};
		end
	end
	CC.PixelIdxList = newPixelIdxList;
	CC.NumObjects = length(CC.PixelIdxList);

	%Make rgb label matrix from the CC ROIs
	L = labelmatrix(CC);
%	figure; imshow(label2rgb(L));	%TESTING

	w = L == 0;
	g4 = g3 & ~w;
	%figure, imshow(g4)

%	figure, imshow(g4&bothMasks)   %TESTING

	se = strel('disk',edgeSmooth2);
	g5 = imclose(g4,se);
	bwFrame = g5&bothMasks;
%	figure; imshow(bwFrame); title('bw close')   %TESTING
	%-------end new Algorithm-------------------------------------

	A2(:,:,fr) = bwFrame;
	
	%Optional--Show the frame and prep for .avi movie making if desired
	if showFigure > 0
		imshow(label2rgb(L));	
		M(fr) = getframe;
	end
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
	vidObj = VideoWriter(fnm3)
	open(vidObj)
	for i =1:numel(M)
		writeVideo(vidObj,M(i));
	end
	close(vidObj)

%write the motion JPEG .avi to disk using auto-generated datestring based filename
	fnm3 = [fnm2(1:length(fnm2)-4) '-mask' '.avi']; 
	vidObj = VideoWriter(fnm3)
	open(vidObj)
	for i =1:numel(F)
		writeVideo(vidObj,F(i));
	end
	close(vidObj)
end
