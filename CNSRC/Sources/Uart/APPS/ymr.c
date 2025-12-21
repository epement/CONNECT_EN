//
// NAME: YMR.C [YMODEM Receive]
//
// TYPE: Win32 console mode.
//
// DATE: August 12, 2004.
//
// PURPOSE: YMODEM (receive) example program.
//
// NOTE:    Requires XYM [ver 3.1 or above]
//
// COMPILE: From the command line:
//
//     nmake -f ymr32._m_  (Microsoft VC)
//      make -f ymr32._b_  (Borland 5.0)
//      make -f ymr32._i_  (Borland 5.5)
//     wmake -f ymr32._w_  (Watcom 11)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace ymr.mak in MSVC IDE.
//     Open workspace ymr.dsp in MSVC (ver 6.0 only).
//

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "wsc.h"
#include "keycode.h"
#include "xym.h"
#include "sayerror.h"

#define YMODEM  1

#define DEBUG_OFF  0
#define DEBUG_LOW  1
#define DEBUG_HIGH 2

// set debug level below

static int DebugLevel = DEBUG_OFF;

static char Temp[81];
static char FileName[81];

int RunXY(int Port)
{int Code;
 int Packet;
 int LastPacket;
 int GotFilename;
 LastPacket = 0;
 while(1)
   {// run the driver
    Code = xyDriver(Port);
    // any messages from xyDriver ?
    while(xyGetMessage(Port,(LPSTR)Temp,80)>0) printf("%s\n",Temp);
    if(Code == XY_IDLE) return XY_IDLE;
    else if(DebugLevel==DEBUG_OFF)
      {// xyDriver is running
       Packet = xyGetParameter(Port, XY_GET_PACKET);
       if(Packet != LastPacket)
         {// show packet number
          printf(" P%1d",Packet);
          if(Packet%10==9) printf("\n");
         }
       LastPacket = Packet;
      }
     // want incoming filename
     if(Packet==0) GotFilename = FALSE;
     // get filename after packet 0 has been received
     if((Packet==1)&&(!GotFilename))
       {/* get incoming filename */
        xyGetFileName(Port,(LPSTR)FileName,80);
        if(FileName[0])
          {GotFilename = TRUE;
           printf("<%s>",FileName);
          }
       }
   }
}

void main(int argc, char *argv[])
{int Code;
 int Port;
 int Baud;
 int Version;
 printf("This is a console mode program & is designed to run from a command window.\n");
 printf("___________________\n");
 printf("YMR Example Program\n");

 //get command line arguments
 if(argc!=3)
   {printf("Usage: YMR <port> <baud>\n");
    printf("   Eg: YMR 1 38400\n");
    exit(1);
   }
 // get parameters
 Port = atoi(argv[1]) - 1;
 Baud = atoi(argv[2]);
 printf("Port : COM%d\n",1+Port);
 printf("Baud : %1d\n",Baud);
 printf("File : (from Ymodem)\n");
 printf("___________________\n");
 FileName[0] = '\0';
 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
   {printf("ERROR: Bad Key Code!");
    exit(1);
   }
 // reset port (8N1 is default)
 Code = SioReset(Port,2048,2048);
 if(Code < 0)
   {SayError(Code, "SioReset");
    exit(1);
   }
 // set baud rate
 Code = SioBaud(Port,Baud);
 if(Code < 0)
   {SayError(Code, "SioBaud");
    exit(1);
   }
 // set DTR & RTS
 SioDTR(Port,'S');
 SioRTS(Port,'S');
 // set parms [XMODEM/YMODEM are binary protocols & require an 8N1 connection]
 SioParms(Port, WSC_NoParity, WSC_OneStopBit, WSC_WordLength8);
 // set hardware (RTS/CTS) flow control, other side must also set hardware flow control
 if(!SioCTS(Port)) printf("Warning: Program will block until CTS is set by other side\n");
 SioFlow(Port,'H');
 // acquire xyDriver
 xyAcquire(Port, Port);
 // show version number
 Version = xyGetParameter(Port,XY_GET_VERSION);
 printf("XYM Version %d.%d.%d\n", (Version>>8),0x0f&(Version>>4),0x0f&Version);
 // set EOF pad to blank
 xySetParameter(Port, XY_SET_EOF_CHAR, 0x20);
 // set xyDriver debug level
 xyDebug(DebugLevel);
 // specify upload/download directory
    //xySetString(Port,XY_SET_FILES_DIR,(LPSTR)"C:\\WINDOWS\\TEMP");
 xySetString(Port,XY_SET_FILES_DIR,(LPSTR)".\\");

 //*** un-comment to speed up protocol over null modem cables ***
    //xySetParameter(Port, XY_SET_ONE_SECOND, 200);

 printf("Starting YMODEM receive (type Control-BREAK to quit)\n");
 xyStartRx(Port, NULL, 'C', YMODEM);
 // run the YMODEM driver
 RunXY(Port);
 printf("\n%d packets received, %d packets NAKed, %d short packets\n",
    xyGetParameter(Port, XY_GET_PACKETS_ACKED),
    xyGetParameter(Port, XY_GET_NBR_NAKS),
    xyGetParameter(Port, XY_GET_SHORT_PACKETS) );
 xyRelease();
 SioDone(Port);
}
