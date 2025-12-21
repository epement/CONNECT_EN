/*
        CN_NT (Clipboard support for DOS programmes running in NT's VDM.)
        CN_NT.DLL (Win32 DLL part.)
        CN_NT.CPP (Main module.)
*/


#define WINVER 0x0400
#define STRICT

#include <windows.h>
#include <windowsx.h>
#include <string.h>
#include "ntvdm.h"
#include "exec.h"
#include "recycle.h"
#include "sysinfo.h"
#include "ExAttr.h"

bool clip_open;

DWORD CtrlType;
DWORD CtrlCntr = 0;

int dwChangeHandles[2] = {-1, -1};



/*
        CN_NT_InitVDD:
        Called by our TSR at initialization.
*/
extern "C" void __export WINAPI CN_NT_InitVDD(void)
{
  return;
}

/*
        AL = 00h
        Installation Check
*/

void cn_nt_installcheck()
{
 setAX(0x0103);  // Windows 3.1 (lie ;-)
 return;
}

/*
        AL = 01h
        Open Clipboard
*/
void cn_nt_open_clipb()
{
 if(!clip_open)
  {
   clip_open = OpenClipboard(NULL);
   setAX(clip_open);
  }
 else setAX(0);
 return;
}

/*
        AL = 02h
        Empty Clipboard
*/
void cn_nt_clear_clipb()
{
 setAX((bool)EmptyClipboard());
 return;
}


/*
        AL = 03h
        Write to clipboard
*/
void cn_nt_write_clipb()
{
 DWORD   rm_ptr = MAKELONG(getBX(),getES());
 DWORD   size   = MAKELONG(getCX(),getSI())+1;

 HGLOBAL gmem;   // handle of global mem
 LPVOID  gptr;   // pointer to global mem
 PBYTE   srcptr; // pointer to source address (converted)

 LPSTR buf; // address of buffer for new string
 int uBufSize;

 srcptr = GetVDMPointer(rm_ptr, size, false);

 uBufSize = MultiByteToWideChar(CP_OEMCP, 0, (LPCSTR)srcptr,
                                 size+1, (LPWSTR)gptr, 0);

 gmem = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE, uBufSize*2+1);
 if(!gmem) { setAX(GetLastError()); return; };

 gptr = GlobalLock(gmem);
 if(!gptr) { setAX(GetLastError()); GlobalFree(gmem); return; };

 MultiByteToWideChar(CP_OEMCP, 0, (LPCSTR)srcptr,
                             size+1, (LPWSTR)gptr, uBufSize+1);

 FreeVDMPointer(rm_ptr, size, srcptr, false );

 GlobalUnlock(gptr);


 setAX((bool)SetClipboardData(CF_UNICODETEXT, gmem));
 return;
}

/*
        AL = 04h
        Close Clipboard
*/



void cn_nt_read_clipb_size()
{

 DWORD   size;
 HANDLE  gmem;

 gmem = GetClipboardData(CF_UNICODETEXT);

 size = gmem ? GlobalSize(gmem) : 0;

 size /= 2;

 setAX(LOWORD(size));
 setDX(HIWORD(size));

 return;
}

/*
        AL = 05h
        Read clipboard
*/
void cn_nt_read_clipb()
{
 DWORD   rm_ptr = MAKELONG(getBX(),getES());

 HANDLE  gmem;
 LPVOID  gptr;
 DWORD   size;
 int     BufType;
 int     usize;
 PBYTE   destptr;

 gmem = GetClipboardData(CF_UNICODETEXT);
 if(!gmem)
  {
   setAX(false);
   return;
  };

 size = GlobalSize(gmem)/2;

 gptr = GlobalLock(gmem);
 if(!gptr)
  {
   setAX(false);
   return;
  };

 destptr = GetVDMPointer(rm_ptr, size, false);


 usize = WideCharToMultiByte(CP_OEMCP, 0, (LPCWSTR)gptr, -1,
                             (LPSTR)destptr, 0, NULL, NULL);

 WideCharToMultiByte(CP_OEMCP, 0, (LPCWSTR)gptr, -1,
                     (LPSTR)destptr, usize, NULL, NULL);
 FreeVDMPointer(rm_ptr, size, destptr, false );

 GlobalUnlock(gptr);

 setAX(true);

 return;
}

/*
        AL = 08h
        Close Clipboard
*/
void cn_nt_close_clipb()
{
 bool succ;

 if(clip_open)
 {
  succ = CloseClipboard();
  clip_open = !succ;
  setAX(succ);
 }
 else setAX(0);

 return;
}

