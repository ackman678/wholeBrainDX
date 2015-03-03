function [A2, A, thresh, Amin, Amax] = wholeBrain_segmentationOtsu(fnm,backgroundRemovRadius,region,hemisphereIndices,showFigure,makeMovies,thresh,pthr,sigma,useSobel,A)
%PURPOSE -- segment functional domains in wholeBrain calcium imaging movies into ROIs
%USAGE -- 	[A2, A] = wholeBrain_segmentation(fnm,[],region)
%			[A2, A, thresh, Amin] = wholeBrain_segmentation('120518_07.tif',60,region,[2 3],0,1,[],0.99,5);
%			[A2, A, thresh, Amin] = wholeBrain_segmentation(fn,backgroundRemovRadius,region,hemisphereIndices,0,makeInitMovies,grayThresh,pthr,sigma);
%
%INPUTS
%	fnm - string, raw movie filename. This name will be passed to bfopen.m for reading in the imaging data. This name will also be formatted for writing .avi movies.
% 	backgroundRemovRadius - single numeric in pixels. Default corresponds to 681 µm radius (round(681/region.spaceres)) for the circular structured element used for background subtraction.
%	region - 
% 	hemisphereIndices - vector of integers, region.coord index locations in region.name for gross anatomical brain regions like 'cortex.L' and 'cortex.R' and others (e.g. 'OB.L', 'OB.R', 'SC.L', 'SC.R', etc).
%	showFigure - binary true/false to show intermediate plots. Default is 0 (false). As of 2014-07-28 09:24:06 this functionality probabaly work properly and needs to be updated. 
% 	makeMovies - binary true/false to indicate if you want to make avis. Defaults to 1 (true)
% 	thresh - single numeric logical. Default is 1, for estimating the graythreshold using Otsu's method for each movie separately. Alternative is to use previous movie graythresh (like for subsequent recordings).
% 	pthr - single numeric. Default is 0.99. Percentile threshold for the sobel edge based detection algorithm in wholeBrain_segmentation.m
%	sigma is the standard deviation in pixels of the gaussian for smoothing. It is 56.75µm at 11.35µm/px dimensions to give a **5px sigma**. gaussSmooth.m multiplies the sigma by 2.25 standard deviations for the filter size by default.
%
%OUTPUTS
%	A2 - binary array of segmented signals
%	A  - double array of raw dF/F movie, positively shifted
%	thresh - the calculated Otsu threshold
%	Amin - the minimum value from the original zero centered dF/F array, (can be used to calculate original zero centered dF/F signal amplitudes).
%
%James B. Ackman
%2012-12-20
%updated, improved algorithm with gaussian smooth 2013-02-01 by J.B.A.
%modified 2013-03-28 14:25:44 by J.B.A.
% Optimized and simplified algoritm 2014-05-21 16:06:48 by J.B.A.
% Switched read tiff to imread to make bioformats dependency optional 2014-12-31 09:54:00 J.B.A.
%
% Except where otherwise noted, all code in this program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
if nargin < 11 || isempty(A), 
	loadMovie = 1; 
else
	loadMovie = 0;
end
if nargin < 10 || isempty(useSobel), useSobel = 1; end
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

if loadMovie
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
end
[pathstr, name, ext] = fileparts(fnm);
fnm2 = [name '_wholeBrain_segmentation_' datestr(now,'yyyymmdd-HHMMSS') '.avi']; 

if loadMovie
	if isfield(region,'extraFiles')
	    if ~isempty(region.extraFiles)
	        extraFiles = region.extraFiles;
	    end
	else
	    extraFiles = [];
	end
	A = openMovie(fnm,extraFiles);
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

%Make deltaF/F movie ( (F - F0)/F0 normalizaion at each pixel )
% Amean = mean(A,3);
% for i = 1:size(A,3)
% 		A(:,:,i) = (A(:,:,i) - Amean)./Amean;
% end
if loadMovie
npix = prod(sz(1:2));
A = reshape(A, npix, szZ); %reshape 3D array into space-time matrix
Amean = mean(A,2); %avg at each pixel location in the image over time
A = A ./ (Amean * ones(1,szZ)) - 1;   % F/F0 - 1 == ((F-F0)/F0);
A = reshape(A, sz(1), sz(2), szZ);
end
Amin = min(reshape(A,prod(size(A)),1));
Amax = max(reshape(A,prod(size(A)),1));
A = mat2gray(A);  %Scale deltaF array

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

parfor fr = 1:szZ; %option:parfor
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

[h, x] = imhist(reshape(G,numel(G),1));

if showFigure > 0; figure; stem(x,h); end
%	pthr = 0.99;
Q = prctileThresh(h,pthr);
%	markerImage = grad > Q;
markerImage = G > Q;
%	[level,est] = graythresh(grad);  %Otsu's threshold from Image Processing Toolbox  
%	markerImage = im2bw(grad,level);  %Make binary based on Otsu's threshold
if showFigure > 0; figure; imshow(markerImage(:,:,1),[]); end

%	fp = f.*markerImage; 
if useSobel
	fp = Iarr.*markerImage; 
else
	fp = Iarr.*bothMasks3D;
end

[hp, x] = imhist(reshape(fp,numel(fp),1));
if showFigure > 0
figure, imshow(fp(:,:,1),[])
figure, stem(x,hp)
end

hp(1) = 0;  %assumes that most pixels in bin #1 are black level pixels that shouldn't count towards the Otsu threshold calculation
if showFigure > 0; 
figure; stem(x,hp); 
figure; hist((reshape(Iarr,prod(size(Iarr)),1) .* (Amax - Amin)) - abs(Amin),40)
end
T = otsuthresh(hp);
%	T*(numel(hp) - 1)
if makeThresh < 1
	%If false, ignore the threshold, T, set above and use preexisting otsu threshold (for drug movies) passed as handle
	T = thresh;
end

disp(['mat2gray T ' num2str(T)])
disp(['orig scale T ' num2str((T* (Amax - Amin)) - abs(Amin))])

%======BEGIN segmentation=================================================================
parfor fr = 1:szZ; %option:parfor

	bw = Iarr(:,:,fr) > T;

	%Detect connected components in the frame and return ROI CC data structure----------------
	%CC = bwconncomp(bw);
	S = regionprops(bw, 'Area', 'Centroid', 'PixelIdxList');

	if ~isempty(S)
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
	else
		bw2=bw;
	end

	A2(:,:,fr) = bothMasks & bw2;
	%A2(:,:,fr) = bw2;
	%-----------------------------------------------------------------------------------------
end

thresh = T;

%Optional--Export .avi movie if desired
%write the motion JPEG .avi videos to disk using auto-generated datestring based filename
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
		[I2, map2] = gray2ind(A2(:,:,fr), 8); %figure; imshow(I2,map)
		F(fr) = im2frame(I2,map2);  %setup the binary segmented mask movie
	end

	fnm3 = [fnm2(1:length(fnm2)-4) '-dFoF' '.avi']; 
	writeMovie(M,fnm3);

	fnm3 = [fnm2(1:length(fnm2)-4) '-mask' '.avi'];
	writeMovie(F,fnm3);
end
