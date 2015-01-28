 function PlotPCspectrum(fn, CovEvals, PCuse)
% PlotPCspectrum(fn, CovEvals, PCuse)
%
% Plot the principal component (PC) spectrum and compare with the
% corresponding random-matrix noise floor
%
% Inputs:
%   fn - movie file name. Must be in TIFF format.
%   CovEvals - eigenvalues of the covariance matrix
%   PCuse - [optional] - indices of PCs included in dimensionally reduced
%   data set
%
% Forked from CellsortPlotPCspectrum by Eran Mukamel, Axel Nimmerjahn and Mark Schnitzer, 2009
% Edited by James Ackman 2015
% References:  
% [#Sengupta:1999]: Sengupta, A. M. and Mitra, P. P. (1999).  Distributions of singular values for some random matrices, Phys Rev E Stat Phys Plasmas Fluids Relat Interdiscip Topics, 60(3), 3389-92
% [#Mitra:1999]: Mitra, P. P. and Pesaran, B. (1999).  Analysis of dynamic brain imaging data, Biophys J, 76(2), 691-708

if nargin<3
    PCuse = [];
end

[pixw,pixh] = size(imread(fn,1));
npix = pixw*pixh;
nt = tiff_frames(fn);

% Random matrix prediction (Sengupta & Mitra)
p1 = npix; % Number of pixels
q1 = nt; % Number of time frames
q = max(p1,q1);
p = min(p1,q1);
sigma = 1;
lmax = sigma*sqrt(p+q + 2*sqrt(p*q));
lmin = sigma*sqrt(p+q - 2*sqrt(p*q));
lambda = [lmin: (lmax-lmin)/100.0123423421: lmax];
rho = (1./(pi*lambda*(sigma^2))).*sqrt((lmax^2-lambda.^2).*(lambda.^2-lmin^2));
rho(isnan(rho)) = 0;
rhocdf = cumsum(rho)/sum(rho);
noiseigs = interp1(rhocdf, lambda, [p:-1:1]'/p, 'linear', 'extrap').^2 ;

% Normalize the PC spectrum
normrank = min(nt-1,length(CovEvals));
pca_norm = CovEvals*noiseigs(normrank) / (CovEvals(normrank)*noiseigs(1));

clf
plot(pca_norm, 'o-', 'Color', [1,1,1]*0.3, 'MarkerFaceColor', [1,1,1]*0.3, 'LineWidth',2)
hold on
plot(noiseigs / noiseigs(1), 'b-', 'LineWidth',2)
plot(2*noiseigs / noiseigs(1), 'b--', 'LineWidth',2)
if ~isempty(PCuse)
    plot(PCuse, pca_norm(PCuse), 'rs', 'LineWidth',2)
end
hold off
formataxes
set(gca,'XScale','log','YScale','log', 'Color','none')
xlabel('PC rank')
ylabel('Normalized variance')
axis tight
if isempty(PCuse)
    legend('Data variance','Noise floor','2 x Noise floor')
else
    legend('Data variance','Noise floor','2 x Noise floor','Retained PCs')
end

fntitle = fn;
fntitle(fn=='_') = ' ';
title(fntitle)

function formataxes

set(gca,'FontSize',12,'FontWeight','bold','FontName','Helvetica','LineWidth',2,'TickLength',[1,1]*.02,'tickdir','out')
set(gcf,'Color','w','PaperPositionMode','auto')

function j = tiff_frames(fn)
%
% n = tiff_frames(filename)
%
% Returns the number of slices in a TIFF stack.
%
%

status = 1; j=0;
jstep = 10^3;
while status
    try
        j=j+jstep;
        imread(fn,j);
    catch
        if jstep>1
            j=j-jstep;
            jstep = jstep/10;
        else
            j=j-1;
            status = 0;
        end
    end
end