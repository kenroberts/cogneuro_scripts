function plot_joint_histogram(clean_data, subj, run)
%   PLOT_JOINT_HISTOGRAM(clean_data, subj, run)
% clean_data is a cell-array of data, and subj and run index into
% that cell array so that clean_data{subj}{run} is used to create
% the joint 
        
    x_data = clean_data{subj}.runs{run}.pos.xpos;
    y_data = clean_data{subj}.runs{run}.pos.ypos;
    
    % scale + truncate data to desired range (hard coded to -1..2)
    x_data = max(min( (x_data+1)/3, 1), 0);
    y_data = max(min( (y_data+1)/3, 1), 0);
    
    nbins = 100;

    % all data here should be on interval (0..1)
    jh = joint_histogram(x_data, y_data);
    imagesc(linspace(-1,2,100), linspace(-1, 2, 100), full(jh)); axis xy;
       
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% jh = joint_histogram(A, B, nbins)
%
% KCR, made range safe.
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
