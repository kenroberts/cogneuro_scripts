function plot_joint_histograms(sub_data, run)
    % plot_joint_histograms(sub_data, run)
    
    figure;
    nsubs = length(sub_data);
    x_dim = ceil(sqrt(nsubs));
    y_dim = ceil(nsubs/x_dim);
    
    for i = 1:nsubs
        subplot(x_dim, y_dim, i);
        plot_joint_histogram(sub_data, i, run);
    end;
    
return;


