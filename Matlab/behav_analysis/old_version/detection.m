function nothing = detection
% This function is called by the analyze.m script
% There may be multiple types of targets to detect, but, 
% the False Alarm rate will not be distinguishable.
% (ie, if there is indeed a false alarm, how do you attribute it 
% as belonging to one type of target versus another?)
% Laura Busse
% Ken Roberts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% changelog
%
% 8/5/02	KCR	Modified count_responses.  For each target, looks for 
%				a response within max_RT, no longer limited to looking 
% 				ahead only a certain number of events.
%
% 8/5/02	KCR	Fixed a bug in which_condition where the conditions were hard-coded.
%
% 8/7/02	KCR, SF  Revised program to accept strings as valid target and response codes.   
%
% 8/7/02    KCR	Added a min_RT variable
%
% 8/13/02	KCR	Trial feature removed
%
% 8/13/02	KCR	Now calculates standard deviations
%
% 8/27/02   KCR Changed location of output file to the subject's directory
%               (where the input files are)
%
% 11/18/02  KCR Added threshholding by SD.
%
% 11/18/02  KCR Added ANOVA output for RT.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% catalog of functions
%
% discrimination- calculates reaction times and percentage correct hits 
%     for a presentation log file.
% open_logfile- reads in a presentation log file, and handles errors.
%     (reqs. the function decode_error)
% count_events- counts the number of events specified in any_code in the 
%     edit_vars file.  useful for checking to see if the presentation
%		script was properly created.
% test_lfi- debug function to print out logfile info struct.
% test_ts- debug function to print out logfile stats struct.
% count_responses- function that takes logfile info struct and counts
%		correct, incorrect responses and RT's.  Returns an array of target structs (ts).
% compute_values- function that takes an array of stats, eact corresponding 
%		to one target, and forms a single cumulative stats struct (cs).
% write_values- function that writes a cumulative stats struct (cs).
% summarize_results- takes stats structs from several  logfiles and computes
%		cumulative data for each condition.
% print_results- prints out all of the results in appropriate files.
% decode_error- looks at an error string to see if it contains a specific message.
% which_condition- returns the condition a run belongs to
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% global variables the user specifies in edit_vars.m
global root_dir anova_dir SubjectID use_subjectID log_filenames ...
    min_RT max_RT target_codes target_names standard_names compound_names ...
    name_condition condition SD_factor new_min_RT new_max_RT;

% deletes old Anova SUMMARY FILES
warning off;
num_of_conditions = size(condition, 2);
anovafiles = { 'ANOVA_RT.log' 'ANOVA_ER.log' 'ANOVA_PC.log' 'ANOVA_FA.log'};
if (isempty(anova_dir))
    anova_dir = root_dir;
end

for i = 1:num_of_conditions
    for j = 1:length(anovafiles)
        % delete the file
        anovafile = sprintf('%s\\%s%s', anova_dir, name_condition{i}, anovafiles{j});
        delete(anovafile);
        fid = fopen(anovafile, 'w');
        % make the names
        if (isempty(strfind('FA', anovafiles{j})))
            for k = 1:length(target_names)
                fprintf(fid, '%s\t', target_names{k});
            end
            for k = 1:length(compound_names)
                fprintf(fid, '%s\t', compound_names{k});
            end
        else
            for k = 1:length(standard_names)
                fprintf(fid, '%s\t', standard_names{k});
            end
        end
        fprintf(fid, '\r\n');
        fclose(fid);
    end;  
end
warning on;

num_subjects = length(SubjectID); % total number of subjects

