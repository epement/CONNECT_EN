/*
        CN_NT (Clipboard support for DOS programmes running in NT's VDM.)
        CN_NT.DLL (Win32 DLL part.)
        CN_NT.CPP (Main module.)
*/


#define WINVER 0x0400
#define STRICT
#pragma warn -8057
#include <windows.h>
#include <windowsx.h>
#include <string.h>
#include <Shellapi.h>
#include "ntvdm.h"
#include "exec.h"
#include "recycle.h"
#include "sysinfo.h"
#include "ExAttr.h"
#include "comm.h"

BOOL clip_open;

DWORD CtrlType;
DWORD CtrlCntr = 0;


/*
        CN_NT_InitVDD:
        Called by our TSR at initialization.
*/
extern void __export WINAPI CN_NT_InitVDD(void)
{
  return;
}

/*
        AL = 00h
        Installation Check
*/

void cn_nt_installcheck(void)
{
 setAX(0x0103);  // Windows 3.1 (lie ;-)
 return;
}

/*
        AL = 01h
        Open Clipboard
*/
void cn_nt_open_clipb(void)
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
void cn_nt_clear_clipb(void)
{
 setAX((BOOL)EmptyClipboard());
 return;
}


/*
        AL = 03h
        Write to clipboard
*/
void cn_nt_write_clipb(void)
{
 DWORD   rm_ptr = MAKELONG(getBX(),getES());
 DWORD   size   = MAKELONG(getCX(),getSI())+1;

 HGLOBAL gmem;   // handle of global mem
 LPVOID  gptr;   // pointer to global mem
 PBYTE   srcptr; // pointer to source address (converted)

 LPSTR buf; // address of buffer for new string
 int uBufSize;

 srcptr = GetVDMPointer(rm_ptr, size, FALSE);

 uBufSize = MultiByteToWideChar(CP_OEMCP, 0, (LPCSTR)srcptr,
                                 size+1, (LPWSTR)gptr, 0);

 gmem = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE, uBufSize*2+1);
 if(!gmem) { setAX(GetLastError()); return; };

 gptr = GlobalLock(gmem);
 if(!gptr) { setAX(GetLastError()); GlobalFree(gmem); return; };

 MultiByteToWideChar(CP_OEMCP, 0, (LPCSTR)srcptr,
                             size+1, (LPWSTR)gptr, uBufSize+1);

 FreeVDMPointer(rm_ptr, size, srcptr, FALSE );

 GlobalUnlock(gptr);


 setAX((BOOL)SetClipboardData(CF_UNICODETEXT, gmem));
 return;
}

/*
        AL = 04h
        Close Clipboard
*/



void cn_nt_read_clipb_size(void)
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
void cn_nt_read_clipb(void)
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
   setAX(FALSE);
   return;
  };

 size = GlobalSize(gmem)/2;

 gptr = GlobalLock(gmem);
 if(!gptr)
  {
   setAX(FALSE);
   return;
  };

 destptr = GetVDMPointer(rm_ptr, size, FALSE);


 usize = WideCharToMultiByte(CP_OEMCP, 0, (LPCWSTR)gptr, -1,
                             (LPSTR)destptr, 0, NULL, NULL);

 WideCharToMultiByte(CP_OEMCP, 0, (LPCWSTR)gptr, -1,
                     (LPSTR)destptr, usize, NULL, NULL);
 FreeVDMPointer(rm_ptr, size, destptr, FALSE );

 GlobalUnlock(gptr);

 setAX(TRUE);

 return;
}