/*
        AL = 09h
        Don't know exactly what this does.
        Maybe for compatibility with older real mode Windows versions?
        Simply return requested size free memory. (1MB)
*/
void cn_nt_compact_clipb()
{
 setAX(getCS());
 setDX(getSI());
 return;
}


/*
        AL = 0Ah
        Don't know exactly what this is supposed to do.
        Just return nothing and pray noone calls it. ;-)
*/
void cn_nt_get_dev_caps()
{
 return;
}

/*
        AL = 0Fh
        Get Cosole control
*/

void cn_nt_GetConCtl()
{
 setAX(CtrlType%0x10000);
 setBX(CtrlType/0x10000);
 if (CtrlType != 0) CtrlCntr++;
 if (CtrlCntr == 10)
  {
   CtrlCntr = CtrlType = 0;
   Beep(1000, 50);
  }
 return;
}

/*
        AL = 10h
        Additional Installation Check
*/
void cn_nt_add_installcheck()
{
 setAX(0x1117);
 return;
}

/*
        AL = 11h
        GetDiskFreeSpace
*/

void cn_nt_GetDiskFreeSpace()
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 DWORD SectorsPerCluster = 0;        //  sectors per cluster
 DWORD BytesPerSector = 0;           //  bytes per sector
 DWORD NumberOfFreeClusters = 0;     //  number of free clusters
 DWORD TotalNumberOfClusters = 0;    //  total number of clusters
 PBYTE srcptr;

 srcptr = GetVDMPointer(rm_ptr, 0, false);

 (void)GetDiskFreeSpace((LPCTSTR)srcptr,
                    &SectorsPerCluster,    // address of sectors per cluster
                    &BytesPerSector,       // address of bytes per sector
                    &NumberOfFreeClusters, // address of number of free clusters
                    &TotalNumberOfClusters // address of total number of clusters
                  );
 FreeVDMPointer(rm_ptr, 0, srcptr, false );

 setAX((SectorsPerCluster));
 setBX(BytesPerSector);
 setCX(NumberOfFreeClusters%0x10000);
 setDX(NumberOfFreeClusters/0x10000);
 setSI(TotalNumberOfClusters%0x10000);
 setBP(TotalNumberOfClusters/0x10000);
 return;
}

/*
        AL = 12h
        GetDriveType
*/

void cn_nt_GetDriveType()
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 PBYTE srcptr;
 UINT DriveType;

 srcptr = GetVDMPointer(rm_ptr, 0, false);

 DriveType = GetDriveType((LPCTSTR)srcptr);
 FreeVDMPointer(rm_ptr, 0, srcptr, false);

 setAX(DriveType);
 return;
}

/*
        AL = 13h
        GetLogicalDrives
*/

void cn_nt_GetLogicalDrives()
{
 DWORD Drives;

 Drives = GetLogicalDrives();

 setAX(Drives%0x10000);
 setBX(Drives/0x10000);
 return;
}

/*
        AL = 14h
        GetDiskFreeSpace
*/

void cn_nt_GetCompressedFileSize()
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 DWORD CompSize = 0;
 DWORD FileSize;
 PBYTE srcptr;
 int name_size;

 srcptr = GetVDMPointer(rm_ptr, 0, false);

 name_size = strlen((LPCSTR)srcptr);
 OemToCharBuff((LPCSTR)srcptr, (LPTSTR)srcptr, name_size);

 FileSize = GetCompressedFileSize((LPCTSTR)srcptr, &CompSize);
 FreeVDMPointer(rm_ptr, 0, srcptr, false );

 setAX(FileSize%0x10000);
 setBX(FileSize/0x10000);
 setCX(CompSize%0x10000);
 setDX(CompSize/0x10000);
 return;
}

/*
        AL = 15h
        ExecNT
*/

void cn_nt_ExecNT()
{
 DWORD rm_ptr_cmd =   MAKELONG(getBX(),getES());
 DWORD rm_ptr_redir = MAKELONG(getCX(),getDS());
 DWORD flags = getDX() + getSI() << 16;
 DWORD opt = getBP();
 PBYTE cmd_cptr;
 PBYTE redir_cptr;
 DWORD Result;

 cmd_cptr = GetVDMPointer(rm_ptr_cmd, 0, false);
 redir_cptr = GetVDMPointer(rm_ptr_redir, 0, false);

 Result = Exec((LPCSTR)cmd_cptr, (LPCSTR)redir_cptr, flags, opt);

 FreeVDMPointer(rm_ptr_cmd, 0, cmd_cptr, false );
 FreeVDMPointer(rm_ptr_redir, 0, redir_cptr, false );

 setAX(Result%0x10000);
 setBX(Result/0x10000);
 return;
}


