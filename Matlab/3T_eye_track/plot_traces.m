function plot_traces(clean_data, run)
% plot_traces(clean_data, run)
% stacks traces

figure;
for i = 1:length(clean_data)
    % X axis
    subplot(1,2,1);
    color_order = get(gca, 'ColorOrder');
    plot(clean_data{i}.runs{run}.pos.xpos+2*i, ...
        'Color', color_order(mod(i, 7), :));  
    if i == 1
        hold on;
        title(['X eye position for run ' num2str(run)]);
    end;

    % Y axis
    subplot(1,2,2);
    plot(clean_data{i}.runs{run}.pos.ypos+2*i, ...
        'Color', color_order(mod(i, 7), :));
    if i == 1
        hold on;
        title(['Y eye position for run ' num2str(run)]);
    end;

end;

return;