function C = estimate_coherence(X,Y,nfft)

C = mscohere(X,Y,kaiser(4096,4),[],nfft);    
 
end