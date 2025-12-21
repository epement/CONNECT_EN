//
// NAME: SIMPLE.C
//
// TYPE: Win32 GUI mode.
//
// DATE: August 6, 2004.
//
// PURPOSE: Simple terminal emulator example program.
//
//    SIMPLE can be compiled in two ways:
//    (1) Send message WM_USER when data arrives (if SEND_MESSAGE is defined).
//    (2) Use a timer to check the RX queue (if SEND_MESSAGE is not defined).
//
//    The first method requires using the SioMessage function, which is only
//    defined for Win32. SEND_MESSAGE must be commented out (line 32) for Win16.
//
// IMPORTANT: You MUST match flow control to your serial device.  See line 41 of LINE.C
//
// COMPILE: From the command line:
//
//     nmake -f simple32._m_  (Microsoft VC)
//      make -f simple32._b_  (Borland 5.0)
//      make -f simple32._i_  (Borland 5.5)
//     wmake -f simple32._w_  (Watcom 11)
//              simple$.bat   (LCC-WIN32)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace simple.mak in MSVC IDE.
//     Open workspace simple.dsp in MSVC (ver 6.0 only).
//

///#define SEND_MESSAGE

#include <windows.h>

#ifdef WIN32
#define USE_INS HINSTANCE
#define USE_PTR PSTR
#else
#define USE_INS HANDLE
#define USE_PTR LPSTR
#endif

#include "simple.h"
#include "wsc.h"
#include "keycode.h"
#include "sioerror.h"
#include "ascii.h"
#include "message.h"
#include "line.h"
#include "paint.h"
#include "about.h"

// public globals

HWND hMainWnd;            // main window handle
int OnLineFlag = FALSE;   // TRUE: online
int FatalFlag = FALSE;    // TRUE: fatal error

// private globals

static HMENU hMenu;
static HINSTANCE hInstance;
static int ThePort = COM1;
static int TheBaud = WSC_Baud19200;
static int WinWidth = 8 * NCOLS;
static int WinHeight = 12 * NROWS + 48;
static long BaudRateList[10]
       = {300L,600L,1200L,2400L,4800L,9600L,19200L,38400L,57600L,115200L};

#define TEMP_SIZE 1024
static char Temp[TEMP_SIZE];

// miscellaneous functions

