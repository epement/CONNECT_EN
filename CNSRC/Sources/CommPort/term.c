#include <windows.h>
#include <conio.h>
#include <stdio.h>

// service procedures

#define MAX_LINES 8             // Maximum number of COM lines

static HANDLE hCom[MAX_LINES];


void ResetAllHandles(void)      // invalidate all handles on entry
{
  int i;

  for (i = 0; i < MAX_LINES; i++ ) hCom[i] = INVALID_HANDLE_VALUE;
}

void CloseOneHandle(int i)
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


int OpenComPort (char port, USHORT baud, char bits,
                        char parity, char stopbits)
{
  DCB     dcb;
  HANDLE  hLoc;
  BOOL    Success;
  char    pName [] = "\\\\.\\COM\0\0\0";

  if (port > MAX_LINES) return 5;
  if (port < 10) pName[7] = '0' + port;
  else
   {
    pName[7] = '0' + port / 10;
    pName[8] = '0' + port % 10;
   }

  hLoc = CreateFile (
      pName,
      GENERIC_READ | GENERIC_WRITE,
      0,               // comm devices must be opened w/exclusive-access
      NULL,            // no security attributes
      OPEN_EXISTING,   // comm devices must use OPEN_EXISTING
      0,
      NULL             // hTemplate must be NULL for comm devices
  );


  if (hLoc == INVALID_HANDLE_VALUE) return (2);

  Success = GetCommState(hLoc, &dcb);

  if (!Success)
   {
    CloseHandle(hLoc);
    return (3);
   }

  // Fill in the DCB

  dcb.BaudRate = baud;
  dcb.ByteSize = bits;
  switch(stopbits)
   {
    case 1: dcb.StopBits = ONESTOPBIT; break;
    case 2: dcb.StopBits = ONE5STOPBITS; break;
    case 3: dcb.StopBits = TWOSTOPBITS; break;
    default: dcb.StopBits = ONESTOPBIT; break;
   }
  switch (parity)
   {
    case 'n':
    case 'N': dcb.Parity = NOPARITY; break;
    case 'e':
    case 'E': dcb.Parity = EVENPARITY; break;
    case 'o':
    case 'O': dcb.Parity = ODDPARITY; break;
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
    return (4);
   }

  hCom[port] = hLoc;

  return (0);
}


static BOOL PortNotOpen (char port)
{
 return (hCom[port] == INVALID_HANDLE_VALUE);
}

static BOOL PortIsOpen (char port)
{
 return (hCom[port] != INVALID_HANDLE_VALUE);
}

static void ClosePort(char port)
{
 CloseHandle (hCom[port]);
}

static DWORD MinD (DWORD d1, DWORD d2)
{
 return (d1 < d2) ? d1 : d2;
}


int ReadComPort(char port, int ToRead, PCHAR Buffer)
{

  DWORD   lpErr;
  COMSTAT lpStat;

  DWORD   Actual,toGet;
  BOOL    Success;

  Actual = 0;
  Success = ClearCommError(hCom[port], &lpErr, &lpStat);
  toGet = MinD(ToRead, lpStat.cbInQue);

  if (Success && (toGet > 0))
   {
     Success = ReadFile(hCom[port], Buffer, toGet, &Actual, NULL);
   }
  if (!Success) Actual = 0;
  return Actual;

}


int WriteComPort(char port, int ToWrite, PCHAR Buffer)
{
  DWORD   Actual;
  BOOL    Success;

  Success = WriteFile(hCom[port], Buffer, ToWrite, &Actual, NULL);
  if (!Success) Actual = 0;
  return Actual;
}

void CloseComPort(char port)
{
 CloseOneHandle(port);
}

void PortCtl(char port, DWORD Ctl)
{
 EscapeCommFunction(hCom[port], Ctl);
}


void main(void)
{
 char cc, ccc;

 if (OpenComPort(1, 4800, 8, 'N', 1) == 0)
  {
   do
    {
     if (kbhit())
      {
       cc = getch();
       WriteComPort(1, 1, &cc);
      }
     if (ReadComPort(1, 1, &ccc) > 0) putch(ccc);
     Sleep(1);
    }
   while (1); /* (cc != 27); */
   CloseComPort(1);
  }
}
