function [index thr] = mySpikeDetect(data,Fs,thr,min_ref_per)
if nargin < 4, min_ref_per = 1.5; end
% if nargin < 3, thr = 5 * median(abs(data))/0.6745; end
if nargin < 3, thr = 5 * mad(abs(data))/0.6745; end  %mad median absolute deviation
 
ref = floor(min_ref_per*Fs/1000); %detector dead time (in ms)

nspk = 0;
xaux0 = 0;
len = numel(data);

if thr > 0
    xaux = find(data > thr); %positive threshold
    % disp(['length xaux=' num2str(numel(xaux))]) %TESTING
    index=[];
    for i=1:length(xaux)
        % disp(['xaux spike num' num2str(i) ' , fr' num2str(xaux(i))]) %TESTING
        if xaux(i) >= xaux0 + ref
            [maxi iaux]=max((data(xaux(i):min([(xaux(i)+floor(ref/2)-1) len]))));    %introduces alignment
            nspk = nspk + 1;
            index(nspk) = iaux + xaux(i) -1;
            xaux0 = index(nspk);
        end
    end
    
else
    xaux = find(data < thr); %negative threshold
    index=[];
    for i=1:length(xaux)
        if xaux(i) >= xaux0 + ref
            [maxi iaux]=min((data(xaux(i):min([(xaux(i)+floor(ref/2)-1) len]))));    %introduces alignment
            nspk = nspk + 1;
            index(nspk) = iaux + xaux(i) -1;
            xaux0 = index(nspk);
        end
    end
    
end