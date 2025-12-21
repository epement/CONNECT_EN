//
// NAME: SELFTEST.C
//
// TYPE: Win32/Win16 GUI mode.
//
// DATE: August 6, 2004.
//
// PURPOSE: Serial port test example program.
//
// COMPILE: From the command line:
//
//     nmake -f selftest._m_  (Microsoft VC)
//      make -f selftest._b_  (Borland 5.0)
//      make -f selftest._i_  (Borland 5.5)
//     wmake -f selftest._w_  (Watcom 11)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace selftest.mak in MSVC IDE.
//     Open workspace selftest.dsp in MSVC (ver 6.0 only).
//

#include <windows.h>

#ifdef WIN32
#define USE_INS HINSTANCE
#define USE_PTR PSTR
#else
#define USE_INS HANDLE
#define USE_PTR LPSTR
#endif

#include "selftest.h"
#include "message.h"
#include "wsc.h"
#include "keycode.h"
#include "ascii.h"
#include "paint.h"
//#include "line.h"
#include "menu.h"
#include "about.h"
#include "runtest.h"
#include "sioerror.h"

// public globals

HWND hMainWnd;            // main window handle
HWND hInfoWnd;            // popup handle
USE_INS hInstance;        // program instance
int OnLineFlag = FALSE;   // TRUE: online
int FatalFlag = FALSE;    // TRUE: fatal error
char Temp[1024];

// private globals

static int WinWidth = 8 * NCOLS;
static int WinHeight = 12 * NROWS + 48;
static int ThePort = COM1;
static int TheBaudRate = WSC_Baud19200;
static char *BaudRateTable[5] = {"9600","19200","38400","57600",""};

// miscellaneous functions

void ErrorCheck(int);
void ErrorMessage(char *);
void SetTitle(void);

