function [region, def] = dxInputParamsSetup(region, def)
%dxInputParamsSetup
%Examples:
% >>region = dxInputParamsSetup(region)
%USE:
% 	region --  region data structure returned from calciumdx
%(Optional: For the 'extraFiles' variable that will be assigned to region.extraFiles **pass filenames for additional tiff movie files** ('region.extraFiles') if the recording consists of multiple 2GB tiff files) as a **space-delimited character vector**. This will be passed downstream using textscan()
%nframes: Set to the number of frames so that the motor signal preprocessing is the correct length
%James B. Ackman 2014-02-23 15:39:17, 2014-12-30 15:44:40

prompt = {'Spatial resolution (um/px):','Temporal resolution (sec):', 'Number of movie frames:' ,'extraFiles:'};
dlg_title = 'Input experimental parameters';
num_lines = 1;

if nargin < 2 || isempty(def)
	if isfield(region,'spaceres') & isfield(region,'timeres') & isfield(region,'nframes') & isfield(region,'extraFiles')
		def = {num2str(region.spaceres),num2str(region.timeres),num2str(region.nframes),region.extraFiles};
	else
		def = {'','','3000',''};
	end
end

optionsDlg.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,optionsDlg);

if ~isfield(region,'image')
	[filename, pathname] = uigetfile({'*.jpg;*.png;*.tif'}, 'Choose AVG single frame image file to open');
	fn = fullfile(pathname,filename);
	img = imread(fn);
	region.image = img;
elseif isempty(region.image)
	[filename, pathname] = uigetfile({'*.jpg;*.png;*.tif'}, 'Choose AVG single frame image file to open');
	fn = fullfile(pathname,filename);
	img = imread(fn);
	region.image = img;
end

def = answer;
region.spaceres = str2double(answer{1});
region.timeres = str2double(answer{2});
region.nframes = str2double(answer{3});
region.extraFiles = answer{4};

if ~isfield(region,'name') & ~isfield(region,'coords')
	region.name{1} = 'field';
	sz = size(region.image);
	region.coords{1} = [1 1; 1 sz(1); sz(2) sz(1); sz(2) 1];
elseif isempty(region.name)
	region.name{1} = 'field';
	sz = size(region.image);
	region.coords{1} = [1 1; 1 sz(1); sz(2) sz(1); sz(2) 1];
end

if ~isfield(region,'stimuli')
	region.stimuli = [];
end
if ~isfield(region,'motorSignal')
	region.motorSignal = [];
end

if ~isfield(region,'orientation')
	imgfig = figure; imagesc(region.image)
	[x y butt] = ginput(1);
	x = round(x);
	y = round(y);
	if x < 0
	    x = 0;
	elseif x > size(region.image,2)
	    x = size(region.image,2);
	end
	if y < 0
	    y = 0;
	elseif y > size(region.image,1)
	    y = size(region.image,1);
	end
	def_ans1 = 'anteriormedial point = (Y,X); (Y,X) = row, cols';
	def_ans2 = [y x];
	prompt = {'Provide description of orientation coordinate in image:','orientation coordinate in image [Y]:', 'orientation coordinate in image [X]:'};
	dlg_title = 'Input experimental parameters';
	num_lines = 1;
	def2 = {def_ans1,num2str(def_ans2(1)),num2str(def_ans2(2))};
	answer = inputdlg(prompt,dlg_title,num_lines,def2);
	region.orientation.description = answer{1};
	region.orientation.value = [str2double(answer{2}) str2double(answer{3})];
	close(imgfig)
end
