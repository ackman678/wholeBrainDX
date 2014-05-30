function varargout = plotWholeBrainDomainsTraces(varargin)
% PLOTWHOLEBRAINDOMAINSTRACES MATLAB code for plotWholeBrainDomainsTraces.fig
% This function is utilized to visualize and compare multiple copies of the
% same movie and can interactively mark
% all real positive ROIs (calcium domains in this case) as well as
% true-positive detected vs false-positive detected domains. and can export
% the data to workspace for error rate detection statistics.
%
%EXAMPLE:  plotWholeBrainDomainsTraces(movie1,movie2,region,sigtoolFigHandle,sigtoolChannels,movieTitles,data,makeMovie)
%INPUTS: movie1, movie2 are MxNxP matlab arrays
% (uint8 or logical format is best) that get passed within varargin where
% movie1 is varargin{1}, etc.
% movieTitles is a 1xN cell array of strings, whose text describes each
% movie. 
% 
%
%      PLOTWHOLEBRAINDOMAINSTRACES, by itself, creates a new PLOTWHOLEBRAINDOMAINSTRACES or raises the existing
%      singleton*.
%
%      H = PLOTWHOLEBRAINDOMAINSTRACES returns the handle to a new PLOTWHOLEBRAINDOMAINSTRACES or the handle to
%      the existing singleton*.
%
%      PLOTWHOLEBRAINDOMAINSTRACES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOTWHOLEBRAINDOMAINSTRACES.M with the given input arguments.
%
%      PLOTWHOLEBRAINDOMAINSTRACES('Property','Value',...) creates a new PLOTWHOLEBRAINDOMAINSTRACES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plotWholeBrainDomainsTraces_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plotWholeBrainDomainsTraces_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help plotWholeBrainDomainsTraces

% Last Modified by GUIDE v2.5 14-Oct-2013 13:35:51

%Author: %James B. Ackman (c) 4/15/2013 

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plotWholeBrainDomainsTraces_OpeningFcn, ...
                   'gui_OutputFcn',  @plotWholeBrainDomainsTraces_OutputFcn, ...
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


% --- Executes just before plotWholeBrainDomainsTraces is made visible.
function plotWholeBrainDomainsTraces_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plotWholeBrainDomainsTraces (see VARARGIN)

% Create the data to plot.
% narginchk(1, 6)  %[minargs, maxargs]
lenVarargin = length(varargin);

if lenVarargin < 1 || isempty(varargin{1}), 
    error('must provide at least one movie input');
else
    handles.movie1 = varargin{1};
end

handles.movieLength = length(handles.movie1);

if lenVarargin < 2 || isempty(varargin{2}), 
    handles.movie2 = varargin{1};
else
    handles.movie2 = varargin{2};
end

if lenVarargin < 3 || isempty(varargin{3}),
    if exist('calciumdxprefs.mat','file') == 2
        load('calciumdxprefs')
    else
        pathname = pwd;
    end
    [filename, pathname] = uigetfile('*.mat','Select file to load or press cancel',pathname);
    if filename == 0
		matfile.region=[];
    else
		fname = fullfile(pathname,filename);
		matfile=load(fname);
		save('calciumdxprefs.mat', 'pathname','filename');
    end
    if isfield(matfile.region,'locationData')
%         handles.plot3.data=region.locationData.data;
        handles.plot3=setupActiveFractionHandles(region);
    else
        handles.plot3(1).data=[];
        handles.plot3(1).legendText = 'no data';
    end
else
    handles.plot3=setupActiveFractionHandles(varargin{3});   %provide 'region' containing 'locationData.data' as input to varargin{3}.
end


%Default for sigtoolChannel number--
if lenVarargin < 5 || isempty(varargin{5}), varargin{5} = 1; end

%Default for sigtoolFigureHandle. If absent make same as plot3--
if lenVarargin < 4 || isempty(varargin{4}),
    %load sigtoolHandle or make actvFraction temporarily;
    handles.plot4(1).data=handles.plot3(1).data;
    handles.plot4(1).legendText = handles.plot3(1).legendText;
    handles.plot4(1).Fs = 1; %sampling rate (Hz).  Used to convert data point indices to appropriate time units.  Leave at '1' for no conversion (like plotting the indices, 'frames')
	handles.plot4(1).unitConvFactor = 1;
elseif isnumeric(varargin{4})
    handles.plot4 = setupEphysData(varargin{4}, varargin{5}, handles);   %based on sigTOOL figure handle and channel handle inputs
