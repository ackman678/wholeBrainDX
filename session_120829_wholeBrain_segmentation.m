
%-----matlab demo for Otsu's threshold based image segmenation after global noise reduction using strel()
I = imread('rice.png');
imshow(I)
background = imopen(I,strel('disk',15));  %tophat filtering
figure, surf(double(background(1:8:end,1:8:end))),zlim([0 255]);  %view background image
set(gca,'ydir','reverse');
background = imopen(I,strel('disk',15));
figure, surf(double(background(1:8:end,1:8:end))),zlim([0 255]);  %view background image
set(gca,'ydir','reverse');
I2 = I - background;  %subtract background
figure, imshow(I2)
I3 = imadjust(I2);  %increase image contrast, saturating 1% of data at both low and high intensities.
figure, imshow(I3);
[level,em] = graythresh(I3)  %Otsu's threshold
bw = im2bw(I3,level);
figure, imshow(bw)
bw = bwareaopen(bw, 50);  %remove background noise
figure, imshow(bw)



%-----test matlab demo segmentation routine on my data---  120703_01_fr2400-3000.tif, frames 240-280.
for fr = [4 6 26 29]
%fr=26;
	img1 = A(:,:,fr);
	I = img1;
		for i = [7 15 30 60 120]
			h=figure;
			subplot(4,2,1)
			imshow(I,[]); title(['fr ' num2str(fr)])
			background = imopen(I,strel('disk',i));
			subplot(4,2,2)
			imshow(background,[]); title(['background, disk ' num2str(i)])
			% figure, surf(double(background(1:8:end,1:8:end))),zlim([0 255]);  %view backgour image
			% set(gca,'ydir','reverse');
			I2 = I - background;  %subtract background
			subplot(4,2,3); imshow(I2,[]); title('background subtract')
			I3 = imadjust(I2);  %increase image contrast, saturating 1% of data at both low and high intensities.
			subplot(4,2,4); imshow(I3); title('imadjust')
			[level,est] = graythresh(I3)  %Otsu's threshold
			bw = im2bw(I3,level);
			subplot(4,2,5); imshow(bw); title(['level=' num2str(level) ', est=' num2str(est)])
			bw = bwareaopen(bw, 50);  %remove background noise
			subplot(4,2,6); imshow(bw); title('bwareaopen 50')
			[level,est] = graythresh(I)  %Otsu's threshold
			bw = im2bw(I,level);
			subplot(4,2,7); imshow(bw); title('bw raw')
			bw = bwareaopen(bw, 50);  %remove background noise
			subplot(4,2,8); imshow(bw); title('bw raw open')
			fname = [datestr(now,'yyyymmdd-HHMMSS') '_figure' num2str(gcf) '_fr' num2str(fr)];
			print(gcf, '-dpng', fname);
			close(h)
		end
end



%test texture filters----------------------------------------------------
fr=26;
img1 = A(:,:,fr);
I = img1;
%I = imread('circuit.tif'); 
J = entropyfilt(I);   %doesn't help with raw df image data ------------
figure, imshow(I,[]); figure, imshow(J,[]); 

J = rangefilt(I);   %doesn't help with raw df image data --------------
figure, imshow(I,[]); figure, imshow(J,[]);

graycoprops    %test
S = qtdecomp(I)  %test
Surf(3d) %test, implement for my data sets. Look at brain surface rendering

%3D conncomp------------------------------------------%will be difficult to use effectively. stick with 2D
BW = cat(3, [1 1 0; 0 0 0; 1 0 0],...
            [0 1 0; 0 0 0; 0 1 0],...
            [0 1 1; 0 0 0; 0 0 1]);

CC = bwconncomp(BW);
S = regionprops(CC,'Centroid')

figure; surf(BW)


%----------test Sobel filter---------------------------------------------%doesn't really provide any advantage for this data, and could actually just make things worse possibly.
fr=26;
img1 = A(:,:,fr);
f = img1;
figure, imshow(f,[]);
sx = fspecial('sobel');
sy=sx';
gx = imfilter(f, sx, 'replicate');
gy = imfilter(f, sy, 'replicate');
grad = sqrt(gx.*gx + gy.*gy);
grad = grad/max(grad(:));
h = imhist(grad);
Q = percentile2i(h, 0.999);

