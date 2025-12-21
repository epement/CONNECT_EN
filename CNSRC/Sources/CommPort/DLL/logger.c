#include <windows.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "m_types.h"
#include "madli.h"

enum parce {pChar, pCmt, pSep1, pSep2, pEOL, p_num};

struct tlamp_status
 {
   char lamp_name[32];
   char cfg_name[32];
   byte flags;
   byte State;
   word ram[256];
 };

struct tlamp_status lamps[1024];

#define FILD_WITH       64
#define FILD_NUM        3

char Fields[FILD_NUM][FILD_WITH]={"aa"};

bool read_filds(HANDLE hfile, char * fields, int fwide, int fcnt)
{
 char Chr;
 int i, j;
 int State;
 bool Result = true;
 DWORD BytesRead;

 /* Read file */
 i=0;
 j=0;
 Chr = 0;
 State = pChar;
 memset(fields, '\0', fwide*fcnt);
 do
  {
    if (State != pSep2)
     ReadFile(hfile, &Chr, 1, &BytesRead, NULL);
    else State = pChar;

    if (BytesRead > 0)
     {
      if ((i==0) && (Chr == ' ')) continue;
      if (Chr == '\r') continue;

      if (State == pChar)
       {
         if (Chr == ';') State = pCmt;
         else
         if (Chr == ':')
          {
            State = pSep1;
            continue;
          }
       }
      if (Chr == '\n') State = pEOL;
      if (State == pSep1)
       {
         if (Chr ==':') State = pChar;
         else State = pSep2;
       }

      switch (State)
       {
         case pChar:
          fields[j*fwide+i++] = Chr;
         break;

         case pCmt:
         break;

         case pSep2:
          fields[j++*fwide+i] = 0;
          i = 0;
          //State = pChar;
         break;

         case pEOL:
          if (j > 0) return true;
          i=0;
          j=0;
          Chr = 0;
          State = pChar;
         break;
       }
     }
  }
 while (BytesRead != 0);
 return false;

}


bool read_ALL(LPCTSTR all)
{
 HANDLE hfall;
 bool Result = true;
 DWORD BytesRead;
// char fields[FILD_WITH][FILD_NUM];
 char Chr, Chr_1;
 int i, j;
 int State;

 memset (lamps, '\0', sizeof(lamps));
 hfall =  CreateFile(all,                        // file to open
                     GENERIC_READ,               // open for reading
                     FILE_SHARE_READ,            // share
                     NULL,                       // default security
                     OPEN_EXISTING,              // existing or new file
                     FILE_ATTRIBUTE_NORMAL,      // normal file
                     NULL);                      // no attr. template

 if (hfall != INVALID_HANDLE_VALUE)
  {
   do
    {
     Result = read_filds(hfall, (char *)Fields, FILD_WITH, FILD_NUM);
    }
  while (Result);
   CloseHandle(hfall);
  };

 return Result;
}


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

 (void)read_ALL("C:\\CNSRC\\Sources\\CommPort\\DLL\\all.txt");
#ifdef MMMM
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
#endif
}


