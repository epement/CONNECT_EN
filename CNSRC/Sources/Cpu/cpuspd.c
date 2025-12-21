#include <windows.h>
#include <stdio.h>
#pragma warn -8075
#pragma warn -8004
#pragma warn -8019

long CPUSpeed(void)
  {
    DWORD dwTimerHi, dwTimerLo;
    CRITICAL_SECTION CriticalSection;

    TryEnterCriticalSection(&CriticalSection);
    asm
     {
        rdtsc // DW 0x310F
        mov dwTimerLo, EAX
        mov dwTimerHi, EDX
      }
    timeBeginPeriod(1);
    Sleep (100);
    timeEndPeriod(1);
    asm
     {
        rdtsc // DW 0x310F
        sub EAX, dwTimerLo
        sub EDX, dwTimerHi
        mov dwTimerLo, EAX
        mov dwTimerHi, EDX
     }
    LeaveCriticalSection(&CriticalSection);
    return dwTimerLo/(1000*100);
  }

void cpuid(int i, int * eax_, int * ebx_, int * ecx_, int * edx_)
{
 asm{
  mov eax, i
  cpuid
  mov esi, eax_
  mov dword ptr [esi],eax
  mov esi, ebx_
  mov dword ptr [esi],ebx
  mov esi, ecx_
  mov dword ptr [esi],ecx
  mov esi, edx_
  mov dword ptr [esi],edx
 }
}


void main(void)
{
 DWORD PriorityClass;
 HANDLE Process;
 long eax, ebx, ecx, edx;
 char Buf[32];
 int stepping, model, family,
     type, reserved, brand,
     siblings, clf,apic_id,feature_flags;

 cpuid(0,&eax,&Buf[0],&Buf[8],&Buf[4]);
 Buf[12] = 0;
 printf("Vendor ID: %s\r\n", Buf);
 cpuid(1,&eax,&ebx,&ecx,&edx);
 stepping = eax & 0xf;
 model = (eax >> 4) & 0xf;
 family = (eax >> 8) & 0xf;
 type = (eax >> 12) & 0x3;
 reserved = eax >> 14;
 clf = (ebx >> 8) & 0xff;
 apic_id = (ebx >> 24) & 0xff;
 siblings = (ebx >> 16) & 0xff;
 feature_flags = edx;




 Process = GetCurrentProcess();
 PriorityClass = GetPriorityClass(Process);
 SetPriorityClass(Process, REALTIME_PRIORITY_CLASS);
 printf("CPU speed %d MHz\n\r", CPUSpeed());
 SetPriorityClass(Process, PriorityClass);
 while(1);
}
