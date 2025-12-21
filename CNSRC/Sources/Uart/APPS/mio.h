/* mio.h */

#define SEND_TO  1
#define WAIT_FOR 2
#define QUIET    3

#define MIO_IDLE     0
#define MIO_RUNNING  (-1)

NoMangle int DLL_IMPORT_EXPORT mioSendTo(int,unsigned long,LPSTR);
NoMangle int DLL_IMPORT_EXPORT mioQuiet(int,unsigned long);
NoMangle int DLL_IMPORT_EXPORT mioWaitFor(int,unsigned long,LPSTR);
NoMangle int DLL_IMPORT_EXPORT mioResult(int);
NoMangle int DLL_IMPORT_EXPORT mioDriver(int);
NoMangle int DLL_IMPORT_EXPORT mioBreak(int);
NoMangle int DLL_IMPORT_EXPORT mioDebug(HWND);
  
