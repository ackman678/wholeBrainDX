function writeMovie(M,filename,useFFmpeg)
%writeMovie - Make avi movie
%PURPOSE -- Make movie video from a colormapped matlab movie structure. Called by Iarr2avi.m and others and used in conjunction with output from timeColorMapProj.m
%USAGE -- 	writeMovie(M, 'filename.avi');
% M - A matlab specific 'movie' data structure
% filename - string, the 'filename.avi' that the data come from and the string from which the output filename will be formatted
%
% See also timeColorMapProj.m, Iarr2montage.m, myMovie2avi.m, Iarr2avi.m
%
%James B. Ackman 2014-12-31 10:46:39

if nargin < 3 || isempty(useFFmpeg), useFFmpeg = 1; end
if nargin < 2 || isempty(filename), filename = ['movie' datestr(now,'yyyymmdd-HHMMSS') '.avi']; end

disp(['Making ' filename '-----------'])

if useFFmpeg > 0
	%logic to check whether ffmpeg is installed locally
	if exist('ffmpeg') == 2
		useFFmpeg = 1;
	else
		useFFmpeg = 0;
	end

	if isunix && useFFmpeg < 1
		switchVal = system('which ffmpeg');
		if switchVal > 0
			useFFmpeg = 0;
		else
			useFFmpeg = 1;
		end
	end
end

if useFFmpeg
	if isunix && ~ismac 
		%rm -rf /dev/shm/wbDXtmp
		tmpPath = ['/dev/shm/wbDXtmp' datestr(now,'yyyymmddHHMMSS')];
		%tmpPath = '/tmp/wbDXtmp';
		%tmpPath = 'wbDXtmp';
		system(['mkdir ' tmpPath]);
	else
		tmpPath = ['wbDXtmp' datestr(now,'yyyymmddHHMMSS')];
		mkdir(tmpPath)
	end
	szZ = numel(M);
	for fr = 1:szZ; %option:parfor
		tmpFilename = fullfile(tmpPath, sprintf('img%05d.jpg',fr));
		if isempty(M(fr).colormap)
			imwrite(M(fr).cdata,tmpFilename)
		else
			imwrite(M(fr).cdata,M(fr).colormap,tmpFilename)
		end
	end
	
	tic
	disp('ffmpeg running...')
	try
		%System cmd to ffmpeg:
		%system('ffmpeg -f image2 -i img%05d.jpg -vcodec mjpeg a.avi')
		system(['ffmpeg -f image2 -i ' tmpPath filesep 'img%05d.jpg -vcodec mjpeg ' filename])
		%system(['ffmpeg -f image2 -i ' tmpPath filesep 'img%05d.jpg -r 30 ' filename])
		%The call to ffmpeg can be modified to write something other than a motion jpeg avi video:
		%system('ffmpeg -f image2 -i img%05d.png a.mpg')
		rmdir(tmpPath,'s');
	catch
		rmdir(tmpPath,'s');
		error(errstr);
	end
	toc
else
	tic
	disp('FFmpeg not found. writeVideo running instead...please be very patient')
	vidObj = VideoWriter(filename);
	open(vidObj);
	for i =1:numel(M)
	    writeVideo(vidObj,M(i));
	end
	close(vidObj);
	toc
end
