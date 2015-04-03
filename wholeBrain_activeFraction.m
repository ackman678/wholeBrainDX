function data = wholeBrain_activeFraction(A3,region,locationMarkers,stimDesc)
%PURPOSE -- get fraction of active functional domains in wholeBrain calcium imaging movies
%USAGE -- data = wholeBrain_activeFraction(A3,region);
%James B. Ackman
%2013-04-04 09:46:23

if nargin < 2 || isempty(region), region = myOpen; end  %to load the hemisphere region outlines from 'region' calciumdx struct
if nargin < 3 || isempty(locationMarkers), locationMarkers = find(~strcmp(region.name,'field') & ~strcmp(region.name,'craniotomy'));  end  %index location of the hemisphere region outlines or local areal outlines in the 'region' data structure you want to analyse
if nargin < 4 || isempty(stimDesc), stimDesc = ''; end  %plot stimulus periods on active fraction plot below, e.g. stimDesc='drug.state.isoflurane';

stimuli=region.stimuli;
sz = size(A3);
maxProj = max(A3,[],3);   %makes a maximum projection image (all active pixels for whole brain)

%--------Fetch the data-----------------------------------
for locationIndex = 1:length(locationMarkers)   %Can limit this to just hemisphere outlines using locationMarkers = [2 3] if you have the hemisphere coords drawn at region.coords{2} and region.coords{3}
	data(locationIndex).binaryMask = poly2mask(region.coords{locationMarkers(locationIndex)}(:,1),region.coords{locationMarkers(locationIndex)}(:,2),sz(1),sz(2));
	%figure; imshow(data(locationIndex).binaryMask);
	data(locationIndex).nPixels = numel(find(data(locationIndex).binaryMask));   %get the total number of pixels within the binary mask
	data(locationIndex).name = region.name{locationMarkers(locationIndex)};  %name of the location
	data(locationIndex).nPixelsByFrame = zeros(1,sz(3));   %set up empty vector for getting the number of active pixels by frame 
	data(locationIndex).activeFractionByFrame = zeros(1,sz(3));  %set up empty vector for getting the active fraction by frame
	data(locationIndex).nPixelsActive = numel(find(maxProj&data(locationIndex).binaryMask));   %get the total number of active pixels for movie
	data(locationIndex).activeFraction = data(locationIndex).nPixelsActive / data(locationIndex).nPixels;  %get the total active fraction for movie
	data(locationIndex).meanActivePixelLocaRowInd = zeros(1,sz(3));
	data(locationIndex).meanActivePixelLocaColInd = zeros(1,sz(3));
	data(locationIndex).meanActivePixelLocaNormML = zeros(1,sz(3));
	data(locationIndex).meanActivePixelLocaNormAP = zeros(1,sz(3));
end

A3 = reshape(A3,prod(sz(1:2)),sz(3)); %space x time matrix
for locationIndex = 1:length(locationMarkers); %option:parfor
	ROImask = repmat(data(locationIndex).binaryMask,1,1,sz(3));
	ROImask = reshape(ROImask,prod(sz(1:2)),sz(3)); %space x time matrix
	I = A3 & ROImask;
	data(locationIndex).nPixelsByFrame = sum(I,1);  %get the number of active pixels by frame
	data(locationIndex).activeFractionByFrame = data(locationIndex).nPixelsByFrame ./ data(locationIndex).nPixels; %get the active fraction by frame

	[row,col,k]=ind2sub(sz,find(I));

	%A = accumarray(subs,val,sz,fun,fillval)
	rowAgg = accumarray(k,row,[sz(3) 1],@mean,NaN);
	colAgg = accumarray(k,col,[sz(3) 1],@mean,NaN);

	data(locationIndex).meanActivePixelLocaRowInd = rowAgg';
	data(locationIndex).meanActivePixelLocaColInd = colAgg';

	%Calculate normalized medial-lateral and anterior-posterior distances
	mx = max(region.coords{locationMarkers(locationIndex)});  %normally (X, Y) = (cols, rows)
	mn = min(region.coords{locationMarkers(locationIndex)});  %normally (X, Y) = (cols, rows)
	
	%region.orientation.value (Y, X) = (row, cols)
	%mx and mn give from region.coords will normally be: (X, Y) = (cols, rows)
