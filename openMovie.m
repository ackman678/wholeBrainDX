function A = openMovie(fn,useBioformats)
%Can ignore imfinfo Warning: The datatype for tag Software should be TIFF_ASCII instead of TIFF_SHORT.
%fn = filename; 
%useBioformats -- binary 0 or 1 on whether to use the builtin matlab imread or to use the bioformats_package.jar to read in the image array data. Defaults to 0 (use builtin imread)
if nargin < 2 || isempty(useBioformats), useBioformats = 0; end
if nargin < 1 || isempty(fn)
	[filename, pathname] = uigetfile({'*.tif'}, 'Choose raw movie file to open');
	fn = fullfile(pathname,filename);
end

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
