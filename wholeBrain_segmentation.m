function [A2, A, thresh, Amin, Amax] = wholeBrain_segmentation(fnm,A,region,thresh,sigma,hemisphereIndices,makeMovies)
%PURPOSE -- segment functional domains in wholeBrain calcium imaging movies into ROIs
%USAGE -- 	[A2, A] = wholeBrain_segmentation(fnm,[],region)
%			[A2, A, thresh, Amin] = wholeBrain_segmentation('120518_07.tif',60,region,[2 3],0,1,[],0.99,5);
%			[A2, A, thresh, Amin] = wholeBrain_segmentation(fn,backgroundRemovRadius,region,hemisphereIndices,0,makeInitMovies,grayThresh,pthr,sigma);
%
%INPUTS
%	fnm - string, raw movie filename. This name will be passed to bfopen.m for reading in the imaging data. This name will also be formatted for writing .avi movies.
%	region - 
% 	hemisphereIndices - vector of integers, region.coord index locations in region.name for gross anatomical brain regions like 'cortex.L' and 'cortex.R' and others (e.g. 'OB.L', 'OB.R', 'SC.L', 'SC.R', etc).
% 	makeMovies - binary true/false to indicate if you want to make avis. Defaults to 1 (true)
% 	thresh - single numeric, threshold to use for signal detection. Defaults to 2 standard deviations.
%	sigma is the standard deviation in pixels of the gaussian for smoothing. It is 56.75µm at 11.35µm/px dimensions to give a **5px sigma**. gaussSmooth.m multiplies the sigma by 2.25 standard deviations for the filter size by default.
%
%OUTPUTS
%	A2 - binary array of segmented signals
%	A  - double array of movie
%	thresh - the threshold used
%	Amin - the minimum value from the original movie array
%	Amax - the maximum value from the original movie array
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

if nargin < 7 || isempty(makeMovies), makeMovies = 1; end
if nargin < 6 || isempty(hemisphereIndices), hemisphereIndices = find(strcmp(region.name,'cortex.L') | strcmp(region.name,'cortex.R')); end  %index location of the hemisphere region outlines in the 'region' calciumdx struct
if nargin < 5 || isempty(sigma), sigma = 3; end
if nargin < 4 || isempty(thresh), thresh = 2; end
if nargin < 2 || isempty(A) || size(A,3) == 1
	%Try loading and reconstructing a movie from a saved svd decomposition that has PCuse (principal components to use) defined.
	try
	[pathstr,name,~]=fileparts(fnm);
	%Find .mat files in movie directory with svd*.mat in the name.
	listing = dir([fullfile(pathstr,name) '*svd*.mat']);
	n=length(listing);
	load(fullfile(pathstr,listing(n).name));  %Load the most recent svd mat file
	catch exception
		rethrow(exception)
		error('cannot find the svd.mat file...')
	end
	sz=size(mixedfilters);
    npix = prod(sz(1:2));
    szXY = sz(1:2); szZ = size(mixedsig,2);
    mixedfilters2 = reshape(mixedfilters(:,:,PCuse),npix,length(PCuse));  
    A = mixedfilters2 * diag(CovEvals(PCuse).^(1/2)) * mixedsig(PCuse,:);  %reconstruct using svd, A = USV'; 
    A = zscore(reshape(A,npix*szZ,1)); %covert to standardized zscores so that mean=0, and sd = 1;
    A = reshape(A, szXY(1), szXY(2), szZ);  
end

[pathstr, name, ext] = fileparts(fnm);
fnm2 = [name '_wholeBrain_segmentation_' datestr(now,'yyyymmdd-HHMMSS') '.avi']; 

sz = size(A);
szXY = sz(1:2);
szZ=sz(3);

Amin = min(reshape(A,prod(size(A)),1));
Amax = max(reshape(A,prod(size(A)),1));

bothMasks= false(sz(1),sz(2));
for nRoi=1:length(hemisphereIndices)
	regionMask = poly2mask(region.coords{hemisphereIndices(nRoi)}(:,1),region.coords{hemisphereIndices(nRoi)}(:,2),sz(1),sz(2));
	bothMasks = bothMasks|regionMask;  %makes a combined image mask of the two hemispheres
end

M(size(A,3)) = struct('cdata',[],'colormap',[]);
F(size(A,3)) = struct('cdata',[],'colormap',[]);
A2=false(size(A));
Iarr=zeros(size(A));
bothMasks3D = repmat(bothMasks,[1 1 szZ]);

parfor fr = 1:szZ; %option:parfor
	I = A(:,:,fr);
		I2 = gaussSmooth(I,sigma,'same');
	Iarr(:,:,fr) = I2;
end	

T = thresh;

%======BEGIN segmentation=================================================================
bw = Iarr > T;
A2 = bothMasks3D & bw;

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
