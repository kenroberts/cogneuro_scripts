% script for testing eye-tracking code-> snippets to cut and paste into the 
% MATLAB window.

five_dig_subs = {'35104_1to4.xls', '35124_1to4.xls', ...
            'extra\35130_1to4.xls',  'extra\35168_1to4.xls', 'extra\35231_1to4.xls', ...
'extra\35302_1to4.xls', 'extra\35429_1to4.xls','extra\35436_1to4.xls', 'extra\35472_1to4.xls', ...
'extra\35531_1to4.xls', 'extra\35539_1to4.xls', 'extra\35612_1to4.xls', ...
     'extra\35622_1to4.xls', 'extra\35642_1to4.xls', 'extra\35648_1to4.xls', 'extra\35706_1to4.xls'};

if (0)
    % data from Ruth's SaccEye experiment
    % 35104 has really nice saccade data
    % 35124 looks pretty bad, in this file the time rolls over around line
    % 40000!!
    q = read_data({'35104_1to4.xls', '35124_1to4.xls'});
    
    for i = 1:length(q)
        q{i} = split_data('splitbymarker', q{i}, 'startmarker', 'V');
        % q{i} = detrend_eye_data(q{i});
    end;
    
    view_run('filenames', {'35104_1to4.xls', '35124_1to4.xls'}, 'data', q);
    view_sub('filenames', {'35104_1to4.xls', '35124_1to4.xls'}, 'data', q);
    
elseif (0)
    
    q = read_data({'131.xlsx', '135.xlsx'});
    
    for i = 1:length(q)
        q{i} = split_data('startandendmarkers', q{i}, 'startmarker', 'V', 'endmarker', 'E');
    end;
    
    view_run('filenames', {'131.xlsx', '135.xlsx'}, 'data', q);
    view_sub('filenames', {'131.xlsx', '135.xlsx'}, 'data', q);
    
    
elseif (1)
    % do some more
    q = read_data(five_dig_subs);
    
    % split into runs
    for i = 1:length(q)
        q{i} = split_data('splitbymarker', q{i}, 'startmarker', 'V');
        % q{i} = detrend_eye_data(q{i});
    end;
    
    % shift event codes by 1
    q = do_sacc_att_hack(q);
    
    % add text description
    q = text_summary(q);
    
    % classify for outlying points.
    q = classify_points(q);
    
    %save et3 q
    
elseif(0)
    % for cycling through annotate graphics
    run = 1;
    for i = 1:length(q)
        imshow(q{i}.runs{run}.annotate.after_corr_img.ind_data, ...
            q{i}.runs{run}.annotate.after_corr_img.cmap);
        pause
    end;
    
else
    % for cycling through annotate graphics
    sub = 1;
    for i = 1:length(r{sub}.runs)
        imshow(r{sub}.runs{i}.annotate.after_corr_img_a.ind_data, ...
            r{sub}.runs{i}.annotate.after_corr_img_a.cmap);
        pause
        imshow(r{sub}.runs{i}.annotate.after_corr_img_b.ind_data, ...
            r{sub}.runs{i}.annotate.after_corr_img_b.cmap);
        pause
    end;
    
end;