// menu.c

#include "windows.h"
#include "wsc.h"

#include "menu.h"

extern HWND hMainWnd;
extern int FatalFlag;
extern int OnLineFlag;
extern char Temp[256];

void CheckTheMenu(int MenuID)
{HMENU hMenu;
 if(MenuID)
 hMenu = GetMenu(hMainWnd);
 CheckMenuItem(hMenu,MenuID,MF_BYCOMMAND | MF_CHECKED);
}

void UncheckTheMenu(int MenuID)
{HMENU hMenu;
 hMenu = GetMenu(hMainWnd);
 CheckMenuItem(hMenu,MenuID,MF_BYCOMMAND | MF_UNCHECKED);
}

void EnableTheMenu(int MenuID)
{HMENU hMenu;
 hMenu = GetMenu(hMainWnd);
 EnableMenuItem(hMenu,MenuID,MF_BYCOMMAND | MF_ENABLED);
}

void DisableTheMenu(int MenuID)
{HMENU hMenu;
 hMenu = GetMenu(hMainWnd);
 EnableMenuItem(hMenu,MenuID,MF_BYCOMMAND | MF_DISABLED | MF_GRAYED);
}

void EnableMenuBarItem(int nPos)
{HMENU hMenu;
 hMenu = GetMenu(hMainWnd);
 EnableMenuItem(hMenu,nPos,MF_BYPOSITION | MF_ENABLED);
}

void DisableMenuBarItem(int nPos)
{HMENU hMenu;
 hMenu = GetMenu(hMainWnd);
 EnableMenuItem(hMenu,nPos,MF_BYPOSITION | MF_DISABLED | MF_GRAYED);
}


