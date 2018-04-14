%function mua_pipe(file,subject,type)
%function mua_pipe()

%User Input
file = 'anesth_surface_depth_501';
subject = 'b1107';
type = [];

%parameters
svbool = 0; %save spike and epoch data
chan_num = 64; %neural channel number
audio_ch = 65; %audio channel

cc_thres = 0.01;
filter_range = [0 2000];
man_bool = 0; %manual inspection of channels
n_batch = 12; %number of batches

rootpath = '/net/expData/birdSong/ss_data/';
subjectpath = [rootpath subject];
filepath = [subjectpath '/' file '/'];

cfg = [];
cfg.kwd_file = [filepath 'experiment.hfp.kwd'];
cfg.path_name = ['../data/bird/' subject '/' file '/' ]; %path to save results
cfg.exp_name = [subject '_' file];
cfg.ays_name = [cfg.exp_name '_all'];
cfg.filepath = filepath;

%song info
kwefile = [filepath 'experiment.sng.kwe'];
stim = get_stim_info(kwefile);
tmp = zeros(numel(stim.typename),1);

% stim.type = stim.type(1:2); to shorten testing
% stim.atime = stim.atime(1:2);

for i=1:numel(stim.typename)
    audiofile = [rootpath(1:end-8) 'stim_data/' subject '/001/' stim.typename{i} '.wav'];
    [signal,audio_fs] = audioread(audiofile);

    tmp(i) = ceil(numel(signal)/audio_fs);
end
song_len = max(tmp); %find maximum song length of all audio files played

%load map
%map = csvread([filepath 'electrode_map.csv']);

%% only keep bos
Trs = cell(n_batch,1);
for z=1:n_batch
    
    
    if ~isempty(type)
        s = type;
        stim.typename = stim.typename(s);
        idx = stim.type == s;
        stim.type = stim.type(idx);
        stim.atime = stim.atime(idx);
    end %else do all types
    
    n = numel(stim.type);
    a = (z-1)*round(n/n_batch)+1;    
    b = a + round(n/n_batch);
    if b > n
        b = n;
    end
        
    stim1 = stim;
    stim1.type = stim.type(a:b);
    stim1.atime = stim1.atime(a:b);  
    
    %% load data
    
    ecfg = [];
    ecfg.range = [-1 song_len];
    ecfg.rhd_convert = 1;
    Trm = epoch_kwd(cfg.kwd_file, stim1, ecfg);
    sig = Trm.data(:,:,audio_ch); %audio signal        
    
    %% shuffle trials
    
    if 1
    n = numel(Trm.type);
    idx = randperm(n);
    Trm.data = Trm.data(idx,:,:);
    Trm.type = Trm.type(idx);
    end
        
    %% remove artifact             
      
    %inspect potential audio crosstalk via cross correlation
    if z == 1  %only assess for the first batch!
        %remove artifact
        rcfg.n = 2; rcfg.audio_ch = audio_ch;
        %[Trm,An,W] = remove_artifact(Trm,rcfg); %ica
        %rcfg.n = 4; rcfg.audio_ch = audio_ch; 
        %[Trm,H] = remove_artifact3(Trm,[],rcfg); %weiner filter
        %ccfg = []; ccfg.skp_cnt = 4; ccfg.thres = cc_thres; 
        %good_chans = reject_channels2(Trm, sig, ccfg); %assess good vs bad channels in first batch only                        
        %input('Type anything, then press enter to continue: ')
    else        
        %compute cleaned data
        for i=1:size(Trm.data,1)
            tmp_data = squeeze(Trm.data(i,:,:))';
            Trm.data(i,:,:) = (An*W*tmp_data)';
        end        
    end   
    
    %% low pass filter
    
    if 0 %just loading hfp data
    ecfg = [];
    ecfg.range = filter_range;
    ecfg.invert = 0;
    Trm = epoch_filt(Trm,ecfg);    
    end
    
    %% channel select
    
    if z == 1 %% assume that subsequent batches have the same set of good channels
        ccfg = []; ccfg.skp_cnt = 4; ccfg.thres = cc_thres; 
        good_chans = reject_channels2(Trm, sig, ccfg); %assess good vs bad channels in first batch only                              
        return
        if ~isequal(good_chans, Trm.idx)
            disp('warning: some channels thrown away b/c of artifact rejection')
            bad_chans = ~ismember(Trm.idx,good_chans);
            Trm.idx(bad_chans)
        end
    end
    
    chs = Trm.idx(1:chan_num); %neural channels
    mask = ismember(chs, good_chans);
    ccfg = []; ccfg.chs = chs(mask);
    Trm = epoch_chs(Trm,ccfg);     
    
    %% downsample
    
    dcfg = []; dcfg.ds = 2;
    Trm = epoch_ds(Trm,dcfg);
    
    %% square signal
    
    Trm.data = Trm.data.^2;
    
    %% smooth
    
    cfg.range = [0 90];
    Trm = epoch_filt(Trm,cfg);
    
    %% downsample
    
    fs_ds = 1000;
    if rem(Trm.fs,fs_ds)
        disp('error: downsample factor not an integer.. ending program');
        return
    else
        ds = Trm.fs/fs_ds; %to match spike rate
    end
    
    dcfg = []; dcfg.ds = ds;
    Trm = epoch_ds(Trm,dcfg);
    
    %% square-root
    
    Trm.data = sqrt(abs(Trm.data));
    
    %% combine Tr
    
    Trs{z} = Trm;
    clearvars Tr;
    
end

%combine batches into on epoch struct
n = numel(stim.type);
Tr1 = Trs{1};
[~,T,d] = size(Tr1.data);
Trm.data = zeros(n,T,d);
Trm.time = Tr1.time;
Trm.atime = stim.atime;
Trm.fs = Tr1.fs;
Trm.idx = Tr1.idx;
Trm.type = zeros(n,1);
Trm.typename = Tr1.typename;

for z=1:n_batch
    n = numel(stim.type);
    a = (z-1)*round(n/n_batch)+1;
    b = a + round(n/n_batch);    
    if b > n
        b = n;
    end
    Trx = Trs{z};
    Trm.data(a:b,:,:) = Trx.data;
    Trm.type(a:b,1) = Trx.type;
end

%% channel select

if man_bool
    Trm = man_chan_select(Trm, []);
end

%% add audio signal to epoch struct 

audiopath = [rootpath(1:end-8) 'stim_data/' subject '/001/'];
Trm = add_audio_signal(Trm, audiopath);

%% save

if svbool
    savefile = [cfg.path_name cfg.ays_name '_mua_epoch'];
    if ~exist(cfg.path_name, 'dir'); mkdir(cfg.path_name); end
    %save(savefile,'Trm','map','-v7.3');
    save(savefile,'Trm','-v7.3');
end