for sn = 1:num_subjects; % all the subjects
    
    for nlog = 1: length(log_filenames) % all the logfiles
        
        % construct filename
        if (use_subjectID == 0)
            pres_logfile_name = sprintf('%s\\%s\\%s.log', root_dir, SubjectID{sn}, log_filenames{nlog});
        else
            pres_logfile_name = sprintf('%s\\%s\\%s%s%s.log', root_dir, SubjectID{sn}, SubjectID{sn}, name_condition{1},log_filenames{nlog});
        end
        
        fprintf('Opening: %s\r\n', pres_logfile_name);
        
        % lfi is a struct, the name stands for "log file info"
        log_file_info = open_logfile(pres_logfile_name);
        
        % count is the number of events that are in any_codes
        count = count_events(log_file_info);
        fprintf('Number of trials: %d\r\n', count); % total number of trials per logfile/run
        
        % run_info is an array of structs, one for each target, containing info for that target
        [target_info standard_info] = count_responses(log_file_info, nlog);
        
        % from data in the run_info, compute average RT's and percentages and put in run_stats
        % run_stats is a single struct, not an array.
        [t_stats s_stats] = compute_values(target_info, standard_info);
        
        % runs_stats_arr contains data from all runs
        t_stats_arr(nlog) = t_stats;
        s_stats_arr(nlog) = s_stats;
    end; % filenames
    
    % write a complete summary of the data
    % summary_stats is an array with information from each condition
    [tss sss] = summarize_results(t_stats_arr, s_stats_arr);
    print_results(tss, sss, t_stats_arr, s_stats_arr, sn);
    
end; % subject

% prints stats in a table for ANOVA
% print_ANOVA_stats(ANOVA_stats);

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function lfi = open_logfile(filename)
% reads in a logfile and puts all of the relevent information in a struct

stop = 0; % variable will be set when the first line in the logfile is found
lines_to_skip = 0;

trial = [];
types = {};
codes = {};
times = [];
fnf_emsg = 'File not found';

% the first readable line of the file SHOULD be within the first 20 lines
% this prevents an unending loop
while (stop == 0 & lines_to_skip < 20)
    try
        [trial, types, codes, times] = textread(filename, '%d %s %s %d %*[^\n]', 'headerlines', lines_to_skip);
        stop = 1;
    catch
        % throw file not found error
        le = lasterr;
        if (decode_error(le, fnf_emsg) ~= 0)
            emsg = sprintf('The log file %s \nwas not found\n', filename);
            error(emsg);
        end
        % handle case where line was not read properly
        lines_to_skip = lines_to_skip + 1;
    end;
end;

if (lines_to_skip >= 20)
    emsg = sprintf('The log file %s \nis not in a recognizable format\n', filename);
    error(emsg);
end

times = times./10;

% fill the struct that is returned
lfi.log_file_name = filename;
lfi.num_events = length(codes);
lfi.trial = trial;
lfi.types = types;
lfi.codes = codes;
lfi.times = times;
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function num_trials = count_events(lfi)
% get total number of trials first for each logfile/run

global any_code;

num_trials = 0;
for i = 1:lfi.num_events
    for j=1:size(any_code, 2)
        if (strcmp(lfi.codes{i}, any_code{j}))  % specified above, any stimulus codes, not responses
            num_trials = num_trials+1;
        end
    end
end

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nothing = test_lfi(lfi)
% print some values from lfi

fprintf('Log file name: %s\r\n', lfi.log_file_name);
fprintf('Number of events counted: %d\r\n', lfi.num_events);

for i = 1:5
    fprintf('Trial: %d\t Codes: %s\t Times: %d\r\n', trial(i), codes{i}, times(i));
end

return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nothing = test_ts(ts)
% print some values from an array of ts's

global target_names;

for i = 1:length(ts)
    fprintf('Target: %s\r\n', target_names{i});
    ts(i).counts
    ts(i).corr
    ts(i).incorr
    ts(i).RT
end;
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ts, ss] = count_responses(lfi, nlog)
% counts all of the responses to each target in one logfile

global target_codes standard_codes response_codes min_RT max_RT;

% define some variables
num_of_targets = size(target_codes, 2);
num_of_standards = size(standard_codes, 2);
flags = zeros(lfi.num_events, 1);
temp_RT = 0;
timepoints = lfi.num_events;


% array of target stats, each target stats holds info for one target
ts = repmat(struct('counts', 0, 'corr', 0, 'incorr', 0, 'RT', []), size(target_codes, 2), 1);
ss = repmat(struct('counts', 0, 'FA', 0), size(target_codes, 2), 1);

