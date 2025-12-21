//
// NAME: XMR.CPP [XMODEM Receive]
//
// TYPE: Win32 console mode (VC.NET).
//
// DATE: August 6, 2004.
//
// PURPOSE: XMODEM (receive) example program.
//
// COMPILE: From VC.Net integrated developer environment (IDE):
//
//    Open workspace vc_xmr.vcproj in Visual Studio .NET
//

#include "stdafx.h"
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "wsc.h"
#include "keycode.h"
#include "xym.h"


#define NAK  0x15
#define XMODEM  0

#define DEBUG_OFF  0
#define DEBUG_LOW  1
#define DEBUG_HIGH 2

// set debug level below

int DebugLevel = DEBUG_OFF;

char Temp[81];

int RunXY(int Port)
{int Code;
 int Packet;
 int LastPacket;
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
   }
}

int _tmain(int argc, _TCHAR* argv[])
{int Code;
 int Port;
 int Baud;
 int Version;
 char *FileName;
 printf("This is a console mode program & is designed to run from a command window.\n");
 printf("___________________\n");
 printf("XMR Example Program\n");

 //get command line arguments
 if(argc != 4)
   {printf("Usage: XMR <port> <baud> <FileName>\n");
    printf("   Eg: XMR 1 38400 myfile.dat\n");
    return 1;
   }
 // get parameters
 Port = atoi(argv[1]) - 1;
 Baud = atoi(argv[2]);
 FileName = argv[3];
 printf("Port : COM%d\n",1+Port);
 printf("Baud : %1d\n",Baud);
 printf("File : %s\n",FileName);
 printf("_______________\n");
 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
   {printf("ERROR: Bad Key Code!");
    return 1;
   }
 // reset port (8N1 is default)
 Code = SioReset(Port,2048,2048);
 if(Code < 0)
   {printf("SioReset returns error %d\n", Code);
    if(Code==WSC_WIN32ERR)
      {SioWinError((LPSTR)Temp,80);
       printf("%s",Temp);
      }
    return 1;
   }
 // set baud rate
 Code = SioBaud(Port,Baud);
 if(Code < 0)
   {printf("SioBaud returns error %d\n", Code);
    return 1;
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

 //*** un-comment to speed up protocol over null modem cables ***
    //xySetParameter(Port, XY_SET_ONE_SECOND, 200);

 // show version number
 Version = xyGetParameter(Port,XY_GET_VERSION);
 printf("XYM Version %d.%d.%d\n", (Version>>8),0x0f&(Version>>4),0x0f&Version);
 // set EOF pad to blank
 xySetParameter(Port, XY_SET_EOF_CHAR, 0x20);
 // specify upload/download directory
    //xySetString(Port,XY_SET_FILES_DIR,(LPSTR)"C:\\WINDOWS\\TEMP");
 xySetString(Port,XY_SET_FILES_DIR,(LPSTR)".\\");
    // reduce the rate (from 4 to 2 seconds) at which NAK's are sent
    //xySetParameter(Port,XY_SET_NAK_RATE, 2);
 // set xyDriver debug level
 xyDebug(DebugLevel);
 printf("Starting XMODEM receive (type Control-BREAK to quit)\n");
 xyStartRx(Port, FileName, NAK, XMODEM);
 // run the XMODEM driver
 RunXY(Port);
 printf("\n");
 xyRelease();
 SioDone(Port);
 return 0;
}
