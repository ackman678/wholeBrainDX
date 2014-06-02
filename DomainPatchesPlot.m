function DomainPatchesPlot(domains, CC, STATS, plotType, axesHandle, removArtifacts, region)
%DomainPatchesPlot(domains, CC, STATS)
%Examples:
% >>DomainPatchesPlot(region.domainData.domains, region.domainData.CC, region.domainData.STATS,1,[],1) 
%USE:
% 	domains --  domains data returned from DomainSegmentationAssignment.m. Usually stored at region.domainData.domains
% 	CC --  CC data structure returned from wholeBrain_detect.m. Usually stored at region.domainData.CC
% 	STATS --  STATS data structure returned from wholeBrain_detect.m. Usually stored at region.domainData.STATS
%Options:
%plotType--
%'1' = plot domains colored by time of onset activation
%'2' = plot domains colored uniquely by domain index
%'3' = plot domains colored by duration into 3 bins
%'4' = plot domains colored by duration
%'5' = plot domains colored by diameter
%axesHandle-- if you have wrapper code and want this plotting function to draw in existing axes
%removArtifacts -- numeric 0 | 1 for T/F. For if you have list of artifact domains tags at region.domainData.STATS.descriptor
%region -- pass along the region data structure so you have access to region.timeres for proper conversion of plot scales
%
% James B. Ackman 2013-01-04 22:39:02

%hbar = waitbar(0,'Please wait...');   %Drawing the waitbar can quadruple drawing time by forcing patch to drawnow. Not sure of a current workaround

disp('Please be patient. This may take several seconds to plot...')
if nargin < 7 || isempty(region), region.timeres = 0.2; end

if nargin < 6 || isempty(removArtifacts), removArtifacts = 1; end

if nargin < 5 || isempty(axesHandle)
	figure;
	axesHandle = gca;
end

if nargin < 4 || isempty(plotType), plotType = 1; end
%Configure following option depending on whether you want to colorize plot based on time or on domain no.  

switch plotType
case 1
	%myColors = lines(CC.ImageSize(3));  %RGB color array
	myColors = jet(CC.ImageSize(3));  %RGB color array
	%myColors = hsv(CC.ImageSize(3));  %RGB color array
case 2
	%myColors = lines(length(domains));  %RGB color array
	myColors = hsv(length(domains));  %RGB color array
case 3
	ncolors = 4;
	myColors = jet(ncolors);
	marker(1) = 3; %less than 600msec for 5fr/sec imaging    
	marker(2) = 10; %less than 2sec for 5fr/sec imaging    
	marker(3) = 25; %less than 5sec for 5fr/sec imaging  
case 4
	ncolors = 8;
	myColors = jet(ncolors);
case 5
	ncolors = 8;
	myColors = jet(ncolors);	
	
end

if isfield(STATS, 'descriptor');
	removArtifacts = 1;
else
	removArtifacts = 0;
end

%-------------------
%figure; 
%BW = zeros(CC.ImageSize(1:2));
%BW(vertcat(domains.PixelInd)) = 1;
%imagesc(BW); title('max proj of all active pixels')  %testing


       

%-------------------
%setting alpha transparency can give segmentation errors/faults crashing matlab on certain systems. Like linux. Set default renderer to 'zbuffer'
%set(0, 'DefaultFigureRenderer', 'zbuffer');

set(axesHandle,'ydir','reverse','ytick',[],'xtick',[])
xlim([0 CC.ImageSize(2)])
ylim([0 CC.ImageSize(1)])
% axis equal
% axis tight
% set(gca,'ydir','reverse','ytick',[],'xtick',[])

% num=1;  %placeholder from CalciumDX gui code  
% handlCoord{num} = [];  
% hold on
% for numcoords = 1:length(region.coords)
%     if prod(max(region.coords{numcoords})) ~= prod(size(region.image))
%         hCoord = plot([region.coords{numcoords}(:,1); region.coords{numcoords}(1,1)], [region.coords{numcoords}(:,2); region.coords{numcoords}(1,2)],'--','color',[0.5 0.5 0.5]);
%         handlCoord{num} = [handlCoord{num} hCoord];
%     end
% end
tic;
clear h
nDomains = length(domains);
%nDomains = 20; %TESTING

switch removArtifacts

case 1

	roiBoundingBox = [];
	ObjectIndices = [];
	j = 0;
	for i = 1:CC.NumObjects  
	   if ~strcmp(STATS(i).descriptor, 'artifact')  
		   j = j + 1;
		   roiBoundingBox(j,:) = STATS(i).BoundingBox;
		   ObjectIndices = [ObjectIndices i];        
	   end      
	end  

	switch plotType
		case 4
			durations = roiBoundingBox(:,6); 
			x = durations;
	%		cx = log(x);  %optional
