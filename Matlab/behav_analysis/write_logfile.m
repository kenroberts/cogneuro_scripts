function nothing = write_logfile_str(varargin)
%
% This function writes a logfile struct to a file in the 
% presentation logfile format.
%
% the use is
% lfs = write_logfile(lfs, 'C:\myexp\filename.log');
%
% where lfs is a logfile struct, as read in by read_logfile.
%
% If a filename is not supplied, you will be prompted to select a .log
% file to save it as:
%
% lfs = write_logfile(lfs);

% Advanced notes: We have a struct that we wish to write into a
% presentation-style logfile.  We should expect from the beginning that
% no field not listed in the 'colnames' field will be written to disk.
% Every 'colname' should have a corresponding field, with duplicate 
% colnames being resolved by appending _2, _3, and so forth onto the second, 
% third and so on instances of a column.  Also, the second-last line of the 
% header will be recreated to match the column names as they appear 
%
% Ken Roberts

% get the fully qualified path into filename
if nargin < 2
    lfs = varargin{1};
    [filename, pathname] = uiputfile({'*.log', 'Log file (*.log)'}, 'Save the log file as ...');
    if ~filename %make sure user didnt cancel
        return;
    end;
    filename = [pathname, filename];
else
    lfs = varargin{1};
    [pathname, f1, f2] = fileparts(varargin{2});
    filename = [f1 f2];
    if ~isempty(pathname) 
        if (pathname(end) ~= filesep)
            filename = [pathname, filesep, filename];
        else
            filename = [pathname, filename];
        end;
    else
        filename = [pwd, filesep, filename];
    end;
end;

% name of each error check to apply
req_names = {...
    sprintf('File %s already exists, please choose another filename', filename) ...
    };

% form a matrix of tests composed of individual error check
req_cond(1) = (exist(filename) == 0);

% Assert each name in colnames corresponds to a field
hfields = get_fieldnames(lfs.colnames);
col_lengths = [];
for i = 1:length(hfields)
    if ~isfield(lfs, hfields{i}),
        error(sprintf('There is no field named %s in the struct.', hfields{i}));
    end;
    col_lengths(i) = length(getfield(lfs, hfields{i}));
end;

% Assert that all cols are same length
if any(col_lengths(1) ~= col_lengths(2:end))
    fprintf('Name (length): ');
    for i = 1:length(hfields)
        fprintf('%s (%f) ', hfields(i), col_lengths(i));
    end;
    error('All columns must have the same length.');
end;

% test all of the required conditions, and print all test case failures.
if ~all(req_cond)
    ind = find(req_cond == 0);
    error(strcat(req_names{ind}));
end;

fprintf('Writing: %s\n', filename);
try,
    fid = fopen(filename, 'w');
catch
    lasterr
    error('Could not write to file.');
end;
    
% (Presentation-specific) write header, first redoing the end-1 line to hold the colnames
lfs.header{end-1} = deblank(sprintf('%s\t', char(lfs.colnames)'));
for j = 1:length(lfs.header)
    fprintf(fid, '%s\r\n', lfs.header{j});
end;

% write body, 

% first, horzcat each of the cells together (TODO, manipulate columns if
% they are not cellstrs.
big_cell = lfs.(hfields{1});
for j = 2:length(hfields)
    big_cell = horzcat(big_cell, lfs.(hfields{j}));
end;

% then, form a tab-delimited string
% representing one line to be written out.  This should preserve multiple
% tab characters if there are not interstitial fields.
for j = 1:size(big_cell, 1)
    for k = 1:size(big_cell, 2)
        fprintf(fid, '%s\t', char(big_cell{j, k}));
    end;    
    fprintf(fid, '\r\n');
end;
    
% write footer
if ~isempty(lfs.footer)
    for j = 1:length(lfs.footer)
        fprintf(fid, '%s\r\n', lfs.footer{j});
    end;
end;

fclose(fid);

return; 



%%% NOT USED %%%

% write file
for j = 1:length(lfs.trial)
	
    % print 1st six fields
	fprintf(fid, '%d\t%s\t%s\t', lfs.trial(j), lfs.type{j}, lfs.code{j});
    fprintf(fid, '%d\t%d\t%d\t', lfs.time(j), lfs.ttime(j), lfs.t_uncer(j));
    
    % print remaining depending on type
    switch lower(lfs.type{j})
        case 'picture'
            fprintf(fid, '%d\t%d\t%d\t%s\n', lfs.dur(j), lfs.d_uncer(j), lfs.req_time(j), lfs.req_dur{j});
        case 'sound'
            fprintf(fid, '%d\n', lfs.dur(j));
        case 'response'
            fprintf(fid, '\n');
        otherwise
            error(sprintf('No support yet for files with type %s', lfs.type{j}));
    end; %switch
    
end; % for j

fclose(fid);

return;

%%% END NOT USED %%%


% change colnames into field names for the struct which have a few restrictions:
% they cannot have spaces, they should be lower case, and the names can't
% be duplicated (like "Uncertainty" usually appears twice.)
function fieldnames = get_fieldnames(colnames)

% field names should be lower case and no spaces
fieldnames = strrep(lower(colnames), {' '}, {'_'});

% they should be unique too (by adding 2, 3, etc onto duplicate names)
[unique_fields, unique_ind, equiv_ind] = unique(fieldnames);
for i = 1:length(unique_fields)
    % find all of a given type
    temp = find(equiv_ind == i);
    for j = 2:length(temp)
        fieldnames{temp(j)} = sprintf('%s_%d', fieldnames{temp(j)}, j);  
    end;
end;
return;