elseif isstruct(varargin{4})
	handles.plot4 = varargin{4};
else
	error('wrong input to varargin{4}')	
end

%Defaults for axes titles--
if lenVarargin < 6 || isempty(varargin{6}),
    handles.axesTitles{1} = 'movie1'; handles.axesTitles{2} = 'movie2'; handles.axesTitles{3} = 'active fraction'; handles.axesTitles{4} = 'motor activity signal';
else
    handles.axesTitles = varargin{6};
end

%Defaults for existing or non-existing domain label markers--
if lenVarargin < 7 || isempty(varargin{7})  %check if previously saved data structure was passed to function
    for nMovies = 1:2
        for nFrames = 1:handles.movieLength
            handles.data(nMovies).frame(nFrames).allDomains.x = [];
            handles.data(nMovies).frame(nFrames).allDomains.y = [];
            handles.data(nMovies).frame(nFrames).goodDomains.x = [];
            handles.data(nMovies).frame(nFrames).goodDomains.y = [];
            handles.data(nMovies).frame(nFrames).badDomains.x = [];
            handles.data(nMovies).frame(nFrames).badDomains.y = [];
        end
    end
else
    data = varargin{7};
    for nMovies = 1:2
        for nFrames = 1:handles.movieLength
            handles.data(nMovies).frame(nFrames).allDomains.x = data(nMovies).frame(nFrames).allDomains.x;
            handles.data(nMovies).frame(nFrames).allDomains.y = data(nMovies).frame(nFrames).allDomains.y;
            handles.data(nMovies).frame(nFrames).goodDomains.x = data(nMovies).frame(nFrames).goodDomains.x;
            handles.data(nMovies).frame(nFrames).goodDomains.y = data(nMovies).frame(nFrames).goodDomains.y;
            handles.data(nMovies).frame(nFrames).badDomains.x = data(nMovies).frame(nFrames).badDomains.x;
            handles.data(nMovies).frame(nFrames).badDomains.y = data(nMovies).frame(nFrames).badDomains.y;
        end        
    end
end

if lenVarargin < 8 || isempty(varargin{8}), 
	handles.makeMovie = 0; 
else
	handles.makeMovie = varargin{1};
end

%Set the current data value.
handles.currentFrame=1;

%Initialize all the plots with this function--
handles = plotImages_initialize(hObject, eventdata, handles);

set(handles.slider2,'Min',1) %determine and set range of uicontrol slider
set(handles.slider2,'Max',handles.movieLength) %determine and set range of uicontrol slider
set(handles.slider2,'SliderStep',[1/handles.movieLength 100/handles.movieLength]);  %setup default uicontrol slider steps

% Choose default command line output for plotWholeBrainDomainsTraces
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if handles.makeMovie > 0
	pushbutton9_Callback(hObject, eventdata, handles)   %so that this can be called from commandline by passing varargin{8} without having to click on gui using an HPC session
end

% UIWAIT makes plotWholeBrainDomainsTraces wait for user response (see UIRESUME)
% uiwait(handles.figure1);


function plot3 = setupActiveFractionHandles(region)
data = region.locationData.data;
nplots = min([length(data) 6]);
for locationIndex = 1:nplots
    plot3(locationIndex).data = data(locationIndex).activeFractionByFrame;
    plot3(locationIndex).legendText = data(locationIndex).name;
    plot3(locationIndex).Fs = 1/region.timeres;   %sampling rate (Hz).  Used to convert frame times to time for aligning the ephys framemarkers.
	plot3(locationIndex).unitConvFactor = 1; %1 is no conversion. This is to get the x-units same as the other plots
end


function plot4 = setupEphysData(fhandle,channelsToFilter,handles)  %based on sigTOOL figure handle and channel handle inputs
channels=getappdata(fhandle, 'channels');
for chIdx = 1:numel(channelsToFilter)
    plot4(chIdx).data=channels{channelsToFilter(chIdx)}.adc(:,1)';
    plot4(chIdx).legendText = [num2str(channels{channelsToFilter(chIdx)}.hdr.channel) ':' channels{channelsToFilter(chIdx)}.hdr.title];
    plot4(chIdx).Fs=getSampleRate(channels{channelsToFilter(chIdx)});   %sampling rate (Hz).  Used to convert data point indices to time and to convert the framemarker to the appropriate time. 
    plot4(chIdx).unitConvFactor = handles.plot3(1).Fs;
