#define _WIN32_WINNT 0x400
#include <windows.h>
#include <stdio.h>

int main (int ArgC, char *ArgV []) {

  if (ArgC != 2) {
    fprintf (stderr, "Arg 1 must specify the interval in ms\n");
    return 1;
  }

  UINT const MS = atoi (ArgV [1]);

  if (MS < 1 || MS > 100) {
    fprintf (stderr, "Interval must be within 1..100 ms\n");
    return 2;
  }

  DWORD const OldMask = SetThreadAffinityMask (GetCurrentThread (), 1);

  if (!OldMask) {
    fprintf (stderr, "Cannot set affinity mask to 1 (%u)\n", GetLastError ());
    return 3;
  }

  HANDLE Timer = 0;

  if (!SetThreadPriority (GetCurrentThread (),
       THREAD_PRIORITY_TIME_CRITICAL)){
    fprintf (stderr, "Cannot raise priority (%u)\n", GetLastError ());
    return 4;
  }

  Timer = CreateWaitableTimer (0, false, 0);

  if (!Timer) {
    fprintf (stderr, "Cannot create timer (%u)", GetLastError ());
    return 5;
  }

  /*
  MMRESULT const TRes = timeBeginPeriod (1);

  if (TRes != TIMERR_NOERROR) {
    fprintf (stderr, "Cannot set timer resolution (%u)\n", TRes);
    return 6;
  }
  */

  LARGE_INTEGER LI;

  if (!QueryPerformanceFrequency (&LI)) {
    fprintf (stderr, "Cannot query performance frequency (%u)\n",
      GetLastError());
    return 7;
  }

  UINT const kHz = UINT ((LI.QuadPart + 500) / 1000);

  printf ("Performance frequency is %u kHz", kHz);

  if (!QueryPerformanceCounter (&LI)) {
    fprintf (stderr, "Cannot query perf counter (%u)", GetLastError ());
    return 8;
  }

  LONGLONG Counter = LI.QuadPart;

  LI.QuadPart = -1;

  if (!SetWaitableTimer (Timer, &LI, MS, 0, 0, false)) {
    fprintf (stderr, "Cannot set timer (%u)", GetLastError ());
    return 9;
  }

  for (UINT i = 0; i < 200; i++) {

    DWORD const WaitRes = WaitForSingleObject (Timer, INFINITE);
    if (WaitRes != WAIT_OBJECT_0) {
      fprintf (stderr, "WaitForSingleObject returns %u", WaitRes);
      return 10;
    }

    QueryPerformanceCounter (&LI);

    printf ("Timer signaled (%u ms)\n", UINT ((LI.QuadPart - Counter) / kHz));
    Counter = LI.QuadPart;
  }

  //timeEndPeriod (1);

  CloseHandle (Timer);

  return 0;

}
