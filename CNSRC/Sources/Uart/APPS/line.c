/*** line.c ***/

#include "windows.h"
#include "wsc.h"

#include "line.h"
#include "sioerror.h"
#include "paint.h"

extern HWND hMainWnd;
extern int  FatalFlag;
extern int  OnLineFlag;

/*** PRIVATE ***/

static int ErrorCheck(int Code,char *Text)
{if(Code<0) SioError(Code,Text);
 return Code;
}

/*** PUBLIC ***/

int GoOnLine(int Port, int BaudCode, int RxQueSize, int TxQueSize)
{int RetCode;
 int Version;
 char Temp[50];
 if(OnLineFlag) return TRUE;
 /* reset Port */
 SioReset(-1,1,1); // Set DTR & RTS at port initialization.
 RetCode = SioReset(Port,RxQueSize,TxQueSize);
 if(RetCode<0)
   {wsprintf((LPSTR)Temp,"SioReset:COM%d",1+Port);
    SioError(RetCode,Temp);
    return FALSE;
   }
 /* display version */
 Version = SioInfo('V');
 wsprintf((LPSTR)Temp,"WSC Version %d.%d.%d", (Version>>8),0x0f&(Version>>4),0x0f&Version);
 DisplayLine((LPSTR)Temp);
 /* set baud rate */
 ErrorCheck( SioBaud(Port,BaudCode), "SioBaud");
 /* clear receive buffer */
 ErrorCheck( SioRxClear(Port), "SioRxClear");

 // You MUST match flow control (none, HW, SW) to the serial device
 // to which you are connected!

#if 1
 /* no flow control */
 DisplayLine((LPSTR)"Flow control not enabled");
 ErrorCheck( SioFlow(Port,'N'), "SioFlow");
 if(SioCTS(Port))
   DisplayLine((LPSTR)"CTS detected: You may need to enable HW flow control");
#else
 /* hardware flow control [REQUIRED for modems!] */
 DisplayLine((LPSTR)"HW flow control is enabled");
 ErrorCheck( SioFlow(Port,'H'), "SioFlow");
#endif

 /* we're done */

 OnLineFlag = TRUE;
 return TRUE;
}

void GoOffLine(int Port)
{SioDone(Port);
 /* we're done */
 OnLineFlag = FALSE;
}
