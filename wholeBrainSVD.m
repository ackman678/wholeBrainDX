function [mixedsig, mixedfilters, CovEvals, covtrace, movtm] = wholeBrainSVD(fn, mov, nPCs)
% [mixedsig, mixedfilters, CovEvals, covtrace, movtm] = wholeBrainSVD(fn, mov, nPCs)
%
% Read TIFF movie data and perform singular-value decomposition (SVD)
% dimensionality reduction.
%
% Inputs:
%   fn - movie file name. e.g. '140509_01.tif'
%   mov - double precision XYT movie array. where X*Y = no. of pixels for the space-time matrix used for SVD.
%   nPCs - number of principal components to be returned
%
% Outputs:
%   mixedsig - N x T matrix of N temporal signal mixtures sampled at T
%   points.
%   mixedfilters - N x X x Y array of N spatial signal mixtures sampled at
%   X x Y spatial points.
%   CovEvals - largest eigenvalues of the covariance matrix
%   covtrace - trace of covariance matrix, corresponding to the sum of all
%   eigenvalues (not just the largest few)
%   movm - average of all movie time frames at each pixel
%   movtm - average of all movie pixels at each time frame, after
%   normalizing each pixel deltaF/F
%
% Based upon CellsortPCA.m by Eran Mukamel, Axel Nimmerjahn and Mark Schnitzer, Neuron 2009
% Edited by James B. Ackman 2014 for wholeBrainDX workflow
% References:  
% [#Prechtl:1997]: Prechtl, J. C., Cohen, L. B., Pesaran, B., Mitra, P. P., and Kleinfeld, D. (1997).  Visual stimuli induce waves of electrical activity in turtle cortex, Proc Natl Acad Sci U S A, 94(14), 7621-6
% [#Sengupta:1999]: Sengupta, A. M. and Mitra, P. P. (1999).  Distributions of singular values for some random matrices, Phys Rev E Stat Phys Plasmas Fluids Relat Interdiscip Topics, 60(3), 3389-92
% [#Mitra:1999]: Mitra, P. P. and Pesaran, B. (1999).  Analysis of dynamic brain imaging data, Biophys J, 76(2), 691-708



tic
fprintf('-------------- PCA %s: %s -------------- \n', date, fn)

%-----------------------
% Check inputs
if isempty(dir(fn))
    error('Invalid input file name.')
end

if nargin < 2 || isempty(mov)
    error('Input valid dF/F movie structure')
end

nt = size(mov,3);

if nargin<3 || isempty(nPCs)
    nPCs = min(150, nt);
end

% if nargin<5 || isempty(outputdir)
%     outputdir = [pwd,'/cellsort_preprocessed_data/'];
% end

% if isempty(dir(outputdir))
%     mkdir(pwd, '/cellsort_preprocessed_data/')
% end
% if outputdir(end)~='/';
%     outputdir = [outputdir, '/'];
% end

% [fpath, fname] = fileparts(fn);
% fnmat = [outputdir, fname, '_' date,'.mat'];

% if ~isempty(dir(fnmat))
%     fprintf('CELLSORT: Movie %s already processed;', ...
%         fn)
%     forceload = input(' Re-load data? [0-no/1-yes] ');
%     if isempty(forceload) || forceload==0
%         load(fnmat)
%         return
%     end
% end

[pixw,pixh] = size(mov(:,:,1));
npix = pixw*pixh;

fprintf('   %d pixels x %d time frames;', npix, nt)
if nt<npix
    fprintf(' using temporal covariance matrix.\n')
else
    fprintf(' using spatial covariance matrix.\n')
end

mov = reshape(mov, npix, nt);
% Create covariance matrix
if nt < npix
    [covmat, movtm] = create_tcov(mov, pixw, pixh, nt);
else
    [covmat, movtm] = create_xcov(mov, pixw, pixh, nt);
end
covtrace = trace(covmat) / npix;

if nt < npix
    % Perform SVD on temporal covariance
    [mixedsig, CovEvals, percentvar] = cellsort_svd(covmat, nPCs, nt, npix);

    % Load the other set of principal components
    [mixedfilters] = reload_moviedata(pixw*pixh, mov, mixedsig, CovEvals);
else
    % Perform SVD on spatial components
    [mixedfilters, CovEvals, percentvar] = cellsort_svd(covmat, nPCs, nt, npix);

    % Load the other set of principal components
    [mixedsig] = reload_moviedata(nt, mov', mixedfilters, CovEvals);
end
nPCs = size(mixedsig,1);
mixedfilters = reshape(mixedfilters, pixw,pixh,nPCs);

%------------
% Save the output data
% save(fnmat,'mixedfilters','CovEvals','mixedsig','movm','movtm','covtrace')
% fprintf(' CellsortPCA: saving data and exiting; ')
toc

function [covmat, movtm] = create_xcov(mov, pixw, pixh, nt)
%-----------------------
% Load movie data to compute the spatial covariance matrix

npix = pixw*pixh;

movtm = mean(mov,2); % Average over space
clear movmzeros

c1 = (mov*mov')/size(mov,2);
toc
covmat = c1 - movtm*movtm';
clear c1

function [covmat, movtm] = create_tcov(mov, pixw, pixh, nt)
%-----------------------
% Load movie data to compute the temporal covariance matrix
npix = pixw*pixh;

c1 = (mov'*mov)/npix;
movtm = mean(mov,1); % Average over space
covmat = c1 - movtm'*movtm;
clear c1

function [mixedsig, CovEvals, percentvar] = cellsort_svd(covmat, nPCs, nt, npix)
%-----------------------
% Perform SVD

covtrace = trace(covmat) / npix;

opts.disp = 0;
opts.issym = 'true';
if nPCs<size(covmat,1)
    [mixedsig, CovEvals] = eigs(covmat, nPCs, 'LM', opts);  % pca_mixedsig are the temporal signals, mixedsig
else
    [mixedsig, CovEvals] = eig(covmat);
    CovEvals = diag( sort(diag(CovEvals), 'descend'));
    nPCs = size(CovEvals,1);
end
CovEvals = diag(CovEvals);
if nnz(CovEvals<=0)
    nPCs = nPCs - nnz(CovEvals<=0);
    fprintf(['Throwing out ',num2str(nnz(CovEvals<0)),' negative eigenvalues; new # of PCs = ',num2str(nPCs),'. \n']);
    mixedsig = mixedsig(:,CovEvals>0);
    CovEvals = CovEvals(CovEvals>0);
end

mixedsig = mixedsig' * nt;
CovEvals = CovEvals / npix;

percentvar = 100*sum(CovEvals)/covtrace;
fprintf([' First ',num2str(nPCs),' PCs contain ',num2str(percentvar,3),'%% of the variance.\n'])

function [mixedfilters] = reload_moviedata(npix, mov, mixedsig, CovEvals)
%-----------------------
% Re-load movie data
nPCs = size(mixedsig,1);

Sinv = inv(diag(CovEvals.^(1/2)));

movtm = mean(mov,1); % Average over space
movuse = mov - ones(npix,1) * movtm;
mixedfilters = reshape(movuse * mixedsig' * Sinv, npix, nPCs);
