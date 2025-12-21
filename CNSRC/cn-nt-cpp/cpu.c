//---------------------------------------------------------------------------
#include <stdio.h>
#include <windows.h>

#pragma hdrstop

//---------------------------------------------------------------------------

#pragma argsused

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


int main(int argc, char* argv[])
{
    printf("CPU speed %f, MHz\n\r", CPUSpeed());
}

