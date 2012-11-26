function behavior=analysis(varargin);
% This script analyzes the log-files for individual subjects and individual runs
% Users should copy the edit_vars file to their own directory and select it after typing
% analysis in the matlab window.  
% Laura Busse, Feb 7 2002
%              June 6 2002
%              July 4 2002                

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Changelog:
%
% 8/29/02	KCR	Added a call to verifier which will check the input log file.
%						and print out helpful error messages.  If you do not wish for your
%						files to be verified, then just comment out the line 'verifier'.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch nargin,
    case 0   % choose edit_vars with gui
        [hdrName, hdrPath]=uigetfile('*.m', 'Select edit_vars file containing user specified variables.');
        [dummy, hdrName, hdrExt] = fileparts(hdrName);
    case 1   % filename supplied
        [hdrPath, hdrName, hdrExt]=fileparts(varargin{1});
        if isempty(hdrPath), hdrPath=pwd; end;
    otherwise
        error('analysis.m:  Too many input arguments!');
end

%Get hdrFile
try,
    curr_path = pwd;
    cd (hdrPath);
    eval(hdrName);  % Call m-file specified in string hdrName.
catch
    error(['Invalid matlab syntax in file: ' pwd filesep hdrName hdrExt]);
end;

% verify the contents of the edit_vars file
cd(curr_path);
verifier;

% detection task, calculate Hits, False Alarms, Misses, and RT for Hits
% discrimination task, calculate correct & incorrect responses and RT for
% correct responses
switch task
    case 1
        detection;
    case 2
        discrimination;
end