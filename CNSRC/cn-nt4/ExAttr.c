#include <Windows.h>
#include <Winbase.h>
#include <Winioctl.h>

/*
#define FILE_ATTRIBUTE_READONLY             0x00000001
#define FILE_ATTRIBUTE_HIDDEN               0x00000002
#define FILE_ATTRIBUTE_SYSTEM               0x00000004
#define FILE_ATTRIBUTE_DIRECTORY            0x00000010
#define FILE_ATTRIBUTE_ARCHIVE              0x00000020
#define FILE_ATTRIBUTE_DEVICE               0x00000040
#define FILE_ATTRIBUTE_NORMAL               0x00000080
#define FILE_ATTRIBUTE_TEMPORARY            0x00000100
#define FILE_ATTRIBUTE_SPARSE_FILE          0x00000200
#define FILE_ATTRIBUTE_REPARSE_POINT        0x00000400
#define FILE_ATTRIBUTE_COMPRESSED           0x00000800
#define FILE_ATTRIBUTE_OFFLINE              0x00001000
#define FILE_ATTRIBUTE_NOT_CONTENT_INDEXED  0x00002000
#define FILE_ATTRIBUTE_ENCRYPTED            0x00004000
*/

/*
BOOL EncryptFile(
  LPCTSTR lpFileName
);

BOOL DecryptFile(
  LPCTSTR lpFileName,
  DWORD dwReserved
);

DWORD GetFileAttributes(
  LPCTSTR lpFileName
);

BOOL SetFileAttributes(
  LPCTSTR lpFileName,
  DWORD dwFileAttributes
);

COMPRESSION_FORMAT_DEFAULT
COMPRESSION_FORMAT_NONE

*/


/*
Attribute                       How to Set
FILE_ATTRIBUTE_COMPRESSED       To set a file's compression state, use the DeviceIoControl function with the FSCTL_SET_COMPRESSION operation.
FILE_ATTRIBUTE_DEVICE           Reserved; do not use.
FILE_ATTRIBUTE_DIRECTORY        Files cannot be converted into directories. To create a directory, use the CreateDirectory or CreateDirectoryEx function.
FILE_ATTRIBUTE_ENCRYPTED        To create an encrypted file, use the CreateFile function with the FILE_ATTRIBUTE_ENCRYPTED attribute. To convert an existing file into an encrypted file, use the EncryptFile function.
FILE_ATTRIBUTE_REPARSE_POINT    To associate a reparse point with a file or directory, use the DeviceIoControl function with the FSCTL_SET_REPARSE_POINT operation.
FILE_ATTRIBUTE_SPARSE_FILE      To set a file's sparse attribute, use the DeviceIoControl function with the FSCTL_SET_SPARSE operation.
*/


BOOL SetFAttr(char *fName, DWORD fAttr)
{
 DWORD Attrs;
 BOOL Res = TRUE;

 if ((fAttr & (FILE_ATTRIBUTE_SPARSE_FILE +
               FILE_ATTRIBUTE_REPARSE_POINT +
               FILE_ATTRIBUTE_DEVICE)) != 0) return FALSE;

 if ((fAttr & (FILE_ATTRIBUTE_COMPRESSED +
               FILE_ATTRIBUTE_ENCRYPTED)) ==
              (FILE_ATTRIBUTE_COMPRESSED +
               FILE_ATTRIBUTE_ENCRYPTED)) return FALSE;

 Attrs = GetFileAttributes(fName);
 if (Attrs == 0xFFFFFFFF) return FALSE;

 if (Res) Res = SetFileAttributes(fName, fAttr);
 return Res;
}

BOOL SetFTime(
      char *fName,
      DWORD dwLowDateTime,
      DWORD dwHighDateTime,
      DWORD tTime)
{

   HANDLE hFile;             // handle to file
   FILETIME fTime;
   BOOL Res = FALSE;

   hFile =   CreateFile(
              fName,                      // file to open
              GENERIC_READ+               // open for reading
              GENERIC_WRITE,              // open for writing
              0,                          // do not share
              NULL,                       // default security
              OPEN_EXISTING,              // existing file
              FILE_ATTRIBUTE_NORMAL+
              FILE_FLAG_BACKUP_SEMANTICS,  // normal file
              NULL                         // no attr. template
             );

   if (hFile != INVALID_HANDLE_VALUE)
     {
      fTime.dwLowDateTime = dwLowDateTime;
      fTime.dwHighDateTime = dwHighDateTime;
      switch (tTime)
       {
        case 0: // CreationTime
                Res = SetFileTime(
                       hFile,      // identifies the file
                       &fTime,     // time the file was created
                       NULL,       // time the file was last accessed
                       NULL);      // time the file
                break;
        case 1: // LastAccess
                Res = SetFileTime(
                       hFile,      // identifies the file
                       NULL,       // time the file was created
                       &fTime,     // time the file was last accessed
                       NULL);      // time the file
                break;
        case 2: // LastWrite
                Res = SetFileTime(
                       hFile,      // identifies the file
                       NULL,       // time the file was created
                       NULL,       // time the file was last accessed
                       &fTime);    // time the file
                break;
       }
      CloseHandle(hFile);
     }
   return Res;
}

BOOL GetFTime(
      char *fName,
      LPDWORD dwLowDateTime,
      LPDWORD dwHighDateTime,
      DWORD tTime)
{

   HANDLE hFile;             // handle to file
   FILETIME fTime;
   BOOL Res = FALSE;

   hFile =   CreateFile(
              fName,                      // file to open
              GENERIC_READ+               // open for reading
              GENERIC_WRITE,              // open for writing
              0,                          // do not share
              NULL,                       // default security
              OPEN_EXISTING,              // existing file
              FILE_ATTRIBUTE_NORMAL+
              FILE_FLAG_BACKUP_SEMANTICS,  // normal file
              NULL                         // no attr. template
             );

   if (hFile != INVALID_HANDLE_VALUE)
     {
      switch (tTime)
       {
        case 0: // CreationTime
                Res = GetFileTime(
                       hFile,      // identifies the file
                       &fTime,     // time the file was created
                       NULL,       // time the file was last accessed
                       NULL);      // time the file
                break;
        case 1: // LastAccess
                Res = GetFileTime(
                       hFile,      // identifies the file
                       NULL,       // time the file was created
                       &fTime,     // time the file was last accessed
                       NULL);      // time the file
                break;
        case 2: // LastWrite
                Res = GetFileTime(
                       hFile,      // identifies the file
                       NULL,       // time the file was created
                       NULL,       // time the file was last accessed
                       &fTime);    // time the file
                break;
       }
      CloseHandle(hFile);
      *dwLowDateTime = fTime.dwLowDateTime;
      *dwHighDateTime = fTime.dwHighDateTime;
     }
   return Res;
}