% go through the whole log-file
for t = 1:timepoints;
    
    % find out whether event at t is a target or standard or neither
    target_type = 0;
    standard_type = 0;
    for targ = 1:num_of_targets      
        for i = 1:size(target_codes{targ}, 2)
            if strcmp(lfi.codes{t}, target_codes{targ}{i})
                target_type = targ;
            end
        end
    end
    for stand = 1:num_of_standards      
        for i = 1:size(standard_codes{stand}, 2)
            if strcmp(lfi.codes{t}, standard_codes{stand}{i})
                standard_type = stand;
            end
        end
    end
    
    % process one target or standard
    % data may be lost here
    if (target_type ~= 0),
        [ts flags] = score_target(lfi, t, ts, target_type, flags, nlog);
        
    elseif (standard_type ~= 0),
        [ss flags] = score_standard(lfi, t, ss, standard_type, flags, nlog);
        
    end % processing one target or standard
    
end; % stepping through events
return




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cts, css] = compute_values(ts, ss)
% calculate summarized values per target condition
% ts = counts, corr, incorr, RT[]
% cs stands for cumulative_stats, cs = num_of_targets, sum(RT), ...

% define some variables
global target_codes standard_codes;
num_of_targets = size(target_codes, 2);
num_of_standards = size(standard_codes, 2);

cts = struct('total_count', 0, 'count', [], 'mean_RT', [], 'sum_RT', [], 'sum_RT2', [], 'corr', [], ...
    'incorr', [], 'perc_corr', [], 'perc_incorr', [] );
css = struct('total_count', 0, 'count', [], 'total_FA', 0, 'FA', []);

for target_type = 1 : num_of_targets
    cts.total_count = cts.total_count + ts(target_type).counts;
    cts.count(target_type) = ts(target_type).counts;
    
    cts.mean_RT(target_type) = mean( ts(target_type).RT(:) );
    cts.sum_RT(target_type) = sum( ts(target_type).RT(:) );
    cts.sum_RT2(target_type) = sum( (ts(target_type).RT(:)).^2 );
    
    cts.corr(target_type) = ts(target_type).corr;
    cts.incorr(target_type) = ts(target_type).incorr;
    
    % avoid / by zero
    if ts(target_type).counts > 0
        cts.perc_corr(target_type) = (ts(target_type).corr/ts(target_type).counts) * 100;
        cts.perc_incorr(target_type) = (ts(target_type).incorr/ts(target_type).counts) * 100;
    else
        cts.perc_corr(target_type) = 0;
        cts.perc_incorr(target_type) = 0;
    end
end

% do for standards also
for standard_type = 1 : num_of_standards
    css.total_count = css.total_count + ss(standard_type).counts;
    css.count(standard_type) = ss(standard_type).counts;
    css.total_FA = css.total_FA + ss(standard_type).FA;
    css.FA(standard_type) = ss(standard_type).FA;
end;
return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nothing = write_values_standard(opf, ss, pres_logfile_name)

% define some variables
global standard_names standard_codes;
num_of_standards = size(standard_codes, 2);

% print logfile name
fprintf(opf, 'Standards:\t%d\r\n', ss.total_count);
for standard_type = 1 : num_of_standards 
    if ss.count(standard_type) > 0
        fprintf(opf, '%s\t%d\r\n', standard_names{standard_type}, ss.count(standard_type));
    end 
end
fprintf(opf, '\r\n');

fprintf(opf, 'False Alarms:\r\n');
for standard_type = 1 : num_of_standards 
    if ss.count(standard_type) > 0
        fprintf(opf, '%s\t%d\r\n', standard_names{standard_type}, ss.FA(standard_type));
    end 
end
fprintf(opf, '\r\n');
fprintf(opf, '\r\n');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nothing = write_values_target(opf, cs, pres_logfile_name)

% define some variables
global target_names target_codes;
num_of_targets = size(target_codes, 2);