end




function handles = plotImages_initialize(hObject, eventdata, handles)
% hObject    handle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if islogical(handles.movie1)
    handles.clims1 = [0 1];
else
	tmp = max(handles.movie1,[],3);
	tmp2 = min(handles.movie1,[],3);
    handles.clims1 = [min(tmp2(:)) max(tmp(:))];
%    handles.clims1 = [0 255];
end

if islogical(handles.movie2)
    handles.clims2 = [0 1];
else
	tmp = max(handles.movie2,[],3);
    handles.clims2 = [0 max(tmp(:))];
end

% if islogical(handles.movie3)
%     handles.clims3 = [0 1];
% else
%     clear tmp; tmp = handles.movie3(:);
%     handles.clims3 = [min(tmp) max(tmp)];
% end
% if islogical(handles.movie4)
%     handles.clims4 = [0 1];
% else
%     clear tmp; tmp = handles.movie4(:);
%     handles.clims4 = [min(tmp) max(tmp)];
% end

handles.current_data1 = handles.movie1(:,:,handles.currentFrame);
set(gcf,'CurrentAxes',handles.axes1)
handles.image1 = imagesc(handles.current_data1,handles.clims1); axis off; axis image; colormap(gray); title(handles.axesTitles{1})

handles.current_data2 = handles.movie2(:,:,handles.currentFrame);
set(gcf,'CurrentAxes',handles.axes2)
handles.image2 = imagesc(handles.current_data2,handles.clims2); axis off; axis image; colormap(gray); title(handles.axesTitles{2})

if ~isempty(handles.plot3(1).data)
%-------setup plot3-------------------
set(gcf,'CurrentAxes',handles.axes3)
nPlots = length(handles.plot3);
myColors = lines(nPlots);
%myColors = [0 0.5 1; 0 0.5 0;]
set(gca,'ColorOrder',myColors)
lineSize = 1;
ymax = [];
szZ = length(handles.plot3(1).data);
hold all
for locationIndex = 1:nPlots
% 	plot(1:szZ,data(locationIndex).activeFractionByFrame,'Color',myColors(locationIndex,:),'LineWidth',lineSize);
%     plot(1:szZ,handles.plot3(locationIndex).data,'LineWidth',lineSize);
    line(1:szZ,handles.plot3(locationIndex).data,'Color',myColors(locationIndex,:),'LineWidth',lineSize)
	mx = max(handles.plot3(locationIndex).data);
	ymax = max([ymax mx]);
    legendText{locationIndex} = handles.plot3(locationIndex).legendText;
end	
set(gca,'ylim', [0 ymax]);
xlabel('frame no.'); ylabel('Fraction of pixels active'); %title(handles.axesTitles{3});
% Static legend
% legend(legendText, 'Location', 'NorthEastOutside');

% [legend_h,object_h,plot_h,text_str] = legendflex(handles.axes3, legendText,'ref', handles.axes3, 'anchor', [3 1], 'buffer', [ 10   0]);
clickableLegend(handles.axes3,legendText,handles.slider2);  %pass axes handle, legendText cellarray of strings, and ui element you want to pass uicontrol to after button toggles


% set(gca,'LegendColorbarListeners',[]); 
% setappdata(gca,'LegendColorbarManualSpace',1);
% setappdata(gca,'LegendColorbarReclaimSpace',1);
% pan xon

	plot4(1).Fs=1;   %sampling rate (Hz).  Used to convert data point indices to appropriate time units.  Leave at '1' for no conversion (like plotting the indices, 'frames')
	plot4(1).unitConvFactor = 1;
if handles.plot4(1).unitConvFactor == 1
	linkaxes([handles.axes3 handles.axes4],'x');
end
zoom xon
%-------end setup plot3----------------
end

