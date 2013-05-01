% 3T_EYE_TRACK
%
% Files
% the (numbers) indicate 1-5 how complete the feature is.

%   read_data             - (4) read eyetracking data out of txt or excel files.
%                           seems to work well, needs improvement in cache 
%                           part (only works with exact args), 
                            


%   detrend_eye_data      - (2) detrends eye-tracking data (linear)
%                           does not work with mult subs, should add
%                           det.data as separate part of run struct

%   dump_png_or_gif       - (4) makes a 256 color png or gif out of the current figure.
%                           (could add to animate gif)

%   make_pst              - (1) make_pst(clean_data, evt_code)
%                           doesn't work, may need corrected timebase

%   nudge_correction      - (3) nudge_correction(data)
%                           seems to work


%   plot_joint_histogram  - (4) PLOT_JOINT_HISTOGRAM(clean_data, subj, run)
%   plot_joint_histograms - (4) plot_joint_histograms(clean_data, run)
%   plot_trace            - (4) plot_trace(clean_data, run, subject)
%   plot_traces           - (4) plot_traces(clean_data, run)
%   plot_x_histograms     - (3) plot_x_histograms(clean_data, run)
%                           could do a better job w/ rows/cols
%   split_data            - (4) splits continuous eye-tracking data into separate "runs"
%   split_runs            - 
%   test_eyetrack         - script for testing eye-tracking code-> snippets to cut and paste into the 
%   text_summary          - (4) creates text summary of a single subject's eyetrack data
%   view_run              - (3) allows you to plot eye-tracking data from one run
%   view_sub              - (3) view_sub allows you to plot eye-tracking data from one run
%                           both these need to integrate some of the
%                           options that are currently built into the guis.


%%%%% not meant to be public

%   read_xls_file         - used by read_data
%   read_txt_file         - doesn't really work- needs to put things in
%                           struct
%   est_quality           - est_quality(xl_files, subj_xl_data)
%                           useless, unless used inside of read_data

