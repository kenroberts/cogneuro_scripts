function recode_score_eventlist(config)
% This function is called by the analyze.m script
% It goes through an ERPPLAB eventlist and recodes the codes
% based on whether they are scored correctly or not.
%
% Each target must have specified a pair of codes, one which will be used
% to indicate correct trials, and another which indicates incorrect trials.
%
% config is a struct that needs to have all of the required fields filled
% in. (same fields as for Presentation logfile analysis, except that the
% compound fields are ignored).
% Ken Roberts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% changelog
%
%
% 7/20/07   KCR     Total rewrite.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

num_subjects = length(config.SubjectID); % total number of subjects

for sn = 1:num_subjects; % all the subjects

    % rearrange 'nesting' of responses in cell arrays
    % so that 'target' is outer, 'condition' is inner
    temp = vertcat(config.response_codes{:});
    config.response_codes = {};
    for i = 1:size(temp, 2);
        config.response_codes{i} = temp(:,i)';
    end;
    
    % for each subject, populate target struct with characteristics of
    % targets and compound targets
    [targets, ctargets] = make_targets(config);

    for nlog = 1:length(config.log_filenames) % all the logfiles
      
        % create "fake" lfs
        fprintf('Reading: %s\n', get_logfile_name(config, sn, nlog));
        [EEG, EVENTLIST] = readeventlist([], get_logfile_name(config, sn, nlog));
        lfs.filename = get_logfile_name(config, sn, nlog);
        lfs.code = [EVENTLIST.eventinfo(:).code]';
        lfs.time = [EVENTLIST.eventinfo(:).time]' * 1000;
        lfs.eventlist = EVENTLIST;
        
        % needs to be a cellstr, not a vector
        lfs.code = strtrim(cellstr(int2str(lfs.code)));
        
        % score a run, returning modified targets
        ncond = find(cumsum(config.condition) >= nlog, 1); % determine which condition this run belongs to
        targets = score_run(lfs, nlog, ncond, targets);
    
    end; % filenames within subjects
    
end; % subject


return;

% return the name of the nlog'th presentation logfile for subject sn.
function pres_logfile_name = get_logfile_name(config, sn, nlog)
if (config.use_subjectID == 0)
    pres_logfile_name = sprintf('%s\\%s\\%s.txt', config.root_dir, config.SubjectID{sn}, config.log_filenames{nlog});
else
    pres_logfile_name = sprintf('%s\\%s\\%s%s%s.txt', config.root_dir, config.SubjectID{sn}, config.SubjectID{sn}, config.name_condition{1}, config.log_filenames{nlog});
end
return;

%%%%%%%%%%%%
%
% make_targets: populates targets and ctargets structs
%       requires a config struct
%
%   terminology: targets are event codes for which a response will be
%   scored, and ctargets, or compound_targets, are groupings of simple
%   targets over which the scores (and RTs) will be aggregated for
%   reporting purposes.
%
%%%%%%%%%%%%
function [targets, ctargets] = make_targets(config)

targets = struct('name', config.target_names, 'codes', config.target_codes, ...
    'corr_response', config.response_codes, 'RT_window', [config.min_RT, config.max_RT], ...
    'RTs', {{}}, 'scores', {{}}, 'locations', {{}});

if isfield(config, 'compound_names') && ~isempty(config.compound_names)
    ctargets = struct('name', config.compound_names, 'subtargets', config.compound_targets, ...
        'RTs', {{}}, 'scores', {{}}, 'locations', {{}});
else
    ctargets = [];
end;

return;


    
%%%%%%%%%%%%
%
% score_run: the strategy here will be to step through events one at a time
% looking for a target.  If a target is found, the RT window for that
% target is searched for a response that matches either the correct
% response, or a correct response for another target.  Each target is
% scored as C = correct, I = incorrect, and X = no corr or incorr answer within RT window.
%
% Postcondition: 
% targets(x).scores{run} filled with string like 'CCCCICCCX ...' 
% targets(x).RTs{run} filled with RT's for each correct target like
%                     [492.43, 686.72 ...]
%
%%%%%%%%%%%%
function targets = score_run(lfs, nlog, ncond, targets)

% find all targets
targ_mask = match_strings(lfs.code, unique(cat(2, targets(:).codes)));
targ_locs = find(targ_mask);
targ_codes = lfs.code(targ_locs);

% find all responses
resp_mask = match_strings(lfs.code, unique(cat(2, targets(:).corr_response)));
resp_locs = find(resp_mask);
resp_codes = lfs.code(resp_locs);

