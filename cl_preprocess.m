function cl_preprocess(datadirectory,savedirectory)
%cl_preprocess(datadirectory,savedirectory)
%
%This function takes csv and txt files that are output by the spike sorting
%pipeline and prepares the data for MATLAB-based analyses. Data from each
%subject is stored as a single 1xM output structure (S), with M 
%corresponding to the recording date. 
%
%S contains the following fields:
%   ops:            structure containing parameters used for sorting, as
%                   well as recording sampling rate
%
%   trialinfo:      structure conaining one field for each recording type
%                   (pre, active, post), each of which is a strutcure 
%                   consisting of stimulus parameters, timestamps, and
%                   behavioral responses for each trial
%
%   metadata:       structure containing basic information about the data
%                   from each date (i.e. the date, recording depth, etc.)
%
%   breakpoints:    structure containing the "breakpoints" between pre,
%                   active and post sessions. Each value is the timestamp
%                   (in seconds) at which the session type ended.
%
%   units:          structure containing the cluster ID, best channel, 
%                   shank, recording quality metrics, unit deisgnation 
%                   ('good' = single or 'mua' = multi), and the spiketimes
%                   for that unit (in seconds, aligned to session (pre,
%                   active, post) onset.
%   
%This function is designed for batch processing. Therefore, the data should
%be organized as described below.
%
%Input Variables:
%   datadirectory:  String path to a directory that contains subfolders
%                   organized by subject (e.g. SUBJ-ID-174)
%                   
%                   Each subject's subfolder should contain additional 
%                   subfolders arranged by date (e.g. 201116_concat). These
%                   subfolders should contain data collected on single date,
%                   concatenated across session type (pre, active, post).
%                   The data should come directly out of the caras lab
%                   spike sorting pipeline, and should require no user 
%                   intervention before passing it into this function. At a
%                   minimum, the subfolder should include the following 
%                   files:
%
%                       *.txt files, each of which contains the spike times 
%                       (in sec) for one sorted (single or multi) unit, 
%                       arranged as a Nx1 vector.
%
%                       A [*]_breakpoints.csv file that indicates the sample 
%                       number at which each type of recording session 
%                       (passive pre, active, passive post) ended. 
%                       These "breakpoints" should be used to realign the
%                       spike times for each session type.
%
%                       A [*]_trialinfo.csv file for each session type from
%                       that date (pre, active, post). This file is
%                       arranged such that each row is a single trial, and
%                       each column contains the value of a specific
%                       parameter on that trial. Behavioral responses,
%                       trial timestamps, and stimulus parameters are
%                       included (and the important items of interest)
%                       here.
%
%                       A [*]_ePsychMetadata.mat file for each session type
%                       from that date (pre, active, post). This file
%                       contains a structure called Info, which has all of
%                       the metadata associated with that recording session
%                       (Subject ID, Sex, Condition, Age, Recording Depth,
%                       etc...)
%
%                       A [*]_concat_quality_metrics.csv file, arranged 
%                       such that each row is a unit, and each column is a 
%                       quality control metric (used for determining whether
%                       a unit is a single unit or multi unit)
%
%                       A [*]_waveform_measurements.csv file, arranged such
%                       that each row is a unit, and each column is a
%                       specific waveform measurement.
%
%                       A config.mat file that contains the parameters used
%                       for recording and spike sorting. Of interest here
%                       is the sampling rate of the recording (in
%                       samples/sec).
%
%                       
%                       
%
%   savedirectory:   String path to a directory where matlab files should be
%                    saved.
%
% Example usage:
% cl_preprocess('/Users/Desktop/Subjects','/Users/Desktop/MAT/')
%
% Written by ML Caras Feb 2021

%Initialize waitbar
H = waitbar(0);
H.Children.Title.Interpreter = 'none';
H.WindowStyle = 'modal';

%Get a list of all the subfolders in the PARENT directory. 
%Each subfolder should contain data for a single subject
[subjects,subjectIndex]= findRealDirs(datadirectory);

%For each subject...
for i = 1:numel(subjectIndex)
    
    %Start fresh
    clear S
     
    %Initialize a data structure that ultimately will contain all the
    %data and parameters for a single subject.
    S = struct([]);
    
    %Define the path to the SUBJECT directory
    subjdir = fullfile(datadirectory,subjects(subjectIndex(i)).name);
    
    %Get a list of all the subfolders in the SUBJECT directory. 
    %Each subfolder should contain data for a single date. 
    [sessions,sessionIndex]= findRealDirs(subjdir);
     
     
    %For each session (date)...
    for j = 1:numel(sessionIndex)
        
        %Start fresh
        clear allfiles
        
        %Define the path to the current SESSION directory
        sessiondir = fullfile(subjdir,sessions(sessionIndex(j)).name);
        
         %Update waitbar
         wbmsg = {['Processing ',subjects(subjectIndex(i)).name,'...'], sessions(sessionIndex(j)).name};
         waitbar(j/numel(sessionIndex),H,wbmsg) 
        
        %Recursively list all files in the directory
        allfiles = findallfiles(sessiondir);
        
        %Find and load the config file, and append the ops field to our 
        %data structure. This field contains all of the parameters used for
        %spike sorting, as well as the sampling rate of the recording.
        configfile = findmyfile(allfiles,'config.mat');
        config = load(configfile); 
        S(j).ops = config.ops;
        
        %Now, let's load in the trial info files. Each of these csv files 
        %are arranged such that each row is a trial, and each column is a 
        %specific parameter or value recorded for that trial. Trial onset 
        %and offset timestamps, behavioral responses, and stimulus 
        %parameters are included in each file. There is one csv file for
        %each session type (passive pre, active or passive post).After
        %loading, append to our data structure
        S(j).trialinfo = loadandsave(allfiles,'trialinfo.csv');

        
        %Now we'll load the session metadata (date, subject ID, sex,
        %condition, etc)
        S(j).metadata = loadandsave(allfiles,'ePsychMetadata.mat');
        
        
        %Now, let's load in the file that contains the session "breakpoints"
        %(i.e. the last sample of the pre passive session, active session,
        %etc). The file should be formatted such that the session type is 
        %listed in the first column, and the break point is listed in the 
        %second column. 
        breakpointfile = findmyfile(allfiles,'breakpoints.csv');
        breakpoints = importdata(breakpointfile); %import data from csv
        breakpoints.textdata(1,:) = []; %remove the headerline
        breakpoints.textdata(:,2) = []; %remove the extra column
        
        %Determine when the different sessions ended (in seconds) and save
        %to our data structure
        S(j).breakpoints.pre = find_endpoint(breakpoints,'pre',S(j).ops.fs);
        S(j).breakpoints.active = find_endpoint(breakpoints,'aversive',S(j).ops.fs);
        
        
        %Now, let's load in our list of units, their associated quality
        %metrics, and their waveform measurements.
        qualityfile = findmyfile(allfiles,'quality_metrics.csv');
        measurementfile = findmyfile(allfiles,'waveform_measurements.csv');
        Q = readcell(qualityfile);
        M = readcell(measurementfile);
        
        %These two files contain some of the same data. Let's first
        %determine which columns should be identical
        Qheaders = Q(1,:);
        Mheaders = M(1,:);
        identical = ismember(Qheaders,Mheaders);
        
        %One of these identical columns should be the one with the cluster
        %ID. If so...
        if any(endsWith(Qheaders(identical),'cluster','IgnoreCase',true))
            
            %Find the cluster ID column and pull out the list of clusters
            cluscol = endsWith(Qheaders(identical),'cluster','IgnoreCase',true);
            Qclusters = cell2mat(Q(2:end,cluscol));
            Mclusters = cell2mat(M(2:end,cluscol));
            
            %If they are identical...
            if isequal(Qclusters,Mclusters)
                
                %Merge the arrays together
                unitstats = [Q,M(:,~identical)];
            
            %If the clusters are not identical, throw an error...
            else
                emssage = ['ERROR: Data listed in quality_metrics.csv and waveform_measurements.csv may not be from the same units! Check ',sessiondir];
                error(emssage)
            end
            
        else
            emssage = ['ERROR: Cannot find cluster IDs! Check ',sessiondir];
            error(emssage)
            
        end
        
        
        %Convert this cell array into a structure, such that the header
        %rows become field names (and keep them all lowercase).
        S(j).units = cell2struct(unitstats(2:end,:),lower(unitstats(1,:)),2);
        

        %Now we need to get the spike times for each unit. First, we need 
        %to get a list of all of the text files in the subfolder. Each text
        %file contains the spike times for one single or multi unit, 
        %arranged as an Nx1 vector. Spike times are in seconds. 
        [~,fidx] = findmyfile(allfiles,'txt');
        
        %For each file (unit)...
        for k = 1:numel(fidx)
            
            %Start fresh 
            clear spiketimes cluster cidx
            
            %Define the path to the file with the spike times for this unit
            filename = fullfile(allfiles(fidx(k)).folder,allfiles(fidx(k)).name);
            
            %Let's find the structure index for this unit
            clusterSTART = strfind(filename,'cluster')+numel('cluster');
            cluster = str2double(filename(clusterSTART:end-4));
            cidx = find([S(j).units(:).cluster] == cluster);
            
            
            %Load in the spike times (in seconds) for this unit
            spiketimes = dlmread(filename);
            
            
            %Let's break the spiketimes apart by session. Then, we'll 
            %realign the spiketimes so that each session starts at
            %time zero. This will ensure that the spiketimes match up with 
            %the behavioral timestamps. We don't need to realign the pre
            %passive data, because the spike times are already aligned to
            %time zero. So we just need to realign the active and post 
            %passive data. 
            if isfield(S(j).trialinfo,'pre')
                S(j).units(cidx).spiketimes.pre  = spiketimes(spiketimes <= S(j).breakpoints.pre);
            end
            
             if isfield(S(j).trialinfo,'active')
                S(j).units(cidx).spiketimes.active = spiketimes(spiketimes >S(j).breakpoints.pre & spiketimes <= S(j).breakpoints.active);
                S(j).units(cidx).spiketimes.active = S(j).units(cidx).spiketimes.active - S(j).breakpoints.pre; %realign
            end
            
            if isfield(S(j).trialinfo,'post')
                S(j).units(cidx).spiketimes.post = spiketimes(spiketimes > S(j).breakpoints.active);
                S(j).units(cidx).spiketimes.post = S(j).units(cidx).spiketimes.post - S(j).breakpoints.active; %realign
            end
            
            %Now let's use the spike quality metrics to determine whether a
            %unit should be classified as a single or multi unit. The 
            %quality metrics, their calculation, their cutoff values, and
            %their interpretation can be found on the Allen Institute SDK:
            %(https://allensdk.readthedocs.io/en/latest/_static/examples/nb/ecephys_quality_metrics.html)
            if S(j).units(cidx).isi_fprate < 0.5 &&...
                    S(j).units(cidx).fraction_missing < 0.1 &&...
                    S(j).units(cidx).presence_ratio > 0.9
                
                S(j).units(cidx).cluster_quality = 'good';
                
            else
                
                S(j).units(cidx).cluster_quality = 'mua';
                
            end
                
            
        end
        
    end
    
    %Check that the save directory exists. If it doesn't, make it now.
    if ~isfolder(savedirectory)
        mkdir(savedirectory)
    end
    
    %Save the subject's data structure to a file
    savename = fullfile(savedirectory,subjects(subjectIndex(i)).name);
    save(savename,'S')

    
end

%Close waitbar
close(H)

end





%FUNCTION: FIND SESSION ENDPOINT (SECONDS)
function endpoint = find_endpoint(data,session,fs)
    ind = contains(data.textdata,session,'IgnoreCase',true);
    endpoint = data.data(ind); %samples
    
    %Convert the endpoint into seconds
    endpoint = endpoint/fs; 
end

%FUNCTION LOAD AND SAVE DATA FROM FILE
function S = loadandsave(allfiles,targetfile)
[~,idx] = findmyfile(allfiles,targetfile);

for i = 1:numel(idx)
    tempfile = fullfile(allfiles(idx(i)).folder,allfiles(idx(i)).name);
    
    switch tempfile(end-2:end)
        case 'mat'
            T = load(tempfile);
            F = fieldnames(T.Info);
            T.Info = RenameField(T.Info,F,lower(F));
            
            if contains(tempfile,'pre','Ignorecase',true) %pre passive
                S.pre = T.Info;
            elseif contains(tempfile,'aversive','Ignorecase',true) %active
                S.active = T.Info;
            elseif contains(tempfile,'post','Ignorecase',true) %post passive
                S.post = cT.Info;
            end
            
        case 'csv'
            T = readcell(tempfile);
            if contains(tempfile,'pre','Ignorecase',true) %pre passive
                S.pre = cell2struct(T(2:end,:),lower(T(1,:)),2);
            elseif contains(tempfile,'aversive','Ignorecase',true) %active
                S.active = cell2struct(T(2:end,:),lower(T(1,:)),2);
            elseif contains(tempfile,'post','Ignorecase',true) %post passive
                S.post = cell2struct(T(2:end,:),lower(T(1,:)),2);
            end
            
    end
    
    
  
    clear tempfile T
end
end