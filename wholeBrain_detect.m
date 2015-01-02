function [A3, CC, STATS] = wholeBrain_detect(A2,A,NclustersAll,showFigure,fnm,region,hemisphereIndices,makePlots)
%PURPOSE -- detect domains from segmented movie from wholeBrain_segmentation.m
%INPUTS --
%A2: the binary array returned from wholeBrain_segmentation
%A: the raw dF/F image array that was returned from and passed to wholeBrain_segmentation.m originally
%NclustersAll: optional integer vector stating how many k-clusters to detect for each pass
%
%OPTIONS --
% By default, the only detected components that will be removed are those lasting only 1 frame in duration. This is set around ln 165 as `badComponents = find(durations<2);`
% The preceding lines around ln 165 can be uncommented to accept only the kmeans detected signal components that are automatically detected, **but not accepted by default**
% TODO: add optional flag on whether to make use of kmeans clustering (default is off).
% TODO: add option to pass alternative 'badComponents' vector, as could be done using alternate n-D signal decomposition techniques.
%
%USAGE -- [A3, CC] = wholeBrain_detect(A2,A)
%SEE AlSO -- kmeans, wholeBrain_segmentation.m
%James B. Ackman
%2012-12-20
% update 2013-10-31 15:42:02 JBA to used mean, duration, diameter for clustering and to remove single frame activations in the largest cluster
% update 2013-11-21 JBA to implemented sqDist algo to be passed to clustering.
% update 2013-12-31 JBA set default to just remove detected components lasting <2 frames in duration as default for wholeBrain paper.
% update 2014-05-01 14:15:54 JBA changed name to wholeBrain_detect.m and edited documentation.
%
% Except where otherwise noted, all code in this program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.

% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.

% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.



%-----setup default parameters-------
%assuming [2 3] are the region.name location indices for 'cortex.L' and 'cortex.R'
if nargin < 8 || isempty(makePlots), makePlots = 1; end
if nargin < 7 || isempty(hemisphereIndices), hemisphereIndices = find(strcmp(region.name,'cortex.L') | strcmp(region.name,'cortex.R')); end
if nargin < 6 || isempty(region),
    motorSignal = [];
    region = [];
else
    if isfield(region,'motorSignal')
        motorSignal = region.motorSignal;
    else
        motorSignal = [];
    end
end  %a downsampled motorSignal same length as n movie frames can be input to help clustering

if nargin < 5 || isempty(fnm),
    fnm2 = ['wholeBrain_detect_' datestr(now,'yyyymmdd-HHMMSS') '.avi'];
else
    fnm2 = [fnm(1:length(fnm)-4) '_wholeBrain_detect_' datestr(now,'yyyymmdd-HHMMSS') '.avi'];
end

if nargin < 4 || isempty(showFigure), showFigure = 0; end %default is to not show the figures (faster)

if nargin < 3 || isempty(NclustersAll),
    NclustersAll = 3;
end %default Number of k-means clusters to optimize

if length(NclustersAll) < 2,
    NclustersAll = repmat(NclustersAll,1,2);
end

myColors = lines(max(NclustersAll));  %if more more than 8 clusters, then change this colormap accordingly
%Nclusters = 3;
Nreplicates = 5;  %5 repetitions is typically fine.
sz = size(A2);

