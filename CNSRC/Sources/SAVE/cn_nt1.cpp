/*
        CN_NT (Clipboard support for DOS programmes running in NT's VDM.)
        CN_NT.DLL (Win32 DLL part.)
        CN_NT.CPP (Main module.)
*/


#define WINVER 0x0400
#define STRICT

#include <windows.h>
#include <windowsx.h>

#include "ntvdm.h"

bool clip_open;

/*      CN_NT_InitVDD:
        Called by our TSR at initialization.
*/
extern "C" void __export WINAPI CN_NT_InitVDD(void)
{
        return;
}

/*      AL = 00h
        Installation Check
*/
void cn_nt_installcheck()
{
        setAX(0x0103);  // Windows 3.1 (lie ;-)
        return;
}

/*      AL = 01h
        Open Clipboard
*/
void cn_nt_open_clipb()
{
        if(!clip_open)
        {
                clip_open = OpenClipboard(NULL);
                setAX(clip_open);
        }
        else
        {
                setAX(0);
        }

        return;
}

/*      AL = 02h
        Empty Clipboard
*/
void cn_nt_clear_clipb()
{
        setAX( (bool)EmptyClipboard() );
        return;
}

/*      AL = 03h
        Write to clipboard
*/
void cn_nt_write_clipb()
{
        WORD    format = getDX();
        DWORD   rm_ptr = MAKELONG(getBX(),getES());
        DWORD   size   = MAKELONG(getCX(),getSI())+1;

        HGLOBAL gmem;   // handle of global mem
        LPVOID  gptr;   // pointer to global mem
        PBYTE   srcptr; // pointer to source address (converted)

        gmem = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE, size );
        if(!gmem) { setAX(GetLastError()); return; };

        gptr = GlobalLock( gmem );
        if(!gptr) { setAX(GetLastError()); GlobalFree(gmem); return; };

        srcptr = GetVDMPointer( rm_ptr, size, false );
        memmove( gptr, srcptr, size );

       /*  OemToCharBuff((LPCSTR) srcptr, (LPTSTR) gptr, size ); */


        FreeVDMPointer( rm_ptr, size, srcptr, false  );

        GlobalUnlock(gptr);

        setAX( (bool)SetClipboardData( format, gmem ) );
        return;
}

/*      AL = 04h
        Close Clipboard
*/
void cn_nt_read_clipb_size()
{
        WORD    format = getDX();

        DWORD   size;

        HANDLE  gmem;

        gmem = GetClipboardData( format );

        size = gmem ? GlobalSize( gmem ) : 0;

        setAX( LOWORD(size) );
        setDX( HIWORD(size) );

        return;
}

/*      AL = 05h
        Read clipboard
*/
void cn_nt_read_clipb()
{
        WORD    format = getDX();
        DWORD   rm_ptr = MAKELONG(getBX(),getES());

        HANDLE  gmem;
        LPVOID  gptr;
        DWORD   size;

        PBYTE   destptr;

        gmem = GetClipboardData( format );
        if(!gmem) { setAX(false); return; };

        size = GlobalSize( gmem );

        gptr = GlobalLock( gmem );
        if(!gptr) { setAX(false); return; };

        destptr = GetVDMPointer( rm_ptr, size, false );
        memmove( destptr, gptr, size );
        FreeVDMPointer( rm_ptr, size, destptr, false  );

        GlobalUnlock(gptr);

        setAX( true );

        return;
}

/*      AL = 08h
        Close Clipboard
*/
void cn_nt_close_clipb()
{
        if( clip_open )
        {
                bool succ;
                succ = CloseClipboard();
                clip_open = !succ;
                setAX(succ);
        }
        else
                setAX(0);

        return;
}

/*      AL = 09h
        Don't know exactly what this does.
        Maybe for compatibility with older real mode Windows versions?
        Simply return requested size free memory. (1MB)
*/
void cn_nt_compact_clipb()
{
        setAX( getCS() );
        setDX( getSI() );
        return;
}

/*      AL = 0Ah
        Don't know exactly what this is supposed to do.
        Just return nothing and pray noone calls it. ;-)
*/
void cn_nt_get_dev_caps()
{
        return;
}

