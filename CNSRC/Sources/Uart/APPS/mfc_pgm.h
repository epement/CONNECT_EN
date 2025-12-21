// mfc_pgm.h : Declares the class interfaces for the application.
//             MFC_PGM is intended as a simple example of the use of
//             the Microsoft Foundation Class (MFC) library.
//

#define NROWS 20

// CMainWindow

class CMainWindow : public CFrameWnd
{
 public:
   CMainWindow();
   void PgmExit(void);
   void GoOnLine(void);
   void GoOffLine(void);
   void SetCOM1(void);
   void SetCOM2(void);
   void SetCOM3(void);
   void SetCOM4(void);
   void Set2400(void);
   void Set9600(void);
   void Set19200(void);
   void Set38400(void);
   void Set57600(void);
   void DisplayChar(int);
   void DisplayLine(CString);
   void CheckOneItem(UINT,UINT,UINT);
 protected:
   //CWnd * MainWndPtr;
   UINT TimerID;
   int  ThePort;
   int  TheBaud;
   int  OnLineFlag;
   int  InvalidateFlag;
   int  TheRow;
   CString Buffer[NROWS];
   afx_msg void OnPaint();
   //afx_msg void OnAbout();
   afx_msg void OnTimer(UINT);
   afx_msg void OnChar(UINT,UINT,UINT);
   //}}AFX_MSG
   DECLARE_MESSAGE_MAP()
};

class CTheApp : public CWinApp
{
 public:
   BOOL InitInstance();
};

