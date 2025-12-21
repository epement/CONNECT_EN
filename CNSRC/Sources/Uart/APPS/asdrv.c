//
//  --- asdrv.c  ---
//
//  Copyright(C) 1997-2004 by MarshallSoft Computing, Inc.
//  All rights are reserved.
//
//  This module sends or recieves ASCII files. This code is implemented
//  as a state driver, similar to the XMODEM & YMODEM driver (XYM).
//
//  Note that the receiving side must be started BEFORE the sending side.
//
//  To use this (example code) module, do the following:
//
//  (1) Call ascInit(Port,RxQueSize,xFlag) to perform initialization, where
//            Port = The connected port (COM1, COM2, etc).
//       RxQueSize = The size of the Rx Queue as passed to SioReset().
//           xFlag = TRUE if this module will perform XON/XOFF flow control.
//                   Set to FALSE if flow control is being performed by the
//                   WSC code (you called SioFlow()).
//
//  (2) To send an ASCII file, call
//      ascStartTx(FileName,CharPace,TermChar,EchoFlag), where
//         FileName = The path & name of the file to send.
//         CharPace = The delay in milliseconds between characters.
//         TermChar = The termination character to send after the file
//                    has been sent. If none, use 0x00.
//         EchoFlag = TRUE if screen echo is desired.
//      Then call ascDriver() until it returns IDLE (TRUE).
//
//  (3) To receive an ASCII file, call
//      ascStartRx(FileName,TermChar,CharWait,EchoFlag), where
//         FileName = The path & name of the file to send.
//         TermChar = The termination character. If none, use 0x00.
//        FirstWait = The maximum number of seconds to wait for the
//                    first incoming character.
//         CharWait = The maximum number of seconds after which it is
//                    assumed that the other side has completed sending.
//                    If unsure, set this to 3 seconds.
//         EchoFlag = TRUE if screen echo is desired.
//      Then call ascDriver() until it returns IDLE (TRUE).
//
//  See example of use in TERM example application program.
//

#define DEBUG   0
#define DEBUG_X 0

#include <windows.h>
#include "wsc.h"
#include "ascodes.h"
#include "ascii.h"
#include "asdrv.h"
#include "paint.h"

#define ULONG unsigned long
#define MIN(a,b) ((a<=b)?(a):(b))
#define MAX(a,b) ((a>=b)?(a):(b))

//// ascDriver functions & variables

static char Temp[256]; // temporary buffer

#define BUFFER_SIZE 512

//// ascDriver state variables ////

static ULONG ascFileSize;       // file size
static ULONG ascCharCount;      // # chars sent or received
static ULONG ascMarkTime;       // time last char received
static ULONG ascSendTime;       // time to send next char
static ULONG ascCharWait;       // max ms before assuming sender is done
static ULONG ascFirstWait;      // max wait (ms) for first inmcoming char
static int ascActive=FALSE;     // TRUE if initialized
static int ascBufferSize;       // # bytes in ascBuffer
static int ascBufferIndex;      // index to next char
static int ascErrorCode;        // last error code
static int ascErrorState;       // state in which last error occured
static int ascHandle;           // file Handle
static int ascPort;             // serial port
static int ascState;            // current driver state
static int ascLastState;        // last driver state
static int ascStateCount;       // # times last state called
static int ascCharPace;         // ms delay after sending each char
static int ascEchoFlag;         // echo flag
static int ascLastXchar;        // last XON/XOFF received
static int ascLowWater;         // RX buffer low water mark
static int ascHighWater;        // RX buffer high water mark
static int ascMaxBurst;         // # chars to send in burst
static int ascXflag;            // perform XON/XOFF flow control if true
static char ascTermChar;        // termination char (0x00 => none)
static char ascFileName[64];    // filename buffer
static char ascBuffer[BUFFER_SIZE+1]; // disk buffer

//// private functions ////

// get file length

static long FileLength(int Handle)
{long lCurrentPos = _llseek(Handle,0L,1);
 long lFileLength = _llseek(Handle,0L,2);
 _llseek(Handle,lCurrentPos,0);
 return lFileLength;
}

// set error state

