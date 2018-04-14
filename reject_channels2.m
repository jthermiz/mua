function good_chans = reject_channels2(Tr, sig,  cfg)

man_bool = ~isfield(cfg,'thres');

max_lag = 100;%round(Tr.fs/200); %5 msec
d = numel(Tr.idx);
res = zeros(d,1);
lag = res;

skp_cnt = cfg.skp_cnt; %skip every 'skp_cnt'
tr_num = numel(Tr.type);
trs = 1:skp_cnt:tr_num;

sig = squeeze(sig); %ensure its a 2d matrix
A = sig(trs,:)';

for i=1:d
    N = squeeze(Tr.data(trs,:,i))';
    [r,lags] = xcorr(A(:), N(:) ,max_lag,'coeff');
    [res(i),idx] = max(r);
    lag(i) = lags(idx);
end


figure, subplot(2,1,1)
bar(res)
grid on
subplot(2,1,2)
bar(sort(res))
grid on

if man_bool
    thres = input('Input Threshold: ');
else
    thres = cfg.thres;
end

good_chans = Tr.idx(res < thres);

end