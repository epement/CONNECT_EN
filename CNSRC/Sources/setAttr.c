#include <Windows.h>
#include <Winioctl.h>


BOOL SetComprAttr(char *fName)
{
   HANDLE hDevice;             // handle to device of interest

   DWORD dwIoControlCode;      // control code of operation to perform
   char InBuffer[0x8000];      // pointer to buffer to supply input data
   DWORD nInBufferSize;        // size of input buffer
   LPVOID lpOutBuffer;         // pointer to buffer to receive output data
   DWORD nOutBufferSize;       // size of output buffer
   DWORD BytesReturned;        // pointer to variable to receive output byte count
   LPOVERLAPPED lpOverlapped;  // pointer to overlapped structure for asynchronous operation
   BOOL Res;

   Res = FALSE;
   hDevice = CreateFile(
              fName,                      // file to open
              GENERIC_READ+GENERIC_WRITE, // open for reading
              0,                          // do not share
              NULL,                       // default security
              OPEN_EXISTING,              // existing file
              FILE_ATTRIBUTE_NORMAL,      // normal file
              NULL                        // no attr. template
             );

   if (hDevice != INVALID_HANDLE_VALUE)
     {
      Res = DeviceIoControl(
              (HANDLE) hDevice,            // handle to file or directory
              FSCTL_SET_COMPRESSION,       // dwIoControlCode
              (LPVOID) InBuffer,           // input buffer
              (DWORD) sizeof(InBuffer),    // size of input buffer
              NULL,                        // lpOutBuffer
              0,                           // nOutBufferSize
              (LPDWORD) &BytesReturned,    // number of bytes returned
              NULL                         // OVERLAPPED structure
            );
      CloseHandle(hDevice);
     }
   return Res;
}
