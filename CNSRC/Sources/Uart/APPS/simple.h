/* simple.h */

#ifdef WIN32
int WINAPI
#else
int PASCAL
#endif
WinMain(USE_INS, USE_INS, USE_PTR, int);

#ifdef WIN32
LRESULT CALLBACK
#else
long FAR PASCAL
#endif
MainWndProc(HWND, UINT, WPARAM, LPARAM );
  