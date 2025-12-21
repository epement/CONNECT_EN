//
// NAME: RS485.C
//
// TYPE: Win32 console mode.
//
// DATE: August 10, 2004.
//
// PURPOSE: Windows 95/98/Me/XP console mode application for RS485 port.
//          Uses RTS to enable RS485 transmit driver.
//
//          Uncomment the "USING_NT" line below for Windows NT, 2000, or XP
//          since they do not allow direct access to the serial port hardware.
//
// NOTE:    LCC-WIN32: Link in MSVCRT.LIB [required for kbhit]
//
// COMPILE: From the command line:
//
//     nmake -f rs485._m_  (Microsoft VC)
//      make -f rs485._b_  (Borland 5.0)
//      make -f rs485._i_  (Borland 5.5)
//     wmake -f rs485._w_  (Watcom 11)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace rs485.mak in MSVC IDE.
//     Open workspace rs485.dsp in MSVC (ver 6.0 only).
//

#define USING_NT

#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <conio.h>

#include "wsc.h"
#include "keycode.h"

char Temp[80];
int Port;
int Baud;

// trap WSC error codes

int ErrorCheck(int Code)
{if(Code<0)
   {printf("ERROR %d ",Code);
    SioDone(Port);
    exit(1);
   }
 return Code;
}

// wait for last bit of last character to be transmitted

#ifdef USING_NT
#else
void Wait4TxDone(int Port)
{int Code;
 while(1)
   {Code = SioRead(Port, 5);
    if((0x60&Code)==0x60) break;
    Sleep(0);
   }
}
#endif

//** main **

void main(int argc, char *argv[])
{char c;
 int  n;
 static char Buffer[128];
 static char *Alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ\r\n";
 printf("This is a console mode program & is designed to run from a command window.\n");
 // process args
 if(argc!=3)
   {printf("Usage: RS485 <port> <baud>\n");
    printf("   Eg: RS485 1 19200\n");
    return;
   }
 Port = atoi(argv[1]) - 1;
 Baud = atoi(argv[2]);

#ifndef USING_NT
 printf("Assuming Win 95/98 machine\n");
#endif

 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
   {printf("ERROR: Bad Key Code!");
    exit(1);
   }
 // reset the port
 ErrorCheck( SioReset(Port,1024,1024) );
 ErrorCheck( SioBaud(Port,Baud) );
 // set DTR
 ErrorCheck( SioDTR(Port,'S') );
 printf("\nEnter terminal loop ( Type ^Z to exit )\n");
 // enter terminal loop
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
       else if(c=='#')
         {// set RTS
          SioRTS(Port,'S');
          // transmit alphabet plus CR/LF
          SioPuts(Port,Alpha,28);
          // wait till TX queue is empty
          if(SioTxQue(Port)>1) SioEvent(Port, EV_TXEMPTY);
          // wait for last bit of last character to be transmitted
#ifdef USING_NT
          Sleep(0);
#else
          Wait4TxDone(Port);
#endif
          // drop RTS
          SioRTS(Port,'C');
         }
       else
         {// set RTS
          SioRTS(Port,'S');
          // transmit character
          SioPutc(Port,c);
          // wait for last bit of last character to be transmitted
#ifdef USING_NT
          Sleep(0);
#else
          Wait4TxDone(Port);
#endif
          // drop RTS
          SioRTS(Port,'C');
         }
      }
    // any incoming over serial port ?
    n = SioGets(Port,Buffer,127);
    if(n>0)
      {Buffer[n] = '\0';
       printf(Buffer);
      }
   } // end-while(TRUE)
} // end main

