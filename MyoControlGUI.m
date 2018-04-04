function varargout = MyoControlGUI(varargin)
% MYOCONTROLGUI MATLAB code for MyoControlGUI.fig
%      MYOCONTROLGUI, by itself, creates a new MYOCONTROLGUI or raises the existing
%      singleton*.
%
%      H = MYOCONTROLGUI returns the handle to a new MYOCONTROLGUI or the handle to
%      the existing singleton*.
%
%      MYOCONTROLGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MYOCONTROLGUI.M with the given input arguments.
%
%      MYOCONTROLGUI('Property','Value',...) creates a new MYOCONTROLGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MyoControlGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MyoControlGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MyoControlGUI

% Last Modified by GUIDE v2.5 11-Jun-2016 15:29:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MyoControlGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @MyoControlGUI_OutputFcn, ...
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


% --- Executes just before MyoControlGUI is made visible.
function MyoControlGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MyoControlGUI (see VARARGIN)

% Choose default command line output for MyoControlGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

delete(instrfindall); % Reset Com Port
delete(timerfindall); % Delete Timers

% *************************************************
% Constants
% *************************************************
BAUDRATE = 57600;
INPUTBUFFER = 2048;

% SET LOGO
axes(handles.axes3)
imshow('neurolab.png')
set(gca,'visible','off')


% Set charts
set(handles.axes1,'ylim',[-512 512]);
ht1=get(handles.axes1,'title');
set(ht1,'string','Channel 1');
set(handles.axes2,'ylim',[-512 512]);
ht2=get(handles.axes2,'title');
set(ht2,'string','Channel 2');
    

% Create a serial object
if ispc
    portname = 'COM3'; % Windows
    %portname = 'COM24'; % Bluetoooth
elseif ismac   
    portname = '/dev/tty.KeySerial1'; % OSX
    portname = '/dev/tty.usbmodemFA131';
    portname = '/dev/tty.usbmodem1411';
    
end

board = serial(portname, 'BaudRate', BAUDRATE, 'DataBits',8); % serial port variable
%board = Bluetooth('HC-06', portname, 'BaudRate', BAUDRATE, 'DataBits',8); % Bluetooth variable
%board = Bluetooth('HC-06',1);

% Set serial port buffer
set(board,'InputBufferSize', INPUTBUFFER);
fopen(board);

% Setup two stripcharts
AxesWidth = 1; % Axes Width (s)
Nchan = 2;
Fs = 2048; % sampling rate
stripchart(handles.axes1,Fs,AxesWidth,Nchan);
hl = findobj(handles.axes1,'Tag','StripChart');  % hl(1) is 2, hl(2) is 1...
if get(handles.radiobutton1_raw,'value')
  set(hl(2),'linestyle','-');
else
  set(hl(2),'linestyle','none');
end
if get(handles.radiobutton1_env,'value')
  set(hl(1),'linestyle','-','linew',2);
else
  set(hl(1),'linestyle','none');
end

stripchart(handles.axes2,Fs,AxesWidth,Nchan);
hl = findobj(handles.axes2,'Tag','StripChart');  % hl(1) is 2, hl(2) is 1...
if get(handles.radiobutton2_raw,'value')
  set(hl(2),'linestyle','-');
else
  set(hl(2),'linestyle','none');
end
if get(handles.radiobutton2_env,'value')
  set(hl(1),'linestyle','-','linew',2);
else
  set(hl(1),'linestyle','none');
end

% Setup a timer
% The timer has a callback that reads the serial port and updates the
% stripchart
% Construct a timer object with a timer callback funciton handle,
% getData
TIMER_PERIOD = .003;
TIMER_PERIOD = 0.05; % 100 packets at 2048 Hz = 100/2048
%TIMER_PERIOD = 0.5;
t = timer('TimerFcn', @(x,y)get2Data(handles), 'Period', TIMER_PERIOD);
set(t,'ExecutionMode','fixedRate');
setappdata(hObject, 'TimerObj', t); 
setappdata(hObject, 'SerialObj', board); 

% UIWAIT makes MyoControlGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MyoControlGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in startbutton2.
function startbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to startbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%fclose('all'); % close all open files
%delete(instrfindall); % Reset Com Port
%delete(timerfindall); % Delete Timers
t = getappdata(handles.figure1,'TimerObj');
start(t);

% --- Executes on button press in stopbutton1.
function stopbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to stopbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
t = getappdata(handles.figure1,'TimerObj');
stop(t);


% --- Executes on button press in radiobutton1_raw.
function radiobutton1_raw_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1_raw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1_raw
hl = findobj(handles.axes1,'Tag','StripChart');  % hl(1) is 2, hl(2) is 1...
if get(hObject,'Value') % raw is selected
    set(hl(2),'linestyle','-')
else
    set(hl(2),'linestyle','none')
end 

% --- Executes on button press in radiobutton1_env.
function radiobutton1_env_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1_env (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1_env
hl = findobj(handles.axes1,'Tag','StripChart');  % hl(1) is 2, hl(2) is 1...
if get(hObject,'Value') % env is selected
    set(hl(1),'linestyle','-')
else
    set(hl(1),'linestyle','none')
end 


% --- Executes on button press in radiobutton2_raw.
function radiobutton2_raw_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2_raw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2_raw
% get(hObject,'Value')
hl = findobj(handles.axes2,'Tag','StripChart');  % hl(1) is 2, hl(2) is 1...
if get(hObject,'Value') % raw is selected
    set(hl(2),'linestyle','-')
else
    set(hl(2),'linestyle','none')
end 

% --- Executes on button press in radiobutton2_env.
function radiobutton2_env_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2_env (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2_env
hl = findobj(handles.axes2,'Tag','StripChart');  % hl(1) is 2, hl(2) is 1...
if get(hObject,'Value') % raw is selected
    set(hl(1),'linestyle','-')
else
    set(hl(1),'linestyle','none')
end 
