function [WMean, WRMS]=WeightedMean(x,W);
% Usage: OUT=WeightedMean(x,W);
%This function is designed to return the weighted mean of the input vector, 
% previously a mongrel to do on the fly.
x=x(:);
W=W(:);
WMean=sum(x.*W)/sum(W);
if length(x)==1
    WRMS=0;
else
    WRMS=sqrt(sum( ((x - WMean).^2).*W )/ (sum(W)) );
end
