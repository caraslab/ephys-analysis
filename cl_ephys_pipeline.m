%cl_ephys_pipeline.m
%
%This script is a pipeline for processing, analyzing, and plotting single
%and multi-unit physiology data collected in the Caras lab. Prior to using
%this pipieline, raw datafiles should already have been pre-processed,
%spikes extracted and sorted with kilosort, and manually curated with Phy.
%
%Copyright ML Caras. 2021.


%% 1. PRE PROCESS THE DATA
%This function takes csv and txt files that are output by the spike sorting
%pipeline and prepares the data for MATLAB-based analyses. Data from each
%subject is stored as a single 1xM output structure (S), with M 
%corresponding to the recording date. 

datadirectory = '/Users/Melissa/Desktop/Subjects/';
savedirectory = '/Users/Melissa/Desktop/Processed/';


cl_preprocess(datadirectory,savedirectory)

%% 2. PLOT RASTERS AND PSTHS
%Once the data has been pre-processed, the next step is to generate rasters
%and psth plots for each unit. Every unit should be inspected for problems
%(like the loss of signal), and if any are identified, the problems should
%be addressed before quantitative analysis.

datadirectory = '/Users/Melissa/Desktop/Processed/';
figdirectory = '/Users/Melissa/Desktop/Figures/';
binsize = 0.01; %seconds


cl_make_raster_psth(datadirectory,figdirectory,binsize)

%% 3. CHECK AND VERIFY METADATA
%Run this function to verify that the subject's metadata is correct for each session.
datadirectory = '/Users/Melissa/Desktop/Processed/';

cl_check_metadata(datadirectory);

%% 4: (IF NEEDED) FIX BAD RECORDINGS
%If any problems were identified for any units (or recording sessions as a
%whole), now's the time to fix them. Run any correction scripts needed, 
%then regenerate the rasters and psths by going back to step 2 to ensure 
%that everything looks good.
%
%If there are no problems, skip this and move on to step 5.

%Run the script to correct subject 174's data
cl_qc_fix174

%% 5. CALCULATE NEUROMETRICS (FR, POWER, d') FOR EACH UNIT

datadirectory = '/Users/Melissa/Desktop/Processed/';

cl_calcneurometrics(datadirectory)

%% 6. CALCULATE BEHAVIORAL METRICS (Hit rate, FA rate, d')

datadirectory = '/Users/Melissa/Desktop/Processed/';

cl_calcbehavmetrics(datadirectory)

%% 7. FIT NEUROMETRIC DATA

%This is where we would call a function to fit the neurometric data and
%calculate neural thresholds.

%Coming soon...

%% Unique functions
%Now that the data have been pre-processed by our standard pipeline, and
%have been checked for errors, and have been cleaned up, it's time to do
%the analyses that are specific to each user's experiment. This is where
%each individual's code will diverge, as the needs for each experiment
%differ.


%This code is for Lashaka. It plots various metrics (firing rate, power,
%firing rate-based dprime, and power-based dprime) for auditory cortical
%neurons recorded during passive sound exposure and during behavior. These
%plots are broken up by the drug that was infused between the pre passive
%and behavior session (Saline or Muscimol). 
datadirectory = '/Users/Melissa/Desktop/Processed/';
figdirectory = '/Users/Melissa/Desktop/Figures/';
whichunits = 'mua'; % 'mua' for just multi units, 'good' for just good units, 'all' for all units


lj_fig1(datadirectory,figdirectory,whichunits);



