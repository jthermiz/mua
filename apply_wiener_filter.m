function y = apply_wiener_filter(x ,H )

H = reshape(H,1,numel(H));

X = fft(x);
n = numel(X);
X = X(1:(n/2+1)); %discard negative freqs
Y = H.*X; %apply filter %%% erroring because of dim mismatch... didn't account for trials
Y = [Y fliplr(conj(Y(2:end-1)))];
y = ifft(Y);