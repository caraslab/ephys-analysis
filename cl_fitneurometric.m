function cl_fitneurometric(datadirectory,figdirectory)
%cl_fitneurometric(datadirectory,figdirectory)
%
%This function generates neurometric fits based on FR-based d' values for
%individual units. The plots are arranged as 1 row, with three columns,
%with each column corresponding to a behavioral state (pre, active, post).
%FR-based d' values are plotted as a function of AM depth and fit with a
%sigmoid using least squares regression. Fits are deemed valid or invalid
%based on whether the fitted y-values are significantly correlated with the
%original raw y values. Invalid fits are plotted with dashed lines. After
%fitting, the function determines the neural threshold (the AM depth at
%which the fit crosses d' == 1. If the highest d' < 1, no threshold is
%calculated (NaN). If the lowest d' > 1, threshold is defined as the lowest
%AM depth tested in that session. Only AM depths that were presented at
%least 5 times are included in the fits. 
%
%This function is a batch processor. It will cycle through all subjects,
%all units, and all behavioral states in a given directory.
%
%Input variables:
%
%   datadirectory: String path to where data are stored.Each file in the
%                  directory should contain data from a single animal.
%
%   figdirectory:  String path to where figures should be saved


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
        
        bstates = fields(S(j).trialinfo);
        
        %For each unit...
        for k = 1:numel(S(j).units)
            
            %Initialize a figure window
            fig = figure;
            
            %For each behavioral state...
            for m = 1:numel(bstates)
                
                %Start fresh
                clear x y xfit yfit
                
                %x values are AM depths in dB re: 100%
                x = S(j).units(k).metrics.(bstates{m}).FRdprimemat(:,1);
                
                %y values are FR-based dprime values
                y = S(j).units(k).metrics.(bstates{m}).FRdprimemat(:,2);
                
                
                %We will fit our data with a sigmoidal function. To do
                %this, we first need to set up the function. The equation
                %for a signmoidal function is:
                %
                %f = y0 + a/(1 + exp(-(x - x0)/b))
                %
                %The parameters (p) that govern the function are:
                %p(1):  y0 = min
                %p(2):   a = max - min
                %p(3):   b = slope
                %p(4):  x0 = x coordinate at inflection point
                f = @(p,x) p(1) + p(2) ./ (1 + exp(-(x-p(3))/p(4)));
                
                
                %Establish s vector of initial coefficients (beta0)
                beta0 = [0 20 50 5];
                
                %Set the maximum number of iterations to 10000
                options = statset('MaxIter',10000);
                
                %Estimate the coefficients of a nonlinear regression using
                %least squares estimation
                [p, ~, ~, ~, ~] = nlinfit(x,y,f,beta0,options);
                xfit = linspace(x(1),x(end),1000);
                yfit = f(p,xfit);
                yfit_corr = f(p,x);
                
                %Calculate p value to determine if the fit is a valid one
                [~, p_val] = corrcoef(y,yfit_corr);
                if numel(p_val) > 1
                    p_val = p_val(1,2);
                end
                
                %Find threshold (AM depth @ which d' == 1)
                dprime_threshold = calc_neurometric_threshold(xfit,yfit,p_val,1);
                
                %Let's append the fit data to the data structure
                S(j).units(k).fits.(bstates{m}).xfit = xfit;
                S(j).units(k).fits.(bstates{m}).yfit = yfit;
                S(j).units(k).fits.(bstates{m}).threshold = dprime_threshold;
                S(j).units(k).fits.(bstates{m}).fit_p_value = p_val;
                
                %-----------------------------------------------
                % Plot the fit and the raw data
                %-----------------------------------------------
                subplot(1,3,m);
                
                %Plot raw data
                hraw = plot(x,y,'k.','markersize',25,'linewidth',2); %#ok<NASGU>
                hold on
                
                %Plot the fitted data 
                hfit = plot(xfit,yfit,'k-','linewidth',2);
                
               %Plot as dashed line if the fit is invalid)
                if p_val>0.05
                    set(hfit,'linestyle','--');
                end
                
                %Plot threshold lines if there was a threshold
                if ~isnan(dprime_threshold)
                    ylimits = get(gca,'ylim');
                    ymin = ylimits(1);
                    x = [dprime_threshold,dprime_threshold];
                    y = [ymin,1];
                    plot(x,y,'-','Color',[0.5 0.5 0.5]);
                    
                    xlimits = get(gca,'xlim');
                    xmin = xlimits(1);
                    x = [xmin,dprime_threshold];
                    y = [1,1];
                    plot(x,y,'-','Color',[0.5 0.5 0.5]);
                    
                end
                
                
                %Format the plot
                xlabel('AM Depth (dB)')
                ylabel('FR-based dprime')
                title(bstates{m});
                set(gca,'box','off')
                set(gca,'tickdir','out');
                
                if max(y) < 3.5
                    set(gca,'ylim',[0 3.5]);
                end
                
            end
            
            %Add a title to the figure with the subject, date, and unit
            %name
            ftitle = [S(j).metadata.active.name, S(1).metadata.active.date,...
                newline, 'Cluster ', num2str(S(j).units(k).cluster)];
            hs = suptitle(ftitle);
            set(hs,'Interpreter','none'); %ensure underscores are displayed properly
            
            %Save the figure as an eps file
            set(figure(fig),'PaperPositionMode','auto');
            savename = fullfile(figdirectory,ftitle);
            print(figure(fig),'-painters','-depsc', [savename, '_fits'])
            
            %Close the figure window
            close all
            
            
        end
        
    end
    
    %Save all of the fits and thresholds to the file
    save(tempfile,'S');
    
end


end







%FUNCTION: CALCULATE NEUROMETRIC THRESHOLD
function dprime_threshold = ...
    calc_neurometric_threshold(xfit,yfit,p_val,dprime_val)
%dprime_threshold = calc_neurometric_threshold(xfit,yfit,p_val,dprime_val)
%
%This function finds the stimulus value at which the neurometric fit
%crosses a dprime of dprimeval.
%
%Input variables:
%   xfit: vector of x values for neurometric fit
%   yfit: vector of y values for neurometric fit (must be same size as x)
%   p_val: p value from pearson's r to determine if fit is valid
%   dprime_val: value at which you want to find threshold
%
%Written by ML Caras Dec 5 2016


%If the fit is not valid, there is no threshold
if isnan(p_val) || p_val > 0.05
    dprime_threshold = NaN;
    
    %If the fit is valid, and it crossed dprime_val...
elseif max(yfit) > dprime_val && min(yfit) < dprime_val
    
    indmax = find(yfit == max(yfit));
    indmin = find(yfit == min(yfit));
    
    indmax = indmax(1);
    indmin = indmin(end);
    
    xmax = xfit(indmax);
    xmin = xfit(indmin);
    
    %And if the fit slope was positive
    if xmax > xmin
        
        %Find threshold @ dprime = dprime_val
        target = min(abs(yfit - dprime_val));
        thresh_ind = find(abs(yfit - dprime_val) == target);
        dprime_threshold = xfit(thresh_ind(1));
        
    else
        dprime_threshold = NaN;
        
    end
    
    %If the fit is valid, but the maximum value is still below dprime_val,
    %there is no threshold
elseif max(yfit) < dprime_val
    
    dprime_threshold = NaN;
    
    
    
    %If the fit is valid, but the minimum value is above dprime_val, set the
    %threshold to the lowest AM depth tested that day
elseif min(yfit) > dprime_val
    
    dprime_threshold = min(xfit);
    
end


end


