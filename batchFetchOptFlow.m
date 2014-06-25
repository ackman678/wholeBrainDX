function batchFetchOptFlow(filelist, region, varin)
%batchFetchOptFlow(filelist, region, varin)
% Fetches and makes movies of the optic flow calculation for each domain mask movie described by the region d2r file in filelist
% Examples
% filelist = readtext('files.txt',' ');
% batchFetchOptFlow(filelist);
% varin.makePlots=1; batchFetchOptFlow(filelist, region, varin);
%
% INPUTS
% filelist -- cell array of strings, full path names to the region domains2region, *d2r*.mat files
% region -- region formatted data structure (as from CalciumDX, domains2region, etc) that includes CC and STATS data structures returned from wholeBrain_segmentation.m and wholeBrain_detect.m
% varin -- optional additional arguments.
%
% See also wholeBrain_opticFlowByDomain.m, batchfetchDomainProps.m, wholeBrain_batch.m, optFlowLk.m
%
% James B. Ackman 2014-06-25 13:37:27  

if nargin< 2 || isempty(region), region = []; end
if nargin< 3 || isempty(varin), varin = []; end
if ~isfield(varin,'makePlots'), varin.makePlots=0; end

mainfcnLoop(filelist, region, varin);


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

    sprintf(fnms{j})    
	varin.fnm = fnms{j};
	
    disp('--------------------------------------------------------------------')
	
	A3 = setupMovieArray(region);
	[Vsum, ~, ~] = wholeBrain_opticFlowByDomain(A3,region,region.filename,varin.makePlots);
	region.domainData.Vsum = Vsum;
	save(fnms{j},'region','-v7.3') 

	% [pathstr, name, ext] = fileparts(fnms{j});
	% region.matfilename = [name ext];
	
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


function A3 = setupMovieArray(region)
sz=region.domainData.CC.ImageSize;
A3 = false(sz);
for i = 1:region.domainData.CC.NumObjects
	if ~strcmp(region.domainData.STATS(i).descriptor, 'artifact')
		A3(region.domainData.CC.PixelIdxList{i}) = 1;      
	end  
end
