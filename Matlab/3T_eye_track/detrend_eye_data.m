function data = detrend_eye_data(data)
% detrends eye-tracking data (only linear for now)
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
for i = 1:length(data.runs)
    
    % first, do a linear detrend.
    npoints = length(data.runs{i}.pos.row);
    X = [ones(npoints, 1), data.runs{i}.pos.time];
    xbetas = X\data.runs{i}.pos.xpos;
    mask = abs(X*xbetas - data.runs{i}.pos.xpos) > 1;
    ybetas = X\data.runs{i}.pos.ypos;
    mask = mask | (abs(X*ybetas - data.runs{i}.pos.ypos) > 1);
    
    fprintf('\tRemoving %d rows from run %d.\n', sum(double(mask)), i);
    fprintf('\tMeans: [%1.3f, %1.3f]\n', xbetas(1), ybetas(1));
    
    % now, remove the problematic rows.
    removed = struct('row', data.runs{i}.pos.row(mask), ...
        'time', data.runs{i}.pos.time(mask), ...        
        'xpos', data.runs{i}.pos.xpos(mask), ...
        'ypos', data.runs{i}.pos.ypos(mask), ...
        'pwidth', data.runs{i}.pos.pwidth(mask), ...
        'paspect', data.runs{i}.pos.paspect(mask));
    
    data.runs{i}.pos.row = data.runs{i}.pos.row(~mask);
    data.runs{i}.pos.time = data.runs{i}.pos.time(~mask);
    data.runs{i}.pos.xpos = data.runs{i}.pos.xpos(~mask);
    data.runs{i}.pos.ypos = data.runs{i}.pos.ypos(~mask);
    data.runs{i}.pos.pwidth = data.runs{i}.pos.pwidth(~mask);
    data.runs{i}.pos.paspect = data.runs{i}.pos.paspect(~mask);
    
    % with bad rows removed, detrend again using chosen method
    npoints = length(data.runs{i}.pos.row);
    X = [ones(npoints, 1), data.runs{i}.pos.time];
    xbetas = X\data.runs{i}.pos.xpos;
    xdetrend = X*xbetas;
    ybetas = X\data.runs{i}.pos.ypos;
    ydetrend = X*ybetas;
    
    % plot data and detrending line
    verbose = 1;
    if verbose
        if isempty(debug_fig)
            debug_fig = figure;
        end;
        figure(debug_fig);
        hold off;
        plot(data.runs{i}.pos.xpos, 'b')
        hold on;
        plot(xdetrend, 'g')
        plot(data.runs{i}.pos.ypos, 'r')
        plot(ydetrend, 'k');
        title('Detrending eye-tracking data')
        
        pause;
    end;
    
    
    % and add the detrending fields
    data.runs{i}.detrend = struct('method', 'linear', 'xbetas', xbetas, ...
            'ybetas', ybetas, 'xpos', xdetrend - 0.5, 'ypos', ydetrend - 0.5);
end;