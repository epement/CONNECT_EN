//** runtest **

#include "windows.h"
#include "wsc.h"
#include "sioerror.h"
#include "paint.h"
//#include "line.h"
#include "runtest.h"

extern HWND hMainWnd;
extern int  OnLineFlag;
extern char Temp[1024];

#define TEST_SIZE 62

// private

static char TestSet[TEST_SIZE+1];
static int  NbrRuns = 16;
static int  TestLength = 0;
static int  TestRun = 0;
int GetChar(int,int);

// public

int RunTest(int Port)
{int i;
 int n;
 int rc;

 // initialize
 if(TestLength==0)
   {// build TestSet[] array
    for(i=0;i<26;i++) TestSet[i] = 'A'+i;
    for(i=0;i<26;i++) TestSet[26+i] = 'a'+i;
    for(i=0;i<10;i++) TestSet[52+i] = '0'+i;
    TestSet[62] = '\0';
   }

 // check for loopback adapter
 SioRxClear(Port);
 SioTxClear(Port);
 SioPutc(Port,'$');
 if( (char)GetChar(Port,500) != '$')
   {DisplayLine("Loopback not detected. See Instructions.");
    return FALSE;
   }

 // run the test
 wsprintf((LPSTR)Temp,"\n\rTest Run %d\n", ++TestRun);
 DisplayLine(Temp);
 wsprintf((LPSTR)Temp,"Test Set: %s",(LPSTR)TestSet);
 DisplayString(Temp);

 // send test sets
 DisplayString("\n\r  Sending set: ");
 for(i=0;i<NbrRuns;i++)
    {// send test set again
     wsprintf((LPSTR)Temp,"%d ",i);
     DisplayString(Temp);
#if 0
     {int c;
      for(n=0;n<TEST_SIZE;n++)
        {c = TestSet[n];
         SioPutc(Port,(char)c);
        }
     }
#else
     while(1)
       {n = SioPuts(Port,(LPSTR)TestSet, TEST_SIZE);
        // if BUSY, nothing is sent
        if(n!=WSC_BUSY) break;
       }

     if(n<0)
        {wsprintf((LPSTR)Temp,"SioPuts return %d\n", n);
         DisplayLine(Temp);
         return FALSE;
        }
     while(SioTxQue(Port)>0);
#endif
    }

 // receive test sets
 DisplayString("\n\rReceiving set: ");
 for(i=0;i<NbrRuns;i++)
    {// receive next test set
     for(n=0;n<TEST_SIZE;n++)
        {rc = GetChar(Port,2000);
         if(rc<0)
            {SioError(rc,"SioGetc:");
             wsprintf((LPSTR)Temp,"%d bytes in COM%d RX queue\n", SioRxQue(Port),1+Port );
             DisplayLine(Temp);
             wsprintf((LPSTR)Temp,"%d bytes in COM%d TX queue\n", SioTxQue(Port),1+Port );
             DisplayLine(Temp);
             return FALSE;
            }
         // compare character
         if((char)rc!=TestSet[n])
           {wsprintf((LPSTR)Temp,"\n\rERROR: Expecting '%c'(0x%x), received '%c'(0x%x)\n",
              (char)rc,(char)rc,TestSet[n],TestSet[n]);
            DisplayLine(Temp);
            return FALSE;
           }
        } // end-for(n)
     wsprintf((LPSTR)Temp,"%d ",i);
     DisplayString(Temp);
    } // end-for(i)

 // look at results
 DisplayLine("\n\rSUCCESS: Test AOK !");

 // DTR vs DSR test
 n = 0;
 SioDTR(Port,'C');
 if(SioDSR(Port)) n++;
 SioDTR(Port,'S');
 if(SioDSR(Port)==0) n++;
 if(n==0) DisplayLine("DTR/DSR test OK");
 else DisplayLine("DTR/DSR test fails [or not connected]");

 // RTS vs CTS test
 n = 0;
 SioRTS(Port,'C');
 if(SioCTS(Port)) n++;
 SioRTS(Port,'S');
 if(SioCTS(Port)==0) n++;
 if(n==0) DisplayLine("RTS/CTS test OK");
 else DisplayLine("RTS/CTS test fails [or not connected]");

 return TRUE;
}

int GetChar(int Port, int MilliSecs)
{int   Code;
 int   Flag;
 DWORD Count;
 Flag = 0;
 while(1)
   {Code = SioGetc(Port);
    if(Code!=WSC_NO_DATA) return Code;
    if(Flag==0)
       {Count = GetTickCount() + (DWORD)MilliSecs;
        Flag = 1;
       }
    if(GetTickCount()>Count) break;
   }
 return WSC_NO_DATA;
}

