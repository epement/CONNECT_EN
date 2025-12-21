#include <Windows.h>
#include <Shellapi.h>

BOOL MyInternalDelete ( char* pFiles )
{
        //Code which deletes files if pFiles is a double-zero terminated string

   SHFILEOPSTRUCT shMyfile;
   HWND hwndDesktop;

        // Check whether pFiles has any name or not
        if ( strlen( pFiles ) == 0 ) return FALSE;

   hwndDesktop = GetDesktopWindow( );

   memset( &shMyfile, 0, sizeof( shMyfile ) );

   shMyfile.hwnd = hwndDesktop;
   shMyfile.wFunc = FO_DELETE;
   shMyfile.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_SILENT;
   shMyfile.pFrom = pFiles;


   SHFileOperation( &shMyfile ) ; //IMPORTANT

        return TRUE;
}

