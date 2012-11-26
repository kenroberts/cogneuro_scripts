function nothing = verifier(varargin);
% this will verify an edit_vars file.
% the (optional) argument to this function is an array containing 0's and 1's 
% which will allow you to selectively skip certain parts of the verification process.
% the order of the array is:
% - checks for existence of files in log_filenames
% - checks conditions
% - checks targets
% - checks compound targets
% - checks RT bounds
% 
% for example, verifier([1 0 0 0 0]) will only check for the existence of the logfiles,
% and verifier([1 1 1 0 1]) will check everything except for compound targets.

if size(varargin, 1) > 0
   check_flags = varargin{1};
else
   check_flags = [1 1 1 1 1];
end

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
   trial_ID;

DEBUG = 0;

%%%%%%%%%%%%%%%%%%
% check filenames
%%%%%%%%%%%%%%%%%%
if (check_flags(1))
   for i = 1:size(SubjectID, 2)
      for j = 1:size(log_filenames, 2)
         
         subject = SubjectID{i};
         logfile = log_filenames{j};
         
         if (use_subjectID)
            filename = fullfile(root_dir, subject, [subject logfile '.log']);
         else
            filename = fullfile(root_dir, subject, [logfile '.log']);
         end
         
         if (DEBUG)
            fprintf('Verifying: %s\n', filename);
         end
         
         % try to open file
         try
            opf = fopen(filename, 'r');
            fclose(opf);
         catch
            fprintf('Could not find the file %s', filename);   
         end
      end
   end
end


%%%%%%%%%%%%%%%%%%
%check condition
%%%%%%%%%%%%%%%%%%
if (check_flags(2))
   
   % checking condition against logfiles
   if (sum(condition, 2) ~= size(log_filenames, 2))
      message = 'Your condition and log_files variables do not match.\n';
      message = [message 'The runs in the condition variable sum to ' num2str(sum(condition, 2)) '\n'];
      message = [message 'The log_files variable has ' num2str(size(log_filenames, 2)) ' files.\n'];
      fprintf(message);
   end
   
   % checking condition against name_condition
   if (size(condition, 2) ~= size(name_condition, 2))
      message = 'Your condition and name_condition variables do not match.\n';
      message = [message 'The condition variable has ' num2str(size(condition, 2)) ' conditions.\n'];
      message = [message 'The name_condition variable has ' num2str(size(name_condition, 2)) ' conditions.\n'];
      fprintf(message);
   end
   
   % checking condition against response_codes
   if (size(condition, 2) ~= size(response_codes, 2))
      message = 'Your condition and response_codes variables do not match.\n';
      message = [message 'The condition variable has ' num2str(size(condition, 2)) ' conditions.\n'];
      message = [message 'The response_codes variable specifies responses for ' num2str(size(response_codes, 2)) ' conditions.\n'];
      fprintf(message);
   end
end

%%%%%%%%%%%%%%%%%%%%%%
% check targets
%%%%%%%%%%%%%%%%%%%%%%
if (check_flags(3))
   
   % checking target_names against target_codes
   if (size(target_names, 2) ~= size(target_codes, 2))
      message = 'Your target_names and target_codes variables do not match.\n';
      message = [message 'The target_names variable has ' num2str(size(target_names, 2)) ' names.\n'];
      message = [message 'The target_codes variable has ' num2str(size(target_codes, 2)) ' codes.\n'];
      fprintf(message);
   end
   
   % checking target_names against response_codes for each condition
   for i = 1:size(condition, 2)
      if (size(target_names, 2) ~= size(response_codes{i}, 2))
         message = ['Your target_names and response_codes variables do not match for condition ' num2str(i) '\n'];
         message = [message 'The target_names variable has ' num2str(size(target_names, 2)) ' names.\n'];
         message = [message 'The response_codes variable has ' num2str(size(response_codes{i}, 2)) ' codes.\n'];
         fprintf(message);
      end
   end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%
% check compound targets
%%%%%%%%%%%%%%%%%%%%%%%%%%
if (check_flags(4))
   % checking compound_names against compound_targets
   if (size(compound_names, 2) ~= size(compound_targets, 2))
      message = 'Your compound_names and compound_targets variables do not match.\n';
      message = [message 'The compound_names variable has ' num2str(size(compound_names, 2)) ' names.\n'];
      message = [message 'The compound_targets variable has ' num2str(size(compound_targets, 2)) ' targets.\n'];
      fprintf(message);
   end
   
   % checking compound_targets against target_names
   num_targets = size(target_names, 2);
   for i = 1:size(compound_targets, 2)
      targs = compound_targets{i};
      for j = 1:size(targs, 2)
         if targs(j) > num_targets
            message = 'Your compound_targets refers to a target that is not in target_names.\n';
            message = [message 'The bad target was in spot ' num2str(j) ' of compound target ' num2str(i) '\n'];
            fprintf(message);
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% checking min_RT and max_RT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (check_flags(5))
   if min_RT < 0
      fprintf('min_RT cannot be less than zero. \n');
   end
   
   if min_RT > max_RT
      fprintf('min_RT cannot be greater than max_RT. \n');
   end
end

