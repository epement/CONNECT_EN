//
// NAME: TERM.C
//
// TYPE: Win32 GUI mode.
//
// DATE: August 6, 2004.
//
// PURPOSE: Terminal emulator example program. Features Dialing,
//          XMODEM/YMODEM/ASCII protocols and ANSI emulation.
//
// NOTE: Must be in 8N1 before using XMODEM or YMODEM !
//
// COMPILE: From the command line:
//
//     nmake -f term32._m_  (Microsoft VC)
//      make -f term32._b_  (Borland 5.0)
//      make -f term32._i_  (Borland 5.5)
//     wmake -f term32._w_  (Watcom 11)
//              term$.bat   (LCC-WIN32)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace term.mak in MSVC IDE.
//     Open workspace term.dsp in MSVC (ver 6.0 only).
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

#include "wsc.h"
#include "keycode.h"
#include "mio.h"
#include "xym.h"
#include "term.h"
#include "message.h"
#include "ascii.h"
#include "config.h"
#include "paint.h"
#include "line.h"
#include "menu.h"
#include "about.h"
#include "sioerror.h"
#include "accept.h"
#include "ansi.h"
#include "asdrv.h"
#include "progress.h"

// defines

#define MENU_BAR_LINE    0
#define MENU_BAR_CHANGE  1
#define MENU_BAR_DIAL    2
#define MENU_BAR_SEND    3
#define MENU_BAR_RECEIVE 4
#define MENU_BAR_BREAK   5
#define MENU_BAR_STATUS  6

#define Dial_1    1
#define Dial_2    2
#define Dial_3    3

#define XM_RCV    1
#define XM_SND    2
#define YM_RCV    3
#define YM_SND    4
#define XY_MODEM  5
#define ASC_RCV   6
#define ASC_SND   7
#define ASC_MODEM 8

#define QUESIZE 2048

// public globals

HWND hMainWnd;            // main window handle
HWND hProgressWnd;        // file xfer progress handle
USE_INS hInstance;        // program instance
int OnLineFlag = FALSE;   // TRUE: online
int FatalFlag = FALSE;    // TRUE: fatal error
char Temp[1024];
char MsgBuffer[81];

// private globals

static int ThePort = -1;       // the port
static int DebugLevel = 0;     // debug level must be [0,1,2]
#ifdef WIN32
#else
static FARPROC lpfnAboutDlgProc = NULL;
static FARPROC lpfnAcceptDlgProc = NULL;
static FARPROC lpfnProgressProc = NULL;
#endif
static int WinWidth = 8 * NCOLS;
static int WinHeight = 12 * NROWS + 48;
static char FileName[65];
static char DialString[40];
static int LastPacket = -1;

// miscellaneous functions

