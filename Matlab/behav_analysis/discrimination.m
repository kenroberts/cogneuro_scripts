function nothing = discrimination
% This function is called by the analyze.m script
% It goes through Presentation logfiles specified in edit_vars.m
% and writes one output file per subject per condition with
% targets, correct & incorrect responses, % correct, % incorrect, RT.
% These variables are calculated per run and averaged per condition
% Laura Busse
% Ken Roberts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% changelog
%
% 8/5/02		KCR	Modified count_responses.  For each target, looks for 
%						a response within max_RT, no longer limited to looking 
%						ahead only a certain number of events.
%
% 8/5/02		KCR	Fixed a bug in which_condition where the conditions were hard-coded.
%
% 8/7/02		KCR, SF  Revised program to accept strings as valid target and response codes.   
%
% 8/7/02		KCR	Added a min_RT variable
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
global root_dir anova_dir SubjectID use_subjectID log_filenames min_RT max_RT ...
    target_codes target_names compound_names name_condition condition SD_factor new_min_RT new_max_RT;

% deletes old Anova SUMMARY FILES
num_of_conditions = size(condition, 2);
anovafiles = { 'ANOVA_RT.log' 'ANOVA_ER.log' 'ANOVA_PC.log' };
if (isempty(anova_dir))
    anova_dir = root_dir;
end

for i = 1:num_of_conditions
    for j = 1:length(anovafiles)
        % delete the file
        anovafile = fullfile(anova_dir, [name_condition{i}, anovafiles{j}] );
        delete(anovafile);
        fid = fopen(anovafile,'w');
        
        if ~fid
            error('Could not open %s for writing.', anovafile);
        else
            fprintf('Opening %s for writing.\n', anovafile);
        end;
        
        % make the names
        fprintf(fid, '\t');
        for k = 1:length(target_names)
            fprintf(fid, '%s\t', target_names{k});
        end
        for k = 1:length(compound_names)
            fprintf(fid, '%s\t', compound_names{k});
        end
        fprintf(fid, '\r\n');
        fclose(fid);
    end;  
end



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
        run_info = count_responses(log_file_info, nlog);
        
        % from data in the run_info, compute average RT's and percentages and put in run_stats
        % run_stats is a single struct, not an array.
        run_stats = compute_values(run_info);
        
        % runs_stats_arr contains data from all runs
        run_stats_arr(nlog) = run_stats;
    end; % filenames
    
    % write a complete summary of the data
    % summary_stats is an array with information from each condition
    summary_stats = summarize_results(run_stats_arr);
    
    % calculate new min_RT and max_RT
    % for logfiles
    % count_resp, compute_values, end, summarize_results
    num_of_targets = size(target_codes, 2);
    num_of_conditions = size(condition, 2);
    new_min_RT = zeros(num_of_targets, num_of_conditions);
    new_max_RT = zeros(num_of_targets, num_of_conditions);
    for i = 1:num_of_conditions
        for j = 1:num_of_targets
            num = summary_stats(i).corr(j);
            mean = summary_stats(i).mean_RT(j);
            sum1 = summary_stats(i).sum_RT(j);
            sum_sq = summary_stats(i).sum_RT2(j);
            var = (sum_sq - 2*mean*sum1 + num*mean*mean)/(num-1);
            %We've changed this so that the user can control whether standard deviation or min_max_RT is used.
            if (exist('SD_factor') ~= 2 & ~isempty(SD_factor))
                new_min_RT(j, i) = mean - SD_factor*sqrt(var);
                new_max_RT(j, i) = mean + SD_factor*sqrt(var);
            else
                new_min_RT(j, i)=min_RT;
                new_max_RT(j, i)=max_RT;
            end;
            
        end;
        
    end;
    
    size(new_min_RT)
    new_min_RT
    size(new_max_RT)
    new_max_RT
    
    % calculate everything over again fi SD_factor is defined.
    if (exist('SD_factor') ~=2 & ~isempty(SD_factor))
        for nlog = 1: length(log_filenames) % all the logfiles
            if (use_subjectID == 0)
                pres_logfile_name = sprintf('%s\\%s\\%s.log', root_dir, SubjectID{sn}, log_filenames{nlog});
            else
                pres_logfile_name = sprintf('%s\\%s\\%s%s%s.log', root_dir, SubjectID{sn}, SubjectID{sn}, name_condition{1}, log_filenames{nlog});
            end
            log_file_info = open_logfile(pres_logfile_name);
            run_info = count_responses2(log_file_info, nlog);
            run_stats = compute_values(run_info);
            run_stats_arr(nlog) = run_stats;
        end
    end
    
    summary_stats = summarize_results(run_stats_arr);
    print_results(summary_stats, run_stats_arr, sn);
    
    
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
codes = {};
times = [];
fnf_emsg = 'File not found';

