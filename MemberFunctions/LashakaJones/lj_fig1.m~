function lj_fig1(datadirectory,figdirectory,whichunits)
%lj_fig1(datadirectory,figdirectory)
%
%This function plots various metrics (firing rate, power,
%firing rate-based dprime, and power-based dprime) for auditory cortical
%neurons recorded during passive sound exposure and during behavior. These
%plots are broken up by the drug that was infused between the pre passive
%and behavior session (Saline or Muscimol). 
%
%Input variables:
%
%   datadirectory:  String indicating the full path to the data directory
%
%   figdirectory:   String indicating the full path to the folder where you
%                   want to store the figures that are generated
%
%   whichunits:     String indicating which unit types you want included in
%                   the analysis. Acceptable options are:
%                       'good' for single units
%                       'mua' for multi-units
%                       'all' for both single and multi units
%      
%Written by ML Caras March 2021




%Get a list of all the files in the directory
allfiles = findallfiles(datadirectory);

%Find the real files (the *.mat files)
[~,idx] = findmyfile(allfiles,'.mat');

%Initialize data matrices (one for each parameter we're interested in, and
%one for each drug condition
FR.saline = [];
FR.muscimol = [];

FRdprime.saline = [];
FRdprime.muscimol = [];

Power.saline = [];
Power.muscimol = [];

Powerdprime.saline = [];
Powerdprime.muscimol = [];

NOGOFR.saline = [];
NOGOFR.muscimol = [];

NOGOPower.saline = [];
NOGOPower.muscimol = [];

%For each file (subject)
for i = 1:numel(idx)
    
    clear tempfile S
    
    %Load the data
    tempfile = fullfile(allfiles(idx(i)).folder,allfiles(idx(i)).name);
    load(tempfile,'S');
    
    %For each session (date)...
    for j = 1:numel(S)
        
        %Pull out the drug condition for the active state
        cond = lower(S(j).metadata.active.condition);%lowercase
        
        %Define the behavioral states
        bstates = fields(S(j).trialinfo);
        
        %Preallocate
        sess.FR = NaN(numel(S(j).units),3);
        sess.Power = NaN(numel(S(j).units),3);
        sess.FRd = NaN(numel(S(j).units),3);
        sess.Powerd = NaN(numel(S(j).units),3);
        sess.NOGOFR = NaN(numel(S(j).units),3);
        sess.NOGOpow = NaN(numel(S(j).units),3);
        
        %For each unit...
        for k = 1:numel(S(j).units)
            
            %Do we want to include all units in the analysis?
            if ~strcmpi(whichunits,'all')
                
                %If not, is this unit the right kind?
                if ~strcmpi(S(j).units(k).cluster_quality,whichunits)
                    
                    %If not, skip this unit and move on to the next one.
                    continue
                end
            end
            
            
            %For each behavioral state...
            for m = 1:numel(bstates)
                
                switch bstates{m}
                    case 'pre'
                        col = 1;
                        xtext{1} = 'pre';
                    case 'active'
                        col = 2;
                        xtext{2} = 'active';
                    case 'post'
                        col = 3;
                        xtext{3} = 'post';
                end
                
                
                %Pull out the firing rate, FRdprime, power, and powerdprime
                %for 100% AM depth (GO)
                target = round(make_stim_log(1));
                fr = findmyval(S(j).units(k).metrics.(bstates{m}).FRmat,target);
                pow = findmyval(S(j).units(k).metrics.(bstates{m}).Powermat,target);
                frd = findmyval(S(j).units(k).metrics.(bstates{m}).FRdprimemat,target);
                powd = findmyval(S(j).units(k).metrics.(bstates{m}).Powerdprimemat,target);
                
                
                %Pull out the firing rate and power for 0% AM depth (NOGO)
                target = round(make_stim_log(0));
                nogofr = findmyval(S(j).units(k).metrics.(bstates{m}).FRmat,target);
                nogopow = findmyval(S(j).units(k).metrics.(bstates{m}).Powermat,target);
                
                
                
                %Append data to appropriate column in matrix
                sess.FR(k,col) = fr;
                sess.FRd(k,col) = frd;
                sess.Power(k,col) = pow;
                sess.Powerd(k,col) = powd;
                sess.NOGOFR(k,col) = nogofr;
                sess.NOGOpow(k,col) = nogopow;
                
            end
            
        end
        
        %Append data to larger matrix 
        FR.(cond) = [FR.(cond);sess.FR];
        Power.(cond) = [Power.(cond);sess.Power];
        FRdprime.(cond) = [FRdprime.(cond);sess.FRd];
        Powerdprime.(cond) = [Powerdprime.(cond);sess.Powerd];
        NOGOFR.(cond) = [NOGOFR.(cond);sess.NOGOFR];
        NOGOPower.(cond) = [NOGOPower.(cond);sess.NOGOpow];
        
    end
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTTING AND STATISTICAL TESTS

%Note: This code plots pre and active and post data, but currently only
%runs a paired t-ttest for the pre v.s active comparison. When post data
%are eventually included, we'll need to revisit the stats.
%P values are not corrected for multiple comparisons.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%Now that we have our data compiled, let's plot it
myplot;
x = 1:3;
xtext = {'Pre', 'Active','Post'};

%AM noise evoked Firing rate
s1 = plotmydata(x,FR.saline,xtext,['0 dB AM-evoked' newline 'FR (sp/s)'],...
    'Saline',1);
s2 = plotmydata(x,FR.muscimol,xtext,['0 dB AM-evoked' newline 'FR (sp/s)'],...
    'Muscimol',2);

%AM noise evoked Power
s3 = plotmydata(x,Power.saline,xtext,['0 dB AM-evoked' newline 'Power (sp/sec^2/Hz)'],...
    'Saline',3);
s4 = plotmydata(x,Power.muscimol,xtext,['0 dB AM-evoked' newline 'Power (sp/sec^2/Hz)'],...
    'Muscimol',4);



%Unmodulated noise evoked Firing rate
s5 = plotmydata(x,NOGOFR.saline,xtext,['Unmod. noise' newline 'FR (sp/s)'],...
    'Saline',5);
s6 = plotmydata(x,NOGOFR.muscimol,xtext,['Unmod. noise' newline 'FR (sp/s)'],...
    'Muscimol',6);

%Unmodulated noise evoked Power
s7 = plotmydata(x,NOGOPower.saline,xtext,['Unmod. noise' newline 'Power (sp/sec^2/Hz)'],...
    'Saline',7);
s8 = plotmydata(x,NOGOPower.muscimol,xtext,['Unmod. noise' newline 'Power (sp/sec^2/Hz)'],...
    'Muscimol',8);



%Firing-rate based d'
s9 = plotmydata(x,FRdprime.saline,xtext,'FR-based d''',...
    'Saline',9);
s10 = plotmydata(x,FRdprime.muscimol,xtext,'FR-based d''',...
    'Muscimol',10);


%Power-based d'
s11 = plotmydata(x,Powerdprime.saline,xtext,'Power-based d''',...
    'Saline',11);
s12 = plotmydata(x,Powerdprime.muscimol,xtext,'Power-based d''',...
    'Muscimol',12);

%Scale axes
linkaxes([s1,s2])
linkaxes([s3,s4])
linkaxes([s5,s6])
linkaxes([s7,s8])
linkaxes([s9,s10])
linkaxes([s11,s12])

%Figure title
switch whichunits
    case 'good'
        ftitle = 'Single units';
    case 'mua'
        ftitle = 'Multi-units';
    case 'all'
        ftitle = 'Single and multi-units';
end

suptitle(ftitle);

%Run stats
mystats(FR.saline,s1)
mystats(FR.muscimol,s2)

mystats(Power.saline,s3)
mystats(Power.muscimol,s4)


mystats(NOGOFR.saline,s5)
mystats(NOGOFR.muscimol,s6)

mystats(NOGOPower.saline,s7)
mystats(NOGOPower.muscimol,s8)


mystats(FRdprime.saline,s9)
mystats(FRdprime.muscimol,s10)

mystats(Powerdprime.saline,s11)
mystats(Powerdprime.muscimol,s12)


%Save the figure as an eps file
set(gcf,'PaperPositionMode','auto');
fname = ['lj_fig1_', ftitle];
print(gcf,'-painters','-depsc', [figdirectory,fname])


close all

end



%FUNCTION: FIND MY VALUE
function val = findmyval(mat,target)

ind = (mat(:,1) == target);
val = mat(ind,2);

end


%FUNCTION PLOT MY DATA
function s = plotmydata(x,mat,xtext,ytext,titletext,sind,varargin)

%Initilize subplot
s = subplot(6,2,sind);

%Plot means
h = bar(nanmean(mat));
set(h,'facecolor','none','linewidth',2);
hold on;

%Plot raw
for n = 1:size(mat,1)
    plot(x,mat(n,1:3),'ko-')
end

%Rescale bottom of bar
ylimits = get(gca,'ylim');
set(h,'BaseValue',ylimits(1));

%Add lables
ylabel(ytext)
set(gca,'XTickLabel',xtext);
title(titletext)


%Format
set(gca,'box','off')
set(gca,'tickdir','out')



end

%FUNCTION
function mystats(mat,ax)

[~,p] = ttest2(mat(:,1),mat(:,2));
if p < 0.0001
    ptext = 'p < 0.0001';
else
    p = (round(p,4));
    ptext = ['p = ',num2str(p)];
end

axes(ax)
x = 1.2;
ylim = get(gca,'ylim');
y = ylim(2)*0.8;
text(x,y,ptext)

end