/*
        AL = 08h
        Close Clipboard
*/
void cn_nt_close_clipb(void)
{
 BOOL succ;

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
void cn_nt_compact_clipb(void)
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
void cn_nt_get_dev_caps(void)
{
 return;
}

/*
        AL = 0Fh
        Get Cosole control
*/

void cn_nt_GetConCtl(void)
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
void cn_nt_add_installcheck(void)
{
 setAX(0x1117);
 return;
}

/*
        AL = 11h
        GetDiskFreeSpace
*/

void cn_nt_GetDiskFreeSpace(void)
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 DWORD SectorsPerCluster = 0;        //  sectors per cluster
 DWORD BytesPerSector = 0;           //  bytes per sector
 DWORD NumberOfFreeClusters = 0;     //  number of free clusters
 DWORD TotalNumberOfClusters = 0;    //  total number of clusters
 PBYTE srcptr;

 srcptr = GetVDMPointer(rm_ptr, 0, FALSE);

 (void)GetDiskFreeSpace((LPCTSTR)srcptr,
                    &SectorsPerCluster,    // address of sectors per cluster
                    &BytesPerSector,       // address of bytes per sector
                    &NumberOfFreeClusters, // address of number of free clusters
                    &TotalNumberOfClusters // address of total number of clusters
                  );
 FreeVDMPointer(rm_ptr, 0, srcptr, FALSE );

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

void cn_nt_GetDriveType(void)
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 PBYTE srcptr;
 UINT DriveType;

 srcptr = GetVDMPointer(rm_ptr, 0, FALSE);

 DriveType = GetDriveType((LPCTSTR)srcptr);
 FreeVDMPointer(rm_ptr, 0, srcptr, FALSE);

 setAX(DriveType);
 return;
}

/*
        AL = 13h
        GetLogicalDrives
*/

void cn_nt_GetLogicalDrives(void)
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

void cn_nt_GetCompressedFileSize(void)
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 DWORD CompSize = 0;
 DWORD FileSize;
 PBYTE srcptr;
 int name_size;

 srcptr = GetVDMPointer(rm_ptr, 0, FALSE);

 name_size = strlen((LPCSTR)srcptr);
 OemToCharBuff((LPCSTR)srcptr, (LPTSTR)srcptr, name_size);

 FileSize = GetCompressedFileSize((LPCTSTR)srcptr, &CompSize);
 FreeVDMPointer(rm_ptr, 0, srcptr, FALSE );

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

void cn_nt_ExecNT(void)
{
 DWORD rm_ptr_cmd =   MAKELONG(getBX(),getES());
 DWORD rm_ptr_redir = MAKELONG(getCX(),getDS());
 DWORD flags = getDX() + getSI() << 16;
 DWORD opt = getBP();
 PBYTE cmd_cptr;
 PBYTE redir_cptr;
 DWORD Result;

 cmd_cptr = GetVDMPointer(rm_ptr_cmd, 0, FALSE);
 redir_cptr = GetVDMPointer(rm_ptr_redir, 0, FALSE);

 Result = Exec((LPCSTR)cmd_cptr, (LPCSTR)redir_cptr, flags, opt);

 FreeVDMPointer(rm_ptr_cmd, 0, cmd_cptr, FALSE );
 FreeVDMPointer(rm_ptr_redir, 0, redir_cptr, FALSE );

 setAX(Result%0x10000);
 setBX(Result/0x10000);
 return;
}


/*
        AL = 16h
        DelToTrash
*/

void cn_nt_DelToTrash(void)
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 BOOL Result;
 PBYTE srcptr;
 int name_size;

 srcptr = GetVDMPointer(rm_ptr, 0, FALSE);

 name_size = strlen((LPCSTR)srcptr);
 OemToCharBuff((LPCSTR)srcptr, (LPTSTR)srcptr, name_size);

 Result = DelToTrash((char *)srcptr);
 FreeVDMPointer(rm_ptr, 0, srcptr, FALSE );

 setAX(Result);
 return;
}

/*
        AL = 17h
        EmptyTrash
*/

void cn_nt_EmptyTrash(void)
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 BOOL Result;
 PBYTE srcptr;
 int name_size;

 srcptr = GetVDMPointer(rm_ptr, 0, FALSE);

 name_size = strlen((LPCSTR)srcptr);
 OemToCharBuff((LPCSTR)srcptr, (LPTSTR)srcptr, name_size);

 Result = EmptyTrash((char *)srcptr);
 FreeVDMPointer(rm_ptr, 0, srcptr, FALSE );

 setAX(Result);
 return;
}

