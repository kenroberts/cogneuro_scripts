% script for testing eye-tracking code-> snippets to cut and paste into the 
% MATLAB window.


% q = read_data({'35104_1to4.xls', '35124_1to4.xls'});
q = read_data({'131.xlsx', '135.xlsx'});

for i = 1:length(q)
    q{i} = split_data('startandendmarkers', q{i}, 'startmarker', 'V', 'endmarker', 'E');
end;