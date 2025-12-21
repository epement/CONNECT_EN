#include <windows.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include "m_types.h"
#include "madli.h"


enum mdata {mdCmd, mdAddr, mdData, mdChk, md_num};
enum sdata {mdState, mdDataLo, mdDataHi, mdSChk, mdS_num};

const char * const mErr_str[] =
{"Ok", "Echo timeout", "Echo mismatch", "Reply timeout",
 "Checksum mismatch", "EE data mismatch", "COM error",
 "Packet incomplete"};

#define mhGrp       1
#define mhAddr      2
#define mhBcstAddr  4
#define mhBcstGrp   8
#define mEELock     0x55
#define mEEUnLock   0xaa


HANDLE OpenComPort(word port, USHORT baud, byte bits,
                        char parity, byte stopbits, pbyte res)
{
  DCB     dcb;
  HANDLE  hLoc;
  char    pName[] = "\\\\.\\COM\0\0\0\0\0\0\0";

  itoa(port, &pName[7], 10);

  hLoc = CreateFile (
      pName,
      GENERIC_READ | GENERIC_WRITE,
      0,               // comm devices must be opened w/exclusive-access
      NULL,            // no security attributes
      OPEN_EXISTING,   // comm devices must use OPEN_EXISTING
      0,
      NULL             // hTemplate must be NULL for comm devices
  );


  if (hLoc == INVALID_HANDLE_VALUE)
   {
    *res = 2;
    return INVALID_HANDLE_VALUE;
   }

  if (!GetCommState(hLoc, &dcb))
   {
    CloseHandle(hLoc);
    *res = 3;
    return INVALID_HANDLE_VALUE;
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

  dcb.fParity           = 0;                    // enable parity checking
  dcb.fOutxCtsFlow      = 0;                    // CTS output flow control
  dcb.fOutxDsrFlow      = 0;                    // DSR output flow control
  dcb.fDtrControl       = DTR_CONTROL_DISABLE;  // DTR flow control type
  dcb.fDsrSensitivity   = 0;                    // DSR sensitivity
  dcb.fTXContinueOnXoff = 0;                    // XOFF continues Tx
  dcb.fOutX             = 0;                    // XON/XOFF out flow control
  dcb.fInX              = 0;                    // XON/XOFF in flow control
  dcb.fErrorChar        = 0;                    // enable error replacement
  dcb.fNull             = 0;                    // enable null stripping
  dcb.fRtsControl       = RTS_CONTROL_DISABLE;  // RTS flow control
  dcb.fAbortOnError     = 0;                    // abort on error

  if (!SetCommState(hLoc, &dcb))
   {
    CloseHandle(hLoc);
    *res = 4;
    return INVALID_HANDLE_VALUE;
   }

  *res = 0;
  return hLoc;
}


static BOOL PortNotOpen(HANDLE port)
{
 return (port == INVALID_HANDLE_VALUE);
}

static BOOL PortIsOpen(HANDLE port)
{
 return (port != INVALID_HANDLE_VALUE);
}

static void ClosePort(HANDLE port)
{
 CloseHandle(port);
}

static DWORD MinD (DWORD d1, DWORD d2)
{
 return (d1 < d2) ? d1 : d2;
}

int ReadComPort(HANDLE port, int ToRead, PCHAR Buffer)
{
  DWORD   lpErr;
  COMSTAT lpStat;
  DWORD   Actual,toGet;
  BOOL    Result;

  Actual = 0;
  Result = ClearCommError(port, &lpErr, &lpStat);
  toGet = MinD(ToRead, lpStat.cbInQue);

  if (Result && (toGet > 0))
    Result = ReadFile(port, Buffer, toGet, &Actual, NULL);
  if (!Result) Actual = 0;
  return Actual;
}

int WriteComPort(HANDLE port, int ToWrite, PCHAR Buffer)
{
  DWORD   Actual;
  BOOL    Result;

  Result = WriteFile(port, Buffer, ToWrite, &Actual, NULL);
  if (!Result) Actual = 0;
  return Actual;
}

void CloseComPort(HANDLE port)
{
  CloseHandle(port);
}

void PortCtl(HANDLE port, DWORD Ctl)
{
 EscapeCommFunction(port, Ctl);
}

int GetCharTimeout(HANDLE port, DWORD timeout_ms)
{
 DWORD   time;
 DWORD   lpErr;
 COMSTAT lpStat;
 DWORD   Actual;
 BOOL    Result;
 int     result = -1;

 Actual = 0;
 time =  GetTickCount();
 do
  {
   Result = ClearCommError(port, &lpErr, &lpStat);
   if (Result && (lpStat.cbInQue > 0))
     Result = ReadFile(port, &result, 1, &Actual, NULL);
   if (Result && (Actual == 1)) return result;
  }
 while ((GetTickCount() - time) > timeout_ms);
 return result;
}


bool mSendPkt(HANDLE port, byte Cmd, byte Group,
              word bAddr, byte data, byte* mError)
{
 DWORD   time;
 DWORD   lpErr;
 COMSTAT lpStat;
 DWORD   Actual;
 BOOL    Result;
 byte    mEc_pkt[md_num];
 byte    mTx_pkt[md_num];
 byte    ch;
 byte    midx;

 *mError = meOk;
 /* Clear receiver */
 Actual = 0;
 do
  {
   Result = ClearCommError(port, &lpErr, &lpStat);
   if (Result && (lpStat.cbInQue > 0))
    ReadFile(port, &ch, 1, &Actual, NULL);
  }
 while (lpStat.cbInQue > 0);
 timeBeginPeriod(1);

 /* Send packet */
 if (Group == 0) ch = mTx_pkt[mdCmd] = (Cmd << 3) | ((bAddr / 256) & 3);
 else ch = mTx_pkt[mdCmd] = (Cmd << 3) | 4;
 ch += mTx_pkt[mdAddr] = bAddr % 256;
 ch += mTx_pkt[mdData] = data;
 mTx_pkt[mdChk] = ch & ~0x80;

 time =  GetTickCount();
 Result = WriteFile(port, &mTx_pkt, md_num, &Actual, NULL);
 if (!Result || (Actual != md_num))
  {
   *mError = meCommErr;
   goto Exit;
  }

 /* Wait for received byte */
 do
  {
   Result = ClearCommError(port, &lpErr, &lpStat);
   if (!Result)
    {
     *mError = meCommErr;
     goto Exit;
    }
   if ((GetTickCount() - time) > 30)
    {
     *mError = meEchoTimeout;
     goto Exit;
    }
   Sleep(1);
  }
 while (lpStat.cbInQue < md_num);

 /* Receive echo */
 for(midx = 0; midx < md_num; midx++)
  {
   Result = ClearCommError(port, &lpErr, &lpStat);
   if (Result && (lpStat.cbInQue > 0))
     Result = ReadFile(port, &mEc_pkt[midx], 1, &Actual, NULL);
   else Sleep(1);
   if (!Result && (Actual != 1))
    {
     *mError = meCommErr;
     goto Exit;
    }

   if ((GetTickCount() - time) > 30)
    {
     *mError = meEchoTimeout;
     goto Exit;
    }

   if (mEc_pkt[midx] != mTx_pkt[midx])
    {
     *mError = meEchoMismatch;
     goto Exit;
    }

  }
 Exit:
  timeEndPeriod(1);
  return (*mError == 0);
}

bool mReceivePkt(HANDLE port, DWORD timeout_ms, byte* state,
                 word* data, byte* mError)
{
 DWORD   time;
 DWORD   lpErr;
 COMSTAT lpStat;
 DWORD   Actual;
 BOOL    Result;
 byte    mRx_pkt[md_num];
 byte    ch;
 byte    midx;

 *mError = meOk;
 timeBeginPeriod(1);
 time = GetTickCount();

 /* Wait for received byte */
 do
  {
   Result = ClearCommError(port, &lpErr, &lpStat);
   if (!Result)
    {
     *mError = meCommErr;
     goto Exit;
    }
   if ((GetTickCount() - time) > timeout_ms)
    {
     *mError = meReplyTimeout;
     goto Exit;
    }
   Sleep(1);
  }
 while (lpStat.cbInQue < md_num);

 /* Receive packet */
 ch = 0;
 for(midx = 0; midx < md_num; midx++)
  {
   Result = ClearCommError(port, &lpErr, &lpStat);
   if (Result && (lpStat.cbInQue > 0))
     Result = ReadFile(port, &mRx_pkt[midx], 1, &Actual, NULL);
   else Sleep(1);
   if (!Result && (Actual != 1))
    {
     *mError = meCommErr;
     goto Exit;
    }
   if (midx < md_num - 1) ch += mRx_pkt[midx];

   if ((GetTickCount() - time) > timeout_ms)
    {
     if (midx > 0) *mError = meCollision;
     else *mError = meReplyTimeout;
     goto Exit;
    }
  }

 if ((mRx_pkt[mdChk] & 0x7f) != (ch & 0x7f))
  {
   *mError = meChecksumMismatch;
   goto Exit;
  }

 if (state != NULL) *state = mRx_pkt[mdState];
 if (data != NULL) *data = mRx_pkt[mdDataLo] + mRx_pkt[mdDataHi] * 256;

 Exit:
  timeEndPeriod(1);
  return (*mError == 0);
}

void Delay(DWORD ms)
{
  timeBeginPeriod(1);
  Sleep(ms);
  timeEndPeriod(1);
}

bool GetRam(HANDLE port, word bAddr, byte ram, byte* state,
            word* data, byte* mError)
{
 bool Result;

 Result = mSendPkt(port, mcmGetRam, 0, bAddr, ram, mError);
 if (Result) Result = mReceivePkt(port, 30, state, data, mError);
 return Result;
}

bool GetRamBlock(HANDLE port, word bAddr, byte count,
                 byte* state, word data[], byte* mError, progress pr_fn)
{
 int i;
 bool Result;

 for(i = 0; i < count; i++)
  {
   Result = mSendPkt(port, mcmGetRam, 0, bAddr, i, mError);
   if (Result) Result = mReceivePkt(port, 30, state, &data[i], mError);
   if (!Result) return FALSE;
   if ((pr_fn != NULL) && (!pr_fn(i, count))) return FALSE;
  }
 return Result;
}

bool GetEE(HANDLE port, word bAddr, byte ram, word* data, byte* mError)
{
 bool Result;

 if (mSendPkt(port, mcmGetEE, 0, bAddr, ram, mError))
   Result = mReceivePkt(port, 30, NULL, data, mError);
 return Result;
}

bool GetEEBlock(HANDLE port, word bAddr, byte count,
                word data[], byte* mError, progress pr_fn)
{
 int i;
 bool Result;

 for(i = 0; i < count; i++)
  {
   Result = mSendPkt(port, mcmGetEE, 0, bAddr, i, mError);
   if (Result) Result = mReceivePkt(port, 30, NULL, &data[i], mError);
   if (!Result) return FALSE;
   if ((pr_fn != NULL) && (!pr_fn(i, count))) return FALSE;
  }
 return Result;
}

bool SetEE(HANDLE port, byte Group, word bAddr, byte ee,
            byte data, byte* mError)
{
 bool Broadcast;
 word UnLockTime;
 word eeData;
 bool Result;

 Broadcast = ((Group != 0) || (bAddr == 1023));

 Result = mSendPkt(port, mcmLock, Group, bAddr, mEEUnLock, mError);
 if (!Result) return FALSE;
 if (!Broadcast) Result = mReceivePkt(port, 30, NULL, &UnLockTime, mError);
 else Delay(30);
 if (!Result) return FALSE;

 Result = mSendPkt(port, mcmSetEEaddr, Group, bAddr, ee, mError);
 if (!Result) return FALSE;
 if (!Broadcast) Result = mReceivePkt(port, 30, NULL, &UnLockTime, mError);
 else Delay(30);
 if (!Result) return FALSE;

 Result = mSendPkt(port, mcmSetEEdata, Group, bAddr, data, mError);
 if (!Broadcast) Result = mReceivePkt(port, 80, NULL, &eeData, mError);
 else Delay(50);
 if (!Result) return FALSE;

 Result = mSendPkt(port, mcmLock, Group, bAddr, mEELock, mError);
 if (!Result) return FALSE;
 if (!Broadcast) Result = mReceivePkt(port, 30, NULL, &UnLockTime, mError);
 else Delay(30);
 if (!Result) return FALSE;

 if ((byte)eeData != data)
  {
   *mError = meEE_Mismatch;
   return FALSE;
  }
 else return TRUE;
}

bool SetEEBlock(HANDLE port, byte Group, word bAddr, byte count,
                 byte data[], byte* mError, progress pr_fn)
{
 int i;
 bool Broadcast;
 word UnLockTime;
 word eeData;
 bool Result;

 UnLockTime = 0;
 Broadcast = ((Group != 0) || (bAddr == 1023));

 for(i = 0; i < count; i++)
  {
   if (UnLockTime < 10)
    {
     Result = mSendPkt(port, mcmLock, Group, bAddr, mEEUnLock, mError);
     if (!Result) return FALSE;
     if (!Broadcast) Result = mReceivePkt(port, 30, NULL, &UnLockTime, mError);
     else Delay(30);
     if (!Result) return FALSE;
    }

   Result = mSendPkt(port, mcmSetEEaddr, Group, bAddr, i, mError);
   if (!Result) return FALSE;
   if (!Broadcast) Result = mReceivePkt(port, 30, NULL, &UnLockTime, mError);
   else Delay(30);
   if (!Result) return FALSE;

   Result = mSendPkt(port, mcmSetEEdata, Group, bAddr, data[i], mError);
   if (!Broadcast) Result = mReceivePkt(port, 80, NULL, &eeData, mError);
   else Delay(50);
   if (!Result) return FALSE;

   if ((byte)eeData != data[i])
    {
     *mError = meEE_Mismatch;
     return FALSE;
    }

   if ((pr_fn != NULL) && (!pr_fn(i, count))) return FALSE;
  }
 Result = mSendPkt(port, mcmLock, Group, bAddr, mEELock, mError);
 if (!Result) return FALSE;
 if (!Broadcast) Result = mReceivePkt(port, 30, NULL, &UnLockTime, mError);
 else Delay(30);
 if (!Result) return FALSE;

 return TRUE;
}

bool bSwitch(HANDLE port, byte Group, word bAddr, byte cmd,
             byte dimm, byte* mError)

{
 bool Broadcast;
 word UnLockTime;
 word eeData;
 bool Result;

 Broadcast = ((Group != 0) || (bAddr == 1023));

 Result = mSendPkt(port, cmd, Group, bAddr, dimm, mError);
 if (!Result) return FALSE;
 if (!Broadcast) Result = mReceivePkt(port, 30, NULL, NULL, mError);
 if (!Result) return FALSE;
 Delay(30);
 Result = mSendPkt(port, cmd, Group, bAddr, dimm, mError);
 if (!Result) return FALSE;
 if (!Broadcast) Result = mReceivePkt(port, 60, NULL, NULL, mError);
 else Delay(50);
 if (!Result) return FALSE;
 return TRUE;
}

bool SetBallAddr(HANDLE port, word bAddr, byte* mError)
{
 bool Result;

 Result = mSendPkt(port, mcmLock, 0, 1023, mEEUnLock, mError);
 if (!Result) return FALSE;
 Delay(30);
 Result = mSendPkt(port, mcmSetAddr, 0, bAddr, mEEUnLock, mError);
 if (!Result) return FALSE;
 Delay(20);
 Result = mSendPkt(port, mcmWriteAddr, 0, bAddr, mEELock, mError);
 if (!Result) return FALSE;
 if (bAddr != 1023) Result = mReceivePkt(port, 60, NULL, NULL, mError);
 return Result;
}

bool SetBallGroup(HANDLE port, word bAddr, byte GrNum,
                  byte GrAddr, byte* mError)
{
 word UnLockTime;
 bool Result;

 Result = mSendPkt(port, mcmLock, 0, bAddr, mEEUnLock, mError);
 if (!Result) return FALSE;
 Result = mReceivePkt(port, 30, NULL, &UnLockTime, mError);
 if (!Result) return FALSE;

 Result = mSendPkt(port, mcmSetGrp0 + GrNum, 0, bAddr, GrAddr, mError);
 if (!Result) return FALSE;
 Result = mReceivePkt(port, 30, NULL, NULL, mError);
 if (!Result) return FALSE;

 Result = mSendPkt(port, mcmLock, 0, bAddr, mEELock, mError);
 if (!Result) return FALSE;
 Result = mReceivePkt(port, 30, NULL, &UnLockTime, mError);
 if (!Result) return FALSE;

 return TRUE;
}



