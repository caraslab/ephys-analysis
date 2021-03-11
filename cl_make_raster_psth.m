function cl_make_raster_psth(datadirectory,figdirectory, binsize, varargin)
%cl_make_raster_psth(datadirectory,figdirectory, binsize,varargin)
%
%This function generates raster and psth plots for individual units.
%Raster and psth panels are arranged such that each row is a single AM
%depth, and each column is a session type (pre passive, active, or post
%passive). Two files are saved in eps form for each unit-- one containing
%the rasters, another containing the psths.
%
%Input Variables:
%   datadirectory:  String path to a directory that contains data files for
%                   each subject
%
%
%   figdirectory:   String path to a directory where figures should be
%                   saved.
%
%
%
%
%   binsize:        Scalar value indicating bin size (in seconds) that
%                   should be used for PSTH generation
%
%   varargin{1}:    If desired, user can set the y axis limit for the
%                   raster plots, to standardize across plots, and increase
%                   the ease of viewing. If no input is detected, then the
%                   axes will not be scaled to the same number of trials.
%
% Example usage:
% cl_make_raster_psth('/Users/Desktop/Subjects','/Users/Desktop/Figures/',0.01,20)
%
% Written by ML Caras Feb 2021


%Get a list of all the files in the directory
allfiles = findallfiles(datadirectory);

%Find the real files (the *.mat files)
[~,idx] = findmyfile(allfiles,'.mat');

