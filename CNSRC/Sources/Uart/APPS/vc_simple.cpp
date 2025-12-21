//
// NAME: SIMPLE.CPP
//
// TYPE: Win32 GUI mode (VC.Net).
//
// DATE: August 6, 2004.
//
// PURPOSE: Simple terminal emulator example program.
//
// IMPORTANT: You MUST match flow control to your serial device.  See line 41 of LINE.C
//
// COMPILE: From VC.Net integrated developer environment (IDE):
//
//     Open workspace vc_simple.vcproj in Visual Stdudio .NET
//

#include "stdafx.h"
#include "vc_simple.h"

#include "wsc.h"
#include "keycode.h"
#include "message.h"
#include "PaintClass.h"

#define MAX_LOADSTRING 100

// Global Variables:

HINSTANCE hInst;                               // current instance
TCHAR szTitle[MAX_LOADSTRING];                 // The title bar text
TCHAR szWindowClass[MAX_LOADSTRING];           // the main window class name

#define TEMP_SIZE 1023

static HMENU hMenu;
static UINT idTimer;
static HWND hMainWnd;
static int OnLineFlag = FALSE;   // TRUE: online
static int FatalFlag = FALSE;    // TRUE: fatal error
static int ThePort = COM1;
static int TheBaud = WSC_Baud19200;
static long BaudRateList[10]
       = {300L,600L,1200L,2400L,4800L,9600L,19200L,38400L,57600L,115200L};
static char Temp[TEMP_SIZE+1];

// Forward declarations of functions included in this code module:
ATOM                    MyRegisterClass(HINSTANCE hInstance);
BOOL                    InitInstance(HINSTANCE, int);
LRESULT CALLBACK        WndProc(HWND, UINT, WPARAM, LPARAM);
LRESULT CALLBACK        About(HWND, UINT, WPARAM, LPARAM);


static void MsgBox(LPSTR Ptr)
{
 MessageBox(NULL,Ptr,(LPSTR)"Info",MB_TASKMODAL|MB_ICONEXCLAMATION);
}

void GetErrorText(int Code, LPSTR Buffer, int BufLen)
{switch(Code)
   {case WSC_NO_DATA:
      lstrcpy((LPSTR)Buffer,(LPSTR)"No Data");
      break;
    case WSC_RANGE:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Parameter out of range");
      break;
    case WSC_ABORTED:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Aborted");
      break;
    case WSC_EXPIRED:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Evaluation version expired, or SioKeyCode not called");
      break;
    case WSC_BUFFERS:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Cannot allocate memory for buffers");
      break;
    case WSC_THREAD:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Cannot start thread");
      break;
    case WSC_TIMEOUT:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Timed out");
      break;
    case WSC_KEYCODE:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Bad key code.");
      break;
    case WSC_IE_BADID:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Invalid COM port");
      break;
    case WSC_IE_OPEN:
      lstrcpy((LPSTR)Buffer,(LPSTR)"COM port already open");
      break;
    case WSC_IE_NOPEN:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Cannot open COM port");
      break;
    case WSC_IE_MEMORY:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Cannot allocate memory");
      break;
    case WSC_IE_DEFAULT:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Error in default parameters");
      break;
    case WSC_IE_HARDWARE:
      lstrcpy((LPSTR)Buffer,(LPSTR)"COM port hardware not present");
      break;
    case WSC_IE_BYTESIZE:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Unsupported byte size");
      break;
    case WSC_IE_BAUDRATE:
      lstrcpy((LPSTR)Buffer,(LPSTR)"Unsupported baud rate");
      break;
    case WSC_WIN32ERR:
      SioWinError((LPSTR)Temp,80);
      lstrcpy((LPSTR)Buffer,(LPSTR)Temp);
      break;
    default:
      wsprintf((LPSTR)Temp,"Unknown code %d",Code);
      lstrcpy((LPSTR)Buffer,(LPSTR)Temp);
      break;
   }
}

//--------------------------------------------------------------------

//static void DisplayString(HWND hWnd, LPSTR Ptr, int Line)
//{HDC hDC;
// hDC = GetDC(hWnd);
// TextOut(hDC, 2, 15*Line, Ptr, lstrlen(Ptr));
// ReleaseDC(hWnd, hDC);
//}

//--------------------------------------------------------------------

