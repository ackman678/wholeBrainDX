function [Array1,Array2] = myWholeBrainBackgroundSubstract(fnm,diskRadius,deltaF)
%Open a calcium imaging recording, perform background subtraction
%James B. Ackman
%2012-12-20
%INPUTS:
%deltaF: string, 'yes' or 'no'.  Whether or not you want to perform the subtraction on a deltaF/F normalized signal (divide each frame by average fluorescence image)
%diskRadius: numeric, optional radius of strel 'disk' object for the imopen operation (morphological opening to make background image)
%fnm: string, optional full filename
%OUTPUTS: 
%Array1, Array2 -- optional
%2012-12-21 update
%2013-03-12 12:13:21 update with improved background subtract algorithm

if nargin < 3 || isempty(deltaF), deltaF= 'yes'; end

if nargin < 2 || isempty(diskRadius), diskRadius= 60; end

if nargin < 1 || isempty(fnm)
    if exist('pathname','var')
        [filename, pathname] = uigetfile({'*.tif'}, 'Choose image to open',pathname);
        if ~ischar(filename)
            return
        end
    else
        [filename, pathname] = uigetfile({'*.tif'}, 'Choose image to open');
        if ~ischar(filename)
            return
        end
    end
    fnm = [pathname filename];
    save('calciumdxprefs.mat', 'pathname','filename')
end

A = openMovie(fnm);

%%Make deltaF/F movie
Amean = mean(A,3);
szZ = size(A,3);
%Comment out the following for loop for non dF testing...
if strcmp(deltaF,'yes')
	% 
	for i = 1:szZ
	%     A(:,:,i) = (A(:,:,i) - region.image)./region.image;
		A(:,:,i) = (A(:,:,i) - Amean)./Amean;
	end
	%}
	Amin2D = min(A,[],3);
	Amin = min(Amin2D(:));
	A = A + abs(Amin);  %Scale deltaF array so everything is positive valued	
end

sz = size(Amean);

% myOpen;
% fnm = [pathname filename];

fnm2=[fnm(1:end-4) '_bkgndSubtr-yes_' num2str(diskRadius) '_dF-' deltaF '-' datestr(now,'yyyymmdd-HHMMSS') '.tif'];
fnm3=[fnm(1:end-4) '_bkgndSubtr-no_' num2str(diskRadius) '_dF-' deltaF '-' datestr(now,'yyyymmdd-HHMMSS') '.tif'];

%{
%--------for direct write------------------------------------
parfor fr = 1:szZ; %option:parfor
I = A(:,:,fr);
    %fr=26;
% 	img1 = A(:,:,fr);
% 	I = img1;
		%for i = [60]
%             diskDiameter = 60;
%             h=figure;
%             subplot(4,2,1)
%             imshow(I,[]); title(['fr ' num2str(fr)])
			background = imopen(I,strel('disk',diskRadius));
% 			subplot(4,2,2)
% 			imshow(background,[]); title(['background, disk ' num2str(i)])
			% figure, surf(double(background(1:8:end,1:8:end))),zlim([0 255]);  %view background image
			% set(gca,'ydir','reverse');
			I2 = I - background;  %subtract background
% 			subplot(4,2,3); imshow(I2,[]); title('background subtract')

            minValue = abs(min(I2(:)));
            I2 = round((I2 + minValue).*2^16);  %scale data to fit within uint16 range [0,2^16), because df/F gives negative values   %commented out, keep double for mat2gray
            Array1 = uint16(I2);
            %Write to multipage TIFF
            imwrite(Array1, fnm2,'tif', 'Compression', 'none', 'WriteMode', 'append');
% end 

    if rem(fr,100) == 0
%         waitbar(i/size(s,1),hbar);
%         disp('.')
        disp([num2str(fr) '/' num2str(szZ)])
    end

end
%}

A1 = zeros([sz szZ]);
A2 = zeros([sz szZ]);

%Array1 = zeros([sz szZ],'uint16');
%Array2 = zeros([sz szZ],'uint16');

%--------for write to memory------------------------------------
parfor fr = 1:szZ; %option:parfor
I = A(:,:,fr);
    %fr=26;
% 	img1 = A(:,:,fr);
% 	I = img1;
		%for i = [60]
%             diskDiameter = 60;
%             h=figure;
%             subplot(4,2,1)
%             imshow(I,[]); title(['fr ' num2str(fr)])
			background = imopen(I,strel('disk',diskRadius));
% 			subplot(4,2,2)
% 			imshow(background,[]); title(['background, disk ' num2str(i)])
			% figure, surf(double(background(1:8:end,1:8:end))),zlim([0 255]);  %view background image
			% set(gca,'ydir','reverse');
			I2 = I - background;  %subtract background
% 			subplot(4,2,3); imshow(I2,[]); title('background subtract')
			A1(:,:,fr) = I2;
			A2(:,:,fr) = I;

%This commented out code block was old algorithm, which scaled and assigned data to uint16 arrays within the loop, in a more memory efficient manner, but did not use an array-wide min value for scaling the data, so this was making the background levels fluctuate.
%{
            %write out the background subtracted movie to uint16 array
            minValue = abs(min(I2(:)));   %***Doing the minvalue addition in this step makes the background levels fluctuate severely from frame to frame!
            if strcmp(deltaF,'yes')
				I2scale = round((I2 + minValue).*(2^16-1));  %scale data to fit within uint16 range [0,2^16), because df/F gives negative values   %commented out, keep double for mat2gray.  %***Doing the minvalue addition in this step makes the background levels fluctuate severely from frame to frame!
            else
				I2scale = I2;  %for no dF/F  <-------TESTING
			end
            I2int16 = uint16(I2scale);
            Array1(:,:,fr)=I2int16;
            
            %write out the raw movie to uint16 array
            minValue = abs(min(I(:)));
			if strcmp(deltaF,'yes')
				I3 = round((I + minValue).*(2^16-1));  %scale data to fit within uint16 range [0,2^16), because df/F gives negative values   %commented out, keep double for mat2gray
			else				
				I3 = I;  %for no dF/F   <------TESTING
			end
            I3int16 = uint16(I3);
            Array2(:,:,fr)=I3int16;
%}
            
            %Write to multipage TIFF
%             imwrite(Array1, fnm2,'tif', 'Compression', 'none', 'WriteMode', 'append');
% end 

    if rem(fr,100) == 0
%         waitbar(i/size(s,1),hbar);
%         disp('.')
        disp([num2str(fr) '/' num2str(szZ)])
    end

end

Amin2D = min(A1,3);
Amin = min(Amin2D(:));
A1 = A1 + abs(Amin);  %Scale deltaF array so everything is positive valued
A1 = mat2gray(A1);
A1 = A1.*(2^16-1);
Array1 = uint16(A1);
clear A1

Amin2D = min(A2,3);
Amin = min(Amin2D(:));
A2 = A2 + abs(Amin);  %Scale deltaF array so everything is positive valued
A2 = mat2gray(A2);
A2 = A2.*(2^16-1);
Array2 = uint16(A2);
clear A2


%--------for write to disk------------------------------------
%Since write to disk is small percent of the total computation time, okay to have outside for loop as long as enough memory on system to hold both large arrays.
for fr = 1:size(Array1,3);
%     imwrite(Array1(:,:,fr), '120703_01_fr2400-3000_backgroundSubtract','tif', 'Compression', 'none', 'WriteMode', 'append');
    imwrite(Array1(:,:,fr), fnm2,'tif', 'Compression', 'none', 'WriteMode', 'append');
    imwrite(Array2(:,:,fr), fnm3,'tif', 'Compression', 'none', 'WriteMode', 'append');
end