/*      AL = 10h
        Additional Installation Check
*/
void cn_nt_add_installcheck()
{
        setAX(0x1117);
        return;
}
/*      AL = 11h
        GetDiskFreeSpace
*/

void cn_nt_GetDiskFreeSpace()
{
    DWORD rm_ptr = MAKELONG(getBX(),getES());
    DWORD SectorsPerCluster = 0;        // address of sectors per cluster
    DWORD BytesPerSector = 0;           // address of bytes per sector
    DWORD NumberOfFreeClusters = 0;     // address of number of free clusters
    DWORD TotalNumberOfClusters = 0;    // address of total number of clusters
    PBYTE srcptr;

    srcptr = GetVDMPointer( rm_ptr, 0, false );

   (void)GetDiskFreeSpace((LPCTSTR)srcptr,
                      &SectorsPerCluster,    // address of sectors per cluster
                      &BytesPerSector,       // address of bytes per sector
                      &NumberOfFreeClusters, // address of number of free clusters
                      &TotalNumberOfClusters // address of total number of clusters
                     );
   FreeVDMPointer( rm_ptr, 0, srcptr, false  );

   setAX((SectorsPerCluster));
   setBX(BytesPerSector);
   setCX(NumberOfFreeClusters%0x10000);
   setDX(NumberOfFreeClusters/0x10000);
   setSI(TotalNumberOfClusters%0x10000);
   setBP(TotalNumberOfClusters/0x10000);
   return;
}

/*      AL = 12h
        GetDriveType
*/

void cn_nt_GetDriveType()
{
    DWORD rm_ptr = MAKELONG(getBX(),getES());
    PBYTE srcptr;
    UINT DriveType;

    srcptr = GetVDMPointer( rm_ptr, 0, false );

   DriveType = GetDriveType((LPCTSTR)srcptr);
   FreeVDMPointer( rm_ptr, 0, srcptr, false  );

   setAX(DriveType);
   return;
}

/*      AL = 13h
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

/*      AL = 14h
        GetDiskFreeSpace
*/

void cn_nt_GetCompressedFileSize()
{
    DWORD rm_ptr = MAKELONG(getBX(),getES());
    DWORD CompSize = 0;
    DWORD FileSize;
    PBYTE srcptr;

    srcptr = GetVDMPointer( rm_ptr, 0, false );

   FileSize = GetCompressedFileSize((LPCTSTR)srcptr, &CompSize);
   FreeVDMPointer( rm_ptr, 0, srcptr, false  );

   setAX(FileSize%0x10000);
   setBX(FileSize/0x10000);
   setCX(CompSize%0x10000);
   setDX(CompSize/0x10000);
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
                case 0x0b:
                case 0x0c:
                case 0x0d:
                case 0x0e:
                case 0x0f:
                case 0x10: cn_nt_add_installcheck();            break;
                case 0x11: cn_nt_GetDiskFreeSpace();            break;
                case 0x12: cn_nt_GetDriveType();                break;
                case 0x13: cn_nt_GetLogicalDrives();            break;
                case 0x14: cn_nt_GetCompressedFileSize();       break;

        }

        return;
}

/*      CN_NT_process_attach:
        Called at DLL initialization.
*/
bool CN_NT_process_attach(HINSTANCE hdll)
{
        clip_open = false;
        return true;
}

/*      CN_NT_process_attach:
        Called at DLL desinitialization.
        Free NTVDM I/O hooks.
*/
bool CN_NT_process_detach(HINSTANCE hdll)
{
        if(clip_open)
                CloseClipboard();

        return true;
}

/*      DllEntryPoint:
        Win32 standard DLL entry point.
*/
extern "C"
BOOL WINAPI DllEntryPoint(
        HINSTANCE hdll,         // handle to DLL module
        DWORD fdwReason,        // reason for calling function
        LPVOID                          // reserved
   )
{
        struct {
                DWORD   event;
                bool(*  entry)(HINSTANCE hdll);
        }
        inittable[] =
        {
                { DLL_PROCESS_ATTACH, CN_NT_process_attach },
                { DLL_PROCESS_DETACH, CN_NT_process_detach }
        };

        for (int x = 0; x < sizeof inittable /sizeof inittable[0]; x++ )
                if( inittable[x].event == fdwReason )
                        return inittable[x].entry(hdll);
        return true;
}
