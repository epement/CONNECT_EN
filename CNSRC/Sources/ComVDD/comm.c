/*
   Com_VDD.c - Windows NT serial port Virtual Device Driver
   based on code by: 24-Dec-1992 John Morgan
*/

#define WIN
#define FLAT_32
#define TRUE_IF_WIN32   1
#define _WINDOWS

#include <windows.h>
#include <stdlib.h>
#include <vddsvc.h>


BOOL VDDInitialize( PVOID, ULONG, PCONTEXT );
VOID VDDTerminateVDM( VOID );
VOID VDDInit( VOID );
VOID VDDDispatch( VOID );


#define MAX_LINES 8             // Maximum number of COM lines

typedef unsigned char   byte;

static HANDLE       hCom [MAX_LINES];
static VDM_MODE     VDMProtected = VDM_V86;


//  forward declarations

static void     ResetAllHandles (void);
static void     CloseOneHandle  (int i);
static void     CloseAllHandles (void);
static int      OpenPort    (byte base, byte chan, byte opt, USHORT baud);
static void     ClosePort   (byte chan);
static BOOL     PortNotOpen (byte chan);
static BOOL     PortIsOpen  (byte chan);
static DWORD    MinD (DWORD d1, DWORD d2);

// ---------------------

/*
 *
 * VDDInitialize
 *
 * Arguments:
 *     DllHandle - Identifies this VDD
 *     Reason - Attach or Detach
 *     Context - Not Used
 *
 * Return Value:
 *     TRUE: SUCCESS
 *     FALSE: FAILURE
 *
 */

BOOL VDDInitialize(
    IN PVOID    DllHandle,
    IN ULONG    Reason,
    IN PCONTEXT Context OPTIONAL
    )
{

    switch ( Reason ) {

    case DLL_PROCESS_ATTACH:

        ResetAllHandles();
        break;

    case DLL_PROCESS_DETACH:

        CloseAllHandles();
        break;

    default:
        break;
    }

    return TRUE;
}


/*
 *
 * VDDTerminateVDM
 *
 */

VOID VDDTerminateVDM( VOID )
{
    return;
}


/*
 *
 * VDDInit
 *
 */
VOID VDDInit( VOID )
{

    // Called from the BOP manager. If VDDInitialize has done all the
    // checking and resources alloaction, just return success.

    setCF( 0 );

    return;
}


/*
 *
 * VDDDispatch
 *
 * Arguments:
 *     Client (DX)    = Address / command code

    0xBBCL

     high byte : "BB" : NT port base (8 for COM8 etc) (used in OPEN only)
     nibble 1  : "C"  : Command
     nibble 0  : "L"  : LINE (channel 0..7) e.g. 0 -> COM8, 1 -> COM9 etc

    Commands:

    0 : INIT    CX = baud rate
                BL = line options  (bits, stops, parity)
                BH = 0 (REAL MODE) or 1 (PROTECTED MODE)

    1 : READ    CX = number of chars to read
                ES:SI = buffer
                return : CX = actual read

    2 : WRITE   CX = number of chars to write
                ES:DI = buffer
                return : CX = actual written

    3 : CLOSE

    4 : MDM_CTL CX= EscapeCommFunction signal code

 * Return Value:
 *     Client Carry Clear:  SUCCESS  AX = 0
 *     Client Carry Set:    FAILURE, AX = reason
 *
 */