markerImage = grad > Q;
figure, imshow(markerImage,[])
fp = f.*markerImage;
figure, imshow(fp)
hp = imhist(fp);
%hp = imhist(f);

hp(1) = 0;
bar(hp,0)
T = otsuthresh(hp);
T*(numel(hp) - 1)

g = im2bw(f, T);
figure; imshow(g)




%---------watershed segmentation using gradients--- %also not useful, oversegmentation. Might try on tophat filtered/contrast adjusted image though.
fr=26;
img1 = A(:,:,fr);
f = img1;
figure, imshow(f,[]);
sx = fspecial('sobel');
sy=sx';
gx = imfilter(f, sx, 'replicate');
gy = imfilter(f, sy, 'replicate');
grad = sqrt(gx.*gx + gy.*gy);

L = watershed(grad);   %gradient image segmentation, might have oversegmentation
wr = L == 0;
figure; imshow(wr)

grad2 = imclose(imopen(grad, ones(3,3)), ones(3,3));  %smooth the gradient image
L2 = watershed(grad2);
wr2 = L2 == 0;
f2 = f;
f2(wr2) = 255;
figure; imshow(f2)

%---------There is also discussion in Gonzales of a Marker-controlled Watershed segmentation, which might be the best.  But still best only on an image with low background. tophat filtered/contrast adjusted image though.


%----------tophat filtering----------------
fr=26;
img1 = A(:,:,fr);
i=60;
I = img1;
h=figure;
subplot(4,2,1)
imshow(I,[]); title(['fr ' num2str(fr)])
background = imopen(I,strel('disk',i));
subplot(4,2,2)
imshow(background,[]); title(['background, disk ' num2str(i)])
% figure, surf(double(background(1:8:end,1:8:end))),zlim([0 255]);  %view backgour image
% set(gca,'ydir','reverse');
I2 = I - background;  %subtract background
subplot(4,2,3); imshow(I2,[]); title('background subtract')
I3 = imtophat(I,strel('disk',i));  %increase image contrast, saturating 1% of data at both low and high intensities.
subplot(4,2,4); imshow(I3); title('tophat')

fr=26;
img1 = A(:,:,fr);
i=60;
I = img1;
h=figure;
subplot(2,1,1)
imshow(I,[])
subplot(2,1,2)
I2 = mat2gray(I);
imshow(I2,[])


%-----tst more otsu filtering  120703_01_fr2400-3000.tif, frames 240-280.-------different thresholding options (otsu from image, and otsu from histogram with blocking out black pixel bin for improved separation)
for fr = [26]
%fr=26;
	img1 = A(:,:,fr);
	I = img1;
	 i = [60]
			h=figure;
			subplot(4,5,1)
			imshow(I,[]); title(['fr ' num2str(fr)])

			subplot(4,5,2)
			hp = imhist(I);			
			hp(1) = 0;
			bar(hp,0)
			level2 = otsuthresh(hp);

			subplot(4,5,3)
			[level,est] = graythresh(I)  %Otsu's threshold
			bw = im2bw(I,level); 
			imshow(bw,[]); title('bw')

			subplot(4,5,4)
			bw = im2bw(I,level2); 
			imshow(bw,[]); title('bw')

			subplot(4,5,5); 
			bw = bwareaopen(bw, 50);  %remove background noise
			imshow(bw); title('bwareaopen 50')


			subplot(4,5,6); 
			background = imopen(I,strel('disk',i));
			I2 = I - background;  %subtract background
			imshow(I2,[]); title('background subtract')
			
			subplot(4,5,7)
			hp = imhist(I2);			
			hp(1) = 0;
			bar(hp,0)
			level2 = otsuthresh(hp);

			subplot(4,5,8); 
			[level,est] = graythresh(I2)  %Otsu's threshold
			bw = im2bw(I2,level);
			imshow(bw,[]); title('bw')					

			subplot(4,5,9)
			bw = im2bw(I2,level2); 
			imshow(bw,[]); title('bw')

			subplot(4,5,10); 
			bw = bwareaopen(bw, 50);  %remove background noise
			imshow(bw); title('bwareaopen 50')
			
			
			subplot(4,5,11); 
			I3 = imadjust(I2);  %increase image contrast, saturating 1% of data at both low and high intensities.
			imshow(I3); title('imadjust')
			
			subplot(4,5,12)
			hp = imhist(I3);			
			hp(1) = 0;
			bar(hp,0)
			level2 = otsuthresh(hp);
			
			subplot(4,5,13); 
			[level,est] = graythresh(I3)  %Otsu's threshold
			bw = im2bw(I3,level);
			imshow(bw,[]); title('bw')
			
			subplot(4,5,14)
			bw = im2bw(I3,level2); 
			imshow(bw,[]); title('bw')
			
			subplot(4,5,15); 
			bw = bwareaopen(bw, 50);  %remove background noise
			imshow(bw); title('bwareaopen 50')			
			
			
			
			
			subplot(4,2,5); imshow(bw); title(['level=' num2str(level) ', est=' num2str(est)])
			bw = bwareaopen(bw, 50);  %remove background noise
			subplot(4,2,6); imshow(bw); title('bwareaopen 50')
			[level,est] = graythresh(I)  %Otsu's threshold
			bw = im2bw(I,level);
			subplot(4,2,7); imshow(bw); title('bw raw')
			bw = bwareaopen(bw, 50);  %remove background noise
			subplot(4,2,8); imshow(bw); title('bw raw open')
			fname = [datestr(now,'yyyymmdd-HHMMSS') '_figure' num2str(gcf) '_fr' num2str(fr)];
			print(gcf, '-dpng', fname);
			close(h)
		end
