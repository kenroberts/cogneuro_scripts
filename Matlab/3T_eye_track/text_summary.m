function descrip = text_summary(data)
% creates text summary of a single subject's eyetrack data
%
% Ken roberts

descrip = {};

descrip{end+1} = 'Summary of subject data:';
descrip{end+1} = '';
descrip{end+1} = 'Runs:';

for i = 1:length(data.runs)
    start_time = min([ min(data.runs{i}.events.time), ...
                        min(data.runs{i}.pos.time), ...
                        min(data.runs{i}.nodata.time) ]);
    end_time = max([ max(data.runs{i}.events.time), ...
                        max(data.runs{i}.pos.time), ...
                        max(data.runs{i}.nodata.time) ]);
    descrip{end+1} = sprintf('    Run %2d: %8.2f seconds', i, end_time - start_time);
end;

descrip{end+1} = '';
descrip{end+1} = 'Event counts:';

if (0) % make ugly table
    for i = 1:length(data.runs)
        descrip{end+1} = sprintf('Run %d:', i);
        event_str = unique(data.runs{i}.events.code);
        event_str = sort(event_str);
        for j = 1:length(event_str)
            descrip{end+1} = sprintf('\t%s:\t %d', event_str{j}, ...
                sum(strcmp(data.runs{i}.events.code, event_str{j})) );
        end;
    end;
    
else % make more compact table

    descrip{end+1} = sprintf('%16s', ' ');
    
    event_str = {}; % gather event codes
    for i = 1:length(data.runs)
        descrip{end} = [descrip{end}, sprintf('Run %2d    ', i) ];
        event_str = cat(1, event_str, data.runs{i}.events.code);
    end;
    event_str = sort(unique(event_str));
        
    % print rest of table
    for i = 1:length(event_str)
        descrip{end+1} = sprintf('%9s:', event_str{i});
        for j = 1:length(data.runs)
            descrip{end} = sprintf('%s%10d', descrip{end}, ...
                sum(strcmp(data.runs{j}.events.code, event_str{i})) );
        end;
    end;
end;

descrip = descrip';