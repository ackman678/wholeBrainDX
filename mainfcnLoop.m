function mainfcnLoop(filelist, region, datafilename, functionHandles, datasetSelector, fid, useStimuli, stimuliIndices)
%start loop through files-----------------------------------------------------------------

if nargin < 5 || isempty(datasetSelector), datasetSelector=[]; end
if nargin < 7 || isempty(useStimuli), useStimuli=[]; end
if nargin < 8 || isempty(stimuliIndices), stimuliIndices=[]; end

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
    
    if ~isfield(region,'filename')    
		if size(filelist,2) > 1 && ~isfield(region,'filename')
			[pathstr, name, ext] = fileparts(fnms2{j});
			region.filename = [name ext];  %2012-02-07 jba
		else
			region.filename = ['.tif'];
		end
    end
	[pathstr, name, ext] = fileparts(fnms{j});
	region.matfilename = [name ext];  %2012-02-07 jba    
	
%	rowinfo = [name1 name2];  %cat cell array of strings
%	rowinfo = filelist(j,:);
    sprintf(fnms{j})    

    disp('--------------------------------------------------------------------')
	%myEventProps(region,rowinfo);
	functionHandles.main(region, functionHandles.workers, datafilename, datasetSelector, fid, useStimuli, stimuliIndices)
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
