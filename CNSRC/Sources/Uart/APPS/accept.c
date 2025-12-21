// accept.c

#include <windows.h>
#include "accept.h"

#define TEXT_SIZE 50

static char TextEditBuf[TEXT_SIZE] = {"\0"};

static void MsgBox(LPSTR Ptr)
{
 MessageBox(NULL,Ptr,(LPSTR)"Info",MB_TASKMODAL|MB_ICONEXCLAMATION);
}

int GetAcceptText(LPSTR Ptr)
{if(TextEditBuf[0]=='\0') return FALSE;
 else
   {lstrcpy((LPSTR)Ptr,(LPSTR)TextEditBuf);
    TextEditBuf[0] = '\0';
    return TRUE;
   }
}

#ifdef WIN32
BOOL CALLBACK
#else
BOOL FAR PASCAL
#endif
AcceptDlgProc(HWND hDlg, UINT iMsg, WPARAM wParam, LPARAM lParam)
{switch (iMsg)
    {case WM_INITDIALOG:
         if(lParam==0) SetWindowText(hDlg,"Enter Phone #");
         if(lParam==1) SetWindowText(hDlg,"XMODEM file name ?");
         if(lParam==2) SetWindowText(hDlg,"YMODEM file name ?");
         if(lParam==3) SetWindowText(hDlg,"ASCII file name ?");
         return TRUE;
     case WM_COMMAND:
         switch (LOWORD(wParam))
           {case IDD_EDIT:
              GetDlgItemText(hDlg,IDD_EDIT,(LPSTR)TextEditBuf,TEXT_SIZE);
              return TRUE;
            case IDOK:
              EndDialog(hDlg, TRUE);
              return TRUE;
           }
         break;
     case WM_CLOSE:
         MsgBox((LPSTR)"Type 'Enter' key in text box to close");
         break;
     default:
         return FALSE;
    }
    return FALSE;
} // end AcceptDlgProc
