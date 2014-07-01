function wholeBrainActivityMapPlot(img, maxSig, handles, contourLevels)
%wholeBrainActivityMapPlot(img, handles)
% Examples
%	wholeBrainActivityMapPlot(img);
%	wholeBrainActivityMapPlot(img, handles);
% INPUTS
% img -- 
% normValue --
% handles -- handles for figure
% James B. Ackman 2013-10-14 10:19:38

if nargin < 3 || isempty(handles),
	handles.figHandle = figure;
	handles.axesHandle = gca;
	handles.axesTitle = 'Signal px count norm to max sig count. MaxSig=';
	handles.frames =  [];
	handles.clims = [0 max(img(:))];
end

if nargin < 2 || isempty(maxSig), maxSig = handles.clims(2); end;


if nargin < 4 || isempty(contourLevels),
	makeSubplot(img, maxSig, handles);
else
	makeSubplotContour(img, maxSig, handles, contourLevels);
end

function makeSubplot(img, maxSig, handles) 
set(handles.figHandle,'CurrentAxes',handles.axesHandle)
if isempty(handles.frames)
	frTxt = 'fr:all';
else
	frTxt = ['fr' num2str(handles.frames(1)) ':' num2str(handles.frames(2))];
end

imagesc(img,handles.clims);
title([handles.axesTitle [num2str(maxSig) ', ' frTxt]], 'Interpreter','none'); 
myColors = jet(256);
myColors(1,:) = [0 0 0];
colormap(myColors);
colorbar('location','eastoutside'); 
axis image
axis tight
axis off


function makeSubplotContour(img, maxSig, handles, contourLevels)
if nargin < 4 || isempty(contourLevels), contourLevels = 20; end
set(handles.figHandle,'CurrentAxes',handles.axesHandle)
%set(handles.axesHandle,'Color',[0 0 0])

if isempty(handles.frames)
	frTxt = 'fr:all';
else
	frTxt = ['fr' num2str(handles.frames(1)) ':' num2str(handles.frames(2))];
end

ylimits = [1 size(img,1)];  
xlimits = [1 size(img,2)];

%***contour plot***    
contour(flipud(img),contourLevels); caxis(handles.clims) 
myColors = jet(256);
myColors(1,:) = [0 0 0];
colormap(myColors);
myColors = jet(contourLevels);
colormap(myColors);


title([handles.axesTitle num2str(maxSig) ',' frTxt ',' num2str(contourLevels) 'levels']); 
colorbar('location','eastoutside'); 
axis equal; xlim(xlimits); ylim(ylimits);
set(handles.axesHandle,'Color',[0 0 0],'XTick',[],'YTick',[])