static int SetError(int Code)
{int i;
 ascErrorCode = Code;
 ascErrorState = ascState;
 ascState = ASC_IDLE;
 if(Code!=ASC_NO_ERROR) for(i=0;i<6;i++) SioPutc(ascPort,CAN);
 SioRxClear(ascPort);
 if(Code)
   {wsprintf((LPSTR)Temp,"ascDriver: Error=%d ascLastState=%d ascStateCount=%d\n",
       Code,ascLastState,ascStateCount);
    DisplayLine((LPSTR)Temp);
   }
 return(Code);
}

// report sending or receiving XON

void ReportXON(void)
{
#if DEBUG_X
 wsprintf((LPSTR)Temp,"[XON]");
 DisplayString((LPSTR)Temp);
#endif
}

// report sending or receiving XOFF

void ReportXOFF(void)
{
#if DEBUG_X
 wsprintf((LPSTR)Temp,"[XOFF]");
 DisplayString((LPSTR)Temp);
#endif
}

// time to send XOFF ?

static void XON_Test(int LowWater)
{// do we need to send XON ?
 if(ascLastXchar==XOFF)
    {if(SioRxQue(ascPort) <= LowWater)
       {SioPutc(ascPort,(char)XON);
        ascLastXchar = XON;
        ReportXON();
       }
    }
}

// time to send XOFF ?

static void XOFF_Test(int HighWater)
{// do we need to send XOFF ?
 if(ascLastXchar==XON)
   {if(SioRxQue(ascPort) >= HighWater)
      {SioPutc(ascPort,(char)XOFF);
       ascLastXchar = XOFF;
       ReportXOFF();
      }
   }
}

//// public functions ////

// abort current file transfer

int ascAbort(void)
{int i;
 _lclose(ascHandle);
 DisplayLine("Aborting...\n");
 ascErrorCode = ASC_NO_ERROR;
 ascErrorState = 0;
 ascState = ASC_IDLE;
 for(i=0;i<6;i++) if(SioPutc(ascPort,CAN)==-1) break;
 SioRxClear(ascPort);
 return(0);
}

// get (last) error code

int ascGetErrorCode(void)
{ascDriver();
 return( ascErrorCode );
}

// get (last) error state

int ascGetErrorState(void)
{ascDriver();
 return( ascErrorState );
}

// get name of file being transfered

LPSTR ascGetFileName(void)
{ascDriver();
 return( ascFileName );
}

// get current value of state variable

int ascGetState(void)
{ascDriver();
 return( ascState );
}

// get file length of file being transfered

long ascGetFileLength()
{ascDriver();
 return( ascFileSize );
}

// get total # bytes sent or received

long ascGetCharCount()
{ascDriver();
 return( ascCharCount );
}

// initialize this module

void ascInit(int Port,       // port
             int RxQueSize,  // RX queue size
             int xFlag)      // do XON/XOFF ?
{
#if DEBUG
 wsprintf((LPSTR)Temp,"ascInit: Port=COM%d, xFlag=%d\n",Port+1,xFlag);
 DisplayLine((LPSTR)Temp);
 ascLastState = -1;
 ascStateCount = 0;
#endif
 ascActive = TRUE;
 ascPort = Port;
 ascMaxBurst = 128;
 ascLowWater = ascMaxBurst + 32;
 ascHighWater = RxQueSize - ascLowWater;
#if DEBUG
 wsprintf((LPSTR)Temp,"RxQueSize=%d, LowWater=%d, HiWater=%d",
   RxQueSize,ascLowWater,ascHiWater);
 DisplayLine((LPSTR)Temp);
#endif
 ascState = ASC_IDLE;
 ascHandle = -1;
 ascFileName[0] = '\0';
 ascErrorCode = ASC_NO_ERROR;
 ascCharWait = 10000; // 10 secs
 ascXflag = xFlag;
}

// initiate file transmission

void ascStartTx(LPSTR FileName, // File name
                int   CharPace, // char pace in ms
                char  TermChar, // termination char
                int   EchoFlag) // echo flag
{
#if DEBUG
 wsprintf((LPSTR)Temp,"ascStartTx:FileName='%s' TermChar='%c' EchoFlag=%d\n",
    FileName,TermChar,EchoFlag);
 DisplayLine((LPSTR)Temp);
#endif
 ascErrorCode = ASC_NO_ERROR;
 ascErrorState = 0;
 lstrcpy((LPSTR)ascFileName,(LPSTR)FileName);
 ascState = TX_START;
 ascFileSize = 0;
 ascCharPace = CharPace;
 ascTermChar = TermChar;
 ascEchoFlag = EchoFlag;
 ascLastXchar = XON;
 ascCharCount = 0L;
}// ascStartTx