void cn_nt_SysInfo(void)
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 PBYTE srcptr;
 int name_size;
 DWORD CpuSpeed;

 srcptr = GetVDMPointer(rm_ptr, 0, FALSE);

 CpuSpeed = asysinfo(srcptr);
 FreeVDMPointer(rm_ptr, 0, srcptr, FALSE );

 setAX(CpuSpeed%0x10000);
 setBX(CpuSpeed/0x10000);

 return;
}

void cn_nt_ScrInfo(void)
{
 DWORD rm_ptr = MAKELONG(getBX(),getES());
 PBYTE srcptr;
 int name_size;

 srcptr = GetVDMPointer(rm_ptr, 0, FALSE);

 ScreenInfo(srcptr);
 FreeVDMPointer(rm_ptr, 0, srcptr, FALSE );

 return;
}

void cn_nt_GetVolumeLabel(void)
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

 cptr_Root = GetVDMPointer(rm_ptr_Root, 0, FALSE);
  if (rm_ptr_Label != 0)
   {
    cptr_Label = GetVDMPointer(rm_ptr_Label, 0, FALSE);
    name_size = 33;
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
 FreeVDMPointer(rm_ptr_Root, 0, cptr_Root, FALSE );
 FreeVDMPointer(rm_ptr_Label, 0, cptr_Label, FALSE );

 setCX(VolumeSerialNumber%0x10000);
 setBX(VolumeSerialNumber/0x10000);
 setDX(FileSystemFlags%0x10000);
 setSI(FileSystemFlags/0x10000);

 setAX(Result);
 return;
}


void cn_nt_SetVolumeLabel(void)
{
 DWORD rm_ptr_Root = MAKELONG(getBX(),getES());
 DWORD rm_ptr_Label = MAKELONG(getCX(),getDS());

 PBYTE cptr_Root;
 PBYTE cptr_Label;
 BOOL Result;
 int name_size;

 cptr_Root = GetVDMPointer(rm_ptr_Root, 0, FALSE);
 cptr_Label = GetVDMPointer(rm_ptr_Label, 0, FALSE);

 name_size = strlen((LPCSTR)cptr_Label);
 OemToCharBuff((LPCSTR)cptr_Label, (LPTSTR)cptr_Label, name_size);

 Result = SetVolumeLabel((LPCTSTR)cptr_Root, (LPCTSTR)cptr_Label);
 FreeVDMPointer(rm_ptr_Root, 0, cptr_Root, FALSE );
 FreeVDMPointer(rm_ptr_Label, 0, cptr_Label, FALSE );

 setAX(Result);
 return;
}

void cn_nt_SetTitle(void)
{
 DWORD rm_ptr_Title = MAKELONG(getBX(),getES());

 PBYTE cptr_Title;
 BOOL Result;

 cptr_Title = GetVDMPointer(rm_ptr_Title, 0, FALSE);

 Result = SetConsoleTitle((LPCTSTR)cptr_Title);
 FreeVDMPointer(rm_ptr_Title, 0, cptr_Title, FALSE );

 setAX(Result);
 return;
}

void cn_nt_SetFAttr(void)
{
 DWORD rm_ptr_fName = MAKELONG(getBX(),getES());
 DWORD fAttr = MAKELONG(getCX(),getDX());

 PBYTE cptr_fName;

 BOOL Result;
 int name_size;

 cptr_fName= GetVDMPointer(rm_ptr_fName, 0, FALSE);

 name_size = strlen((LPCSTR)cptr_fName);
 OemToCharBuff((LPCSTR)cptr_fName, (LPTSTR)cptr_fName, name_size);

 Result = SetFAttr((LPTSTR)cptr_fName, fAttr);
 FreeVDMPointer(rm_ptr_fName, 0, cptr_fName, FALSE );

 setAX(Result);
 return;
}

void cn_nt_GetFAttr(void)
{
 DWORD rm_ptr_fName = MAKELONG(getBX(),getES());
 DWORD fAttr;

 PBYTE cptr_fName;
 int name_size;

 cptr_fName= GetVDMPointer(rm_ptr_fName, 0, FALSE);

 name_size = strlen((LPCSTR)cptr_fName);
 OemToCharBuff((LPCSTR)cptr_fName, (LPTSTR)cptr_fName, name_size);

 fAttr = GetFileAttributes((LPCTSTR)cptr_fName);
 FreeVDMPointer(rm_ptr_fName, 0, cptr_fName, FALSE );

 setAX(fAttr%0x10000);
 setBX(fAttr/0x10000);
 return;
}