int StartXY(int,LPSTR);
int StartAscii(LPSTR);
void ErrorCheck(int);
void ErrorMessage(LPSTR);
void ShowProgress(void);

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
    wc.hIcon = LoadIcon(hInst, "TermIcon");
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH) GetStockObject(WHITE_BRUSH);
    wc.lpszMenuName =  "TermMenu";
    wc.lpszClassName = "TermWClass";
    Result = RegisterClass(&wc);
    if(!Result) return FALSE;
   }

 // create main window
 hInstance = hInst;
 hMainWnd = CreateWindow(
   "TermWClass",   "Term",       WS_OVERLAPPEDWINDOW,
   CW_USEDEFAULT,  CW_USEDEFAULT,
   WinWidth,       WinHeight,
   NULL,           NULL,
   hInstance,      NULL);
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
{int  i;
 int  TheChar;
 int  rc, Code;
 HDC  hDC;
 UINT idTimer = 0;
 PAINTSTRUCT ps;
 static int mioState;
 static int xyState;
 static int ascState;

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

            case MSG_BREAK:
              if(hProgressWnd)
                {DestroyWindow(hProgressWnd);
                 hProgressWnd = 0;
                };
              mioState = 0;
              xyState = 0;
              ascState = 0;
              LastPacket = -1;
              mioBreak(ThePort);
              xyAbort(ThePort);
              DisableTheMenu(MSG_BREAK);
              DrawMenuBar(hMainWnd);
              break;

            case MSG_ASC_RCV:
              if(!StartAscii(FileName)) break;
              ascState = ASC_RCV;
              break;

            case MSG_ASC_SND:
              if(!StartAscii(FileName)) break;
              ascState = ASC_SND;
              break;

            case MSG_XM_RCV:
              if(!StartXY(1,FileName)) break;
              xyState = XM_RCV;
              break;

            case MSG_XM_SND:
              if(!StartXY(1,FileName)) break;
              xyState = XM_SND;
              break;

            case MSG_YM_RCV:
              if(!StartXY(0,FileName)) break;
              xyState = YM_RCV;
              break;

            case MSG_YM_SND:
              if(!StartXY(2,FileName)) break;
              xyState = YM_SND;
              break;

            case MSG_DIAL:
#ifdef WIN32
              DialogBoxParam(hInstance,"AcceptBox",hMainWnd,AcceptDlgProc,0);
#else
              DialogBoxParam(hInstance,"AcceptBox",hMainWnd,lpfnAcceptDlgProc,0);
#endif
              mioState = Dial_1;
              break;

            case MSG_DEBUG_LEVEL_OFF:
              DebugLevel = 0;
              xyDebug(DebugLevel);
              DisplayLine("Debug off");
              break;
            case MSG_DEBUG_LEVEL_LOW:
              DebugLevel = 1;
              xyDebug(DebugLevel);
              DisplayLine("Debug low");
              break;
            case MSG_DEBUG_LEVEL_HIGH:
              DebugLevel = 2;
              xyDebug(DebugLevel);
              DisplayLine("Debug high");
              break;
            case MSG_STATUS:
              while(xyGetMessage(ThePort,(LPSTR)MsgBuffer,80)) DisplayLine(MsgBuffer);
              // get state info
              Code = (int) xyGetParameter(ThePort,XY_GET_ERROR_CODE);
              if(Code)
                {wsprintf(Temp,"ERROR_CODE=%d", Code );
                 DisplayLine(Temp);
                 if(Code>=WSC_EXPIRED) SioError(Code,"");
                 wsprintf(Temp,"ERROR_STATE=%d", (int)xyGetParameter(ThePort,XY_GET_ERROR_STATE) );
                 DisplayLine(Temp);
                }
              if(ThePort<0) break;
              Code = SioStatus(ThePort, 0xFFFF);
              // framing error ?
              if((WSC_FRAME & Code) > 0) DisplayLine("[Framing error]");
              // overrun error ?
              if((WSC_OVERRUN & Code) > 0) DisplayLine("[Data overrun error]");
              // parity error ?
              if((WSC_PARITY & Code) > 0) DisplayLine("[Data parity error]");
              // RX overflow
              if((WSC_RXOVER & Code) > 0) DisplayLine("[Receive queue overflow]");
              // TX overflow
              if((WSC_TXFULL & Code) > 0) DisplayLine("[Transmit queue overflow]");
              // Show RX queue size
              Code = SioRxQue(ThePort);
              if(Code>0)
                {wsprintf((LPSTR)Temp,"[RX queue size = %d]", Code);
                 DisplayLine(Temp);
                }
              // Show TX queue size
              Code = SioTxQue(ThePort);
              if(Code>0)
                {wsprintf((LPSTR)Temp,"[TX queue size = %d]", Code);
                 DisplayLine(Temp);
                }
              // DSR status
              if(SioDSR(ThePort) > 0) DisplayLine("[DSR set]");
              else DisplayLine("[DSR clear]");
              // CTS status
              if(SioCTS(ThePort) > 0) DisplayLine("[CTS set]");
              else DisplayLine("[CTS clear]");
              break;

            case MSG_ONLINE:
              if(FatalFlag) ErrorMessage("Fatal Error");
              else
                {// try to go on-line
                 ThePort = GetPort();
                 GoOnLine(ThePort,GetBaud(),QUESIZE,QUESIZE);
                 Code = 0;
                 if(SioDSR(ThePort)==0) DisplayLine("[Expecting DSR=1]");
                 else Code++;
                 if(SioCTS(ThePort)==0) DisplayLine("[Expecting CTS=1]");
                 else Code++;
                 if(Code==2)
                   {// set hardware flow control
                    DisplayLine("[Setting hardware (RTS/CTS) flow control]");
                    SioFlow(ThePort,'H');
                   }
                 else DisplayLine("[Flow control is NOT set]");
                 // setup XYM
                 xyAcquire(ThePort,ThePort);
                 xyDebug(DebugLevel);
                 // setup ASDRV
                 ascInit(ThePort,QUESIZE,TRUE);
                 EnableMenuBarItem(MENU_BAR_SEND);
                 EnableMenuBarItem(MENU_BAR_RECEIVE);
                 EnableMenuBarItem(MENU_BAR_STATUS);
                 EnableTheMenu(MSG_DIAL);
                 SetTitle();
                 CheckTheMenu(MSG_ONLINE);
                 UncheckTheMenu(MSG_OFFLINE);
                 EnableTheMenu(MSG_OFFLINE);
                 DisableTheMenu(MSG_ONLINE);
                 DisableMenuBarItem(MENU_BAR_CHANGE);
                 DrawMenuBar(hMainWnd);
                }
              break;

            case MSG_OFFLINE:

              CheckTheMenu(MSG_OFFLINE);
              UncheckTheMenu(MSG_ONLINE);
              EnableTheMenu(MSG_ONLINE);
              DisableTheMenu(MSG_OFFLINE);
              DisableTheMenu(MSG_DIAL);
              EnableMenuBarItem(MENU_BAR_CHANGE);
              GoOffLine(ThePort);
              xyRelease();
              SetTitle();
              DisableMenuBarItem(MENU_BAR_SEND);
              DisableMenuBarItem(MENU_BAR_RECEIVE);
              DisableMenuBarItem(MENU_BAR_STATUS);
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

            case MSG_115200:
              SetBaud(WSC_Baud115200);
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

            default:
              return (DefWindowProc(hMainWnd, iMsg, wParam, lParam));
           }
         break;

    case WM_CREATE:
      hProgressWnd = 0;
      // check "OFFLINE" menu item
      CheckTheMenu(MSG_OFFLINE);
      DisableTheMenu(MSG_OFFLINE);
      DisableTheMenu(MSG_BREAK);
      DisableTheMenu(MSG_DIAL);
      DisableMenuBarItem(MENU_BAR_SEND);
      DisableMenuBarItem(MENU_BAR_RECEIVE);
      DisableMenuBarItem(MENU_BAR_STATUS);