if ~isempty(handles.plot4(1).data)
%-------setup plot4-------------------
set(gcf,'CurrentAxes',handles.axes4)
nPlots = length(handles.plot4);
% myColors = lines(nPlots);
myColors = [0.3 0.3 0.3; 0.5 0.5 0.5];
set(gca,'ColorOrder',myColors)
lineSize = 1;
ymax = [];
szZ = length(handles.plot4(1).data);
hold all
for locationIndex = 1:nPlots
% 	plot(1:szZ,data(locationIndex).activeFractionByFrame,'Color',myColors(locationIndex,:),'LineWidth',lineSize);
%     plot(1:szZ,handles.plot4(locationIndex).data,'LineWidth',lineSize);
%     line(1:szZ,handles.plot4(locationIndex).data,'Color',myColors(locationIndex,:),'LineWidth',lineSize)
    hLine = dsplot((1:szZ)/handles.plot4(locationIndex).Fs,handles.plot4(locationIndex).data,[],handles.figure1,handles.axes4);  %3rd argument is numPoints = 50000 (default);  Change to reduce aliasing effects (brief spikes get thrown out with too few pts).
    set(hLine,'Color',myColors(locationIndex,:),'LineWidth',lineSize)
	mx = max(handles.plot4(locationIndex).data);
	ymax = max([ymax mx]);
    legendText{locationIndex} = handles.plot4(locationIndex).legendText;
end	
% set(gca,'ylim', [0 ymax]);

szZ = length(handles.plot3(1).data);

set(gca,'xlim', [0 szZ/handles.plot4(1).unitConvFactor]);   %unitConvFactor will usually be equivalent to Fs for plot3

if handles.plot4(1).unitConvFactor == 1
	xlabel('Time (frames)'); 
	ylabel('signal plot4'); %title(handles.axesTitles{4});
else
	xlabel('Time (s)'); 
	ylabel('movement signal (uV)'); %title(handles.axesTitles{4});
end

% Static legend
% legend(legendText, 'Location', 'NorthEastOutside');
% [legend_h,object_h,plot_h,text_str] = legendflex(handles.axes4, legendText,'ref', handles.axes4, 'anchor', [3 1], 'buffer', [ 10   0]);
clickableLegend(handles.axes4,legendText,handles.slider2);  %pass axes handle, legendText cellarray of strings, and ui element you want to pass uicontrol to after button toggles

% set(gca,'LegendColorbarListeners',[]); 
% setappdata(gca,'LegendColorbarManualSpace',1);
% setappdata(gca,'LegendColorbarReclaimSpace',1);

% linkaxes(ax,'x');
% pan xon
zoom xon
%-------end setup plot4----------------
end

handles = setupFrameMarkers(hObject, eventdata, handles);

% handles.current_data3 = handles.movie3(:,:,handles.currentFrame);
% set(gcf,'CurrentAxes',handles.axes3)
% imagesc(handles.current_data3,handles.clims3); axis image; colormap(gray); title(handles.axesTitles{3})
% 
% handles.current_data4 = handles.movie4(:,:,handles.currentFrame);
% set(gcf,'CurrentAxes',handles.axes4)
% imagesc(handles.current_data4,handles.clims4); axis image; colormap(gray); title(handles.axesTitles{4})

% Update handles structure
uicontrol(handles.slider2);





function handles = plotImages(handles)
% hObject    handle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.current_data1 = handles.movie1(:,:,handles.currentFrame);
set(handles.figure1,'CurrentAxes',handles.axes1)
delete(findobj(gca,'Type','line'))
set(handles.image1,'CData',handles.current_data1)  %set image data directly instead of making new imagesc call
hold on
plot(handles.data(1).frame(handles.currentFrame).allDomains.x,handles.data(1).frame(handles.currentFrame).allDomains.y,'og','MarkerSize',7);
plot(handles.data(1).frame(handles.currentFrame).goodDomains.x,handles.data(1).frame(handles.currentFrame).goodDomains.y,'om','MarkerSize',5,'MarkerFaceColor','m');
plot(handles.data(1).frame(handles.currentFrame).badDomains.x,handles.data(1).frame(handles.currentFrame).badDomains.y,'or','MarkerSize',5);
hold off        
% 
handles.current_data2 = handles.movie2(:,:,handles.currentFrame);
set(handles.figure1,'CurrentAxes',handles.axes2)
delete(findobj(gca,'Type','line'))
set(handles.image2,'CData',handles.current_data2)  %set image data directly instead of making new imagesc call
hold on
plot(handles.data(2).frame(handles.currentFrame).allDomains.x,handles.data(2).frame(handles.currentFrame).allDomains.y,'og','MarkerSize',7);
plot(handles.data(2).frame(handles.currentFrame).goodDomains.x,handles.data(2).frame(handles.currentFrame).goodDomains.y,'om','MarkerSize',5,'MarkerFaceColor','m');
plot(handles.data(2).frame(handles.currentFrame).badDomains.x,handles.data(2).frame(handles.currentFrame).badDomains.y,'or','MarkerSize',5);
hold off