% the first readable line of the file SHOULD be within the first 20 lines
% this prevents an unending loop
while (stop == 0 & lines_to_skip < 20)
   try
      [trial, codes, times] = textread(filename, '%*d %d %*s %s %d %*[^\n]', 'headerlines', lines_to_skip);
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
function ts = count_responses(lfi, nlog)
% counts all of the responses to each target in one logfile

global target_codes response_codes min_RT max_RT;

% define some variables
num_of_targets = size(target_codes, 2);
flags = zeros(lfi.num_events, 1);
temp_RT = 0;
timepoints = lfi.num_events;


% array of target stats, each target stats holds info for one target
ts = repmat(struct('counts', 0, 'corr', 0, 'incorr', 0, 'RT', []), size(target_codes, 2), 1);

% go through the whole log-file
for t = 1:timepoints;
   
   % find out whether event at t is a target or not
   target_type = 0;
   for targ = 1:num_of_targets      
      for i = 1:size(target_codes{targ}, 2)
         if strcmp(lfi.codes{t}, target_codes{targ}{i})
            target_type = targ;
         end
      end
   end
   
   % process one target
   if (target_type ~= 0)
      
      ts(target_type).counts = ts(target_type).counts + 1;
      target_time = lfi.times(t);                    % get the time of the current code
      stop = 0;		% if this is 1, the loop will stop
      i = 1;         % this will count events succeeding the target 
      
      % look for one response to the target by checking each successive event within max_RT
      while (t+i <= timepoints) & (lfi.times(t+i)-target_time < max_RT) & (stop ~= 1) 
         
         % check if (t+i)th entry is the correct response, and has not yet been used
         %ansme = [10, (strcmp(lfi.codes{t+i}, response_codes{which_condition(nlog)}{target_type})), 11, (flags(t+i) == 0), 12, (lfi.times(t+i)-target_time > min_RT)]
         if (strcmp(lfi.codes{t+i}, response_codes{which_condition(nlog)}{target_type})) & (flags(t+i) == 0) & (lfi.times(t+i)-target_time > min_RT)
            temp_RT = lfi.times(t + i) - target_time;   
            ts(target_type).corr = ts(target_type).corr + 1;
            ts(target_type).RT = cat(2, ts(target_type).RT, temp_RT); 
            flags(t+i) = 1;  % set flag to 1 for each "used" response
            stop = 1;   
            
            % check if next entry might be an incorrect response    
         elseif (lfi.times(t+i)-target_time > min_RT)
            for other_targs = 1:num_of_targets % check all the available "wrong" responses that correspond to other target_types
               if (strcmp(lfi.codes{t+i}, response_codes{which_condition(nlog)}{other_targs})) & (flags(t + i) == 0) 
                  ts(target_type).incorr = ts(target_type).incorr + 1; % increment counts for incorrect responses
                  flags(t+i) = 1; % set flags for used responses
                  stop = 1;
               end
            end
         else
 				% ignore if the stimulus is before min_RT     
         end
         i = i+1;
      end % while looking for response               
      
   end % processing one target
   
 end; % stepping through events
   
return
   
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ts = count_responses2(lfi, nlog)
% counts all of the responses to each target in one logfile

global target_codes response_codes new_min_RT new_max_RT;

% define some variables
num_of_targets = size(target_codes, 2);
flags = zeros(lfi.num_events, 1);
temp_RT = 0;
timepoints = lfi.num_events;
cc = which_condition(nlog);


% array of target stats, each target stats holds info for one target
ts = repmat(struct('counts', 0, 'corr', 0, 'incorr', 0, 'RT', []), size(target_codes, 2), 1);

