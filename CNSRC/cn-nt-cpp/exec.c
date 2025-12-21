#define WINVER 0x0400
#define STRICT

#include <windows.h>
#include <string.h>

#define BUFSIZE         512U
#define eoErrIgnore     1
#define eoErrZero       2
#define eoAsync         4

DWORD Exec(LPCTSTR cmd, LPCTSTR redir, DWORD flags, DWORD opt)
{
 STARTUPINFO StartupInfo;
 PROCESS_INFORMATION ProcessInfo;
 SECURITY_ATTRIBUTES pipe_sa;
 HANDLE out_read = INVALID_HANDLE_VALUE;
 HANDLE out_write = INVALID_HANDLE_VALUE;
 HANDLE err_read = INVALID_HANDLE_VALUE;
 HANDLE err_write = INVALID_HANDLE_VALUE;
 HANDLE hfredir;
 DWORD Result;
 char Buf[BUFSIZE];
 DWORD BytesRead;
 DWORD BytesWrites;
 DWORD cmd_size;
 DWORD redir_size;

 cmd_size = strlen(cmd);
 OemToCharBuff((LPCSTR)cmd, (LPTSTR)cmd, cmd_size);

 redir_size = strlen(redir);
 OemToCharBuff((LPCSTR)redir, (LPTSTR)redir, redir_size);

 ZeroMemory(&StartupInfo, sizeof(STARTUPINFO));
 StartupInfo.cb = sizeof(StartupInfo);
 StartupInfo.dwFlags = STARTF_USESHOWWINDOW;
 StartupInfo.wShowWindow =  SW_SHOWNORMAL;
 if (((redir != NULL) && (*redir != 0)) &&
     ((opt & eoAsync) == 0))
  {
   /* Open pipes here */

   pipe_sa.nLength = sizeof(pipe_sa);
   pipe_sa.bInheritHandle = TRUE;
   pipe_sa.lpSecurityDescriptor = NULL;
   Buf[0] = 13; Buf[1] = 10;
   if (!CreatePipe(&out_read, &out_write, &pipe_sa, 0x8000))
    {
      out_read = INVALID_HANDLE_VALUE;
      out_write = INVALID_HANDLE_VALUE;
    }
   else WriteFile(out_write, Buf, 2, &BytesWrites, NULL);

   if (!CreatePipe(&err_read, &err_write, &pipe_sa, 0x8000))
    {
      err_read = INVALID_HANDLE_VALUE;
      err_write = INVALID_HANDLE_VALUE;
    }
   else WriteFile(err_write, Buf, 2, &BytesWrites, NULL);

   StartupInfo.wShowWindow = SW_HIDE;
   StartupInfo.dwFlags |= STARTF_USESTDHANDLES;
  }

 StartupInfo.hStdInput = INVALID_HANDLE_VALUE;
 StartupInfo.hStdOutput = out_write;
 StartupInfo.hStdError = err_write;
 flags |= NORMAL_PRIORITY_CLASS;
 if (!CreateProcess(NULL,         // pointer to name of executable module
                    cmd,          // pointer to command line string
                    NULL,         // pointer to process security attributes
                    NULL,         // pointer to thread security attributes
                    TRUE,         // handle inheritance flag
                    flags,        // creation flags
                    NULL,         // pointer to new environment block
                    NULL,         // pointer to current directory name
                    &StartupInfo, // pointer to STARTUPINFO
                    &ProcessInfo  // pointer to PROCESS_INFORMATION
                   )
    ) Result = 0;
 else Result = GetLastError();

 if (((Result == 0)||((opt & eoErrIgnore) != 0)) &&
     ((opt & eoAsync) == 0))
  {
   WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
   CloseHandle(ProcessInfo.hThread );
   CloseHandle(ProcessInfo.hProcess );
   /* Create or open report file */

   hfredir = CreateFile(redir,                     // file to open
                       GENERIC_READ+GENERIC_WRITE, // open for reading
                       0,                          // do not share
                       NULL,                       // default security
                       OPEN_ALWAYS,                // existing or new file
                       FILE_ATTRIBUTE_NORMAL,      // normal file
                       NULL);                      // no attr. template

   if (hfredir != INVALID_HANDLE_VALUE)
    {
      /* Go to the end of file */
      SetFilePointer(hfredir, GetFileSize (hfredir, NULL), NULL, FILE_BEGIN);
      /* Copy output pipe to the report file */
      do
       {
         ReadFile(out_read, Buf, BUFSIZE, &BytesRead, NULL);
         WriteFile(hfredir, Buf, BytesRead, &BytesWrites, NULL);
       }
      while (BytesRead == BUFSIZE);
      /* Copy error pipe to the report file */
      do
       {
         ReadFile(err_read, Buf, BUFSIZE, &BytesRead, NULL);
         WriteFile(hfredir, Buf, BytesRead, &BytesWrites, NULL);
       }
      while (BytesRead == BUFSIZE);
      /* Close report file */
      CloseHandle(hfredir);
    };
  };
 if (err_read != INVALID_HANDLE_VALUE) CloseHandle(err_read);
 if (err_write != INVALID_HANDLE_VALUE) CloseHandle(err_write);
 if (out_read != INVALID_HANDLE_VALUE) CloseHandle(out_read);
 if (out_write != INVALID_HANDLE_VALUE) CloseHandle(out_write);
 if ((opt & eoErrZero) == 0) return Result;
 else return 0;
};