end






[data, series1] = myOpenOMEtiff;
load('/Volumes/Vega/Users/ackman/Data/2photon/120703i/120703_01_AVG_dummy_outlines_areas.mat')
%load test_opticalflow.mat
%save('test_opticalflow.mat')
% waveONidx=1103;
% waveOFFidx=1182;
waveONidx=240;
waveOFFidx=280;

% waveONidx=region.wavedata{2}.waveonsets(6);
% waveOFFidx=region.wavedata{3}.waveoffsets(8);
A = double(series1(:,:,waveONidx:waveOFFidx));
Amean = mean(A,3);
for i = 1:size(A,3)
%     A(:,:,i) = (A(:,:,i) - region.image)./region.image;
    A(:,:,i) = (A(:,:,i) - Amean)./Amean;
end

sz = size(A);
regionMask1 = poly2mask(region.coords{2}(:,1),region.coords{2}(:,2),sz(1),sz(2));
regionMask2 = poly2mask(region.coords{3}(:,1),region.coords{3}(:,2),sz(1),sz(2));
figure; imshow(regionMask1); 	figure; imshow(regionMask2);
bothMasks = regionMask1|regionMask2;
%fr1ind = find(bothMasks);

%-----tst same with hemi ROI OR and extra erosion-------------
fr=26;
%	img1 = A(:,:,fr);
%	I = img1;
	i = [60]; backgroundRemovDiam = i; 
	h=figure;
	subplot(4,1,1)
	I = A(:,:,fr);	
%    I(bothMasks<1) = 0; imshow(I)
	background = imopen(I,strel('disk',backgroundRemovDiam));  %make sure backgroundRemovDiam strel object is bigger than the biggest objects (functional domains) that you want to detect in the image
	I2 = I - background;  %subtract background
	I3 = imadjust(I2);  %increase image contrast, saturating 1% of data at both low and high intensities.
	[level,est] = graythresh(I3);  %Otsu's threshold
	bw = im2bw(I3,level);
	bw = bwareaopen(bw, 50);  %remove background single isolated pixel noise
%	subplot(3,1,2); 
	imshow(bw); title('bwareaopen 50')

	subplot(4,1,2); 
	bwExclude = bw&bothMasks;
	imshow(bwExclude); title('bwareaopen & mask')

	subplot(4,1,3); 
	se = strel('disk',3)
	bw2 = imclose(bwExclude,se);
	imshow(bwExclude); title('bw close')
	
	subplot(4,1,4); 
	CC = bwconncomp(bw2);
	L = labelmatrix(CC);
	imshow(label2rgb(L));	




	figure;	imshow(label2rgb(L));	
%	fr1ind = intersect(find(regionMask1),find(BW));

bwBorders = bwperim(bothMasks);
figure, imshow(bwBorders);
se = strel('square',3);

bwBorders = imdilate(bwBorders,se);
figure, imshow(bwBorders)

