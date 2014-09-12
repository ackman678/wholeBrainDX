function [Vsum, AVx, AVy] = wholeBrain_opticFlowByDomain(A,region,fnm,makePlots)
%wholeBrain_opticFlowByDomain - Get optic flow motion estimate of active domains in a wholeBrain movie array using optFlowLk, which uses the image registration algorithm by Lucas and Kanade 1981 implemented in the Piotr Image Processing toolbox at Caltech.  Returns the vector sum through space and time for each previously detected domain (wholeBrain_detect.m) in the array.
%Examples:
% >> [Vsum, ~, ~] = wholeBrain_opticFlowByDomain(A,region);
% >> [Vsum, ~, ~] = wholeBrain_opticFlowByDomain(A,region,region.filename);
% >> [Vsum, ~, ~] = wholeBrain_opticFlowByDomain(A,region,'mymovie.tif');
%
%**USE**
%Must provide two inputs:
%
%(1) An 3D movie array, *A* containing the binary masks or pixel values of the signals you want to get motion estimates from
%(2) The corresponding *d2r.mat 'region' file containing the region.domainData structure for the movie. 
%
%Options:
%fnm - string, filename.tif to base filename for saving .avi to
%
%Output:
%Vsum - structure, vector sum outputs for n domains containing theta (angle) and rho (magnitude)
%AVx - 3D array, x displacement array built from optic flow estimates
%AVy - 3D array, y displacement array built from optic flow estimates
%
%Dependencies:
% arrow.m
% zbuffer_cdata.m
%
% See also optFlowLk.m, wholeBrain_segmentation.m, wholeBrain_detect.m, batchfetchDomainProps.m, Domains2region.m, wholeBrain_batch.m, wholeBrain_opticFlowByFrame.m, arrow.m
%
% by James B. Ackman 2014-06-25 07:51:44

%--------Setup defaults---------------------------------------
if nargin < 3 || isempty(fnm)
	fnm2=['opticflow' datestr(now,'yyyymmdd-HHMMSS') '.avi']
else
	fnm2 = [fnm(1:end-4) '-opticflow' datestr(now,'yyyymmdd-HHMMSS') '.avi'];
end
if nargin < 4 || isempty(makePlots), makePlots = 1; end
sz=size(A);
[X,Y]=meshgrid(1:sz(2),1:sz(1));

winSig = [3];   %soft gaussian window of integration for estimating opticflow. See optFlowLk.m
sigma = [1.2];  %gaussian sigma for smoothing the image when estimating opticflow. See optFlowLk.m

arrowLength=200; %arrow length in pixels. Determines the length of the maximum vector magnitude displayed in the .avi movie

if islogical(A)
	clims=[0 1];
else
	clims=[min(A(:)) max(A(:))];
end

roiBoundingBox=vertcat(region.domainData.STATS.BoundingBox);
onsets=ceil(roiBoundingBox(:,3));
offsets=onsets+(roiBoundingBox(:,6)-1);

AVx=zeros(sz);
AVy=zeros(sz);

%--------Get optic flow in frame loop ---------------------------------------
disp('Processing optFlowLk...')
for fr = 1:sz(3)-1 %or parfor fr = 1:sz(3)-1
	img1 = A(:,:,fr);
	img2 = A(:,:,fr+1);
	[Vx,Vy,reliab] = optFlowLk( img1, img2, [], winSig, sigma, 3e-6);
	AVx(:,:,fr) = Vx;
	AVy(:,:,fr) = Vy;
end

%--------Get vector sums by domain in frame loop-----------------------------
disp('Processing Domain theta and rho...')
nDomains = numel(region.domainData.STATS);
Vsum(1:nDomains) = struct('theta',[],'rho',[]);
for k = 1:nDomains
	[theta, rho]= cart2pol(sum(AVx(region.domainData.STATS(k).PixelIdxList)), sum(AVy(region.domainData.STATS(k).PixelIdxList)));
	Vsum(k).theta = theta.*-1;
	Vsum(k).rho = rho;
end

mx = max(vertcat(Vsum.rho)); %max vector magnitude in the population for normalization of lengths

%--------Plot movie frames--------------------------------------------------
if sum(get(0, 'ScreenSize')) > 4  %hack to test whether matlab is started with no display which would give get(0, 'ScreenSize') = [1 1 1 1]
	if makePlots
		disp('Making movie...')
		% nDomains = numel(region.domainData.STATS);
		% Vsum(1:nDomains) = struct('theta',[],'rho',[]);
		h=figure;
		for fr = 1:sz(3)-1
			
			if mod(fr,100)<1
				disp([num2str(fr) '/' num2str(sz(3)-1)])
			end

			img1 = A(:,:,fr);
			imagesc(img1,clims); colormap(gray)  % By default, imagesc sets the YDir property to reverse already. Use set(gca,'YDir','normal') if normal coords are desired, but then theta has to be flipped below in pol2cart.
			hold on
			for k = 1:nDomains
				if fr >= onsets(k) & fr <= offsets(k)
					% [theta, rho]= cart2pol(sum(AVx(region.domainData.STATS(k).PixelIdxList)), sum(AVy(region.domainData.STATS(k).PixelIdxList)));
					% Vsum(k).theta = theta;
					% Vsum(k).rho = rho;

					theta=Vsum(k).theta;
					rho=Vsum(k).rho;
					xpts = region.domainData.STATS(k).Centroid(1);
					ypts = region.domainData.STATS(k).Centroid(2);
					% [dxpts,dypts] = pol2cart(theta.* -1,rho);
					[dxpts,dypts] = pol2cart(theta.*-1,(rho./mx).*arrowLength);
					% amquiver(X, Y, Vx, Vy);
					arrow([xpts, ypts], [xpts + dxpts, ypts + dypts], 10, 15, 20, 1, 'EdgeColor', 'b', 'FaceColor', 'b', 'LineWidth', 2);
				end
			end

			hold off
			set(h,'Renderer','zbuffer')
			M(fr) = im2frame(zbuffer_cdata(h));  %grab figure data for frame without getframe screen draw issues
		end

		%--------Write movie---------------------------------------
		vidObj = VideoWriter(fnm2)
		open(vidObj)
		for i =1:numel(M)
		writeVideo(vidObj,M(i))
		end
		close(vidObj)

		close all
	end
end
