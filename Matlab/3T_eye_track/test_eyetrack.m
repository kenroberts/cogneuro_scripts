% script for testing eye-tracking code-> snippets to cut and paste into the 
% MATLAB window.


if (1)
    q = read_data({'35104_1to4.xls', '35124_1to4.xls'});
    
    for i = 1:length(q)
        q{i} = split_data('splitbymarker', q{i}, 'startmarker', 'V');
        q{i} = detrend_eye_data(q{i});
    end;
    
else
    
    q = read_data({'131.xlsx', '135.xlsx'});
    
    for i = 1:length(q)
        q{i} = split_data('startandendmarkers', q{i}, 'startmarker', 'V', 'endmarker', 'E');
    end;
    
    view_run('filenames', {'131.xlsx', '135.xlsx'}, 'data', q);
    view_sub('filenames', {'131.xlsx', '135.xlsx'}, 'data', q);
    
end;