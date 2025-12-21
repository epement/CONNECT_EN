#include <windows.h>
#include <stdlib.h>
#include <stdio.h>
#include <tchar.h>

void RefreshDirectory(LPTSTR);
void RefreshTree(LPTSTR);

void WatchDirectory(LPTSTR lpDir)
{
   DWORD dwWaitStatus;
   HANDLE dwChangeHandles[2];
   TCHAR lpDrive[4];
   TCHAR lpFile[_MAX_FNAME];
   TCHAR lpExt[_MAX_EXT];

   _tsplitpath(lpDir, lpDrive, NULL, lpFile, lpExt);

   lpDrive[2] = (TCHAR)'\\';
   lpDrive[3] = (TCHAR)'\0';

// Watch the directory for file creation and deletion.

   dwChangeHandles[0] = FindFirstChangeNotification(
      lpDir,                         // directory to watch
      FALSE,                         // do not watch subtree
      FILE_NOTIFY_CHANGE_FILE_NAME); // watch file name changes

   if (dwChangeHandles[0] == INVALID_HANDLE_VALUE)
      ExitProcess(GetLastError());

// Watch the subtree for directory creation and deletion.

   dwChangeHandles[1] = FindFirstChangeNotification(
      lpDrive,                       // directory to watch
      TRUE,                          // watch the subtree
      FILE_NOTIFY_CHANGE_DIR_NAME);  // watch dir. name changes

   if (dwChangeHandles[1] == INVALID_HANDLE_VALUE)
      ExitProcess(GetLastError());

// Change notification is set. Now wait on both notification
// handles and refresh accordingly.

   while (TRUE)
   {
   // Wait for notification.

      dwWaitStatus = WaitForMultipleObjects(2, dwChangeHandles,
         FALSE, INFINITE);

      switch (dwWaitStatus)
      {
         case WAIT_OBJECT_0:

         // A file was created or deleted in the directory.
         // Refresh this directory and restart the notification.

            RefreshDirectory(lpDir);
            if ( FindNextChangeNotification(
                    dwChangeHandles[0]) == FALSE )
                ExitProcess(GetLastError());
            break;

         case WAIT_OBJECT_0 + 1:

         // A directory was created or deleted in the subtree.
         // Refresh the tree and restart the notification.

            RefreshTree(lpDrive);
            if (FindNextChangeNotification(
                    dwChangeHandles[1]) == FALSE)
                ExitProcess(GetLastError());
            break;

        default:
            ExitProcess(GetLastError());
      }
   }
}

void RefreshDirectory(LPTSTR lpDir)
{
   _tprintf(TEXT("Refresh the directory (%s).\n"), lpDir);
}

void RefreshTree(LPTSTR lpDrive)
{
   _tprintf(TEXT("Refresh the directory tree (%s).\n"), lpDrive);
}
