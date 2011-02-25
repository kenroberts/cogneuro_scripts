function plot_trace(clean_data, run, subject)
% plot_trace(clean_data, run, subject)
%
% plot on same axes, pts_per_line points of xpos traces and ypos traces

    pts_per_line = 1000;
    num_lines = ceil( length(clean_data{subject}{run}.pos.pos_row)/pts_per_line );
    figure;
    axis ij;
    
    % plot each line of the trace
    for i = 1:num_lines
        
        range_start = pts_per_line*(i-1)+1;
        
        % plotting last line?
        if i == num_lines
            last_line_pts = length(clean_data{subject}{run}.pos.ypos) - range_start + 1;
            p1 = plot(0:last_line_pts-1, clean_data{subject}{run}.pos.ypos(range_start:end)+2*i, 'r');
            p2 = plot(0:last_line_pts-1, clean_data{subject}{run}.pos.xpos(range_start:end)+2*i, 'b');
            legend([p1, p2], 'x pos', 'y pos');
        else
            plot(0:pts_per_line-1, clean_data{subject}{run}.pos.ypos(range_start:(range_start+pts_per_line-1))+2*i, 'r');
            hold on;
            plot(0:pts_per_line-1, clean_data{subject}{run}.pos.xpos(range_start:(range_start+pts_per_line-1))+2*i, 'b');
        end;
    end;
        
    axis ij;
    
    title(['Eye position for subject ' num2str(subject) ' run ' num2str(run)]);
return;
