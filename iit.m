function varargout = iit(varargin)
% IIT MATLAB code for iit.fig
%      IIT, by itself, creates a new IIT or raises the existing
%      singleton*.
%
%      H = IIT returns the handle to a new IIT or the handle to
%      the existing singleton*.
%
%      IIT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IIT.M with the given input arguments.
%
%      IIT('Property','Value',...) creates a new IIT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before iit_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to iit_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help iit

% Last Modified by GUIDE v2.5 09-Jul-2012 21:45:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @iit_OpeningFcn, ...
                   'gui_OutputFcn',  @iit_OutputFcn, ...
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


% --- Executes just before iit is made visible.
function iit_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to iit (see VARARGIN)

% Choose default command line output for iit
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Set initial View
set(handles.Options,'Visible','Off')


% UIWAIT makes iit wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = iit_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function num_nodes_Callback(hObject, eventdata, handles)
% hObject    handle to num_nodes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_nodes as text
%        str2double(get(hObject,'String')) returns contents of num_nodes as a double

if ~isposintscalar(str2num(get(hObject,'String')))
    
    set(handles.warning,'String','Number of nodes must be a positive integer.');
    set(hObject,'String',num2str(size(get(handles.TPM,'Data'),1)));
    
else
    set(handles.warning,'String','');
    gatherAndUpdate(handles)
end


% --- Executes during object creation, after setting all properties.
function num_nodes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_nodes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in net_definition_method.
function net_definition_method_Callback(hObject, eventdata, handles)
% hObject    handle to net_definition_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns net_definition_method contents as cell array
%        contents{get(hObject,'Value')} returns selected item from net_definition_method


% --- Executes during object creation, after setting all properties.
function net_definition_method_CreateFcn(hObject, eventdata, handles)
% hObject    handle to net_definition_method (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% get information from the ui elements and rebuild ui
function gatherAndUpdate(handles)

input_data = gather_data(handles);
updateView(handles,input_data)

% get the current settings from input elements
function input_data = gather_data(handles)

input_data.nNodes = str2double(get(handles.num_nodes,'String'));
input_data.net_definition = get(handles.net_definition_method,'String');

% redraw the GUI based on the current settings
function updateView(handles,input_data)

% update TPM
tpm_old = get(handles.TPM,'Data');
tpm_size_old = size(tpm_old,1);
tpm_size_new = 2^input_data.nNodes;
% increase size
if tpm_size_new > tpm_size_old
    
    tpm_new = eye(tpm_size_new);
    tpm_new(1:tpm_size_old,1:tpm_size_old) = tpm_old;

% decrease size
else
    
    % resize
    tpm_new = tpm_old(1:tpm_size_new,1:tpm_size_new);
        
end

set(handles.TPM,'Data',tpm_new);

% rename cols and rows
names = cell(1,tpm_size_new);
for i = 1:tpm_size_new
    names{i} = dec2bin(i-1,input_data.nNodes);
end
set(handles.TPM,'ColumnName',names,'RowName',names);

% update current state talbe

cur_state_old = get(handles.cur_state,'Data');
cur_state_size_old = length(cur_state_old);

% increase size
if input_data.nNodes > cur_state_size_old
    
    cur_state_new = zeros(1,input_data.nNodes);
    cur_state_new(1:cur_state_size_old) = cur_state_old;

% decrease size
else
    
    cur_state_new = cur_state_old(1:input_data.nNodes);
    
end

set(handles.cur_state,'Data',cur_state_new);


% --- Executes on selection change in view_select.
function view_select_Callback(hObject, eventdata, handles)
% hObject    handle to view_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns view_select contents as cell array
%        contents{get(hObject,'Value')} returns selected item from view_select

view_choices = cellstr(get(hObject,'String'));
% turn all views off
for i = 1:length(view_choices)
    
    this_view = view_choices{i}(view_choices{i} ~= ' ');
    eval(['set(handles.' this_view ',''Visible'',''Off'')'])
    
end

% turn selected view on
selection = view_choices{get(hObject,'Value')};
selection = selection(selection ~= ' ');
eval(['set(handles.' selection ',''Visible'',''On'')'])




% --- Executes during object creation, after setting all properties.
function view_select_CreateFcn(hObject, eventdata, handles)
% hObject    handle to view_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in parallel_option_menu.
function parallel_option_menu_Callback(hObject, eventdata, handles)
% hObject    handle to parallel_option_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns parallel_option_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from parallel_option_menu


% --- Executes during object creation, after setting all properties.
function parallel_option_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to parallel_option_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in state_option_menu.
function state_option_menu_Callback(hObject, eventdata, handles)
% hObject    handle to state_option_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns state_option_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from state_option_menu


% --- Executes during object creation, after setting all properties.
function state_option_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to state_option_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in complex_option_menu.
function complex_option_menu_Callback(hObject, eventdata, handles)
% hObject    handle to complex_option_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns complex_option_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from complex_option_menu


% --- Executes during object creation, after setting all properties.
function complex_option_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to complex_option_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in run_button.
function run_button_Callback(hObject, eventdata, handles)
% hObject    handle to run_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in big_phi_alg_menu.
function big_phi_alg_menu_Callback(hObject, eventdata, handles)
% hObject    handle to big_phi_alg_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns big_phi_alg_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from big_phi_alg_menu


% --- Executes during object creation, after setting all properties.
function big_phi_alg_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to big_phi_alg_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in big_phi_func_menu.
function big_phi_func_menu_Callback(hObject, eventdata, handles)
% hObject    handle to big_phi_func_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns big_phi_func_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from big_phi_func_menu


% --- Executes during object creation, after setting all properties.
function big_phi_func_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to big_phi_func_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in small_phi_func_menu.
function small_phi_func_menu_Callback(hObject, eventdata, handles)
% hObject    handle to small_phi_func_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns small_phi_func_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from small_phi_func_menu


% --- Executes during object creation, after setting all properties.
function small_phi_func_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to small_phi_func_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function noise_Callback(hObject, eventdata, handles)
% hObject    handle to noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of noise as text
%        str2double(get(hObject,'String')) returns contents of noise as a double


% --- Executes during object creation, after setting all properties.
function noise_CreateFcn(hObject, eventdata, handles)
% hObject    handle to noise (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in normalization_menu.
function normalization_menu_Callback(hObject, eventdata, handles)
% hObject    handle to normalization_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns normalization_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from normalization_menu


% --- Executes during object creation, after setting all properties.
function normalization_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to normalization_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when entered data in editable cell(s) in TPM.
function TPM_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to TPM (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)

% can i know which one they changed?
if any(get(hObject,'Data') < 0 || get(hObject,'Data') > 1)
    
    set(handles.warning,'String','Entries in the TPM must be in [0,1].');  
    
else
    
    set(handles.warning,'String','');
    
end

    