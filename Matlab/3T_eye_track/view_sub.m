function varargout = view_sub(varargin)
% view_sub allows you to plot eye-tracking data from one run
%
% call from the command line like:
% view_sub('filenames', filenames, 'data', data) where 
% filenames is cell-array of filenames, and data is a
% struct returned from make_clean_data.


% view_sub M-file for view_sub.fig
%      view_sub, by itself, creates a new view_sub or raises the existing
%      singleton*.
%
%      H = view_sub returns the handle to a new view_sub or the handle to
%      the existing singleton*.
%
%      view_sub('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in view_sub.M with the given input arguments.
%
%      view_sub('Property','Value',...) creates a new view_sub or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before view_sub_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to view_sub_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help view_sub

% Last Modified by GUIDE v2.5 02-Nov-2010 15:15:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @view_sub_OpeningFcn, ...
                   'gui_OutputFcn',  @view_sub_OutputFcn, ...
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


% --- Executes just before view_sub is made visible.
function view_sub_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to view_sub (see VARARGIN)

% Choose default command line output for view_sub
handles.output = hObject;

% easy testing with dummy data
if length(varargin) == 0
    global clean_data;
    input_files = {'131.xlsx', '135.xlsx'};
    %input_files = { '35104_1to4.xls' };
    raw_data = read_data(input_files);
    if length(raw_data{1}) == 1
        clean_data = make_clean_data(input_files, raw_data);
    else
        clean_data = raw_data;
    end;
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
    subj_str = handles.filenames{1};  % subjPopup
    for i = 2:length(handles.filenames), 
        subj_str = strcat(subj_str, '|', handles.filenames{i});
    end;
    set(handles.subjPopup, 'String', subj_str);
    
    run_str = '1';                    % runPopup
    for i = 2:length(handles.data{1})
        run_str = sprintf('%s|%d', run_str, i);
    end;
    set(handles.runPopup, 'String', run_str);
    
    trial_types = unique(handles.data{1}{1}.events.code);
    trial_str = trial_types{1};        % trialPopup
    for i = 2:length(trial_types)
        trial_str = sprintf('%s|%s', trial_str, trial_types{i});
    end;
    set(handles.trialPopup, 'String', trial_str);
    handles.mode = 'jointhist';
end;

% Update handles structure
guidata(hObject, handles);

% consequence-free redraw of axes
update_axis(handles);

% UIWAIT makes view_sub wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% redraw the plot
function update_axis(handles)
    sub = get(handles.subjPopup, 'Value');
    run = get(handles.runPopup, 'Value');
    trial = get(handles.trialPopup, 'Value');
    
    axes(handles.axes1);
    
    switch handles.mode
        case 'jointhist'    
            plot_joint_histogram(handles.data, sub, run);
        case 'xhist'
            hist(handles.data{sub}{run}.pos.xpos, 100);
        case 'yhist'
            hist(handles.data{sub}{run}.pos.ypos, 100);
            
        case 'pstx' % peri-stimulus timecourse
            
        case 'psty' % peri-stimulus timecourse    
            
        case 'bfx' % butterfly plot
            
        case 'bfy'
            
        case 'tlax'
            
        case 'tlay'
            
        otherwise
            disp([handles.mode ' not implemented'])
    end
    % set up trial combo-thing.
    
    
    
% --- Outputs from this function are returned to the command line.
function varargout = view_sub_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in subjPopup.
function subjPopup_Callback(hObject, eventdata, handles)
% hObject    handle to subjPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns subjPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from
%        subjPopup
update_axis(handles);

% --- Executes during object creation, after setting all properties.
function subjPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subjPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in runPopup.
function runPopup_Callback(hObject, eventdata, handles)
% hObject    handle to runPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns runPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from runPopup
update_axis(handles);

% --- Executes during object creation, after setting all properties.
function runPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to runPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in trialPopup.
function trialPopup_Callback(hObject, eventdata, handles)
% hObject    handle to trialPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns trialPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from
%        trialPopup
update_axis(handles);

% --- Executes during object creation, after setting all properties.
function trialPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function File_menu_Callback(hObject, eventdata, handles)
% hObject    handle to File_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in acrossSubsButton.
function acrossSubsButton_Callback(hObject, eventdata, handles)
% hObject    handle to acrossSubsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected object is changed in uipanel1.
function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel1 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
handles.mode = get(eventdata.NewValue, 'Tag');
guidata(hObject, handles);
update_axis(handles);
