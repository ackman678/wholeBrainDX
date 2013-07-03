function [A2, A] = wholeBrain_segmentation(fnm,backgroundRemovRadius,region,hemisphereIndices,showFigure)
%PURPOSE -- segment functional domains in wholeBrain calcium imaging movies into ROIs
%USAGE -- A2 = wholeBrain_segmentation(fnm,[],region)
%James B. Ackman
%2012-12-20
%updated, improved algorithm with watershed separation and gaussian smooth 2013-02-01 by J.B.A.
%modified 2013-03-28 14:25:44 by J.B.A.

if nargin < 5 || isempty(showFigure), showFigure = 0; end %default is to not show the figures (faster)
if nargin < 4 || isempty(hemisphereIndices), hemisphereIndices = [2 3]; end  %index location of the hemisphere region outlines in the 'region' hippo struct
if nargin < 3 || isempty(region), region = myOpen; end  %to load the hemisphere region outlines from 'region' hippo struct
if nargin < 2 || isempty(backgroundRemovRadius); backgroundRemovRadius = 60; end   %radius in pixels, should be a few times larger than the biggest object of interest in the image


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
    save('hippoprefs.mat', 'pathname','filename')
end

fnm2 = [fnm(1:length(fnm)-4) '_wholeBrain_segmentation_' datestr(now,'yyyymmdd-HHMMSS') '.avi']; 

[data, series1] = myOpenOMEtiff(fnm);
A = double(series1);
clear data series1
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


%The following assumes that the 'region' data structure will have outlines of the hemispheres drawn at index locations 2 and 3. Should make interactive or default preference saving
regionMask1 = poly2mask(region.coords{hemisphereIndices(1)}(:,1),region.coords{hemisphereIndices(1)}(:,2),sz(1),sz(2));
regionMask2 = poly2mask(region.coords{hemisphereIndices(2)}(:,1),region.coords{hemisphereIndices(2)}(:,2),sz(1),sz(2));
%figure; imshow(regionMask1); 	figure; imshow(regionMask2);
bothMasks = regionMask1|regionMask2;  %makes a combined image mask of the two hemispheres

%------Make pixelindex lists for background component removal within for loop below-----------
x = [10 sz(2)-10 sz(2)-10 10 10];  %make image border outline 10 px wide to intersect 
y = [10 10 sz(1)-10 sz(1)-10 10];  %make image border outline 10 px wide to intersect 
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

%------Start core for loop-------------------------
%figure;
parfor fr = 1:szZ;
%	I = (double(A(:,:,fr)) - Amean)./Amean;   %for big array testing, make double
%	I = I + abs(min(I(:)));   %***Doing the minvalue addition in this step makes the background levels fluctuate severely from frame to frame!

	I = A(:,:,fr);
%	I(~bothMasks) = 0;
%	figure, imshow(I,[])
%	
%	bwNoise = imnoise(I,'gaussian');  %add gaussian background noise, so that corr value can always be calculated
%	figure, imshow(bwNoise,[])

%	I = A(:,:,fr);  %get frame  %original
%	figure; imshow(I,[]); title('I')	
	%Perform tophat filtering (background subtraction)
	
%	ballRadius = 120;
%	ballHeight = 5;
%	se = strel('ball',ballRadius,ballHeight);
		
	se = strel('disk',backgroundRemovRadius);
	background = imopen(I,se);  %make sure backgroundRemovRadius strel object is bigger than the biggest objects (functional domains) that you want to detect in the image
	I2 = I - background;  %subtract background
%	figure; imshow(I2,[]); title('I2')
	
	I2 = gaussSmooth(I2,5,'same');
%		figure, imshow(img2,[])
		
	%Adjust filtered image contrast, estimate Otsu's threshold, then binarize the frame, and remove single pixel noise
	I3 = imadjust(I2);  %increase image contrast, saturating 1% of data at both low and high intensities.
 	[level,est] = graythresh(I3);  %Otsu's threshold
	bw = im2bw(I3,level);  %Make binary based on Otsu's threshold
%	figure; imshow(bw,[]); title('bw')
	bw = bwareaopen(bw, 50);  %remove background single isolated pixel noise. 50 is matlab default value?
%	figure; imshow(bw,[]); title('bwareaopen 50')

	%-------Begin new algorithm-----------------------
	se = strel('disk',2);
	bw2 = imdilate(bw,se);
	%bw2 = imfill(bw2,'holes');
	%figure, imshow(bw2,[]); title('fill')

