function [region, def] = dxInputParamsOpt(region, def)
%dxInputParamsOpt
%Examples:
% >>region = dxInputParamsOpt(region)
%USE:
% 	region --  region data structure returned from calciumdx
%James B. Ackman 2014-02-23 15:39:17, 2014-12-30 15:44:46

prompt = {'Type (wt, C57BL6, emx-gcamp3, etc):','Age (P3, P8, etc):','Type of experiment (2P.img, CCD.img, img.ephys):','Calcium dye used:','Brain area (cortex, SC.L, V1.R, etc):','Enter field factor (f1, f2, etc):','Enter y or n if z-artifact present:','Enter z-depth below pia (in um):','Enter type of anesthetic:','Enter inhal anesthetic percentage:','Comments:'};
dlg_title = 'Optional experimental information';
num_lines = 1;

if nargin < 2 || isempty(def)
	if isfield(region,'animaltype') & isfield(region,'age') & isfield(region,'exptype') & isfield(region, 'dye') & isfield(region,'brainarea') & isfield(region,'field') & isfield(region,'zartifact') & isfield(region,'zdepth') & isfield(region,'anesthetic') & isfield(region,'anesthpercent') & isfield(region,'comments')
		def = {region.animaltype,region.age,region.exptype,region.dye,region.brainarea,region.field,region.zartifact,region.zdepth,region.anesthetic,num2str(region.anesthpercent),region.comments};
	else
		def = {'snap25-gcamp6','','CMOS.img','gcamp','cortex','','n','','isoflurane','0',''};
	end
end
optionsDlg.Resize='on';
answer = inputdlg(prompt,dlg_title,num_lines,def,optionsDlg);

region.animaltype = answer{1};
region.age = answer{2};
region.exptype = answer{3};
region.dye = answer{4};
region.brainarea = answer{5};
region.field = answer{6};
region.zartifact = answer{7};
region.zdepth = answer{8};
region.anesthetic = answer{9};
region.anesthpercent = str2double(answer{10});
region.comments = answer{11};
def = {region.animaltype,region.age,region.exptype,region.dye,region.brainarea,region.field,region.zartifact,region.zdepth,region.anesthetic,num2str(region.anesthpercent),region.comments};