%			if min(cx) < 0, 
%			cx = cx + floor(min(cx));
%			elseif min(cx) == 0
%			cx = cx + 1;
%			else
%			end
	cx = x;
			cx = cx/max(cx);
			cind = ceil(cx .* ncolors);

		case 5
			diameters = mean([roiBoundingBox(:,4) roiBoundingBox(:,5)], 2);
			x = diameters;
			cx = x;
			cx = cx/max(cx);
			cind = ceil(cx .* ncolors);
	end



	for i = 1:length(ObjectIndices)
		j = ObjectIndices(i);
		%disp(j) %TESTING
		BW = zeros(CC.ImageSize(1:2));
		BW(domains(j).PixelInd) = 1;
		[BP2,L] = bwboundaries(BW,'noholes');
		boundary = BP2{1};
		locatmp = [boundary(:,2) boundary(:,1)];

		switch plotType
		case 1
			onset = ceil(STATS(unique(domains(j).OrigDomainIndex)).BoundingBox(3));
			h(i) = patch(locatmp(:,1),locatmp(:,2),myColors(onset,:));
	%				set(h(j),'EdgeColor',[0 0 0], 'FaceAlpha',0.1, 'LineWidth',0.5);  %alpha looks great but matlab does not export transparency well except for .pngs
			set(h(i),'EdgeColor',[1 1 1], 'FaceAlpha',0.1, 'LineWidth',0.5);  %alpha looks great but matlab does not export transparency well except for .pngs
		case 2
			h(i) = patch(locatmp(:,1),locatmp(:,2),myColors(j,:));
			set(h(i),'EdgeColor',[0 0 0], 'FaceAlpha',0.5, 'LineWidth',0.5);  %alpha looks great but matlab does not export transparency well except for .pngs
		case 3
			if x(i,1) <= marker(1)  
				h(i) = patch(locatmp(:,1),locatmp(:,2),myColors(1,:));
				set(h(i),'EdgeColor',[0 0 0], 'FaceAlpha',0.5, 'LineWidth',0.5);
			elseif x(i,1) < marker(2)  
				h(i) = patch(locatmp(:,1),locatmp(:,2),myColors(2,:));
				set(h(i),'EdgeColor',[0 0 0], 'FaceAlpha',0.5, 'LineWidth',0.5);
		%    elseif x(i,1) <= marker(3)  
		%       plot(centr(1),centr(2),'o','Color',mycolors(3,:),'MarkerSize',myMarkerSize(3))    
			else  %everything greater than marker(2)
				h(i) = patch(locatmp(:,1),locatmp(:,2),myColors(4,:));
				set(h(i),'EdgeColor',[0 0 0], 'FaceAlpha',0.5, 'LineWidth',0.5);
			end
		case 4 
			h(i) = patch(locatmp(:,1),locatmp(:,2),myColors(cind(i),:));
			set(h(i),'EdgeColor','none', 'FaceAlpha',0.5, 'LineWidth',0.5);
%			set(h(i),'EdgeColor','none');
		case 5 
			h(i) = patch(locatmp(:,1),locatmp(:,2),myColors(cind(i),:));
			set(h(i),'EdgeColor','none', 'FaceAlpha',0.5);
		end

	%    if rem(j,10) == 0
	%        waitbar(j/nDomains,hbar); 
	%    end 
		%drawnow  %**greatly** increases plotting time.
	end

case 0

	for j = 1:nDomains
		%disp(j) %TESTING
		BW = zeros(CC.ImageSize(1:2));
		BW(domains(j).PixelInd) = 1;
		[BP2,L] = bwboundaries(BW,'noholes');
		boundary = BP2{1};
		locatmp = [boundary(:,2) boundary(:,1)];

		if ColorByTime > 0
			onset = ceil(STATS(unique(domains(j).OrigDomainIndex)).BoundingBox(3));
			h(j) = patch(locatmp(:,1),locatmp(:,2),myColors(onset,:));
			set(h(j),'EdgeColor',[0 0 0], 'FaceAlpha',0.1, 'LineWidth',0.5);  %alpha looks great but matlab does not export transparency well except for .pngs
		else
			h(j) = patch(locatmp(:,1),locatmp(:,2),myColors(j,:));
			set(h(j),'EdgeColor',[0 0 0], 'FaceAlpha',0.5, 'LineWidth',0.5);  %alpha looks great but matlab does not export transparency well except for .pngs
		end

	%    if rem(j,10) == 0
	%        waitbar(j/nDomains,hbar); 
	%    end 
		%drawnow  %**greatly** increases plotting time.
	end
	%close(hbar)

end

toc;
colormap(myColors); axis equal; colorbar
title('segmented domain assignments')

cbar_handle = findobj(gcf,'tag','Colorbar');
yticklabs = get(cbar_handle,'YTickLabel');

switch plotType
case 1
yticklabs2 = num2str(str2num(yticklabs) .* CC.ImageSize(3));
set(cbar_handle,'YTickLabel',yticklabs2);

case 4
%yticklabs2 = num2str(exp(str2num(yticklabs) .* max(log(x))) .* region.timeres);  % if x was log transformed
yticklabs2 = num2str(str2num(yticklabs) .* max(x) .* region.timeres);  % if normal scale was used
set(cbar_handle,'YTickLabel',yticklabs2); title('duration (s)')

case 5
%yticklabs2 = num2str(exp(str2num(yticklabs) .* max(log(x))) .* region.timeres);  % if x was log transformed
yticklabs2 = num2str(str2num(yticklabs) .* max(x) .* region.spaceres);  % if normal scale was used
set(cbar_handle,'YTickLabel',yticklabs2); title('diameter (um)')

end

%colormap(lines); colorbar
%axis equal