void cn_nt_SetFTime(void)
{
 DWORD rm_ptr_fName = MAKELONG(getBX(),getES());
 DWORD fTimeLow = MAKELONG(getCX(),getDX());
 DWORD fTimeHigh = MAKELONG(getSI(),getBP());
 DWORD tTime = getDS();
 PBYTE cptr_fName;

 BOOL Result;
 int name_size;

 cptr_fName= GetVDMPointer(rm_ptr_fName, 0, FALSE);

 name_size = strlen((LPCSTR)cptr_fName);
 OemToCharBuff((LPCSTR)cptr_fName, (LPTSTR)cptr_fName, name_size);

 Result = SetFTime((LPTSTR)cptr_fName, fTimeLow, fTimeHigh, tTime);
 FreeVDMPointer(rm_ptr_fName, 0, cptr_fName, FALSE );

 setAX(Result);
 return;
}

void cn_nt_GetFTime(void)
{
 DWORD rm_ptr_fName = MAKELONG(getBX(),getES());
 DWORD fTimeLow;
 DWORD fTimeHigh;
 DWORD tTime = getDS();
 BOOL Result;

 PBYTE cptr_fName;
 int name_size;

 cptr_fName= GetVDMPointer(rm_ptr_fName, 0, FALSE);

 name_size = strlen((LPCSTR)cptr_fName);
 OemToCharBuff((LPCSTR)cptr_fName, (LPTSTR)cptr_fName, name_size);

 Result = GetFTime((LPTSTR)cptr_fName, &fTimeLow, &fTimeHigh, tTime);
 FreeVDMPointer(rm_ptr_fName, 0, cptr_fName, FALSE );

 setCX(fTimeLow%0x10000);
 setDX(fTimeLow/0x10000);
 setSI(fTimeHigh%0x10000);
 setBP(fTimeHigh/0x10000);
 setAX(Result);
 return;
}


/*
function SetDirCheck(Dir: String): Longint; {Handle}
function SetTreeCheck(Dir: String): Longint; {Handle}
function DirCheck(var Handle: Longint): BOOLean;
procedure DirFree(Handle: Longint);
*/

