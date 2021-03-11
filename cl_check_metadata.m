function cl_check_metadata(datadirectory)
%cl_check_metadata(datadirectory)
%
%This function verifies that basic metadata information (subject name, sex,
%age, and session date) are the same across all behavioral states in the
%file. If a discrepancy is found, a message pops up in the command window
%instructing the user to check the file in question for problems. This
%check ensures that data from different animals, or from different dates,
%weren't accidentally merged into a single file, and also ensures that the
%sex and age of the animal is correctly recorded. 
%
%This file also prompts the user to verify the condition of the subject,
%and the recording depth for each session. Both of these values are
%manually recorded by the user during each session, but generally change
%from day to day, thus leading to the possibility of error.
%
%Written by ML Caras March 2021



%Clear command window
clc

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
            
            %Pull out the basic metadata that shouldn't change across
            %behavioral state
            sessdate = S(j).metadata.(bstates{k}).date;
            subj = S(j).metadata.(bstates{k}).name;
            age = S(j).metadata.(bstates{k}).age;
            sex = S(j).metadata.(bstates{k}).sex;
            
            dates{k} = sessdate; %#ok<*AGROW>
            subjs{k} = subj;
            ages{k} = age;
            sexes{k} = sex;
        end
        
        %Check that the basic metadata match up across behavioral states
        %(i.e. that we didn't accidentally merge data from different
        %animals or dates into a single file).
        if ~isequal(dates{:}) || ~isequal(subjs{:}) || ~isequal(ages{:}) || ~isequal(sexes{:})
            
            %Alert user to check the file for metadata discrepancies
            disp([newline 'Check ',tempfile, ' for metadata discrepancies.' ...
                newline 'File will not be processed further.'])
            
            %Abort and skip to next file
            break
        end
        
        
        
        %Now, let's verify a few extra pieces of information that might
        %differ across behavioral states. First, we'll check the subject's
        %condition. We want to use standardized labels so that group
        %analyses down the road can easily divide the subjects or sessions
        %into specific groups.
        
        %For each state...
        for k = 1:numel(bstates)
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%CHECK CONDITION%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %Get the subject condition
            condition = S(j).metadata.(bstates{k}).condition;
            
            %Set up the menu header...
            menuheader = ['Please verify the condition for:' newline subj,...
                ' ',sessdate, ' ',bstates{k} newline newline 'Subject Condition: ', condition];
            
            
            %Ask the user to verify if the information is correct
            choice = menu(menuheader,'Correct','Incorrect');
            
            %If the information is not correct, prompt the user to
            %enter the correct data
            if choice == 2
                answer = inputdlg(['Please enter the correct condition for:'...
                    newline subj,' ' sessdate, ' ', bstates{k}]);
                S(j).metadata.(bstates{k}).condition = answer{1};
                
            end
            
            
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%CHECK RECORDING DEPTH
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %Get the recording depth and convert from text to a number
            recordingdepth = str2double(S(j).metadata.(bstates{k}).recordingdepth);
            
            %Let's make sure the recording depth is always recorded using
            %the same units
            if recordingdepth < 10 %mm
                
                %Convert to um and save to structure
                S(j).metadata.(bstates{k}).recordingdepth = num2str(recordingdepth*1000);
                
            end
            
            %Set up the menu header...
            menuheader = ['Please verify the recording depth for:' newline subj,...
                ' ',sessdate, ' ',bstates{k} newline newline...
                'Recording depth (um): ', ...
                S(j).metadata.(bstates{k}).recordingdepth];
            
            %Ask the user to verify if the information is correct
            choice = menu(menuheader,'Correct','Incorrect');
            
            %If the information is not correct, prompt the user to
            %enter the correct data
            if choice == 2
                answer = inputdlg('Please enter the correct recording depth (in um).');
                S(j).metadata.(bstates{k}).recordingdepth = answer{1};
                
            end
            
            
        end
        
    end
    
end

%Save the data to the file
save(tempfile,'S')
disp ([tempfile,' updated and saved!'])
