% GE fieldmap is different from fieldmaps from the SIEMENS scanners
% This script organize the GE fieldmap images into the structures that is
% readable to fmriprep
% 
% Briefly speaking, first do dcm2nii using the latest version of
% dcm2niix.exe. This will generate two .nii files with different
% PhaseEncodingDirection. "j" means anterior to posterior, and "j-" means
% posterior to anterior. Next, we need to copy these .nii and .json files
% into the folders named "fmap" under each subject's directory of the
% "BIDS" folder.
%
% NOTE: the older version of dcm2niix may not be able to generate two .nii
% files due to a known issue:
% https://neurostars.org/t/ge-direct-fieldmaps-how-to-debug-pe-direction/22959/3
%
% Xiao Chen
% 240528
% chenxiaophd@gmail.com

% Reference:
% https://bids-specification.readthedocs.io/en/stable/modality-specific-files
% /magnetic-resonance-imaging-data.html#types-of-fieldmaps
%% initialization
clear; clc;

work_dir = 'C:\DYSMARK_pilot\resting_state_fieldmap';
subj_ID = 'Pilot001';

%% dicom to nifti
StartIndex = 3;
DirDCM=dir([work_dir, filesep, 'FieldMapRaw', filesep, subj_ID, ...
            filesep, '*']);
InputFilename=[work_dir, filesep, 'FieldMapRaw', filesep, subj_ID, ...
                 filesep, DirDCM(StartIndex).name];
OutputDir = [work_dir, filesep, 'FieldMap', filesep, subj_ID];
if ~exist(OutputDir, "dir"); mkdir(OutputDir); end
% using the latest version of dcm2niix software
eval(['!C:\toolbox\dcm2niix.exe ','-o ',OutputDir,' ',InputFilename]);


%% organize into BIDS format
fmap_dir = [work_dir, filesep, 'BIDS', filesep, 'sub-', subj_ID, ...
            filesep, 'fmap'];
if ~exist(fmap_dir, "dir"); mkdir(fmap_dir); end

jsonFiles = dir(fullfile(OutputDir, '*.json'));
niiFiles = dir(fullfile(OutputDir, '*.nii'));

for k = 1:length(jsonFiles)
    % Get the file name (without the extension)
    [~, fileName, ~] = fileparts(jsonFiles(k).name);
     % Construct the full file path
    filePath = fullfile(OutputDir, jsonFiles(k).name);
    % Read the JSON file
    jsonData = fileread(filePath);
    
    % Decode the JSON data
    data = jsondecode(jsonData);

    if strcmp(data.PhaseEncodingDirection, "j")
        dir_label = 'AP';
    elseif strcmp(data.PhaseEncodingDirection, "j-")
        dir_label = 'PA';
    end

    % copy .json file
    BIDS_name = ['sub-', subj_ID, '_dir-', dir_label, '_epi'];
    source = filePath;
    destination = [fmap_dir, filesep, BIDS_name, '.json'];
    copyfile(source, destination);

    % copy .nii file
    source = fullfile(OutputDir, niiFiles(k).name);
    destination = [fmap_dir, filesep, BIDS_name, '.nii'];
    copyfile(source, destination);
end

%% added the field "intenedfor"
dir_label = 'AP';
BIDS_name = ['sub-', subj_ID, '_dir-', dir_label, '_epi'];
destination = [fmap_dir, filesep, BIDS_name, '.json'];
JSON=spm_jsonread(destination);
JSON.IntendedFor= 'func/sub-Pilot001_task-rest_bold.nii';
spm_jsonwrite(destination,JSON);

dir_label = 'PA';
BIDS_name = ['sub-', subj_ID, '_dir-', dir_label, '_epi'];
destination = [fmap_dir, filesep, BIDS_name, '.json'];
JSON=spm_jsonread(destination);
JSON.IntendedFor= 'func/sub-Pilot001_task-rest_bold.nii';
spm_jsonwrite(destination,JSON);