void cn_nt_DirCheck(void)
{
 DWORD rm_ptr_Dir0 =   MAKELONG(getBX(),getES());
 HANDLE dirHandle = (HANDLE)MAKELONG(getCX(),getDX());
 DWORD op = getSI();
 PBYTE cptr_Dir0;
 DWORD Result = 0;
 int name_size;

 switch (op)
  {
   case 0: /*  Set directory */

     cptr_Dir0 = GetVDMPointer(rm_ptr_Dir0, 0, FALSE);

     name_size = strlen((LPCSTR)cptr_Dir0);
     OemToCharBuff((LPCSTR)cptr_Dir0, (LPTSTR)cptr_Dir0, name_size);


     if ((cptr_Dir0 != NULL) && (*cptr_Dir0 != 0))
      dirHandle = FindFirstChangeNotification(
         cptr_Dir0,      // directory to watch
         FALSE,          // do not watch subtree
         FILE_NOTIFY_CHANGE_FILE_NAME +
         FILE_NOTIFY_CHANGE_DIR_NAME +
         FILE_NOTIFY_CHANGE_ATTRIBUTES +
         FILE_NOTIFY_CHANGE_SIZE);         // watch all changes
     else dirHandle = INVALID_HANDLE_VALUE;

     FreeVDMPointer(rm_ptr_Dir0, 0, cptr_Dir0, FALSE);
     Result = (DWORD)(dirHandle != INVALID_HANDLE_VALUE);
   break;
   case 1: // Check directory
     if (WaitForMultipleObjects(
          1,
          &dirHandle,
          FALSE,
          0) == WAIT_OBJECT_0)
      {
        Result = (DWORD)TRUE;
        FindNextChangeNotification(dirHandle);
      }
   break;
   case 2: // Close handles
     if (dirHandle != INVALID_HANDLE_VALUE)
       FindCloseChangeNotification(dirHandle);
     dirHandle =  INVALID_HANDLE_VALUE;
   break;
   case 3: /*  Set tree */

     cptr_Dir0 = GetVDMPointer(rm_ptr_Dir0, 0, FALSE);

     name_size = strlen((LPCSTR)cptr_Dir0);
     OemToCharBuff((LPCSTR)cptr_Dir0, (LPTSTR)cptr_Dir0, name_size);


     if ((cptr_Dir0 != NULL) && (*cptr_Dir0 != 0))
      dirHandle = FindFirstChangeNotification(
         cptr_Dir0,      // directory to watch
         TRUE,           // do not watch subtree
         FILE_NOTIFY_CHANGE_FILE_NAME +
         FILE_NOTIFY_CHANGE_DIR_NAME +
         FILE_NOTIFY_CHANGE_ATTRIBUTES +
         FILE_NOTIFY_CHANGE_SIZE);         // watch all changes
     else dirHandle = INVALID_HANDLE_VALUE;

     FreeVDMPointer(rm_ptr_Dir0, 0, cptr_Dir0, FALSE);
     Result = (DWORD)(dirHandle != INVALID_HANDLE_VALUE);
   break;
  }

 setCX((DWORD)dirHandle%0x10000);
 setDX((DWORD)dirHandle/0x10000);
 setAX(Result);
 return;
}



void cn_nt_SHExec(void)
{
 DWORD rm_ptr_cmd =   MAKELONG(getBX(),getES());
 DWORD rm_ptr_param = MAKELONG(getCX(),getDS());
 int Flags;
 PBYTE cmd_cptr;
 PBYTE param_cptr;
 DWORD Result;
 int name_size;

 cmd_cptr = GetVDMPointer(rm_ptr_cmd, 0, FALSE);
 param_cptr = GetVDMPointer(rm_ptr_param, 0, FALSE);

 name_size = strlen((LPCSTR)cmd_cptr);
 OemToCharBuff((LPCSTR)cmd_cptr, (LPTSTR)cmd_cptr, name_size);

 if (getDX() == 1) Flags = SW_SHOWMAXIMIZED;
 else Flags = SW_SHOWNORMAL;

 Result =(int) ShellExecute(
                NULL,  // handle to parent window
                "open", // pointer to string that specifies operation to perform
                (LPCTSTR)cmd_cptr, // pointer to filename or folder name string
                (LPCTSTR)param_cptr,       // pointer to string that specifies executable-file parameters
                NULL,        // pointer to string that specifies default directory
                Flags // whether file is shown when opened
               );
 FreeVDMPointer(rm_ptr_cmd, 0, cmd_cptr, FALSE );
 FreeVDMPointer(rm_ptr_param, 0, param_cptr, FALSE );

 setAX(Result%0x10000);
 setBX(Result/0x10000);
 return;
}

BOOL CopyCancel;
WORD CallbackSS;
WORD CallbackSP;
WORD CallbackCS;
WORD CallbackIP;