int APIENTRY _tWinMain(HINSTANCE hInstance,
                       HINSTANCE hPrevInstance,
                       LPTSTR    lpCmdLine,
                       int       nCmdShow)
{
        // TODO: Place code here.
        MSG msg;
        HACCEL hAccelTable;

        // Initialize global strings
        LoadString(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
        LoadString(hInstance, IDC_VC_SIMPLE, szWindowClass, MAX_LOADSTRING);
        MyRegisterClass(hInstance);

        // Perform application initialization:
        if (!InitInstance (hInstance, nCmdShow))
        {
                return FALSE;
        }

        hAccelTable = LoadAccelerators(hInstance, (LPCTSTR)IDC_VC_SIMPLE);

        // Main message loop:
        while (GetMessage(&msg, NULL, 0, 0))
        {
                if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
                {
                        TranslateMessage(&msg);
                        DispatchMessage(&msg);
                }
        }

        return (int) msg.wParam;
}



//
//  FUNCTION: MyRegisterClass()
//
//  PURPOSE: Registers the window class.
//
//  COMMENTS:
//
//    This function and its usage are only necessary if you want this code
//    to be compatible with Win32 systems prior to the 'RegisterClassEx'
//    function that was added to Windows 95. It is important to call this function
//    so that the application will get 'well formed' small icons associated
//    with it.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
        WNDCLASSEX wcex;

        wcex.cbSize = sizeof(WNDCLASSEX);

        wcex.style              = CS_HREDRAW | CS_VREDRAW;
        wcex.lpfnWndProc        = (WNDPROC)WndProc;
        wcex.cbClsExtra         = 0;
        wcex.cbWndExtra         = 0;
        wcex.hInstance          = hInstance;
        wcex.hIcon              = LoadIcon(hInstance, (LPCTSTR)IDI_VC_SIMPLE);
        wcex.hCursor            = LoadCursor(NULL, IDC_ARROW);
        wcex.hbrBackground      = (HBRUSH)(COLOR_WINDOW+1);
        wcex.lpszMenuName       = (LPCTSTR)IDC_VC_SIMPLE;
        wcex.lpszClassName      = szWindowClass;
        wcex.hIconSm            = LoadIcon(wcex.hInstance, (LPCTSTR)IDI_SMALL);

        return RegisterClassEx(&wcex);
}

//
//   FUNCTION: InitInstance(HANDLE, int)
//
//   PURPOSE: Saves instance handle and creates main window
//
//   COMMENTS:
//
//        In this function, we save the instance handle in a global variable and
//        create and display the main program window.
//

BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   HWND hWnd;

   hInst = hInstance; // Store instance handle in our global variable

   hWnd = CreateWindow(szWindowClass,
                       szTitle,
                       WS_OVERLAPPEDWINDOW,
                       CW_USEDEFAULT,    // X
                       CW_USEDEFAULT,    // Y
                       600,              // width
                       360,              // height
                       NULL,
                       NULL,
                       hInstance,
                       NULL);

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   return TRUE;
}

