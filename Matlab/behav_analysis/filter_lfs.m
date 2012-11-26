function [lfs, ind] = filter_lfs_str(varargin)
% Allows the filtering of a logfile struct using include and exclude lists.
%
% flfs = filter_lfs(lfs, 'include', [100 110 200 210]);
% 
% which results in only events with those codes to be returned.  You may
% also specify an 'exclude' list which will return all events except those
% specified.
%
% [flfs, ind] = filter_lfs(lfs, ...);
%
% will place in ind an array having the same length as the number of
% events in the incoming lfs, which contains the indices of the incoming
% lfs that were preserved.  In other words, flfs.code = lfs.code(ind). 
%
% finally, the last option is 'custom', where a list of indices to be
% preserved is passed in.

% Advanced: pays no attention to the 'colnames' variable.  Just operates
% on filtering out all the fields that are not 'header', 'colnames' or
% 'footer'.
%
% Ken Roberts

% name of each error check to apply
req_names = {...
    sprintf('Must have exactly three arguments.\n'), ...
    sprintf('The second argument must be either ''include'' or ''exclude''\n'), ...
    sprintf('The third argument must be a cellstr.\n'), ...
    sprintf(['If ''custom'' is specified, the third argument must be an array of indices \n' ...
            'within [1, length(lfs)].\n']), ...
    };

% form a matrix of tests composed of individual error check
req_cond(1) = nargin == 3;
inc_or_exc = find(strcmp(lower(varargin{2}), {'include', 'exclude', 'custom'}));
req_cond(2) = ~isempty(inc_or_exc);
req_cond(3) = iscellstr(varargin{3}) || (inc_or_exc == 3);

% set the local variables
lfs = varargin{1};
list = reshape(varargin{3}, 1, prod(size(varargin{3})));

% test all of the required conditions, and print all test case failures.
if ~all(req_cond)
    ind = find(req_cond == 0);
    error(strcat(req_names{ind}));
end;

% switch based on the string in
% varargin{2} and come up with a list of indices that will be in the new struct.
switch inc_or_exc
    case 1 % include the list (find where any code is on the list)
        %ind = find( any((lfs.code*ones(1, length(list)) == ...
        %    ones(length(lfs.code), 1)*list), 2));
        isinlist = false(size(lfs.code));
        for i = 1:length(list)
            isinlist = isinlist | strcmp(lfs.code, list{i});
        end;
        ind = find(isinlist);    
        
    case 2 % exclude the list (find where all codes not on the list) 
        %ind = find( all((lfs.code*ones(1, length(list)) ~= ...
        %    ones(length(lfs.code), 1)*list), 2));
        notinlist = true(size(lfs.code));
        for i = 1:length(list)
            notinlist = notinlist & ~strcmp(lfs.code, list{i});
        end;
        ind = find(notinlist);    
    case 3 % use the custom indices
        ind = list;
end;
    
% build the struct based on the predetermined indices
hfields = setdiff(fieldnames(lfs), {'header', 'colnames', 'footer'});
for i = 1:length(hfields)
    lfs.(hfields{i}) = subsref(lfs.(hfields{i}), struct('type', {'()'}, 'subs', {{ind}}));
end;

% lfs.trial   = lfs.trial(ind);
% ...
% lfs.req_dur = lfs.req_dur(ind);

return;