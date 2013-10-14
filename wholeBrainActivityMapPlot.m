function wholeBrainActivityMapPlot(A3proj, normValue, handles)
%wholeBrainActivityMapPlot(A3proj, normValue, handles)
% Examples
%	wholeBrainActivityMapPlot(A3proj);
%	wholeBrainActivityMapPlot(A3proj, normValue);
%	wholeBrainActivityMapPlot(A3proj,[], handles);
% INPUTS
% A3proj -- 
% normValue --
% handles -- handles for figure
% James B. Ackman 2013-10-14 10:19:38

if (nargin < 2 || isempty(normValue)), normValue = max(A3proj(:)); end %if no normValue was passed to wholeBrainActivityMapPlot
if nargin < 3 || isempty(handles),
	handles.figHandle = figure;
	handles.axesHandle = gca;
	handles.axesTitle = 'Signal px count norm to max sig count. MaxSig=';
end

img = A3proj./normValue;
mxNormSig=max(img);
makeSubplot(img, handles, mxNormSig);
disp(['mx normA3proj = ' num2str(mxNormSig)])

function makeSubplot(img, handles, maxSig) 
set(handles.figHandle,'CurrentAxes',handles.axesHandle)
imagesc(img);
title([handles.axesTitle num2str(maxSig)]); colorbar('location','eastoutside'); axis image
