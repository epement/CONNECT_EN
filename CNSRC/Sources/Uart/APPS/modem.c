//
// NAME: MODEM.C
//
// TYPE: Win32 GUI mode.
//
// DATE: August 6, 2004.
//
// PURPOSE: Serial Device (modem, etc.) exerciser example program.
//
//          The flow control type MUST match between this program
//          and the serial device.
//
// COMPILE: From the command line:
//
//     nmake -f modem32._m_  (Microsoft VC)
//      make -f modem32._b_  (Borland 5.0)
//      make -f modem32._i_  (Borland 5.5)
//     wmake -f modem32._w_  (Watcom 11)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace modem.mak in MSVC IDE.
//     Open workspace modem.dsp in MSVC (ver 6.0 only).
//

#define USECOMM

#include <windows.h>

#ifdef WIN32
#define USE_INS HINSTANCE
#define USE_PTR PSTR
#else
#define USE_INS HANDLE
#define USE_PTR LPSTR
#endif

#include "modem.h"
#include "message.h"
#include "wsc.h"
#include "keycode.h"
#include "ascii.h"
#include "config.h"
#include "paint.h"
#include "line.h"
#include "menu.h"
#include "about.h"
#include "sioerror.h"

#define MENU_BAR_CHANGE 1

// public globals
HWND hMainWnd;            // main window handle
HWND hInfoWnd;            // popup handle
USE_INS hInstance;         // program instance
int OnLineFlag = FALSE;   // TRUE: online
int FatalFlag = FALSE;    // TRUE: fatal error
char *Alpha = "TestABCDEFGHIJKLMNOPQRSTUVWXYZ\r\n";
char Temp[1024];

// private globals

static int WinWidth = 8 * NCOLS;
static int WinHeight = 12 * NROWS + 48;

// miscellaneous functions