% set(gcf,'CurrentAxes',handles.axes3)
set(handles.current_data3.frameMarker,'XData',[handles.currentFrame handles.currentFrame]);


% set(gcf,'CurrentAxes',handles.axes4)
set(handles.current_data4.frameMarker,'XData',[handles.currentFrame/handles.plot4(1).unitConvFactor handles.currentFrame/handles.plot4(1).unitConvFactor]);

%------------------------------------------------------------------ 
% handles.current_data3 = handles.movie3(:,:,handles.currentFrame);
% set(gcf,'CurrentAxes',handles.axes3)
% imagesc(handles.current_data3,handles.clims3); title(handles.axesTitles{3})
% hold on
% plot(handles.data(3).frame(handles.currentFrame).allDomains.x,handles.data(3).frame(handles.currentFrame).allDomains.y,'og','MarkerSize',7);
% plot(handles.data(3).frame(handles.currentFrame).goodDomains.x,handles.data(3).frame(handles.currentFrame).goodDomains.y,'om','MarkerSize',5,'MarkerFaceColor','m');
% plot(handles.data(3).frame(handles.currentFrame).badDomains.x,handles.data(3).frame(handles.currentFrame).badDomains.y,'or','MarkerSize',5);
% hold off        
% 
% handles.current_data4 = handles.movie4(:,:,handles.currentFrame);
% set(gcf,'CurrentAxes',handles.axes4)
% imagesc(handles.current_data4,handles.clims4); title(handles.axesTitles{4})
% hold on
% plot(handles.data(4).frame(handles.currentFrame).allDomains.x,handles.data(4).frame(handles.currentFrame).allDomains.y,'og','MarkerSize',7);
% plot(handles.data(4).frame(handles.currentFrame).goodDomains.x,handles.data(4).frame(handles.currentFrame).goodDomains.y,'om','MarkerSize',5,'MarkerFaceColor','m');
% plot(handles.data(4).frame(handles.currentFrame).badDomains.x,handles.data(4).frame(handles.currentFrame).badDomains.y,'or','MarkerSize',5);
% hold off        

% Update handles structure
% guidata(hObject, handles);
% uicontrol(handles.slider2);  %don't include uicontrol call here, causes max recursion limit problem 'Maximum recursion limit of 500 reached. Use set(0,'RecursionLimit',N)'


function handles = setupFrameMarkers(hObject, eventdata, handles)
% hObject    handle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%if ~isempty(handles.plot3.data)
set(gcf,'CurrentAxes',handles.axes3)
ylimits = get(handles.axes3,'YLim');
myColors = [0.5 0.5 0.5];

handles.current_data3.frameMarker = line([handles.currentFrame handles.currentFrame],ylimits,'LineStyle','-','LineWidth',1,'Color',myColors);
%end

%if ~isempty(handles.plot4.data)
set(gcf,'CurrentAxes',handles.axes4)
ylimits = get(handles.axes4,'YLim');

handles.current_data4.frameMarker = line([handles.currentFrame/handles.plot4(1).unitConvFactor handles.currentFrame/handles.plot4(1).unitConvFactor],ylimits,'LineStyle','-','LineWidth',1,'Color',myColors);   %this frameMarker converted to time (s) based on the framerate (plot3(1).Fs)
%end

function plotFrameMarkers(handles)
% hObject    handle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set(handles.current_data3.frameMarker,'XData',[handles.currentFrame handles.currentFrame]);
% set(handles.current_data4.frameMarker,'XData',[handles.currentFrame handles.currentFrame]);
% guidata(hObject, handles);





% --- Outputs from this function are returned to the command line.
function varargout = plotWholeBrainDomainsTraces_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




