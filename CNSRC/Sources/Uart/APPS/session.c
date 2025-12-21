// session.c
//
// Called from HOST.CPP
//

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "wsc.h"
#include "session.h"
#include "mio.h"

#define CR       13
#define LF       10

static char UserName[40];      // caller's user name
static char PassName[40];      // caller's password
static char WorkBuf[80];       // work buffer

// run the MIO driver

void RunTheDriver(int Port)
{int Code;
 while(1)
   {Code = mioDriver(Port);
    if(Code==MIO_IDLE) break;
    if(Code>=0) printf("%c",Code);
    Sleep(0);
   }
 }

// send string to both display and serial port

void PutString(int Port,char *String)
{int i;
 int Len;
 char c;
 Len = strlen(String);
 for(i=0;i<Len;i++)
   {c = String[i];
    if(c=='!')
      {printf("%c",CR);
       SioPutc(Port,CR);
       c = LF;
      }
    printf("%c",c);
    SioPutc(Port,c);
   }
}

// get string from serial port, echoing if requested

void GetString(int Port,char *Buffer,int BufSize,int Echo)
{int i;
 int Len = 0;
 while(1)
   {i = SioGetc(Port);
    if(i>=0)
      {if(Echo)
         {// echo character
          printf("%c",(char)i);
          SioPutc(Port,(char)i);
         }
       else
         {// echo dot
          printf("%c",'.');
          SioPutc(Port,'.');
         }
       if(i==CR) break;
       Buffer[Len++] = (char)i;
       if(Len==BufSize-1) break;
      }
   }
 Buffer[Len] = '\0';
}

// process user's session from logon to logoff

int Session(int Port)
{int i;
 // answer RING
 printf("<<Answering RING>>\n");

 mioSendTo(Port, 100,"!ATA!");
 RunTheDriver(Port);

 printf("<<Awaiting CONNECT>>\n");
 mioWaitFor(Port,5000,"CONNECT");
 RunTheDriver(Port);
 if(mioResult(Port)) printf("<<Modem is ready>>\n");
 else
   {printf("<<CONNECT is NOT seen>>\n");
    return FALSE;
   }
 // send CR & then wait for line to clear
 SioPutc(Port, CR);
 mioQuiet(Port,3000);
 RunTheDriver(Port);
 PutString(Port,"!HOST program!");
 // get user name
 PutString(Port,"Logon: ");
 GetString(Port,UserName,sizeof(UserName),TRUE);
 PutString(Port,"!");
 mioQuiet(Port,250);
 RunTheDriver(Port);
 // get password
 PutString(Port,"Password: ");
 GetString(Port,PassName,sizeof(PassName),FALSE);
 PutString(Port,"!");
 // OK
 while(1)
   {mioQuiet(Port,200);
    RunTheDriver(Port);
    PutString(Port,"Q)uit B)ulletins M)essages F)iles : ");
    // get response character
    while(1)
      {// check carrier
       if(SioDCD(Port)==0)
         {printf("<<No carrier>>");
          return FALSE;
         }
       // get next incoming
       i = SioGetc(Port);
       if(i!=WSC_NO_DATA) break;
      }
    switch( toupper((char)i) )
       {case 'Q': // Exit
          PutString(Port,"Logging off");
          return TRUE;
        case 'B': // Bulletins
        case 'M': // Messages
        case 'F': // Files
          sprintf(WorkBuf,"Hello '%s'.!",UserName);
          PutString(Port,WorkBuf);
       } // end switch
   } // end while
} // end Session
