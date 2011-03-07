function data_out = split_data(varargin)
%  splits continuous eye-tracking data into separate "runs"
%
% data = split_data(data)
%
% This is the easiest way to use the function, and will prompt you with
% menus that ask you how you want to split the data.
%
% You can also run from the command line one of the following ways:
%
% split_data(method, data, optionname, optionvalue) will split a single run
% of data into multiple segments.  method must be one of the following 
% strings:
%
% 'splitbymarker' - will split the file into different segments based on a
% marker. the first segment will consist of the beginning of the data up
% until the first marker of the designated type, and the second segment 
% will go from that marker to the second marker of that type, and so on.
% use optionname of 'marker' and optionvalue for the marker string.
% 
% runs = split_data('splitbymarker', data, 'marker', 'S');
%
% will take the eyetracking data in "data" and split it into runs based on the
% event-code marker 'S'.
%
% 'startandendmarkers' - will split data into segments started by a
% 'startmarker' and ending with an 'endmarker'.
% 
% runs = split_data('startandendmarkers', data, 'startmarker', 'S', 'endmarker', 'E');
%

% TODO: implement other methods like:
%
% 'nearevents' - will split data into runs depending on how often markers
% appear.  So, if 'interval' is set to 5 seconds, then any gap without
% markers longer than 5 seconds will be considered the end of a run, and
% the beginning of the next run.
%
% runs = split_data('nearevents', data, 'interval', 5);



if nargin < 2 % get info graphically
    
    choice = menu('Please choose a method of splitting into runs:', ...
                    'Split by start marker', ...
                    'Split by start and end markers');
    switch choice
        case 1
            methodname = 'splitbymarker';
            answer = inputdlg('Please enter a start marker code:', '', 1);
            options.startmarker = answer{1};

        case 2
            methodname = 'startandendmarkers';
            prompt = { 'Please enter a start marker code:', ...
                        'Please enter an end marker code:'};
            answer = inputdlg(prompt, '', 1);
            options.startmarker = answer{1};
            options.endmarker = answer{2};
    end;

else % try to get everything from the command line.
    methodname = varargin{1};
    data = varargin{2};
    
    % fill "options" - a struct with fields for each option
    options = struct;
    for i = 3:2:nargin    
        if ~ischar(varargin{i}) && nargin <= i+1 && ischar(varargin{i+1})
            error(['Optionnames and optionvalues must come in pairs \n' ...
                'and both must be strings.']);
        end;
        
        options = setfield(options, varargin{i}, varargin{i+1});
    end;
end;

    
switch methodname
    
    case 'splitbymarker'
        if ~isfield(options, 'startmarker')
            error('Please specify ''startmarker'' and ''endmarker.''');
        end;
        seg_starts = strcmp(data.events.code, options.startmarker);
        seg_starts = data.events.time(seg_starts);
        seg_ends = seg_starts(2:end);
        seg_starts = seg_starts(1:end-1);
        
    case 'startandendmarkers'
        if ~isfield(options, 'startmarker') || ~isfield(options, 'endmarker')
            error('Please specify options for both ''startmarker'' and ''endmarker.''');
        end;
        
        % find event numbers that correspond to each start and end.
        seg_starts = strcmp(data.events.code, options.startmarker);
        seg_ends = strcmp(data.events.code, options.endmarker);
        
        seg_starts = data.events.time(seg_starts);
        seg_ends = data.events.time(seg_ends);
        
        % sanity check: equal lengths, no starts after ends.
        if length(seg_starts) ~= length(seg_ends) || any((seg_ends-seg_starts) < 0)
            error('Mismatched starts and ends.');
        end;
        
        %error('not implemented yet');
    case 'nearevents'
        error('not implemented yet');
    otherwise
        error(['The method %s is not supported.  Please type\n' ...
            'help %s to find examples of usage.'], methodname, mfilename);
end; % switch

verbose = 1;
if verbose
    fprintf('Found %d runs.\n', length(seg_starts));
    for i = 1:length(seg_starts)
        fprintf('\tSegment %d: %f seconds.\n', i, seg_ends(i)-seg_starts(i)); 
    end;
end;

% post switch-block requirements:
% that seg_starts and seg_ends are equal in length, and that they 
% mark the time corresponding to the start and end of each segment.
data_out = cell(length(seg_starts), 1);
for i = 1:length(seg_starts)
    choose_ind = find(data.events.time >= seg_starts(i));
    choose_ind = setdiff(choose_ind, find(data.events.time >= seg_ends(i)));
    ev = struct('row', data.events.row(choose_ind), ...
                'time', data.events.time(choose_ind), ...
                'code', { data.events.code(choose_ind) });
            
    choose_ind = find(data.pos.time >= seg_starts(i));
    choose_ind = setdiff(choose_ind, find(data.pos.time >= seg_ends(i)));
    pos = struct('row', data.pos.row(choose_ind), ...
                'time', data.pos.time(choose_ind), ...
                'xpos', data.pos.xpos(choose_ind), ...
                'ypos', data.pos.ypos(choose_ind), ...
                'paspect', data.pos.pwidth(choose_ind), ...
                'pwidth', data.pos.paspect(choose_ind) );
    
    choose_ind = find(data.nodata.time >= seg_starts(i));
    choose_ind = setdiff(choose_ind, find(data.nodata.time >= seg_ends(i)));
    nodata = struct('row', data.nodata.row(choose_ind), ...
                'time', data.nodata.time(choose_ind) );
    data_out{i} = struct('events', ev, 'nodata', nodata, 'pos', pos); 
end;


return;