//
//   mfc_pgm.cpp
//
//   MFC_PGM is intended as a simple example of the use of
//   the Microsoft Foundation Class (MFC) library with the
//   Windows Standard Serial Comm Library for C/C++ (WSC4C)
//
//   File NAFXCW.LIB may have to be copied from MFC\LIB on
//   your Microsoft Visual C/C++ CD disk.

#include "stdafx.h"
#include "resource.h"

#include "wsc.h"
#include "mfc_pgm.h"
#include "keycode.h"

static CWnd * MainWndPtr;

// Display character on screen

void CMainWindow::DisplayChar(int nChar)
{int Row;
 // process the character
 if(nChar==10) return;
 if(nChar==13)
   {if(TheRow<NROWS-1) TheRow++;
    else
      {// scroll page (TheRow==NROWS-1)
       for(Row=0;Row<=NROWS-2;Row++) Buffer[Row] = Buffer[Row+1];
       Buffer[NROWS-1].Empty();
       TheRow = NROWS-1;
      }
   }
 else
   {// stuff character into display buffer
    Buffer[TheRow] += (char)nChar;
   }
}

// Display string on screen

void CMainWindow::DisplayLine(CString Text)
{
 Buffer[TheRow] += Text;
 DisplayChar(13);
 InvalidateFlag = TRUE;
 MainWndPtr->UpdateWindow();
}

// Check one item, unchecking all else

void CMainWindow::CheckOneItem(UINT FirstID, UINT LastID, UINT CheckID)
{UINT i;
 CMenu *pMenu;
 pMenu = MainWndPtr->GetMenu();
 for(i=FirstID;i<=LastID;i++)
   if(i!=CheckID) pMenu->CheckMenuItem(i, MF_BYCOMMAND|MF_UNCHECKED);
 pMenu->CheckMenuItem(CheckID, MF_BYCOMMAND|MF_CHECKED);
}

// CMainWindow message map

BEGIN_MESSAGE_MAP( CMainWindow, CFrameWnd )
   //{{AFX_MSG_MAP( CMainWindow )
   ON_WM_PAINT()
   ON_WM_TIMER()
   ON_WM_CHAR()
   ON_COMMAND(ID_LINE_EXIT,    PgmExit)
   ON_COMMAND(ID_LINE_ONLINE,  GoOnLine)
   ON_COMMAND(ID_LINE_OFFLINE, GoOffLine)
   ON_COMMAND(ID_LINE_EXIT,    PgmExit)
   ON_COMMAND(ID_PORT_COM1,  SetCOM1)
   ON_COMMAND(ID_PORT_COM2,  SetCOM2)
   ON_COMMAND(ID_PORT_COM3,  SetCOM3)
   ON_COMMAND(ID_PORT_COM4,  SetCOM4)
   ON_COMMAND(ID_BAUD_2400,  Set2400)
   ON_COMMAND(ID_BAUD_9600,  Set9600)
   ON_COMMAND(ID_BAUD_19200, Set19200)
   ON_COMMAND(ID_BAUD_38400, Set38400)
   ON_COMMAND(ID_BAUD_57600, Set57600)
   //}}AFX_MSG_MAP
END_MESSAGE_MAP()

CTheApp NEAR theApp;

// PgmExit: Exits application

void CMainWindow::PgmExit(void)
{// Close serial port
 SioDone(ThePort);
 PostQuitMessage(0);
}

// SetCOM1: Selects COM1
void CMainWindow::SetCOM1(void)
{
 ThePort = COM1;
 CheckOneItem(ID_PORT_COM1, ID_PORT_COM4, ID_PORT_COM1);
}

// SetCOM2: select COM2

void CMainWindow::SetCOM2(void)
{
 ThePort = COM2;
 CheckOneItem(ID_PORT_COM1, ID_PORT_COM4, ID_PORT_COM2);
}

// SetCOM3: Selects COM3

void CMainWindow::SetCOM3(void)
{
 ThePort = COM3;
 CheckOneItem(ID_PORT_COM1, ID_PORT_COM4, ID_PORT_COM3);
}

// SetCOM4: Selects COM4

void CMainWindow::SetCOM4(void)
{
 ThePort = COM4;
 CheckOneItem(ID_PORT_COM1, ID_PORT_COM4, ID_PORT_COM4);
}

// Set2400: Selects 2400 baud

void CMainWindow::Set2400(void)
{
 TheBaud = WSC_Baud2400;
 CheckOneItem(ID_BAUD_300, ID_BAUD_57600, ID_BAUD_2400);
}

// Set9600: Selects 4800 baud

void CMainWindow::Set9600(void)
{
 TheBaud = WSC_Baud9600;
 CheckOneItem(ID_BAUD_300, ID_BAUD_57600, ID_BAUD_9600);
}

// Set19200: Selects 19200 baud

