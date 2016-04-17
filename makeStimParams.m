function [region] = makeStimParams(region,stimframe_indices,desc,overwrite)
%makeStimParams - Convert frame indices to stimulus parameters
% Adds a list of frame indices as stimulusParams to a region data structure. It appends to the list of any existing stimulusParams, so you can analyse many different stimulus types in your files. 
% Converts the frame and stimulus times to microseconds
% INPUTS: 
%	region - struct, a valid region data structure, see calciumdx
%	stimframe_indices - numeric vector of stimulus times as frame indices
%	desc - string descriptor for the simulus. Recommended to have no spaces for downstream applications, use dot, underscore, or camelCase notations to concatentate word descriptors
% overwrite - logical flag to indicate whether a preexisting stimulus should be overwritten (based on matching the desc string)
% 
% Examples: 
%	[region] = makeStimParams(region,region.wavedata{2}.waveonsets,'waveonsets.VCtx')
%	[region] = makeStimParams(region,region.wavedata{3}.waveonsets,'waveonsets.SC')
%
% See also: batchmakeStimParamsWaveonsets, getStimParams, myFrameTriggerDetect, calciumdx, myBatchFilter
%
% Author: James B. Ackman 2/20/2012 11:55:49

if nargin < 4 || isempty(overwrite), overwrite = 0; end

if ~isfield(region,'stimuli')
  region.stimuli = {}; 
end

if length(region.stimuli) > 0
  j = length(region.stimuli) + 1;
  if overwrite
    for i = 1:length(region.stimuli)
      if strcmp(region.stimuli{i}.description,desc)
        j = i;
        region.stimuli{i}.stimulusParams = {};
      end
    end
  end
else
  j = 1;
end

for i=1:length(stimframe_indices)
   region.stimuli{j}.stimulusParams{i}.frame_indices = stimframe_indices(i);
   region.stimuli{j}.stimulusParams{i}.frame_times = stimframe_indices(i) .* region.timeres * 1e06;
   region.stimuli{j}.stimulusParams{i}.stimulus_times = stimframe_indices(i) .* region.timeres * 1e06;
   region.stimuli{j}.description = desc; 
end
