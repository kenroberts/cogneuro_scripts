
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
% Assume that the srate of the hardware is highly regular, so that the
% timepoints are acquired at y[n] = shift + srate*n.  A timepoint that has
% less than 1/2 frame of shift has an error of
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

verbose = 1;
for i=1  %:length(data)
    for j = 2  %:length(data{i})
        
        ptime = data{i}.runs{j}.pos.time;
        srate = 1.001/30;
        time_intervals = diff(ptime);
        ideal_intervals = round(time_intervals/srate) * srate;
        resid = time_intervals-ideal_intervals;
        
        if exist('verbose', 'var') && verbose
            % residuals against time
            figure; subplot(1, 2, 1);
            plot(resid); title('Deviation between ideal and exact time intervals');
            
            % serial correlation graph
            subplot(1, 2, 2); scatter(resid(2:end)*1000, resid(1:end-1)*1000); title('Serial correlations in ISI');
            xlabel('Deviation of current point (ms)');
            ylabel('Deviation of previous point (ms)');
            hold on;
            fprintf('Notice all timepoints on the diagonal.  These are all points where\n');
            fprintf('a short lag is followed by a long lag, or vice-versa, and the lags \n');
            fprintf('sum to the duration of two frames.\n\n');
        end;
        
        % Nudge factor: srate*0.05 corresponds to a 5% nudge of a point.
        nudge_factor = srate*0.05;
        
        % finds timepoints within 1/2 nudge_factor of the falling diagonal in the
        % serial correlation plot (consecutive intervals summing to two frames)
        deviated_ind = find(abs(resid(2:end)+resid(1:end-1)) < sqrt(nudge_factor.^2));
        
        % do not nudge points that are close to the origin in the serial
        % correlation plot (these are good data points)
        deviated_ind = setdiff(deviated_ind, find( sqrt(resid(2:end).^2+resid(1:end-1).^2) < 1.5*nudge_factor));
        
        if exist('verbose', 'var') && verbose
            scatter(resid(deviated_ind+1)*1000, resid(deviated_ind)*1000, 'r');
            line(srate*500*[-1 1], srate*500*[1 -1] + sqrt(nudge_factor.^2)*1000, 'LineStyle', '--', 'Color', [0 0 0]);
            line(srate*500*[-1 1], srate*500*[1 -1] - sqrt(nudge_factor.^2)*1000, 'LineStyle', '--', 'Color', [0 0 0]);
            fprintf('Red points are candidates for correction\n\n');
            
            plot(1000*nudge_factor*cos(0:0.1:2*pi), 1000*nudge_factor*sin(0:0.1:2*pi), 'g');
            hold off;
        end;
        
        % do the correction, and use the floor function to move late timepoints
        % backward.  This turns out to be the right thing to do almost all the
        % time.
        ptime2 = ptime;
        new_timepoints = floor(time_intervals/srate) * srate;
        new_resid = time_intervals - new_timepoints;
        ptime2(deviated_ind+1) = ptime2(deviated_ind+1) - new_resid(deviated_ind);
        time_intervals2 = diff(ptime2);
        
        % just in case we wind up with doubled-up timepoints because of the above assumption,
        % undo the correction on those points and nudge forward instead.
        %undo_ind = find(diff(ptime2)==0);
        %ptime2(undo_ind) = ptime(undo_ind);
        
        % check
        %for i=undo_ind
            
        %end
        
        % check the correction
        if exist('verbose', 'var') && verbose
            figure;
            num_pts_plot = min(10, numel(deviated_ind));
            for k = 1:num_pts_plot
                % plot deviated points
                plot_range = (-4:5) + deviated_ind(k);
                scatter(-4:5, time_intervals(plot_range));
                
                % indicate frame boundaries
                nframes_yrange = 5;
                axis([-4 5 0 srate*nframes_yrange]);
                line(repmat([-4;5], 1, nframes_yrange), srate*[1;1]*(1:nframes_yrange), 'LineStyle', '--', 'Color', [0 0 0]);
                
                % plot fixed points
                hold on;
                scatter([0 1], [time_intervals2(deviated_ind(i)), time_intervals2(deviated_ind(k)+1)], 'r');
                hold off;
                title('Bad timing segment.  Hit enter for next, q to quit');
                key_pressed = lower(strtrim(input('>> ', 's')));
                if key_pressed == 'q'
                    break;
                end;
            end;
        end;
        
        
        % and replot correllogram and Interval plot
        ideal_intervals2 = round(time_intervals2/srate) * srate;
        resid2 = time_intervals2-ideal_intervals2;
        
        
        figure; subplot(1, 3, 1); scatter(resid2(2:end), resid2(1:end-1)); title('Serial correlations in ISI');
        subplot(1, 3, 2); plot(ptime(2:end)-ptime(1:end-1)); hold on; plot(ptime2(2:end)-ptime2(1:end-1), 'r');
        subplot(1, 3, 3); plot(ptime-ptime2); title('Cumulative time shift');
    end;
end;
return;


