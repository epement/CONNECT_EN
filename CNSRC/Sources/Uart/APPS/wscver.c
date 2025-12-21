//
// NAME: WSCVER.C
//
// TYPE: Win32 / Win16 GUI mode.
//
// DATE: August 6, 2004.
//
// PURPOSE: Displays the WSC32.DLL Version and Build #
//
// COMPILE: From the command line:
//
//     nmake -f wscver32._m_  (Microsoft VC)
//      make -f wscver32._b_  (Borland 5.0)
//      make -f wscver32._i_  (Borland 5.5)
//     wmake -f wscver32._w_  (Watcom 11)
//              wscver$.bat   (LCC-WIN32)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace wscver.mak in MSVC IDE.
//     Open workspace wscver.dsp in MSVC (ver 6.0 only).
//

#include <windows.h>

#ifdef WIN32
#define USE_INS HINSTANCE
#define USE_PTR PSTR
#else
#define USE_INS HANDLE
#define USE_PTR LPSTR
#endif

#include "wscver.h"
#include "wsc.h"
#include "keycode.h"
#include "message.h"
#include "paint.h"

// public globals

HWND hMainWnd;            // main window handle

// private globals

static HMENU hMenu;
static HINSTANCE hInstance;
///static long BaudRateList[10]
///      = {300L,600L,1200L,2400L,4800L,9600L,19200L,38400L,57600L,115200L};

#ifdef WIN32
int WINAPI
#else
int PASCAL
#endif
WinMain(USE_INS hInst, USE_INS hPrevInstance, USE_PTR lpCmdLine, int nCmdShow)
{WNDCLASS wc;
 MSG  msg;
 BOOL Result;
 if(!hPrevInstance)
   {// register main window class
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = MainWndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hInstance = hInst;
    wc.hIcon = LoadIcon(hInst, "VersionIcon");
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH);
    wc.lpszMenuName =  "VersionMenu";
    wc.lpszClassName = "VersionWClass";
    Result = RegisterClass(&wc);
    if(!Result) return FALSE;
   }

 // create main window
 hInstance = hInst;
 hMainWnd = CreateWindow(
   "VersionWClass",
   "WSCVER",
   WS_OVERLAPPEDWINDOW,
   CW_USEDEFAULT,
   CW_USEDEFAULT,
   350,
   120,
   NULL,
   NULL,
   hInstance,
   NULL);
 ShowWindow(hMainWnd, nCmdShow);
 UpdateWindow(hMainWnd);
 hMenu = GetMenu(hMainWnd);

 // window control loop

 while(GetMessage(&msg,NULL,0,0))
   {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
   }
 return (msg.wParam);
} // end WinMain

#ifdef WIN32
LRESULT CALLBACK
#else
long FAR PASCAL
#endif
MainWndProc(HWND hWindow,UINT iMsg,WPARAM wParam,LPARAM lParam)
{int DaysLeft;
 HDC  hDC;
 PAINTSTRUCT ps;
 hMainWnd = hWindow;
 switch (iMsg)
   {case WM_COMMAND:
      switch(wParam)
       {case MSG_INFO:
         {int Version;
          int Build;
          int Code;
          char Temp[55];
          // pass the key code
          if(SioKeyCode(WSC_KEY_CODE)<0)
            {DisplayLine((LPSTR)"ERROR: Bad Key Code!");
             break;
            }
          // display version and build
          Version = SioInfo('V');
          Build = SioInfo('B');
#ifdef WIN32
          wsprintf((LPSTR)Temp,"Win32 WSC Version %d.%d.%d, Build %d",
#else
          wsprintf((LPSTR)Temp,"Win16 WSC Version %d.%d.%d, Build %d",
#endif
              (Version>>8),0x0f&(Version>>4),0x0f&Version, Build);
          DisplayLine((LPSTR)Temp);
          // display registration string
          Code = SioGetReg((LPSTR)Temp, 50);
          if(Code>0) DisplayLine((LPSTR)Temp);
          // display # days left in evaluation version
          DaysLeft = SioInfo('?');
          if(DaysLeft==999) break; // registered version always returns 999
          if(DaysLeft>0)
            wsprintf((LPSTR)Temp,"%d days remaining for evaluation", DaysLeft );
          else
            wsprintf((LPSTR)Temp,"60 day evaluation period exceeded!");
          DisplayLine((LPSTR)Temp);
          break;
         }

        case MSG_EXIT:
          DestroyWindow(hMainWnd);
          break;

        default:
          return (DefWindowProc(hMainWnd, iMsg, wParam, lParam));
      }
    break;

    case WM_CREATE:
      // initialize paint module
      PaintInit();
      break;

    case WM_PAINT:
      HideCaret(hMainWnd);
      hDC = BeginPaint(hMainWnd, &ps);
      SetMapMode(hDC,MM_ANISOTROPIC);
      SelectObject(hDC, GetStockObject(OEM_FIXED_FONT) );
      PaintMain(hDC,&ps);
      EndPaint(hMainWnd,&ps);
      SetCaretPos(PaintGetColPos(),PaintGetRowPos());
      ShowCaret(hMainWnd);
      break;

    case WM_DESTROY:
      PostQuitMessage(0);
      break;

    default:
      return (DefWindowProc(hMainWnd, iMsg, wParam, lParam));
   }
 return 0;

} // end MainWndProc
