% 3T_EYE_TRACK
%
% Files

%   read_data             - read eyetracking data out of txt or excel files.
% seems to work well, needs improvement in cache part (only works with
% exact args)
                            
%   read_xls_file         - NOTE: the canonical form of data should be very similar to what

%   read_txt_file         - no longer puts data in proper struct (only
%   hands back big array.


%   detrend_eye_data      - detrends eye-tracking data
%   dump_png_or_gif       - makes a 256 color png or gif out of the current figure.
%   est_quality           - est_quality(xl_files, subj_xl_data)
%   make_pst              - make_pst(clean_data, evt_code)
%   nudge_correction      - nudge_correction(data)
%   plot_joint_histogram  - PLOT_JOINT_HISTOGRAM(clean_data, subj, run)
%   plot_joint_histograms - plot_joint_histograms(clean_data, run)
%   plot_trace            - plot_trace(clean_data, run, subject)
%   plot_traces           - plot_traces(clean_data, run)
%   plot_x_histograms     - plot_x_histograms(clean_data, run)

%   split_data            - splits continuous eye-tracking data into separate "runs"
%   split_runs            - 
%   test_eyetrack         - script for testing eye-tracking code-> snippets to cut and paste into the 
%   text_summary          - creates text summary of a single subject's eyetrack data
%   view_run              - allows you to plot eye-tracking data from one run
%   view_sub              - view_sub allows you to plot eye-tracking data from one run
