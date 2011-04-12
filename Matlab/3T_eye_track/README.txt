Project 3T_eye_track:

Goal: develop command-line and visual set of tools for reading in 
eye-tracking data.

ET struct:

subject_data{}
    -> runs{}
        -> events()  // correspond to lines marked 12 in raw file
            row, time and code
        -> nodata()  // lines marked 99 (can't find pupil)
            row, time
        -> pos()     // lines marked 10 (position data)
            row, time, xpos, ypos, pwidth, paspect
    -> history
        -> commands{}
    -> header
        -> lines{}
    -> cache