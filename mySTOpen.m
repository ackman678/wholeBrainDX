function fhandle = mySTOpen(fname)
%mySTOpen
% INPUT
% fname -- optional string specifying file you want to open

if nargin < 1 || isempty(fname)    
    if exist('calciumdxprefs.mat','file') == 2
        load('calciumdxprefs')
    else
        pathname = pwd;
    end

    [filename pathname] = uigetfile({'*.kcl'; '*.mat'},'Select file to load',pathname);
    fname = fullfile(pathname,filename);

    str1 = filename(end-3:end);
    if strcmp(str1,'.mat')
        matfilename = myImportMAT(fname);
        fname = matfilename;
    end
    save('calciumdxprefs.mat', 'pathname','filename');
end

channels=scOpen(fname);
fhandle=plot(channels{:});
% clear channels;

%{
%following code can be commented out if need be. It is for adding
%parameters to sigTOOL.kcl files and highpass filtered traces.
if ~isfield(channels{2}.hdr,'userdata')
    myAddParams.m
    button = questdlg({'Add highpass (300Hz butter) filtered traces?'},'Add filtered channels','Ok','cancel','Ok');
    switch button
        case 'Ok'
            channels = myBatchFilter(fhandle,channels);
        case 'cancel'
            return
    end
end

% channels=getappdata(fhandle, 'channels');

%}