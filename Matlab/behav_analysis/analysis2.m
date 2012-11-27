function analysis2(varargin)
% This script analyzes the log-files for individual subjects and individual runs
% Users should copy the edit_vars file to their own directory and select it after typing
% analysis in the matlab window.  
% Laura Busse, Feb 7 2002
%              June 6 2002
%              July 4 2002                

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Changelog:
%
% 8/29/02	KCR	Added a call to verifier which will check the input log file.
%						and print out helpful error messages.  If you do not wish for your
%						files to be verified, then just comment out the line 'verifier'.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch nargin,
    case 0   % choose edit_vars with gui
        [hdrName, hdrPath] = uigetfile('*.m', 'Select edit_vars file containing user specified variables.');
        [~, hdrName, hdrExt] = fileparts(hdrName);
    case 1   % filename supplied
        [hdrPath, hdrName, hdrExt]=fileparts(varargin{1});
        if isempty(hdrPath), hdrPath=pwd; end;
    otherwise
        error('analysis.m:  Too many input arguments!');
end

%Get hdrFile
try,
    curr_path = pwd;
    cd (hdrPath);
    eval(hdrName);  % Call m-file specified in string hdrName.
catch
    error(['Invalid matlab syntax in file: ' pwd filesep hdrName hdrExt]);
end;

% make enormous config struct
config = struct('root_dir', root_dir, 'SubjectID', {SubjectID}, 'use_subjectID', use_subjectID, ...
    'log_filenames', {log_filenames}, 'condition', condition,  'name_condition', {name_condition}, ...
    'any_code', {any_code}, 'target_names', {target_names}, 'target_codes',  {target_codes}, ...
    'response_codes',  {response_codes}, 'standard_codes',  {standard_codes},  'compound_names', {compound_names}, ...
    'compound_targets', {compound_targets}, 'min_RT', min_RT, 'max_RT', max_RT,  ...
    'SD_factor', SD_factor ...
     );

% X rootdir
% X SubjectID...
% X use_subjectID...
% X log_filenames...
% X condition...
% X name_condition...
%   N task...
% X any_code...
% X target_names...
% X standard_names...
% X target_codes...
% X response_codes...
% X standard_codes...
% X compound_names...
% X compound_targets...
% X min_RT...
% X max_RT...
%   N trial_ID...
% X SD_factor;

% SD_factor and anova_dir are both optional
if exist('SD_factor') && ~isempty(SD_factor), config = setfield(config, 'SD_factor', SD_factor); end;
if exist('anova_dir') && ~isempty(anova_dir), config = setfield(config, 'anova_dir', anova_dir); end;

% verify the contents of the edit_vars file
cd(curr_path);
%verifier;

% detection task, calculate Hits, False Alarms, Misses, and RT for Hits
% discrimination task, calculate correct & incorrect responses and RT for
% correct responses
switch task
    case 1
        detection2(config);
    case 2
        discrimination2(config);
end;
