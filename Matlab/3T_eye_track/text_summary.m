function data = text_summary(varargin)
% creates text summary of eyetrack data
% attaches it to the struct
%
%
% Ken roberts

% see if only a single struct is passed in (from one sub) or
% a cell-array of structs.
if isstruct(varargin{1}) && isfield(varargin{1}, 'runs')
    data = { varargin{1} };
else
    data = varargin{1};
end;


for k = 1:length(data)
    
    descrip = {};
    
    descrip{end+1} = 'Summary of subject data:';
    descrip{end+1} = '';
    descrip{end+1} = 'Runs:';
    
    % print run length summary
    for i = 1:length(data{k}.runs)
        start_time = min([ min(data{k}.runs{i}.events.time), ...
            min(data{k}.runs{i}.pos.time), ...
            min(data{k}.runs{i}.nodata.time) ]);
        end_time = max([ max(data{k}.runs{i}.events.time), ...
            max(data{k}.runs{i}.pos.time), ...
            max(data{k}.runs{i}.nodata.time) ]);
        descrip{end+1} = sprintf('    Run %2d: %8.2f seconds', i, end_time - start_time);
    end;
    
    descrip{end+1} = '';
    descrip{end+1} = 'Event counts:';
    
    
    
    descrip{end+1} = sprintf('%16s', ' ');
    
    event_str = {}; % gather event codes
    for i = 1:length(data{k}.runs)
        descrip{end} = [descrip{end}, sprintf('Run %2d    ', i) ];
        event_str = cat(1, event_str, data{k}.runs{i}.events.code);
    end;
    event_str = sort(unique(event_str));
    
    % print rest of table
    for i = 1:length(event_str)
        descrip{end+1} = sprintf('%9s:', event_str{i});
        for j = 1:length(data{k}.runs)
            descrip{end} = sprintf('%s%10d', descrip{end}, ...
                sum(strcmp(data{k}.runs{j}.events.code, event_str{i})) );
        end;
    end;
    
    
    data{k}.description = char(descrip');
    
end; % subject loop

return