% print logfile name
fprintf(opf, 'Logfile:\t%s\r\n\r\n', pres_logfile_name);

fprintf(opf, 'Targets:\t%d\r\n', cs.total_count);
for target_type = 1 : num_of_targets 
    if cs.count(target_type) > 0
        fprintf(opf, '%s\t%d\r\n', target_names{target_type}, cs.count(target_type));
    end 
end
fprintf(opf, '\r\n');

fprintf(opf, 'Correct Responses:\r\n');
for target_type = 1 : num_of_targets
    if cs.count(target_type) > 0
        fprintf(opf, '%s\t%d\r\n', target_names{target_type}, cs.corr(target_type));
    end
end
fprintf(opf, '\r\n');

fprintf(opf, 'Incorrect Responses:\r\n');
for target_type = 1 : num_of_targets
    if cs.count(target_type) > 0
        fprintf(opf, '%s\t%d\r\n', target_names{target_type}, cs.incorr(target_type));
    end
end
fprintf(opf, '\r\n');

fprintf(opf, 'Percent Correct:\r\n');
for target_type = 1 : num_of_targets 
    if cs.count(target_type) > 0
        fprintf(opf, '%s\t%3.2f\r\n', target_names{target_type}, cs.perc_corr(target_type));
    end
end 
fprintf(opf, '\r\n');

fprintf(opf, 'Percent Incorrect:\r\n');
for target_type = 1 : num_of_targets
    if cs.count(target_type) > 0
        fprintf(opf, '%s\t%3.2f\r\n', target_names{target_type}, cs.perc_incorr(target_type));
    end
end
fprintf(opf, '\r\n');


fprintf(opf, 'mean RT:\r\n');
for target_type = 1 : num_of_targets
    if cs.count(target_type) > 0
        fprintf(opf, '%s\t%3.2f\r\n', target_names{target_type}, cs.mean_RT(target_type));
    end 
end
fprintf(opf, '\r\n');

fprintf(opf, 'estimator of population SD of RT:\r\n');
for target_type = 1 : num_of_targets
    if cs.count(target_type) > 0
        num = cs.corr(target_type);
        mean = cs.mean_RT(target_type);
        sum = cs.sum_RT(target_type);
        sum_sq = cs.sum_RT2(target_type);
        Var = (sum_sq - 2*mean*sum + num*mean*mean)/(num-1);
        fprintf(opf, '%s\t%3.2f\r\n', target_names{target_type}, sqrt(Var));
    end 
end 


fprintf(opf, '\r\n');
fprintf(opf, '\r\n');
fprintf(opf, '\r\n');
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tss, sss] = summarize_results(csa, ssa)
% finally, summarize the results for a condition
% each condition contains results averaged across the specified trials
% returns tss, sss, which is summary of statistics

% define some variables
global target_names target_codes standard_names standard_codes condition name_condition;

num_of_standards = size(standard_codes, 2);
num_of_targets = size(target_codes, 2);
num_of_conditions = size(condition, 2);