CC = bwconncomp(A2);
%{
%---1st pass----------------------------------------------------------------------------
[centr,centrZ,motorAmpl,roiArea,roiMean,roiMax,durations,diameters,sqDist] = getMetrics(CC,A,region,motorSignal,hemisphereIndices);

if ~isempty(region) && ~isempty(motorSignal)
    %2013-11-21 12:02:10
    X = [sqDist (durations/max(durations))  (motorAmpl/max(motorAmpl))' (diameters/max(diameters)) (roiMean/max(roiMean))'];  %make data matrix to pass to kmeans for clustering
    xlab = 'sqDist'; ylab = 'duration'; zlab = 'motorAmpl'; %zlab = 'diameters';
    
    %	X = [(roiMean/max(roiMean))' (durations/max(durations))  (motorAmpl/max(motorAmpl))' (diameters/max(diameters))];  %make data matrix to pass to kmeans for clustering
    %	xlab = 'roiMean'; ylab = 'duration'; zlab = 'motorAmpl'; %zlab = 'diameters';
    
    Nclusters = NclustersAll(1);
    [cidx,ctrs] = kmeans(X,Nclusters,'replicates',Nreplicates);   %we want two clusters and the default clustering method (sq euclidean)
    
    NumObjects = [];
    for i = 1:Nclusters
        NumObjects = [NumObjects numel(find(cidx == i))];
    end
    disp(NumObjects)
    
    plotDomainCentroids(cidx,NumObjects,xlab,ylab,zlab,sz,fnm2,Nclusters,Nreplicates,centr,myColors,'1st pass domain centroid location');
    plotClusters(X,cidx,NumObjects,xlab,ylab,zlab,sz,fnm2,Nclusters,Nreplicates,centr,myColors,'1st pass kmeans inputs distribution');
    
    %-------Figure out which clusters to keep and get vector of object indices-------
    %[mx,NoiseClusterIdx] = max(ctrs(:,3));  %3rd column from input matrix X above is the motor signal amplitudes. We want the cluster centroid having the max motor signal to be the noise cluster idx in this 1st pass.
    %[mx,NoiseClusterIdx] = max(ctrs(:,1));  %1st column from input matrix X above is the sqDist. We want the cluster centroid having the max motor signal to be the noise cluster idx in this 1st pass.
    %Find the cluster that is closest to the max sqDist, and min duration, and max motorAmpl:
    edgeSubIdx = [1 0 1];  %sqDist is 1st col, dur is 2nd col, motorAmpl is 3rd col;
    
    ctrs2 = ctrs(:,1:3);  %1st 3 columns of cluster centers
    edgeDistances=zeros(size(ctrs2,1),1);
    for i=1:size(ctrs2,1)
        vCentr=repmat(ctrs2(i,1:3), size(edgeSubIdx,1),1);
        vSqDist=sum((vCentr-edgeSubIdx).^2,2);
        minSqDist=min(vSqDist);
        euclDist=sqrt(minSqDist);
        edgeDistances(i,1)=euclDist;
    end
    [mn,NoiseClusterIdx] = min(edgeDistances);
    
    %NoiseClusterIdx = find(NumObjects == max(NumObjects));
    
    badComponents = find(cidx==NoiseClusterIdx);  %if Removing all domains from the NoiseClusterIdx
    
    ObjectIndices =  setdiff(1:length(durations),badComponents);
    
    %---Make plot of only good clusters---
    figure; plot(centr(ObjectIndices,1),centr(ObjectIndices,2),'o','Color',myColors(1,:)); title('1st pass Noise cluster removed') %title('durations > 1fr')
    axis image; axis ij; %axis off
    ylim([1 sz(1)]); xlim([1 sz(2)]); colormap(myColors); colorbar;
    print(gcf, '-dpng', [fnm2(1:end-4) datestr(now,'yyyymmdd-HHMMSS') '-3.png']);
    print(gcf, '-depsc', [fnm2(1:end-4) datestr(now,'yyyymmdd-HHMMSS') '-3.eps']);
    
    %ObjectIndices=goodComponents;  %TESTING. Line goes with <= 1 frame delete noise code above.
    %----Remake CC data structure with desired objects (deleting noise components)----
    %now we remake the connected components (CC) data structure by keeping only the objects in the cluster of interest (the functional signal cluster)
    newPixelIdxList = {};
    count = 0;
    for i = 1:length(ObjectIndices)
        count = count+1;
        newPixelIdxList{count} = CC.PixelIdxList{ObjectIndices(i)};
    end
    CCorig=CC;
    CC.PixelIdxList = newPixelIdxList;
    CC.NumObjects = length(CC.PixelIdxList);
    
end
%}


