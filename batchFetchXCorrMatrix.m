function results = batchFetchXCorrMatrix(filelist, region, varin)

if nargin< 2 || isempty(region), region = []; end
if nargin< 3 || isempty(varin), varin = []; end

results = mainfcnLoop(filelist, region, varin);

function results = mainfcnLoop(filelist, region, varin)
%start loop through files-----------------------------------------------------------------

if nargin< 2 || isempty(region); 
    region = []; loadfile = 1; 
else
    loadfile = 0;
end

fnms = filelist(:,1);

if size(filelist,1) > 1 && size(filelist,2) > 1
	fnms2 = filelist(:,2);
end

for j=1:numel(fnms)
    if loadfile > 0
        matfile=load(fnms{j});
        region=matfile.region;
    end

%	[pathstr, name, ext] = fileparts(fnms{j});

    sprintf(fnms{j})    
	varin.fnm = fnms{j};
	
    disp('--------------------------------------------------------------------')
	cM = getXCorrLagMatrix(region, varin);
	results(j).cM = cM;
	results(j).filename = fnms{j};
%	results(j).nframes = region.nframes;
%	results(j).timeres = region.timeres;
	
	
	if ismac | ispc
		h = waitbar(j/numel(fnms));
	else
		disp([num2str(j) '/' num2str(numel(fnms))])		
    end
end
%data=results;
if ismac | ispc
	close(h)
end




function cM = getXCorrLagMatrix(region, varin)
if ~isfield(varin, 'st')
	st(1).str = {'HL.L' 'HL.R' 'T.L' 'T.R' 'FL.L' 'FL.R'};      
	st(2).str = {'M1.L' 'M1.R' 'M2.L' 'M2.R'};      
	st(3).str = {'M1.L' 'M1.R'};      
	st(4).str = {'M2.L' 'M2.R'};      
	st(5).str = {'barrel.L' 'barrel.R' 'AS.L' 'AS.R'};      
	st(6).str = {'barrel.L' 'barrel.R'};      
	st(7).str = {'RSA.L' 'RSA.R'};      
	st(8).str = {'PPC.L' 'PPC.R'};      
	st(9).str = {'V1.L' 'V1.R'};      
	st(10).str = {'V2L.L' 'V2L.R' 'V2M.L' 'V2M.R'};
end

if ~isfield(varin, 'fnm')
	fnm = 'd2r.mat'
else
	fnm = varin.fnm
end

if ~isfield(varin, 'makePlots')
	makePlots = 1;
else
	makePlots = varin.makePlots;
end

if isfield(varin, 'rsFactor')
	rsFactor = varin.rsFactor;
else
	rsFactor = 1;
end

if isfield(varin, 'timeres')
	rsFactor = varin.timeres / region.timeres;  %resample factor if different sampling rates
	if varin.nframes ~= (region.nframes*(1/rsFactor))  %make sure if resampling is performed, that the new signals will be the same length
		error('Movies not same length of time-- crop movies or edit batchFetchXCorrMatrix.m arg before proceeding')
	end
else
	rsFactor = 1;
end

if isfield(region,'motorSignal') 
	[region, cM, lags] = wholeBrain_MotorSignalCorr(fnm,region,st, [], [], rsFactor);  

	if makePlots > 0
		ind = numel(region.userdata.motorCorr);
		szZ=(size(cM,2) + 1) / 2; 
		titleStr='motorXcorrLags';
		imagesc(cM)
		colorbar
		names = region.userdata.motorCorr{ind}.names;
		names = names(~strcmp(names,'motorSignal'));
		set(gca,'YTick',[1:length(names)])
		set(gca,'YTickLabel',names)

		xticklabels = -szZ:50:szZ;  %make it centered around lag zero with 100 fr spacing
		xticks = linspace(1, size(cM, 2), numel(xticklabels));
		set(gca, 'XTick', xticks, 'XTickLabel', xticklabels)
		set(gca,'XLim',[-250 250] + szZ)  %set xlim to within 250fr of zeroth lag
		title(titleStr)
		zoom xon
		fnm2 = [fnm(1:length(fnm)-4) '_' titleStr '_' datestr(now,'yyyymmdd-HHMMSS')];    
		set(gcf,'PaperPositionMode','auto');
		print('-dpng', [fnm2 '.png'])
		print('-depsc', [fnm2 '.eps'])
	end
else
	error('No motor signal found-- add or edit batchFetchXCorrMatrix.m logic')
end
