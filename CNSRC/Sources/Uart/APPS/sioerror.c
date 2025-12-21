//
// SioError.c
//
// For GUI mode. Use SayError.c for console mode.
//

#include <stdio.h>
#include "windows.h"
#include "sioerror.h"
#include "wsc.h"
#include "paint.h"

void SioError(int Code, char *Text)
{static char Temp[81];
 if(Text)
   {DisplayString(Text);
    DisplayString(". ");
   }
 switch(Code)
   {case WSC_NO_DATA:
      DisplayLine("No Data");
      break;
    case WSC_RANGE:
      DisplayLine("Parameter out of range");
      break;
    case WSC_ABORTED:
      DisplayLine("Aborted");
      break;
    case WSC_EXPIRED:
      DisplayLine("Evaluation version expired, or SioKeyCode not called");
      break;
    case WSC_BUFFERS:
      DisplayLine("Cannot allocate memory for buffers");
      break;
    case WSC_THREAD:
      DisplayLine("Cannot start thread");
      break;
    case WSC_TIMEOUT:
      DisplayLine("Timed out");
      break;
    case WSC_KEYCODE:
      DisplayLine("Bad key code.");
      break;
    case WSC_IE_BADID:
      DisplayLine("Invalid COM port");
      break;
    case WSC_IE_OPEN:
      DisplayLine("COM port already open");
      break;
    case WSC_IE_NOPEN:
      DisplayLine("Cannot open COM port");
      break;
    case WSC_IE_MEMORY:
      DisplayLine("Cannot allocate memory");
      break;
    case WSC_IE_DEFAULT:
      DisplayLine("Error in default parameters");
      break;
    case WSC_IE_HARDWARE:
      DisplayLine("COM port hardware not present");
      break;
    case WSC_IE_BYTESIZE:
      DisplayLine("Unsupported byte size");
      break;
    case WSC_IE_BAUDRATE:
      DisplayLine("Unsupported baud rate");
      break;
#ifdef WIN32
    case WSC_WIN32ERR:
      SioWinError((LPSTR)Temp,80);
      DisplayLine((LPSTR)Temp);
      break;
#endif
    default:
      wsprintf((LPSTR)Temp,"Unknown code %d",Code);
      DisplayLine((LPSTR)Temp);
      break;
   }
} // end SioError