%------------TESTING 2013-03-27 13:12:53---------------
%{
	D = bwdist(~bw2);   %Euclidean distance transform of the binary image
	%figure, imshow(D,[],'InitialMagnification','fit'); title('Distance transform of ~bw')
	D = -D;   %invert of distance matrix
	D(~bw2) = -Inf;   %sets zero level pixels in the binary mask to negative infinity
	L = watershed(D);  %computes label matrix of the watershed regions
	rgb = label2rgb(L,'jet',[.5 .5 .5]);    %colorize regions for figure
%	figure, imshow(rgb,'InitialMagnification','fit'); title('Watershed transform of D')   %TESTING

	w = L == 0;   %shortcut to identify pixels in the L watershed label matrix that are background

	g2 = bw2 & ~w;  %make new binary image that does not include the 
	%figure, imshow(g2)

	g3 = bwareaopen(g2, 50);  %remove background single isolated pixel noise. 50 is matlab default value?
	%figure; imshow(g3,[]); title('bwareaopen 50')
%}
	g3 = bw2;  %TESTING 2013-03-27 13:12:53
%-------------END TESTING-------------------------------


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
	%}

		%Make rgb label matrix from the CC ROIs
	L = labelmatrix(CC);
%	figure; imshow(label2rgb(L));	%TESTING

	w = L == 0;
	g4 = g3 & ~w;
	%figure, imshow(g4)

%	figure, imshow(g4&bothMasks)   %TESTING

	se = strel('disk',3);
	g5 = imclose(g4,se);
	bwFrame = g5&bothMasks;
%	figure; imshow(bwFrame); title('bw close')   %TESTING
	%-------end new Algorithm-------------------------------------


%{
%--------------begin original algorithm------------------------	
	%Exclude pixels in the bw image that are outside the hemisphere masks to make new Exclude image mask
	bwExclude = bw&bothMasks;
	figure; imshow(bwExclude); title('bwareaopen & mask')
	
	%Smooth the new image mask with a 3 px radius disk to fill in most of the small holes in any components in the mask
	se = strel('disk',3);
	bw2 = imclose(bwExclude,se);
	figure; imshow(bwExclude); title('bw close')
	
	%Detect connected components in the frame and return ROI CC data structure
	CC = bwconncomp(bw2);
	L = labelmatrix(CC);
	figure; imshow(label2rgb(L));	
	
	%Make border mask of the hemispheres and make the border a little bit wider with a square image dilation of 3 px?
	bwBorders = bwperim(bothMasks);
	%figure, imshow(bwBorders);
	se = strel('square',3);
	bwBorders = imdilate(bwBorders,se);
	figure, imshow(bwBorders)
	
	%Find the pixel indices for those on the border and find out which CC ROI objects overlap with these border pixels and remove them from the CC ROI data structure
	%This assumes that most of the functional signals on the borders will be edge effect artifacts (like from z-movements, etc). This is probably mostly true, 
	%but can certainly diminsh the number detected functional signals and domains from areas on the edges, like retrosplenial, cingulate, parts of V1, A1, S2, Ent etc.  
	%This algorithm is simple and fast but could be improved. These following lines can be commented out if necessary as well.
%
	backgroundIndices = find(bwBorders);
	newPixelIdxList = {};
	count = 0;
	for i = 1:CC.NumObjects
		if	length(intersect(CC.PixelIdxList{i},backgroundIndices)) < 1   %maybe change this threshold, to more than one px intersect like a percentage
		count = count+1;
		newPixelIdxList{count} = CC.PixelIdxList{i};
		end
	end
	CC.PixelIdxList = newPixelIdxList;
	CC.NumObjects = length(CC.PixelIdxList);


	%Make rgb label matrix from the CC ROIs
	L = labelmatrix(CC);


	
	%Concatenate the resulting frame mask into a binary movie array for output
	bwFrame=im2bw(L,0);
	%--------------end orig------------------------
%}
		
%	if fr > 1
%		A2 = cat(3,A2,bwFrame);
%	else
%		A2 = bwFrame;
%	end
	
	A2(:,:,fr) = bwFrame;
	
	%Optional--Show the frame and prep for .avi movie making if desired
	if showFigure > 0
		imshow(label2rgb(L));	
		M(fr) = getframe;
	else
		I=mat2gray(A2(:,:,fr));
		[I2, map] = gray2ind(I, 8); %figure; imshow(I2,map)
		%[I2, map] = gray2ind(I, 256); %figure; imshow(I2,map)
		M(fr) = im2frame(I2,map);
		
		I=mat2gray(g5);
		[I2, map] = gray2ind(I, 8); %figure; imshow(I2,map)
		F(fr) = im2frame(I2,map);
	end
	
end

%Optional--Export .avi movie if desired
%if showFigure > 0
%	vidObj = VideoWriter(['wholeBrain_' datestr(now,'yyyymmdd-HHMMSS') '.avi'])
%	open(vidObj)
%	for i =1:numel(M)
%		writeVideo(vidObj,M(i));
%	end
%	close(vidObj)
%end


%write the motion JPEG .avi to disk using auto-generated datestring based filename
%vidObj = VideoWriter(fnm2)
%open(vidObj)
%for i =1:numel(M)
%writeVideo(vidObj,M(i));
%end
%close(vidObj)

%write the motion JPEG .avi to disk using auto-generated datestring based filename
vidObj = VideoWriter(fnm2)
open(vidObj)
for i =1:numel(F)
writeVideo(vidObj,F(i));
end
close(vidObj)