VOID VDDDispatch( VOID )
{
  PCHAR   Buffer;
  DWORD   lpErr;
  COMSTAT lpStat;
  USHORT  UserCX, UserDX, IO_Result;
  BYTE    temp, PortOpt, PortCommand, PortChan, PortBase;
  DWORD   Actual,toGet;
  BOOL    Success;
  int     result;


    UserDX = getDX();

    PortCommand = (UserDX >> 4) & 0x0F;
    PortChan    =  UserDX       & 0x07;
    PortBase    = (UserDX >> 8) & 0x1F;


    UserCX = getCX();               // all commands use CX

    switch (PortCommand ) {

    case 0: // Initialize

        if (PortIsOpen (PortChan)) {
            setAX(1);
            setCF(1);
            return;
        }

        PortOpt = getBL();
        VDMProtected = (getBH() == 0) ? VDM_V86 : VDM_PM;

        result = OpenPort (PortBase, PortChan, PortOpt, UserCX);
        setCF((result==0)? 0 : 1 );
        setAX((USHORT)result );
        break;

    case 1: // Read buffer

        if (PortNotOpen (PortChan)) {
            setCX(0);
            setAX(1);
            setCF(1);
            return;
        }

        Buffer = VdmMapFlat (getES(), getSI(), VDMProtected);

        Success = ClearCommError(hCom[PortChan], &lpErr, &lpStat);
        toGet = MinD(UserCX, lpStat.cbInQue);

        if (toGet > 0) {
            Success = ReadFile ( hCom[PortChan], Buffer, toGet, &Actual, NULL);
        }
        setCX((USHORT) toGet);
        setAX(0);
        setCF(0);
        break;

    case 2: // Write buffer

        if (PortNotOpen (PortChan)) {
            setCX(0);
            setAX(1);
            setCF(1);
            return;
        }

        Buffer = VdmMapFlat (getES(), getDI(), VDMProtected);
        Success = WriteFile ( hCom[PortChan], Buffer, UserCX, &Actual, NULL);

        setAX(0);
        setCX((USHORT) Actual);
        setCF(0);
        break;

    case 3: // CLOSE

        if (PortIsOpen (PortChan)) {
            CloseOneHandle(PortChan);
            setAX(0);
            setCF(0);
        } else {
            setAX(1);
            setCF(1);
        }


        break;
    case 4: // MDM_CTL

        if (PortNotOpen (PortChan)) {
            setCX(0);
            setAX(1);
            setCF(1);
            return;
        }

        Success = EscapeCommFunction ( hCom[PortChan], UserCX);
        setAX(0);
        setCF(0);
        break;

    default: // unknown command
        break;

    }

    return;
}


// service procedures


static void ResetAllHandles (void)      // invalidate all handles on entry
{
  int i;

    for (i = 0; i < MAX_LINES; i++ ) hCom[i] = INVALID_HANDLE_VALUE;
}

static void CloseOneHandle (int i)
{
    if (hCom[i] != INVALID_HANDLE_VALUE)
    {
       CloseHandle (hCom[i]);
       hCom[i] = INVALID_HANDLE_VALUE;
    }

}


static void CloseAllHandles (void)      // close all open handles
{
  int i;

    for (i = 0; i < MAX_LINES; i++)  CloseOneHandle(i);

}


static int OpenPort (byte base, byte chan, byte opt, USHORT baud)
{

  DCB     dcb;
  HANDLE  hLoc;
  BOOL    fSuccess; //0 1 23 456 7 8 9
  char    pName [] = "\\\\.\\COM\0\0\0";
  byte    nCom, n;


    nCom = base + chan;

    if ( nCom < 10 )
    {
        pName[7] = '0' + nCom;

    } else {

        pName[7] = '0' + nCom / 10;
        pName[8] = '0' + nCom % 10;
    }

    hLoc = CreateFile (
        pName,
        GENERIC_READ | GENERIC_WRITE,
        0,                          // comm devices must be opened
w/exclusive-access
        NULL,                       // no security attributes
        OPEN_EXISTING,              // comm devices must use OPEN_EXISTING
        0,
        NULL  // hTemplate must be NULL for comm devices
    );


    if (hLoc == INVALID_HANDLE_VALUE) return (2);

    fSuccess = GetCommState(hLoc, &dcb);

    if ( ! fSuccess) {
        CloseHandle (hLoc);
        return (3);
    }

    // Fill in the DCB

    dcb.BaudRate = baud;
    dcb.ByteSize = 5 + (opt & 3);
    dcb.StopBits = (opt & 4) ? TWOSTOPBITS : ONESTOPBIT;

    n = (opt >> 3) & 3;         // extract parity bits

    switch (n) {
    case 0:
    case 2: dcb.Parity = NOPARITY;
            break;
    case 1: dcb.Parity = ODDPARITY;
            break;
    case 3: dcb.Parity = EVENPARITY;
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

    fSuccess = SetCommState(hLoc, &dcb);

    if ( ! fSuccess) {
        CloseHandle (hLoc);
        return (4);
    }

    hCom[chan] = hLoc;

    return (0);

}


static BOOL PortNotOpen (byte chan)
{
    return (hCom[chan] == INVALID_HANDLE_VALUE);
}

static BOOL PortIsOpen (byte chan)
{
    return (hCom[chan] != INVALID_HANDLE_VALUE);
}

static void ClosePort (byte chan)
{
    CloseHandle (hCom[chan]);
}

static DWORD MinD (DWORD d1, DWORD d2)
{
    return (d1 < d2) ? d1 : d2;
}


