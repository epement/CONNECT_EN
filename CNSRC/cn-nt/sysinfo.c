#include <string.h>
#include <windows.h>

#pragma warn -8059
#pragma warn -8075
#pragma pack(1)

typedef struct _ASI{
 OSVERSIONINFO   os_ver_inf;
 MEMORYSTATUS    mem_stat;
 SYSTEM_INFO     si;
 char ComputerName[128];
 char UserName[128];
} ASI, *PASI;

typedef struct _SCI{
 DWORD horzsize;   // Width, in millimeters, of the physical screen.
 DWORD vertsize;   // Height, in millimeters, of the physical screen.
 DWORD horzres;    // Width, in pixels, of the screen.
 DWORD vertres;    // Height, in raster lines, of the screen.
 DWORD logpixelsx; // Number of pixels per logical inch along the screen width.
 DWORD logpixelsy; // Number of pixels per logical inch along the screen height.
 DWORD bitspixel;  // Number of adjacent color bits for each pixel.
 DWORD colorres;   // Actual color resolution of the device, in bits per pixel.
 DWORD vrefresh;   // Windows NT only: For display devices: the current vertical refresh rate of the device, in cycles per second (Hz).
} SCI, *PSCI;


long CPUSpeed(void)
  {
    DWORD dwTimerHi, dwTimerLo;
    CRITICAL_SECTION CriticalSection;
    BOOL Critical;

    InitializeCriticalSection(&CriticalSection);
    Critical = TryEnterCriticalSection(&CriticalSection);
    if (Critical)
     {
      timeBeginPeriod(1);
      asm
       {
          rdtsc // DW 0x310F
          mov dwTimerLo, EAX
          mov dwTimerHi, EDX
        }
      Sleep (100);
      asm
       {
          rdtsc // DW 0x310F
          sub EAX, dwTimerLo
          sub EDX, dwTimerHi
          mov dwTimerLo, EAX
          mov dwTimerHi, EDX
       }
      timeEndPeriod(1);
     }
    else dwTimerLo = 0;
    if (Critical) LeaveCriticalSection(&CriticalSection);
    DeleteCriticalSection(&CriticalSection);

    return dwTimerLo/(1000*100);
  }


long asysinfo(ASI * asi)
{
 int rc;
 int name_size;

 /* Windows version */
 memset(asi, 0, sizeof(ASI));
 asi -> os_ver_inf.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
 GetVersionEx(&asi -> os_ver_inf);
 /* Name of computer and user */
 rc = sizeof(asi -> ComputerName);
 GetComputerName(&asi -> ComputerName, &rc);
 name_size = strlen((LPCSTR)(asi -> ComputerName));
 CharToOemBuff((LPCSTR)(LPCSTR)(asi -> ComputerName),
               (LPTSTR)(LPCSTR)(asi -> ComputerName), name_size);
 rc = sizeof(asi -> UserName);
 GetUserName(&asi -> UserName, &rc);
 name_size = strlen((LPCSTR)(asi -> UserName));
 CharToOemBuff((LPCSTR)(LPCSTR)(asi -> UserName),
               (LPTSTR)(LPCSTR)(asi -> UserName), name_size);
 /* Memory info */
 asi -> mem_stat.dwLength = sizeof(MEMORYSTATUS);
 GlobalMemoryStatus(&asi -> mem_stat);
 /* SysInfo*/
 GetSystemInfo(&asi -> si);
 return CPUSpeed();
}

void ScreenInfo(SCI* sci)
{
 HDC hdc;
 hdc = GetDC(NULL);
 sci -> horzsize = GetDeviceCaps(hdc, HORZSIZE);
 sci -> vertsize = GetDeviceCaps(hdc, VERTSIZE);
 sci -> horzres = GetDeviceCaps(hdc, HORZRES);
 sci -> vertres = GetDeviceCaps(hdc, VERTRES);
 sci -> logpixelsx = GetDeviceCaps(hdc, LOGPIXELSX);
 sci -> logpixelsy = GetDeviceCaps(hdc, LOGPIXELSY);
 sci -> bitspixel = GetDeviceCaps(hdc, BITSPIXEL);
 sci -> colorres = GetDeviceCaps(hdc, COLORRES);
 sci -> vrefresh = GetDeviceCaps(hdc, VREFRESH);
 ReleaseDC(NULL, hdc);
}
