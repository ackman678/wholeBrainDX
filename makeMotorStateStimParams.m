function region = makeMotorStateStimParams(region, motorOns, motorOffs, overwrite)
%makeMotorStateStimParams -- Convert motor period onsets and offsets as frame indices to stimuli and append to stimulusParams
%detect slow oscillatory signals and make region.stimuli.stimulusParams as % Converts the frame and stimulus times to microseconds
%James Ackman, 2013-05-02 14:31:11
%need to have 'region' data structure loaded into workspace
% INPUTS: 
%	region - struct, a valid region data structure, see calciumdx
%	motorOns - numeric vector of motor state onset times as frame indices. The number of motor onsets and motor offsets should be the same. 
%	motorOffs - numeric vector of motor state offset times as frame indices.
%	overwrite - logical flag to indicate whether a preexisting stimulus should be overwritten (based on matching the desc string)
% 
% Examples: 
%	[region] = makeStimParams(region,region.wavedata{2}.waveonsets,'waveonsets.VCtx')
%	[region] = makeStimParams(region,region.wavedata{3}.waveonsets,'waveonsets.SC')
%
% See also: batchmakeStimParamsWaveonsets, getStimParams, myFrameTriggerDetect, calciumdx, myBatchFilter
%
% Author: James B. Ackman 2013-05-06 12:21:06
%based on makeStimParams.m 2/20/2012 11:55:49 by James B. Ackman

if nargin < 4 || isempty(overwrite), overwrite = 0; end

if length(motorOns) ~= length(motorOffs)
	error('The number of motor onsets and motor offset is not the same')
end

if ~isfield(region,'nframes')
	error('region.nframes (movieLength) needed')
end

if ~isempty(motorOns)
	if motorOns(1) < 3  %if a motor offset is one frame away from the start make it fr1
		motorOns(1) = 1;
	end

	if abs(motorOns(end) - region.nframes) < 2  %if a motor onset is one frame away from end it pass through the following logic
		motorOns = motorOns(1:end-1);
		motorOffs = motorOffs(1:end-1);
	end

end

if ~isempty(motorOffs)
	if abs(motorOffs(end) - region.nframes) < 2  %if a motor offset is one frame away from end it pass through the following logic
		motorOffs(end) = region.nframes;
	end
end

% disp(['active state ons = ' num2str(motorOns)]) %TESTING
% disp(['active state offs = ' num2str(motorOffs)]) %TESTING

desc = 'motor.state.active';
region = appendStimulusParams(region, motorOns, motorOffs, desc, overwrite)

desc = 'motor.state.quiet';

q_onsets = [1 motorOffs + 1 region.nframes];
q_offsets = [1 motorOns - 1 region.nframes];

q_onsets = intersect(setxor(q_onsets,motorOns),q_onsets);
q_offsets = intersect(setxor(q_offsets,motorOffs),q_offsets);

q_onsets = unique(q_onsets(q_onsets < region.nframes & q_onsets >= 1));
q_offsets = unique(q_offsets(q_offsets <= region.nframes & q_offsets > 1));


% disp(['quiet state ons = ' num2str(q_onsets)]) %TESTING
% disp(['quiet state offs = ' num2str(q_offsets)]) %TESTING

if length(q_onsets) ~= length(q_offsets)
	error('The number of quiet onsets and offsets is not the same')
end

region = appendStimulusParams(region, q_onsets, q_offsets, desc, overwrite)


function region = appendStimulusParams(region, stimframe_indices, stimframe_offsets, desc, overwrite)
%appendStimulusParams -- generic append
	if nargin < 5 || isempty(overwrite), overwrite = 0; end
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
	   region.stimuli{j}.stimulusParams{i}.frame_indices = stimframe_indices(i):stimframe_offsets(i);
	   region.stimuli{j}.stimulusParams{i}.frame_times = [stimframe_indices(i):stimframe_offsets(i)] .* region.timeres * 1e06;
	   region.stimuli{j}.stimulusParams{i}.stimulus_times = [stimframe_indices(i) stimframe_offsets(i)] .* region.timeres * 1e06;
	   region.stimuli{j}.description = desc; 
	end
