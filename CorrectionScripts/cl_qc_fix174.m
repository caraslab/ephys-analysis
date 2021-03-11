%cl_qc_fix174.m
%
%This script corrects a problem with the data collected from subject 174.
%It appears that the signal drops out during the pre-passive session on Nov
%16, 2020, right around the 80th trial of the 0% AM stimulus. So, just to
%be safe, let's drop all trials after the 75th trial of the 0% AM stimulus.
%
%After removing the problematic trials, a new field ("correction") will be
%added to the metadata for the problematic session. The correction filed
%will have a flag (in case we need to find sessions hat were manually
%curated in the future) and will have notes about the correction applied.
%
%Note that this is obviously hard coded, and specific for this particular
%situation. Issues in other animals should be handled on a case by case
%basis, and the script names should start with cl_qc_fix and then the
%subject ID number. (cl = caras lab, qc = quality control).
%
%Written by ML Caras Mar 2021


%Problem file:
filename = '/Users/Melissa/Desktop/Processed/SUBJ-ID-174.mat';
load(filename,'S');

%First check: has this file already been corrected? (We don't want to
%accidentally run this script multiple times on the same file, as it'll
%remove good trials). Abort if the issue has already been corrected.
if isfield(S(1).metadata.pre,'correction')
    if S(1).metadata.pre.correction.flag == 1
        return
    end
end



%Pull out the trials for the problematic session
trials = [S(1).trialinfo.pre(:).amdepth]';

%Find the indices for the 0% AM depth stimulus
nogos = find(trials == 0);

%Find the 75th index
lasttrial = nogos(75);

%Remove all trials that occur after the 75th nogo trial.
S(1).trialinfo.pre = S(1).trialinfo.pre(1:lasttrial);

%What's the timestamp of the end of the 75th trial?
lasttime = S(1).trialinfo.pre(end).trial_offset;

%For each unit, remove the extra spike times 
for i = 1:numel(S(1).units)
    spks = S(1).units(i).spiketimes.pre;
    spks = spks(spks<lasttime);
    
    S(1).units(i).spiketimes.pre = spks;
    
end

%Add a field to the metadata structure indicating that the data has been
%manually curated
S(1).metadata.pre.correction.flag = 1;
S(1).metadata.pre.correction.notes = 'All trials after the 75th nogo trial (the 19th go trial) in this session have been manually removed because of a signal disruption and loss -ML Caras Mar 2, 2021';

%Save the data
save(filename,'S')