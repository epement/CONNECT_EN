// fSio.h

#include <windows.h>
#include "wsc.h"

class fSio
  {
   public:
     fSio(void);
     ~fSio(void);
     int fSioReset(int,int,int);
     int fSioDone(int);
     int fSioBaud(int,unsigned);
     int fSioPutc(int,char);
     int fSioPuts(int,LPSTR,unsigned);
     int fSioGetc(int);
     int fSioGets(int,LPSTR,unsigned);
     int fSioDTR(int,char);
     int fSioRTS(int,char);
     int fSioTxClear(int);
     int fSioRxClear(int);
     int fSioTxQue(int);
     int fSioRxQue(int);
     int fSioStatus(int,unsigned);
     int fSioFlow(int,char);
     int fSioParms(int,int,int,int);
     int fSioCTS(int);
     int fSioDSR(int);
     int fSioRI(int);
     int fSioDebug(int);
     int fSioInfo(char);
     int fSioDCD(int);
     int fSioBrkSig(int,char);
     int fSioUnGetc(int,char);
     int fSioWinError(LPSTR,int);
     int fSioRead(int,int);
     DWORD fSioTimer(void);
     int fSioEvent(int,DWORD);
     int fSioMessage(int,HWND,WORD,DWORD);
     int fSioKeyCode(ULONG);
     int fSioGetReg(LPSTR,int);
     int fSioSetInteger(int,int,ULONG);
   };

