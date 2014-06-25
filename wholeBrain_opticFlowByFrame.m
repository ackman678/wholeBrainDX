function wholeBrain_opticFlowByFrame(A,region,fnm)
%wholeBrain_opticFlowByFrame - Get optic flow motion estimate of active frames in a wholeBrain movie array using optFlowLk, which uses the image registration algorithm by Lucas and Kanade 1981 implemented in the Piotr Image Processing toolbox at Caltech.  Returns the a movie with the vector sum for each individual connected component in the frame.
%Examples:
% >> [Vsum, ~, ~] = wholeBrain_opticFlowByFrame(A,region);
% >> [Vsum, ~, ~] = wholeBrain_opticFlowByFrame(A,region,region.filename);
% >> [Vsum, ~, ~] = wholeBrain_opticFlowByFrame(A,region,'mymovie.tif');
%
%**USE**
%Must provide two inputs:
%
%(1) An 3D movie array, *A* containing the binary masks of the signals you want to get motion estimates from.
%(2) The corresponding *d2r.mat 'region' file containing the region.domainData structure for the movie. 
%
%Options:
%fnm - string, filename.tif to base filename for saving .avi to
%
%
% See also optFlowLk.m, wholeBrain_segmentation.m, wholeBrain_detect.m, batchfetchDomainProps.m, Domains2region.m, wholeBrain_batch.m, wholeBrain_opticFlowByDomain.m
%
% by James B. Ackman 2014-06-25 07:52:15

%--------Setup defaults---------------------------------------
if nargin < 3 || isempty(fnm)
	fnm2=['opticflow' datestr(now,'yyyymmdd-HHMMSS') '.avi']
else
	fnm2 = [fnm(1:end-4) '-opticflow' datestr(now,'yyyymmdd-HHMMSS') '.avi'];
end
sz=size(A);
[X,Y]=meshgrid(1:sz(2),1:sz(1));
filtTF = [0]; %whether to use median filter on the Vx, Vy optic flow matrices
winSig = [3]; %soft gaussian window of integration for estimating opticflow. See optFlowLk.m
sigma = [1.2]; %gaussian sigma for smoothing the image when estimating opticflow. See optFlowLk.m
% inds = [length domains];
frStart = 1;
frEnd = sz(3);
clear V M
% V(1:numel(frEnd-frStart)) = struct('Vx',zeros(sz(1:2)),'Vy',zeros(sz(1:2)));
i=0;
h=figure;

%--------Start frame loop---------------------------------------
for fr = frStart:frEnd-1
	i = i+1;
	img1 = A(:,:,fr);
	img2 = A(:,:,fr+1);

	imagesc(img1,[0 1]); set(gca,'ydir','reverse'); colormap(gray)
	hold on

	[Vx,Vy,reliab] = optFlowLk( img1, img2, [], winSig, sigma, 3e-6);
	% Normalize the lengths of the arrows
	mag = sqrt(Vx.^2 + Vy.*2);
	dxptsN = Vx ./ mag;
	dyptsN = Vy ./ mag;
	bw = ~isnan(dxptsN) & ~isnan(dyptsN);
	ind = find(bw);


	if ~isempty(ind)
		if filtTF > 0
			Vx = medfilt2(Vx, [7 7]);  %use default medfilt2 (which has a 3x3 default).
			Vy = medfilt2(Vy, [7 7]);  %use default medfilt2 (which has a 3x3 default).
		end
		S = regionprops(img1, 'Centroid', 'PixelIdxList');		
		% R(1:length(S)) = struct('theta',[],'rho',[]);
		% vCentrs=round(vertcat(S.Centroid));
		% centrInd = sub2ind(sz, round(vCentrs(:,2))', round(vCentrs(:,1))', round(vCentrs(:,3))'); 

		for k = 1:length(S)
			[theta, rho]= cart2pol(sum(Vx(S(k).PixelIdxList)), sum(Vy(S(k).PixelIdxList)));
			xpts = S(k).Centroid(1);
			ypts = S(k).Centroid(2);
			% R(k).theta = theta;
			% R(k).rho = rho;
			% [dxpts,dypts] = pol2cart(theta.* -1,rho);
			[dxpts,dypts] = pol2cart(theta,rho);
			% amquiver(X, Y, Vx, Vy);
			arrow([xpts, ypts], [xpts + dxpts, ypts + dypts], 10, 12, 16, 'EdgeColor', 'b', 'FaceColor', 'b', 'LineWidth', 2);
		end
	end

	hold off
	set(h,'Renderer','zbuffer')
	M(i) = im2frame(zbuffer_cdata(h));  %grab figure data for frame without getframe screen draw issues
	disp([num2str(i) '/' num2str(frEnd-frStart)])		
end

%--------Write movie---------------------------------------
vidObj = VideoWriter(fnm2)
open(vidObj)
for i =1:numel(M)
writeVideo(vidObj,M(i))
end
close(vidObj)