% go through the whole log-file
for t = 1:timepoints;
   
   % find out whether event at t is a target or not
   target_type = 0;
   for targ = 1:num_of_targets      
      for i = 1:size(target_codes{targ}, 2)
         if strcmp(lfi.codes{t}, target_codes{targ}{i})
            target_type = targ;
         end
      end
   end
   
   % process one target
   if (target_type ~= 0)
      
      ts(target_type).counts = ts(target_type).counts + 1;
      target_time = lfi.times(t);                    % get the time of the current code
      stop = 0;		% if this is 1, the loop will stop
      i = 1;         % this will count events succeeding the target 
      
      % look for one response to the target by checking each successive event within max_RT
      while (t+i <= timepoints) & (lfi.times(t+i)-target_time < new_max_RT(target_type, cc)) & (stop ~= 1) 
         
         % check if (t+i)th entry is the correct response, and has not yet been used
         %ansme = [10, (strcmp(lfi.codes{t+i}, response_codes{which_condition(nlog)}{target_type})), 11, (flags(t+i) == 0), 12, (lfi.times(t+i)-target_time > min_RT)]
         if (strcmp(lfi.codes{t+i}, response_codes{cc}{target_type})) & (flags(t+i) == 0) & (lfi.times(t+i)-target_time > new_min_RT(target_type, cc))
            temp_RT = lfi.times(t + i) - target_time;   
            ts(target_type).corr = ts(target_type).corr + 1;
            ts(target_type).RT = cat(2, ts(target_type).RT, temp_RT); 
            flags(t+i) = 1;  % set flag to 1 for each "used" response
            stop = 1;   
            
            % check if next entry might be an incorrect response    
         elseif (lfi.times(t+i)-target_time > new_min_RT(target_type, cc))
            for other_targs = 1:num_of_targets % check all the available "wrong" responses that correspond to other target_types
               if (strcmp(lfi.codes{t+i}, response_codes{cc}{other_targs})) & (flags(t + i) == 0) 
                  ts(target_type).incorr = ts(target_type).incorr + 1; % increment counts for incorrect responses
                  flags(t+i) = 1; % set flags for used responses
                  stop = 1;
               end
            end
         else
 				% ignore if the stimulus is before min_RT     
         end
         i = i+1;
      end % while looking for response               
   end % processing one target
 end; % stepping through events
 return
 
 
 
 
   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cs = compute_values(ts)
% calculate summarized values per target condition
% ts = counts, corr, incorr, RT[]
% cs stands for cumulative_stats, cs = num_of_targets, sum(RT), ...

% define some variables
global target_codes;
num_of_targets = size(target_codes, 2);

cs = struct('total_count', 0, 'count', [], 'mean_RT', [], 'sum_RT', [], 'sum_RT2', [], 'corr', [], ...
   'incorr', [], 'perc_corr', [], 'perc_incorr', [] );

for target_type = 1 : num_of_targets
   cs.total_count = cs.total_count + ts(target_type).counts;
   cs.count(target_type) = ts(target_type).counts;
   
   cs.mean_RT(target_type) = mean( ts(target_type).RT(:) );
   cs.sum_RT(target_type) = sum( ts(target_type).RT(:) );
   cs.sum_RT2(target_type) = sum( (ts(target_type).RT(:)).^2 );
   
   cs.corr(target_type) = ts(target_type).corr;
   cs.incorr(target_type) = ts(target_type).incorr;
   
   % avoid / by zero
   if ts(target_type).counts > 0
      cs.perc_corr(target_type) = (ts(target_type).corr/ts(target_type).counts) * 100;
      cs.perc_incorr(target_type) = (ts(target_type).incorr/ts(target_type).counts) * 100;
   else
      cs.perc_corr(target_type) = 0;
      cs.perc_incorr(target_type) = 0;
   end
end
return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nothing = write_values(opf, cs, pres_logfile_name)

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
      sum1 = cs.sum_RT(target_type);
      sum_sq = cs.sum_RT2(target_type);
      Var = (sum_sq - 2*mean*sum1 + num*mean*mean)/(num-1);
      fprintf(opf, '%s\t%3.2f\r\n', target_names{target_type}, sqrt(Var));
   end 
end 


fprintf(opf, '\r\n');
fprintf(opf, '\r\n');
fprintf(opf, '\r\n');
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ss = summarize_results(csa)
% finally, summarize the results for a condition
% each condition contains results averaged across the specified trials
% returns ss, which is summary of statistics

% define some variables
global target_names target_codes condition name_condition;
num_of_targets = size(target_codes, 2);

num_of_conditions = size(condition, 2);

for curr_cond = 1:num_of_conditions % for each condition
   
   % this will hold all of the info for the condition
   temp_cs = struct('total_count', 0, 'count', [], 'mean_RT', [], 'sum_RT', [], 'sum_RT2', [], 'corr', [], ...
      'incorr', [], 'perc_corr', [], 'perc_incorr', [] );
   
   % get the numbers of the runs being averaged together
   start_on = sum(condition(1:curr_cond-1)) + 1; 
   log_range = start_on:condition(curr_cond) + start_on - 1; 
   
   % sum the total counts   
   temp_cs.total_count = sum( cat(1, csa(log_range).total_count));
   
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
   
   ss(curr_cond) = temp_cs;
   
end
return



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nothing = print_results(ss, csa, sn)
% finally, summarize the results for a condition

% define some variables
global target_names target_codes condition name_condition compound_names ...
    compound_targets root_dir SubjectID log_filenames;
