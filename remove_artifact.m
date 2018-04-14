function [Tr,An,W] = remove_artifact(Tr,cfg)

n_trial = cfg.n;
[n,T,d] = size(Tr.data);
n_comp = min(16,d);

tr_max = floor(n/n_trial)*n_trial;
trs = 1:tr_max/n_trial:tr_max;
n_trial = numel(trs);

data = Tr.data(trs,:,:);
data = permute(data,[2 1 3]);
data = reshape(data,n_trial*T,d);

%[IC,A,W] = fastica(data','numOfIC',n_comp,'g','gauss','finetune','pow3','epsilon',10^-5,'a2',2^-3);
[IC,A,W] = fastica(data','numOfIC',n_comp,'verbose','off');
% [A,S] = runica(data');
% W = A*S;
% IC = A*data';

%compute corr b/w ICs and artifact
thres = 0.001;
[R,P] = corr(data(:,cfg.audio_ch),IC');
figure, plot(abs(R))
%mask = abs(R) > thres;
mask = P < thres; %find artifactual components %changed from R! abs(R) > thres;
An = A;
An(:,mask) = 0; %new mixing matrix

%compute cleaned data
for i=1:n
    tmp_data = squeeze(Tr.data(i,:,:))';
    Tr.data(i,:,:) = (An*W*tmp_data)';
end


r = 5*Tr.fs:15*Tr.fs;
figure
for i=1:n_comp
    subplot(5,5,i)
    plot(IC(i,r))
end

disp('done')