function region = makeStimTimeParams(region, tim, stim_dur, desc)
%makeStimTimeParams -- Convert stimulus onsets to stimuli and append to stimulusParams
%need to have 'region' data structure loaded into workspace
% INPUTS: 
%	region - struct, a valid region data structure, see calciumdx
%	tim - numeric vector of stimulus onset times in seconds.
%	stim_dur - single numeric or vector of stimulus durations (must be same length as tim)
% 
% Examples: 
%	[region] = makeStimTimeParams(region,tim, stim_dur,'waveonsets.VCtx')
%
% See also: batchmakeStimParamsWaveonsets, getStimParams, myFrameTriggerDetect, calciumdx, myBatchFilter, makeStimFrameParams
%
% Author: James B. Ackman 2014-11-09 14:59:30

if length(stim_dur) ~= 1 && length(stim_dur) ~= length(tim)
	error('The number of stim times and stimulus durations is not the same')
end

if length(stim_dur) == 1
	stim_dur = repmat(stim_dur(1),1,length(tim));
end

if ~isfield(region,'nframes')
	error('need to define no. of movie frames as region.nframes')
end

tim = tim.*1e06; %convert values to microseconds
stim_dur = stim_dur.*1e06; 
times = [1:region.nframes] .* region.timeres .*1e06;

if isfield(region,'stimuli')
	j = length(region.stimuli);
else
	j = 0;
end
 
for i=1:numel(tim)
    frame_indices=find(tim(i) <= times & times < (tim(i)+stim_dur(i)));
    if ~isempty(frame_indices)
        if times(frame_indices(1)-1) < tim(i) && tim(i) < times(frame_indices(1))
            frame_indices=[frame_indices(1)-1 frame_indices];
        end
        region.stimuli{j+1}.stimulusParams{i}.frame_indices=frame_indices;
        region.stimuli{j+1}.stimulusParams{i}.frame_times=times(frame_indices);
        region.stimuli{j+1}.stimulusParams{i}.stimulus_times=[tim(i) tim(i)+stim_dur(i)];
        region.stimuli{j+1}.description = desc; 
    end
end
