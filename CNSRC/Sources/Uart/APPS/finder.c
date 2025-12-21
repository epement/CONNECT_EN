//
// NAME: FINDER.C
//
// TYPE: Win32 console mode.
//
// DATE: August 10, 2004.
//
// PURPOSE: Searches for modem, which must be connected
//          to the serial port and tuned on.
//
// COMPILE: From the command line:
//
//     nmake -f finder32._m_  (Microsoft VC)
//      make -f finder32._b_  (Borland 5.0)
//      make -f finder32._i_  (Borland 5.5)
//     wmake -f finder32._w_  (Watcom 11)
//              finder$.bat   (LCC-WIN32)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace finder.mak in MSVC IDE.
//     Open workspace finder.dsp in MSVC (ver 6.0 only).
//

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

#include "wsc.h"
#include "keycode.h"

#define FIRST_PORT COM1
#define LAST_PORT  COM4

#define QUOTE 0x22

char Temp[80];

// trap WSC error codes

int ErrorCheck(int Code, int Port)
{if(Code<0)
   {printf("ERROR %d",Code);
    SioDone(Port);
    exit(1);
   }
 return Code;
}

// display error & exit

void SayError(char *Msg)
{printf("ERROR: %s: %d\n", Msg, GetLastError() );
 exit(1);
}

//** main **

void main(void)
{int  i;
 int Port;
 int Code;
 DWORD TimeMark;
 static char Expect[] = "OK";     // expect OK
 static int  Next = 0;            // index into Expect[]
 printf("This is a console mode program & is designed to run from a command window.\n");
 printf("\n*** Searching COM%d to COM%d for connected modem.\n\n",
      1+FIRST_PORT, 1+LAST_PORT);

 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
    {printf("ERROR: Bad Key Code!");
     exit(1);
    }

 // enter search loop
 for(Port=FIRST_PORT;Port<=LAST_PORT;Port++)
   {// reset the port
    Code = SioReset(Port,1024,512);
    if(Code<0) continue;
    // found UART: set baud rate, DTR and RTS
    SioBaud(Port, 19200);
    SioDTR(Port,'S');
    SioRTS(Port,'S');
    // modem should set DSR
    ///SioPutc(Port,'\r');
    if(SioDSR(Port)==0)
      {// modem must set DSR
       printf("COM%d: DSR is not set (DSR=0)\n",1+Port);
       continue;
      }
    printf("COM%d: DSR is set, transmitting %cAT%c...\n",1+Port,QUOTE,QUOTE);
    // send AT
    SioPutc(Port,'\r');
    Sleep(250);
    SioPutc(Port,'A');
    Sleep(250);
    SioPutc(Port,'T');
    Sleep(250);
    SioPutc(Port,'\r');
    // expect OK back within 2 seconds
    Next = 0;
    TimeMark = SioTimer() + 2000;
    //printf("\n[%lx:%lx]\n", SioTimer(), TimeMark);
    while(SioTimer() < TimeMark)
      {// any incoming over serial port ?
       i = SioGetc(Port);
       if(i>-1)
         {// got character
          printf("%c",(char)i);
          if((char)i==Expect[Next])
            {Next++;
             if(Next==2)
               {printf("\nModem found on COM%d\n",1+Port);
                SioDone(Port);
                exit(0);
               }
            }
         }
      } // end while
    // no modem on this port
    SioDone(Port);
    printf("No response.\n");
   } // end-for
 printf("Done.\n");
} // end main

