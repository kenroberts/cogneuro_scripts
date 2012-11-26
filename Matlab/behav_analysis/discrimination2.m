function discrimination2(config)
% This function is called by the analyze.m script
% It goes through Presentation logfiles specified in edit_vars.m
% and writes one output file per subject per condition with
% targets, correct & incorrect responses, % correct, % incorrect, RT.
% These variables are calculated per run and averaged per condition
%
% config is a struct that needs to have all of the required fields filled
% in.
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
    temp = vertcat(config.response_codes{:});
    config.response_codes = {};
    for i = 1:size(temp, 2);
        config.response_codes{i} = {temp{:,i}};
    end;
    
    % for each subject, populate target struct with characteristics of
    % targets and compound targets
    [targets, ctargets] = make_targets(config);

    for nlog = 1:length(config.log_filenames) % all the logfiles
      
        % create lfs from file
        lfs = read_logfile(get_logfile_name(config, sn, nlog));

        % count the number of any_code
        lfs2 = filter_lfs(lfs, 'include', unique(config.any_code));
        fprintf('Number of targets found: %d\n', length(lfs2.code));
        
        % score a run, returning modified targets
        ncond = find(cumsum(config.condition) >= nlog, 1); % determine which condition this run belongs to
        targets = score_run(lfs, nlog, ncond, targets);
        ctargets = merge_targets(targets, ctargets, nlog);
  
        % display a scored run graphically, if requested
        % this should be of use for profiling subjects as they are run in
        % ERP scripts.
    
    end; % filenames within subjects

    warning('off', 'MATLAB:divideByZero');
    log_runs(targets, ctargets, sn, config);
    warning('on', 'MATLAB:divideByZero');
    
    % write an entry in the ANOVA tables (across subs, choose xls or txt output)
    % write_anova(targets, ctargets, config.name_condition,
    % config.condition, sn);

end; % subject


return;

% return the name of the nlog'th presentation logfile for subject sn.
function pres_logfile_name = get_logfile_name(config, sn, nlog)
if (config.use_subjectID == 0)
    pres_logfile_name = sprintf('%s\\%s\\%s.log', config.root_dir, config.SubjectID{sn}, config.log_filenames{nlog});
else
    pres_logfile_name = sprintf('%s\\%s\\%s%s%s.log', config.root_dir, config.SubjectID{sn}, config.SubjectID{sn}, config.name_condition{1}, config.log_filenames{nlog});
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
ctargets = struct('name', config.compound_names, 'subtargets', config.compound_targets, ...
    'RTs', {{}}, 'scores', {{}}, 'locations', {{}});

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
time_diff = str2num(char(lfs.time{resp_locs})) * ones(1, length(targ_locs));
time_diff = time_diff - ones(length(resp_locs), 1) * str2num(char(lfs.time{targ_locs}))';
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
% TODO: insert detailed reporting in logfile ...

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
   
    targi_locs = find(targi_mask);
    targets(i).RTs{nlog} = rt_by_targ(targi_locs);
    targets(i).scores{nlog} = scores(targi_locs);
    targets(i).locations{nlog} = targ_locs(targi_locs); % find locs ref to logfile line
end;

% check to see if any targets were scored twice.
if any(cum_targs > 1)
    disp('Warning: some targets were scored twice.');
    disp('Compound target statistics may double count some targets.');
end;

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


% Merges targets together into ctargets
% populate these fields of ctargets
function ctargets = merge_targets(targets, ctargets, nlog)
    for ctarg = 1:length(ctargets)
        data = [];
        for subtarg = ctargets(ctarg).subtargets
            % within a log, start to merge RTs, answers, locs
            data = vertcat(data, horzcat(targets(subtarg).locations{nlog}, ...
                targets(subtarg).RTs{nlog}', double(targets(subtarg).scores{nlog})'));
        end;
        data = sortrows(data);
        ctargets(ctarg).locations{nlog} = data(:,1);
        ctargets(ctarg).RTs{nlog} = data(:,2)';
        ctargets(ctarg).scores{nlog} = char(data(:,3)');
    end;
return;

% log all the runs from a single subject.
function log_runs(targets, ctargets, sn, config)
    
    ncond = 1;
    cstart = cumsum([1 config.condition(1:end-1)]);
    cend = cumsum(config.condition);
    for nlog = 1:length(config.log_filenames)
    
        [out_fn, fn] = fileparts(get_logfile_name(config, sn, nlog));
        out_fn = [out_fn filesep config.SubjectID{sn} config.name_condition{ncond} 'Results.log'];
    
        if (any(cstart == nlog)), opf = fopen(out_fn, 'w'); end;
  
        % then, print header
        fprintf(opf, '\r\n\r\nRun: %02d   Logfile: %s\r\n\r\n', nlog, fn);
        fprintf(opf, '%-20s%-10s%-10s%-12s%-12s%-15s%-12s%-12s\r\n', 'Name', '#targs', ...
        'Correct', 'Incorrect', '% Correct', '% Incorrect', 'Mean RT', 'StdDev RT');
        
        print_record(opf, targets, nlog);
        print_record(opf, ctargets, nlog);
        
        % if end of condition, summarize the condition, and print the 
        if (any(cstart == nlog)), 
            fprintf(opf, '\r\n\r\nCondition: %02d   %s\r\n\r\n', ncond, config.name_condition{ncond});
            fprintf(opf, '%-20s%-10s%-10s%-12s%-12s%-15s%-12s%-12s\r\n', 'Name', '#targs', ...
        'Correct', 'Incorrect', '% Correct', '% Incorrect', 'Mean RT', 'StdDev RT');
             
            print_record(opf, targets, cstart(ncond):cend(ncond));
            print_record(opf, ctargets, cstart(ncond):cend(ncond));
            
            ncond = ncond+1; 
            fclose(opf); 
        end;
    end;
return;

% prints a single record, collates across possible range in nlog
function [anova_out] = print_record(opf, targets, nlog)
    anova_out = {'','',''}; % rt, er, pc
    for i = 1:length(targets)
        n = length(cat(2, targets(i).locations{nlog}));
        if n > 0
            cor = length(strfind(cat(2, targets(i).scores{nlog}), 'C')); 
            icor = length(strfind(cat(2, targets(i).scores{nlog}), 'I'));
            rts = targets(i).RTs{nlog}; rts = rts(cat(2, targets(i).scores{nlog}) == 'C'); % only use corr RTs
            fprintf(opf, '%-20s%-10d%-10d%-12d', targets(i).name, n, cor, icor);
            fprintf(opf, '%-12.2f%-15.2f%-12.2f%-12.2f\r\n', 100*(cor/n), 100*(icor/n), mean(rts), std(rts));
            anova_out{1} = sprintf('%s\t%4.2f\t', anova_out{1}, mean(rts));
            anova_out{2} = sprintf('%s\t%4.2f\t', anova_out{2}, 100*(icor/n));
            anova_out{3} = sprintf('%s\t%4.2f\t', anova_out{3}, 100*(cor/n));
        else
            anova_out{1} = sprintf('%s\tNaN\t', anova_out{1});
            anova_out{2} = sprintf('%s\tNaN\t', anova_out{2});
            anova_out{3} = sprintf('%s\tNaN\t', anova_out{3});
        end;
    end;
    fprintf(opf, '\r\n');
    
return;

% prints out reports
% reportlevel = 1 -> ANOVA tables, subject summary
% reportlevel = 2 -> above, plus per run summary
% reportlevel = 3 -> above, plus new marked-up logfiles
% reportlevel = 4 -> run-by-run graphical summary (like CIRC)

