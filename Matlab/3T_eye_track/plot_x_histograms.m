function plot_x_histogram(clean_data, run)
% plot_x_histograms(clean_data, run)

figure;
    
    for i = 1:length(clean_data)
        subplot(4, 4, i);
        hist(clean_data{i}{run}.pos.xpos, 100);
    end;
    
    %title(['Eye position for run ' num2str(run)]);
return;