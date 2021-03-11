function cl_calcbehavmetrics(datadirectory)
%cl_calcbehavmetrics(datadirectory)
%
%This function calculates hit rates, miss rates, and dprime values for
%each session, and appends this information to the data structure S. Each
%file in the data directory should contain the data for a single animal.
%
%Written by ML Caras March 2021


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
        
        %Start fresh
        clear data
        
        %Initialize matrix for storing hits and fas
        data.original = [];
      
        
        %We only need to calculate behavioral data for the active state
        if isfield(S(j).trialinfo,'active')
            depths = [S(j).trialinfo(:).active.amdepth]';
            reminders = [S(j).trialinfo(:).active.reminder]';
            hits = [S(j).trialinfo(:).active.hit]';
            fas = [S(j).trialinfo(:).active.fa]';
        end
        
        %Remove reminder trials
        depths = depths(reminders == 0);
        hits = hits(reminders == 0);
        fas = fas(reminders == 0);
        
        %Unique depths presented
        udepths = unique(depths);
      
        %For each depth...
        for k = 1:numel(udepths)
            
            %Calculate the number of trials presented at this depth
            ntrials = numel(depths(depths == udepths(k)));
            
            %Calculate the number of "yes" responses (i.e. the hitrate) 
            %for warn (go) trials
            if udepths(k) > 0 %depths still in percent, these are the warn stim
                nyes = sum(hits(depths == udepths(k)));
                
            %Calculate the number of "yes" responses (i.e. the false alarm
            %rate) for safe (nogo) trials    
            elseif udepths(k) == 0 %depths in percent, this is the safe stim
                nyes = sum(fas(depths == udepths(k)));
            end
            
            yesrate = nyes/ntrials; %proportion;
            data.original = [data.original;udepths(k),nyes,ntrials,yesrate];
            
        end
        
        
        %When calculating d' values, we need to adjust for perfect 
        %performance (hit rate = 1 or FA rate = 0) by
        %bounding hit/fa rates between 0.05 and 0.95. Note that other common
        %corrections (i.e. log-linear, 1/2N, etc) artificially inflate lower
        %bound when go trial numbers are small, nogo trial numbers are large,
        %hit rates are very low (sometimes for muscimol) and fa rates are very
        %low.
          
        data.adjusted = data.original;
        data.adjusted(data.adjusted(:,4) < 0.05,4) = 0.05;
        data.adjusted(data.adjusted(:,4) > 0.95,4) = 0.95; %#ok<*AGROW>
        
        
        %Adjust number of "yes" responses to match adjusted "yes rate" 
        %(So we can fit data with psignifit later, if desired)
        data.adjusted(:,2) = data.adjusted(:,3).*data.adjusted(:,4);
        
        %Sort data so safe (nogo) stimulus is on top
        data.adjusted = sortrows(data.adjusted,1);
        
        %Calculate d'
        hitrates = data.adjusted(2:end,4);
        farate = data.adjusted(1,4);

        zfa = norminv(farate);
        zhit = norminv(hitrates);

        dprime = zhit - zfa;
        
        %Append dprime to matrix
        data.adjusted(1,5) = NaN;
        data.adjusted(2:end,5) = dprime;
        
        
        %Convert stimulus values to log. Round stimulus values to avoid
        %equality errors later.
        data.original(:,1) = round(make_stim_log(data.original)); 
        data.adjusted(:,1) = round(make_stim_log(data.adjusted));

        %Record header information
        data.headers = {'AM depth (dB re: 100%)', 'n yes resps', 'n trials', 'yes rate', 'd'}; 
    
        %Save to structure
        S(j).behavior = data;
        
    end
    
   %Save the data to the file
   save(tempfile,'S')
end