DWORD WINAPI CopyProgressRoutine(
    LARGE_INTEGER TotalFileSize,         // total file size, in bytes
    LARGE_INTEGER TotalBytesTransferred, // total number of bytes transferred
    LARGE_INTEGER StreamSize,   // total number of bytes for this stream
    LARGE_INTEGER StreamBytesTransferred, // total number of bytes transferred for this stream
    DWORD dwStreamNumber,       // the current stream
    DWORD dwCallbackReason,     // reason for callback
    HANDLE hSourceFile, // handle to the source file
    HANDLE hDestinationFile,    // handle to the destination file
    LPVOID lpData       // passed by CopyFileEx
   )
{

 WORD SaveAX = getAX();
 WORD SaveBX = getBX();
 WORD SaveCX = getCX();
 WORD SaveDX = getDX();
 WORD SaveSI = getSI();
 WORD SaveDI = getDI();
 WORD SaveBP = getBP();
 WORD SaveSP = getSP();
 WORD SaveDS = getDS();
 WORD SaveES = getES();
 WORD SaveSS = getSS();
 WORD SaveCS = getCS();
 WORD SaveIP = getIP();
 DWORD Result;

 setSS(CallbackSS);
 setSP(CallbackSP-2);
 setCS(CallbackCS);
 setIP(CallbackIP);
 setAX(TotalBytesTransferred.LowPart%0x10000);
 setBX(TotalBytesTransferred.LowPart/0x10000);
 setCX((DWORD)TotalBytesTransferred.HighPart%0x10000);
 setDX((DWORD)TotalBytesTransferred.HighPart/0x10000);
 setSI(TotalFileSize.LowPart%0x10000);
 setDI(TotalFileSize.LowPart/0x10000);
 setES((DWORD)TotalFileSize.HighPart%0x10000);
 setDS((DWORD)TotalFileSize.HighPart/0x10000);
 VDDSimulate16();
 CopyCancel = (BOOL)getAX();
// Result = getDX();
// CopyCancel = 0;
 Result = 0;
 setAX(SaveAX);
 setBX(SaveBX);
 setCX(SaveCX);
 setDX(SaveDX);
 setSI(SaveSI);
 setDI(SaveDI);
 setBP(SaveBP);
 setSP(SaveSP);
 setDS(SaveDS);
 setES(SaveES);
 setSS(SaveSS);
 setCS(SaveCS);
 setIP(SaveIP);
 return Result;
}


void cn_nt_SysCopy(void)
{
 DWORD rm_ptr_Source = MAKELONG(getBX(),getES());
 DWORD rm_ptr_Dest = MAKELONG(getCX(),getDS());
 DWORD dwCopyFlags = getDX();
 PBYTE cptr_Source;
 PBYTE cptr_Dest;
 BOOL Result;
 int name_size;
 DWORD Attrs;

 CallbackSS = getSS();
 CallbackSP = getSP();
 CallbackCS = getBP();
 CallbackIP = getSI();

 cptr_Source = GetVDMPointer(rm_ptr_Source, 0, FALSE);
 cptr_Dest = GetVDMPointer(rm_ptr_Dest, 0, FALSE);

 name_size = strlen((LPCSTR)cptr_Source);
 OemToCharBuff((LPCSTR)cptr_Source, (LPTSTR)cptr_Source, name_size);

 name_size = strlen((LPCSTR)cptr_Dest);
 OemToCharBuff((LPCSTR)cptr_Dest, (LPTSTR)cptr_Dest, name_size);

 CopyCancel = FALSE;

 Result = CopyFileEx(
    (LPCSTR)cptr_Source, // pointer to name of an existing file
    (LPCSTR)cptr_Dest,   // pointer to filename to copy to
    (LPPROGRESS_ROUTINE)CopyProgressRoutine,  // pointer to the callback function
    NULL,                 // to be passed to the callback function
    &CopyCancel,  // flag that can be used to cancel the operation
    dwCopyFlags   // flags that specify how the file is copied
   );

 if (Result && ((dwCopyFlags & 4) != 0))
  {
    Attrs = GetFileAttributes((LPCSTR)cptr_Dest);
    Result = SetFileAttributes((LPCSTR)cptr_Dest,
                 Attrs & ~FILE_ATTRIBUTE_READONLY);
  }
 FreeVDMPointer(rm_ptr_Source, 0, cptr_Source, FALSE );
 FreeVDMPointer(rm_ptr_Dest, 0, cptr_Dest, FALSE );

 setAX(Result);
 return;
}

