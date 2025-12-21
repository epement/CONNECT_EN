//
// NAME: EVENT.C
//
// TYPE: Win32 console mode.
//
// DATE: August 6, 2004.
//
// PURPOSE: Terminal emulator similar to SIMPLE that uses SioEvent in a thread.
//          Also see EVENTS.C which uses SioPuts rather than SioPutc.
//
//       Event flags (defined in winbase.h) that can be passed to SioEvent:
//
//         EV_RXCHAR    -- Any character received
//         EV_RXFLAG    -- Received certain character
//         EV_TXEMPTY   -- Transmit queue empty
//         EV_CTS       -- CTS changed state
//         EV_DSR       -- DSR changed state
//         EV_RLSD      -- RLSD changed state
//         EV_BREAK     -- BREAK received
//         EV_ERR       -- Line status error occurred
//         EV_RING      -- Ring signal detected
//         EV_PERR      -- Printer error occured
//         EV_RX80FULL  -- Receive buffer is 80 percent full
//
// COMPILE: From the command line:
//
//     nmake -f event32._m_  (Microsoft VC)
//      make -f event32._b_  (Borland 5.0)
//      make -f event32._i_  (Borland 5.5)
//     wmake -f event32._w_  (Watcom 11)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace event.mak in MSVC IDE.
//     Open workspace event.dsp in MSVC (ver 6.0 only).
//
// ALSO SEE: echoport.c
//

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>

#include "wsc.h"
#include "keycode.h"
#include "sayerror.h"

typedef struct
{int Port;
 int BytesRead;
} ParamType;

// 'TheThread' handles all incoming serial data
// independently of the main program.

void TheThread(PVOID pvoid)
{int Code;
 char Buffer[128];
 ParamType *ParamPtr;
 ParamPtr = (ParamType *) pvoid;
 while(1)
   {Sleep(0);
    // grab all available data
    Code = SioGets(ParamPtr->Port,(LPSTR)Buffer,127);
    if(Code>0)
      {ParamPtr->BytesRead += Code;
       Buffer[Code] = '\0';
       printf("%s",Buffer);
       fflush(stdout);
      }

    //
    // SioEvent will block this thread until there is more data.
    //
    // NOTE: This thread can also be unblocked by calling
    //       SioSetInteger(Port,'S',1) from the main program or
    //       from another thread.

    SioEvent(ParamPtr->Port, EV_RXCHAR);
   }
}

HANDLE CreateTheThread(PVOID Params)
{DWORD ThreadID;
 HANDLE ThreadHandle;
 // start thread to handle incoming serial
 ThreadHandle = CreateThread(0,1024,(LPTHREAD_START_ROUTINE)TheThread,Params,0,&ThreadID);
 if(ThreadHandle==0)
   {printf("ERROR: Could not start thread\n");
    return (HANDLE)-1;
   }
 return ThreadHandle;
}

// trap WSC error codes

int ErrorCheck(int Port, int Code)
{if(Code<0)
   {SayError(Code,NULL);
    SioDone(Port);
    exit(1);
   }
 return Code;
}

///* main **

void main(int argc, char *argv[])
{int Version;
 int Build;
 HANDLE ThreadHandle;
 ParamType Params;
 char c;
 int Port;
 int Baud;
 printf("This is a console mode program & is designed to run from a command window.\n");
 // process args
 if(argc!=3)
   {printf("Usage: EVENT <port> <baud>\n");
    printf("   Eg: EVENT 1 19200\n");
    return;
   }
 Port = atoi(argv[1]) - 1;
 Baud = atoi(argv[2]);
 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
   {printf("ERROR: Bad Key Code!");
    return;
   }
 Version = SioInfo('V');
 Build = SioInfo('B');
 printf("WSC Version %d.%d.%d (Build %d)\n",
   (Version>>8),0x0f&(Version>>4),0x0f&Version,Build);
 // reset the port
 ErrorCheck( Port, SioReset(Port,1024,1024) );
 ErrorCheck( Port, SioBaud(Port,Baud) );
 // set DTR and RTS
 SioDTR(Port,'S');
 SioRTS(Port,'S') ;
 // save info for thread
 Params.Port = Port;
 Params.BytesRead =  0;
 // start thread to handle incoming serial
 ThreadHandle = CreateTheThread((PVOID)&Params);
 if(ThreadHandle==(HANDLE)-1) exit(1);

 // start main loop
 printf("Type ^Z to abort...\n");

 while(1)
   {// wait for user to type a character (no echo)
    c = getch();
    // quit if user typed ^Z
    if(c==0x1a) break;
    else SioPutc(Port,c);
    Sleep(0);
   }

 TerminateThread(ThreadHandle,0);
 printf("\n_____________________\n");
 printf("%d bytes were received\n", Params.BytesRead);
 SioDone(Port);
} // end main

