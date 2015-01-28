function A = openMovie(fn,extraFiles,useBioformats)
% A = openMovie(fn)
% Open or more TIFF movie files and concatenate together 
%Can ignore imfinfo Warning: The datatype for tag Software should be TIFF_ASCII instead of TIFF_SHORT.
%fn = filename; 
%useBioformats -- binary 0 or 1 on whether to use the builtin matlab imread or to use the bioformats_package.jar to read in the image array data. Defaults to 0 (use builtin imread)
%extraFiles should be a single space-delimited character vector of additional movie filenames

if nargin < 3 || isempty(useBioformats), useBioformats = 0; end
if nargin < 2 || isempty(extraFiles), extraFiles = []; end
if nargin < 1 || isempty(fn)
	[filename, pathname] = uigetfile({'*.tif'}, 'Choose raw movie file to open');
	fn = fullfile(pathname,filename);
end
[pathstr, name, ext] = fileparts(fn);

%Read in the primary or first movie file:  
A = readTIFF(fn,useBioformats);

%Find out whether there are extra movie files that need to be concatenated together with the first one (regular tiffs have 2+GB limit in size):  
if ~isempty(extraFiles)
    C = textscan(extraFiles,'%s', ' ');  %region.extraFiles should be a single space-delimited character vector of additional movie filenames        
    for i = 1:numel(C{1})       
        if ~strcmp(fn,C{1}{i})  %if the current filename is not the first one proceed with concatenation               
            fn2=fullfile(pathstr,C{1}{i});
            B = readTIFF(fn2,useBioformats);
            A = cat(3, A, B);
            clear B
        end
    end
end

function A = readTIFF(fn,useBioformats)
if useBioformats
	if exist('myOpenOMETiff.m') == 2 && exist('bfopen.m') == 2
		[~, series1] = myOpenOMEtiff(fn);
		A = double(series1);
		clear series1
	end
else
	info = imfinfo(fn);
	nt = numel(info);
	width = info(1).Width;
	height = info(1).Height;
	A = zeros(height, width, nt);
	fprintf('Reading movie... \n    ');
	for i = 1:nt; %option:parfor
	    A(:,:,i) = imread(fn,i,'Info',info);
	    % if mod(i,500) == 1
	    %     fprintf('.');
	    % end
	end
	fprintf('\n');
end
