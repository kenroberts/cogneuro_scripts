function est_quality(xl_files, subj_xl_data)
% est_quality(xl_files, subj_xl_data)
%
% Notes on measures:
%
% Number of points: number of sampled points
% Glitches: when a location-row of data is misformed 
%  (there should never be data in the 11th column)
% Events: number of rows with marker data
% Range checking: UL of screen is (0,0) and LR is (1,1).  Every
%   coordinate should fall in this range.
% Sample intervals: eye-location rows should be recorded at a 
%   regular rate.  This plots the difference in time between 
%   successive samples.
%
global sav_data;
for i = 1:length(xl_files)
    
    sub_xl_data = subj_xl_data{i};
    fprintf('Quality information for file: %s\n', xl_files{i});
    
    % timing regularity
    %fprintf
    
    
    % overall statistics
    pos_rows = find(sub_xl_data(:,1)==10);
    no_data_rows = find(sub_xl_data(:,1)==99);
    if size(sub_xl_data, 2) > 10
        glitches = intersect(pos_rows, find(~isnan(sub_xl_data(pos_rows, 11))) );
        pos_rows = setdiff(pos_rows, glitches);
        n_glitches = length(glitches);
    else
        n_glitches = 0;
    end;
    
    fprintf('\t%-28s %d\n', 'Number of points:', length(pos_rows) + length(no_data_rows));
    fprintf('\t%-28s %d\n', 'Points with ''no data'':', length(no_data_rows));
    fprintf('\t%-28s %d\n', 'Glitches:', n_glitches);
    fprintf('\t%-28s %d\n', 'Events:', length(find(sub_xl_data(:,1)==12)));
    
    % timing check
    sper = 1.001/30;
    samp_rows = union(pos_rows, no_data_rows);
    rdiff = sub_xl_data(samp_rows(2:end), 2) - sub_xl_data(samp_rows(1:end-1), 2);
    fprintf('\t%-28s %d\n', 'Sample intervals > 2*period:', length(find(rdiff > 2*sper)));
    
    figure; plot(rdiff);
    title(['Sample intervals - ' xl_files{i}], 'Interpreter', 'none');
    % figure; plot(min(rdiff, 0.5));
    % title(['Sample intervals under 0.5s - ' xl_files{i}], 'Interpreter', 'none');
    % figure; plot(conv(double(sav_data.raw_data{1}(:, 1) == 99), ones(30, 1)/30));
    % title(['No pupil indicator (s) - ' xl_files{i}], 'Interpreter', 'none');
    
    ar_order = 2;
    a = aryule(sub_xl_data(pos_rows,4), ar_order);
    fprintf('AR(%d) Yule-Walker Coeffs: %s\n', ar_order, num2str(a));
    
    % range checking
    fprintf('\t%-28s\n', 'Percent <0 and >1:');
    fprintf('\t%-28s %8.2f, %8.2f\n', '     x:', ...
        100*sum(double(sub_xl_data(pos_rows,4)<0))/length(pos_rows), ...
        100*sum(double(sub_xl_data(pos_rows,4)>1))/length(pos_rows) );
    fprintf('\t%-28s %8.2f, %8.2f\n', '     y:', ...
        100*sum(double(sub_xl_data(pos_rows,5)<0))/length(pos_rows), ...
        100*sum(double(sub_xl_data(pos_rows,5)>1))/length(pos_rows) );
    
    fprintf('\t%-28s\n', 'Percent <-0.5 and >1.5:');
    fprintf('\t%-28s %8.2f, %8.2f\n', '     x:', ...
        100*sum(double(sub_xl_data(pos_rows,4)<-0.5))/length(pos_rows), ...
        100*sum(double(sub_xl_data(pos_rows,4)>1.5))/length(pos_rows) );
    fprintf('\t%-28s %8.2f, %8.2f\n', '     y:', ...
        100*sum(double(sub_xl_data(pos_rows,5)<-0.5))/length(pos_rows), ...
        100*sum(double(sub_xl_data(pos_rows,5)>1.5))/length(pos_rows) );
    
    fprintf('\n\n');
end;

return;