/*
        AL = 16h
        DelToTrash
*/

void cn_nt_DelToTrash()
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 BOOL Result;
 PBYTE srcptr;
 int name_size;

 srcptr = GetVDMPointer(rm_ptr, 0, false);

 name_size = strlen((LPCSTR)srcptr);
 OemToCharBuff((LPCSTR)srcptr, (LPTSTR)srcptr, name_size);

 Result = DelToTrash((char *)srcptr);
 FreeVDMPointer(rm_ptr, 0, srcptr, false );

 setAX(Result);
 return;
}

/*
        AL = 17h
        EmptyTrash
*/

void cn_nt_EmptyTrash()
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 BOOL Result;
 PBYTE srcptr;
 int name_size;

 srcptr = GetVDMPointer(rm_ptr, 0, false);

 name_size = strlen((LPCSTR)srcptr);
 OemToCharBuff((LPCSTR)srcptr, (LPTSTR)srcptr, name_size);

 Result = EmptyTrash((char *)srcptr);
 FreeVDMPointer(rm_ptr, 0, srcptr, false );

 setAX(Result);
 return;
}

void cn_nt_SysInfo()
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 PBYTE srcptr;
 int name_size;

 srcptr = GetVDMPointer(rm_ptr, 0, false);

 asysinfo(srcptr);
 FreeVDMPointer(rm_ptr, 0, srcptr, false );

 return;
}

void cn_nt_GetVolumeLabel()
{
 DWORD rm_ptr_Root = MAKELONG(getBX(),getES());
 DWORD rm_ptr_Label = MAKELONG(getCX(),getDS());

 PBYTE cptr_Root;
 PBYTE cptr_Label;
 BOOL Result;
 int name_size;

 DWORD VolumeSerialNumber;
 DWORD FileNameLen;
 DWORD FileSystemFlags;
 char  FS[8];

 cptr_Root = GetVDMPointer(rm_ptr_Root, 0, false);
  if (rm_ptr_Label != 0)
   {
    cptr_Label = GetVDMPointer(rm_ptr_Label, 0, false);
    name_size = 32;
   }
  else
   {
    cptr_Label = NULL;
    name_size = 0;
   }
 Result = GetVolumeInformation((LPCTSTR)cptr_Root,
                               (LPTSTR)cptr_Label,
                               name_size,
                               &VolumeSerialNumber,
                               &FileNameLen,
                               &FileSystemFlags,
                               FS,
                               8);
 name_size = strlen((LPCSTR)cptr_Label);
 CharToOemBuff((LPCSTR)cptr_Label, (LPTSTR)cptr_Label, name_size);
 FreeVDMPointer(rm_ptr_Root, 0, cptr_Root, false );
 FreeVDMPointer(rm_ptr_Label, 0, cptr_Label, false );

 setCX(VolumeSerialNumber%0x10000);
 setBX(VolumeSerialNumber/0x10000);
 setDX(FileSystemFlags%0x10000);
 setSI(FileSystemFlags/0x10000);

 setAX(Result);
 return;
}


void cn_nt_SetVolumeLabel()
{
 DWORD rm_ptr_Root = MAKELONG(getBX(),getES());
 DWORD rm_ptr_Label = MAKELONG(getCX(),getDS());

 PBYTE cptr_Root;
 PBYTE cptr_Label;
 BOOL Result;
 int name_size;

 cptr_Root = GetVDMPointer(rm_ptr_Root, 0, false);
 cptr_Label = GetVDMPointer(rm_ptr_Label, 0, false);

 name_size = strlen((LPCSTR)cptr_Label);
 OemToCharBuff((LPCSTR)cptr_Label, (LPTSTR)cptr_Label, name_size);

 Result = SetVolumeLabel((LPCTSTR)cptr_Root, (LPCTSTR)cptr_Label);
 FreeVDMPointer(rm_ptr_Root, 0, cptr_Root, false );
 FreeVDMPointer(rm_ptr_Label, 0, cptr_Label, false );

 setAX(Result);
 return;
}

