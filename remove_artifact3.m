function [Tr,H] = remove_artifact3(Tr, H, cfg)
%removes artifact by computing wiener filter


tr_num = numel(Tr.type);
trs = 1:min(cfg.n,tr_num);
d = numel(Tr.idx);
res = zeros(d,1);
sig = Tr.data(:,:,cfg.audio_ch); %ensure its a 2d matrix
A = sig(trs,:)';

shape = size(Tr.data);
nfft = shape(2)/2+1;
C = zeros(nfft,d);

%if filter is not provided compute it
if isempty(H)
    H = C;
    estimate_H_bool = 1;
else
    estimate_H_bool = 0;
end

for i=1:1
    N = squeeze(Tr.data(trs,:,i))';      
    
    %estimate wiener filter using coherence with audio signal
    if estimate_H_bool
        C(:,i) = estimate_coherence(A(:),N(:),shape(2));
        H(:,i) = 1 - sqrt(C(:,i));
        H = filter(ones(128,1)/128,1,H);
    end    
    
    figure, plot(H(:,1))
    
    %apply the wiener filter to remove audio interference    
    for j=1:shape(1)
        Tr.data(j,:,i) = apply_wiener_filter(Tr.data(j,:,i),H(:,i));    
    end
    
end

%structure back into epoch struct
% for i=1:1
%     tmp.data = epoch_unflatten(tmps{i},[shape(1:2) 1]);
%     Tr.data(:,:,i) = tmp.data;
% end


