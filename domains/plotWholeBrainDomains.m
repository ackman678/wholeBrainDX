function varargout = plotWholeBrainDomains(varargin)
% PLOTWHOLEBRAINDOMAINS MATLAB code for plotWholeBrainDomains.fig
% This function is utilized to visualize and compare multiple copies of the
% same movie (in this case up to 4) and can interactively mark
% all real positive ROIs (calcium domains in this case) as well as
% true-positive detected vs false-positive detected domains. and can export
% the data to workspace for error rate detection statistics.
%
%EXAMPLE:  plotWholeBrainDomains(movie1,movie2,movie3,movie4,movieTitles)
%INPUTS: movie1, movie2, movie3, and movie4 are MxNxP matlab arrays
% (uint8 or logical format is best) that get passed within varargin where
% movie1 is varargin{1}, etc.
% movieTitles is a 1xN cell array of strings, whose text describes each
% movie. 
% 
%
%      PLOTWHOLEBRAINDOMAINS, by itself, creates a new PLOTWHOLEBRAINDOMAINS or raises the existing
%      singleton*.
%
%      H = PLOTWHOLEBRAINDOMAINS returns the handle to a new PLOTWHOLEBRAINDOMAINS or the handle to
%      the existing singleton*.
%
%      PLOTWHOLEBRAINDOMAINS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOTWHOLEBRAINDOMAINS.M with the given input arguments.
%
%      PLOTWHOLEBRAINDOMAINS('Property','Value',...) creates a new PLOTWHOLEBRAINDOMAINS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plotWholeBrainDomains_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plotWholeBrainDomains_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help plotWholeBrainDomains

% Last Modified by GUIDE v2.5 01-Apr-2013 09:51:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plotWholeBrainDomains_OpeningFcn, ...
                   'gui_OutputFcn',  @plotWholeBrainDomains_OutputFcn, ...
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


% --- Executes just before plotWholeBrainDomains is made visible.
function plotWholeBrainDomains_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plotWholeBrainDomains (see VARARGIN)

%-------BEGIN JBA EDIT---------
% Create the data to plot.

handles.movie1 = varargin{1};
handles.movie2 = varargin{2};
handles.movie3 = varargin{3};
handles.movie4 = varargin{4};
handles.axesTitles = varargin{5};
handles.movieLength = length(handles.movie1);

if length(varargin) < 6   %check if previously saved data structure was passed to function
    for nMovies = 1:4
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
    data = varargin{6};
    for nMovies = 1:4
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


% Set the current data value.
handles.currentFrame=1;

handles = plotImages_initialize(hObject, eventdata, handles);

set(handles.slider2,'Min',1) %determine and set range of slider
set(handles.slider2,'Max',handles.movieLength) %determine and set range of slider
set(handles.slider2,'SliderStep',[1/handles.movieLength 100/handles.movieLength]);

%-------END JBA EDIT-----------

% Choose default command line output for plotWholeBrainDomains
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes plotWholeBrainDomains wait for user response (see UIRESUME)
% uiwait(handles.figure1);



function handles = plotImages_initialize(hObject, eventdata, handles)
% hObject    handle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if islogical(handles.movie1)
    handles.clims1 = [0 1];
else
%     clear tmp; tmp = handles.movie1(:);
%     handles.clims1 = [min(tmp) max(tmp)];
    handles.clims1 = [0 255];
end

if islogical(handles.movie2)
    handles.clims2 = [0 1];
else
    clear tmp; tmp = handles.movie2(:);
    handles.clims2 = [min(tmp) max(tmp)];
end

if islogical(handles.movie3)
    handles.clims3 = [0 1];
else
    clear tmp; tmp = handles.movie3(:);
    handles.clims3 = [min(tmp) max(tmp)];
end
if islogical(handles.movie4)
    handles.clims4 = [0 1];
else
    clear tmp; tmp = handles.movie4(:);
    handles.clims4 = [min(tmp) max(tmp)];
end

handles.current_data1 = handles.movie1(:,:,handles.currentFrame);
set(gcf,'CurrentAxes',handles.axes1)
imagesc(handles.current_data1,handles.clims1); axis image; colormap(gray); title(handles.axesTitles{1})

handles.current_data2 = handles.movie2(:,:,handles.currentFrame);
set(gcf,'CurrentAxes',handles.axes2)
imagesc(handles.current_data2,handles.clims2); axis image; colormap(gray); title(handles.axesTitles{2})

