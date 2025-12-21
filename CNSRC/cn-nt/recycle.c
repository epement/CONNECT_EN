#include <Windows.h>
#include <Shellapi.h>

BOOL DelToTrash (char* pFiles)
{
   /* Code which deletes files if pFiles is a double-zero terminated string */

   SHFILEOPSTRUCT shMyfile;
   HWND hwndDesktop = NULL;

   /*  Check whether pFiles has any name or not */
   if ((pFiles == NULL) || (*pFiles == 0 )) return FALSE;

   /* hwndDesktop = GetDesktopWindow( ); */

   memset( &shMyfile, 0, sizeof( shMyfile ) );

   shMyfile.hwnd = hwndDesktop;
   shMyfile.wFunc = FO_DELETE;
   shMyfile.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_SILENT;

   shMyfile.pFrom = pFiles;


   if (SHFileOperation(&shMyfile) == 0) return TRUE;
   else return FALSE;
}

BOOL EmptyTrash(char* RootPath)
{
   return SHEmptyRecycleBin(0,RootPath,
                            SHERB_NOCONFIRMATION |
                            SHERB_NOPROGRESSUI |
                            SHERB_NOSOUND);
}


