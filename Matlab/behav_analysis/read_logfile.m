function [lfs] = read_logfile_str(varargin)
%
% This function reads in a logfile and returns a struct containing all of
% the information.  The struct has a header, containing the beginning lines of
% the logfile, a footer, containing the end of the log file, and a series
% of fields corresponding to each column of the middle portion of the
% logfile.
% A typical logfile struct may look something like this:
%
%          header: {'Scenario - flanker_T1'  [1x36 char]  ''  [1x88 char]  ''}
%        colnames: {11x1 cell}
%          footer: {1x204 cell}
%         subject: {400x1 cell}
%           trial: {400x1 cell}
%      event_type: {400x1 cell}
%            code: {400x1 cell}
%            time: {400x1 cell}
%           ttime: {400x1 cell}
%     uncertainty: {400x1 cell}
%        duration: {400x1 cell}
%   uncertainty_2: {400x1 cell}
%         reqtime: {400x1 cell}
%          reqdur: {400x1 cell}
%
% Usage:
% lfs = read_logfile('C:\myexp\filename.log');
%
% If a filename is not supplied, you will be prompted to select a .log
% file.
%
% For reading a Presentation-like logfile with a header and columnar
% format, please see the advanced notes in the source for the assumptions 
% that are made about the file. 
%
% see also write_logfile, filter_lfs

% Advanced notes: We are reading in a logfile that we assume is in a
% correct format produced by presentation.  The assumption is that the
% second last line of the header contains the names for each of the columns
% that form the bulk of the file.  A unique, separate field in the logfile struct
% will be created for every column name in this line.  These names are what
% make their way into the colnames variable.
%
% Ken Roberts

% get the fully qualified path into filename
if nargin < 1
    [filename, pathname] = uigetfile('*.log', 'Pick a log file');
    if ~filename %make sure user didnt cancel
        return;
    end;
    filename = [pathname, filename];
else
    [pathname, f1, f2] = fileparts(varargin{1});
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
    sprintf('File %s does not exist', filename), ...
    };

% form a matrix of tests composed of individual error check
req_cond(1) = (exist(filename) == 2);

% test all of the required conditions, and print all test case failures.
if ~all(req_cond)
    ind = find(req_cond == 0);
    error(strcat(req_names{ind}));
end;

fprintf('Reading: %s\n', filename);
fid = fopen(filename, 'r');

% SECTION 1:
% read in log file line by line
% identify the description line
% identify the field names present in this logfile
% first line to parse is desc_linenum+2,
% beginning of footer (unparsed part) is marked by first empty line after
% the first parsed line
count = 0;
lines = {};
desc_linenum = 0;
foot_linenum = 0;
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    count = count+1;
    if ~desc_linenum 
        if is_desc(tline), desc_linenum = count; end;
    elseif ~foot_linenum && isempty(tline)
        if count > desc_linenum+1, foot_linenum = count; end;
    end
    lines{count} = tline;
end;
[colnames, fieldnames] = get_colnames(lines{desc_linenum});


fclose(fid);

lfs.header = lines(1:desc_linenum+1);
lfs.colnames = colnames;

% set lines and footer depending on whether there IS a footer
if foot_linenum == 0
    lfs.footer = {};
    lines = lines(desc_linenum+2:end);
else
    lfs.footer = lines(foot_linenum:end);
    lines = lines(desc_linenum+2:foot_linenum-1);
end;

% make all of the relevant fields in the struct
big_cell = cell(length(lines), length(colnames)); 

% loop through the lines in the logfile one line at a time
for i = 1:length(lines)
    try
        % parse it according to tabs
        values = subsref(textscan(lines{i}, '%s', 'delimiter', '\t'), struct('type', {'{}'}, 'subs', {{1}}));
        big_cell(i, 1:length(values)) = values;
    catch
        error(['Error parsing line ' num2str(i+length(lfs.header))]);
    end;
end;

% copy in all of the fields
for i = 1:length(fieldnames)
    lfs.(fieldnames{i}) = big_cell(:, i);
end;

% parse any port conflicts from footer
lfs.conflicts = parse_port_conflicts(lfs.footer);

return;


% subfunction to parse port conflicts
% takes in footer, looks for lines like:
% -> The following output port codes were not sent because of a conflict on the port.
% -> Port	Code	Time(ms)
% -> 1	41	7166
function conflicts = parse_port_conflicts(footer)
    conflicts = struct('port', {}, 'code', {}, 'time', {});
    port_start = find(strcmp(footer, ...
        'The following output port codes were not sent because of a conflict on the port.'));
   
    if isempty(port_start)    
        return;
    end;
    
    curr_line = port_start + 2;
    while curr_line <= length(footer)
        try
            [a, b, c] = strread(footer{curr_line}, '%d%d%f');
            conflicts(curr_line-port_start-1) = struct('port', {a}, 'code', {b}, 'time', {c});
            curr_line = curr_line+1;
        catch 
            break
        end;
    end;
  
return;

% subfunction to determine whether a line is the "descriptor line,"
% or that line that contains the names of each column
function is_desc_ret = is_desc(line)
% does the line contain the prototypical field names?
% the few we absolutely need are 'Event Type', 'Code', and 'Time'
if ~isempty(strfind(line, 'Event Type')) && ... 
        ~isempty(strfind(line, 'Code')) && ...
         ~isempty(strfind(line, 'Time'))
    is_desc_ret = 1;
else
    is_desc_ret = 0;
end;
return;


% parse the column names contained in the descriptor line.
% change them into field names for the struct which have a few restrictions:
% they cannot have spaces, they should be lower case, and the names can't
% be duplicated (like "Uncertainty" usually appears twice.)
function [colnames, fieldnames] = get_colnames(line)

% split up the descriptor line into column names
colnames = subsref(textscan(line, '%s', 'delimiter', '\t'), struct('type', {'{}'}, 'subs', {{1}}));

% field names should be lower case and no spaces
fieldnames = strrep(lower(colnames), {' '}, {'_'});
fieldnames = strrep(fieldnames, {'('}, {'_'});
fieldnames = strrep(fieldnames, {')'}, {'_'});

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