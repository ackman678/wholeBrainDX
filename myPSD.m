function PxxM = myPSD(nt,ind,Fs)
%returns a plot of the averaged Welch Power Spectral Density Estimate for one or more channels (multiple recorded timeseries)
%ind is a vector of timeseries indices to select from your nt matrix of multiple timeseries
%JBA, Wednesday, October 22, 2008 2:41 PM, 2015-01-02 02:05:45

if numel(ind) > 0
    PxxM = [];
    for i=1:length(ind)
%     [Pxx1, f] = pwelch(nt(ind(i),:),hamming(200),[],1024,Fs);
    [Pxx1, f] = pwelch(nt(ind(i),:),[],[],1024,Fs);
    %[Cxy1,F] = mscohere(r1,nt(ind(i),:),[],[],1024,1/region.timeres);  %coherence of signal with gaussian noise
    PxxM(:,i) = Pxx1(:,1);   %add new values to matrix
    end
    Hpsd = dspdata.psd(mean(PxxM,2),'Fs',Fs);   %mean of the Power spectrum values
    figure;
    plot(Hpsd)  %plot the mean power spectrum
else
    PxxM = [];
    print('Error-- less than one index input')
end
