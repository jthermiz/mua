function Tr = epoch_filt(Tr, cfg)
%filter signals forward and reverse using 3-order butterworth filter
%specify filter parameters using fcfg.range 
%Example:
    % fcfg.range = [1 10]; %Hz
    % fcfg.invert = 0; %bandpass or bandstop
    % Tr = epoch_filt(Tr, fcfg);
    %Note make sure filtering is stable!

range = cfg.range;
ny = Tr.fs/2;
order = 3; 

%design filter
if cfg.range(1) == 0
    %low pass filter
    [b,a] = butter(order, range(2)/ny, 'low');
elseif cfg.range(2) == 0
    %high pass filter
    [b,a] = butter(order, range(1)/ny, 'high');
else
    if cfg.invert == 0
        %bandpass
        [b,a] = butter(order, range./ny,'bandpass');
    else
        %notch
        [b,a] = butter(order, range./ny,'stop');
    end
end

gpu_bool = 0;
if isfield(cfg,'gpu')
    if cfg.gpu
        gpu_bool = 1;
    end
end

if gpu_bool
    Tr.data = gpuArray(single(Tr.data));
end

Tr.data = permute(Tr.data, [2 1 3]); 
[T,n,d] = size(Tr.data);

n_pad = 100;
Tr.data = cat(1,Tr.data,zeros(n_pad,n,d)); %pad
Tr.data = reshape(Tr.data,(T+n_pad)*n,d); %reshape to samples x channels

%filter forward and back 
Tr.data = filter(b,a,Tr.data); %samples by channels for efficient computation
Tr.data = flipud(Tr.data);
Tr.data = filter(b,a,Tr.data);
Tr.data = flipud(Tr.data);
Tr.data = reshape(Tr.data,(T+n_pad),n,d); %samples x trials x channels
Tr.data = Tr.data(1:T,:,:); %get rid of extra zeros
Tr.data = permute(Tr.data, [2 1 3]); %trials x samples x channels

if gpu_bool
    Tr.data = double(gather(Tr.data));
end

end