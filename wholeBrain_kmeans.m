function [A3, CC, STATS] = wholeBrain_kmeans(A2,A,Nclusters,showFigure,fnm)
%PURPOSE -- use kmeans clustering to clean up segmentation from wholeBrain_segmentation.m
%INPUTS -- 
%A2: the binary array returned from wholeBrain_segmentation  
%A: the raw dF/F image array that was returned from and passed to wholeBrain_segmentation.m originally
%Nclusters: optional integer stating how many k-clusters to detect
%USAGE -- [A3, CC] = wholeBrain_kmeans(A2,A)
%SEE AlSO -- kmeans, wholeBrain_segmentation.m
%James B. Ackman
%2012-12-20
% update 2013-10-31 15:42:02 JBA to used mean, duration, diameter for clustering and to remove single frame activations in the largest cluster

%-----setup default parameters-------
if nargin < 5 || isempty(fnm),
	fnm2 = ['wholeBrain_kmeans_' datestr(now,'yyyymmdd-HHMMSS') '.avi']; 
else
	fnm2 = [fnm(1:length(fnm)-4) '_wholeBrain_kmeans_' '.avi']; 
end

if nargin < 4 || isempty(showFigure), showFigure = 0; end %default is to not show the figures (faster)

if nargin < 3 || isempty(Nclusters), Nclusters = 3; end %default Number of k-means clusters to optimize

myColors = lines(Nclusters);  %if more more than 8 clusters, then change this colormap accordingly 
%Nclusters = 3;
Nreplicates = 5;  %5 repetitions is typically fine.


%-----Get 3D connected components structure and some STATS available for n-D arrays-----
CC = bwconncomp(A2);
STATS = regionprops(CC,A,'Area','BoundingBox', 'Centroid', 'MaxIntensity', 'MinIntensity', 'MeanIntensity');  %some of the properties in regionprops that work on n-D arrays
%STATS = regionprops(CC,A,'Area','BoundingBox', 'Centroid', 'MaxIntensity', 'MinIntensity', 'MeanIntensity', 'FilledArea', 'FilledImage', 'Image', 'PixelIdxList', 'PixelList', 'SubarrayIdx'); %all the properties in regionprops that work on n-D arrays

%Get measurements that will be used as inputs to kmeans---
centr = vertcat(STATS.Centroid);
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
%hemisphereIndices = [2 3];
%sz = size(A2);
%regionMask1 = poly2mask(region.coords{hemisphereIndices(1)}(:,1),region.coords{hemisphereIndices(1)}(:,2),sz(1),sz(2));
%regionMask2 = poly2mask(region.coords{hemisphereIndices(2)}(:,1),region.coords{hemisphereIndices(2)}(:,2),sz(1),sz(2));
%%figure; imshow(regionMask1); 	figure; imshow(regionMask2);
%bothMasks = regionMask1|regionMask2;  %makes a combined image mask of the two hemispheres
%bwBorders = bwperim(bothMasks);
%%figure; imshow(bwBorders) %TESTING
%[row,col] = find(bwBorders);
%edgeSubIdx = [col row];   %n x 2 array of subarray indices for hemisphere outlines.
%
%edgeDistances=zeros(size(centr,1),1);
%for i=1:size(centr,1)
%	vCentr=repmat(centr(i,1:2), size(edgeSubIdx,1),1);
%	vSqDist=sum((vCentr-edgeSubIdx).^2,2);
%	minSqDist=min(vSqDist);
%	euclDist=sqrt(minSqDist);
%	edgeDistances(i,1)=euclDist;
%end
%
%sqDist = edgeDistances .^ 2;
%sqDist = abs(max(sqDist)-sqDist);
%figure; plot3(centr(:,1),centr(:,2),sqDist(:,1),'o')  %TESTING, to check that the distribution is correct
%title('raw squared distances inverted')
%
%sqDist = edgeDistances .^ 2;
%sqDist = abs(max(sqDist)-sqDist);
%sqDist=(sqDist/max(sqDist));
%figure; plot3(centr(:,1),centr(:,2),sqDist(:,1),'o')  %TESTING, to check that the distribution is correct
%title('normalized inverted squared distances within [0,1]')
%
%%edgeDistances = abs(1-edgeDistances) .^ 2;
%figure; plot3(centr(:,1),centr(:,2),edgeDistances(:,1),'o')  %TESTING, to check that the distribution is correct


