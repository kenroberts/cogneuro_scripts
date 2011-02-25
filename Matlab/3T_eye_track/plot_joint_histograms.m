function plot_joint_histograms(clean_data, run)
    % plot_joint_histograms(clean_data, run)
    figure;
    
    nbins = 100;
    for i = 1:length(clean_data)
        subplot(2, 2, i);
        jh = joint_histogram((clean_data{i}{run}.pos.xpos+1)/3, ...
            (clean_data{i}{run}.pos.ypos+1)/3, nbins);
        imagesc(full(jh')); axis xy;
        
        % set the 'Position' to 'OuterPosition'
        %set(gca, 'Position', get(gca, 'OuterPosition')); 
    end;
    
    %title(['Eye position for run ' num2str(run)]);
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% jh = joint_histogram(A, B, nbins)
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function jh = joint_histogram(A, B, nbins)

if nargin < 3; nbins = 63; end;  % default 

% thus nbins*intensities go from 0 to nbins, rounded 0,1,...,nbins-1
a = round((nbins-1)*A);
b = round((nbins-1)*B);

% little trick to get accelerated histograms: use sparse
jh = sparse(a+1,b+1,1, nbins, nbins); % matlab indexing is 1-based

% Display
if nargout == 0
    imagesc(full(jh));
end;

return;
