/*

 DO>>  Добавлю.  Единственное, там же дата/время - это два лонга (на
 DO>> сколько я помню, в LFN API тоже). Что там есть что ты не помнишь?

 IB> Похоже, что в LFN API другое, там мы берем только младший long и
 IB> считаем его временем в ДОС-формате, а здесь UTC format.

Ок, я посмотрю как одно в другое переделать. Есть например такие функции:

 INT 21h  AX=71A6 - Windows95 - LONG FILENAME - GET FILE INFO BY HANDLE
 INT 21h  AX=71A7 BL=00 - Windows95 - LONG FILENAME - FILE TIME TO DOS TIME
 INT 21h  AX=71A7 BL=01 - Windows95 - LONG FILENAME - DOS TIME TO FILE TIME

На сколько я понимаю, 71A6 возвращает тоже самое, что и
BOOL GetFileInformationByHandle(
    HANDLE hFile,  // handle of file
    LPBY_HANDLE_FILE_INFORMATION lpFileInformation  // address of structure
   );
typedef struct _BY_HANDLE_FILE_INFORMATION { // bhfi
    DWORD    dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD    dwVolumeSerialNumber;
    DWORD    nFileSizeHigh;
    DWORD    nFileSizeLow;
    DWORD    nNumberOfLinks;
    DWORD    nFileIndexHigh;
    DWORD    nFileIndexLow;
} BY_HANDLE_FILE_INFORMATION;

INT 21h  AX=71A6
 INT 21 - Windows95 - LONG FILENAME - GET FILE INFO BY HANDLE
         AX = 71A6h
         BX = file handle
         DS:DX -> buffer for file information (see #1473)
         CF set
 Return: CF clear if successful
             file information record filled
         CF set on error
             AX = error code
                 7100h if function not supported
 See: AX=71A7h/BL=00h


 Format of Windows95 file information:
 Offset  Size    Description     (Table 1473)
  00h    DWORD   file attributes
  04h    QWORD   creation time (0 = unsupported)
  0Ch    QWORD   last access time (0 = unsupported)
  14h    QWORD   last write time
  1Ch    DWORD   volume serial number
  20h    DWORD   high 32 bits of file size
  24h    DWORD   low 32 bits of file size
  28h    DWORD   number of links to file
  2Ch    DWORD   unique file identifier (high 32 bits)
  30h    DWORD   unique file identifier (low 32 bits)
 Note:   the file identifer and volume serial number together uniquely
identify
           a file while it is open; the identifier may change when the
system
           is restarted or the file is first opened
 See: INT 21h  AX=71A6

и это те же данные, что используются в

BOOL GetFileTime(
    HANDLE hFile, // identifies the file
    LPFILETIME lpCreationTime, // address of creation time
    LPFILETIME lpLastAccessTime, // address of last access time
    LPFILETIME lpLastWriteTime  // address of last write time
   );

и

BOOL SetFileTime(
    HANDLE hFile, // identifies the file
    CONST FILETIME *lpCreationTime, // time the file was created
    CONST FILETIME *lpLastAccessTime, // time the file was last accessed
    CONST FILETIME *lpLastWriteTime  // time the file was last written
   );

Единственное, я совершенно не помню чем это от упакованного в long времени
отличается, но я поищу, это не большая проблема.

Есть такое

 Bitfields for file date:
 Bit(s)  Description     (Table 1352)
  15-9   year - 1980
  8-5    month
  4-0    day
 See: INT 21h  AX=5700

 и такое

 Bitfields for file time:
 Bit(s)  Description     (Table 1351)
  15-11  hours (0-23)
  10-5   minutes
  4-0    seconds/2

 See: INT 21h  AX=5700

Если ты сделаешь мне рыбу с этой функцией, работающей для одного времени, я
сделаю все остальное.
*/