void cn_nt_SetTitle()
{
 DWORD rm_ptr_Title = MAKELONG(getBX(),getES());

 PBYTE cptr_Title;
 BOOL Result;

 cptr_Title = GetVDMPointer(rm_ptr_Title, 0, false);

 Result = SetConsoleTitle((LPCTSTR)cptr_Title);
 FreeVDMPointer(rm_ptr_Title, 0, cptr_Title, false );

 setAX(Result);
 return;
}

void cn_nt_SetFAttr()
{
 DWORD rm_ptr_fName = MAKELONG(getBX(),getES());
 DWORD fAttr = MAKELONG(getCX(),getDX());

 PBYTE cptr_fName;

 BOOL Result;
 int name_size;

 cptr_fName= GetVDMPointer(rm_ptr_fName, 0, false);

 name_size = strlen((LPCSTR)cptr_fName);
 OemToCharBuff((LPCSTR)cptr_fName, (LPTSTR)cptr_fName, name_size);

 Result = SetFAttr((LPTSTR)cptr_fName, fAttr);
 FreeVDMPointer(rm_ptr_fName, 0, cptr_fName, false );

 setAX(Result);
 return;
}

void cn_nt_GetFAttr()
{
 DWORD rm_ptr_fName = MAKELONG(getBX(),getES());
 DWORD fAttr;

 PBYTE cptr_fName;
 int name_size;

 cptr_fName= GetVDMPointer(rm_ptr_fName, 0, false);

 name_size = strlen((LPCSTR)cptr_fName);
 OemToCharBuff((LPCSTR)cptr_fName, (LPTSTR)cptr_fName, name_size);

 fAttr = GetFileAttributes((LPCTSTR)cptr_fName);
 FreeVDMPointer(rm_ptr_fName, 0, cptr_fName, false );

 setAX(fAttr%0x10000);
 setBX(fAttr/0x10000);
 return;
}

void cn_nt_SetFTime()
{
 DWORD rm_ptr_fName = MAKELONG(getBX(),getES());
 DWORD fTimeLow = MAKELONG(getCX(),getDX());
 DWORD fTimeHigh = MAKELONG(getSI(),getBP());
 DWORD tTime = getDS();
 PBYTE cptr_fName;

 BOOL Result;
 int name_size;

 cptr_fName= GetVDMPointer(rm_ptr_fName, 0, false);

 name_size = strlen((LPCSTR)cptr_fName);
 OemToCharBuff((LPCSTR)cptr_fName, (LPTSTR)cptr_fName, name_size);

 Result = SetFTime((LPTSTR)cptr_fName, fTimeLow, fTimeHigh, tTime);
 FreeVDMPointer(rm_ptr_fName, 0, cptr_fName, false );

 setAX(Result);
 return;
}

void cn_nt_GetFTime()
{
 DWORD rm_ptr_fName = MAKELONG(getBX(),getES());
 DWORD fTimeLow;
 DWORD fTimeHigh;
 DWORD tTime = getDS();
 BOOL Result;

 PBYTE cptr_fName;
 int name_size;

 cptr_fName= GetVDMPointer(rm_ptr_fName, 0, false);

 name_size = strlen((LPCSTR)cptr_fName);
 OemToCharBuff((LPCSTR)cptr_fName, (LPTSTR)cptr_fName, name_size);

 Result = GetFTime((LPTSTR)cptr_fName, &fTimeLow, &fTimeHigh, tTime);
 FreeVDMPointer(rm_ptr_fName, 0, cptr_fName, false );

 setCX(fTimeLow%0x10000);
 setDX(fTimeLow/0x10000);
 setSI(fTimeHigh%0x10000);
 setBP(fTimeHigh/0x10000);
 setAX(Result);
 return;
}

