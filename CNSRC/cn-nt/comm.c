#include <windows.h>
#include "ntvdm.h"


#define MAX_LINES 64             // Maximum number of COM lines

typedef unsigned char   byte;

static HANDLE hCom[MAX_LINES];


/*   forward declarations */

void ResetAllHandles(void);
void CloseAllHandles(void);
static void CloseOneHandle(int i);
static int OpenPort(byte port, USHORT opt, USHORT baud);
static void ClosePort(byte port);
static BOOL PortNotOpen(byte port);
static BOOL PortIsOpen(byte port);
static DWORD MinD(DWORD d1, DWORD d2);

/*
 *
 * CommFunc
 *
 * Arguments:
 *     Client(DX)    = Address / command code

    0xBBCC

     high byte : "BB" : NT port base (8 for COM8 etc) (used in OPEN only)
     Low byte: : "CC" : Command

    Commands:

    0 : INIT    DH = Port (1 - Com1, 2 - Com2)
                DL = 0
                CX = baud rate
                BL & 0x0f = bits (5, 6, 7, 8)
                BL & 0xf0 = stops (1 - , 2 - 1.5, 3 - 2)
                BH & 0x0f = parity (0 - none, 1 - even, 2 - odd)

    1 : READ    DH = Port (1 - Com1, 2 - Com2)
                DL = 1
                CX = number of chars to read
                ES:SI = buffer
                return : CX = actual read

    2 : WRITE   DH = Port (1 - Com1, 2 - Com2)
                DL = 2
                CX = number of chars to write
                ES:SI = buffer
                return : CX = actual written

    3 : CLOSE   DH = Port (1 - Com1, 2 - Com2)
                DL = 3

    4 : MDM_CTL DH = Port (1 - Com1, 2 - Com2)
                DL = 4
                CX = EscapeCommFunction signal code

 * Return Value:
 *     Client Carry Clear:  SUCCESS  AX = 0
 *     Client Carry Set:    FAILURE, AX = reason
 *
 */



void CommFunc( void )
{
  PCHAR   Buffer;
  DWORD   lpErr;
  COMSTAT lpStat;
  USHORT  UserCX, UserDX, IO_Result;
  BYTE    temp, PortOpt, PortCommand, port;
  DWORD   Actual,toGet;
  BOOL    Success;
  int     result;


    UserDX = getDX();

    PortCommand = UserDX % 256;
    port = UserDX / 256;


    UserCX = getCX();               // all commands use CX

    switch (PortCommand)
     {
      case 0: // Initialize
          if (PortIsOpen(port))
           {
             setAX(1);
             setCF(1);
             return;
           }

          PortOpt = getBX();
          result = OpenPort(port, PortOpt, UserCX);
          setCF((result==0)? 0 : 1);
          setAX((USHORT)result);
          break;

      case 1: // Read buffer

          if (PortNotOpen(port))
           {
              setCX(0);
              setAX(1);
              setCF(1);
              return;
           }


          Buffer = GetVDMPointer(MAKELONG(getSI(), getES()), 0, FALSE);

          Success = ClearCommError(hCom[port], &lpErr, &lpStat);
          toGet = MinD(UserCX, lpStat.cbInQue);

          if (Success && (toGet > 0))
             Success = ReadFile(hCom[port], Buffer, toGet, &Actual, NULL);

          if (!Success) toGet = 0;

          setCX((USHORT) toGet);
          setAX(0);
          setCF(0);
          break;

      case 2: // Write buffer

          if (PortNotOpen(port))
           {
              setCX(0);
              setAX(1);
              setCF(1);
              return;
           }

          Buffer = GetVDMPointer(MAKELONG(getSI(), getES()), 0, FALSE);
          Success = WriteFile( hCom[port], Buffer, UserCX, &Actual, NULL);
          if (!Success) Actual = 0;

          setAX(0);
          setCX((USHORT) Actual);
          setCF(0);
          break;

      case 3: // CLOSE

          if (PortIsOpen(port))
           {
              CloseOneHandle(port);
              setAX(0);
              setCF(0);
           }
          else
           {
              setAX(1);
              setCF(1);
           }
          break;
      case 4: // MDM_CTL

          if (PortNotOpen(port))
           {
              setCX(0);
              setAX(1);
              setCF(1);
              return;
           }

          Success = EscapeCommFunction(hCom[port], UserCX);
          setAX(0);
          if (Success) setCF(0);
          else setCF(1);
          break;

      default: // unknown command
          break;

     }

    return;
}


