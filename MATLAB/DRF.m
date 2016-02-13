function [DRF_corey, lag, Ambig_spacing_ns]=DRF(freq)
% Usage: [DRF_corey,lag,DRF_all]=DRF(freq)
% This function computes the multi-band delay resolution function for a
% set of input frequencies (freq, in MHz). The DRF_corey variable is the DRF as returned by Brian
% Corey's script, the
% corresponding lags (lag) and Ambiguity Spacing which is the DRF
freq=freq-min(freq);
delfreq=[];
Ambig_freq=[];
for i=1:length(freq)-1
    for ii=i+1:length(freq)
        delfreq=[delfreq freq(i)-freq(ii)];
        Ambig_freq(length(Ambig_freq)+1)=gcd(freq(i), freq(ii));
    end
end
delfreq=abs(delfreq);
Ambig_spacing_ns=1E3/min(Ambig_freq);

lag=-1E-9*Ambig_spacing_ns/2:1E-10:1E-9*Ambig_spacing_ns/2;

drf=zeros(size(lag));
for i=1:length(freq)
  drf_corey(i,:)=exp(j*2*pi*freq(i)*1E6 * lag);
end

DRF_corey=abs(sum(drf_corey));
DRF_corey=DRF_corey/max(DRF_corey);
