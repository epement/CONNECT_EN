// about.c

#include <windows.h>
#include "about.h"

#ifdef WIN32
BOOL CALLBACK
#else
BOOL FAR PASCAL
#endif
AboutDlgProc(HWND hDlg, UINT iMsg, WPARAM wParam, LPARAM lParam)
{
 switch (iMsg)
    {
     case WM_INITDIALOG:
         return (TRUE);

     case WM_COMMAND:
         if (wParam == IDOK || wParam == IDCANCEL)
           {EndDialog(hDlg, TRUE);
            return (TRUE);
           }
         break;
    }
    return (FALSE);
} // end AboutDlgProc

