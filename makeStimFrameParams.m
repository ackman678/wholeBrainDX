function region = makeStimFrameParams(region, onsets, offsets, desc)
%makeStimFrameParams -- Make onsets and offsets as frame indices to stimuli and append to stimulusParams
%James Ackman, 2014-11-09 14:54:10
%need to have 'region' data structure loaded into workspace
% INPUTS: 
%	region - struct, a valid region data structure, see calciumdx
%	onsets - numeric vector of onset times as frame indices.
%	offsets - numeric vector of offset times as frame indices.
% 
% Examples: 
%	[region] = makeStimFrameParams(region,frOnsets, frOffsets,'waveonsets.VCtx')
%
% See also: batchmakeStimParamsWaveonsets, getStimParams, myFrameTriggerDetect, calciumdx, myBatchFilter, makeStimTimeParams
%
% Author: James B. Ackman 2014-11-03 12:14:37
%based on makeStimParams.m 2/20/2012 11:55:49 by James B. Ackman

if length(onsets) ~= length(offsets)
	error('The number of onsets and offsets is not the same')
end

region = appendStimulusParams(region, onsets, offsets, desc);


function region = appendStimulusParams(region, stimframe_indices, stimframe_offsets, desc)
%appendStimulusParams -- generic append
	if isfield(region,'stimuli')
		j = length(region.stimuli);
	else
		j = 0;
	end

	for i=1:length(stimframe_indices)
	   region.stimuli{j+1}.stimulusParams{i}.frame_indices = stimframe_indices(i):stimframe_offsets(i);
	   region.stimuli{j+1}.stimulusParams{i}.frame_times = [stimframe_indices(i):stimframe_offsets(i)] .* region.timeres * 1e06;
	   region.stimuli{j+1}.stimulusParams{i}.stimulus_times = [stimframe_indices(i) stimframe_offsets(i)] .* region.timeres * 1e06;
	   region.stimuli{j+1}.description = desc; 
	end
