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


% HARD-CODED: get rid of runs less than 10s or less than 300 rows (usually
% also about 10s).


% print informative message to screen?
verbose = 1;


if nargin < 2 % get info graphically
    
    data_out = varargin{1};
    if length(data_out.runs) > 1
        warning('Splitting more than one run not supported, only splitting first run.');
    end;
    
    choice = menu('Please choose a method of splitting into runs:', ...
                    'Split by start marker', ...
                    'Split by start and end markers', ...
                    'Split by gaps in events');
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
            
        case 3
            methodname = 'nearevents';
            answer = inputdlg('Split into runs between event-gaps of how many seconds');
            options.interval = answer;
    end;
    
    

else % try to get everything from the command line.
    methodname = varargin{1};
    data_out = varargin{2};
    
    if length(data_out.runs) > 1
        warning('Splitting more than one run not supported, only splitting first run.');
    end;
    
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
            error('Please specify ''startmarker''');
        end;
        seg_starts = strcmp(data_out.runs{1}.events.code, options.startmarker);
        seg_starts(end) = 1; % add last event as end
        seg_starts = data_out.runs{1}.events.row(seg_starts);
        seg_ends = seg_starts(2:end);
        seg_starts = seg_starts(1:end-1);
        
    case 'startandendmarkers'
        if ~isfield(options, 'startmarker') || ~isfield(options, 'endmarker')
            error('Please specify options for both ''startmarker'' and ''endmarker.''');
        end;
        
        % find event numbers that correspond to each start and end.
        seg_starts = strcmp(data_out.runs{1}.events.code, options.startmarker);
        seg_ends = strcmp(data_out.runs{1}.events.code, options.endmarker);
        
        seg_starts = data_out.runs{1}.events.row(seg_starts);
        seg_ends = data_out.runs{1}.events.row(seg_ends);
        
        % sanity check: equal lengths, no starts after ends.
        % (if there is a false start- a run starts, then is stopped early
        % for some reason, and then continues again, there may be extra
        % start markers)
        if length(seg_starts) ~= length(seg_ends) || any((seg_ends-seg_starts) < 0)
            error('Mismatched starts and ends.');
        end;
        
    case 'nearevents'
        
        error('not implemented yet');
        
        tdiff = data_out.run{1}.events.time(2:end) - data_out.run{1}.events.time(1:end-1);
        
        % each event has to have a time greater than the event preceding it
        % for violations, replace w/ nearby time.
        errs = find(tdiff < 0) + 1;
        for i = 1:length(errs)
            row = data_out.run{1}.events.row(errs(i));
            prev_pos_row_time = data_out.runs{1}.pos.time( find(data_out.runs{1}.pos.row < row, 1, 'last'));
            prev_nodata_row_time = data_out.run{1}.nodata.time( find(data_out.runs{1}.nodata.row < row, 1, 'last'));
            next_pos_row_time = data_out.runs{1}.pos.time( find(data_out.runs{1}.pos.row > row, 1));
            next_nodata_row_time = data_out.runs{1}.nodata.time( find(data_out.runs{1}.nodata.row > row, 1));
            
            data_out.run{1}.events.time(errs(i)) = mean([ max(prev_pos_row_time, prev_nodata_row_time), ...
                min(next_pos_row_time, next_nodata_row_time) ]);
            
        end;
        
        % break up at every gap > interval
        tdiff = data_out.runs{1}.events.time(2:end)-data_out.runs{1}.events.time(1:end-1);
        last_time = max(max(data_out.runs{1}.pos.time(end), data_out.runs{1}.nodata.time(end)), data_out.runs{1}.events.time(end));
        seg_starts = [data_out.runs{1}.events.time(1); data_out.run{1}.events.time(find(tdiff > options.interval) + 1) + 0.5*options.interval ]; 
        seg_ends = [data_out.runs{1}.events.time(find(tdiff > options.interval)-1) - 0.5*options.interval; last_time ];
        
        
    otherwise
        error(['The method %s is not supported.  Please type\n' ...
            'help %s to find examples of usage.'], methodname, mfilename);
end; % switch

% do the splitting
data_out.runs = split_on_rows(data_out, seg_starts, seg_ends);

% print summary
if verbose
    fprintf('Found %d runs.\n', length(seg_starts));
    for i = 1:length(data_out.runs)
        tstart = min([data_out.runs{i}.pos.time(1), data_out.runs{i}.nodata.time(1), data_out.runs{i}.events.time(1)]);
        tend = max([data_out.runs{i}.pos.time(end), data_out.runs{i}.nodata.time(end), data_out.runs{i}.events.time(end)]);
        fprintf('\tSegment %d: %.2f s\n', i, tend-tstart); 
    end;
end;


return;


% split data by rows in seg_starts, seg_ends
% which are vectors containing row numbers 
function runs = split_on_rows(data, seg_starts, seg_ends)

% HARD-CODED: minimum length in rows (300 ~= 10s)
MIN_LENGTH_ROW = 300;
nskip = 0;
%runs = cell(length(seg_starts));
fprintf('%d\n', length(seg_starts));

for i = 1:length(seg_starts)
    if seg_ends(i)-seg_starts(i) < MIN_LENGTH_ROW
        warning('Skipping run of only %f rows.', seg_ends(i)-seg_starts(i));
        nskip = nskip+1;
        continue
    end;
    
    choose_ind = find(data.runs{1}.events.row >= seg_starts(i));
    choose_ind = setdiff(choose_ind, find(data.runs{1}.events.row >= seg_ends(i)));
    ev = struct('row', data.runs{1}.events.row(choose_ind), ...
                'time', data.runs{1}.events.time(choose_ind), ...
                'code', { data.runs{1}.events.code(choose_ind) });
            
    choose_ind = find(data.runs{1}.pos.row >= seg_starts(i));
    choose_ind = setdiff(choose_ind, find(data.runs{1}.pos.row >= seg_ends(i)));
    pos = struct('row', data.runs{1}.pos.row(choose_ind), ...
                'time', data.runs{1}.pos.time(choose_ind), ...
                'xpos', data.runs{1}.pos.xpos(choose_ind), ...
                'ypos', data.runs{1}.pos.ypos(choose_ind), ...
                'paspect', data.runs{1}.pos.paspect(choose_ind), ...
                'pwidth', data.runs{1}.pos.pwidth(choose_ind) );
    
    choose_ind = find(data.runs{1}.nodata.row >= seg_starts(i));
    choose_ind = setdiff(choose_ind, find(data.runs{1}.nodata.row >= seg_ends(i)));
    nodata = struct('row', data.runs{1}.nodata.row(choose_ind), ...
                'time', data.runs{1}.nodata.time(choose_ind) );
            
            
            
    runs{i-nskip} = struct('events', ev, 'nodata', nodata, 'pos', pos); 
end;


return;