#ifdef WIN32
int WINAPI
#else
int PASCAL
#endif
WinMain(USE_INS hInst,USE_INS hPrevInstance,USE_PTR lpCmdLine,int nCmdShow)
{WNDCLASS  wc;
 MSG msg;
 BOOL Result;
 if(!hPrevInstance)
   {// register main window class
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = MainWndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hInstance = hInst;
    wc.hIcon = LoadIcon(hInst, "SelftestIcon");
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH);
    wc.lpszMenuName =  "SelftestMenu";
    wc.lpszClassName = "SelftestWClass";
    Result = RegisterClass(&wc);
    if(!Result) return FALSE;
   }

 // create main window
 hInstance = hInst;
 hMainWnd = CreateWindow(
        "SelftestWClass", "Selftest",       WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,    CW_USEDEFAULT,
        WinWidth,         WinHeight,
        NULL,             NULL,
        hInstance,        NULL);
 ShowWindow(hMainWnd, nCmdShow);
 UpdateWindow(hMainWnd);

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
{int  Code;
 HDC  hDC;
 PAINTSTRUCT ps;
 static FARPROC lpfnAboutDlgProc;

 hMainWnd = hWindow;
 switch (iMsg)
    {case WM_COMMAND:
         switch(wParam)
           {case MSG_ABOUT:
#ifdef WIN32
              DialogBox(hInstance,"AboutBox",hMainWnd,AboutDlgProc);
#else
              DialogBox(hInstance,"AboutBox",hMainWnd,lpfnAboutDlgProc);
#endif
              break;

            case MSG_DEBUG:
              break;

            case MSG_INSTRUCT:
              DisplayLine("SELFTEST tests a single port for functionality.\n");
              DisplayLine("The port must terminate with a loopback adapter.");
              DisplayLine("DTR/DSR are tested if DTR is wired to DSR, and");
              DisplayLine("RTS/CTS are tested if RTS is wired to CTS.");
              DisplayLine("See LOOPBACK.TXT for more info.\n");
              break;

            case MSG_TEST:
              // pass the key code
              if(SioKeyCode(WSC_KEY_CODE)<0)
                {DisplayLine((LPSTR)"ERROR: Bad Key Code!");
                 break;
                }
              // open the port
              Code = SioReset(ThePort,2500,2500);
              if(Code<0)
                {SioError(Code,"SioReset");
                 break;
                }
              // set the baud rate
              SioBaud(ThePort,TheBaudRate);
#if 1
              Code = SioSetInteger(ThePort,'W',1);
              DisplayLine("Note: SioPuts will return immediately\n");
#else
              DisplayLine("Note: SioPuts will wait for I/O to complete\n");
#endif
              RunTest(ThePort);
              SioDone(ThePort);
              break;

            case MSG_COM1:
              UncheckTheMenu(MSG_COM1+ThePort);
              ThePort = COM1;
              CheckTheMenu(MSG_COM1);
              SetTitle();
              break;

            case MSG_COM2:
              UncheckTheMenu(MSG_COM1+ThePort);
              ThePort = COM2;
              CheckTheMenu(MSG_COM2);
              SetTitle();
              break;

            case MSG_COM3:
              UncheckTheMenu(MSG_COM1+ThePort);
              ThePort = COM3;
              CheckTheMenu(MSG_COM3);
              SetTitle();
              break;

            case MSG_COM4:
              UncheckTheMenu(MSG_COM1+ThePort);
              ThePort = COM4;
              CheckTheMenu(MSG_COM4);
              SetTitle();
              break;

            case MSG_9600:
              UncheckTheMenu(MSG_9600+TheBaudRate-WSC_Baud9600);
              TheBaudRate = WSC_Baud9600;
              CheckTheMenu(MSG_9600);
              SetTitle();
              break;

            case MSG_19200:
              UncheckTheMenu(MSG_9600+TheBaudRate-WSC_Baud9600);
              TheBaudRate = WSC_Baud19200;
              CheckTheMenu(MSG_19200);
              SetTitle();
              break;

            case MSG_38400:
              UncheckTheMenu(MSG_9600+TheBaudRate-WSC_Baud9600);
              TheBaudRate = WSC_Baud38400;
              CheckTheMenu(MSG_38400);
              SetTitle();
              break;

            case MSG_57600:
              UncheckTheMenu(MSG_9600+TheBaudRate-WSC_Baud9600);
              TheBaudRate = WSC_Baud57600;
              CheckTheMenu(MSG_57600);
              SetTitle();
              break;

            case MSG_EXIT:
              PostQuitMessage(0);
              break;

            default:
              return (DefWindowProc(hMainWnd, iMsg, wParam, lParam));
           }
         break;

    case WM_CREATE:

#ifdef WIN32
#else
      // create AboutDlgProc() thunk
      lpfnAboutDlgProc = MakeProcInstance(AboutDlgProc, hInstance);
#endif
      // initialize paint module
      PaintInit();
      // COM1 @ 19200 is the default
      CheckTheMenu(MSG_COM1);
      CheckTheMenu(MSG_9600+TheBaudRate-WSC_Baud9600);
      SetTitle();
      break;

    case WM_SETFOCUS:
      // create client area caret
      CreateCaret(hMainWnd,NULL,3,10);
      SetCaretPos(PaintGetColPos(),PaintGetRowPos());
      ShowCaret(hMainWnd);
      ShowCaret(hMainWnd);
      break;

    case WM_KILLFOCUS:
      DestroyCaret();
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

void ErrorMessage(char *MsgPtr)
{
 MessageBox(hMainWnd,MsgPtr,"ERROR",MB_ICONEXCLAMATION | MB_OK);
}

void SetTitle(void)
{wsprintf((LPSTR)Temp,"SELFTEST: COM%d @ %s",
    1+ThePort, BaudRateTable[TheBaudRate-WSC_Baud9600]);
 SetWindowText(hMainWnd,Temp);
 DrawMenuBar(hMainWnd);
}

