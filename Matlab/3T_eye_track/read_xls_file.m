function raw_data = read_xls_file(input_filename)

% NOTE: the canonical form of data should be very similar to what
% is contained in a single file-- it should have every readable piece 
% of data from the original file in a totally unmodified form.
% this data structure should probably be split up so that rows
% of various types are in different sub-structs.
% 
% format for now of a 'run' of data:
%
% data.header ("3" rows) TODO
%     .header.lines (ascii contents of marker field)
%     .header.rows
% data.events ("12" rows)
%     .events.row
%     .events.time
%     .events.code
% data.pos    ("10" rows)
% data.nodata ("99" rows)
% data.other  ("2" rows) TODO
%
%  derived fields: TODO
% data.detrend
%     .detrend.xpos
%     .detrend.ypos
% data.history
% 

% todo:
%    four criteria used to reject rows:
%       1- too many fields for that row type
%       2- row types other than 3, 12, 10, 99
%       3- too great a z-score difference on pos
%       4- non-monotonic increase of time

    [xl_num, xl_str] = xlsread(input_filename);
    
    % sometimes acquisition stutters and records things twice, shifting
    % over all of the columns.  Do not use these points.
    if size(xl_num, 2) > 10
        badrows = find( ~isnan(xl_num(:, 11)) );
    else
        badrows = [];
    end;
    
    % ensure that time increases monotonically (if there is a missing
    % 'time' value in the second column, recreate it from average of other 
    % two columns.
%     first_row = min([   find(xl_num(:,1) == 10, 1), ...
%                         find(xl_num(:,1) == 12, 1), ...
%                         find(xl_num(:,1) == 99, 1) ]);
%     last_row  = max([   find(xl_num(:,1) == 12, 1, 'last'), ...
%                         find(xl_num(:,1) == 12, 1, 'last'), ...
%                         find(xl_num(:,1) == 12, 1, 'last') ]);
%     tdiff = xl_num(first_row+1:last_row, 2) - xl_num(first_row:last_row-1, 2);
    
    
    % nodata (99 rows) (have 
    choose_ind = setdiff(find(xl_num(:,1) == 99), badrows);
    nodata.row = choose_ind;
    nodata.time = xl_num(choose_ind, 2);
    
    % events (12 rows, 3 cols)
    choose_ind = setdiff(find(xl_num(:,1) == 12), badrows);
    events.row = choose_ind;
    events.time = xl_num(choose_ind, 2);
    events.code = strtrim(cellstr(num2str(xl_num(choose_ind, 3))));
    temp_str = xl_str(choose_ind, 3);
    temp_isnan = isnan(xl_num(choose_ind, 3));
    events.code(temp_isnan)= temp_str(temp_isnan);
    
    % position (10 rows, 10 cols): TotalTime(2), DeltaTime(3),
    % X_Gaze(4), Y_Gaze(5), Region(6), PupilWidth(7),
    % PupilAspect(8), Count(9), Torsion(10)
    choose_ind = setdiff(find(xl_num(:,1) == 10), badrows);
    pos.row = choose_ind;
    pos.time = xl_num(choose_ind, 2);
    pos.xpos = xl_num(choose_ind, 4);
    pos.ypos = xl_num(choose_ind, 5);
    pos.pwidth = xl_num(choose_ind, 7);
    pos.paspect = xl_num(choose_ind, 8);
    
    % IGNORE headers for now. (string data)
     choose_ind = find(xl_num(:,1) == 3);
     header = cell(length(choose_ind), 1);
     
     for i = 1:length(choose_ind)
        header{i} = '';
        % iterate thru cols
        num_cols = min(size(xl_num, 2), size(xl_str, 2));
        for j = 1:num_cols
             
             if isnan(xl_num(choose_ind(i), j))
                header{i} = sprintf('%s\t%s', header{i}, xl_str{choose_ind(i), j});
             else
                header{i} = sprintf('%s\t%s', header{i}, num2str(xl_num(choose_ind(i), j)));
             end;
        end;
        
     end;

    % 2 rows: other?
    % 3 rows: 2 cols, after first col, all in string.
    % 99 rows: 4 cols, 
    raw_data.header = header;
    raw_data.runs{1} = struct('events', events, 'pos', pos, 'nodata', nodata);
    %raw_data = struct('events', events, 'pos', pos, 'nodata', nodata);

return;