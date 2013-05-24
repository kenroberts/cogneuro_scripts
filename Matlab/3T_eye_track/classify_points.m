function data = classify_points(data)
% if experiment is mistakenly programmed so the event codes
% are all shifted one event in advance of where they should
% be, this function will correct that.


% possible methods, in order:
% unconst_gmdist1d
%   perform 2-component gaussian mixture model classification on pwidth
% seeded_gmdist1d
%   perform 2-component gaussian mixture model classification on pwidth,
%   starting with a narrow component centered around the median and a wide
%   component a little larger
% unconst_gmdist1d_median
%   first, run a 9-point median filter over data
%   then, classify 2-comp gm on the residual (takes care of
%   nonstationarity)
% 
%

method = 'unconst_gmdist1d';

for i = 1:length(data)
    for j = 1:length(data{i}.runs)
        fprintf('Classifying subject %d run %d.\n', i, j);
        pwidth = data{i}.runs{j}.pos.pwidth;    % most important for rej. mean = 0.2
        pasp = data{i}.runs{j}.pos.paspect;     
        
        % get rid of NaN's if they exist by replicating
        % prev point, quick fix.
        nan_ind = find(isnan(pwidth));
        pwidth(nan_ind) = pwidth(nan_ind-1);
        
        switch method
            
            case 'seeded_gmdist1d'
            
            % KxD matrix (K = components)
            S.mu = [mean(pwidth); mean(pwidth) + 0.1];
            
            % DxDxK matrix
            S.Sigma = permute([0.05; 0.5], [2 3 1]);
            
            obj = gmdistribution.fit(pwidth,2, 'Start', S);
            cl = cluster(obj, pwidth); 
            
            case 'unconst_gmdist1d'
                obj = gmdistribution.fit(pwidth,2);
                cl = cluster(obj, pwidth);
            
            case 'unconst_gmdist1d_median'
                obj = gmdistribution.fit(pwidth-medfilt1(pwidth, 9), 2);
                cl = cluster(obj, pwidth);
                
        end;
        
        % make the most likely class the 1st class
        good_class = round(mean(cl));
        if good_class == 2
            cl = 3-cl;
        end;
        
        
        fprintf('\t\tRejected: %4.2f%%  \n', 100*sum(cl==2)/length(cl));
        
        
        data{i}.runs{j}.pos.class = cl;      
    end;
end;

return;