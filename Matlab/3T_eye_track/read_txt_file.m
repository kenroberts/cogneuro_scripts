function raw_data = read_txt_file(input_filename)
% read in eyetracking data from text files.

    % estimate rows in file (sample file is 104000 lines, and
    % 7781342 bytes) and pad by 5%
    %tic;
    fstruct = dir(input_filename); % has .name and .bytes
    rowest = round(fstruct.bytes*(104000/7781342)*1.05);
    
    raw_data = cell(rowest, 10);
    fid = fopen(input_filename, 'r');
    rows = 0;
    bad_parse = 0;
    while (1)
        [type, succ] = fscanf(fid, '%d\t', 1);
        if ~succ, 
            if ftell(fid) == fstruct.bytes
                break;
            else
                bad_parse = bad_parse+1;
                rows = rows+1;
                fgetl(fid);
                continue;
            end;
        end;
        
        rows = rows+1;
        raw_data{rows, 1} = type;
        switch type
            
            case 2 % parse line type 2 or 3: treat rest of line as a string
                raw_data{rows, 2} = fgetl(fid);
            case 3 % (comment)
                raw_data{rows, 2} = fgetl(fid);
            case 10 % eye-position row with fields: TotalTime(2), DeltaTime(3),
                    % X_Gaze(4), Y_Gaze(5), Region(6), PupilWidth(7),
                    % PupilAspect(8), Count(9), Torsion(10)
                raw_data{rows, 2} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 3} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 4} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 5} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 6} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 7} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 8} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 9} = fgetl(fid);

            case 12 % record time, treat rest of line as a string (marker)
                raw_data{rows, 2} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 3} = fgetl(fid);
                
            case 99 % record time, followed by two ints (
                raw_data{rows, 2} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 3} = fscanf(fid, '%f\t', 1);
                raw_data{rows, 4} = fgetl(fid);
           
            otherwise
                bad_parse = bad_parse + 1;
                fgetl(fid);
        end;
    end
    
    raw_data = raw_data(1:rows, :);
    
    
    %fprintf('Estimate %d rows for file %s.\n', rowest, input_filename);
    %fprintf('Read %d rows in %f seconds, %d lines not parsed.\n', rows, read_time, bad_parse);

return;
