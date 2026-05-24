% startup.m — run this once per MATLAB session before running any scripts
% Adds all subfolders (utils, external, external/violinplot, etc.) to the path.
addpath(genpath(fileparts(mfilename('fullpath'))));
