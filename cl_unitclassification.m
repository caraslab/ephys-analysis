function cl_unitclassification(datadirectory,figdirectory)
%cl_unitclassification(datadirectory,figdirectory)
%
%This function does two things:
%
%First, it classifies single units as putative regular spiking (RS) and
%putative fast spiking (FS) neurons based on the peak to peak duration of
%the unit waveform.
%
%Second, it plots a histogram of the peak-to-peak waveform duration for
%all single units, across all days. This distribution should be examined 
%before accepting any classification. If there is a bi-modal distribution, 
%these claims can be made with slightly greater confidence. If there is a 
%single distribution, it is not advised to trust the classification
%
%Input variables:
%
%   datadirectory:  String indicating the full path to the data directory
%
%   figdirectory:   String indicating the full path to the folder where you
%                   want to store the figures that are generated
%   
%
%Written by ML Caras March 2021

durs = [];

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
        
        %For each unit...
        for k = 1:numel(S(j).units)
            
            %If it's a single unit..
            if strcmpi(S(j).units(k).cluster_quality,'good')
                
                
                %Pull out the peak to peak duraton
                ptpdur = S(j).units(k).ptp_duration_ms ;
                
                %Classify the neurons
                if ptpdur > 0.4
                    S(j).units(k).classification = 'RS';
                elseif ptpdur < 0.4
                    S(j).units(k).classification = 'FS';
                end
                
                %Save the duration
                durs = [durs;ptpdur]; %#ok<AGROW>
                
            end
            
        end
    end
    
    %Save the classifications
    save(tempfile,'S')
    
    
end

%Plot the distribution and format the plot
f = figure;
set(gcf,'color','w')
h = histogram(durs,'Normalization','probability','binwidth',0.1);
hx = xlabel('Peak to peak duration (ms)');
set(hx,'Interpreter','none'); %ensure underscores are displayed properly
ylabel('Probability')
set(gca,'box','off')
set(gca,'tickdir','out')
set(h,'FaceColor',[0.5 0.5 0.5])



%Save the figure as an eps file
set(figure(f),'PaperPositionMode','auto');
fname = 'PTP_Duration_Distribution';
print(figure(f),'-painters','-depsc', [figdirectory,fname])


close all


end