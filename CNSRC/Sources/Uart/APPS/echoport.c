//
// NAME: ECHOPORT.C
//
// TYPE: Win32 console mode.
//
// DATE: August 6, 2004.
//
// PURPOSE: Echoes characters incoming on multiple ports using one thread per port.
//
//     (1) Connect serial ports to another computer using a NULL modem cable.
//     (2) Start SIMPLE (or other terminal program) on other computers at 19200 baud.
//     (3) Start ECHOPORT.
//     (4) Anything transmitted from remote is echoed back by ECHOPORT.
//
//     To terminate ECHOPORT, type ^C or disconnect cables (which drops DSR).
//
// IMPORTANT:
//
//     To operate properly, all of the ports that will be running simultaneously MUST
//     be assigned to unique IRQ's, unless you know for a fact that your installed serial
//     port driver supports simultaneous use of ports that share a common IRQ. This is
//     normally not the case. This is a limitation of the serial port hardware and/or driver,
//     not WSC4C.
//
//     Normally COM1 and COM2 share IRQ4 while COM2 and COM4 share IRQ3. For example, running
//     COM1 and COM2 together will work (since they don't share an IRQ), but not COM1 and COM3.
//
// COMPILE: From the command line:
//
//     nmake -f echoport._m_  (Microsoft VC)
//      make -f echoport._b_  (Borland 5.0)
//      make -f echoport._i_  (Borland 5.5)
//     wmake -f echoport._w_  (Watcom 11)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace echoport.mak in MSVC IDE.
//     Open workspace echoport.dsp in MSVC (ver 6.0 only).
//
// ALSO SEE: events.c (which also has list of event flags)
//

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <process.h>
#include "wsc.h"
#include "keycode.h"

// specify number of thread and baud rate
#define NBR_THREADS   2
#define BAUD_RATE 19200

// define structure used by each thread
typedef struct
{int Thread;
 int Port;
 int Running;
} ParamType;

static ParamType Params[NBR_THREADS];

void Thread(PVOID pvoid)
{int Code;
 char Chr;
 ParamType *ParamPtr;
 ParamPtr = (ParamType *) pvoid;
 // starting thread
 ParamPtr->Running = TRUE;
 printf("COM%d: Starting thread %d at %d.\n", (ParamPtr->Port)+1,ParamPtr->Thread,BAUD_RATE);
 // reset port
 Code = SioReset(ParamPtr->Port, 1024, 1024);
 if(Code<0)
   {// Reset returned error
    printf("Error %d: Cannot open COM%d \n", Code, 1+ParamPtr->Port);
    if(Code==WSC_WIN32ERR)
     {char Temp[128];
      if(SioWinError(Temp,128)>0) printf("%s\n",Temp);
      }
    ParamPtr->Running = FALSE;
    return;
   }
 // set baud rate, DTR, and RTS
 SioBaud(ParamPtr->Port, BAUD_RATE);
 SioDTR(ParamPtr->Port, 'S');
 SioRTS(ParamPtr->Port, 'S');
 // look for incoming
 while(1)
   {// this thread is done when DSR is dropped
    if(SioDSR(ParamPtr->Port)==0)
       {printf("COM%d: DSR dropped, aborting thread.\n", 1+ParamPtr->Port);
        SioDone(ParamPtr->Port);
        ParamPtr->Running = FALSE;
        return;
       }

#if 1
    // block until data is available
    Code = SioEvent(ParamPtr->Port, EV_RXCHAR);
#endif

    // get everthing in the RX queue
    while(1)
      {// get incoming character
       Code = SioGetc(ParamPtr->Port);
       if(Code==WSC_NO_DATA) break;
       if(Code<WSC_NO_DATA)
         {// SioGetc returned error
          printf("COM%d: ERROR %d\n", 1+ParamPtr->Port, Code);
          return;
         }
       // good character
       Chr = (char)Code;
       // echo character back
       SioPutc(ParamPtr->Port, Chr);
       // display on screen
       printf("%c",Chr);
       fflush(stdout);
       Sleep(0);
       // remote user types ^Z or ESC to quit
       if((Chr==0x1a)||(Chr==0x1b))
         {// user has quit
          SioDone(ParamPtr->Port);
          ParamPtr->Running = FALSE;
          printf("COM%d: Thread terminated by remote.\n",1+ParamPtr->Port);
          return;
         }
      } // end if
    // give up rest of thread's time slice
    Sleep(0);
   } // end while
}

HANDLE CreateTheThread(PVOID Params)
{DWORD ThreadID;
 HANDLE ThreadHandle;
 // start thread to handle incoming serial
 ThreadHandle = CreateThread(0,1024,(LPTHREAD_START_ROUTINE)Thread,Params,0,&ThreadID);
 if(ThreadHandle==0)
   {printf("ERROR: Could not start thread\n");
    return (HANDLE)-1;
   }
 return ThreadHandle;
}

void AssignPortToThread(int Thread, int Port)
{// assign Port (COM1==0) to thread (1st thread==0)
 Params[Thread].Thread = Thread;
 Params[Thread].Port = Port;
 printf("COM%1d: Assigned to thread %d\n", 1+Port, Thread);
 // start thread
 CreateTheThread((PVOID)&Params[Thread]);
}

void main(void)
{int Thread;
 int Running;
 printf("ECHOPORT 3.3 (Type ^C to exit)\n");
 printf("This is a console mode program & is designed to run from a command window.\n");
 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
   {printf("ERROR: Bad Key Code!");
    exit(1);
   }

 //*** PROGRAMMER: Assign port (with unique IQ) to thread & start thread.
 AssignPortToThread(0, COM1);
 AssignPortToThread(1, COM2);
 //*** END-PROGRAMMER

 // run until all threads are done
 while(1)
   {// check each thread
    Running = 0;
    for(Thread=0;Thread<NBR_THREADS;Thread++)
      {// count running threads
       if(Params[Thread].Running) Running++;
       Sleep(0);
      }
    // all threads done ?
    if(Running==0)
      {printf("All threads have terminated.\n");
       return;
      }
    // take a breather
    Sleep(50);
   }
}