%			if region.orientation.value(1) < mn(2)
	if mn(1) < region.orientation.value(2)   %switched for whole brain movies with anterior-medial point being up
		xlocanorm = (colAgg' - mn(1))/(mx(1) - mn(1));
		ylocanorm = (rowAgg' - mn(2))/(mx(2) - mn(2));
		xlocanorm = abs(1-xlocanorm);  %switched for whole brain movies with anterior-medial point being up
	else
		xlocanorm = (colAgg' - mn(1))/(mx(1) - mn(1));
		ylocanorm = (rowAgg' - mn(2))/(mx(2) - mn(2));    
	end
	
	data(locationIndex).meanActivePixelLocaNormML = xlocanorm;
	data(locationIndex).meanActivePixelLocaNormAP = ylocanorm;
end


%
%figure;
%legendText = {};
%hold all
%for locationIndex = 1:length(locationMarkers)
%	plot(1:sz(3),data(locationIndex).activeFractionByFrame)
%	legendText{locationIndex} = data(locationIndex).name;
%end
%title('Active Fraction by Frame')
%xlabel('frame no.'); ylabel('Fraction of pixels active'); legend(legendText);


%--------Plot the active fraction by frame for each location----------------------------
figure;
myColors = lines(length(locationMarkers));
%myColors = [0 0.5 1; 0 0.5 0;]
set(gcf,'DefaultAxesColorOrder',myColors)
lineSize = 1;
legendText = {};
clear ax
ymax = [];
nPlots = length(locationMarkers) + 1;
for locationIndex = 1:length(locationMarkers)
	ax(locationIndex) = subplot(nPlots,1,locationIndex);
	plot(1:sz(3),data(locationIndex).activeFractionByFrame,'Color',myColors(locationIndex,:),'LineWidth',lineSize);
	legendText{locationIndex} = data(locationIndex).name;
	mx = max(data(locationIndex).activeFractionByFrame);
	ymax = max([ymax mx]);
	ylabel('Fraction of pixels active'); legend(legendText{locationIndex});
end	

ax(nPlots) = subplot(nPlots,1,nPlots);
hold all
for locationIndex = 1:length(locationMarkers)
	minY = min(data(locationIndex).activeFractionByFrame); maxY = max(data(locationIndex).activeFractionByFrame);
	if maxY == 0 | isnan(maxY); minY=0; maxY=1; end
	plotStimuli(region,stimuli,minY,maxY,[0.8 0.8 0.8; 0.8 0.8 0.8; 0.8 0.8 0.8; 0.8 0.8 0.8; 0.8 0.8 0.8],stimDesc);
	plot(1:sz(3),data(locationIndex).activeFractionByFrame,'LineWidth',lineSize)
	%legendText{locationIndex} = data(locationIndex).name;
end
%title('Active Fraction by Frame')
if ymax == 0 | isnan(ymax); ymax=1; end
set(ax,'ylim', [0 ymax]);
xlabel('frame no.'); ylabel('Fraction of pixels active'); legend(legendText);
linkaxes(ax,'x');
pan xon
zoom xon


%--------Display some results to command line--------------------------
%disp(['name' ' ' 'active.fraction'])
%for locationIndex = 1:length(locationMarkers)
%	disp([data(locationIndex).name ' ' num2str(data(locationIndex).activeFraction)]) 
%end

disp(['name ' 'actvFraction ' 'maxFraction ' 'minFraction ' 'meanFraction ' 'sdFraction ' 'meanActvFraction ' 'sdActvFraction ' 'actvFrames ' 'actvTimeFraction ' 'nonActvFrames ' 'nonActvTimeFraction'])

for locationIndex = 1:length(locationMarkers)
	actvFraction = data(locationIndex).activeFraction;
	maxFraction = max(data(locationIndex).activeFractionByFrame);
	minFraction = min(data(locationIndex).activeFractionByFrame);
	meanFraction = mean(data(locationIndex).activeFractionByFrame);
	sdFraction = std(data(locationIndex).activeFractionByFrame);
	
	actvFramesIdx = find(data(locationIndex).activeFractionByFrame);
	meanActvFraction = mean(data(locationIndex).activeFractionByFrame(actvFramesIdx));
	sdActvFraction = std(data(locationIndex).activeFractionByFrame(actvFramesIdx));
	
	actvFrames = numel(find(data(locationIndex).activeFractionByFrame));
	actvTimeFraction = actvFrames/length(data(locationIndex).activeFractionByFrame);
	
	nonActvFrames = length(data(locationIndex).activeFractionByFrame) - actvFrames;
	nonActvTimeFraction = nonActvFrames/length(data(locationIndex).activeFractionByFrame);
	
	disp([data(locationIndex).name ' ' num2str(actvFraction) ' ' num2str(maxFraction) ' ' num2str(minFraction) ' ' num2str(meanFraction) ' ' num2str(sdFraction) ' ' num2str(meanActvFraction) ' ' num2str(sdActvFraction) ' ' num2str(actvFrames) ' ' num2str(actvTimeFraction) ' ' num2str(nonActvFrames) ' ' num2str(nonActvTimeFraction)]) 
end