borderIndices = find(bwBorders);
newPixelIdxList = {};
count = 0
for i = 1:CC.NumObjects
	if	length(intersect(CC.PixelIdxList{i},borderIndices)) < 1 
	count = count+1;
	newPixelIdxList{count} = CC.PixelIdxList{i}
	end
end
CC.PixelIdxList = newPixelIdxList;
CC.NumObjects = length(CC.PixelIdxList);
L = labelmatrix(CC);
figure, imshow(label2rgb(L));	

%	STATS = regionprops(CC,'Area','Centroid')
%	areas=[STATS.Area];

	fname = [datestr(now,'yyyymmdd-HHMMSS') '_figure' num2str(gcf) '_fr' num2str(fr)];
	print(gcf, '-dpng', fname);
	close(h)

end


%--------TEST kmean segregation of 3D connected components in Image bw array A2 returned from segmentWholeBrain.m

CC = bwconncomp(A2);
STATS = regionprops(CC,A,'Area', 'Centroid', 'MaxIntensity', 'MinIntensity', 'MeanIntensity');  %all the properties in regionprops that work on n-D arrays
roiArea=[STATS.Area]; 
figure; hist(roiArea,20); title('area')  %can see two separate populations
roiMean=[STATS.MeanIntensity]; 
figure; hist(roiMean,20); title('mean intensity')  %can see two separate populations
roiMax=[STATS.MaxIntensity];
figure; hist(roiMax,20); title('max intensity')    %can see two separate populations
figure; plot3(roiMean,roiMax,roiArea,'o')  %can see two separate populations