void cn_nt_DirsCheck()
{
 DWORD rm_ptr_Dir0 =   MAKELONG(getBX(),getES());
 DWORD rm_ptr_Dir1 = MAKELONG(getCX(),getDS());
 DWORD op = getDX();
 PBYTE cptr_Dir0;
 PBYTE cptr_Dir1;
 DWORD Result = 0;
 int name_size;

 switch (op)
  {
   case 0: /*  Set directory */
     if (dwChangeHandles[0] != -1)
       FindCloseChangeNotification((HANDLE)dwChangeHandles[0]);
     if (dwChangeHandles[1] != -1)
       FindCloseChangeNotification((HANDLE)dwChangeHandles[1]);
     dwChangeHandles[0] = dwChangeHandles[1] = -1;

     cptr_Dir0 = GetVDMPointer(rm_ptr_Dir0, 0, false);
     cptr_Dir1 = GetVDMPointer(rm_ptr_Dir1, 0, false);

     name_size = strlen((LPCSTR)cptr_Dir0);
     OemToCharBuff((LPCSTR)cptr_Dir0, (LPTSTR)cptr_Dir0, name_size);

     name_size = strlen((LPCSTR)cptr_Dir1);
     OemToCharBuff((LPCSTR)cptr_Dir1, (LPTSTR)cptr_Dir1, name_size);

     if ((cptr_Dir0 != NULL) && (*cptr_Dir0 != 0))
      dwChangeHandles[0] = (DWORD)FindFirstChangeNotification(
         cptr_Dir0,      // directory to watch
         FALSE,          // do not watch subtree
         0x1ff);         // watch all changes

     if ((cptr_Dir0 != NULL) && (*cptr_Dir0 != 0))
      dwChangeHandles[1] = (DWORD)FindFirstChangeNotification(
         cptr_Dir1,      // directory to watch
         FALSE,          // do not watch subtree
         0x1ff);         // watch all changes

     FreeVDMPointer(rm_ptr_Dir0, 0, cptr_Dir0, false);
     FreeVDMPointer(rm_ptr_Dir1, 0, cptr_Dir1, false);
   break;
   case 1: // Check directory
     if (WaitForMultipleObjects(
          1,
          &((HANDLE)dwChangeHandles[0]),
          FALSE,
          0) == WAIT_OBJECT_0)
      {
        Result |= 1;
        FindNextChangeNotification((HANDLE)dwChangeHandles[0]);
      }
     if (WaitForMultipleObjects(
          1,
          &((HANDLE)dwChangeHandles[1]),
          FALSE,
          0) == WAIT_OBJECT_0)
      {
        Result |= 2;
        FindNextChangeNotification((HANDLE)dwChangeHandles[1]);
      }
   break;
   case 2: // Close handles
     if (dwChangeHandles[0] != -1)
       FindCloseChangeNotification((HANDLE)dwChangeHandles[0]);
     if (dwChangeHandles[1] != -1)
       FindCloseChangeNotification((HANDLE)dwChangeHandles[1]);
     dwChangeHandles[0] = dwChangeHandles[1] = -1;
   break;
  }
 setAX(Result);
 return;
}

/*
function SetDirCheck(Dir: String): Longint; {Handle}
function DirCheck(var Handle: Longint): Boolean;
procedure DirFree(Handle: Longint);
*/

void cn_nt_DirCheck()
{
 DWORD rm_ptr_Dir0 =   MAKELONG(getBX(),getES());
 int dirHandle = MAKELONG(getCX(),getDX());
 DWORD op = getSI();
 PBYTE cptr_Dir0;
 DWORD Result = 0;
 int name_size;

 switch (op)
  {
   case 0: /*  Set directory */

     cptr_Dir0 = GetVDMPointer(rm_ptr_Dir0, 0, false);

     name_size = strlen((LPCSTR)cptr_Dir0);
     OemToCharBuff((LPCSTR)cptr_Dir0, (LPTSTR)cptr_Dir0, name_size);


     if ((cptr_Dir0 != NULL) && (*cptr_Dir0 != 0))
      dirHandle = (DWORD)FindFirstChangeNotification(
         cptr_Dir0,      // directory to watch
         FALSE,          // do not watch subtree
         0x1ff);         // watch all changes
     else dirHandle = -1;

     FreeVDMPointer(rm_ptr_Dir0, 0, cptr_Dir0, false);
     Result = (DWORD)(dirHandle != -1);
   break;
   case 1: // Check directory
     if (WaitForMultipleObjects(
          1,
          &((HANDLE)dirHandle),
          FALSE,
          0) == WAIT_OBJECT_0)
      {
        Result = (DWORD)TRUE;
        FindNextChangeNotification((HANDLE)dirHandle);
      }
   break;
   case 2: // Close handles
     if (dirHandle != -1)
       FindCloseChangeNotification((HANDLE)dirHandle);
     dirHandle =  -1;
   break;
  }

 setCX((DWORD)dirHandle%0x10000);
 setDX((DWORD)dirHandle/0x10000);
 setAX(Result);
 return;
}