// initiate file reception

void ascStartRx(LPSTR FileName, // File name
                char TermChar,  // termination char
                int FirstWait,  // wait for 1st incoming character
                int CharWait,   // max wait (secs) before assume done
                int EchoFlag)   // echo flag
{
#if DEBUG
 wsprintf((LPSTR)Temp,"ascStartRx:FileName='%s' RxQueSize=%d TermChar='%c' EchoFlag=%d\n",
    FileName,RxQueSize,TermChar,EchoFlag);
 DisplayLine((LPSTR)Temp);
#endif
 ascErrorCode = ASC_NO_ERROR;
 ascErrorState = 0;
 lstrcpy((LPSTR)ascFileName,(LPSTR)FileName);
 ascState = RX_START;
 ascFileSize = 0;
 ascTermChar = TermChar;
 ascEchoFlag = EchoFlag;
 ascLastXchar = XON;
 ascCharCount = 0L;
 ascFirstWait = 1000L * (ULONG) (FirstWait);
 ascCharWait = 1000L * (ULONG) (CharWait);
}// end ascStartRx

// execute next state

int ascDriver()
{int  i, n;
 char c;
 LPSTR Ptr;
 int Code; // return code
 // start
 if(!ascActive)
    {SetError(ASC_NOT_ACTIVE_ERROR);
     return TRUE;
    }
#if DEBUG
  if(ascLastState!=ascState)
    {wsprintf((LPSTR)Temp,"%ld: State = %d\n",GetTickCount(),ascState);
     DisplayLine((LPSTR)Temp);
    }
#endif
#if 0
 wsprintf((LPSTR)Temp,"{%d}",ascState);
 DisplayString((LPSTR)Temp);
#endif

 if(ascLastState==ascState) ascStateCount++;
 else
   {ascStateCount = 1;
    ascLastState = ascState;
   }
 // process according to state
 switch(ascState)
   {case ASC_IDLE:

      // return TRUE for IDLE
      return TRUE;

      //// Transmit states ////

    case TX_START:
      ascCharCount = 0;
      // fall thru

    case TX_NEWFILE:

      ascHandle = _lopen((LPSTR)&ascFileName[0],OF_READ|OF_SHARE_DENY_WRITE);
      if(ascHandle<0)
        {SetError(ASC_NOT_OPEN_ERROR);
         return TRUE;
        }
      ascFileSize = FileLength(ascHandle);
      // clear comm port
      SioRxClear(ascPort);
      ascState = TX_READ_DISK;
      break;

    case TX_READ_DISK:

      // read next block from disk
      Code = _lread(ascHandle,ascBuffer,BUFFER_SIZE);
      if(Code<0)
        {SetError(ASC_DISK_READ_ERROR);
         return TRUE;
        }
      if(Code==0) ascState = TX_DONE;
      else
        {ascBufferSize = Code;
         ascBufferIndex = 0;
         if(ascXflag) ascState = TX_WAIT4_XON;
         else ascState = TX_SEND_DATA;
        }
      break;

    case TX_WAIT4_XON:

      // wait for XON ?
      if(ascLastXchar==XOFF)
        {Code = SioGetc(ascPort);
         if(Code==WSC_NO_DATA) break;
         if(Code<0)
           {// error
            SetError(Code);
            return TRUE;
           }
         if((char)Code==XON)
           {ascLastXchar = XON;
            ReportXON();
            ascState = TX_SEND_DATA;
            break;
           }
         if((char)Code==CAN)
           {ascState = ASC_IDLE;
            break;
           }
        }
      else ascState = TX_SEND_DATA;
      break;

    case TX_SEND_DATA:

      // send burst
      n = MIN(ascMaxBurst,ascBufferSize-ascBufferIndex);
      for(i=0;i<n;i++)
        {// send byte
         c = ascBuffer[ascBufferIndex++];
         SioPutc(ascPort,c);
         if(ascEchoFlag) DisplayChar(c);
         ascCharCount++;
        }
      // buffer empty ?
      if(ascBufferIndex==ascBufferSize) ascState = TX_READ_DISK;
      else
        {ascSendTime = GetTickCount() + (long)ascCharPace;
         ascState = TX_PACE;
        }
      if(!ascXflag) break;
      // check for incoming XON or XOFF
      Code = SioGetc(ascPort);
      if((Code!=WSC_NO_DATA)&&(Code<0))
        {// got error
         SetError(Code);
         return TRUE;
        }
      if(Code==XON)
        {if(ascLastXchar==XOFF) ascLastXchar = (char)XON;
         ReportXON();
        }
      if(Code==XOFF)
        {if(ascLastXchar==XON) ascLastXchar = (char)XOFF;
         ReportXOFF();
        }
      break;

    case TX_PACE:

      // ready to send next character ?
      if(GetTickCount() < ascSendTime) break;
      if(ascXflag) ascState = TX_WAIT4_XON;
      else ascState = TX_SEND_DATA;
      break;

    case TX_DONE:

      // transmission is done
      if(ascTermChar) SioPutc(ascPort,ascTermChar);
      _lclose(ascHandle);
      wsprintf((LPSTR)Temp,"/// %d bytes transmitted", ascCharCount);
      DisplayLine((LPSTR)Temp);
      ascState = ASC_IDLE;
      break;

    //// Receive states ////

    case RX_START:

      // clear comm port
      SioRxClear(ascPort);
      ascState = RX_OPEN_FILE;
      ascCharCount = 0;
      break;

    case RX_OPEN_FILE:

      // open file passed in FileName[] for write
      ascHandle = _lcreat((LPSTR)&ascFileName[0],0);
      if(ascHandle<0)
        {SetError(ASC_CANNOT_OPEN_ERROR);
         return TRUE;
        }
      ascMarkTime = GetTickCount();
      ascBufferIndex = 0;
      ascState = RX_READY;
      break;

    case RX_READY:

      // await first incoming byte
      if(SioRxQue(ascPort)>0)
        {ascState = RX_GET_DATA;
         ascMarkTime = GetTickCount();
         break;
        }
      if(GetTickCount() > ascMarkTime + ascFirstWait) ascState = RX_DONE;
      break;

    case RX_GET_DATA:

      // get data from other side
      if(ascXflag)
        {XON_Test(ascLowWater);
         XOFF_Test(ascHighWater);
        }
      n = 0;
      Ptr = (LPSTR) &ascBuffer[ascBufferIndex];
      // gather up all there is
      for(i=0;i<BUFFER_SIZE;i++)
        {Code = SioGetc(ascPort);
         if(Code==WSC_NO_DATA)
           {// byte not ready
            if(GetTickCount() > ascMarkTime + ascCharWait) ascState = RX_DONE;
            if(ascXflag) XON_Test(ascLowWater);
            break;
           }
         if(Code<0)
           {// error
            SetError(Code);
            return TRUE;
           }
         c = (char)Code;
         // received char (Code>=0)
         if(c==ascTermChar)
           {// got termination character
            ascState = RX_DONE;
            break;
           }
         if(Code==CAN)
           {DisplayLine("Cancelled by sender\n");
            ascState = RX_DONE;
            break;
           }
         // save data in buffer
         ascBuffer[ascBufferIndex++] = c;
         n++; ascCharCount++;
         if(ascBufferIndex>=BUFFER_SIZE) break;
        } // end for(i)
      if(n>0)
        {ascMarkTime = GetTickCount();
         if(ascEchoFlag) WriteTheString(Ptr,n);
        }
      if(ascBufferIndex>0) ascState = RX_WRITE_DISK;
      if(ascXflag)
        {XOFF_Test(ascHighWater);
         XON_Test(ascLowWater);
        }
      break;

    case RX_WRITE_DISK:

      // write buffer to disk
      _lwrite(ascHandle,ascBuffer,ascBufferIndex);
      ascBufferIndex = 0;
      ascMarkTime = GetTickCount();
      ascState = RX_GET_DATA;
      break;

    case RX_DONE:

      // file received
      if(ascBufferIndex) _lwrite(ascHandle,ascBuffer,ascBufferIndex);
      wsprintf((LPSTR)Temp,"/// %d bytes received", ascCharCount);
      DisplayLine((LPSTR)Temp);
      _lclose(ascHandle);
      ascState = ASC_IDLE;
      break;

    default:

      // unknown state
      wsprintf((LPSTR)Temp,"INTERNAL ERROR: Bad state = %d\n",ascState);
      DisplayLine((LPSTR)Temp);
      SetError(ASC_INTERNAL_ERROR);
      return TRUE;
     }// end switch
  // return FALSE for "not IDLE"
  return FALSE;
 } // end ascDriver