%---2nd pass----------------------------------------------------------------------------
[centr,centrZ,motorAmpl,roiArea,roiMean,roiMax,durations,diameters,sqDist] = getMetrics(CC,A,region,motorSignal,hemisphereIndices);

%------Do the clustering procedure------------------
%X = [(roiMean/max(roiMean))' (durations/max(durations)) (roiArea/max(roiArea))' (roiMax/max(roiMax))' (edgeDistances/max(edgeDistances))];  %make data matrix to pass to kmeans for clustering
%X = [(roiMean/max(roiMean))' (durations/max(durations)) (roiArea/max(roiArea))' (roiMax/max(roiMax))'];  %make data matrix to pass to kmeans for clustering  % **previous default from 2013-03-27**

%X = [sqDist (durations/max(durations)) (roiArea/max(roiArea))'];
%X = [(roiMean/max(roiMean))' (durations/max(durations)) (roiArea/max(roiArea))' (roiMax/max(roiMax))' sqDist];  %make data matrix to pass to kmeans for clustering

%2013-10
X = [(roiMean/max(roiMean))' (durations/max(durations)) (diameters/max(diameters))];  %make data matrix to pass to kmeans for clustering
xlab = 'roiMean'; ylab = 'duration'; zlab = 'diameters';

Nclusters = NclustersAll(2);
[cidx,ctrs] = kmeans(X,Nclusters,'replicates',Nreplicates);   %we want two clusters and the default clustering method (sq euclidean)

NumObjects = [];
for i = 1:Nclusters
    NumObjects = [NumObjects numel(find(cidx == i))];
end
disp(NumObjects)

if makePlots
plotDomainCentroids(cidx,NumObjects,xlab,ylab,zlab,sz,fnm2,Nclusters,Nreplicates,centr,myColors,'2nd pass domain centroid location');
plotClusters(X,cidx,NumObjects,xlab,ylab,zlab,sz,fnm2,Nclusters,Nreplicates,centr,myColors,'2nd pass kmeans inputs distribution');
end
%-------Figure out which clusters to keep and get vector of object indices-------
%Single frame activation noise removal on big cluster algorithm
%NoiseClusterIdx = find(NumObjects == max(NumObjects));

%Find the cluster with the shortest average durations, and choose that as the candidate noise cluster:
[mn,NoiseClusterIdx] = min(ctrs(:,2));  %2nd column from input matrix X is the durations,

%badComponents = find(durations<2 & cidx==NoiseClusterIdx);  %if Removing only 1fr activation domains from the NoiseClusterIdx
%badComponents = find(durations<2 & sqDist>=0.95);  %if Removing only 1fr activation domains from the NoiseClusterIdx
badComponents = find(durations<2);  %if Removing only 1fr activation domains from the NoiseClusterIdx
ObjectIndices =  setdiff(1:length(durations),badComponents);

tmp = {};
tmp{1} = 'total no. of good:';
tmp{2} = num2str(numel(ObjectIndices));
disp(tmp)

if makePlots
%---Make plot of only good clusters---
figure; plot(centr(ObjectIndices,1),centr(ObjectIndices,2),'o','Color',myColors(1,:)); title('2nd pass Noise cluster removed') %title('durations > 1fr')
axis image; axis ij; %axis off
ylim([1 sz(1)]); xlim([1 sz(2)]); colormap(myColors); colorbar;
print(gcf, '-dpng', [fnm2(1:end-4) datestr(now,'yyyymmdd-HHMMSS') '-3.png']);
print(gcf, '-depsc', [fnm2(1:end-4) datestr(now,'yyyymmdd-HHMMSS') '-3.eps']);
end
%ObjectIndices=goodComponents;  %TESTING. Line goes with <= 1 frame delete noise code above.
%----Remake CC data structure with desired objects (deleting noise components)----
%now we remake the connected components (CC) data structure by keeping only the objects in the cluster of interest (the functional signal cluster)
newPixelIdxList = {};
count = 0;
for i = 1:length(ObjectIndices)
    count = count+1;
    newPixelIdxList{count} = CC.PixelIdxList{ObjectIndices(i)};
end
CCorig=CC;
CC.PixelIdxList = newPixelIdxList;
CC.NumObjects = length(CC.PixelIdxList);



%---Finish---
if exist('A')
%    STATS = regionprops(CC,A,'Area','BoundingBox', 'Centroid', 'MaxIntensity', 'MinIntensity', 'MeanIntensity', 'FilledArea', 'FilledImage', 'Image', 'PixelIdxList', 'PixelList', 'SubarrayIdx'); %all the properties in regionprops that work on n-D arrays   in 2014a FilledImage and FilledArea take too long, not needed anyways
    STATS = regionprops(CC,A,'Area','BoundingBox', 'Centroid', 'MaxIntensity', 'MinIntensity', 'MeanIntensity', 'Image', 'PixelIdxList', 'PixelList', 'SubarrayIdx'); %all the properties in regionprops that work on n-D arrays
else
%    STATS = regionprops(CC,'Area','BoundingBox', 'Centroid', 'FilledArea', 'FilledImage', 'Image', 'PixelIdxList', 'PixelList', 'SubarrayIdx'); %all the properties in regionprops that work on n-D arrays % in 2014a FilledImage and FilledArea take too long, not needed anyways
    STATS = regionprops(CC,'Area','BoundingBox', 'Centroid', 'Image', 'PixelIdxList', 'PixelList', 'SubarrayIdx'); %all the properties in regionprops that work on n-D arrays
end

A3 = getMovie(CC,A2,fnm2,sz,showFigure);









function [centr,centrZ,motorAmpl,roiArea,roiMean,roiMax,durations,diameters,sqDist] = getMetrics(CC,A,region,motorSignal,hemisphereIndices)
%-----Get 3D connected components structure and some STATS available for n-D arrays-----
STATS = regionprops(CC,A,'Area','BoundingBox', 'Centroid', 'MaxIntensity', 'MinIntensity', 'MeanIntensity');  %some of the properties in regionprops that work on n-D arrays
%STATS = regionprops(CC,A,'Area','BoundingBox', 'Centroid', 'MaxIntensity', 'MinIntensity', 'MeanIntensity', 'FilledArea', 'FilledImage', 'Image', 'PixelIdxList', 'PixelList', 'SubarrayIdx'); %all the properties in regionprops that work on n-D arrays

%Get measurements that will be used as inputs to kmeans---
centr = vertcat(STATS.Centroid);
centrZ = round(centr(:,3));

if ~isempty(motorSignal)
    %	rateChan = rateChannels(region,[],0);  %region.motorSignal processed in rateChannels to give moving average timecourse
    %	motorAmpl = rateChan(1).y(centrZ);  %assuming 1st rate channel is 50 fr lag channel (10 sec moving average)
    motorAmpl = region.motorSignal(centrZ);
else
    motorAmpl = [];
end

roiArea=[STATS.Area];  %Scalar; the actual number of pixels in the region. (This value might differ slightly from the value returned by bwarea, which weights different patterns of pixels differently.
%figure; hist(roiArea,20); title('area')  %can see two separate populations

%Centroid' – 1-by-Q vector that specifies the center of mass of the region. Note that the first element of Centroid is the horizontal coordinate (or x-coordinate) of the center of mass, and the second element is the vertical coordinate (or y-coordinate). All other elements of Centroid are in order of dimension.
%roiBoundingBox=[STATS.BoundingBox]; % BoundingBox' — The smallest rectangle containing the region, a 1-by-Q *2 vector, where Q is the number of image dimensions: ndims(L), ndims(BW), or numel(CC.ImageSize). BoundingBox is [ul_corner width], where: ul_corner is in the form [x y z ...] and specifies the upper-left corner of the bounding box width is in the form [x_width y_width ...] and specifies the width of the bounding box along each dimension
roiMean=[STATS.MeanIntensity];
%figure; hist(roiMean,20); title('mean intensity')  %can see two separate populations
roiMax=[STATS.MaxIntensity];
%roiMin=[STATS.MinIntensity];
%figure; hist(roiMax,20); title('max intensity')    %can see two separate populations
%figure; plot3(roiMean,roiMax,roiArea,'o')  %can see two separate populations

roiBoundingBox = zeros(length(STATS),6);
for i = 1:length(STATS)
    roiBoundingBox(i,:) = STATS(i).BoundingBox;
end

durations = roiBoundingBox(:,6);  %add to kmeans
diameters = mean([roiBoundingBox(:,4) roiBoundingBox(:,5)], 2);

%----TESTING-- following several lines are to find domains with durations of just 1 fr for 5fr/sec recordings (mostly noise component) for comparison with noise component isolated from kmeans. Not needed/not useful. Rationale outlined in [[2013-01-30_wholeBrain_analysis.txt]].
%goodComponents = find(durations>1);
%figure; plot3(centr(goodComponents,1),centr(goodComponents,2),centr(goodComponents,3),'o')
%badComponents = find(durations<2);
%figure; plot3(centr(badComponents,1),centr(badComponents,2),centr(badComponents,3),'o')
%length(durations)-length(goodComponents)

%----TESTING-- following lines are to find distance from edge of hemisphere. Not needed/not useful. Rationale outlined in [[2013-01-30_wholeBrain_analysis.txt]].
%Assuming region is loaded into workspace
if ~isempty(region)
    sz = size(region.image);
    bothMasks=false(sz(1),sz(2));
    for nRoi=1:length(hemisphereIndices)
		regionMask = poly2mask(region.coords{hemisphereIndices(nRoi)}(:,1),region.coords{hemisphereIndices(nRoi)}(:,2),sz(1),sz(2));
		%regionMask2 = poly2mask(region.coords{hemisphereIndices(2)}(:,1),region.coords{hemisphereIndices(2)}(:,2),sz(1),sz(2));
		%figure; imshow(regionMask1); 	figure; imshow(regionMask2);
		bothMasks = bothMasks|regionMask;  %makes a combined image mask of the two hemispheres
    end
    bwBorders = bwperim(bothMasks);
    %figure; imshow(bwBorders) %TESTING
    [row,col] = find(bwBorders);
    edgeSubIdx = [col row];   %n x 2 array of subarray indices for hemisphere outlines.
    
    edgeDistances=zeros(size(centr,1),1);
    for i=1:size(centr,1)
        vCentr=repmat(centr(i,1:2), size(edgeSubIdx,1),1);
        vSqDist=sum((vCentr-edgeSubIdx).^2,2);
        minSqDist=min(vSqDist);
        euclDist=sqrt(minSqDist);
        edgeDistances(i,1)=euclDist;
    end
    %
    %sqDist = edgeDistances .^ 2;
    %sqDist = abs(max(sqDist)-sqDist);
    %figure; plot3(centr(:,1),centr(:,2),sqDist(:,1),'o')  %TESTING, to check that the distribution is correct
    %title('raw squared distances inverted')
    %
    sqDist = edgeDistances .^ 2;
    sqDist = abs(max(sqDist)-sqDist);
    sqDist=(sqDist/max(sqDist));
    %figure; plot3(centr(:,1),centr(:,2),sqDist(:,1),'o')  %TESTING, to check that the distribution is correct
    %title('normalized inverted squared distances within [0,1]')
    %
    %%edgeDistances = abs(1-edgeDistances) .^ 2;
    %figure; plot3(centr(:,1),centr(:,2),edgeDistances(:,1),'o')  %TESTING, to check that the distribution is correct
else
    sqDist = [];
end






function A3 = getMovie(CC,A2,fnm2,sz,showFigure)
%Now make a binary movie array based on the segmented functional signal domains
A3 = false(sz);
for i = 1:CC.NumObjects
    A3(CC.PixelIdxList{i}) = 1;
end

%L = labelmatrix(CC);
%imshow(label2rgb(L));
%M(fr) = getframe;
%
%bwFrame=im2bw(L,0);
%if fr > 1
%A3 = cat(3,A3,bwFrame);
%else
%A3 = bwFrame;
%end

%fname = [datestr(now,'yyyymmdd-HHMMSS') '_figure' num2str(gcf) '_fr' num2str(fr)];
%print(gcf, '-dpng', fname);

%Transform the binary array into a matlab specific 'movie' data structure that can be written as an motion JPEG .avi to disk.
%write the motion JPEG .avi to disk using auto-generated datestring based filename
if showFigure > 0
    for fr=1:size(A3,3)
        I=mat2gray(A3(:,:,fr));
        [I2, map] = gray2ind(I, 8); %figure; imshow(I2,map)
        M(fr) = im2frame(I2,map);
    end
    writeMovie(M,fnm2);
end







function plotDomainCentroids(cidx,NumObjects,xlab,ylab,zlab,sz,fnm2,Nclusters,Nreplicates,centr,myColors,titleStr)
%---Make plots of all clusters---
sortNumObj = sort(NumObjects,'descend');

figure;
hold on
for j = 1:Nclusters
    %	j = find(sortNumObj == NumObjects(i));
    i = find(NumObjects == sortNumObj(j));
    %plot3(centr(cidx==i,1),centr(cidx==i,2),centr(cidx==i,3),'o','Color',myColors(j,:))
    plot(centr(cidx==i,1),centr(cidx==i,2),'o','Color',myColors(j,:))
    hold on
end
axis image; axis ij; %axis off
ylim([1 sz(1)]); xlim([1 sz(2)]);
colormap(myColors); colorbar; title([titleStr ', k=' num2str(Nclusters) ',' num2str(Nreplicates) 'reps']);% view(180,90)
print(gcf, '-dpng', [fnm2(1:end-4) datestr(now,'yyyymmdd-HHMMSS') '.png']);
print(gcf, '-depsc', [fnm2(1:end-4) datestr(now,'yyyymmdd-HHMMSS') '.eps']);






function plotClusters(X,cidx,NumObjects,xlab,ylab,zlab,sz,fnm2,Nclusters,Nreplicates,centr,myColors,titleStr)

sortNumObj = sort(NumObjects,'descend');

figure;
hold on
for j = 1:Nclusters
    %	j = find(sortNumObj == NumObjects(i));
    i = find(NumObjects == sortNumObj(j));
    plot3(X(cidx==i,1),X(cidx==i,2),X(cidx==i,3),'o','Color',myColors(j,:))     %plot3(X(cidx==i,1),X(cidx==i,2),X(cidx==i,3),'o')
    hold on
end
xlabel(xlab); ylabel(ylab); zlabel(zlab);
colormap(myColors); colorbar; title([titleStr ', k=' num2str(Nclusters) ',' num2str(Nreplicates) 'reps']); view(3)
%ylim([0.03 0.07])  %scaled for testing purposes, single outlier in test distribution based on max intensity (bad pixel?)
print(gcf, '-dpng', [fnm2(1:end-4) datestr(now,'yyyymmdd-HHMMSS') '-2.png']);
print(gcf, '-depsc', [fnm2(1:end-4) datestr(now,'yyyymmdd-HHMMSS') '-2.eps']);

%figure;
%plot3(X(cidx==1,1),X(cidx==1,2),X(cidx==1,3),'ro')
%hold on
%plot3(X(cidx==2,1),X(cidx==2,2),X(cidx==2,3),'bo'); title('kmeans,norm eucl')

%[silh3,h] = silhouette(X,cidx,'sqeuclidean')
%
%eucD = pdist(X,'euclidean');
%clustTreeEuc = linkage(eucD,'average');
%cophenet(clustTreeEuc,eucD)
%
%[h,nodes] = dendrogram(clustTreeEuc,0);
%set(gca,'TickDir','out','TickLength',[.002 0],'XTickLabel',[]);




