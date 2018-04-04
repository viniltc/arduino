
function get2Data(hdl)
% Receive the Data
% After sending the start command to the Arduino, the receiver will start
% receiving values and writing them to the serial port

% Payload:
% struct Olimexino328_packet
% {
%   uint8_t	sync0;		// = 0xa5
%   uint8_t	sync1;		// = 0x5a
%   uint8_t	version;	// = 2 (packet version)
%   uint8_t	count;		// packet counter. Increases by 1 each packet.
%   uint16_t	data[6];	// 10-bit sample (= 0 - 1023) in big endian (Motorola) format.
%   uint8_t	switches;	// State of PD5 to PD2, in bits 3 to 0.
% };

header = hex2dec({'a5','5a'});
hsize = length(header);
PACKETSIZE = 17; % packet size
payload = zeros(PACKETSIZE,1);

board = getappdata(hdl.figure1,'SerialObj');

%% Parse the Data

%PACKETS = 1024; % no. of packets received per read
PACKETS = 100; % no. of packets received per read
data1 = zeros(PACKETS,6);
for j = 1:PACKETS
    
    % look for header
    ishead = 1;
    h=1;
    while ishead & h<=hsize, % look for header
        tmp = fread(board, 1);
        ishead = tmp==header(h);
        h=h+1;
    end
    
    % Receive remaining packet
    if ishead  % header received
        %disp('Got header! Reading data packet...');        
        payload(1:PACKETSIZE-hsize,1) = fread(board, PACKETSIZE-hsize);
        for n = 1:6 % all 6 channels  
            data1(j,n) =  payload(3+2*(n-1))*256+payload(4+2*(n-1));
        end
    end
end
%% Update the stripchart for data
stripchart(hdl.axes1,[(8*(data1(:,1)-512))+128,data1(:,2)/2]) 
set(hdl.axes1,'ylim',[-512 512]);
drawnow;

stripchart(hdl.axes2,[(8*(data1(:,3)-512))+128,data1(:,4)/2]) 
set(hdl.axes2,'ylim',[-512 512]);
drawnow;
 
 