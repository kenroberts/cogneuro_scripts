function data = nudge_correction(data)
% nudge_correction(data)
%
% nudge correction:  The eye-tracking data comes from an ordinary video
% signal--just like one you could feed into your TV.  The eye-position is
% computed for every frame of video.  The camera and the acquisition card
% have highly accurate timing-- a frame is sampled exactly by the hardware
% 29.97 times per second.  But, the computer, with a multi-tasking
% operating system, sometimes has a little lag, and might not be able to
% accurately timestamp every timepoint.  If we see the markers timestamped
% 10ms, 20ms, 30ms, 45ms, 50ms 60ms, ... it is easy to see that the
% 40ms timepoint has been recorded as arriving 5ms too late.  What this
% function attempts to do is to look at the interval between each sampling
% point, and if two consecutive intervals are different than the sampling
% rate, but add up to two frames' duration, it will assume that timepoint
% alone has been delayed, or arrived early, and it will nudge it back into
% place.
%
% Assume that the samp_per of the hardware is highly regular, so that the
% timepoints are acquired at y[n] = shift + samp_per*n.  A timepoint that has
% less than 1/2 frame of shift has an error of

% annotate.nodata_pts
%       
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% not so much 0/1 verbose or not, but choose an output strategy:
% 0 - do not plot
% 1 - plot graphs for every run/subject
% 2 - plot graphs 
verbose = 1;

% 0 - do not annotate 
% 1 - "annotate" every subject/run with info on nudging
do_annotate = 1;

for i = 1:length(data)
    for j = 1:length(data{i}.runs)
        tic;
        samp_per = 1.001/30;
        
        % merge 'nodata' and 'pos' timepoints, mtime = "merged time"
        mtime = vertcat(data{i}.runs{j}.nodata.time, data{i}.runs{j}.pos.time);
        is_pos = vertcat(zeros(size(data{i}.runs{j}.nodata.time)), ...
                            ones(size(data{i}.runs{j}.pos.time)) );
        [mtime, sort_order] = sort(mtime);
        is_pos = is_pos(sort_order);    % stores whether it is a 'pos' time
        annotate.nodata_pts = size(data{i}.runs{j}.nodata.time, 2);
        
        % start to calculate intervals
        time_intervals = diff(mtime);
        ideal_intervals = round(time_intervals/samp_per) * samp_per;
        resid = time_intervals-ideal_intervals;
        annotate.time_missing = sum(time_intervals(time_intervals > 1.5*samp_per));
        annotate.time_missing_pct = annotate.time_missing*100./(mtime(end) - mtime(1));
        
        % generate graph of residuals: amt each interval has to change to
        % go to the closest ideal interval, and serial correlations
        if exist('verbose', 'var') && verbose
            plot_residuals(resid);
        end;
        
        % Nudge factor: samp_per*0.05 corresponds to a 5% nudge of a point.
        nudge_factor = samp_per*0.05;
        
        % finds timepoints within 1/2 nudge_factor of the falling diagonal in the
        % serial correlation plot (consecutive intervals summing to two frames)
        deviated_ind = find(abs(resid(2:end)+resid(1:end-1)) < sqrt(nudge_factor.^2));
        
        % do not nudge points that are close to the origin in the serial
        % correlation plot (these are good data points)
        deviated_ind = setdiff(deviated_ind, find( sqrt(resid(2:end).^2+resid(1:end-1).^2) < 1.5*nudge_factor));
        
        % continue plotting on serial correlation graph.
        if exist('verbose', 'var') && verbose
            [my_im, my_map] = plot_residuals2(resid, deviated_ind, nudge_factor, samp_per);
            annotate.before_corr_img.ind_data = my_im;
            annotate.before_corr_img.cmap = my_map;
        end;
        annotate.points_nudged = length(deviated_ind);
        
        % do the correction, and use the floor function to move late timepoints
        % backward.  This turns out to be the right thing to do almost all the
        % time.
        mtime2 = mtime;
        new_timepoints = floor(time_intervals/samp_per) * samp_per;
        new_resid = time_intervals - new_timepoints;
        mtime2(deviated_ind+1) = mtime2(deviated_ind+1) - new_resid(deviated_ind);
        time_intervals2 = diff(mtime2);
                
        % and replot correllogram and Interval plot
        ideal_intervals2 = round(time_intervals2/samp_per) * samp_per;
        resid2 = time_intervals2-ideal_intervals2;
        
        if exist('verbose', 'var') && verbose
            figure;
            win_dim = get(0, 'MonitorPositions');
            set(gcf, 'Position', [(win_dim(3)-800)/2, (win_dim(4)-400)/2, 800, 400]);
            
            subplot(1, 2, 1); scatter(resid2(2:end)*1000, resid2(1:end-1)*1000); 
            title('Serial correlations in ISI');
            subplot(1, 2, 2); plot(1000*(mtime(2:end)-mtime(1:end-1))); hold on; 
            plot(1000*(mtime2(2:end)-mtime2(1:end-1)), 'r');
            title('Intervals, before and after');
            legend('before', 'after');
            % subplot(1, 3, 3); plot(1000*(mtime-mtime2)); title('Cumulative time shift');
            
            % save image
            [my_im, my_map] = rgb2ind(frame2im(getframe(gcf)), 16);
            annotate.after_corr_img_a.ind_data = my_im;
            annotate.after_corr_img_a.cmap = my_map;
            
        end;
        
        % check intervals after dev_ind
        time_intervals2 = diff(mtime2);
        annotate.deviated_ind = deviated_ind;
        annotate.deviated_int = time_intervals(deviated_ind);
        annotate.after_dev_pts = time_intervals2(deviated_ind+1);
        
        % just in case we wind up with doubled-up timepoints because of the above assumption,
        % undo the correction on those points and nudge forward instead.
        undo_ind = find(diff(mtime2)< 0.85 * samp_per);
        undo_ind = intersect(undo_ind, deviated_ind);
        %mtime2(undo_ind) = mtime(undo_ind);
        
        annotate.undo_pts = length(undo_ind);
        annotate.push_forward_pts = sum(diff(mtime2)< 0.85 * samp_per);
        annotate.filtration_vals = [0.85:0.01:1.00];
        annotate.filtration = zeros(size(annotate.filtration_vals));
        for v = 1:length(annotate.filtration_vals)
            annotate.filtration(v) = sum(diff(mtime2)< annotate.filtration_vals(v) * samp_per);
        end;
        
        % actually undo the correction
        mtime2(undo_ind+1) = mtime2(undo_ind+1) + new_resid(undo_ind);
        
        if exist('verbose', 'var') && verbose
            figure;
            win_dim = get(0, 'MonitorPositions');
            set(gcf, 'Position', [(win_dim(3)-800)/2, (win_dim(4)-400)/2, 800, 400]);
            
            subplot(1, 2, 1); scatter(resid2(2:end)*1000, resid2(1:end-1)*1000); 
            title('Serial correlations in ISI');
            subplot(1, 2, 2); plot(1000*(mtime(2:end)-mtime(1:end-1))); hold on; 
            plot(1000*(mtime2(2:end)-mtime2(1:end-1)), 'r');
            title('Intervals, before and after');
            legend('before', 'after');
            % subplot(1, 3, 3); plot(1000*(mtime-mtime2)); title('Cumulative time shift');
            
            % save image
            [my_im, my_map] = rgb2ind(frame2im(getframe(gcf)), 16);
            annotate.after_corr_img_b.ind_data = my_im;
            annotate.after_corr_img_b.cmap = my_map;
            
        end;
        
        annotate.elapsed_time = toc;
        
        % question:
        % save annotations
        if exist('do_annotate') && do_annotate
            data{i}.runs{j}.annotate = annotate;
        end;
        
        close('all');
    end; % run
