//
// SayError.c
//
// For console mode. Use SioError.c for GUI mode.
//

#include <stdio.h>
#include "windows.h"
#include "sayerror.h"
#include "wsc.h"

void SayError(int Code, char *Text)
{static char Temp[128];
 if(Text) printf("%s\n",Text);
 switch(Code)
   {case WSC_NO_DATA:
      printf("No Data\n");
      break;
    case WSC_RANGE:
      printf("Parameter out of range\n");
      break;
    case WSC_ABORTED:
      printf("Aborted");
      break;
    case WSC_EXPIRED:
      printf("Evaluation version expired or SioKeyCode not called\n");
      break;
    case WSC_BUFFERS:
      printf("Cannot allocate memory for buffers\n");
      break;
    case WSC_THREAD:
      printf("Cannot start thread\n");
      break;
    case WSC_KEYCODE:
      printf("Bad key code\n");
      break;
    case WSC_IE_BADID:
      printf("Invalid COM port\n");
      break;
    case WSC_IE_OPEN:
      printf("COM port already open\n");
      break;
    case WSC_IE_NOPEN:
      printf("Cannot open COM port\n");
      break;
    case WSC_IE_MEMORY:
      printf("Cannot allocate memory\n");
      break;
    case WSC_IE_DEFAULT:
      printf("Error in default parameters\n");
      break;
    case WSC_IE_HARDWARE:
      printf("COM port hardware not present\n");
      break;
    case WSC_IE_BYTESIZE:
      printf("Unsupported byte size\n");
      break;
    case WSC_IE_BAUDRATE:
      printf("Unsupported baud rate\n");
      break;
    case WSC_WIN32ERR:
      SioWinError(Temp,128);
      printf("Error %s\n",Temp);
      break;
    default:
      printf("Unknown code %d\n",Code);
      break;
   }
} // end SioError