% time_diff(i, j) is the time of ith response after the jth target
time_diff = lfs.time(resp_locs) * ones(1, length(targ_locs));
time_diff = time_diff - ones(length(resp_locs), 1) * lfs.time(targ_locs)';
time_diff = time_diff/10; % convert to ms

% threshold by min and max RT permissible
    % possible to add RT std devs for scoring, (choice: attribute target to
    % only one of targets, or attribute it to many?  If many, then no way to do
    % per-target class RT std dev thresholding
time_mask = (time_diff > targets(1).RT_window(2)) | (time_diff < targets(1).RT_window(1));
time_diff(time_mask) = 0;

% make sure every targ has one resp, and vice versa
% (ie, targets "consume" responses)
for j = 1:length(targ_locs)
    this_resp = find(time_diff(:, j) ~= 0);
    if ~isempty(this_resp)
        time_diff(this_resp(1)+1:end, j) = 0;
        time_diff(this_resp(1), j+1:end) = 0;
    end;
end;

matched_targets = double(sum(time_diff) ~= 0);
rt_by_targ = sum(time_diff);
time_mask = double(time_diff ~= 0); % useful for mapping targs to resp with a multiply


% % find resp->targ matches and targ->resp matches indexed to resp# and targ#
% [resp_mat, targ_mat] = find(time_diff ~= 0);
% % re-index to location in logfile
% resp_mat = targ_locs(resp_mat);
% resp_mat = targ_locs(resp_mat);

% TODO: insert detailed log-by-log based graphical reporting


% go through targets and fill 
%   RT{cond} = [450, 430, ...] and scores{cond} =
%   scores{cond} = ['CCICM...']
scores = repmat('M', 1, length(targ_codes));
cum_targs = zeros(length(targ_codes), 1);
for i = 1:length(targets)
    targi_mask = match_strings(targ_codes, targets(i).codes);   % find targets 
    cum_targs = double(targi_mask) + cum_targs;                 % and increment counts
    
    corri = targi_mask & (strcmp(resp_codes, targets(i).corr_response{ncond})' * time_mask)';
    icorri = targi_mask & matched_targets' & ~corri;
    
    scores(corri) = 'C';
    scores(icorri) = 'I';
   
    % fill in struct for that target
    targi_locs = find(targi_mask);
    targets(i).RTs{nlog} = rt_by_targ(targi_locs);
    targets(i).scores{nlog} = scores(targi_locs);
    targets(i).locations{nlog} = targ_locs(targi_locs); % find locs ref to logfile line
end;

% reporting
if 1
    rewrite_logfile(lfs, targets, scores, targ_codes, targ_locs);
end;


% check to see if any targets were scored twice.
if any(cum_targs > 1)
    disp('Warning: some targets were scored twice.');
    disp('Compound target statistics may double count some targets.');
end;

return;



function lfs = rewrite_logfile(lfs, targets, scores, targ_codes, targ_locs)

% rewrite-list should be a cell-array the same length as the 
% targets.  Each target will be rewritten with two codes, the first code if
% it has been scored as correct, and the second if it has not (incorr, or
% miss)
rewrite_list = {[5,6]};

% non-numeric codes -> -10.
[rewrite_codes] = str2double(lfs.code);
rewrite_codes(isnan(rewrite_codes)) = -10;

for i = 1:length(targets)
    targi_mask = match_strings(targ_codes, targets(i).codes);   % find targets
    corri = targi_mask & (scores == 'C')';
    icorri = targi_mask & ~corri;
    
    % 
    fprintf('Target: %s has %d/%d correct.\n', targets(i).name, ...
        sum(double(corri)), length(targi_mask));
    
    % rewrite the codes
    rewrite_codes(targ_locs(corri)) = rewrite_list{1}(1);
    rewrite_codes(targ_locs(icorri)) = rewrite_list{1}(2);
end;

% push codes back into EVENTLIST
rewrite_codes = num2cell(rewrite_codes);
[lfs.eventlist(:).code] = [rewrite_codes{:}];

% warn about overwriting files?
out_fn = strrep(lfs.filename, '.log', '_scored.log');
if exist(out_fn, 'file')
    delete(out_fn);
end;
creaeventlist([], lfs.eventlist, out_fn, 1);

return;


% returns binary the size of str_arr that correponds to whether each entry
% matches any string in str_list
% reasonably vectorized, should be quite fast.
function isinlist = match_strings(str_arr, str_list)
isinlist = false(size(str_arr));
for i = 1:length(str_list)
    isinlist = isinlist | strcmp(str_arr, str_list{i});
end;
return