end; % subject

return;

%%
% generate graph of residuals: amt each interval has to change to
% go to the closest ideal interval, and serial correlations
function plot_residuals(resid)

% residuals against time
figure; 
win_dim = get(0, 'MonitorPositions');
set(gcf, 'Position', [(win_dim(3)-800)/2, (win_dim(4)-400)/2, 800, 400]);

subplot(1, 2, 1);
plot(resid); title('Deviation between ideal and exact time intervals');

% serial correlation graph
subplot(1, 2, 2); scatter(resid(2:end)*1000, resid(1:end-1)*1000); title('Serial correlations in ISI');
xlabel('Deviation of current point (ms)');
ylabel('Deviation of previous point (ms)');
hold on;
fprintf('Notice all timepoints on the diagonal.  These are all points where\n');
fprintf('a short lag is followed by a long lag, or vice-versa, and the lags \n');
fprintf('sum to the duration of two frames.\n\n');
return;

%%
% generate graph of residuals: amt each interval has to change to
% go to the closest ideal interval, and serial correlations
function [my_im, my_map] = plot_residuals2(resid, deviated_ind, nudge_factor, samp_per)

scatter(resid(deviated_ind+1)*1000, resid(deviated_ind)*1000, 'r');
line(samp_per*500*[-1 1], samp_per*500*[1 -1] + sqrt(nudge_factor.^2)*1000, 'LineStyle', '--', 'Color', [0 0 0]);
line(samp_per*500*[-1 1], samp_per*500*[1 -1] - sqrt(nudge_factor.^2)*1000, 'LineStyle', '--', 'Color', [0 0 0]);
fprintf('Red points are candidates for correction\n\n');

plot(1000*nudge_factor*cos(0:0.1:2*pi), 1000*nudge_factor*sin(0:0.1:2*pi), 'g');
hold off;

[my_im, my_map] = rgb2ind(frame2im(getframe(gcf)), 16);
return;

% check the timepoint correction
function check_correction(deviated_ind, time_intervals, time_intervals2, samp_per)
figure;
num_pts_plot = min(10, numel(deviated_ind));
for k = 1:num_pts_plot
    % plot deviated points
    plot_range = (-4:5) + deviated_ind(k);
    scatter(-4:5, time_intervals(plot_range));
    
    % indicate frame boundaries
    nframes_yrange = 5;
    axis([-4 5 0 samp_per*nframes_yrange]);
    line(repmat([-4;5], 1, nframes_yrange), samp_per*[1;1]*(1:nframes_yrange), 'LineStyle', '--', 'Color', [0 0 0]);
    
    % plot fixed points
    hold on;
    scatter([0 1], [time_intervals2(deviated_ind(k)), time_intervals2(deviated_ind(k)+1)], 'r');
    hold off;
    title('Bad timing segment.  Hit enter for next, q to quit');
    key_pressed = lower(strtrim(input('>> ', 's')));
    if key_pressed == 'q'
        break;
    end;
end;
return;
