function cl_fitneurometric(datadirectory,figdirectory)



%Get a list of all the files in the directory
allfiles = findallfiles(datadirectory);

%Find the real files (the *.mat files)
[~,idx] = findmyfile(allfiles,'.mat');


%For each file (subject)
for i = 1:numel(idx)
    
    clear tempfile Ss
    
    %Load the data
    tempfile = fullfile(allfiles(idx(i)).folder,allfiles(idx(i)).name);
    load(tempfile,'S');
    
    %For each session (date)...
    for j = 1:numel(S)
        
        bstates = fields(S(j).trialinfo);
        
        %For each unit...
        for k = 1:numel(S(j).units)
            
            %For each behavioral state...
            for m = 1:numel(bstates)
                
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
                
                %Calculate p value
                [~, p_val] = corrcoef(y,yfit_corr);
                if numel(p_val) > 1
                    p_val = p_val(1,2);
                end
                
                %Find threshold (AM depth @ which d' == 1)
                
                
                
                
            end
            
        end
        
    end
    
    
end