handles.current_data3 = handles.movie3(:,:,handles.currentFrame);
set(gcf,'CurrentAxes',handles.axes3)
imagesc(handles.current_data3,handles.clims3); axis image; colormap(gray); title(handles.axesTitles{3})

handles.current_data4 = handles.movie4(:,:,handles.currentFrame);
set(gcf,'CurrentAxes',handles.axes4)
imagesc(handles.current_data4,handles.clims4); axis image; colormap(gray); title(handles.axesTitles{4})

% Update handles structure
uicontrol(handles.slider2);





function plotImages(hObject, eventdata, handles)
% hObject    handle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.current_data1 = handles.movie1(:,:,handles.currentFrame);
set(gcf,'CurrentAxes',handles.axes1)
imagesc(handles.current_data1,handles.clims1); title(handles.axesTitles{1})
hold on
plot(handles.data(1).frame(handles.currentFrame).allDomains.x,handles.data(1).frame(handles.currentFrame).allDomains.y,'og','MarkerSize',7);
plot(handles.data(1).frame(handles.currentFrame).goodDomains.x,handles.data(1).frame(handles.currentFrame).goodDomains.y,'om','MarkerSize',5,'MarkerFaceColor','m');
plot(handles.data(1).frame(handles.currentFrame).badDomains.x,handles.data(1).frame(handles.currentFrame).badDomains.y,'or','MarkerSize',5);
hold off        

handles.current_data2 = handles.movie2(:,:,handles.currentFrame);
set(gcf,'CurrentAxes',handles.axes2)
imagesc(handles.current_data2,handles.clims2); title(handles.axesTitles{2})
hold on
plot(handles.data(2).frame(handles.currentFrame).allDomains.x,handles.data(2).frame(handles.currentFrame).allDomains.y,'og','MarkerSize',7);
plot(handles.data(2).frame(handles.currentFrame).goodDomains.x,handles.data(2).frame(handles.currentFrame).goodDomains.y,'om','MarkerSize',5,'MarkerFaceColor','m');
plot(handles.data(2).frame(handles.currentFrame).badDomains.x,handles.data(2).frame(handles.currentFrame).badDomains.y,'or','MarkerSize',5);
hold off        

handles.current_data3 = handles.movie3(:,:,handles.currentFrame);
set(gcf,'CurrentAxes',handles.axes3)
imagesc(handles.current_data3,handles.clims3); title(handles.axesTitles{3})
hold on
plot(handles.data(3).frame(handles.currentFrame).allDomains.x,handles.data(3).frame(handles.currentFrame).allDomains.y,'og','MarkerSize',7);
plot(handles.data(3).frame(handles.currentFrame).goodDomains.x,handles.data(3).frame(handles.currentFrame).goodDomains.y,'om','MarkerSize',5,'MarkerFaceColor','m');
plot(handles.data(3).frame(handles.currentFrame).badDomains.x,handles.data(3).frame(handles.currentFrame).badDomains.y,'or','MarkerSize',5);
hold off        

handles.current_data4 = handles.movie4(:,:,handles.currentFrame);
set(gcf,'CurrentAxes',handles.axes4)
imagesc(handles.current_data4,handles.clims4); title(handles.axesTitles{4})
hold on
plot(handles.data(4).frame(handles.currentFrame).allDomains.x,handles.data(4).frame(handles.currentFrame).allDomains.y,'og','MarkerSize',7);
plot(handles.data(4).frame(handles.currentFrame).goodDomains.x,handles.data(4).frame(handles.currentFrame).goodDomains.y,'om','MarkerSize',5,'MarkerFaceColor','m');
plot(handles.data(4).frame(handles.currentFrame).badDomains.x,handles.data(4).frame(handles.currentFrame).badDomains.y,'or','MarkerSize',5);
hold off        

% Update handles structure
guidata(hObject, handles);
uicontrol(handles.slider2);




% --- Outputs from this function are returned to the command line.
function varargout = plotWholeBrainDomains_OutputFcn(hObject, eventdata, handles) 
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
handles.currentFrame = floor(currentValue);
set(handles.frameNumberText1,'String',num2str(handles.currentFrame));
plotImages(hObject, eventdata, handles);
% Update handles structure
guidata(hObject, handles);



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
if strcmp(str,'1')  %add all true-positive domains markers from real data in green
    [x,y] = ginput;

    currAxis= get(hObject,'CurrentAxes');
    if currAxis == handles.axes1
        for nMovies = 1:4
            handles.data(nMovies).frame(handles.currentFrame).allDomains.x = x;
            handles.data(nMovies).frame(handles.currentFrame).allDomains.y = y;
        end
    end
    plotImages(hObject, eventdata, handles)
