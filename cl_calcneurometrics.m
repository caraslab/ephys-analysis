function cl_calcneurometrics(datadirectory)
%cl_calcneurometrics(datadirectory)
%
%This function calculates basic neurometrics for each unit, for every file
%in a data directory. Each file should contain the data from a single
%session (date) for a single animal, across all behavioral states (pre,
%active, and post). The function will save the data structure S, which will
%now have some new fields:
%
%S(i).units(j).FRs:         A vector containing the firing rates (sp/s) 
%                           for each trial
%
%S(i).units(j).Powers:      A vector containing the power at the stimulus 
%                           modulation frequency for each trial
%
%S(i).units(j).metrics:     Data for each behavioral state (pre, active,
%                           post). Average/STDEV FRs, Average/STDEV Powers,
%                           and associated d' values for each AM depth.
%
%Written by ML Caras March 2021

FFTfs = 500; %samples for FFT analysis

%Initialize waitbar
H = waitbar(0);
H.Children.Title.Interpreter = 'none';
H.WindowStyle = 'modal';

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
        
       
        %Determine which type of behavioral state data was collected on
        %that day (pre, active, and/or post)
        bstates = fields(S(j).trialinfo);
        
        %For each state...
        for k = 1:numel(bstates)
            
         %Update waitbar
         wbmsg = {['Processing ',S(j).metadata.(bstates{k}).name],[S(j).metadata.(bstates{k}).date],bstates{k}};
         waitbar(j/numel(S),H,wbmsg) 
        
            
            %Pull out the trial onset timestamps (in seconds)
            onsets = [S(j).trialinfo.(bstates{k})(:).trial_onset]';
            
            %Pull out the AM depths for each trial
            depths = [S(j).trialinfo.(bstates{k})(:).amdepth]';
            
            %Convert the depths to dB re: 100% and round to the nearest
            %integer to avoid future errors with equality testing
            depths = make_stim_log(depths);
            depths = round(depths);
            
            %Pull out the stimulus durations for each trial
            durations = [S(j).trialinfo.(bstates{k})(:).stim_duration]';
            durations = durations/1000; %convert from msec to sec
            
            %Pull out the AM rate for each trial
            rates = [S(j).trialinfo.(bstates{k})(:).amrate]';
            if numel(unique(rates))>1
                warning('Different AM rates were presented on each trial. Power will not be calculated.')
                warn = 1;
                
            else
                MF = unique(rates);
                warn = 0;
            end
            
            %For each unit...
            for m = 1:numel(S(j).units)
                
                %Initialize a firing rate vector
                S(j).units(m).FRs.(bstates{k}) = [];
                
                %Pull out the spike times for this behavioral state
                spks = S(j).units(m).spiketimes.(bstates{k});
                
                %Initialize a vector for power calculation
                S(j).units(m).Powers.(bstates{k}) = zeros(numel(onsets),1);
                
                %For each trial...
                for n = 1:numel(onsets)
                    
                    %Define the trial start time (in seconds)
                    trialstart = onsets(n);
                    
                    %Define the trial end time (in seconds)
                    trialend = trialstart+durations(n);
                    
                    %Pull out the spike times for the trial
                    currspks = spks(spks>=trialstart & spks <=trialend);
                    
                    %Calculate the firing rate for this trial and save
                    FR = numel(currspks)/durations(n); %spikes/sec
                    S(j).units(m).FRs.(bstates{k}) = [S(j).units(m).FRs.(bstates{k});FR];
                    
                    %Now let's calculate the power at the modulation
                    %frequency for this trial and add it to our power
                    %vector. (If there were no spikes for the trial, we
                    %can't calculate the power, and the value in the power
                    %vector for this trial remains as zero). Also, only
                    %calculate power if the same AM rate was presented on
                    %each trial.
                    if warn == 0
                        if ~isempty(currspks)
                            spksaligned = currspks - trialstart;
                            S(j).units(m).Powers.(bstates{k})(n) = cl_calcpower(FFTfs,durations(n),spksaligned,MF);
                        end
                    end
                end
                
                
                
                %Now that we have the FR on a trial-by-trial basis for this
                %unit, let's calculate the average and stdev FR for each AM
                %depth
                [meanFR,stdFR,grps] = grpstats(S(j).units(m).FRs.(bstates{k}),depths,{'mean','std','gname'});
                S(j).units(m).metrics.(bstates{k}).FRmat = [cellfun(@str2num,grps),meanFR,stdFR]; 
                S(j).units(m).metrics.(bstates{k}).FRheaders = {'AM depth (dB re: 100%)','meanFR (sp/s)','stdFR (sp/s)'};
                 
                %And let's calculate FR-based d'
                S(j).units(m).metrics.(bstates{k}).FRdprimemat = cl_calcdprime(S(j).units(m).metrics.(bstates{k}).FRmat);
                S(j).units(m).metrics.(bstates{k}).FRdprimeheaders = {'AM depth (dB re: 100%)','FRdprime'};
                
                %If we're calculating power...
                if warn == 0
                    %Now that we have the power on a trial-by-trial basis
                    %for this unit, let's calculate the average and stdev power
                    %for each AM depth
                    [meanPower,stdPower,grps] = grpstats(S(j).units(m).Powers.(bstates{k}),depths,{'mean','std','gname'});
                    S(j).units(m).metrics.(bstates{k}).Powermat = [cellfun(@str2num,grps),meanPower,stdPower]; 
                    S(j).units(m).metrics.(bstates{k}).Powerheaders = {'AM depth (dB re: 100%)','meanPower (sp/sec^2/Hz)','stdPower (sp/sec^2/Hz)'};
                    
                    %And let's calculate power-based d'
                    S(j).units(m).metrics.(bstates{k}).Powerdprimemat = cl_calcdprime(S(j).units(m).metrics.(bstates{k}).Powermat);
                    S(j).units(m).metrics.(bstates{k}).Powerdprimeheaders = {'AM depth (dB re: 100%)','Powerdprime'};
                    
                end
            end
        end
    end
    
    %Save the data to the file
    save(tempfile,'S')
    
  
end


%Close waitbar
close(H)


end