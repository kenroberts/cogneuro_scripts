%function q = plot_velocity(q)

sub = 1;
run = 1;

pos = q{sub}.runs{run}.pos;

if 0
    figure;
    
    % plot x position
    subplot(2, 1, 1);
    %plot(pos.time, pos.xpos);
    %hold on;
    
    xpmf = medfilt1(pos.xpos, 9);
    plot(pos.time, xpmf, 'r');
    %hold off;
    
    
    % plot velocity
    subplot(2, 1, 2);
    
    %v = (pos.xpos(2:end)-pos.xpos(1:end-1)) ./ (pos.time(2:end)-pos.time(1:end-1));
    %plot(pos.time(1:end-1), v);
    %hold on;
    xv = (xpmf(2:end)-xpmf(1:end-1)) ./ (pos.time(2:end)-pos.time(1:end-1));
    plot(pos.time(1:end-1), v2, 'r');
    %hold off;
    
    figure;
    hist(v2, 100);

else

    % miniconclusion 1: use 9pt running median filter on position
    % calculate the velocity from that
    xpmf = medfilt1(pos.xpos, 9);
    xv = [(xpmf(2:end)-xpmf(1:end-1)) ./ (pos.time(2:end)-pos.time(1:end-1)); 0];

    % now, calculate the density of events
    % first, calculate time range from -1s before 1st event to +1s after last
    % (skipping the first and last event)
    ev_t = [q{sub}.runs{run}.events.time(2), q{sub}.runs{run}.events.time(end-1)];
    ev_t = ev_t + [-1 1];
    
    time_mask = find(pos.time > ev_t(1) & pos.time < ev_t(2));
    
    
    % adjust a symmetric velocity threshhold so that the number of saccades
    % is approximately equal to the number of events
    xv_t = xv(time_mask);
    [xvs, sort_ind] = sort( abs(xv_t), 1, 'descend' );
    num_events = length(q{sub}.runs{run}.events.time);
    
    % start with all points labeled as '0', or not-saccade.
    % starting with highest velocity, label that timepoint as being a
    % saccade (as '1') and update the number of connected components.
    % that is , if 0 0 0 -> 0 1 0 the number of components jumps by 2.
    % if 0 0 1 -> 0 1 1, no change, and 1 0 1 -> 1 1 1, drop by 2.
    curr_ind = 1; 
    cl = zeros(size(xv_t));
    num_comp = 1;
    while num_comp < 2*num_events
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
       
    plot(pos.time, xpmf);
    hold on;
    plot(pos.time(time_mask), cl, 'r');
    hold off;
    
    % plot timing intervals between saccades
    figure;
    s_start = find(cl(2:end)-cl(1:end-1) == 1);          % these are now ind. into time_mask
    s_start = s_start + time_mask(1)-1;                 % now ind into whole thing
    s_int = pos.time(s_start(2:end)) - pos.time(s_start(1:end-1));
    plot(s_int);
    

end;

%return