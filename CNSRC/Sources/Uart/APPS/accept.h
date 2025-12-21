#ifdef WIN32
BOOL CALLBACK
#else
BOOL FAR PASCAL
#endif
AcceptDlgProc(HWND, UINT, WPARAM, LPARAM);

int GetAcceptText(LPSTR);

#define IDD_EDIT 100
  