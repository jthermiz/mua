function Tr = man_chan_select(Tr, cfg)

[n,T,d] = size(Tr.data);
data = permute(Tr.data,[2 1 3]);
data = reshape(data,[n*T d]);
sigma = std(data);
bar(sort(sigma));
thres = input('Enter sigma threshold: ');
mask = sigma < thres;
ccfg= [];
ccfg.chs = Tr.idx(mask);
Tr = epoch_chs(Tr,ccfg);

end