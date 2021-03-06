function [pst_fig, avg_fig] = make_pst(clean_data, evt_code)
% make_pst(clean_data, evt_code)

% hard-code a peri-stimulus interval in ms:
PST_INTERVAL = [-0.2:0.017:0.5];

    pst_fig = figure;
    avg_fig = figure;
    
    peri_code_pts = -20:30;
    for sub=1:length(clean_data)
        
        % clear out pst
        pst = zeros(0, length(PST_INTERVAL));
        
        for run = 1:length(clean_data{sub})
            events = clean_data{sub}.runs{run}.events;
            pos = clean_data{sub}.runs{run}.pos;
            
            time_lock = events.time(strcmp(evt_code, events.code)); 
            pst_run = zeros(length(time_lock), length(PST_INTERVAL));
            % Syntax for intperp1: Vq = interp1(X,V,Xq)
            for k = 1:length(time_lock)
                %tl_ind = find(pos.pos_row > time_lock(k), 1);
                %pst_run(k,:) = pos.xpos(tl_ind + peri_code_pts);
                pst_run(k,:) = interp1(pos.time, pos.xpos, time_lock(k)+PST_INTERVAL);
            end;
            
            pst = cat(1, pst, pst_run);
        end;
        
        % tack on the mean of the pre-code timepoints to beginning and sort
        % on it.
        %pst = cat(2, pst, mean( pst(:, find(peri_code_pts < 0)), 2));
        %pst = sortrows(pst);
        
        % clip values, and 5-pt running avg 
        %pst = min(1, max(pst, 0));
        pst = conv2(pst, [0.2 0.2 0.2 0.2 0.2], 'same');
        figure(pst_fig); subplot(4, 4, sub); imagesc(pst);
        colormap(gray);
        
        % plot line
        start = find(PST_INTERVAL > 0, 1)-1;
        h = line([start, start], [1, size(pst, 1)]);
        set(h, 'Color', [1 0 0]);
        
        
        % try doing a selective average once per subject.
        the_avg = mean(pst, 1);
        figure(avg_fig); 
        subplot(4, 4, sub);
        plot(the_avg);
        axis tight;
        
    end;
    
return;