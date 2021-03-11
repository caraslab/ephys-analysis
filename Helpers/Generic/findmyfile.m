function [myfile,varargout] = findmyfile(filelist,target)
%[myfile,varargout] = findmyfile(filelist,target)
%
%This function returns the files that include the target text.
%
%Input variables:
%   filelist:   A structure containing the names and paths to all of the
%               files in a given directory and its subfolders.
%
%   target:     A text string that contains part of the file name or
%               extension (e.g. 'config.mat', or 'aversive', or '.txt').
%               Text matching is case-insensitive.
%
%Output variables:
%   myfile:     A structure containing the names and paths to all of the
%               files in the filelist that match the target
%
%   varargout:  The indices of the files that match the target 
%
%Example usage: [myfile,idx] = findmyfile(allfiles,'.mat')
%
%Written by ML Caras Mar 2021

ind= contains({filelist.name},target,'IgnoreCase',true);
myfile = fullfile(filelist(ind).folder,filelist(ind).name);

varargout{1} = find(ind == 1);