int ErrorCheck(int);

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
    wc.hIcon = LoadIcon(hInst, "SimpleIcon");
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH);
    wc.lpszMenuName =  "SimpleMenu";
    wc.lpszClassName = "SimpleWClass";
    Result = RegisterClass(&wc);
    if(!Result) return FALSE;
   }

 // create main window
 hInstance = hInst;
 hMainWnd = CreateWindow(
   "SimpleWClass",
   "SIMPLE",
   WS_OVERLAPPEDWINDOW,
   CW_USEDEFAULT,
   CW_USEDEFAULT,
   WinWidth,
   WinHeight,
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
{int i;
#ifndef SEND_MESSAGE
 UINT idTimer = 0;
#endif
 HDC  hDC;
 PAINTSTRUCT ps;
 int Count;
#ifdef WIN32
#else
 static FARPROC lpfnAboutDlgProc;
#endif
 hMainWnd = hWindow;
 switch (iMsg)
    {
     case WM_COMMAND:
    switch(wParam)
      {case MSG_ABOUT:
#ifdef WIN32
         DialogBox(hInstance,"AboutBox",hMainWnd,AboutDlgProc);
#else
         DialogBox(hInstance,"AboutBox",hMainWnd,lpfnAboutDlgProc);
#endif
         break;

       case MSG_ONLINE:
         if(OnLineFlag) break;
         else
           {// try to go on-line
            if(GoOnLine(ThePort,TheBaud,2048,512))
              {// we're online
               OnLineFlag = TRUE;
               wsprintf((LPSTR)Temp,(LPSTR)"SIMPLE: COM%d online at %ld baud",
               1+ThePort,BaudRateList[TheBaud]);
               SetWindowText(hMainWnd,Temp);
               CheckMenuItem(hMenu,MSG_OFFLINE,MF_BYCOMMAND | MF_UNCHECKED);
               CheckMenuItem(hMenu,MSG_ONLINE,MF_BYCOMMAND | MF_CHECKED);
               for(i=MSG_COM1;i<=MSG_COM4;i++)
                 EnableMenuItem(hMenu,i,MF_BYCOMMAND|MF_GRAYED);
               for(i=MSG_300;i<=MSG_115200;i++)
                 EnableMenuItem(hMenu,i,MF_BYCOMMAND|MF_GRAYED);
#ifdef SEND_MESSAGE
               // ask for message WM_USER as when data arrives
               ErrorCheck( SioMessage(ThePort, hMainWnd, WM_USER, EV_RXCHAR) );
#endif
              }
           }
         break;

       case MSG_OFFLINE:
         if(!OnLineFlag) break;
         GoOffLine(ThePort);
         OnLineFlag = FALSE;
         SetWindowText(hMainWnd,"SIMPLE: Offline");
         CheckMenuItem(hMenu,MSG_ONLINE,MF_BYCOMMAND | MF_UNCHECKED);
         CheckMenuItem(hMenu,MSG_OFFLINE,MF_BYCOMMAND | MF_CHECKED);
         for(i=MSG_COM1;i<=MSG_COM4;i++)
           EnableMenuItem(hMenu,i,MF_BYCOMMAND|MF_ENABLED);
         for(i=MSG_300;i<=MSG_115200;i++)
           EnableMenuItem(hMenu,i,MF_BYCOMMAND|MF_ENABLED);
         break;

       case MSG_EXIT:
         DestroyWindow(hMainWnd);
         break;

       case MSG_COM1:
         CheckMenuItem(hMenu,MSG_COM1+ThePort,MF_BYCOMMAND | MF_UNCHECKED);
         ThePort = COM1;
         CheckMenuItem(hMenu,MSG_COM1,MF_BYCOMMAND | MF_CHECKED);
         break;

       case MSG_COM2:
         CheckMenuItem(hMenu,MSG_COM1+ThePort,MF_BYCOMMAND | MF_UNCHECKED);
         ThePort = COM2;
         CheckMenuItem(hMenu,MSG_COM2,MF_BYCOMMAND | MF_CHECKED);
         break;

       case MSG_COM3:
         CheckMenuItem(hMenu,MSG_COM1+ThePort,MF_BYCOMMAND | MF_UNCHECKED);
         ThePort = COM3;
         CheckMenuItem(hMenu,MSG_COM3,MF_BYCOMMAND | MF_CHECKED);
         break;

       case MSG_COM4:
         CheckMenuItem(hMenu,MSG_COM1+ThePort,MF_BYCOMMAND | MF_UNCHECKED);
         ThePort = COM4;
         CheckMenuItem(hMenu,MSG_COM4,MF_BYCOMMAND | MF_CHECKED);
         break;

       case MSG_300:
         CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_UNCHECKED);
         TheBaud = WSC_Baud300;
         CheckMenuItem(hMenu,MSG_300,MF_BYCOMMAND | MF_CHECKED);
         break;

       case MSG_1200:
         CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_UNCHECKED);
         TheBaud = WSC_Baud1200;
         CheckMenuItem(hMenu,MSG_1200,MF_BYCOMMAND | MF_CHECKED);
         break;

       case MSG_2400:
         CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_UNCHECKED);
         TheBaud = WSC_Baud2400;
         CheckMenuItem(hMenu,MSG_2400,MF_BYCOMMAND | MF_CHECKED);
         break;

       case MSG_4800:
         CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_UNCHECKED);
         TheBaud = WSC_Baud4800;
         CheckMenuItem(hMenu,MSG_4800,MF_BYCOMMAND | MF_CHECKED);
         break;

       case MSG_9600:
         CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_UNCHECKED);
         TheBaud = WSC_Baud9600;
         CheckMenuItem(hMenu,MSG_9600,MF_BYCOMMAND | MF_CHECKED);
         break;

       case MSG_19200:
         CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_UNCHECKED);
         TheBaud = WSC_Baud19200;
         CheckMenuItem(hMenu,MSG_19200,MF_BYCOMMAND | MF_CHECKED);
         break;

       case MSG_38400:
         CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_UNCHECKED);
         TheBaud = WSC_Baud38400;
         CheckMenuItem(hMenu,MSG_38400,MF_BYCOMMAND | MF_CHECKED);
         break;

       case MSG_57600:
         CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_UNCHECKED);
         TheBaud = WSC_Baud57600;
         CheckMenuItem(hMenu,MSG_57600,MF_BYCOMMAND | MF_CHECKED);
         break;

