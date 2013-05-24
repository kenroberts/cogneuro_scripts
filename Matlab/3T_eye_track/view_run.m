function varargout = view_run(varargin)
% VIEW_RUN allows you to plot eye-tracking data from one run
%
% call from the command line like:
% view_run('filenames', filenames, 'data', data) where 
% filenames is cell-array of filenames, and data is a
% struct returned from make_clean_data.


% VIEW_RUN M-file for view_run.fig
%      VIEW_RUN, by itself, creates a new VIEW_RUN or raises the existing
%      singleton*.
%
%      H = VIEW_RUN returns the handle to a new VIEW_RUN or the handle to
%      the existing singleton*.
%
%      VIEW_RUN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIEW_RUN.M with the given input arguments.
%
%      VIEW_RUN('Property','Value',...) creates a new VIEW_RUN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before view_run_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to view_run_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help view_run

% Last Modified by GUIDE v2.5 23-May-2013 11:40:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @view_run_OpeningFcn, ...
                   'gui_OutputFcn',  @view_run_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before view_run is made visible.
function view_run_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to view_run (see VARARGIN)

% Choose default command line output for view_run
handles.output = hObject;

% easy testing with dummy data
if length(varargin) == 0
    input_files = {'131.xlsx', '135.xlsx'};
    clean_data = read_data(input_files);
    %clean_data = make_clean_data(input_files, raw_data);
    varargin = {'filenames', input_files, 'data', clean_data};
end;

% handle command line input:
% expect 'filenames' filenames 'data' data
for i = 1:2:length(varargin)
    if ischar(varargin{i}) && length(varargin) >= i+1
        handles = setfield(handles, varargin{i}, varargin{i+1});
    else
        error('Bad command line input.  Please see help.');
    end;
end;

if ~isfield(handles, 'data') || ~isfield(handles, 'filenames')
    error('Bad command line input.  Please see help.');
else
    subj_str = handles.filenames{1};
    for i = 2:length(handles.filenames), 
        subj_str = strcat(subj_str, '|', handles.filenames{i});
    end;
    set(handles.popupmenu1, 'String', subj_str);
    
    run_str = '1';
    for i = 2:length(handles.data{1}.runs)
        run_str = sprintf('%s|%d', run_str, i);
    end;
    set(handles.popupmenu2, 'String', run_str);
    
    scale_str = '1s|5s|10s|30s|1m|5m';
    set(handles.popupmenu3, 'String', scale_str);
    
    update_slider(handles);
end;

% Update handles structure
guidata(hObject, handles);

% consequence-free redraw of axes
update_axis(handles);

% UIWAIT makes view_run wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% update slider range
function update_slider(handles)
    
%     pos = handles.data{get(handles.popupmenu1, 'Value')}{get(handles.popupmenu2, 'Value')}.pos;
%     events = handles.data{get(handles.popupmenu1, 'Value')}{get(handles.popupmenu2, 'Value')}.events;
%     
%     start_time = min(pos.time(1), events.time(1));
%     end_time = max(pos.time(end), events.time(end));
% 
%     vals = [get(handles.slider1, 'Min') get(handles.slider1, 'Max') get(handles.slider1, 'Value')];
%     
%     scales = {1, 5, 10, 30, 60, 300}; % scale_str = '1s|5s|10s|30s|1m|5m';
%     curr_scale = scales{get(handles.popupmenu3, 'Value')};
%     
%     sl_min = floor(start_time/curr_scale)*curr_scale;
%     sl_max = floor(end_time/curr_scale)*curr_scale;
%     
%     value = (vals(3)-vals(1))/(vals(2)-vals(1)) * (sl_max-sl_min) + sl_min;
%     value = round(value/curr_scale) * curr_scale;
%     
%     fprintf('Slider Min: %f Max: %f Value: %f\n', sl_min, sl_max, value); 
%     
%     set(handles.slider1, 'Min', sl_min, 'Max', sl_max, 'SliderStep', [curr_scale, curr_scale*5], 'Value', value);

