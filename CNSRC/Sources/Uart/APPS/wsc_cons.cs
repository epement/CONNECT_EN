//
// WSC constants for C# programs
//

const int COM1   = 0;
const int COM2   = 1;
const int COM3   = 2;
const int COM4   = 3;
const int COM5   = 4;
const int COM6   = 5;
const int COM7   = 6;
const int COM8   = 7;
const int COM9   = 8;
const int COM10  = 9;
const int COM11  = 10;
const int COM12  = 11;
const int COM13  = 12;
const int COM14  = 13;
const int COM15  = 14;
const int COM16  = 15;
const int COM17  = 16;
const int COM18  = 17;

// Parity Codes 

const int WSC_NoParity   = 0;
const int WSC_OddParity  = 1;
const int WSC_EvenParity = 2;
const int WSC_MarkParity = 3;
const int WSC_SpaceParity = 4;

// Stop Bit Codes 

const int WSC_OneStopBit   = 0;
const int WSC_One5StopBits = 1;
const int WSC_TwoStopBits  = 2;

// Word Length Codes 

const int WSC_WordLength5  = 5;
const int WSC_WordLength6  = 6;
const int WSC_WordLength7  = 7;
const int WSC_WordLength8  = 8;

// return codes 

const int WSC_BUSY      = (-100);
const int WSC_NO_DATA   = (-100);
const int WSC_RANGE     = (-101);
const int WSC_ABORTED   = (-102);
const int WSC_WIN32ERR  = (-103);
const int WSC_EXPIRED   = (-104);
const int WSC_BUFFERS   = (-105);
const int WSC_THREAD    = (-106);
const int WSC_TIMEOUT   = (-107);
const int WSC_KEYCODE   = (-108);

const int WSC_IE_BADID     = (-1);
const int WSC_IE_OPEN      = (-2);
const int WSC_IE_NOPEN     = (-3);
const int WSC_IE_MEMORY    = (-4);
const int WSC_IE_DEFAULT   = (-5);
const int WSC_IE_HARDWARE  = (-10);
const int WSC_IE_BYTESIZE  = (-11);
const int WSC_IE_BAUDRATE  = (-12);

// baud codes 

const int WSC_Baud110    = 0;
const int WSC_Baud300    = 1;
const int WSC_Baud1200   = 2;
const int WSC_Baud2400   = 3;
const int WSC_Baud4800   = 4;
const int WSC_Baud9600   = 5;
const int WSC_Baud19200  = 6;
const int WSC_Baud38400  = 7;
const int WSC_Baud57600  = 8;
const int WSC_Baud115200 = 9;

// SioGetError masks 

const int WSC_RXOVER   = 0x0001;
const int WSC_OVERRUN  = 0x0002;
const int WSC_PARITY   = 0x0004;
const int WSC_FRAME    = 0x0008;
const int WSC_BREAK    = 0x0010;
const int WSC_TXFULL   = 0x0100;

// SioDTR and SioRTS Commands 

const int WSC_SET_LINE     = 'S';
const int WSC_CLEAR_LINE   = 'C';
const int WSC_READ_LINE    = 'R';

// SioBrkSig Commands 

const int WSC_ASSERT_BREAK = 'A';
const int WSC_CANCEL_BREAK = 'C';
const int WSC_DETECT_BREAK = 'D';

// SioFlow Commands 

const int WSC_HARDWARE_FLOW_CONTROL = 'H';
const int WSC_SOFTWARE_FLOW_CONTROL = 'S';
const int WSC_NO_FLOW_CONTROL       = 'N';

// SioInfo commands 

const int WSC_GET_VERSION     =  'V';
const int WSC_IS_32BITS       =  '3';

// SioSetInteger commands 

const int WSC_WAIT_ON_PUTS =  'W';
const int WSC_BURST_SIZE   =  'B';
const int WSC_SIGNAL       =  'S';

