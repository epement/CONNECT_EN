//
// NAME: HOST.C
//
// TYPE: Win32 console mode.
//
// DATE: August 6, 2004.
//
// PURPOSE: Simple HOST program. Will answer incoming calls.
//
// COMPILE: From the command line:
//
//     nmake -f host32._m_  (Microsoft VC)
//      make -f host32._b_  (Borland 5.0)
//      make -f host32._i_  (Borland 5.5)
//     wmake -f host32._w_  (Watcom 11)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace host.mak in MSVC IDE.
//     Open workspace host.dsp in MSVC (ver 6.0 only).
//

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "wsc.h"
#include "keycode.h"
#include "mio.h"
#include "session.h"

#define CTLZ 0x1a
#define TEMP_SIZE 256

static char Temp[TEMP_SIZE];
static int Port;
static int Baud;

// trap WSC error codes

int ErrorCheck(int Code)
{if(Code<0)
   {wsprintf((char *)Temp,"ERROR %d ",Code);
    printf("%s",Temp);
    SioDone(Port);
    exit(1);
   }
 return Code;
}

// display error & exit

void SayError(char *Msg)
{
 wsprintf((char *)Temp,"ERROR: %s: %d\n", Msg, GetLastError() );
 printf("%s",Temp);
 exit(1);
}

//** main **

char AwaitMsg[] = "<<Awaiting caller (type ^BREAK to exit) >>";

void main(int argc, char *argv[])
{int  c;
 int  Code;
 printf("This is a console mode program & is designed to run from a command window.\n");
 // process args
 if(argc!=3)
   {printf("Usage: HOST <port> <baud>\n");
    return;
   }
 Port = atoi(argv[1]) - 1;
 Baud = atoi(argv[2]);
 // set defaults for all ports. Note 'Port' argument is -1
 ///ErrorCheck( SioReset(-1,1,1)); // DTR & RTS set at port initialization
 ///ErrorCheck( SioParms(-1,WSC_NoParity,WSC_OneStopBit,WSC_WordLength8));
 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
   {printf("ERROR: Bad Key Code!");
    return;
   }
 // reset (initialize) the port
 ErrorCheck( SioReset(Port,1024,512) );
 ErrorCheck( SioBaud(Port,Baud) );
 ErrorCheck( SioDTR(Port,'S') );
 ErrorCheck( SioRTS(Port,'S') );
 // wait for Modem to say its ready
 printf("<<Waiting for Modem DSR, type ^BREAK to abort>>\n");
 while( !SioDSR(Port) )
   {printf("%c",'.');
    Sleep(1000);
   }
 printf("\n<<Initializing modem>>\n");
 // send initialization string to modem
 mioSendTo(Port, 100,"!!AT E1 S7=60 S11=60 V1 X1 Q0 S0=0!");
 printf("<<Waiting for 'OK' from modem>>\n");
 // run the MIO driver to send string
 RunTheDriver(Port);
 // wait for response
 mioWaitFor(Port,5000,"OK");
 // run the MIO driver to get result
 RunTheDriver(Port);
 if(mioResult(Port)) printf("<<Modem is ready to answer>>\n");
 else
   {printf("<<Modem is NOT ready>>\n");
    SioDone(Port);
    exit(1);
   }
 Sleep(1000);
 // echo characters in RX buffer
 Code = SioRxQue(Port);
 if(Code>0)
   {Code = SioGets(Port,Temp,TEMP_SIZE);
    Temp[Code] = '\0';
    printf("%s",Temp);
   }
 // enter terminal loop
 printf("\n%s",AwaitMsg);
 while(1)
   {// any incoming over serial port ?
    c = SioGetc(Port);
    if(c != WSC_NO_DATA)
      {// echo all incoming
       printf("%c",(char)c);
       // RING ?
       if((char)c=='R')
         {// might be RING
          mioWaitFor(Port,2000,"ING");
          // run the MIO driver to get result
          RunTheDriver(Port);
          Code = mioResult(Port);
          printf("<%x>", Code);
          if(Code)
            {printf("<<RING detected>>\n");
             Session(Port);
             // hangup up the modem
             SioDTR(Port,'C');
             Sleep(1100);
             SioDTR(Port,'S');
             printf("\n%s\n",AwaitMsg);
            }
         }
      }
  } // end while
} // end main