% redraw the upper and lower graphs (upper = events, xpos, ypos, lower =
% pupil width and aspect) 
function update_axis(handles)
    data = handles.data{get(handles.popupmenu1, 'Value')}.runs{get(handles.popupmenu2, 'Value')};
    detrend_check = [get(handles.checkbox6, 'Value'), get(handles.checkbox7, 'Value') ];
    
    % absolute start and end times of data
    start_time = min(data.pos.time(1), data.events.time(1));
    end_time = max(data.pos.time(end), data.events.time(end));
    
    scales = {1, 5, 10, 30, 60, 300}; % scale_str = '1s|5s|10s|30s|1m|5m';
    curr_scale = scales{get(handles.popupmenu3, 'Value')};
    
    % set the boundaries for plotting (time-wise)
    plot_start = (end_time-start_time-curr_scale) * get(handles.slider1, 'Value');
    plot_start = plot_start+start_time; plot_end = plot_start + curr_scale;
    
    plot_mask = find(data.pos.time > plot_start & data.pos.time < plot_end);
    axes(handles.axes1);
    hold off;
    if get(handles.checkbox1, 'Value') == 1
        if detrend_check(1) && isfield(data, 'detrend')
            plot(data.pos.time(plot_mask), ...
                data.pos.xpos(plot_mask) - data.detrend.xpos(plot_mask), 'b');
        else
            plot(data.pos.time(plot_mask), data.pos.xpos(plot_mask), 'b');
        end;
        hold on;
    end;
    if get(handles.checkbox2, 'Value') == 1
         if detrend_check(1) && isfield(data, 'detrend')
            plot(data.pos.time(plot_mask), ...
                data.pos.ypos(plot_mask) - data.detrend.ypos(plot_mask), 'r');
        else
            plot(data.pos.time(plot_mask), data.pos.ypos(plot_mask), 'r');
        end;
         hold on;
    end;
    
    % TODO: unlock y-axis, or lock from -1..2
    ax1 = axis(handles.axes1); ax1(3:4) = [0 1]; axis(ax1); % set y-scale to 0-1
    
    % plot pupil width (with different colors if there is 'class'
    % indicating blinks/gaps)
    axes(handles.axes2);
    hold off;
    if get(handles.checkbox3, 'Value') == 1
        if isfield(data.pos, 'class')
            good_class = round(mean(data.pos.class));
            start_ind = find([1; data.pos.class(2:end) ~= data.pos.class(1:end-1); 1]);
            start_ind = [plot_mask(1); intersect(start_ind, plot_mask); plot_mask(end)];
            for j = 1:length(start_ind)-1
                if data.pos.class(start_ind(j)) == good_class
                    plot(data.pos.time(start_ind(j):start_ind(j+1)), ...
                        data.pos.pwidth(start_ind(j):start_ind(j+1)), 'g');
                    hold on;
                else
                    plot(data.pos.time(start_ind(j):start_ind(j+1)), ...
                        data.pos.pwidth(start_ind(j):start_ind(j+1)), 'k');
                    hold on;
                end;
            end;
        else
            plot(data.pos.time(plot_mask), data.pos.pwidth(plot_mask), 'b'); 
        end;
    end;
    
    % plot pupil aspect ratio
    if get(handles.checkbox4, 'Value') == 1
         plot(data.pos.time(plot_mask), data.pos.paspect(plot_mask), 'r');
         hold on;
    end;
    ax2 = axis(handles.axes2); ax2(3:4) = [0 1]; axis(ax2); % set y-scale to 0-1
    
    % plot velocity
    
    
    % plot events
    axes(handles.axes1);
    uniq_ev = unique(data.events.code);
    color_order = get(gca, 'ColorOrder');
    
    plot_ind = [find(data.events.time > plot_start, 1) find(data.events.time < plot_end, 1, 'last')];
    if numel(plot_ind) > 1 && get(handles.checkbox5, 'Value') == 1
        %line_x = repmat(data.events.time(plot_ind(1):plot_ind(2))', 2, 1);
        %line_y = repmat(ax1(3:4)', 1, plot_ind(2)-plot_ind(1)+1);
        
        % lh = line(line_x, line_y);
        for j = plot_ind(1):plot_ind(2)
            %set(lh(j), 'Color', color_order(mod(j, size(color_order, 1)), :));
            uniq_ev_num = find(strcmp(data.events.code(j), uniq_ev));
            curr_color = color_order(mod(uniq_ev_num, size(color_order, 1))+1, :);
            th = text(data.events.time(j), 1, data.events.code(j));
            set(th,  'Color', curr_color );
            th = line([data.events.time(j); data.events.time(j)], [0, 1]);
            set(th,  'Color', curr_color );
        end;
    end;
    
% --- Outputs from this function are returned to the command line.
function varargout = view_run_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
update_slider(handles);
update_axis(handles);

% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2
update_slider(handles);
update_axis(handles);

% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3
update_slider(handles);
update_axis(handles);

% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% fprintf('Value: %f\n', get(hObject,'Value'));
update_axis(handles);



% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in checkbox1.
function checkbox_display_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1
update_axis(handles);

% Hint: get(hObject,'Value') returns toggle state of checkbox4


% --------------------------------------------------------------------
function File_menu_Callback(hObject, eventdata, handles)
% hObject    handle to File_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkbox6.
% SPLINE DETREND X
function checkbox6_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox6


% --- Executes on button press in checkbox7.
% SPLINE DETREND Y
function checkbox7_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox7

% UNLOCK AXES
% --- Executes on button press in checkbox8.
function checkbox8_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox8

% X VELOCITY
% --- Executes on button press in checkbox9.
function checkbox9_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox9
