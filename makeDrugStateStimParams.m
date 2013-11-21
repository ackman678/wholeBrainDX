function region = makeDrugStateStimParams(region, drugOns, drugOffs, drugString)
%makeMotorStateStimParams -- Convert motor period onsets and offsets as frame indices to stimuli and append to stimulusParams
%detect slow oscillatory signals and make region.stimuli.stimulusParams as % Converts the frame and stimulus times to microseconds
%James Ackman, 2013-05-02 14:31:11
%need to have 'region' data structure loaded into workspace
% INPUTS: 
%	region - struct, a valid region data structure, see calciumdx
%	drugOns - numeric vector of motor state onset times as frame indices. The number of motor onsets and motor offsets should be the same. 
%	drugOffs - numeric vector of motor state offset times as frame indices.
%	drugString - string descriptor
% 
% Examples: 
%	[region] = makeStimParams(region,region.wavedata{2}.waveonsets,'waveonsets.VCtx')
%	[region] = makeStimParams(region,region.wavedata{3}.waveonsets,'waveonsets.SC')
%
% See also: batchmakeStimParamsWaveonsets, getStimParams, myFrameTriggerDetect, calciumdx, myBatchFilter
%
% Author: James B. Ackman 2013-05-06 12:21:06
%based on makeStimParams.m 2/20/2012 11:55:49 by James B. Ackman

if length(drugOns) ~= length(drugOffs)
	error('The number of motor onsets and motor offset is not the same')
end

if nargin < 4 || isempty(drugString), drugString = 'drug'; end

desc = ['drug.state.' drugString];
region = appendStimulusParams(region, drugOns, drugOffs, desc)

desc = 'drug.state.control';

if ~isfield(region,'nframes')
	error('region.nframes (movieLength) needed')
end

q_onsets = [1 drugOffs + 1 region.nframes];
q_offsets = [1 drugOns - 1 region.nframes];

q_onsets = intersect(setxor(q_onsets,drugOns),q_onsets);
q_offsets = intersect(setxor(q_offsets,drugOffs),q_offsets);

q_onsets = unique(q_onsets(q_onsets < region.nframes & q_onsets >= 1));
q_offsets = unique(q_offsets(q_offsets <= region.nframes & q_offsets > 1));

if length(q_onsets) ~= length(q_offsets)
	error('The number of quiet onsets and offsets is not the same')
end

region = appendStimulusParams(region, q_onsets, q_offsets, desc)


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
