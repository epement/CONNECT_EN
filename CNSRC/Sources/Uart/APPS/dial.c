//
// NAME: DIAL.C
//
// TYPE: Win32 console mode.
//
// DATE: August 6, 2004.
//
// PURPOSE: Dials a host or BBS program.
//          Not for establishing an internet connection.
//
// COMPILE: From the command line:
//
//     nmake -f dial32._m_  (Microsoft VC)
//      make -f dial32._b_  (Borland 5.0)
//      make -f dial32._i_  (Borland 5.5)
//     wmake -f dial32._w_  (Watcom 11)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace dial.mak in MSVC IDE.
//     Open workspace dial.dsp in MSVC (ver 6.0 only).
//

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "wsc.h"
#include "keycode.h"
#include "mio.h"
#include "sayerror.h"

char Temp[81];

/*** run the MIO driver ***/

void RunTheDriver(int Port)
{int Code;
 while(1)
   {Code = mioDriver(Port);
    if(Code==MIO_IDLE) break;
    if(Code>=0) printf("%c",Code);
    Sleep(0);
   }
 }

void main(int argc, char *argv[])
{int Code;
 int Port;
 int Baud;
 char *Phone;
 char DialString[64];
 printf("This is a console mode program & is designed to run from a command window.\n");
 printf("_______________\n");
 printf("DIAL Example Program\n");
 if(argc != 4)
   {printf("Usage: DIAL <port> <baud> <phone>\n");
    printf("   Eg: DIAL 1 38400 12568814630\n");
    exit(1);
   }
 // get parameters
 Port = atoi(argv[1]) - 1;
 Baud = atoi(argv[2]);
 Phone = argv[3];
 // display parameters
 printf("Port  : COM%d\n",1+Port);
 printf("Baud  : %1d\n",Baud);
 printf("Phone : %s\n",Phone);
 printf("_______________\n");
 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
   {printf("ERROR: Bad Key Code!");
    exit(1);
   }
 // reset port (8N1 is default)
 Code = SioReset(Port,1024,1024);
 if(Code < 0)
   {SayError(Code,"SioReset");
    exit(1);
   }
 // set baud rate
 SioBaud(Port,Baud);
 // set DTR & RTS
 SioDTR(Port,'S');
 SioRTS(Port,'S');
 // check DSR [set by modem]
 if(SioDSR(Port)==0)
   {printf("DSR is down. Aborting...\n");
    SioDone(Port);
    return;
   }
 if(SioCTS(Port)==0)
   {printf("CTS is down. Aborting...\n");
    SioDone(Port);
    return;
   }
 // set RTS/CTS flow control
 SioFlow(Port,'H');
 // send AT ['!' changed to '\r' by mioSendTo]
 mioSendTo(Port, 125, "!AT!");
 RunTheDriver(Port);
 // expect OK back
 mioWaitFor(Port,5000,"OK");
 RunTheDriver(Port);
 if(!mioResult(Port))
   {printf("Expected OK is NOT seen\n");
    SioDone(Port);
    return;
   }
 // construct dial string ['!' changed to '\r' by mioSendTo]
 lstrcpy((LPSTR)DialString,"!ATDT");
 lstrcat((LPSTR)DialString,Phone);
 lstrcat((LPSTR)DialString,"!");
 // dial
 printf("\nDialing...\n");
 mioSendTo(Port, 125, (LPSTR)DialString);
 RunTheDriver(Port);
 // wait for CONNECT
 mioWaitFor(Port,60000,"CONNECT");
 RunTheDriver(Port);
 if(!mioResult(Port))
   {printf("Expected CONNECT is NOT seen\n");
    SioDone(Port);
    return;
   }
 printf("Connected!");

 // replace Sleep(2000) with your application code.
 Sleep(2000);

 printf("Hanging up.\n");
 SioDTR(Port,'C');

 SioDone(Port);
}