for curr_cond = 1:num_of_conditions % for each condition
    
    % this will hold all of the info for the condition
    temp_cs = struct('count', [], 'mean_RT', [], 'sum_RT', [], 'sum_RT2', [], 'corr', [], ...
        'incorr', [], 'perc_corr', [], 'perc_incorr', [] );
    temp_ss = struct('count', [], 'FA', []);
    
    % get the numbers of the runs being averaged together
    start_on = sum(condition(1:curr_cond-1)) + 1; 
    log_range = start_on:condition(curr_cond) + start_on - 1; 
    
    for i = 1:num_of_targets
        
        % add together the results
        temp_cs.count(i) = 0;
        temp_cs.corr(i) = 0;
        temp_cs.incorr(i) = 0;
        temp_cs.sum_RT(i) = 0;
        temp_cs.sum_RT2(i) = 0;
        for j = log_range
            temp_cs.count(i) = temp_cs.count(i) + csa(j).count(i);
            temp_cs.corr(i) = temp_cs.corr(i) + csa(j).corr(i);
            temp_cs.incorr(i) = temp_cs.incorr(i) + csa(j).incorr(i);
            temp_cs.sum_RT(i) = temp_cs.sum_RT(i) + csa(j).sum_RT(i);
            temp_cs.sum_RT2(i) = temp_cs.sum_RT2(i) + csa(j).sum_RT2(i);
        end
        
        % weighted avg of RT's and perc.
        temp_cs.mean_RT(i) = temp_cs.sum_RT(i) ./ temp_cs.corr(i);
        
        % do not div by zero
        if (temp_cs.count(i) ~= 0)
            temp_cs.perc_corr(i) = (temp_cs.corr(i) ./ temp_cs.count(i)) * 100;
            temp_cs.perc_incorr(i) = (temp_cs.incorr(i) ./ temp_cs.count(i)) * 100;
        else
            temp_cs.perc_corr(i) = 0;
            temp_cs.perc_incorr(i) = 0;
        end
        
    end
    tss(curr_cond) = temp_cs;
    
    % do the standards
    for i = 1:num_of_standards
        % add together the results
        temp_ss.count(i) = 0;
        temp_ss.FA(i) = 0;
        for j = log_range
            temp_ss.count(i) = temp_ss.count(i) + ssa(j).count(i);
            temp_ss.FA(i) = temp_ss.FA(i) + ssa(j).FA(i);
        end;
    end; % standards
    sss(curr_cond) = temp_ss;
end; % condition
return
    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nothing = print_results(tss, sss, tsa, ssa, sn)
% finally, summarize the results for a condition

% define some variables
global target_names target_codes standard_names standard_codes condition name_condition compound_names ...
    compound_targets root_dir SubjectID log_filenames;
num_of_targets = size(target_codes, 2);
num_of_standards = size(standard_codes, 2);

