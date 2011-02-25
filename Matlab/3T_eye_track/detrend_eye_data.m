function data = detrend_eye_data(data)
% detrends eye-tracking data
%
% data = detrend_eye_data(data) will 
%
% 1) calculate a linear trend for the data
% 2) tossing out outlier points greater than 1 away from trend
% 3) using the cleaned-up data to calculate and remove a trend
%       according to the chosen method.
% you can use spline-interpolation, moving-average filtering,
% or plain linear detrending.
%
% it is recommended to do detrending on separate runs, mostly because the
% inter-run periods have terrible artifacts.
%
% the result is that (1) rows will be removed from the 'pos' data if they 
% are outliers, and placed in 'outliers', and (2) that detrending vectors 
% will be placed into pos.detrendx and pos.detrendy
% 
% TODO: add detrending methods besides linear
% add spline
% add moving avg
% add box-jenkins
%


debug_fig =[];
for i = 1:length(data)
    
    % first, do a linear detrend.
    npoints = length(data{i}.pos.row);
    X = [ones(npoints, 1), data{i}.pos.time];
    xbetas = X\data{i}.pos.xpos;
    mask = abs(X*xbetas - data{i}.pos.xpos) > 1;
    ybetas = X\data{i}.pos.ypos;
    mask = mask | (abs(X*ybetas - data{i}.pos.ypos) > 1);
    
    fprintf('\tRemoving %d rows from run %d.\n', sum(double(mask)), i);
    fprintf('\tMeans: [%1.3f, %1.3f]\n', xbetas(1), ybetas(1));
    
    % now, remove the problematic rows.
    removed = struct('row', data{i}.pos.row(mask), ...
        'time', data{i}.pos.time(mask), ...        
        'xpos', data{i}.pos.xpos(mask), ...
        'ypos', data{i}.pos.ypos(mask), ...
        'pwidth', data{i}.pos.pwidth(mask), ...
        'paspect', data{i}.pos.paspect(mask));
    
    data{i}.pos.row = data{i}.pos.row(~mask);
    data{i}.pos.time = data{i}.pos.time(~mask);
    data{i}.pos.xpos = data{i}.pos.xpos(~mask);
    data{i}.pos.ypos = data{i}.pos.ypos(~mask);
    data{i}.pos.pwidth = data{i}.pos.pwidth(~mask);
    data{i}.pos.paspect = data{i}.pos.paspect(~mask);
    
    % with bad rows removed, detrend again using chosen method
    npoints = length(data{i}.pos.row);
    X = [ones(npoints, 1), data{i}.pos.time];
    xbetas = X\data{i}.pos.xpos;
    xdetrend = X*xbetas;
    ybetas = X\data{i}.pos.ypos;
    ydetrend = X*ybetas;
    
    % plot data and detrending line
    verbose = 1;
    if verbose
        if isempty(debug_fig)
            debug_fig = figure;
        end;
        figure(debug_fig);
        hold off;
        plot(data{i}.pos.xpos, 'b')
        hold on;
        plot(xdetrend, 'g')
        plot(data{i}.pos.ypos, 'r')
        plot(ydetrend, 'k');
        title('Detrending eye-tracking data')
        
        pause;
    end;
    
    
    % and add the detrending fields
    data{i}.detrend = struct('method', 'linear', 'xbetas', xbetas, ...
            'ybetas', ybetas, 'xpos', xdetrend - 0.5, 'ypos', ydetrend - 0.5);
end;