% prepare your logfiles:
% 1. logfiles should be located in root directory of the experiment
% which you specify below
% 2. Within this root directory you should have a folder for each subject that
% is named SubjectID

% %%%%%%%%%%%%%%%%%%%%%%%%%%DO NOT EDIT - List of global variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global root_dir...
   SubjectID...
   use_subjectID...
   log_filenames...
   condition...
   name_condition...
   task...
   any_code...
   target_names...
   standard_names...
   target_codes...
   response_codes...
   standard_codes...
   compound_names...
   compound_targets...
   min_RT...
   max_RT...
   trial_ID...
   SD_factor;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% User SHOULD EDIT these %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the root directory of the experiment
root_dir = 'C:\Users\kcr2\Desktop\cogneuro_scripts\Matlab\behav_analysis\testing_behav_scr\logfile_from_hanna';

% SubjectID field, can be any string (a number or a name, or a code word)
SubjectID = {'101'}; % edit the number of subjects

% names of logfiles
% if the logfiles have the subjectID prepended to them 
% (ie are of the type '01Attend_Left1' where 01 is the subject_ID
% then set use_subjectID to 1.  Otherwise set to zero.
use_subjectID = 0;
log_filenames = {'shape-blockedAttention_cueShape2'};

% conditions: which runs are of the same condition, which runs should be averaged together
% specify last item of each condition
% e.g. condition = [3, 3] means that the first 3 logfiles belong to the first condition,
% the second 3 logfiles belong to the second condition
condition = [1];
name_condition = {'Color_Change_Pilot'};

% detection (Hits, Misses, FA, RT) or discrimination (correct & incorrect responses, RT)
task = 2; 	% 1 = detection
		    % 2 = discrimination   


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Describe codes  %%%

% any of the stimulus codes in the logfile, no responses codes
any_code = { };

% Create a cell vector of names for all the different targets (i.e. stimuli after which you expect a response)
target_names = {'Non-targets', 'R Targets', 'L Targets'};

% Create a cell vector of cell of codes for all of the different events that require responses.  
% Each entry in the cell vector has a corresponding entry in the cell vector above.
% Events will be mapped to one of the arrays in the cell vector target_names.
% targets must have associated response codes- ie they cannot be ignored.
target_codes = {{'11','12','21','22'}, {'51'}, {'52'}};


% Specify the codes for the correct responses for each condition         
% Responses will be mapped to the corresponding array in the cell vector
% In this example, use 1 for circles on the attended side, and 2 for no circles on the attended side
response_codes = {{'1', '2', '2'}};


% other stimulus types you want to keep track of
% detection: e.g. number of standards, ...
% discrimination: e.g. number of cues, ...
  standard_names = {''};


% Create a cell vector of arrays of codes for the remaining events that should be counted, i.e. standards, cues, ...              
% Events will be mapped to one of the arrays in the cell vector standard_names
  standard_codes = { [''], ...
     };

% compound codes are made from unions of the simple codes listed above.
% for example, with :
% target_names = {'HH'; 'SS'; 'SH'; 'HS'};
% target_codes = { [100,111,112,113,114,115], ...
%      				[200,211,212,213,214,215], ...
%      				[300,311,312,313,314,315], ...
%      				[400,411,412,413,414,415] ...
%   					};
% compound_names = {'HH_and_SS', 'SH_and_HS'};
% compound_targets = {[1, 2], [3, 4]};
% all the statistics from HH and SS will be merged into HH_and_SS, etc.
compound_names = { 'All targets' };
compound_targets = { [2, 3] };

% specify how long after the target responses are accepted (should usually be less than the SOA)
min_RT = 100 ;
max_RT = 1000;  % in milliseconds

% this variable may be set in addition to min and max RT to redo the
% windowing from min_RT to max_RT to mean+-x*SD where x is the SD_factor
% for example, SD_factor = 2 will window the responses to the mean plus or
% minus two standard deviations for each simple condition independently.
% Assuming a normal distribution, here is a short chart of SD_factor vs.
% percentage of trials preserved:
%   1   66
%   2   95
%   3   99.7
% if you do not want to use this feature, comment out the line.
% SD_factor = 2;

% in Presentation, the first column of the logfile is the trial number
% the program will only tabulate results that have the trial_ID set here.
% modify the program so that -1 ignores the trialID
trial_ID = 1091;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
