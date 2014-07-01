function cdata = zbuffer_cdata(hfig)
% Get CDATA from hardcopy using zbuffer
% Need to have PaperPositionMode be auto 
orig_mode = get(hfig, 'PaperPositionMode');
set(hfig, 'PaperPositionMode', 'auto');
cdata = hardcopy(hfig, '-Dzbuffer', '-r0');
% Restore figure to original state
set(hfig, 'PaperPositionMode', orig_mode); % end

%For the "OpenGL" renderer you can write a similar code. This technique will not work for the "painters" renderer.