void cn_nt_MsgBox(void)
{
 DWORD rm_ptr_Text= MAKELONG(getBX(), getES());
 DWORD rm_ptr_Caption = MAKELONG(getCX(), getDS());
 DWORD uType = MAKELONG(getDX(), getSI());
 PBYTE cptr_Text;
 PBYTE cptr_Caption;
 BOOL Result;
 int name_size;

 cptr_Text= GetVDMPointer(rm_ptr_Text, 0, FALSE);
 cptr_Caption = GetVDMPointer(rm_ptr_Caption, 0, FALSE);

 name_size = strlen((LPCSTR)cptr_Text);
 OemToCharBuff((LPCSTR)cptr_Text, (LPTSTR)cptr_Text, name_size);

 name_size = strlen((LPCSTR)cptr_Caption);
 OemToCharBuff((LPCSTR)cptr_Caption, (LPTSTR)cptr_Caption, name_size);

 Result = MessageBox(
           NULL, //GetDesktopWindow(),
           (LPCSTR)cptr_Text,     // address of text in message box
           (LPCSTR)cptr_Caption,  // address of title of message box
           (UINT)uType            // style of message box
          );
 FreeVDMPointer(rm_ptr_Text, 0, cptr_Text, FALSE );
 FreeVDMPointer(rm_ptr_Caption, 0, cptr_Caption, FALSE );
 setAX(Result%0x10000);
 setBX(Result/0x10000);
 return;
}


/*      CN_NT_CallVDD:
        Called for INT 2Fh, AH=17h
*/
extern void __export WINAPI CN_NT_CallVDD(void)
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
   case 0x0c: CommFunc();                          break;
   case 0x0d: cn_nt_DirCheck();                    break;
   case 0x0e: cn_nt_SHExec();                      break;
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
   case 0x26: cn_nt_ScrInfo();                     break;
   case 0x27: cn_nt_SysCopy();                     break;
   case 0x28: cn_nt_MsgBox();                      break;
 }

 return;
}


BOOL CtrlHandler(DWORD fdwCtrlType)
{
  switch(fdwCtrlType)
  {
    case CTRL_C_EVENT:
      CtrlType = 1;
      return TRUE;

    case CTRL_CLOSE_EVENT:
      CtrlType = 2;
      return TRUE;

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

BOOL CN_NT_process_attach(HINSTANCE hdll)
{
 clip_open = FALSE;

 SetConsoleCtrlHandler((PHANDLER_ROUTINE) CtrlHandler, TRUE);

 ResetAllHandles(); /* Reset all comports */

 return TRUE;
}

/*
        CN_NT_process_detach:
        Called at DLL desinitialization.
        Free NTVDM I/O hooks.
*/

BOOL CN_NT_process_detach(HINSTANCE hdll)
{
 if (clip_open) CloseClipboard();

 SetConsoleCtrlHandler((PHANDLER_ROUTINE) CtrlHandler, FALSE);

 CloseAllHandles(); /* Close all comports */

 return TRUE;
}

/*
        DllEntryPoint:
        Win32 standard DLL entry point.
*/
extern
BOOL WINAPI DllEntryPoint(
        HINSTANCE hdll,         // handle to DLL module
        DWORD fdwReason,        // reason for calling function
        LPVOID lpv)             // reserved
{
 struct {
         DWORD event;
         BOOL(* entry)(HINSTANCE hdll);
        } inittable[] =
  {
    {DLL_PROCESS_ATTACH, CN_NT_process_attach},
    {DLL_PROCESS_DETACH, CN_NT_process_detach}
  };
 int x;

 for (x = 0; x < sizeof inittable /sizeof inittable[0]; x++)
  if (inittable[x].event == fdwReason)
   return inittable[x].entry(hdll);
 return TRUE;
}

/*
BOOL VDDInitialize(IN PVOID DllHandle, IN ULONG Reason,
IN PCONTEXT Context OPTIONAL)


Routine Description:

Arguments:
    DllHandle - Not Used
    Reason - Attach or Detach
    Context - Not Used

Return Value:
    SUCCESS - TRUE
    FAILURE - FALSE


{

    switch (Reason) {

    case DLL_PROCESS_ATTACH:
    // Allocate VDD's local heap if needed. Check that NT FAX driver
    // is available by opening that device.
        break;
    case DLL_PROCESS_DETACH:
    // Deallocate VDD's local heap if needed.
    // Communicate to appropriate Device driver about your departure.
        break;
    default:
        break;
    }

    return TRUE;
}

*/
