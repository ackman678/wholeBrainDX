function varargout = domainTaggingGui(varargin)
% DOMAINTAGGINGGUI MATLAB code for domainTaggingGui.fig
%      DOMAINTAGGINGGUI, by itself, creates a new DOMAINTAGGINGGUI or raises the existing
%      singleton*.
% This is a wrapper gui function for domainPatchesPlot. 
%
%EXAMPLE:  domainTaggingGui(region)
%INPUTS: region data structure
%
%      H = DOMAINTAGGINGGUI returns the handle to a new DOMAINTAGGINGGUI or the handle to
%      the existing singleton*.
%
%      DOMAINTAGGINGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DOMAINTAGGINGGUI.M with the given input arguments.
%
%      DOMAINTAGGINGGUI('Property','Value',...) creates a new DOMAINTAGGINGGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before domainTaggingGui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to domainTaggingGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: plotWholeBrainDomainsTraces, GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help domainTaggingGui

% Last Modified by GUIDE v2.5 15-May-2013 16:12:42

%Author: %James B. Ackman (c) 5/8/2013 

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @domainTaggingGui_OpeningFcn, ...
                   'gui_OutputFcn',  @domainTaggingGui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before domainTaggingGui is made visible.
function domainTaggingGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to domainTaggingGui (see VARARGIN)

handles.region = varargin{1};
setupCurrentPlot(handles)

% Choose default command line output for domainTaggingGui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes domainTaggingGui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


function setupCurrentPlot(handles)
DomainPatchesPlot(handles.region.domainData.domains, handles.region.domainData.CC, handles.region.domainData.STATS, 1, handles.axes1)

% --- Outputs from this function are returned to the command line.
function varargout = domainTaggingGui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
helpdlg({'1. Use cursors to draw outlines that will select domain centroids for tagging as artifacts', '2. Export updated "region" data to workspace'},'Cursor based domain selection')


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%Initial info

handles = addBorder(handles);
guidata(hObject, handles);
%determineRegions(handles)
% HippoDetermineRegions


function handles = addBorder(handles)
handles.bord = [];
handles.bhand = [];

stl = 1;
c = 1;
x = [];
y = [];
isb = 0;
[szM,szN] = size(handles.region.image);
hold on

while stl
    [x(c) y(c) butt] = ginput(1);
    x(c) = round(x(c));
    y(c) = round(y(c));
    
	if x(c) < 1
		x(c) = 1;
	elseif x(c) > szN
		x(c) = szN;
	end
	if y(c) < 1
		y(c) = 1;
	elseif y(c) > szM
		y(c) = szM;
	end
    
    if butt > 1
        if c == 1
            isb = 1;
        else
            stl = 0;
        end
        if isb == 1
            [mn i] = min([x(c) szN-x(c)+1 y(c) szM-y(c)+1]);
            switch i
                case 1
                    x(c) = 1;
                case 2
                    x(c) = szN;
                case 3
                    y(c) = 1;
                case 4
                    y(c) = szM;
            end
        end
    end
    if c == 1
        h = plot(x,y,'bo');    %TODO: Fix the drawing, make temporary
    end
    if c == 2
        delete(h);
        h = plot(x,y,':+b');  %TODO: Fix the drawing, make temporary
    end
    if c > 2
        set(h,'xdata',x,'ydata',y);
    end
    c = c+1;
end
if isb == 0
    x = [x x(1)];
    y = [y y(1)];
    set(h,'xdata',x,'ydata',y);
end


handles.bord{length(handles.bord)+1} = [];
handles.bord{end} = [get(h,'xdata')' get(h,'ydata')'];
handles.bhand(end+1) = h;
handles = markArtifacts(handles);
% hTmp = findobj(h.axes1,'Type','patch')
delete(h);

function handles = markArtifacts(handles)
%Locate domain centroids and patch object centroids marked as artifacts

sz = handles.region.domainData.CC.ImageSize;
x = handles.bord{1}(:,1);  %use the data returned from giinput
y = handles.bord{1}(:,2);  %use the data returned from giinput
mask = poly2mask(x,y,sz(1),sz(2));

hTmp = findobj(handles.axes1,'Type','patch');   %optional for blanking patch objects
patchCentrInd = zeros(1,length(hTmp));
for i = 1:length(hTmp)
    cx = get(hTmp(i),'xdata');
    cy = get(hTmp(i),'ydata');
     centr = round(centroid([cy cx]));
     centrInd = sub2ind([sz(1) sz(2)],centr(1),centr(2));
     patchCentrInd(i) = centrInd; 
end

if ~isfield(handles.region.domainData.STATS, 'descriptor')
    for i = 1:length(handles.region.domainData.STATS)
        handles.region.domainData.STATS(i).descriptor = '';
    end
end

nDomains = length(handles.region.domainData.domains);
% nDomains = 20; %TESTING
% 	myColors = jet(nDomains);
% 	figure; imshow(mask)
% 	hold on
for i = 1:nDomains
    %i = 1;
    centr = handles.region.domainData.STATS(i).Centroid;
    centr = round([centr(1) centr(2)]);
    if mask(centr(2),centr(1))
        handles.region.domainData.STATS(i).descriptor = 'artifact';
        for j = find(mask(patchCentrInd));
            set(hTmp(j),'EdgeColor','none', 'FaceColor','none');   %optional for blanking patch objects. Doesn't work, patch objects not drawn in order.
        end
        %disp('artifact!')
    end
% 		plot(centr(1), centr(2), 'o', 'Color', myColors(i,:,:))
end


function centr = centroid(coords)
%centroid = centroid(coords)
%   calculates the center of mass of a polygon
%   with given coordinates

if prod(size(coords))==0
   cx = NaN;
   cy = NaN;
else
   m = [coords; coords(1,:)];
   x = m(:,1);
   y = m(:,2);
   
   a = (sum(x(1:end-1).*y(2:end)) - sum(x(2:end).*y(1:end-1)))/2;
   cx = sum((x(1:end-1)+x(2:end)).*(x(1:end-1).*y(2:end)-x(2:end).*y(1:end-1)))/(6*a);
   cy = sum((y(1:end-1)+y(2:end)).*(x(1:end-1).*y(2:end)-x(2:end).*y(1:end-1)))/(6*a);
end

centr = [cx cy];


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
%Export data 'handles.region' to workspace
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
assignin('base', 'region', handles.region)
