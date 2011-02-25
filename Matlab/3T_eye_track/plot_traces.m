function plot_traces(clean_data, run)
% plot_traces(clean_data, run)
%

    figure;
    for i = 1:length(clean_data)
        subplot(1,2,1);
        plot(clean_data{i}{run}.pos.xpos+2*i); 
        hold on;
        if i==1, title(['X eye position for run ' num2str(run)]), end;
        
        subplot(1,2,2);
        plot(clean_data{i}{run}.pos.ypos+2*i); 
        hold on;
        if i==1, title(['Y eye position for run ' num2str(run)]), end;
    end;
return;