// service procedures


void ResetAllHandles(void)      // invalidate all handles on entry
{
  int i;

  for (i = 0; i < MAX_LINES; i++) hCom[i] = INVALID_HANDLE_VALUE;
}

static void CloseOneHandle (int i)
{
    if (hCom[i] != INVALID_HANDLE_VALUE)
    {
       CloseHandle (hCom[i]);
       hCom[i] = INVALID_HANDLE_VALUE;
    }

}


void CloseAllHandles(void)      // close all open handles
{
 int i;

 for (i = 0; i < MAX_LINES; i++)  CloseOneHandle(i);
}


static int OpenPort(byte port, USHORT opt, USHORT baud)
{
  DCB     dcb;
  HANDLE  hLoc;
  BOOL    Success;
  char    pName[] = "\\\\.\\COM\0\0\0";

  if (port > MAX_LINES) return 5;
  if (port < 10) pName[7] = '0' + port;
  else
   {
    pName[7] = '0' + port / 10;
    pName[8] = '0' + port % 10;
   }

  hLoc = CreateFile(
      pName,
      GENERIC_READ | GENERIC_WRITE,
      0,             // comm devices must be opened w/exclusive-access
      NULL,          // no security attributes
      OPEN_EXISTING, // comm devices must use OPEN_EXISTING
      0,
      NULL           // hTemplate must be NULL for comm devices
  );


  if (hLoc == INVALID_HANDLE_VALUE) return (2);

  Success = GetCommState(hLoc, &dcb);

  if (!Success)
   {
    CloseHandle(hLoc);
    return(3);
   }

  // Fill in the DCB

  dcb.BaudRate = baud;
  dcb.ByteSize = opt & 0x0f;
  switch (opt & 0xf0)
   {
    case 0x10: dcb.StopBits = ONESTOPBIT; break;
    case 0x20: dcb.StopBits = ONE5STOPBITS; break;
    case 0x30: dcb.StopBits = TWOSTOPBITS; break;
    default: dcb.StopBits = ONESTOPBIT; break;
   }

  switch (opt / 256)
   {
    case 0: dcb.Parity = NOPARITY; break;
    case 1: dcb.Parity = EVENPARITY; break;
    case 2: dcb.Parity = ODDPARITY; break;
    default: dcb.Parity = NOPARITY; break;
  }

  dcb.fParity         = 0;                      // enable parity checking
  dcb.fOutxCtsFlow    = 0;                      // CTS output flow control
  dcb.fOutxDsrFlow    = 0;                      // DSR output flow control
  dcb.fDtrControl     = DTR_CONTROL_DISABLE;    // DTR flow control type
  dcb.fDsrSensitivity = 0;                      // DSR sensitivity
  dcb.fTXContinueOnXoff = 0;                    // XOFF continues Tx
  dcb.fOutX           = 0;                      // XON/XOFF out flow control
  dcb.fInX            = 0;                      // XON/XOFF in flow control
  dcb.fErrorChar      = 0;                      // enable error replacement
  dcb.fNull           = 0;                      // enable null stripping
  dcb.fRtsControl     = RTS_CONTROL_DISABLE;    // RTS flow control
  dcb.fAbortOnError   = 0;                      // abort on error

  Success = SetCommState(hLoc, &dcb);

  if (!Success)
   {
    CloseHandle(hLoc);
    return(4);
   }

  hCom[port] = hLoc;

  return (0);

}


static BOOL PortNotOpen (byte port)
{
 return (hCom[port] == INVALID_HANDLE_VALUE);
}

static BOOL PortIsOpen (byte port)
{
 return (hCom[port] != INVALID_HANDLE_VALUE);
}

static void ClosePort(byte port)
{
 CloseHandle(hCom[port]);
}

static DWORD MinD (DWORD d1, DWORD d2)
{
    return (d1 < d2) ? d1 : d2;
}



