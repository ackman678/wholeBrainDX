function [idx1, idx2] = getNonActiveFrameDurations(x)

% x = data(1).activeFractionByFrame; 

sig = x;
figure, 
ax(1)=subplot(4,1,1);
plot(sig); title('active Fraction by frame')

ax(2)=subplot(4,1,2);
x(x>0) = -1;	
plot(x); title('active periods to negative pulse')
%ylim([-1.5 1.5])

ax(3)=subplot(4,1,3);
x(x>-1) = 1;
x(x<1) = 0;
plot(x); title('Non-active periods to positive pulse')		
%ylim([-1.5 1.5])

ax(4)=subplot(4,1,4);
dx = diff(x);
dx2 = [dx 0];
plot(dx2); title('derivative of non-active pulse')		
linkaxes(ax,'x')
zoom xon

wvonsets = find(dx > 0);
wvoffsets = find(dx < 0);

axes(ax(1))
hold on
plot(wvonsets,sig(wvonsets),'og');
plot(wvoffsets,sig(wvoffsets),'or');

axes(ax(3))
hold on
plot(wvonsets,x(wvonsets),'og');
plot(wvoffsets,x(wvoffsets),'or');

axes(ax(4))
hold on
plot(wvonsets,dx2(wvonsets),'og');
plot(wvoffsets,dx2(wvoffsets),'or');

idx1 = wvonsets;
idx2 = wvoffsets;

%figure out if an offset was at last frame of movie (no. of onsets and offsets not equal)
if numel(idx1) ~= numel(idx2)
    button = questdlg('Number of onsets not equal to number of offsets (Event may be at start or end of movie). Automatically Fix?');
    %     errordlg('Number of onsets not equal to number of offsets. Final offset set to last xpoint, in case wave was at end of movie.')
    if strcmp(button,'Yes')
        if idx1(1) > idx2(1)
            idx1 = [1 idx1];
        end
        
        if idx2(end) < idx1(end)
           idx2 = [idx2 size(x,2)];
        end
    end
end