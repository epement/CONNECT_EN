#include <windows.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include "m_types.h"
#include "madli.h"


bool Progress(byte i, byte count)
{
 printf("%d of %d", i, count);
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

 if ((port = OpenComPort(1, 4800, 8, 'N', 1, &res)) != INVALID_HANDLE_VALUE)
  {

  GetRamBlock(port, 741, 50, &state, Ram, &mError, &Progress);

   if (!SetEE(port, 0, 741, 0, 100, &mError))
    printf("%s\n\r", mErr_str[mError]);

   do
    {
     if (GetRam(port, 741, 21, &state, &data, &mError))
      printf("Tout %d\n\r", data);
     else printf("%s\n\r", mErr_str[mError]);

     if (GetEE(port, 741, 0, &data, &mError))
      printf("Pref %d\n\r", data);
     else printf("%s\n\r", mErr_str[mError]);
     Delay(5);

     if (kbhit()) cc = getch();
    }
   while (cc != 27);

   CloseComPort(port);
  }
}

