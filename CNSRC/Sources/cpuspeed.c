#include <Windows.h>

double CPUSpeed(void)
  {
    DWORD dwTimerHi, dwTimerLo;
    asm
     {
        DW 0x310F
        mov dwTimerLo, EAX
        mov dwTimerHi, EDX
      }
    Sleep (500);
    asm
     {
        DW 0x310F
        sub EAX, dwTimerLo
        sub EDX, dwTimerHi
        mov dwTimerLo, EAX
        mov dwTimerHi, EDX
     }
    return dwTimerLo/(1000.0*500);
  }




//TBN Strict 468x60, (095)428-4200, http://tbn.ru