for i = 1:size(condition, 2)
    % open an ANOVA file
    anovafile = sprintf('%s\\%sANOVA_RT.log', root_dir, name_condition{i});
    afid = fopen(anovafile, 'a');
    fprintf(afid, '%s\t', SubjectID{sn}); 
    
    anovafile = sprintf('%s\\%sANOVA_ER.log', root_dir, name_condition{i});
    afid2 = fopen(anovafile, 'a');
    fprintf(afid2, '%s\t', SubjectID{sn}); 
    
    anovafile = sprintf('%s\\%sANOVA_PC.log', root_dir, name_condition{i});
    afid3 = fopen(anovafile, 'a');
    fprintf(afid3, '%s\t', SubjectID{sn}); 

    anovafile = sprintf('%s\\%sANOVA_FA.log', root_dir, name_condition{i});
    afid4 = fopen(anovafile, 'a');
    fprintf(afid4, '%s\t', SubjectID{sn}); 
    
    % for each subject, a result file will be written containing the values for each run...
    resultfile = sprintf('%s\\%s\\%s%sResults.log', root_dir, SubjectID{sn}, SubjectID{sn}, name_condition{i});
    opf = fopen(resultfile,'w'); % open resultfile and enable writing to it
    
    % write the data from the runs in the condition runs
    start_on = sum(condition(1:i-1)) + 1; 
    log_range = start_on:condition(i) + start_on - 1; 
    for j = log_range
        write_values_target(opf, tsa(j), log_filenames{j});
        write_values_standard(opf, ssa(j), log_filenames{j});
    end 
    
    % print averaged results per condition
    fprintf(opf, '\r\n\r\nCondition %s\r\n\r\n', name_condition{i});
    
    for j = 1 : num_of_targets
        if tss(i).count(j) > 0
            num = tss(i).corr(j);
            mean = tss(i).mean_RT(j);
            fprintf(opf, 'Results for: %s\r\n', target_names{j});
            fprintf(opf, '# of Targets: \t%d\r\n', tss(i).count(j));
            fprintf(opf, '# Correct: \t%d\r\n', num);
            fprintf(opf, '# Incorrect: \t%d\r\n', tss(i).incorr(j));
            fprintf(opf, '%% correct: \t%3.2f\r\n', tss(i).perc_corr(j));
            fprintf(opf, '%% incorrect: \t%3.2f\r\n', tss(i).perc_incorr(j));
            fprintf(afid2, '%3.2f\t', 100-tss(i).perc_corr(j));
            fprintf(afid3, '%3.2f\t', tss(i).perc_corr(j));
            fprintf(opf, 'RT: \t\t%3.2f\r\n\', mean);
            fprintf(afid, '%3.2f\t', mean);
            sum = tss(i).sum_RT(j);
            sum_sq = tss(i).sum_RT2(j);
            Var = (sum_sq - 2*mean*ssum + num*mean*mean)/(num-1);
            fprintf(opf, 'Est of SD:\t%3.2f\r\n\r\n', sqrt(Var));
        else
            fprintf(afid, 'X\t');
            fprintf(afid2, 'X\t');
            fprintf(afid3, 'X\t');
            fprintf(opf, 'Results for: %s\r\n', target_names{j});
            fprintf(opf, '# of Targets: \t%d\r\n\r\n', tss(i).count(j));
        end
    end
    
    for j = 1 : num_of_standards
        if sss(i).count(j) > 0
            fprintf(opf, 'Results for: %s\r\n', standard_names{j});
            fprintf(opf, '# of Standards: \t%d\r\n', sss(i).count(j));
            fprintf(opf, '# False Alarms: \t%d\r\n', sss(i).FA(j));
            fprintf(afid4, '%d\t', sss(i).FA(j));
            fprintf(opf, '# Correct Rejections: \t%d\r\n\r\n', sss(i).count(j)-sss(i).FA(j));
        else
            fprintf(opf, 'Results for: %s\r\n', standard_names{j});
            fprintf(opf, '# of Targets: \t%d\r\n\r\n', sss(i).count(j));
            fprintf(afid4, 'X\t');
        end
    end
    
    for j = 1 : size(compound_names, 2)
        
        targets = compound_targets{j};
        % sum the results across all tthe targets in the compound target
        sum_counts = 0;
        sum_corr = 0;
        sum_incorr = 0;
        sum_sum_RT = 0;
        sum_sum_RT2 = 0;
        for k = targets
            sum_counts = sum_counts + tss(i).count(k);
            sum_corr = sum_corr + tss(i).corr(k);
            sum_incorr = sum_incorr + tss(i).incorr(k);
            sum_sum_RT = sum_sum_RT + tss(i).sum_RT(k);
            sum_sum_RT2 = sum_sum_RT2 + tss(i).sum_RT2(k);
        end
        
        % print the compound target
        if sum_counts > 0
            
            fprintf(opf, 'Results for: %s\r\n', compound_names{j});
            fprintf(opf, '# of Targets: \t%d\r\n', sum_counts);
            fprintf(opf, '# Correct: \t%d\r\n', sum_corr);
            fprintf(opf, '# Incorrect: \t%d\r\n', sum_incorr);
            
            fprintf(opf, '%% correct: \t%3.2f\r\n', (sum_corr / sum_counts) * 100);
            fprintf(opf, '%% incorrect: \t%3.2f\r\n', (sum_incorr / sum_counts) * 100);
            
            mean = sum_sum_RT / sum_corr;
            fprintf(opf, 'RT: \t\t%3.2f\r\n\', mean);
            
            Var = (sum_sum_RT2 - 2*mean*sum_sum_RT + sum_corr*mean*mean)/(sum_corr-1);
            fprintf(opf, 'Est of SD:\t%3.2f\r\n\r\n', sqrt(Var));
            
        else
            fprintf(opf, 'Results for: %s\r\n', compound_names{j});
            fprintf(opf, '# of Targets: \t%d\r\n\r\n', sum_counts);
        end
        fprintf(afid, '%3.2f\t', mean);
        fprintf(afid2, '%3.2f\t', ((1-(sum_corr / sum_counts)) * 100));
        fprintf(afid3, '%3.2f\t', (sum_corr / sum_counts) * 100);
            
    end
    fprintf(afid, '\r\n');
    fprintf(afid2, '\r\n');
    fprintf(afid3, '\r\n');
    fprintf(afid4, '\r\n');
    fclose('all');
end
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = decode_error(le, te)
% will return nonzero if the te string is a substring of the le string
% used for testing the type of the last error

lte = length(te);
lle = length(le);

for i = 1:lle-lte+1
    if (sum(le(i:i+lte-1) == te) == lte)
        retval = 1;
        return
    end
end

retval = 0;
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = which_condition(run_num)
% returns the condition that the run is in

global condition;

counter = 1;
for i = 1:size(condition, 2)
    if ismember(run_num, counter:counter+condition(i)-1)
        retval = i;
        return
    end
    counter = counter + condition(i);
end
retval = 0;
return 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ts, flags] = score_target(lfi, tt, ts, target_type, flags, nlog)
% scores one target
% arguments are logfile info, target time, target struct, target type

global target_codes response_codes min_RT max_RT;

% define some variables
num_of_targets = size(target_codes, 2);
temp_RT = 0;
timepoints = lfi.num_events;

ts(target_type).counts = ts(target_type).counts + 1;
target_time = lfi.times(tt);                    % get the time of the current code
stop = 0;		% if this is 1, the loop will stop
i = 1;         % this will count events succeeding the target 

% look for one response to the target by checking each successive event within max_RT
while (tt+i <= timepoints) & (lfi.times(tt+i)-target_time < max_RT) & (stop ~= 1) 
    
    % check if (t+i)th entry is the correct response, and has not yet been used
    if (strcmp(lfi.codes{tt+i}, response_codes{which_condition(nlog)}{target_type})) & (flags(tt+i) == 0) & (lfi.times(tt+i)-target_time > min_RT)
        temp_RT = lfi.times(tt+i) - target_time;   
        ts(target_type).corr = ts(target_type).corr + 1;
        ts(target_type).RT = cat(2, ts(target_type).RT, temp_RT); 
        flags(tt+i) = 1;  % set flag to 1 for each "used" response
        stop = 1;   
        
        % check if next entry might be an incorrect response    
    elseif (lfi.times(tt+i)-target_time > min_RT)
        for other_targs = 1:num_of_targets % check all the available "wrong" responses that correspond to other target_types
            if (strcmp(lfi.codes{tt+i}, response_codes{which_condition(nlog)}{other_targs})) & (flags(tt + i) == 0) 
                %ts(target_type).incorr = ts(target_type).incorr + 1; % increment counts for incorrect responses
                %count it as correct if it is a response at all
                ts(target_type).corr = ts(target_type).corr + 1;
                flags(tt+i) = 1; % set flags for used responses
                stop = 1;
            end
        end
    else
        % ignore if the stimulus is before min_RT     
    end
    i = i+1;
end % while looking for response  
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ss, flags] = score_standard(lfi, st, ss, standard_type, flags, nlog)
% scores one standard
% scores one target
% arguments are logfile info, time of standard, standard struct, target type

global standard_codes min_RT max_RT;

% define some variables
num_of_standards = size(standard_codes, 2);
timepoints = lfi.num_events;

ss(standard_type).counts = ss(standard_type).counts + 1;
target_time = lfi.times(st);                    % get the time of the current code
stop = 0;		% if this is 1, the loop will stop
i = 1;         % this will count events succeeding the target 

% look for one response to the target by checking each successive event within max_RT
while (st+i <= timepoints) & (lfi.times(st+i)-target_time < max_RT) & (stop ~= 1) 
    
    % check if (t+i)th entry is any response, and has not yet been used,
    % and is greater than min_RT
    if (strcmp(lfi.types{st+i}, 'Response')) & (flags(st+i) == 0) & (lfi.times(st+i)-target_time > min_RT)
        ss(standard_type).FA = ss(standard_type).FA + 1;
        flags(st+i) = 1;  % set flag to 1 for each "used" response
        stop = 1;   
    else
        % ignore if the stimulus is before min_RT     
    end
    i = i+1;
end % while looking for response  
return;

