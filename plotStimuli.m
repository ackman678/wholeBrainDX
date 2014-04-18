function plotStimuli(region,stimuli,minY,maxY,mycolors,stimDesc)
% plotStimuli(region,stimuli,minY,maxY,mycolors,desc)
%James B. Ackman 2014-04-18 10:54:46  

if nargin < 6 || isempty(stimDesc), stimDesc = 'motor.state.active'; end

for numStim = 1:length(stimuli)
	if strcmp(stimuli{numStim}.description,desc)
%		 mycolors = [0.8 0.8 1.0; 0.8 1.0 0.8; 1.0 0.8 0.8; 0.6 0.6 1.0; 0.6 1.0 0.6; 1.0 0.6 0.6; 0.4 0.4 1.0; 0.4 1.0 0.4; 1.0 0.4 0.4];        
			for i=1:numel(stimuli{numStim}.stimulusParams)
				x1=(stimuli{numStim}.stimulusParams{i}.frame_indices(1)/stimuli{numStim}.stimulusParams{i}.frame_times(1))*stimuli{numStim}.stimulusParams{i}.stimulus_times(1);
				x2=(stimuli{numStim}.stimulusParams{i}.frame_indices(end)/stimuli{numStim}.stimulusParams{i}.frame_times(end))*stimuli{numStim}.stimulusParams{i}.stimulus_times(end);
				x = [x1; x1; x2; x2];
				y = [minY; maxY; maxY; minY];
				h1(i) = patch(x,y,mycolors(numStim,:));  % fill
	%             set(h1(i),'EdgeColor',mycolors(numStim,:));  %outline
				set(h1(i),'EdgeColor',mycolors(numStim,:));  %outline
	%             set(h1(i),'FaceAlpha',0.1,'EdgeAlpha',0.1)  %looks great but matlab does not export transparency well
%				set(h1(i),'DisplayName',stimuli{numStim}.description{1})
			end
			text(x1,maxY,stimDesc)
	end
end