#ifdef WIN32
#else
      // create AboutDlgProc() thunk
      lpfnAboutDlgProc = MakeProcInstance(AboutDlgProc, hInstance);
      // create AcceptDlgProc() thunk
      lpfnAcceptDlgProc = MakeProcInstance(AcceptDlgProc, hInstance);
      // create ProgressProc() thunk
      lpfnProgressProc = MakeProcInstance(ProgressProc,hInstance);
#endif
      // initialize paint module
      PaintInit();
      // init configuration
      CheckAll();
      SetText((LPSTR)"TERM");
      SetTitle();
      // pass the key code
      if(SioKeyCode(WSC_KEY_CODE)<0)
        {DisplayLine((LPSTR)"ERROR: Bad Key Code!");
         break;
        }
      // start timer
      idTimer = SetTimer(hMainWnd,1,50,NULL);
      if(idTimer==0)
         {ErrorMessage("No timers remaining !");
          FatalFlag = TRUE;
         }
      DrawMenuBar(hMainWnd);
      break;

    case WM_KEYDOWN:
      switch(wParam)
        {case VK_UP:
           AnsiUp(ThePort);
           break;
         case VK_DOWN:
           AnsiDown(ThePort);
           break;
         case VK_RIGHT:
           AnsiRight(ThePort);
           break;
         case VK_LEFT:
           AnsiLeft(ThePort);
           break;
        }
      break;

    case WM_CHAR:
      // send char to port
      SioPutc(ThePort, (char)wParam );
      break;

    case WM_TIMER:
      // fatal error ?
      if(FatalFlag) break;
      if(!OnLineFlag) break;

      // is xyDriver running ?
      if(xyState) switch(xyState)
        {case XM_RCV:
           // XMODEM receive
           if(xyStartRx(ThePort,(LPSTR)FileName,(char)NAK,FALSE))
              {DisplayLine("XMODEM Rx started (assuming 8N1)");
               xyState = XY_MODEM;
              }
           else
              {DisplayLine("Could not start RX");
               xyState = 0;
              }
           break;
         case XM_SND:
           // XMODEM send
           if(xyStartTx(ThePort,(LPSTR)FileName,FALSE,FALSE))
              {DisplayLine("XMODEM Tx started (assuming 8N1)");
               xyState = XY_MODEM;
              }
           else
              {DisplayLine("Could not start TX");
               xyState = 0;
              }
           break;
         case YM_RCV:
           // YMODEM receive
           *FileName = '\0';
           if(xyStartRx(ThePort,(LPSTR)FileName,(char)'C',TRUE))
              {DisplayLine("YMODEM Rx started  (assuming 8N1)");
               xyState = XY_MODEM;
              }
           else
              {DisplayLine("Could not start RX");
               xyState = 0;
              }
           break;
         case YM_SND:
           // YMODEM send
           if(xyStartTx(ThePort,(LPSTR)FileName,TRUE,TRUE))
              {DisplayLine("YMODEM Tx started (assuming 8N1)");
               xyState = XY_MODEM;
              }
           else
              {DisplayLine("Could not start TX");
               xyState = 0;
              }
           break;

         case XY_MODEM:

           // run the driver several times
           {int i;
            for(i=0;i<4;i++) rc = xyDriver(ThePort);
           }
           // look at any messages
           while(xyGetMessage(ThePort,(LPSTR)MsgBuffer,80)) DisplayLine(MsgBuffer);
           if(*MsgBuffer=='!') rc = XY_IDLE;
           // XMODEM or YMODEM in progress ?
           if(rc==XY_IDLE)
             {// XY send/receive has completed
              DisplayLine("XMODEM/YMODEM is done.");
              if(hProgressWnd)
                {DestroyWindow(hProgressWnd);
                 hProgressWnd = 0;
                }
              LastPacket = -1;
              DisableTheMenu(MSG_BREAK);
              DrawMenuBar(hMainWnd);
              xyState = 0;
              break;
             }
           // XMODEM / YMODEM is still running
           ShowProgress();
           break;
         } // end-if(xyState)

      // is ascDriver running ?
      if(ascState) switch(ascState)
         {case ASC_RCV:
           // ASCII receive
           ascStartRx((LPSTR)FileName,0x00,10,3,TRUE);
           ascState = ASC_MODEM;
           break;
         case ASC_SND:
           // ASCII send
           ascStartTx((LPSTR)FileName,5,0x00,TRUE);
           ascState = ASC_MODEM;
           break;
         case ASC_MODEM:
           // run the driver
           if(ascDriver())
             {// ASCII send/receive complete
              DisplayLine("ASCII is done.");
              DisableTheMenu(MSG_BREAK);
              DrawMenuBar(hMainWnd);
              ascState = 0;
              break;
             }
           // ASCII is still running
              //ShowProgress();
           break;
        } // end-switch

      // is Modem I/O driver running ?
      if(mioState)
        {// MIO is running !
         rc = mioDriver(ThePort);
         if(rc==MIO_IDLE)
           {// time to go to next MIO state (since driver is idle)
            switch(mioState)
              {case Dial_1:
                 // fetch dial string
                 if(GetAcceptText((LPSTR)Temp))
                   {// dial modem
                    lstrcpy((LPSTR)DialString,"ATDT");
                    lstrcat((LPSTR)DialString,Temp);
                    lstrcat((LPSTR)DialString,"!");
                    DisplayLine(DialString);
                    EnableTheMenu(MSG_BREAK);
                    DrawMenuBar(hMainWnd);
                    mioSendTo(ThePort, 125, DialString);
                    mioState = Dial_2;
                   }
                 else
                   {DisplayLine("Missing phone number!");
                    mioState = 0;
                   }
                 break;
               case Dial_2:
                 // expect "CONNECT" back (wait up to 60 seconds)
                 if(mioWaitFor(ThePort, 60000, "CONNECT")) mioState = Dial_3;
                 else DisplayString (">>>mioWaitFor fails!");
                 break;
               case Dial_3:
                 // did we get expected result ("CONNECT")
                 if(mioResult(ThePort)) DisplayString (">>>CONNECT was received");
                 else DisplayString (">>>CONNECT was NOT received!");
                 // all done
                 DisableTheMenu(MSG_BREAK);
                 DrawMenuBar(hMainWnd);
                 mioState = 0;
               } // end-switch
            }
         else
           {// MIO is not IDLE
            if(rc != MIO_RUNNING) DisplayChar((char)rc);
           } // end-if(mioState)
         break;
        }

      // AnsiGetc() may return cursor status report
      while((i = AnsiGetc()) >= 0) SioPutc(ThePort, (char)i);

      // IMPORTANT: Continue on ONLY if none of the drivers are running
      if(xyState||ascState||mioState) break;

      // fetch line of up to 1024 chars
      for(i=0;i<1024;i++)
        {TheChar = SioGetc(ThePort);
         // character available ?
         if(TheChar==WSC_NO_DATA) break;
         AnsiPutc((char)TheChar);
        } // end while
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