%For each file (subject)
for i = 1:numel(idx)
    
    clear tempfile S
    
    %Load the data
    tempfile = fullfile(allfiles(idx(i)).folder,allfiles(idx(i)).name);
    load(tempfile,'S');
    
    
    %For each session (date)...
    for j = 1:numel(S)
        
        
        %Let's get a list of all the AM depths presented in this session
        behavstates = fields(S(j).trialinfo);
        alldepths = [];
        
        for jj = 1:numel(behavstates)
            alldepths = [alldepths;[S(j).trialinfo.(behavstates{jj})(:).amdepth]']; %#ok<AGROW>
        end
        
        alldepths = unique(alldepths);
        
        %Now, let's determine which AM depths were presented in ANY
        %session. This will determine the number of rows of subplots.
        inds = zeros(numel(alldepths),3);
        inds(1,:) = 1:3;
        for kk = 2:size(inds,1)
            inds(kk,:) = inds(kk-1,3)+[1:3];
        end
        
        
        
        %Now, let's go through each unit, pull out the spike times, align
        %them to trial onset, and plot the rasters and psths
        for k = 1:numel(S(j).units)
            
            
            %Initialize figure windows and handles for subplots
            f(1) = myplot;
            f(2) = myplot;
            handles.rast = [];
            handles.psth = [];
            
            
            %Now, let's plot the data.
            
            %PRE PASSIVE
            if isfield(S(j).trialinfo,'pre')
                handles = plotrasterpsth('pre',S(j),k,alldepths,f,inds,1,handles,binsize);
            end
            
            %ACTIVE
            if isfield(S(j).trialinfo,'active')
                 handles = plotrasterpsth('active',S(j),k,alldepths,f,inds,2,handles,binsize);
            end
            
            %POST PASSIVE
            if isfield(S(j).trialinfo,'post')
                handles = plotrasterpsth('post',S(j),k,alldepths,f,inds,3,handles,binsize);
            end
           
          
            
            %Format the subplots
            linkaxes(handles.rast)
            linkaxes(handles.psth)
            
            %Standardize and limit the number of trials shown, if chosen by
            %user.
            if nargin>3
                set(handles.rast,'ylim',[0 varargin{1}])
            end
            
            
            
            %If the figure directory doesn't exist, make it now
            if ~isfolder(figdirectory)
                mkdir(figdirectory);
            end
            
            %For each figure
            for m = 1:numel(f)
                
                %Add figure titles with the subject, date, and unit ID
                subjname = S(j).metadata.(behavstates{1}).name;
                sessdate = S(j).metadata.(behavstates{1}).date;
                unitID = ['Cluster ',num2str(S(j).units(k).cluster)];
                figurename = [subjname, '_', sessdate, '_', unitID];
                
                figure(f(m));
                ftitle = suptitle(figurename);
                set(ftitle,'Interpreter','none'); %ensure underscores are displayed properly
                
                %Make the text extension for saving
                switch m
                    case 1
                        figtext = '_raster';
                    case 2
                        figtext = '_psth';
                end
                
                %Save the figure as an eps file
                set(figure(f(m)),'PaperPositionMode','auto');
                fname = [figurename,figtext];
                print(figure(f(m)),'-painters','-depsc', [figdirectory,fname])
                
                
            end
            
            %Close the figures
            close(f);
            
        end
        
    end
    
end



end




%FUNCTION: PLOT RASTER/PSTH
function handles = plotrasterpsth(bstate,S,unitID,alldepths,f,inds,col,handles,binsize)
%This function plots the rasters and psths for a given unit. Input
%variables are as follows:
%
%   bstate:     String indicating the behavioral state of the data. Acceptable
%               inputs include 'pre', 'active', or 'post'
%
%   S:          Structure containing data for a single session (date).
%
%   unitID:     Scalar value indicating the index of the unit you want to plot.
%
%   alldepths:  Vector containing a list of all AM depths presented across
%               all behavioral states for that session (date).
%
%   f:          Handle to initialized figure window
%
%   inds:       Matrix containing the index values used for arranging
%               subplots
%
%   col:        Scalar value indicating which subplot column should be
%               targeted
%
%   handles:    Vector containing handles to the rasters and psths (empty
%               upon input)
%
%   binsize:    Size of bins (in seconds) used for PSTHs



%Pull out the trial onset timestamps (in seconds)
onsets = [S.trialinfo.(bstate)(:).trial_onset]';

%Pull out the AM depths for each trial
depths = [S.trialinfo.(bstate)(:).amdepth]';

%Pull out the stimulus durations for each trial
durations = [S.trialinfo.(bstate)(:).stim_duration]';
durations = durations/1000; %convert from msec to sec

%Pull out the spike times (in seconds)
spks = S.units(unitID).spiketimes.(bstate);

%For each AM depth...
for m = 1:numel(alldepths)
    
    %Pull out the trial onsets for the current depth...
    trials = onsets(depths == alldepths(m));
    
    
    %If the current depth was not presented during this
    %session, abort, and skip to the next depth
    if isempty(trials)
        continue
    end
    
    ntrials = numel(trials);
    
    
    %Find the stimulus duration for each trial
    trialdur = durations(depths == alldepths(m));
    
    
    %Initialize raster figure and subplot
    figure(f(1));
    subind = inds(m,col);
    srast = subplot(numel(alldepths),3,subind);
    
    %Save subplot handles for later formatting
    handles.rast = [handles.rast;srast];
    
    %Initialize an empty vector for spike times aligned to trial onset
    spkaligned = [];
    
    %Now, for each trial of this AM depth...
    for n = 1:ntrials
        
        %Define the trial start time (in seconds)
        trialstart = trials(n);
        
        %Define the trial end time (in seconds)
        trialend = trialstart+trialdur(n);
        
        %Pull out the spike times for the trial, align the spike times
        %to trial onset, and save them for generating a PSTH
        currspks = spks(spks>=trialstart & spks <=trialend);
        currspks = currspks - trialstart;
        spkaligned = [spkaligned;currspks]; %#ok<AGROW>
        
        
        %Make a vector of matching length for the y value
        y = zeros(length(currspks),1);
        y = y+n;
        
        %Plot the data as a raster
        plot(currspks,y,'k.')
        hold on
        
    end
    
    %Format the raster plot
    formatplot(srast,'Time (sec)','Trial',col,alldepths(m));
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Now make the PSTH
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %First, create windows for PSTH
    windowTimes = 0:binsize:1; %all times in seconds
    centered_bins = windowTimes(1:end-1)+(diff(windowTimes))/2;%for plotting
    
    %Set up PSTH binning
    psthY = [];
    for k = 2:length(windowTimes)
        window = [windowTimes(k)-binsize, windowTimes(k)];
        spikeTimesinBin = find(spkaligned<window(2) & spkaligned>window(1));
        nspikesPerBin = length(spikeTimesinBin);
        [psthY] = [psthY, (nspikesPerBin/(ntrials*binsize))];%Spikes/second
        
    end
    
    %Plot PSTH and save axes handles
    figure(f(2));
    spsth = subplot(numel(alldepths),3,subind);
    bar(centered_bins,psthY,1,'k','EdgeColor','k');
    hold on
    handles.psth = [handles.psth;spsth];
    
    %Format the PSTH
    formatplot(spsth,'Time (sec)','FR (Hz)',col,alldepths(m))
end


end


%FUNCTION: FORMAT PLOT
function formatplot(ax,xtitle,ytitle,col,depth)

subplot(ax)
xlabel(xtitle)
ylabel (ytitle)

if col == 1
    sess = 'Pre Passive';
elseif col == 2
    sess = 'Active';
elseif col == 3
    sess = 'Post Passive';
end

title([num2str(depth*100),'% AM Depth ', sess])
set(ax,'box','off');
set(ax,'TickDir','out')

end