% --- Executes during object creation, after setting all properties.
function dataSelectMenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dataSelectMenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider2_Callback(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

currentValue = get(handles.slider2,'Value');
handles.currentFrame = round(currentValue);
set(handles.frameNumberText1,'String',num2str(handles.currentFrame));
handles = plotImages(handles);
% plotFrameMarkers(hObject, eventdata, handles);

% Update handles structure
guidata(hObject, handles);
% disp(handles)



% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function frameNumberText1_Callback(hObject, eventdata, handles)
% hObject    handle to frameNumberText1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frameNumberText1 as text
%        str2double(get(hObject,'String')) returns contents of frameNumberText1 as a double
newFrame = str2double(get(hObject,'String')); %returns contents of frameNumberText1 as a double

if newFrame >= 1 && newFrame <= handles.movieLength
    set(handles.slider2,'Value',newFrame);
    slider2_Callback(hObject, eventdata, handles);
else
    originalFrame=get(handles.SliderStepText,'String');
    set(handles.frameNumberText1,'String', originalFrame);
end
% Update handles structure
guidata(hObject, handles);
uicontrol(handles.slider2);





% --- Executes during object creation, after setting all properties.
function frameNumberText1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameNumberText1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SliderStepText_Callback(hObject, eventdata, handles)
% hObject    handle to SliderStepText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SliderStepText as text
%        str2double(get(hObject,'String')) returns contents of SliderStepText as a double
newStep = str2double(get(handles.SliderStepText,'String')); %returns contents of SliderStepText as a double
if newStep >= 1 && newStep <= handles.movieLength
    set(handles.slider2,'SliderStep',[newStep/handles.movieLength 100/handles.movieLength]);
else
    set(handles.slider2,'SliderStep',[1/handles.movieLength 100/handles.movieLength]);
    set(handles.SliderStepText,'String', num2str(1));
end
% Update handles structure
guidata(hObject, handles);
uicontrol(handles.slider2);



% --- Executes during object creation, after setting all properties.
function SliderStepText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SliderStepText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%KeyPressFcn: plotWholeBrainDomainsTraces('figure1_KeyPressFcn',hObject,eventdata,guidata(hObject))
% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
% str = get(handles.figure1_KeyPressFcn,'Key');
str = eventdata.Key;

switch lower(str)
     case '1'
%if strcmp(str,'1')  %add all true-positive domains markers from real data in green
    [x,y] = myginput2;

    currAxis= get(hObject,'CurrentAxes');
    if currAxis == handles.axes1
        for nMovies = 1:2
            handles.data(nMovies).frame(handles.currentFrame).allDomains.x = x;
            handles.data(nMovies).frame(handles.currentFrame).allDomains.y = y;
        end
    end
    plotImages(handles);
%     chi=get(currAxis,'Children');
%     xdata=get(chi,'XData');
%     ydata=get(chi,'YData');
%     disp(xdata{1})
%     disp(ydata{1})
    
%     idx1 = xdata{1};
%     idx1 = ydata{1};
%elseif strcmp(str,'2')  %add good domains markers in magenta
	case '2'
    [x,y] = myginput2;
    
    currAxis= get(hObject,'CurrentAxes');
    if currAxis == handles.axes2
        handles.data(2).frame(handles.currentFrame).goodDomains.x = x;
        handles.data(2).frame(handles.currentFrame).goodDomains.y = y;
%     elseif currAxis == handles.axes3
%         handles.data(3).frame(handles.currentFrame).goodDomains.x = x;
%         handles.data(3).frame(handles.currentFrame).goodDomains.y = y;
%     elseif currAxis == handles.axes4
%         handles.data(4).frame(handles.currentFrame).goodDomains.x = x;
%         handles.data(4).frame(handles.currentFrame).goodDomains.y = y;
    else
        return
    end
    plotImages(handles);
%elseif strcmp(str,'3')  %add bad domains markers in red
	case '3'
    [x,y] = myginput2;
    currAxis= get(hObject,'CurrentAxes');
    if currAxis == handles.axes2
        handles.data(2).frame(handles.currentFrame).badDomains.x = x;
        handles.data(2).frame(handles.currentFrame).badDomains.y = y;
%     elseif currAxis == handles.axes3
%         handles.data(3).frame(handles.currentFrame).badDomains.x = x;
%         handles.data(3).frame(handles.currentFrame).badDomains.y = y;
%     elseif currAxis == handles.axes4
%         handles.data(4).frame(handles.currentFrame).badDomains.x = x;
%         handles.data(4).frame(handles.currentFrame).badDomains.y = y;
    else
        return
    end
    plotImages(handles);    
%elseif strcmp(str,'d')  %delete
	case 'd'
    [x,y] = myginput2(1);
    currAxis= get(hObject,'CurrentAxes');
    if currAxis == handles.axes1
        for nMovies = 1:2
            handles.data(nMovies).frame(handles.currentFrame).allDomains.x = [];
            handles.data(nMovies).frame(handles.currentFrame).allDomains.y = [];
        end
    
    elseif currAxis == handles.axes2
        for nMovies = 1:2
            handles.data(nMovies).frame(handles.currentFrame).allDomains.x = [];
            handles.data(nMovies).frame(handles.currentFrame).allDomains.y = [];
        end
        handles.data(2).frame(handles.currentFrame).goodDomains.x = [];
        handles.data(2).frame(handles.currentFrame).goodDomains.y = [];
        handles.data(2).frame(handles.currentFrame).badDomains.x = [];
        handles.data(2).frame(handles.currentFrame).badDomains.y = [];
%     elseif currAxis == handles.axes3
%         for nMovies = 1:4
%             handles.data(nMovies).frame(handles.currentFrame).allDomains.x = [];
%             handles.data(nMovies).frame(handles.currentFrame).allDomains.y = [];
%         end
%         handles.data(3).frame(handles.currentFrame).goodDomains.x = [];
%         handles.data(3).frame(handles.currentFrame).goodDomains.y = [];
%         handles.data(3).frame(handles.currentFrame).badDomains.x = [];
%         handles.data(3).frame(handles.currentFrame).badDomains.y = [];
%     elseif currAxis == handles.axes4
%         for nMovies = 1:4
%             handles.data(nMovies).frame(handles.currentFrame).allDomains.x = [];
%             handles.data(nMovies).frame(handles.currentFrame).allDomains.y = [];
%         end
%         handles.data(4).frame(handles.currentFrame).goodDomains.x = [];
%         handles.data(4).frame(handles.currentFrame).goodDomains.y = [];
%         handles.data(4).frame(handles.currentFrame).badDomains.x = [];
%         handles.data(4).frame(handles.currentFrame).badDomains.y = [];
    else
        return
    end
    plotImages(handles);    
    
	 otherwise
	  % Hmmm, something wrong with the parameter string
	  %error(['Unrecognized parameter: ''' str '''']);
	  return
end
guidata(hObject, handles);
uicontrol(handles.slider2);


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'dataFilename')
%    delete(dataFilename)
    data = handles.data;
    assignin('base', 'data', data)
%    handles.dataFilename = ['temp_plotWholeBrainDomains-data-' datestr(now,'yyyymmdd-HHMMSS') '.mat'];      
    save(handles.dataFilename,'data','-v7.3')
else
    data = handles.data;
    assignin('base', 'data', data)
    handles.dataFilename = ['temp_plotWholeBrainDomains-data-' datestr(now,'yyyymmdd-HHMMSS') '.mat'];      
    save(handles.dataFilename,'data','-v7.3')
end
guidata(hObject, handles);
uicontrol(handles.slider2);


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
r = randi(handles.movieLength);  %random integer on interval [1,nFrames]
% handles.currentFrame = r;
% plotImages(handles)
% guidata(hObject, handles);
newFrame = r; %returns contents of frameNumberText1 as a double

if newFrame >= 1 && newFrame <= handles.movieLength
    set(handles.slider2,'Value',newFrame);
    slider2_Callback(hObject, eventdata, handles);
else
    originalFrame=get(handles.SliderStepText,'String');
    set(handles.frameNumberText1,'String', originalFrame);
end
% Update handles structure
guidata(hObject, handles);
uicontrol(handles.slider2);


% --------------------------------------------------------------------
function uitoggletool5_OffCallback(hObject, eventdata, handles)
% hObject    handle to uitoggletool5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uicontrol(handles.slider2);


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
helpdlg({'1. Click on fig window outside axes', '2. Keyboard press 1, 2, 3, d','     * 1 for marking all true-positives in the raw movie data',  '     * 2 for marking good domains in detected data', '     * 3 for marking false positives in detected data', '     * d to delete all domain markers for a frame'},'Marking domains in images')


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%if handles.makeMovie > 0;
	nFrames = handles.movieLength;
%	nFrames = 30;
	M(1:nFrames) = struct('cdata', [],'colormap', []);
	i = 1;
	while i <= nFrames
		set(handles.slider2,'Value',i);
		slider2_Callback(hObject, eventdata, handles);
%		guidata(hObject, handles);
		M(i) = getframe(handles.figure1);
		i = i + 1;
	end
	disp(numel(M));
	vidObj = VideoWriter(['plotWholeBrainDomainsTraces' datestr(now,'yyyymmdd-HHMMSS') '.avi'])
	open(vidObj)
	for i =1:numel(M)
		writeVideo(vidObj,M(i))
	end
	close(vidObj)	
%end
