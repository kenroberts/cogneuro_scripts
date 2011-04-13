function data =  read_data(input_files)
% read eyetracking data out of txt or excel files.
%
% READ_DATA( FILENAME1, FILENAME2, ...) will read eyetracking data
% out of txt or excel files and return a cell array of structs containing 
% position and event data-- one struct per input file.

% TODO: allow choice of threshold
% high cohesion, low coupling.

global sav_data;

% read in data (only if it is not already read in) and has same list of
% subjects
if isempty(sav_data) ...
    || ~isfield(sav_data, 'input_files') ...
    || ~all(all(char(sav_data.input_files) == char(input_files)))
    raw_data = cell(size(input_files));
    for i = 1:length(input_files)
        tic;
        fprintf('Reading file %s ', input_files{i});
        switch input_files{i}(end-3:end)
            case '.txt'
                 data{i}.runs{1} = read_txt_file(input_files{i});
            case '.xls'
                 data{i}.runs{1} = read_xls_file(input_files{i});
            case 'xlsx'
                 data{i}.runs{1} = read_xls_file(input_files{i});
            otherwise
                error('Unknown file type: %s\n', input_files{i});
        end;
        fprintf('in %f seconds.\n', toc);
    end;
    sav_data.data = data;
    sav_data.input_files = input_files;
else
    disp('Re-using cached data.');
    data = sav_data.data;
end;

return;

% NOTE: the canonical form of data should be very similar to what
% is contained in a single file-- it should have every readable piece 
% of data from the original file in a totally unmodified form.
% this data structure should probably be split up so that rows
% of various types are in different sub-structs.
% 
% format for now of a 'run' of data:
%
% data.header ("3" rows)
% data.events ("12" rows)
% data.pos    ("10" rows)
% data.nodata ("99" rows)
% data.other  ("2" rows)
%
%  derived fields:
% data.detrend
% data.history


% helper subfunction to read in eyetracking data from text files.

function raw_data = read_txt_file(input_filename)

    % estimate rows in file, aim high (sample file is 104000 lines, and
    % 7781342 bytes)
    %tic;
    fstruct = dir(input_filename); % has .name and .bytes
    rowest = round(fstruct.bytes*(104000/7781342)*1.05);
    
    raw_data = cell(rowest, 10);
    fid = fopen(input_filename, 'r');
    rows = 0;
    bad_parse = 0;
    while (1)
        [type, succ] = fscanf(fid, '%d\t', 1);
        if ~succ, 
            if ftell(fid) == fstruct.bytes
                break;
            else
                bad_parse = bad_parse+1;
                rows = rows+1;
                fgetl(fid);
                continue;
            end;
        end;
        
        rows = rows+1;
        raw_data{rows, 1} = type;
        switch type
            
            case 2 % parse line type 2 or 3: treat rest of line as a string
                raw_data{rows, 2} = fgetl(fid);
            case 3 % (comment)
                raw_data{rows, 2} = fgetl(fid);
            case 10 % eye-position row with fields: TotalTime(2), DeltaTime(3),
                    % X_Gaze(4), Y_Gaze(5), Region(6), PupilWidth(7),
                    % PupilAspect(8), Count(9), Torsion(10)
                raw_data{rows, 2} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 3} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 4} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 5} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 6} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 7} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 8} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 9} = fgetl(fid);

            case 12 % record time, treat rest of line as a string (marker)
                raw_data{rows, 2} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 3} = fgetl(fid);
                
            case 99 % record time, followed by two ints (
                raw_data{rows, 2} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 3} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 4} = fgetl(fid);
           
            otherwise
                bad_parse = bad_parse + 1;
                fgetl(fid);
        end;
    end
    
    raw_data = raw_data(1:rows, :);
    
    
    %fprintf('Estimate %d rows for file %s.\n', rowest, input_filename);
    %fprintf('Read %d rows in %f seconds, %d lines not parsed.\n', rows, read_time, bad_parse);

return;

% NO LONGER USED %
% helper subfunction to take the data as read in from xlsread or 
% read_txt_file, and package it into a struct
function clean_data = package_data(varargin)

error('This function''s comments indicate it is obsolete.');