//
//  FUNCTION: WndProc(HWND, unsigned, WORD, LONG)
//
//  PURPOSE:  Processes messages for the main window.
//
//  WM_COMMAND  - process the application menu
//  WM_PAINT    - Paint the main window
//  WM_DESTROY  - post a quit message and return
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
        int wmId, wmEvent;
        PAINTSTRUCT ps;
        HDC hDC;
        int i;
        int Count;
        int Code;
        static PaintClass p(hWnd);

        switch (message)
        {
         case WM_COMMAND:
                wmId    = LOWORD(wParam);
                wmEvent = HIWORD(wParam);
                // Parse the menu selections:
                switch (wmId)
                {case MSG_ONLINE:

                    SioReset(-1,1,1); // Set DTR & RTS at port initialization.
                    Code = SioReset(ThePort, 1024, 1024);
                    if(Code<0)
                      {// sioerror ...GetErrorText(int Code, LPSTR Buffer, int BufLen)
                       GetErrorText(Code,(LPSTR)Temp,128);
                       p.DisplayLine((LPSTR)Temp);
                       break;
                      }
                    SioBaud(ThePort, 19200);
                    SioRxClear(ThePort);
                    // You MUST match flow control (none, HW, SW) to the serial device
                    // to which you are connected!
#if 1
                    // no flow control
                    p.DisplayLine((LPSTR)"Flow control not enabled");
                    SioFlow(ThePort,'N');
                    if(SioCTS(ThePort))
                      p.DisplayLine((LPSTR)"CTS detected: You may need to enable HW flow control");
#else
                    // hardware flow control [REQUIRED for modems!]
                    p.DisplayLine((LPSTR)"HW flow control is enabled");
                    SioFlow(ThePort,'H');
#endif
                    wsprintf((LPSTR)Temp,(LPSTR)"VC_SIMPLE: COM%d online at %ld baud",
                       1+ThePort,BaudRateList[TheBaud]);
                    SetWindowText(hMainWnd,Temp);
                    CheckMenuItem(hMenu,MSG_OFFLINE,MF_BYCOMMAND | MF_UNCHECKED);
                    CheckMenuItem(hMenu,MSG_ONLINE,MF_BYCOMMAND | MF_CHECKED);
                    for(i=MSG_COM1;i<=MSG_COM4;i++)
                       EnableMenuItem(hMenu,i,MF_BYCOMMAND|MF_GRAYED);
                    for(i=MSG_300;i<=MSG_115200;i++)
                       EnableMenuItem(hMenu,i,MF_BYCOMMAND|MF_GRAYED);
                    OnLineFlag = TRUE;
                    break;

                 case MSG_OFFLINE:
                    SioDone(ThePort);
                    SetWindowText(hMainWnd,"VC_SIMPLE: Offline");
                    CheckMenuItem(hMenu,MSG_ONLINE,MF_BYCOMMAND | MF_UNCHECKED);
                    CheckMenuItem(hMenu,MSG_OFFLINE,MF_BYCOMMAND | MF_CHECKED);
                    for(i=MSG_COM1;i<=MSG_COM4;i++)
                      EnableMenuItem(hMenu,i,MF_BYCOMMAND|MF_ENABLED);
                    for(i=MSG_300;i<=MSG_115200;i++)
                    EnableMenuItem(hMenu,i,MF_BYCOMMAND|MF_ENABLED);
                    OnLineFlag = FALSE;
                    break;

                 case MSG_INFO:
                   {int Version;
                    int Build;
                    int Code;
                    int DaysLeft;
                    char Temp[55];
                     // display version and build
                    Version = SioInfo('V');
                    Build = SioInfo('B');
                    wsprintf((LPSTR)Temp,"Win32 WSC Version %d.%d.%d, Build %d",
                          (Version>>8),0x0f&(Version>>4),0x0f&Version, Build);
                    p.DisplayLine((LPSTR)Temp);
                    // display registration string
                    Code = SioGetReg((LPSTR)Temp, 50);
                    if(Code>0) p.DisplayLine((LPSTR)Temp);
                    // display # days left in evaluation version
                    DaysLeft = SioInfo('?');
                    if(DaysLeft==999) break; // registered version always returns 999
                    if(DaysLeft>0)
                      wsprintf((LPSTR)Temp,"%d days remaining for evaluation", DaysLeft );
                    else
                      wsprintf((LPSTR)Temp,"90 day evaluation period exceeded!");
                    p.DisplayLine((LPSTR)Temp);

                   }
                   p.DisplayLine("Using timer method");
                   break;

                case MSG_ABOUT:
                   DialogBox(hInst, (LPCTSTR)IDD_ABOUTBOX, hWnd, (DLGPROC)About);
                   break;

                case MSG_EXIT:
                   DestroyWindow(hWnd);
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

               case MSG_115200:
                  CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_UNCHECKED);
                  TheBaud = WSC_Baud115200;
                  CheckMenuItem(hMenu,MSG_115200,MF_BYCOMMAND | MF_CHECKED);
                  break;

                default:
                   return DefWindowProc(hWnd, message, wParam, lParam);
                }
                break;

        case WM_CREATE:
                hMainWnd = hWnd;
                // check "OFFLINE" menu item
                hMenu = GetMenu(hMainWnd);
                CheckMenuItem(hMenu,MSG_OFFLINE,MF_BYCOMMAND | MF_CHECKED);
                // check default COM port
                CheckMenuItem(hMenu,MSG_COM1+ThePort,MF_BYCOMMAND | MF_CHECKED);
                // check default baud rate
                CheckMenuItem(hMenu,MSG_300+TheBaud,MF_BYCOMMAND | MF_CHECKED);
                // pass the key code
                if(SioKeyCode(WSC_KEY_CODE)<0)
                   {MsgBox((LPSTR)"ERROR: Bad Key Code!");
                    break;
                   }
                // start timer
                idTimer = SetTimer(hMainWnd,1,100,NULL);
                if(idTimer==0)
                  {MsgBox((LPSTR)"No timers remaining !");
                   break;
                  }
                break;

        case WM_TIMER:
                // fatal error ?
                if(FatalFlag) break;
                if(!OnLineFlag) break;
                // fetch line of up to 'TEMP_SIZE' chars
                Count = SioGets(ThePort, (LPSTR)Temp, TEMP_SIZE);
                if(Count>0) p.WriteTheString(Temp,Count);

             break;

        case WM_CHAR:
               if(!OnLineFlag) break;
               // send the character
               SioPutc(ThePort, (char)wParam);
               break;

        case WM_PAINT:
               HideCaret(hMainWnd);
               hDC = BeginPaint(hMainWnd, &ps);
               SetMapMode(hDC,MM_ANISOTROPIC);
               SelectObject(hDC, GetStockObject(OEM_FIXED_FONT) );
               p.PaintMain(hDC,&ps);
               EndPaint(hMainWnd,&ps);
               SetCaretPos(p.PaintGetColPos(),p.PaintGetRowPos());
               ShowCaret(hMainWnd);
               break;

        case WM_DESTROY:
                PostQuitMessage(0);
                break;
        default:
                return DefWindowProc(hWnd, message, wParam, lParam);
        }
        return 0;
}

// Message handler for about box.
LRESULT CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
        switch (message)
        {
        case WM_INITDIALOG:
                return TRUE;

        case WM_COMMAND:
                if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
                {
                        EndDialog(hDlg, LOWORD(wParam));
                        return TRUE;
                }
                break;
        }
        return FALSE;
}
