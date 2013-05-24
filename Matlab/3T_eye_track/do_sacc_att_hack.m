function data = do_sacc_att_hack(data)
% if experiment is mistakenly programmed so the event codes
% are all shifted one event in advance of where they should
% be, this function will correct that.

for i = 1:length(data)
    for j = 1:length(data{i}.runs)
        evt = data{i}.runs{j}.events;
        evt.code = evt.code(1:end-1);
        evt.time = evt.time(2:end);
        evt.row = evt.row(2:end);
        data{i}.runs{j}.events = evt;
    end;
end;

return;