clean_data = cell(1, length(xl_files));

for i = 1:length(xl_files)
    
    % see how many segments there are in the data.
    sub_xl_data = subj_xl_data{i};
    
    % find rows where 1st column has a 12, and 3rd column has a NaN
    % (12 is the code for a row that contains a string sent from Presentation to the
    % EyeTracker)
    % segs{i} will store a vector of row indices that contain an 'I'
    % 'V' or 'E' for subject i, which will indicate run divisions within
    % a continuously acqired file
    % in this case, segments start after no markers for 8 seconds.
    sub_segs = intersect( find(sub_xl_data(:,1)==12), find(isnan(sub_xl_data(:,3)))  );
    start_segs = find(diff(sub_segs) > 8000);
    
    % if wanted, print out num of runs
    if exist('verbose', 'var') && verbose
        disp(['Subject ' xl_files{i} ' has ' num2str(length(sub_segs)) ...
        ' segments and ' num2str(length(find(diff(sub_segs) > 8000))) ' runs.']);
    end;

    % chop data into runs
    runs = cell(1, length(start_segs));
    for j = 1:length(start_segs)
        
        % if wanted, print out progress indicator
        if exist('verbose', 'var') && verbose
            disp(['Subject ' num2str(i) ' run ' num2str(j) '.']);
        end;
        
        % run_rows will contain indices of each row in that run
        run_rows = (sub_segs(start_segs(j)):sub_segs(start_segs(j)+1))';

        % linetype = 1st_col, time = 2nd_col, xpos_raw = 3rd_col
        linetype = sub_xl_data(run_rows, 1);
        time = sub_xl_data(run_rows, 2);
        code = sub_xl_data(run_rows, 3);
        xpos_raw = sub_xl_data(run_rows, 4);
        ypos_raw = sub_xl_data(run_rows, 5);
        
        % sometimes acquisition stutters and records things twice, shifting
        % over all of the columns.  Do not use these points.
        if size(sub_xl_data, 2) > 10
            badrows = find( ~isnan(sub_xl_data(run_rows, 11)) );
        else
            badrows = [];
        end;
             
        % xpos has real data where linetype=10.
        choose_ind = find(linetype==10);
        
        % limit xpos and ypos to [-1 .. 2].
        badrows = union(badrows, find(xpos_raw > 2 | xpos_raw < -1));
        badrows = union(badrows, find(ypos_raw > 2 | ypos_raw < -1));
        
        % choose only good rows.
        choose_ind = setdiff(choose_ind, badrows );
        xpos = xpos_raw(choose_ind);
        ypos = ypos_raw(choose_ind);
        pos_time = time(choose_ind);
        pos_row = run_rows(choose_ind);

        % throw in pupil width and aspect ratio (col 7 and 8)
        pwidth = sub_xl_data(run_rows(choose_ind), 7);
        paspect = sub_xl_data(run_rows(choose_ind), 8);
        
        % find events
        choose_ind = intersect(find(linetype==12), find(~isnan(code)) );
        evt_code = code(choose_ind);
        evt_time = time(choose_ind);
        evt_row = run_rows(choose_ind);

        % place in struct
        % Due to a timecode problem specific to Ruth's SaccAtt experiment,
        % we are shifting all of the codes FORWARD one spot.
        % do_saccatt_hack = 1;
        if exist('do_saccatt_hack', 'var') && do_saccatt_hack
            warning('EYETRACK:SACCATT_HACK', 'DOING EVENT-CODE HACK SPECIFIC TO SACCATT EXPT!');
            evt = struct('evt_code', evt_code(1:end-1), 'evt_time', evt_time(2:end), 'evt_row', evt_row(2:end));
        else % do not do hack
            evt = struct('evt_code', evt_code, 'evt_time', evt_time, 'evt_row', evt_row);
        end;
        
        pos = struct('xpos', xpos, 'ypos', ypos, 'pwidth', pwidth, 'paspect', paspect, ...
                    'pos_time', pos_time, 'pos_row', pos_row);
                
        runs{j} = struct('run_rows', run_rows, 'events', evt, 'pos', pos);
    end; % for nruns

    clean_data{i} = runs;

end; % for subj.


return;