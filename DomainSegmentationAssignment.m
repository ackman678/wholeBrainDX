function domains = DomainSegmentationAssignment(CC,STATS,assign)
%overlay domains for plot and for domain assignment from a 3D connected components array
% need CC, connected components and STATS, the structure returned by region.props after running wholeBrain_segmentation.m and then wholeBrain_kmeans.m
% James B. Ackman 2013-01-04 22:39:41

if nargin < 3 || isempty('assign'), assign = 'true'; end;

clear domains
domains(1).PixelInd = [];   %'new' domain based dataset. Indices from max image (find(mx))
domains(1).OrigDomainIndex = [];  %use this for assignments for new spike array and for colorizing plot. Ordered by time.
domains(1).NewDomainIndex = [];  %New domain assignment index to aggregate domains. Not ordered by time.
domains(1).CentroidIndex = [];  %2D (x,y) centroid index
count = 0;

%domainLocations = zeros(1,length(STATS));   

for i = 1:length(STATS);
% for	i = 1:30; %testing
%     disp(num2str(i))
%	tmpArr = zeros([CC.ImageSize(1:2) STATS(i).BoundingBox(6)]);
%	tmpArr(STATS(i).PixelIdxList) = 1;
%	mx = max(tmpArr,[],3);
%	
	mx = zeros(CC.ImageSize(1:2));
	mx(sub2ind(CC.ImageSize(1:2),STATS(i).PixelList(:,2), STATS(i).PixelList(:,1))) = 1;	
%	imagesc(mat2gray(mx));  %testing
	indNew = find(mx);
	centrInd = sub2ind(CC.ImageSize(1:2),round(STATS(i).Centroid(2)),round(STATS(i).Centroid(1)));  %2D centroid index
	%mx2 = mx;
	%mx2(centrInd) = 0;
	%figure; imagesc(mx); title('mx')
	%figure; imagesc(mx2); title('mx2')
	
    
    if strcmp(assign,'true')
        
        fINDEX = find(vertcat(domains.PixelInd) == centrInd);   %finds out whether the domain centroid is already contained within pixels in the indArray
        [~,ia,~] = intersect(vertcat(domains.CentroidIndex),indNew);
        if ~isempty(fINDEX) || ~isempty(ia)
            %         disp(['fIND = ' num2str(fINDEX(1))])
            NewDomainIndexList = vertcat(domains.NewDomainIndex);
%            disp(num2str(fINDEX))
%            disp(num2str(ia))
            fINDtemp = [fINDEX; ia];
            fIND = NewDomainIndexList(fINDtemp(1));
			%disp(['fIND = ' num2str(unique(NewDomainIndexList(fINDtemp))')])
			
			
%			end
            domains(fIND(1)).PixelInd = [domains(fIND(1)).PixelInd; indNew];
            domains(fIND(1)).OrigDomainIndex = [domains(fIND(1)).OrigDomainIndex; repmat(i,numel(indNew),1)];
            domains(fIND(1)).NewDomainIndex = [domains(fIND(1)).NewDomainIndex; repmat(fIND(1),numel(indNew),1)];
            domains(fIND(1)).CentroidIndex = [domains(fIND(1)).CentroidIndex; repmat(centrInd,numel(indNew),1)];
            
        else
            count = count + 1;
            %         disp(['count = ' num2str(count)])
            domains(count).PixelInd = [indNew];
            domains(count).OrigDomainIndex = [repmat(i,numel(indNew),1)];
            domains(count).NewDomainIndex = [repmat(count,numel(indNew),1)];
            domains(count).CentroidIndex = [repmat(centrInd,numel(indNew),1)];
        end
        
    else
        count = count + 1;
        %         disp(['count = ' num2str(count)])
        domains(count).PixelInd = [indNew];
        domains(count).OrigDomainIndex = [repmat(i,numel(indNew),1)];
        domains(count).NewDomainIndex = [repmat(count,numel(indNew),1)];
        domains(count).CentroidIndex = [repmat(centrInd,numel(indNew),1)];
    end
    
end


%{
figure;
xlim([0 CC.ImageSize(2)])
ylim([0 CC.ImageSize(1)])
% axis equal
% axis tight
% set(gca,'ydir','reverse','ytick',[],'xtick',[])
set(gca,'ydir','reverse','ytick',[],'xtick',[])

% num=1;  %placeholder from CalciumDX gui code  
% handlCoord{num} = [];  
% hold on
% for numcoords = 1:length(region.coords)
%     if prod(max(region.coords{numcoords})) ~= prod(size(region.image))
%         hCoord = plot([region.coords{numcoords}(:,1); region.coords{numcoords}(1,1)], [region.coords{numcoords}(:,2); region.coords{numcoords}(1,2)],'--','color',[0.5 0.5 0.5]);
%         handlCoord{num} = [handlCoord{num} hCoord];
%     end
% end

% myColors = jet(length(domains));  %RGB color array
myColors = lines(length(domains));  %RGB color array

% figure;
BW = zeros(CC.ImageSize(1:2));
BW(domains(1).PixelInd) = 1;
% imagesc(BW);  %testing
     
[BP2,L] = bwboundaries(BW,'noholes');
boundary = BP2{1};
locatmp = [boundary(:,2) boundary(:,1)];

cnt1 = patch(locatmp(:,1),locatmp(:,2),myColors(1,:));
set(cnt1,'EdgeColor',[0 0 0]);
set(cnt1,'FaceAlpha',0.5)  %looks great but matlab does not export transparency well
set(cnt1,'LineWidth',0.5)
drawnow




%-------------------
figure; 
BW = zeros(CC.ImageSize(1:2));
BW(vertcat(domains.PixelInd)) = 1;
imagesc(BW);  %testing





%-------------------
figure;
xlim([0 CC.ImageSize(2)])
ylim([0 CC.ImageSize(1)])
% axis equal
% axis tight
% set(gca,'ydir','reverse','ytick',[],'xtick',[])
set(gca,'ydir','reverse','ytick',[],'xtick',[])

% num=1;  %placeholder from CalciumDX gui code  
% handlCoord{num} = [];  
% hold on
% for numcoords = 1:length(region.coords)
%     if prod(max(region.coords{numcoords})) ~= prod(size(region.image))
%         hCoord = plot([region.coords{numcoords}(:,1); region.coords{numcoords}(1,1)], [region.coords{numcoords}(:,2); region.coords{numcoords}(1,2)],'--','color',[0.5 0.5 0.5]);
%         handlCoord{num} = [handlCoord{num} hCoord];
%     end
% end

myColors = lines(length(domains));  %RGB color array

for j = 1:length(domains)
BW = zeros(CC.ImageSize(1:2));
BW(domains(j).PixelInd) = 1;
     
[BP2,L] = bwboundaries(BW,'noholes');
boundary = BP2{1};
locatmp = [boundary(:,2) boundary(:,1)];

cnt1 = patch(locatmp(:,1),locatmp(:,2),myColors(j,:));
set(cnt1,'EdgeColor',[0 0 0]);
set(cnt1,'FaceAlpha',0.5)  %looks great but matlab does not export transparency well
set(cnt1,'LineWidth',0.5)
drawnow
end
%}