num_of_targets = size(target_codes, 2);


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
    
    % for each subject, a result file will be written containing the values for each run...
    resultfile = sprintf('%s\\%s\\%s%sResults.log', root_dir, SubjectID{sn}, SubjectID{sn}, name_condition{i});
    opf = fopen(resultfile,'w'); % open resultfile and enable writing to it
    
    % write the data from the runs in the condition runs
    start_on = sum(condition(1:i-1)) + 1; 
    log_range = start_on:condition(i) + start_on - 1; 
    for j = log_range
        write_values(opf, csa(j), log_filenames{j});
    end 
    
    % print averaged results per condition
    fprintf(opf, '\r\n\r\nCondition %s\r\n\r\n', name_condition{i});
    
    for j = 1 : num_of_targets
        if ss(i).count(j) > 0
            num = ss(i).corr(j);
            mean1 = ss(i).mean_RT(j);
            fprintf(opf, 'Results for: %s\r\n', target_names{j});
            fprintf(opf, '# of Targets: \t%d\r\n', ss(i).count(j));
            fprintf(opf, '# Correct: \t%d\r\n', num);
            fprintf(opf, '# Incorrect: \t%d\r\n', ss(i).incorr(j));
            fprintf(opf, '%% correct: \t%3.2f\r\n', ss(i).perc_corr(j));
            fprintf(opf, '%% incorrect: \t%3.2f\r\n', ss(i).perc_incorr(j));
            
            fprintf(opf, 'RT: \t\t%3.2f\r\n', mean1);
            
            sum1 = ss(i).sum_RT(j);
            sum_sq = ss(i).sum_RT2(j);
            Var = (sum_sq - 2*mean1*sum1 + num*mean1*mean1)/(num-1);
            fprintf(opf, 'Est of SD:\t%3.2f\r\n\r\n', sqrt(Var));
            
            fprintf(afid, '%3.2f\t', mean1);
            fprintf(afid2, '%3.2f\t', ss(i).perc_incorr(j));
            fprintf(afid3, '%3.2f\t', ss(i).perc_corr(j));
        else
            fprintf(afid, 'X\t');
            fprintf(afid2, 'X\t');
            fprintf(afid3, 'X\t');
            fprintf(opf, 'Results for: %s\r\n', target_names{j});
            fprintf(opf, '# of Targets: \t%d\r\n\r\n', ss(i).count(j));
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
            sum_counts = sum_counts + ss(i).count(k);
            sum_corr = sum_corr + ss(i).corr(k);
            sum_incorr = sum_incorr + ss(i).incorr(k);
            sum_sum_RT = sum_sum_RT + ss(i).sum_RT(k);
            sum_sum_RT2 = sum_sum_RT2 + ss(i).sum_RT2(k);
        end
        
        % print the compound target
        if sum_counts > 0
            
            fprintf(opf, 'Results for: %s\r\n', compound_names{j});
            fprintf(opf, '# of Targets: \t%d\r\n', sum_counts);
            fprintf(opf, '# Correct: \t%d\r\n', sum_corr);
            fprintf(opf, '# Incorrect: \t%d\r\n', sum_incorr);
            
            fprintf(opf, '%% correct: \t%3.2f\r\n', (sum_corr / sum_counts) * 100);
            fprintf(opf, '%% incorrect: \t%3.2f\r\n', (sum_incorr / sum_counts) * 100);
            
            
            mean1 = sum_sum_RT / sum_corr;
            fprintf(opf, 'RT: \t\t%3.2f\r\n', mean1);
            
            Var = (sum_sum_RT2 - 2*mean1*sum_sum_RT + sum_corr*mean1*mean1)/(sum_corr-1);
            fprintf(opf, 'Est of SD:\t%3.2f\r\n\r\n', sqrt(Var));
            
            fprintf(afid, '%3.2f\t', mean1);
            fprintf(afid2, '%3.2f\t', (sum_incorr / sum_counts) * 100);
            fprintf(afid3, '%3.2f\t', (sum_corr / sum_counts) * 100);
            
        else
            fprintf(afid, 'X\t');
            fprintf(afid2, 'X\t');
            fprintf(afid3, 'X\t');
            fprintf(opf, 'Results for: %s\r\n', compound_names{j});
            fprintf(opf, '# of Targets: \t%d\r\n\r\n', sum_counts);
        end
    end
    fprintf(afid, '\r\n');
    fprintf(afid2, '\r\n');
    fprintf(afid3, '\r\n');
    fclose(opf);
    fclose(afid);    
    fclose(afid2);    
    fclose(afid3);  
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
%function get_ANOVA_stats(ss)
