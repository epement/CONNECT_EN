#include <windows.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include "m_types.h"
#include "madli.h"


bool __pascal Progress(byte i, byte count)
{
 printf("%d of %d   \r", i, count);
 if (kbhit() && (getch()== 27)) return FALSE;
 else return TRUE;
}

void main(void)
{
 char cc, ccc;
 HANDLE port;
 byte res;
 word data;
 byte state;
 byte mError;
 word Ram[256];
 byte EE[256];
 word Addr;

 if ((port = OpenComPort(1, 4800, 8, 'N', 1, &mError, NULL)) !=
       INVALID_HANDLE_VALUE)
  {
   Addr = 841;
//   printf("Clear EE:\r\n ");
//   SetBallAddr(port, 1023, &mError);
//   printf("%s\n\r", ErrorStr(mError));

   printf("Set ballast address:\r\n ");
   SetBallAddr(port, Addr, &mError);
   printf("%s\n\r", ErrorStr(mError));

   printf("Get RAM block:\r\n ");
   GetRamBlock(port, Addr, 20, &state, Ram, &mError, &Progress);
   printf("%s\n\r", ErrorStr(mError));

   printf("Get EE block:\r\n ");
   GetEEBlock(port, Addr, 20, EE, &mError, &Progress);
   printf("%s\n\r", ErrorStr(mError));

   printf("Set EE block:\r\n ");
//   SetEEBlock(port, 0, Addr, 20, EE, &mError, &Progress);
   printf("%s\n\r", ErrorStr(mError));

   printf("Get EE block:\r\n ");
//   GetEEBlock(port, Addr, 20, EE, &mError, &Progress);
   printf("%s\n\r", ErrorStr(mError));

   printf("Set Group address:\r\n ");
//   SetBallGroup(port, Addr, 2, 100, &mError);
   printf("%s\n\r", ErrorStr(mError));

   printf("Set EE data:\r\n ");
//   SetEE(port, 0, Addr, 0, 100, &mError);
   printf("%s\n\r", ErrorStr(mError));

   do
    {
     if (GetRam(port, Addr, 21, &state, &data, &mError))
      printf("State %x \t Tout %d\t", state, data);
     else printf("%s\n\r", ErrorStr(mError));
     Delay(15);
     if (GetRam(port, Addr, 20, &state, &data, &mError))
      printf("Pout %d\t", data);
     else printf("%s\n\r", ErrorStr(mError));
     Delay(15);
     if (GetEE(port, Addr, 0, &data, &mError))
      printf("Pref %d\t", data);
     else printf("%s\n\r", ErrorStr(mError));
     Delay(15);

     if (kbhit()) cc = getch();
     else cc = ' ';
     switch(cc)
      {
       case 'O': bSwitch(port, 0, Addr, mcmOn, 255, &mError); break;
       case 'F': bSwitch(port, 0, Addr, mcmOff, 255, &mError); break;
      }
     printf("\t\r");
    }
   while (cc != 27);

   CloseComPort(port);
  }
 else printf("%s\n\r", ErrorStr(mError));
}


