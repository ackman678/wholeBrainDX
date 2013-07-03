function [A3, CC, STATS] = wholeBrain_kmeans(A2,A,showFigure,fnm)
%PURPOSE -- use kmeans clustering to clean up segmentation from wholeBrain_segmentation.m
%need the binary A2 array returned from wholeBrain_segmentation and the raw dF/F image array that was input to wholeBrain_segmentation.m originally
%USAGE -- [A3, CC] = wholeBrain_kmeans(A2,A)
%James B. Ackman
%2012-12-20

if nargin < 4 || isempty(fnm),
	fnm2 = ['wholeBrain_kmeans_' datestr(now,'yyyymmdd-HHMMSS') '.avi']; 
else
	fnm2 = [fnm(1:length(fnm)-4) '_wholeBrain_kmeans_' datestr(now,'yyyymmdd-HHMMSS') '.avi']; 
end


if nargin < 3 || isempty(showFigure), showFigure = 0; end %default is to not show the figures (faster)
CC = bwconncomp(A2);
STATS = regionprops(CC,A,'Area','BoundingBox', 'Centroid', 'MaxIntensity', 'MinIntensity', 'MeanIntensity');  %some of the properties in regionprops that work on n-D arrays
%STATS = regionprops(CC,A,'Area','BoundingBox', 'Centroid', 'MaxIntensity', 'MinIntensity', 'MeanIntensity', 'FilledArea', 'FilledImage', 'Image', 'PixelIdxList', 'PixelList', 'SubarrayIdx'); %all the properties in regionprops that work on n-D arrays

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

%X = [(roiMean/max(roiMean))' (roiMax/max(roiMax))' (roiArea/max(roiArea))' (roiMin/max(roiMin))'];  %adding in minIntensity draws too much similarity between signal and noise
X = [(roiMean/max(roiMean))' (roiMax/max(roiMax))' (roiArea/max(roiArea))'];  %make data matrix to pass to kmeans for clustering
cidx = kmeans(X,2,'replicates',5);   %we want two clusters and the default clustering method (sq euclidean)
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

%here we assume that the objects of interest will be in the minority population (smaller number of objects) to automatically fetch the cluster index
NumObjects = [numel(find(cidx == 1)) numel(find(cidx == 2))];
clusterIdx = find(NumObjects == min(NumObjects));
ObjectIndices = find(cidx == clusterIdx);

%now we remake the connected components (CC) data structure by keeping only the objects in the cluster of interest (the functional signal cluster)
newPixelIdxList = {};
count = 0;
for i = 1:length(ObjectIndices)
	count = count+1;
	newPixelIdxList{count} = CC.PixelIdxList{ObjectIndices(i)};
end
CC.PixelIdxList = newPixelIdxList;
CC.NumObjects = length(CC.PixelIdxList);

clear STATS
STATS = regionprops(CC,A,'Area','BoundingBox', 'Centroid', 'MaxIntensity', 'MinIntensity', 'MeanIntensity', 'FilledArea', 'FilledImage', 'Image', 'PixelIdxList', 'PixelList', 'SubarrayIdx'); %all the properties in regionprops that work on n-D arrays

%Now make a binary movie array based on the segmented functional signal domains
A3 = zeros(size(A),'uint8');
for i = 1:CC.NumObjects
A3(CC.PixelIdxList{i}) = 1;
end
A3 = logical(A3);

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