X = [(roiMean/max(roiMean))' (roiMax/max(roiMax))' (roiArea/max(roiArea))'];
idx = kmeans(X,2);
figure;
plot3(X(idx==1,1),X(idx==1,2),X(idx==1,3),'ro')
hold on
plot3(X(idx==2,1),X(idx==2,2),X(idx==2,3),'bo'); title('kmeans,norm eucl')

[silh3,h] = silhouette(X,idx,'sqeuclidean')

eucD = pdist(X,'euclidean');
clustTreeEuc = linkage(eucD,'average');
cophenet(clustTreeEuc,eucD)

[h,nodes] = dendrogram(clustTreeEuc,0);
set(gca,'TickDir','out','TickLength',[.002 0],'XTickLabel',[]);


NumObjects = [numel(find(idx == 1)) numel(find(idx == 2))];
clusterIdx = find(NumObjects == min(NumObjects));
ObjectIndices = find(idx == clusterIdx);

newPixelIdxList = {};
count = 0
for i = ObjectIndices
	count = count+1;
	newPixelIdxList{count} = CC.PixelIdxList{i};
end
CC.PixelIdxList = newPixelIdxList;
CC.NumObjects = length(CC.PixelIdxList);



X = [(roiMean)' (roiMax)' (roiArea)'];
idx = kmeans(X,2);
figure;
plot3(X(idx==1,1),X(idx==1,2),X(idx==1,3),'ro')
hold on
plot3(X(idx==2,1),X(idx==2,2),X(idx==2,3),'bo'); title('kmeans,eucl')

X = [(roiMean)' (roiMax)' (roiArea)'];
idx = kmeans(X,2,'distance','correlation');
figure;
plot3(X(idx==1,1),X(idx==1,2),X(idx==1,3),'ro')
hold on
plot3(X(idx==2,1),X(idx==2,2),X(idx==2,3),'bo'); title('kmeans, corr')

X = [(roiMean/max(roiMean))' (roiMax/max(roiMax))' (roiArea/max(roiArea))'];
idx = kmeans(X,2,'distance','correlation');
figure;
plot3(X(idx==1,1),X(idx==1,2),X(idx==1,3),'ro')
hold on
plot3(X(idx==2,1),X(idx==2,2),X(idx==2,3),'bo'); title('kmeans,norm corr')

X = [(roiMean)' (roiMax)' (roiArea)'];
idx = kmeans(X,2,'distance','cityblock');
figure;
plot3(X(idx==1,1),X(idx==1,2),X(idx==1,3),'ro')
hold on
plot3(X(idx==2,1),X(idx==2,2),X(idx==2,3),'bo'); title('kmeans, city')

X = [(roiMean)' (roiMax)' (roiArea)'];
idx = kmeans(X,2,'distance','cosine');
figure;
plot3(X(idx==1,1),X(idx==1,2),X(idx==1,3),'ro')
hold on
plot3(X(idx==2,1),X(idx==2,2),X(idx==2,3),'bo'); title('kmeans, cosine')


%--------------------------workflow--------------------------------------------------
[data, series1] = myOpenOMEtiff;
load('/Volumes/Vega/Users/ackman/Data/2photon/120703i/120703_01_AVG_dummy_outlines_areas.mat');
%waveONidx=240;
%waveOFFidx=280;
%A = double(series1(:,:,waveONidx:waveOFFidx));
A = double(series1);
Amean = mean(A,3);
for i = 1:size(A,3)
%     A(:,:,i) = (A(:,:,i) - region.image)./region.image;
    A(:,:,i) = (A(:,:,i) - Amean)./Amean;
end
tic
A2 = wholeBrain_segmentation(A,[],region);
[A3, CC] = wholeBrain_kmeans(A2,A);
toc
tic
A2 = wholeBrain_segmentation(series1,[],region);
[A3, CC] = wholeBrain_kmeans(A2,series1);
toc

%-------Make movie array with with raw intensity values within the functional ROIs--------
minValue = abs(min(A(:)));
A4 = (A + minValue);  %.*2^16;  %scale data to fit within uint16 range [0,2^16), because df/F gives negative values   %commented out, keep double for mat2gray
A4(A3<1) = 0;  %A3 from wholeBrain_kmeans and wholeBrain_segmentation
A4=mat2gray(A4);

%---------------------sum/max projection of possible domains------------------------------
sm=sum(A4,3);
mx=max(sm(:));
A5 = sum(A4,3)./mx;
A5 = max(A4,[],3);
figure; imshow(A5,'displayrange',[],'colormap',jet(256));


%---------------------Save movie array as avi---------------------------------------------
%A4 = mat2gray(A4);
%A4 = A4.*2^16;  %scale data to fit within uint16 range [0,2^16)
for fr=1:size(A4,3)
I=A4(:,:,fr);
[I2, map] = gray2ind(I, 256); %figure; imshow(I2,map)
M(fr) = im2frame(I2,map);
end

vidObj = VideoWriter(['wholeBrain_' datestr(now,'yyyymmdd-HHMMSS') '.avi'])
open(vidObj)
for i =1:numel(M)
writeVideo(vidObj,M(i));
end
close(vidObj)





%-------------2012-11-26---------------------------------------------------

[data, series1] = myOpenOMEtiff;
A = double(series1);
Amean = mean(A,3);
for i = 1:size(A,3)
%     A(:,:,i) = (A(:,:,i) - region.image)./region.image;
    A(:,:,i) = (A(:,:,i) - Amean)./Amean;
end

myOpen;
fnm = [pathname filename];
fnm2=[fnm(1:end-4) '_backgroundSubtract' '.tif'];


for fr = 1:size(series1,3);
I = A(:,:,fr);
    %fr=26;
% 	img1 = A(:,:,fr);
% 	I = img1;
		%for i = [60]
            i = 60;
%             h=figure;
%             subplot(4,2,1)
%             imshow(I,[]); title(['fr ' num2str(fr)])
			background = imopen(I,strel('disk',i));
% 			subplot(4,2,2)
% 			imshow(background,[]); title(['background, disk ' num2str(i)])
			% figure, surf(double(background(1:8:end,1:8:end))),zlim([0 255]);  %view backgour image
			% set(gca,'ydir','reverse');
			I2 = I - background;  %subtract background
% 			subplot(4,2,3); imshow(I2,[]); title('background subtract')

            minValue = abs(min(I2(:)));
            I2 = (I2 + minValue).*2^16;  %scale data to fit within uint16 range [0,2^16), because df/F gives negative values   %commented out, keep double for mat2gray
            I3 = uint16(I2);
            %Write to multipage TIFF
            imwrite(I3, fnm2,'tif', 'Compression', 'none', 'WriteMode', 'append');
% end 
disp('.')
end




% %Write to multipage TIFF
% fnm2=[pathname 'TSeries_038_multipage.tif'];
% fnm2=['TSeries_038_multipage.tif'];
% fnm2=['TSeries_040_multipage.tif'];
% for i = 1:size(A,3)
% imwrite(A(:,:,i), fnm2,'tif', 'Compression', 'none', 'WriteMode', 'append');
% end