void ErrorMessage(LPSTR MsgPtr)
{
 MessageBox(hMainWnd,MsgPtr,"ERROR",MB_ICONEXCLAMATION | MB_OK);
}

void ShowProgress(void)
{int Packet;
 while(xyGetMessage(ThePort,(LPSTR)MsgBuffer,80)) DisplayLine(MsgBuffer);
 Packet = (int) xyGetParameter(ThePort,XY_GET_PACKET);
 if(Packet!=LastPacket)
   {// new packet number
    LastPacket = Packet;
    if(DebugLevel==0)
      {wsprintf((LPSTR)Temp,"Packet %d \r",Packet);
       SetDlgItemText(hProgressWnd,IDOK,(LPSTR)Temp);
      }
    if(Packet==0)
      {// get incoming filename
       xyGetFileName(ThePort,(LPSTR)Temp,65);
       if(Temp[0])
         {DisplayString("Filename = ");
          DisplayLine((LPSTR)Temp);
         }
      }
   }
}

int StartXY(int Choice, LPSTR FileName)
{int Version;
 if(!OnLineFlag)
   {DisplayLine("Must be online!");
    return FALSE;
   }
 // check that other side has set DSR
 if(SioDSR(ThePort)==0)
   {DisplayLine("Warning: Using XMODEM/YMODEM without flow control.");
    ///DisplayLine("DSR must be set by remote before using XMODEM/YMODEM.");
    ///return FALSE;
   }
 Version = xyGetParameter(ThePort,XY_GET_VERSION);
 wsprintf((LPSTR)Temp,"XYM Version %d.%d.%d", (Version>>8),0x0f&(Version>>4),0x0f&Version);
 DisplayLine((LPSTR)Temp);
 if(xyGetParameter(ThePort,XY_GET_STATE)!=(long)XY_IDLE)
   {DisplayLine("xyDriver already running!");
    return FALSE;
   }
 if(Choice)
   {// get file name from user
#ifdef WIN32
    DialogBoxParam(hInstance,"AcceptBox",hMainWnd,AcceptDlgProc,Choice);
#else
    DialogBoxParam(hInstance,"AcceptBox",hMainWnd,lpfnAcceptDlgProc,Choice);
#endif
    if(GetAcceptText((LPSTR)FileName)) DisplayLine(FileName);
    else
      {DisplayLine("Missing filename");
       return FALSE;
      }
   }
#ifdef WIN32
 hProgressWnd = CreateDialog(hInstance, "ProgressBox", hMainWnd, ProgressProc);
#else
 hProgressWnd = CreateDialog(hInstance, "ProgressBox", hMainWnd, lpfnProgressProc);
#endif
 EnableTheMenu(MSG_BREAK);
 DrawMenuBar(hMainWnd);
 return TRUE;
}

int StartAscii(LPSTR FileName)
{if(!OnLineFlag)
   {DisplayLine("Must be online!");
    return FALSE;
   }
 if(!ascDriver())
   {DisplayLine("ascDriver already running!");
    return FALSE;
   }
 // get file name from user
#ifdef WIN32
 DialogBoxParam(hInstance,"AcceptBox",hMainWnd,AcceptDlgProc,3);
#else
 DialogBoxParam(hInstance,"AcceptBox",hMainWnd,lpfnAcceptDlgProc,3);
#endif
 if(GetAcceptText((LPSTR)FileName)) DisplayLine(FileName);
 else
   {DisplayLine("Missing filename");
    return FALSE;
   }
 EnableTheMenu(MSG_BREAK);
 DrawMenuBar(hMainWnd);
 return TRUE;
}

