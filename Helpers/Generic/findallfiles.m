function allfiles = findallfiles(directory)
%allfiles = findallfiles(directory)
%
%This function will find all files in the specified directory and any of
%its subfolders.
%
%Written by ML Caras March 2021

%Recursively list all files in the directory
try
    allfiles = dir(fullfile(directory,'**\*.*')); %mac
catch
    allfiles = dir(fullfile(directory,'**/*.*'));%windows
end

allfiles = allfiles(~[allfiles.isdir]); %remove any subdirectories