%     chi=get(currAxis,'Children');
%     xdata=get(chi,'XData');
%     ydata=get(chi,'YData');
%     disp(xdata{1})
%     disp(ydata{1})
    
%     idx1 = xdata{1};
%     idx1 = ydata{1};
elseif strcmp(str,'2')  %add good domains markers in magenta
    [x,y] = ginput;
    
    currAxis= get(hObject,'CurrentAxes');
    if currAxis == handles.axes2
        handles.data(2).frame(handles.currentFrame).goodDomains.x = x;
        handles.data(2).frame(handles.currentFrame).goodDomains.y = y;
    elseif currAxis == handles.axes3
        handles.data(3).frame(handles.currentFrame).goodDomains.x = x;
        handles.data(3).frame(handles.currentFrame).goodDomains.y = y;
    elseif currAxis == handles.axes4
        handles.data(4).frame(handles.currentFrame).goodDomains.x = x;
        handles.data(4).frame(handles.currentFrame).goodDomains.y = y;
    else
        return
    end
    plotImages(hObject, eventdata, handles)
elseif strcmp(str,'3')  %add bad domains markers in red
    [x,y] = ginput;
    currAxis= get(hObject,'CurrentAxes');
    if currAxis == handles.axes2
        handles.data(2).frame(handles.currentFrame).badDomains.x = x;
        handles.data(2).frame(handles.currentFrame).badDomains.y = y;
    elseif currAxis == handles.axes3
        handles.data(3).frame(handles.currentFrame).badDomains.x = x;
        handles.data(3).frame(handles.currentFrame).badDomains.y = y;
    elseif currAxis == handles.axes4
        handles.data(4).frame(handles.currentFrame).badDomains.x = x;
        handles.data(4).frame(handles.currentFrame).badDomains.y = y;
    else
        return
    end
    plotImages(hObject, eventdata, handles)    
elseif strcmp(str,'d')  %delete
    [x,y] = ginput(1);
    currAxis= get(hObject,'CurrentAxes');
    if currAxis == handles.axes1
        for nMovies = 1:4
            handles.data(nMovies).frame(handles.currentFrame).allDomains.x = [];
            handles.data(nMovies).frame(handles.currentFrame).allDomains.y = [];
        end
    
    elseif currAxis == handles.axes2
        for nMovies = 1:4
            handles.data(nMovies).frame(handles.currentFrame).allDomains.x = [];
            handles.data(nMovies).frame(handles.currentFrame).allDomains.y = [];
        end
        handles.data(2).frame(handles.currentFrame).goodDomains.x = [];
        handles.data(2).frame(handles.currentFrame).goodDomains.y = [];
        handles.data(2).frame(handles.currentFrame).badDomains.x = [];
        handles.data(2).frame(handles.currentFrame).badDomains.y = [];
    elseif currAxis == handles.axes3
        for nMovies = 1:4
            handles.data(nMovies).frame(handles.currentFrame).allDomains.x = [];
            handles.data(nMovies).frame(handles.currentFrame).allDomains.y = [];
        end
        handles.data(3).frame(handles.currentFrame).goodDomains.x = [];
        handles.data(3).frame(handles.currentFrame).goodDomains.y = [];
        handles.data(3).frame(handles.currentFrame).badDomains.x = [];
        handles.data(3).frame(handles.currentFrame).badDomains.y = [];
    elseif currAxis == handles.axes4
        for nMovies = 1:4
            handles.data(nMovies).frame(handles.currentFrame).allDomains.x = [];
            handles.data(nMovies).frame(handles.currentFrame).allDomains.y = [];
        end
        handles.data(4).frame(handles.currentFrame).goodDomains.x = [];
        handles.data(4).frame(handles.currentFrame).goodDomains.y = [];
        handles.data(4).frame(handles.currentFrame).badDomains.x = [];
        handles.data(4).frame(handles.currentFrame).badDomains.y = [];
    else
        return
    end
    plotImages(hObject, eventdata, handles)    
    
else
    return
end
guidata(hObject, handles);


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'dataFilename')
    delete(dataFilename)
    data = handles.data;
    assignin('base', 'data', data)
    handles.dataFilename = ['temp_plotWholeBrainDomains-data-' datestr(now,'yyyymmdd-HHMMSS') '.mat'];      
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
% plotImages(hObject, eventdata, handles)
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