/*      CN_NT_CallVDD:
        Called for INT 2Fh, AH=17h
*/
extern "C" void __export WINAPI CN_NT_CallVDD(void)
{
 BYTE    fnr = LOBYTE(getDI());

 switch(fnr)
 {
   case 0x00: cn_nt_installcheck();                break;
   case 0x01: cn_nt_open_clipb();                  break;
   case 0x02: cn_nt_clear_clipb();                 break;
   case 0x03: cn_nt_write_clipb();                 break;
   case 0x04: cn_nt_read_clipb_size();             break;
   case 0x05: cn_nt_read_clipb();                  break;
   case 0x08: cn_nt_close_clipb();                 break;
   case 0x09: cn_nt_compact_clipb();               break;
   case 0x0a: cn_nt_get_dev_caps();                break;
   case 0x0b:                                      break;
   case 0x0c:                                      break;
   case 0x0d: cn_nt_DirCheck();                    break;
   case 0x0e: cn_nt_DirsCheck();                   break;
   case 0x0f: cn_nt_GetConCtl();                   break;
   case 0x10: cn_nt_add_installcheck();            break;
   case 0x11: cn_nt_GetDiskFreeSpace();            break;
   case 0x12: cn_nt_GetDriveType();                break;
   case 0x13: cn_nt_GetLogicalDrives();            break;
   case 0x14: cn_nt_GetCompressedFileSize();       break;
   case 0x15: cn_nt_ExecNT();                      break;
   case 0x16: cn_nt_DelToTrash();                  break;
   case 0x17: cn_nt_EmptyTrash();                  break;
   case 0x18: cn_nt_SysInfo();                     break;
   case 0x19: cn_nt_GetVolumeLabel();              break;
   case 0x20: cn_nt_SetVolumeLabel();              break;
   case 0x21: cn_nt_SetTitle();                    break;
   case 0x22: cn_nt_SetFAttr();                    break;
   case 0x23: cn_nt_GetFAttr();                    break;
   case 0x24: cn_nt_SetFTime();                    break;
   case 0x25: cn_nt_GetFTime();                    break;
 }

 return;
}


BOOL CtrlHandler(DWORD fdwCtrlType)
{
  switch(fdwCtrlType)
  {
    // Handle the CTRL-C signal.
    case CTRL_C_EVENT:
      CtrlType = 1;
      return TRUE;

    // CTRL-CLOSE: confirm that the user wants to exit.
    case CTRL_CLOSE_EVENT:
      CtrlType = 2;
      return TRUE;

    // Pass other signals to the next handler.
    case CTRL_BREAK_EVENT:
      CtrlType = 3;
      return TRUE;

    case CTRL_LOGOFF_EVENT:
      CtrlType = 4;
      return TRUE;

    case CTRL_SHUTDOWN_EVENT:
      CtrlType = 5;
      return TRUE;

    default:
      return FALSE;
  }
}


/*
        CN_NT_process_attach:
        Called at DLL initialization.
*/

bool CN_NT_process_attach(HINSTANCE hdll)
{
 clip_open = false;

 SetConsoleCtrlHandler((PHANDLER_ROUTINE) CtrlHandler, TRUE);

 return true;
}

/*
        CN_NT_process_detach:
        Called at DLL desinitialization.
        Free NTVDM I/O hooks.
*/
bool CN_NT_process_detach(HINSTANCE hdll)
{
 if (clip_open) CloseClipboard();

 SetConsoleCtrlHandler((PHANDLER_ROUTINE) CtrlHandler, FALSE);

 if (dwChangeHandles[0] != -1)
   FindCloseChangeNotification((HANDLE)dwChangeHandles[0]);
 if (dwChangeHandles[1] != -1)
   FindCloseChangeNotification((HANDLE)dwChangeHandles[1]);
 dwChangeHandles[0] = dwChangeHandles[1] = -1;

 return true;
}

/*
        DllEntryPoint:
        Win32 standard DLL entry point.
*/
extern "C"
BOOL WINAPI DllEntryPoint(
        HINSTANCE hdll,         // handle to DLL module
        DWORD fdwReason,        // reason for calling function
        LPVOID)                 // reserved
{
 struct {
         DWORD event;
         bool(* entry)(HINSTANCE hdll);
        } inittable[] =
  {
    {DLL_PROCESS_ATTACH, CN_NT_process_attach},
    {DLL_PROCESS_DETACH, CN_NT_process_detach}
  };

 for (int x = 0; x < sizeof inittable /sizeof inittable[0]; x++)
  if (inittable[x].event == fdwReason)
   return inittable[x].entry(hdll);
 return true;
}
