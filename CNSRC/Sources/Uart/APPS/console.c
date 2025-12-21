//
// NAME: CONSOLE.C
//
// TYPE: Win32 console mode.
//
// DATE: August 6, 2004.
//
// PURPOSE: Console mode terminal emulator.
//
// NOTE:    LCC-WIN32: Link in MSVCRT.LIB [required for kbhit]
//
// COMPILE: From the command line:
//
//     nmake -f console._m_  (Microsoft VC)
//      make -f console._b_  (Borland 5.0)
//      make -f console._i_  (Borland 5.5)
//     wmake -f console._w_  (Watcom 11)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace console.mak in MSVC IDE.
//     Open workspace console.dsp in MSVC (ver 6.0 only).
//

#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <conio.h>

#include "wsc.h"
#include "keycode.h"
#include "sayerror.h"

char Temp[128];   // temporary buffer
int Port;
int Baud;

// trap WSC error codes

int ErrorCheck(int Port, int Code)
{if(Code<0)
   {SayError(Code,NULL);
    SioDone(Port);
    exit(1);
   }
 return Code;
}

//** main **

void main(int argc, char *argv[])
{char c;
 int  i;
 printf("This is a console mode program & is designed to run from a command window.\n");
 // process args
 if(argc!=3)
   {printf("Usage: CONSOLE <port> <baud>\n");
    printf("   Eg: CONSOLE 1 19200\n");
    return;
   }
 Port = atoi(argv[1]) - 1;
 Baud = atoi(argv[2]);
 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
   {printf("ERROR: Bad Key Code!");
    exit(1);
   }
 // set defaults for all ports. Note 'Port' argument is -1
 ErrorCheck( -1, SioReset(-1,1,1)); // DTR & RTS set at port initialization
 ErrorCheck( -1, SioParms(-1,WSC_NoParity,WSC_OneStopBit,WSC_WordLength8));
 // reset (initialize) the port
 ErrorCheck( Port, SioReset(Port,1024,1024) );
 ErrorCheck( Port, SioBaud(Port,Baud) );
 // DTR and RTS already set by SioReset(-1,1,1)
   ///ErrorCheck( SioDTR(Port,'S') );
   ///ErrorCheck( SioRTS(Port,'S') );
 printf("\nEnter terminal loop ( Type ^Z to exit )\n");
 // enter terminal loop
 SioPutc(Port,'\r');
 while(TRUE)
   {// was key pressed ?
    if(kbhit())
      {// fetch character
       c = getch();
       if(c==0x1a)
         {// restore COM port status & exit
          SioDone(Port);
          exit(1);
         }
       else
         {// transmit character
          SioPutc(Port,c);
         }
      } // end if
    // any incoming over serial port ?
    i = SioGetc(Port);
    if(i==WSC_NO_DATA) Sleep(50);
    else if(i>=0)
     {
#if 1
      printf("%c", i);
#else
      // display in hex
      wsprintf((char *)Temp,"%x ",i);
      printf((char *)Temp);
#endif
     }
   } // end-while(TRUE)
} // end main