%------Do the clustering procedure------------------
%X = [(roiMean/max(roiMean))' (durations/max(durations)) (roiArea/max(roiArea))' (roiMax/max(roiMax))' (edgeDistances/max(edgeDistances))];  %make data matrix to pass to kmeans for clustering  
%X = [(roiMean/max(roiMean))' (durations/max(durations)) (roiArea/max(roiArea))' (roiMax/max(roiMax))'];  %make data matrix to pass to kmeans for clustering  % **previous default from 2013-03-27**

%X = [sqDist (durations/max(durations)) (roiArea/max(roiArea))'];
%X = [(roiMean/max(roiMean))' (durations/max(durations)) (roiArea/max(roiArea))' (roiMax/max(roiMax))' sqDist];  %make data matrix to pass to kmeans for clustering  

X = [(roiMean/max(roiMean))' (durations/max(durations)) (diameters/max(diameters))];  %make data matrix to pass to kmeans for clustering  
xlab = 'roiMean'; ylab = 'duration'; zlab = 'diameters'; 

cidx = kmeans(X,Nclusters,'replicates',Nreplicates);   %we want two clusters and the default clustering method (sq euclidean)  

NumObjects = [];
for i = 1:Nclusters
	NumObjects = [NumObjects numel(find(cidx == i))];
end
disp(NumObjects)

sortNumObj = sort(NumObjects,'descend');
sz = size(A2);

%---Make plots of all clusters---
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
colormap(myColors); colorbar; title(['domain centroid location, k=' num2str(Nclusters) ',' num2str(Nreplicates) 'reps']);% view(180,90)
print(gcf, '-dpng', [fnm2(1:end-4) datestr(now,'yyyymmdd-HHMMSS') '.png']);
print(gcf, '-depsc', [fnm2(1:end-4) datestr(now,'yyyymmdd-HHMMSS') '.eps']);

figure;   
hold on  
for j = 1:Nclusters 
%	j = find(sortNumObj == NumObjects(i));   
	i = find(NumObjects == sortNumObj(j));  
	plot3(X(cidx==i,1),X(cidx==i,2),X(cidx==i,3),'o','Color',myColors(j,:))     %plot3(X(cidx==i,1),X(cidx==i,2),X(cidx==i,3),'o')  
	hold on  
end  
xlabel(xlab); ylabel(ylab); zlabel(zlab);  
colormap(myColors); colorbar; title(['kmeans inputs distribution, k=' num2str(Nclusters) ',' num2str(Nreplicates) 'reps']); view(3)  
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


%-------Figure out which clusters to keep and get vector of object indices------- 
%here we assume that the objects of interest will be in the minority population (smaller number of objects) to automatically fetch the cluster index
%NumObjects = [numel(find(cidx == 1)) numel(find(cidx == 2))];
%clusterIdx = find(NumObjects == min(NumObjects));

%Again we assume that the objects will be in minority, but here we make assumption that noise component is the single largest cluster
%TODO: Will have to change and make option of making interactive, or together with automated selection based on population distance from hemisphere edge, where edge effects lead to greatest source of noise


%{
%original from 2013-03-27
NumObjects = [];
for i = 1:Nclusters
NumObjects = [NumObjects numel(find(cidx == i))];
end
NumObjects
NoiseClusterIdx = find(NumObjects == max(NumObjects));  %change to interactive or automated based on TODO item above
ObjectIndices = find(cidx ~= NoiseClusterIdx);
GoodClusters = unique(cidx(cidx ~= NoiseClusterIdx));

%---Make plot of only good clusters---
figure;   
hold on  
for i = 1:length(GoodClusters)  
	plot3(centr(cidx==GoodClusters(i),1),centr(cidx==GoodClusters(i),2),centr(cidx==GoodClusters(i),3),'o','Color',myColors(GoodClusters(i),:))
	hold on  
end  
colormap(myColors); colorbar; title(['domain centroid location for good clusters, k=' num2str(Nclusters) ',' num2str(Nreplicates) 'reps']); view(180,90)
print(gcf, '-dpng', [fnm2(1:end-4) 'kmeans' datestr(now,'yyyymmdd-HHMMSS') '-3.png']);

%}

%Single frame activation noise removal on big cluster algorithm

%---Make plots of all clusters---
NoiseClusterIdx = find(NumObjects == max(NumObjects));
badComponents = find(durations<2 & cidx==NoiseClusterIdx);
ObjectIndices =  setdiff(1:length(durations),badComponents);

tmp = {};
tmp{1} = 'total no. of good:';
tmp{2} = num2str(numel(ObjectIndices));
disp(tmp)

%---Make plot of only good clusters---
figure; plot(centr(ObjectIndices,1),centr(ObjectIndices,2),'o','Color',myColors(1,:)); title('durations > 1fr')
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

%clear STATS

if exist('A')
	STATS = regionprops(CC,A,'Area','BoundingBox', 'Centroid', 'MaxIntensity', 'MinIntensity', 'MeanIntensity', 'FilledArea', 'FilledImage', 'Image', 'PixelIdxList', 'PixelList', 'SubarrayIdx'); %all the properties in regionprops that work on n-D arrays
else
	STATS = regionprops(CC,'Area','BoundingBox', 'Centroid', 'FilledArea', 'FilledImage', 'Image', 'PixelIdxList', 'PixelList', 'SubarrayIdx'); %all the properties in regionprops that work on n-D arrays
end


%Now make a binary movie array based on the segmented functional signal domains
A3 = zeros(size(A2),'uint8');
for i = 1:CC.NumObjects
A3(CC.PixelIdxList{i}) = 1;
end
A3 = logical(A3);
CCnew=CC;

%Transform the binary array into a matlab specific 'movie' data structure that can be written as an motion JPEG .avi to disk.
if showFigure > 0
	for fr=1:size(A3,3)
	imshow(A3(:,:,fr))
	M(fr) = getframe;
	end
else
	for fr=1:size(A3,3)
	I=mat2gray(A3(:,:,fr));
	[I2, map] = gray2ind(I, 8); %figure; imshow(I2,map)
	M(fr) = im2frame(I2,map);
	end
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


%write the motion JPEG .avi to disk using auto-generated datestring based filename
%vidObj = VideoWriter(fnm2)
%open(vidObj)
%for i =1:numel(M)
%writeVideo(vidObj,M(i));
%end
%close(vidObj)



