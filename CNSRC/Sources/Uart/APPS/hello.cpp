//
// NAME: HELLO.CPP
//
// TYPE: Win32 console mode.
//
// DATE: August 6, 2004
//
// PURPOSE: A simple C++ console mode program that demonstrates how
//          to use the fSio C++ class.
//
// COMPILE: From the command line:
//
//     nmake -f hello32._m_  (Microsoft VC)
//      make -f hello32._b_  (Borland 5.0)
//      make -f hello32._i_  (Borland 5.5)
//     wmake -f hello32._w_  (Watcom 11)
//
// COMPILE: From MSVC integrated developer environment (IDE):
//
//     Open workspace hello.mak in MSVC IDE.
//
//

#include <windows.h>
#include <iostream.h>
#include <string.h>

// declare class fSio
#include "fSio.h"

// include value of key code for SioKeyCode
#include "keycode.h"

static int Port = COM1;

static char Temp[128];

void main(void)
{int Code;
 int Version;
 int Build;
 int d1, d2, d3;
 fSio f;
 // pass the key code
 if(f.fSioKeyCode(WSC_KEY_CODE)<0)
   {cout << "ERROR: Bad Key Code!\r\n";
    exit(1);
   }
 Code = f.fSioReset(Port, 512, 512);
 if(Code<0)
   {cout << "fSioReset returns " << Code << "\r\n";
    exit(1);
   }
 // get WSC version and Build # from WSC32.DLL (or WSC16.DLL)
 Version = f.fSioInfo('V');
 Build = f.fSioInfo('B');
#ifdef WIN32
 cout << "Win32 WSC Version ";
#else
 cout << "Win16 WSC Version ";
#endif
 // display the version number
 d1 = Version>>8;
 d2 = 0x0f & (Version>>4);
 d3 = 0x0f & Version;
 cout << d1 << ".";
 cout << d2 << ".";
 cout << d3 << ", Build ";
 cout << Build << "\r\n";
 // get registration string
 Code = f.fSioGetReg((LPSTR)Temp, 50);
 if(Code>0)
   cout << Temp;
}
