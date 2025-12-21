//
// NAME: DEVICE.C
//
// TYPE: Win32 console mode.
//
// DATE: August 6, 2004.
//
// PURPOSE: Sends a command string (followed by a CR) to a serial device
//          and gets a response.
//
// COMPILE: From the command line:
//
//     nmake -f device32._m_  (Microsoft VC)
//      make -f device32._b_  (Borland 5.0)
//      make -f device32._i_  (Borland 5.5)
//     wmake -f device32._w_  (Watcom 11)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace device.mak in MSVC IDE.
//     Open workspace device.dsp in MSVC (ver 6.0 only).
//

#include <windows.h>
#include <stdio.h>
#include <string.h>

#include "wsc.h"
#include "keycode.h"

#define RESPONSE_WAIT 500
#define QUOTE 0x22

static int Parity   = WSC_NoParity;
static int StopBits = WSC_OneStopBit;
static int DataBits = WSC_WordLength8;

static char Temp[512];
static int  Port;

// trap WSC error codes

int ErrorCheck(int Code)
{if(Code<0)
   {long WinErr;
    printf("ERROR %d ",Code);
    if(Code==WSC_WIN32ERR)
      {WinErr = SioWinError((LPSTR)Temp,80);
       printf("(%d): %s\n",WinErr,(LPSTR)Temp);
      }
    else printf("\n");
    SioDone(Port);
    exit(1);
   }
 return Code;
}

//** main **

void main(int argc, char *argv[])
{char c;
 int  i;
 int  Baud;
 int  CmdLen;
 int  Code;
 LPSTR CmdPtr;
 long  CharWait;
 printf("This is a console mode program & is designed to run from a command window.\n");
 // process args
 if(argc!=5)
   {printf("Usage: device <port> <baud> <command> <char_wait>\n");
    printf("   Eg: device 2 19200 AT 100\n");
    printf("   Eg: device 1 9600 %cThis is a test%c 100\n",QUOTE,QUOTE);
    return;
   }
 Port = atoi(argv[1]) - 1;
 Baud = atoi(argv[2]);
 CmdPtr = (LPSTR)argv[3];
 CharWait = (long) atoi(argv[4]);
 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
   {printf("ERROR: Bad Key Code!");
    return;
   }
 // reset (initialize) the port
 ErrorCheck( SioReset(Port,1024,1024) );
 ErrorCheck( SioBaud(Port,Baud) );
 ErrorCheck( SioDTR(Port,'S') );
 ErrorCheck( SioRTS(Port,'S') );
 ErrorCheck( SioParms(Port,Parity,StopBits,DataBits) );
 printf("    Port : COM%1d\n", 1+Port);
 printf("    Baud : %u\n", Baud);
 printf("     DTR : set\n");
 printf("     RTS : set\n");

 //
 // Hardware flow control should be set if and only if the serial
 // device sets hardware flow control.
 //

#if 0
 ErrorCheck( SioFlow(Port, 'H') );
 printf("    Flow : Hardware\n");
#else
 printf("    Flow : None\n");
#endif

 printf("  Parity : %d\n",Parity);
 printf(" Command : %s\n", CmdPtr);
 printf("CharWait : %ld\n",CharWait);
 printf("StopBits : %d\n",StopBits);
 printf("DataBits : %d\n",DataBits);
 if(SioDSR(Port)) printf("     DSR : set\n");
 else printf("     DSR : clear\n");
 if(SioCTS(Port)) printf("     CTS : set\n");
 else printf("     CTS : clear\n");
 CmdLen = strlen(CmdPtr);
 printf("Sending %c%s%c with %d mSec delay between characters\n",
   QUOTE,CmdPtr,QUOTE,CharWait);
 // send one character at a time
 for(i=0;i<CmdLen;i++)
   {c = CmdPtr[i];
    // map '!' to CR (so can specify CR in command string)
    if(c=='!') c = '\r';
    ErrorCheck( SioPutc(Port, c) );
    // now sleep
    Sleep(CharWait);
   }
 // send carriage return
 SioPutc(Port, 13);
 // allow time for response
 printf("Sleeping %ld milliseconds\n", RESPONSE_WAIT);
 Sleep(RESPONSE_WAIT);
 Code = SioGets(Port,(LPSTR)Temp, 512);
 if(Code<0) ErrorCheck(Code);
 printf("Serial device returning %d bytes\n", Code);
 Temp[Code] = '\0';
 printf("%s\n", Temp);
 SioDone(Port);
} // end main

