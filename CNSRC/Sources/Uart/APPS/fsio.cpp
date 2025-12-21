// fSio.cpp
//
// C++ class wrapper for WSC.
//
// See HELLO.CPP for an example of use.
//

#include <windows.h>
#include <iostream.h>

#include "fSio.h"

// constructor

fSio::fSio(void)
{
};

// destructor

fSio::~fSio(void)
{
};

// Serial I/O (SIO) functions

int fSio::fSioReset(int Port, int InQueue, int OutQueue)
{
 return SioReset(Port,InQueue,OutQueue);
}

int fSio::fSioDone(int Port)
{
 return SioDone(Port);
}

int fSio::fSioBaud(int Port, unsigned BaudRate)
{
 return SioBaud(Port, BaudRate);
}

int fSio::fSioPutc(int Port, char Byte)
{
 return SioPutc(Port, Byte);
}

int fSio::fSioPuts(int Port, LPSTR Buffer, unsigned Size)
{
 return SioPuts(Port, Buffer, Size);
}

int fSio::fSioGetc(int Port)
{
 return SioGetc(Port);
}

int fSio::fSioGets(int Port,LPSTR Buffer,unsigned Size)
{
 return SioGets(Port, Buffer, Size);
}

int fSio::fSioDTR(int Port,char Cmd)
{
 return SioDTR(Port, Cmd);
}

int fSio::fSioRTS(int Port,char Cmd)
{
 return SioRTS(Port, Cmd);
}

int fSio::fSioTxClear(int Port)
{
 return SioTxClear(Port);
}

int fSio::fSioRxClear(int Port)
{
 return SioRxClear(Port);
}

int fSio::fSioTxQue(int Port)
{
 return SioTxQue(Port);
}

int fSio::fSioRxQue(int Port)
{
 return SioRxQue(Port);
}

int fSio::fSioStatus(int Port, unsigned Mask)
{
 return SioStatus(Port, Mask);
}

int fSio::fSioFlow(int Port,char Cmd)
{
 return SioFlow(Port, Cmd);
}

int fSio::fSioParms(int Port,int Parity,int StopBits,int DataBits)
{
 return SioParms(Port, Parity, StopBits, DataBits);
}

int fSio::fSioCTS(int Port)
{
 return SioCTS(Port);
}

int fSio::fSioDSR(int Port)
{
 return SioDSR(Port);
}

int fSio::fSioRI(int Port)
{
 return SioRI(Port);
}

int fSio::fSioDebug(int Parm)
{
 return SioDebug(Parm);
}

int fSio::fSioInfo(char Parm)
{
 return SioInfo(Parm);
}

int fSio::fSioDCD(int Port)
{
 return SioDCD(Port);
}

int fSio::fSioBrkSig(int Port, char Cmd)
{
 return SioBrkSig(Port, Cmd);
}

int fSio::fSioUnGetc(int Port, char Chr)
{
 return SioUnGetc(Port, Chr);
}

int fSio::fSioWinError(LPSTR Buffer, int Size)
{
 return SioWinError(Buffer, Size);
}

int fSio::fSioRead(int Port, int Reg)
{
 return SioRead(Port, Reg);
}

DWORD fSio::fSioTimer(void)
{
 return fSioTimer();
}

int fSio::fSioEvent(int Port, DWORD Mask)
{
 return SioEvent(Port, Mask);
}

int fSio::fSioMessage(int Port, HWND hMsgWnd, WORD MsgCode, DWORD Mask)
{
 return SioMessage(Port, hMsgWnd, MsgCode, Mask);
}

int fSio::fSioKeyCode(ULONG KeyCode)
{
 return SioKeyCode(KeyCode);
}

int fSio::fSioGetReg(LPSTR Buffer, int Size)
{
 return SioGetReg(Buffer, Size);
}

int fSio::fSioSetInteger(int Port, int ParmName, ULONG ParmValue)
{
 return SioSetInteger(Port, ParmName, ParmValue);
}