void ErrorCheck(int);
void ErrorMessage(char *);

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
    wc.hIcon = LoadIcon(hInst, "ModemIcon");
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH);
    wc.lpszMenuName =  "ModemMenu";
    wc.lpszClassName = "ModemWClass";
    Result = RegisterClass(&wc);
    if(!Result) return FALSE;
   }

 // create main window
 hInstance = hInst;
 hMainWnd = CreateWindow(
        "ModemWClass",   "Modem",       WS_OVERLAPPEDWINDOW,
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
{int  i, n;
 int  Count;
 int  StatusWord;
 HDC  hDC;
 UINT idTimer = 0;
 PAINTSTRUCT ps;
#ifdef WIN32
#else
 static FARPROC lpfnAboutDlgProc;
#endif
 static int ThePort;

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

            case MSG_TEST:
#if 1
              DisplayLine("Sending test string 'TestABCD...XYZ' 16 times");
              for(i=0;i<16;i++) SioPuts(ThePort,Alpha,32);
#else
              DisplayLine("Changing baud to 57600\n");
              SioBaud(ThePort, 57600);
#endif
              break;

            case MSG_ONLINE:
              if(FatalFlag) ErrorMessage("Fatal Error");
              else
                {// try to go on-line
                 ThePort = GetPort();
                 GoOnLine(ThePort,GetBaud(),2048,512);
                 // no flow control
                 SioFlow(ThePort,'N');
                 // set DTR and RTS
                 SioDTR(ThePort,'S');
                 SioRTS(ThePort,'S');
                 SetTitle();
                 // update menu settings
                 CheckTheMenu(MSG_DTR_SET);
                 CheckTheMenu(MSG_RTS_SET);
                 UncheckTheMenu(MSG_HW_FLOW);
                 UncheckTheMenu(MSG_SW_FLOW);
                 CheckTheMenu(MSG_NO_FLOW);
                 CheckTheMenu(MSG_ONLINE);
                 UncheckTheMenu(MSG_OFFLINE);
                 EnableTheMenu(MSG_OFFLINE);
                 DisableTheMenu(MSG_ONLINE);
                 DisableMenuBarItem(MENU_BAR_CHANGE);
                 for(i=2;i<=5;i++) EnableMenuBarItem(i);
                 DrawMenuBar(hMainWnd);
                 if(!OnLineFlag) break;
                }
              break;

            case MSG_OFFLINE:
              GoOffLine(ThePort);
              SetTitle();
              // update menu settings
              CheckTheMenu(MSG_OFFLINE);
              UncheckTheMenu(MSG_ONLINE);
              EnableTheMenu(MSG_ONLINE);
              DisableTheMenu(MSG_OFFLINE);
              EnableMenuBarItem(MENU_BAR_CHANGE);
              for(i=2;i<=5;i++) DisableMenuBarItem(i);
              DrawMenuBar(hMainWnd);
              break;

            case MSG_EXIT:
              GoOffLine(ThePort);
              if(idTimer) KillTimer(hMainWnd,idTimer);
              PostQuitMessage(0);
              break;

            case MSG_110:
              SetBaud(WSC_Baud110);
              break;

            case MSG_300:
              SetBaud(WSC_Baud300);
              break;

            case MSG_1200:
              SetBaud(WSC_Baud1200);
              break;

            case MSG_2400:
              SetBaud(WSC_Baud2400);
              break;

            case MSG_4800:
              SetBaud(WSC_Baud4800);
              break;

            case MSG_9600:
              SetBaud(WSC_Baud9600);
              break;

            case MSG_19200:
              SetBaud(WSC_Baud19200);
              break;

            case MSG_38400:
              SetBaud(WSC_Baud38400);
              break;

            case MSG_57600:
              SetBaud(WSC_Baud57600);
              break;

            case MSG_COM1:
              SetThePort(COM1);
              break;

            case MSG_COM2:
              SetThePort(COM2);
              break;

            case MSG_COM3:
              SetThePort(COM3);
              break;

            case MSG_COM4:
              SetThePort(COM4);
              break;

            case MSG_NONE:
              SetParity(WSC_NoParity);
              break;

            case MSG_EVEN:
              SetParity(WSC_EvenParity);
              break;

            case MSG_ODD:
              SetParity(WSC_OddParity);
              break;

            case MSG_1_SB:
              SetStopBits(WSC_OneStopBit);
              break;

            case MSG_2_SB:
              SetStopBits(WSC_TwoStopBits);
              break;

            case MSG_7_DB:
              SetWordLength(WSC_WordLength7);
              break;

            case MSG_8_DB:
              SetWordLength(WSC_WordLength8);
              break;

            case MSG_DTR_SET:
              SioDTR(ThePort,'S');
              CheckTheMenu(MSG_DTR_SET);
              UncheckTheMenu(MSG_DTR_CLR);
              break;

            case MSG_DTR_CLR:
              SioDTR(ThePort,'C');
              CheckTheMenu(MSG_DTR_CLR);
              UncheckTheMenu(MSG_DTR_SET);
              break;

            case MSG_RTS_SET:
              SioRTS(ThePort,'S');
              CheckTheMenu(MSG_RTS_SET);
              UncheckTheMenu(MSG_RTS_CLR);
              break;

            case MSG_RTS_CLR:
              SioRTS(ThePort,'C');
              CheckTheMenu(MSG_RTS_CLR);
              UncheckTheMenu(MSG_RTS_SET);
              break;

            case MSG_HW_FLOW:
              SioFlow(ThePort,'H');
              CheckTheMenu(MSG_HW_FLOW);
              UncheckTheMenu(MSG_SW_FLOW);
              UncheckTheMenu(MSG_NO_FLOW);
              DisplayLine("[Set serial device for HW flow control]");
              break;

            case MSG_SW_FLOW:
              SioFlow(ThePort,'S');
              CheckTheMenu(MSG_SW_FLOW);
              UncheckTheMenu(MSG_HW_FLOW);
              UncheckTheMenu(MSG_NO_FLOW);
              DisplayLine("[Set serial device for SW flow control]");
              break;

            case MSG_NO_FLOW:
              SioFlow(ThePort,'N');
              CheckTheMenu(MSG_NO_FLOW);
              UncheckTheMenu(MSG_HW_FLOW);
              UncheckTheMenu(MSG_SW_FLOW);
              break;

            case MSG_STATUS:

              StatusWord = SioStatus(ThePort, 0x0FFFF);
#if 0
              wsprintf((LPSTR)Temp,"Status = %xH", StatusWord);
              DisplayLine(Temp);
#endif
              // RX overflow ?
              if((WSC_RXOVER & StatusWord) != 0)
                DisplayLine("[Receive queue overflow]");
              // TX overflow
              if((WSC_TXFULL & StatusWord) != 0)
                DisplayLine("[Transmit queue overflow]");
              // Show RX queue size
              n = SioRxQue(ThePort);
              if(n>0)
                {wsprintf((LPSTR)Temp,"[%d bytes in RX queue]",n);
                 DisplayLine(Temp);
                }
              // Show TX queue size
              n = SioTxQue(ThePort);
              if(n>0)
                {wsprintf((LPSTR)Temp,"[%d bytes in TX queue size]",n);
                 DisplayLine(Temp);
                }
              // BREAK signal status
              if(SioBrkSig(ThePort, 'D') > 0) DisplayLine("[BREAK detected]");
              // DTR status
              if(SioDTR(ThePort,'R'))
                {DisplayLine("[DTR set]");
                 CheckTheMenu(MSG_DTR_SET);
                 UncheckTheMenu(MSG_DTR_CLR);
                }
              else
                {DisplayLine("[DTR clear]");
                 CheckTheMenu(MSG_DTR_CLR);
                 UncheckTheMenu(MSG_DTR_SET);
                }
              // RTS status
              if(SioRTS(ThePort,'R'))
                {DisplayLine("[RTS set]");
                 CheckTheMenu(MSG_RTS_SET);
                 UncheckTheMenu(MSG_RTS_CLR);
                }
              else
                {DisplayLine("[RTS clear]");
                 CheckTheMenu(MSG_RTS_CLR);
                 UncheckTheMenu(MSG_RTS_SET);
                }
              // DSR status
              if(SioDSR(ThePort) > 0) DisplayLine("[DSR set]");
              else DisplayLine("[DSR clear]");
              // CTS status
              if(SioCTS(ThePort) > 0) DisplayLine("[CTS set]");
              else DisplayLine("[CTS clear]");
              // DCD (Data Carrier Detect) status
              if(SioDCD(ThePort) > 0) DisplayLine("[DCD set]");
              else DisplayLine("[DCD clear]");

              //** This block is NOT for Win32 running under Windows NT/2000 **
#if 0
              // read all ports
              for(i=0;i<7;i++)
                {n = SioRead(ThePort,i);
                 wsprintf((LPSTR)Temp,"Reg[%d] = 0x%x", i,n);
                 DisplayLine((LPSTR)Temp);
                }
#endif
              break;

            default:
              return (DefWindowProc(hMainWnd, iMsg, wParam, lParam));
           }
         break;

    case WM_CREATE:

      // check "OFFLINE" menu item
      CheckTheMenu(MSG_OFFLINE);
      DisableTheMenu(MSG_OFFLINE);
      // disable all but LINE & CHANGE
      for(i=2;i<=5;i++) DisableMenuBarItem(i);
#ifdef WIN32
#else
      // create AboutDlgProc() thunk
      lpfnAboutDlgProc = MakeProcInstance(AboutDlgProc, hInstance);
#endif
      // initialize paint module
      PaintInit();
      // init configuration
      CheckAll();
      CheckTheMenu(MSG_NO_FLOW);
      UncheckTheMenu(MSG_HW_FLOW);
      UncheckTheMenu(MSG_SW_FLOW);
      SetText((LPSTR)"MODEM");
      SetTitle();
      // pass the key code
      if(SioKeyCode(WSC_KEY_CODE)<0)
        {DisplayLine((LPSTR)"ERROR: Bad Key Code!");
         break;
        }
      // start timer
      idTimer = SetTimer(hMainWnd,1,125,NULL);
      if(idTimer==0)
         {ErrorMessage("No timers remaining !");
          FatalFlag = TRUE;
         }
      break;

    case WM_CHAR:
      SioPutc(ThePort, (char)wParam );
      break;

    case WM_TIMER:
      // fatal error ?
      if(FatalFlag) break;
      if(!OnLineFlag) break;
      // fetch up to 1024 chars
      Count = SioGets(ThePort,Temp,1024);
      if(Count>0) WriteTheString(Temp,Count);
      break;

    case WM_SETFOCUS:
      // create client area caret
      CreateCaret(hMainWnd,NULL,3,10);
      SetCaretPos(PaintGetColPos(),PaintGetRowPos());
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
      if(idTimer) KillTimer(hMainWnd,idTimer);
      PostQuitMessage(0);
      break;

    default:
      return (DefWindowProc(hMainWnd, iMsg, wParam, lParam));
   }
 return 0;
} // end MainWndProc

void ErrorCheck(int Code)
{// trap PCL error codes
 if(Code<0)
    {SioError(Code,"Sio Error");
     SioDone(GetPort());
     FatalFlag = TRUE;
    }
}

void ErrorMessage(char *MsgPtr)
{
 MessageBox(hMainWnd,MsgPtr,"ERROR",MB_ICONEXCLAMATION | MB_OK);
}




