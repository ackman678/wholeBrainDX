function viewPCs(U,n,printFig)
%viewPCs(U)
% viewPCs(mixedfilters(:,:,1:150));
% viewPCs(shiftdim(ica_filters));
% Simple interactive plot for viewing/selecting which principal components to keep
%
% Inputs:
%   U - m x n x nPCs spatial components from [U,S,V] = svd(A) or mixedfilters from cellsort_svd in Cellsort_PCA.m
%
% James Ackman
% Based off of CellsortChoosePCs.m by:
% Eran Mukamel, Axel Nimmerjahn and Mark Schnitzer, 2009
% Email: eran@post.harvard.edu, mschnitz@stanford.edu

%U = mixedfilters(:,:,1:300);
%U=shiftdim(ica_filters,1);
%U=U(:,:,1:500);

if nargin < 2 || isempty(n), n = 25; end
if nargin < 3 || isempty(printFig), printFig = 0; end

nPC = size(U,3);  %nIC or nPC
sz = size(U(:,:,1));
U = reshape(U, prod(sz), []);
U = zscore(U);

%browse ICA gui
ind = [1 min([n nPC])];
i = ind(2);
while i <= nPC  
    if i(1) < 1, 
        ind = [1 min([n nPC])]; 
        i = ind(2); 
    end 
    usepcs = ind(1):ind(2);
    pcs = reshape(U(:,usepcs), sz(1), sz(2), []);
    pcs = permute(pcs, [1, 2, 4, 3]);
    montage(pcs,'DisplayRange',[-1,1]*7); colormap(hot); colorbar
    formataxis(sz,usepcs)
    PCf = input('(''b/f'' to scroll backwards/forwards)): ','s'); 
    if PCf=='b' 
        ind = ind - n; 
    elseif (PCf=='f') 
        ind = ind + n; 
    end
    i = ind(2);
end

function formataxis(sz,usepcs)
%format axis
axis on
xl = xlim;
yl = ylim;
nw = ceil(xl(2)/sz(2))-1;
nh = ceil(yl(2)/sz(1))-1;
set(gca,'YTick',[sz(1):sz(1):yl(2)],'YTickLabel',  num2str(usepcs(min([0:nh]*nw+1, length(usepcs)))'), ...
    'XTick',[sz(2):sz(2):xl(2)], ...
    'XTickLabel',num2str(usepcs([(nh-1)*nw+1:length(usepcs)])'), 'XAxisLocation','bottom','LineWidth',2)
grid on
set(gca,'FontSize',12,'FontWeight','bold','FontName','Helvetica','LineWidth',2,'TickLength',[1,1]*.02,'tickdir','out')
set(gcf,'Color','w','PaperPositionMode','auto')

