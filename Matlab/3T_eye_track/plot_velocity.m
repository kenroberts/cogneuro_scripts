function q = plot_velocity(q)

% over subs and runs
for sub = 1:1
    
    for run = 1:1
               
        pos = q{sub}.runs{run}.pos;

        % calculate x, y velocity
        [xpmf, xv] = calculate_velocity(pos.xpos, pos.time);

        
        
        % detect saccades within -1s before 1st event to +1s after last
        % (skipping the first and last event)
        time_range = [q{sub}.runs{run}.events.time(2), q{sub}.runs{run}.events.time(end-1)];
        time_range = time_range + [-1 1];

        % guess: num_events close to number of saccades (may use iterative
        % proc later.)
        num_events = length(q{sub}.runs{run}.events.time);
        num_saccades = num_events;
        
        
        ind_range = [   find(pos.time > time_range(1), 1, 'first') ...
                        find(pos.time < time_range(2), 1, 'last')];
        cl = classify_saccades(xv, ind_range, num_saccades);
        
        sacc_ons = find(cl(2:end)-cl(1:end-1) == 1)+1;
        sacc_int = pos.time(sacc_ons(2:end)) - pos.time(sacc_ons(1:end-1));
        
        if (1)
            % from here on: useful things are xpmf, cl shou
            subplot(2,1, 1); 
            plot(pos.time, xpmf);
            hold on;
            plot(pos.time, cl, 'r');
            hold off;
            legend('xvelocity', 'saccade ons');
            title('saccade detection');
            subplot(2, 1, 2);
            plot(pos.time-xpmf, 'g');
            title('filtering residual x velocity')
            
            % plot timing intervals between saccades
            figure;
            plot(sacc_int);
            hold on;
            plot(sort(sacc_int), 'r');
            hold off;
            legend('time order', 'sorted')
            title('intervals between saccades')

            % plot 30s of velocity, 1m into run
            start_time = 60;
            dur = 15;
            figure;
            ind_range = [find(pos.time > pos.time(1) + start_time, 1, 'first') ...
                            find(pos.time < pos.time(1) + start_time + dur, 1, 'last')];
            plot(pos.time(ind_range(1):ind_range(2)), xv(ind_range(1):ind_range(2)));
            sacc_ons_subset = intersect(ind_range(1):ind_range(2), sacc_ons);
            hold on;
            scatter(pos.time(sacc_ons_subset), xv(sacc_ons_subset), 'r');
            hold off;
            title('30s of velocity')
            legend('x velocity', 'saccade detected');
       
            % plot sacc_ons +- 2 pts as cum sum (only if v(sacc_ons) is pos.
            figure;
            sacc_ons_subset = intersect(sacc_ons, find(xv > 0));
            plot_mat = zeros(length(sacc_ons_subset), 5);
            for i = 1:length(sacc_ons_subset)
                plot_mat(i, :) = cumsum(xv(sacc_ons_subset(i) + [-2 -1 0 1 2]));
            end;
            plot(plot_mat');
            title('peri-saccade velocity cumulative sum')
            pause;
        
        end;
        
        % next, take each connected component (of zeros) and replace with
        % mean.
        sacc_off = find(cl(2:end)-cl(1:end-1) == -1)+1;
        new_xpos = zeros(size(xv));
        start_ind = 1;
        means = zeros(size(sacc_ons));
        for i = 1:length(sacc_ons)
            temp = mean(xpmf(start_ind:sacc_ons(i)-1));
            new_xpos(start_ind:sacc_ons(i)-1) = temp;
            means(i) = temp;
            start_ind = sacc_off(i);
        end;
        new_xpos(cl==1) = xpmf(cl==1);
        
        subplot(2, 1, 1);
        plot(pos.time, xpmf);
        hold on;
        plot(pos.time, new_xpos, 'r');
        hold off;
        xl = xlim;
        
        subplot(2, 1, 2);
        plot(pos.time(sacc_ons(2:end)), means(2:end)-means(1:end-1), 'x');
        xlim(xl);
        
        % plot residual and histogram
        %hist(new_xpos(ind_range(1):ind_range(2)) - ...
         %   xpmf(ind_range(1):ind_range(2)), 100);
        plot(xpmf - new_xpos);
         hist(new_xpos(ind_range(1):ind_range(2)) - ...
            xpmf(ind_range(1):ind_range(2)), 100);
    end;
end; %sub

return;

% miniconclusion 1: use 9pt running median filter on position
% calculate the velocity from that
function [pfilt, vfilt] = calculate_velocity(pos, time)

pfilt = medfilt1(pos, 9);
vfilt = [0; (pfilt(2:end)-pfilt(1:end-1)) ./ (time(2:end)-time(1:end-1)) ];

return;


% pass in an index range rather than a time range
%
 function [cl_full, thresh] = classify_saccades(xv, ind_range, num_saccades)

    
    time_mask = ind_range(1):ind_range(2);
    [~, sort_ind] = sort(abs(xv(time_mask)), 1, 'descend');
     
    % start with all points labeled as '0', or not-saccade.
    % starting with highest velocity, label that timepoint as being a
    % saccade (as '1') and update the number of connected components.
    % that is , if 0 0 0 -> 0 1 0 the number of components jumps by 2.
    % if 0 0 1 -> 0 1 1, no change, and 1 0 1 -> 1 1 1, drop by 2.
    curr_ind = 1; 
    cl = zeros(size(time_mask));
    num_comp = 1;
    while num_comp < 2*num_saccades
        cl(sort_ind(curr_ind)) = 1;
        
        if sort_ind(curr_ind) > 1 && sort_ind(curr_ind) < length(time_mask)
            if cl(sort_ind(curr_ind)-1) == 0
                if cl(sort_ind(curr_ind)+1) == 0 %  0 0 0 -> 0 1 0
                    num_comp = num_comp + 2;
                end;
            else
                if cl(sort_ind(curr_ind)+1) == 1 %  1 0 1 -> 1 1 1
                    num_comp = num_comp - 2;
                end;
            end;
        end; % do not inc or dec if this is first or final pt.
        curr_ind = curr_ind+1;
    end;
    
    thresh = xv(sort_ind(curr_ind));
    % fprintf('Saccade thresh: %f\n', thresh);
    
    % expand cl out to cover whole of pos.
    cl_full = zeros(size(xv));
    cl_full(time_mask) = cl; 
    
    return;