void CMainWindow::Set19200(void)
{
 TheBaud = WSC_Baud19200;
 CheckOneItem(ID_BAUD_300, ID_BAUD_57600, ID_BAUD_19200);
}

// Set38400: Selects 38400 baud

void CMainWindow::Set38400(void)
{
 TheBaud = WSC_Baud38400;
 CheckOneItem(ID_BAUD_300, ID_BAUD_57600, ID_BAUD_38400);
}

// Set57600: Selects 57600 baud

void CMainWindow::Set57600(void)
{
 TheBaud = WSC_Baud57600;
 CheckOneItem(ID_BAUD_300, ID_BAUD_57600, ID_BAUD_57600);
}

// GoOnLine: Reset port & set baud rate

void CMainWindow::GoOnLine(void)
{// Open serial port
 CMenu *pMenu;
 DisplayLine("Going online . . .");
 pMenu = MainWndPtr->GetMenu();
 pMenu->CheckMenuItem(ID_LINE_OFFLINE, MF_BYCOMMAND|MF_UNCHECKED);
 pMenu->CheckMenuItem(ID_LINE_ONLINE,  MF_BYCOMMAND|MF_CHECKED);
 pMenu->EnableMenuItem(ID_LINE_ONLINE, MF_BYCOMMAND|MF_GRAYED);
 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
    DisplayLine("ERROR: Bad Key Code!");
 else
   {SioReset(ThePort,2048,512);
    SioBaud(ThePort,TheBaud);
    SioDTR(ThePort,'S');
    SioRTS(ThePort,'S');
    OnLineFlag = TRUE;
   }
}

// GoOffLine: Close port

void CMainWindow::GoOffLine(void)
{// Close serial port
 CMenu *pMenu;
 pMenu = MainWndPtr->GetMenu();
 DisplayLine("Shutting down port");
 pMenu->CheckMenuItem(ID_LINE_ONLINE,  MF_BYCOMMAND|MF_UNCHECKED);
 pMenu->CheckMenuItem(ID_LINE_OFFLINE, MF_BYCOMMAND|MF_CHECKED);
 pMenu->EnableMenuItem(ID_LINE_ONLINE, MF_BYCOMMAND|MF_ENABLED);
 SioDone(ThePort);
 OnLineFlag = FALSE;
}

// CMainWindow: constructor

CMainWindow::CMainWindow()
{int Row;
 CString s = "WSC Test";
 LoadAccelTable( "MainAccelTable" );
 Create( NULL, "MFC Example Program",
      WS_OVERLAPPEDWINDOW, rectDefault, NULL, "MainMenu" );
 ThePort = COM1;
 TheBaud = WSC_Baud38400;
 OnLineFlag = FALSE;
 for(Row=0;Row<NROWS;Row++) Buffer[Row].Empty();
 TheRow = 0;
 InvalidateFlag = TRUE;
 // start timer
 TimerID = SetTimer(1,100,NULL);
}

// OnChar: Copy keyboard char to (serial out)

void CMainWindow::OnChar(UINT nChar, UINT nRepeat, UINT nFlags)
{
 if(OnLineFlag)
   {SioPutc(ThePort,nChar);
    InvalidateFlag = TRUE;
   }
}

// OnTimer: Grab all available incoming chars

void CMainWindow::OnTimer(UINT nTimerID)
{int i, Code;
 if(InvalidateFlag)
   {Invalidate(TRUE);
    MainWndPtr->UpdateWindow();
    InvalidateFlag = FALSE;
   }
 if(!OnLineFlag) return;
 for(i=0;i<512;i++)
   {Code = SioGetc(ThePort);
    if(Code<0) break;
    DisplayChar(Code);
   }
 if(i>0)
   {Invalidate(TRUE);
    MainWndPtr->UpdateWindow();
   }
}

// OnPaint:

void CMainWindow::OnPaint()
{int Row;
 CPaintDC dc( this );
 CRect rect;
 GetClientRect( rect );
 dc.SetTextAlign( TA_BASELINE | TA_LEFT );
 dc.SetTextColor( ::GetSysColor( COLOR_WINDOWTEXT ) );
 dc.SetBkMode(TRANSPARENT);
 dc.SelectStockObject(ANSI_FIXED_FONT);
 for(Row=0;Row<=TheRow;Row++)
   {// display the row
    dc.TextOut( 4, 16+(Row<<4), Buffer[Row], Buffer[Row].GetLength() );
   }
}

// InitInstance:

BOOL CTheApp::InitInstance()
{SetDialogBkColor(); //hook gray dialogs
 m_pMainWnd = new CMainWindow();
 m_pMainWnd->ShowWindow( m_nCmdShow );
 m_pMainWnd->UpdateWindow();
 MainWndPtr = m_pMainWnd;
 return TRUE;
}
