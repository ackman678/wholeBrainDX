function DomainPatchesPlot(domains, CC, STATS, ColorByTime, axesHandle, removArtifacts)
%DomainPatchesPlot(domains, CC, STATS)
% James B. Ackman 2013-01-04 22:39:02

%hbar = waitbar(0,'Please wait...');   %Drawing the waitbar can quadruple drawing time by forcing patch to drawnow. Not sure of a current workaround

disp('Please be patient. This may take several seconds to plot...')
if nargin < 6 || isempty(removArtifacts), removArtifacts = 1; end

if nargin < 5 || isempty(axesHandle)
	figure;
	axesHandle = gca;
end

if nargin < 4 || isempty(ColorByTime), ColorByTime = 1; end
%Configure following option depending on whether you want to colorize plot based on time or on domain no.  

if ColorByTime > 0
	%myColors = lines(CC.ImageSize(3));  %RGB color array
	%myColors = jet(CC.ImageSize(3));  %RGB color array
	myColors = hsv(CC.ImageSize(3));  %RGB color array
else
	%myColors = lines(length(domains));  %RGB color array
	myColors = hsv(length(domains));  %RGB color array
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

% num=1;  %placeholder from HippoCalciumDextran gui code  
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

	for j = 1:nDomains
		if ~strcmp(STATS(j).descriptor, 'artifact')
			%disp(j) %TESTING
			BW = zeros(CC.ImageSize(1:2));
			BW(domains(j).PixelInd) = 1;
			[BP2,L] = bwboundaries(BW,'noholes');
			boundary = BP2{1};
			locatmp = [boundary(:,2) boundary(:,1)];

			if ColorByTime > 0
				onset = ceil(STATS(unique(domains(j).OrigDomainIndex)).BoundingBox(3));
				h(j) = patch(locatmp(:,1),locatmp(:,2),myColors(onset,:));
%				set(h(j),'EdgeColor',[0 0 0], 'FaceAlpha',0.1, 'LineWidth',0.5);  %alpha looks great but matlab does not export transparency well except for .pngs
				set(h(j),'EdgeColor',[1 1 1], 'FaceAlpha',0.1, 'LineWidth',0.5);  %alpha looks great but matlab does not export transparency well except for .pngs
			else
				h(j) = patch(locatmp(:,1),locatmp(:,2),myColors(j,:));
				set(h(j),'EdgeColor',[0 0 0], 'FaceAlpha',0.5, 'LineWidth',0.5);  %alpha looks great but matlab does not export transparency well except for .pngs
			end

		%    if rem(j,10) == 0
		%        waitbar(j/nDomains,hbar); 
		%    end 
			%drawnow  %**greatly** increases plotting time.
		end
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
yticklabs2 = num2str(str2num(yticklabs) .* CC.ImageSize(3));
set(cbar_handle,'YTickLabel',yticklabs2);

%colormap(lines); colorbar
%axis equal