#ifdef WIN32
       case MSG_115200:
         CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_UNCHECKED);
         TheBaud = WSC_Baud115200;
         CheckMenuItem(hMenu,MSG_115200,MF_BYCOMMAND | MF_CHECKED);
         break;
#endif

       default:
         return (DefWindowProc(hMainWnd, iMsg, wParam, lParam));
      }
    break;

    case WM_CREATE:

      // check "OFFLINE" menu item
      hMenu = GetMenu(hMainWnd);
      CheckMenuItem(hMenu,MSG_OFFLINE,MF_BYCOMMAND | MF_CHECKED);
      // check default COM port
      CheckMenuItem(hMenu,MSG_COM1+ThePort,MF_BYCOMMAND | MF_CHECKED);
      // check default baud rate
      CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_CHECKED);
#ifdef WIN32
#else
      // create AboutDlgProc() thunk
      lpfnAboutDlgProc = MakeProcInstance(AboutDlgProc, hInstance);
#endif
      // initialize paint module
      PaintInit();
      // pass the key code
      if(SioKeyCode(WSC_KEY_CODE)<0)
        {DisplayLine((LPSTR)"ERROR: Bad Key Code!");
         break;
        }
#ifdef SEND_MESSAGE
      DisplayLine("[Using SEND_MESSAGE method]");
#else
      // start timer
      idTimer = SetTimer(hMainWnd,1,100,NULL);
      if(idTimer==0)
        {MessageBox(hMainWnd,"No timers remaining !","ERROR",MB_ICONEXCLAMATION | MB_OK);
         FatalFlag = TRUE;
        }
      DisplayLine("[Using timer method]");
#endif
      break;


    case WM_CHAR:

      // send the character
      ErrorCheck(SioPutc(ThePort, (char)wParam ) );
#ifdef SEND_MESSAGE
      // ask for message for next incoming byte
#endif
      break;


#ifdef SEND_MESSAGE
    case WM_USER:
      // got keystroke
      //DisplayLine((LPSTR)"WM_USER");
      // the port (0 for COM1, etc.) is also passed in wParam by SioMessage
#else
    case WM_TIMER:
#endif
      // fatal error ?
      if(FatalFlag) break;
      if(!OnLineFlag) break;
      // fetch line of up to 'TEMP_SIZE' chars
      Count = SioGets(ThePort, (LPSTR)Temp, TEMP_SIZE);
      if(Count>0) WriteTheString(Temp,Count);
#ifdef SEND_MESSAGE
      // ask for more data
      ErrorCheck( SioMessage(ThePort, hMainWnd, WM_USER, EV_RXCHAR) );
#endif
      break;


    case WM_SETFOCUS:
      // create client area caret
      CreateCaret(hMainWnd,NULL,3,10);
      SetCaretPos(PaintGetColPos(), PaintGetRowPos());
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
      GoOffLine(ThePort);
      SetWindowText(hMainWnd,"SIMPLE: Offline");
      CheckMenuItem(hMenu,MSG_OFFLINE,MF_BYCOMMAND | MF_CHECKED);
      CheckMenuItem(hMenu,MSG_ONLINE,MF_BYCOMMAND | MF_UNCHECKED);
#ifndef SEND_MESSAGE
      if(idTimer) KillTimer(hMainWnd,idTimer);
#endif
      PostQuitMessage(0);
      break;

    default:
      return (DefWindowProc(hMainWnd, iMsg, wParam, lParam));
   }
 return 0;

} // end MainWndProc

int ErrorCheck(int Code)
{// trap PCL error codes
 if(Code<0)
   {SioError(Code,"");
    SioRxClear(ThePort);
    SioDone(ThePort);
    FatalFlag = TRUE;
   }
 return Code;
} // end ErrorCheck

