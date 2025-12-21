// config.c

#include "windows.h"
#include "config.h"
#include "wsc.h"
#include "menu.h"
#include "message.h"
#include "sioerror.h"

extern HWND hMainWnd;
extern char Temp[256];
extern int  OnLineFlag;

#define TEXT_SIZE 8

static struct
 {int Port;
  int BaudRateCode;
  int DataBits;
  int ParityCode;
  int StopBitsCode;
 } Config = {COM1,WSC_Baud19200,8,WSC_NoParity,WSC_OneStopBit};

static char ConfigText[TEXT_SIZE+1] = "";
static char StopBitList[3] = {'1','?','2'};
static char ParityList[5]  = {'N','O','E','M','S'};
static unsigned BaudRateValue[10] = {110,300,1200,2400,4800,9600,19200,38400,57600,115200};

static int PortMsgID[4] = {MSG_COM1,MSG_COM2,MSG_COM3,MSG_COM4};
static int BaudRateMsgID[10] = {MSG_110, MSG_300, MSG_1200, MSG_2400,
                               MSG_4800,MSG_9600,MSG_19200,MSG_38400,
                               MSG_57600,MSG_115200};
static int StopBitsMsgID[3] = {MSG_1_SB,0,MSG_2_SB};
static int ParityMsgID[5] = {MSG_NONE,MSG_ODD,MSG_EVEN,0,0};
static int DataBitsMsgID[9] = {0,0,0,0,0,0,0,MSG_7_DB,MSG_8_DB};

static char *LineText[2] = {"OFF", "ON"};

static int LastPortID = MSG_COM1;
static int LastParityID = MSG_NONE;
static int LastStopBitsID = MSG_1_SB;
static int LastDataBitsID = MSG_8_DB;
static int LastBaudRateID = MSG_19200;

void UncheckAll(void)
{UncheckTheMenu(LastPortID);
 UncheckTheMenu(LastParityID);
 UncheckTheMenu(LastStopBitsID);
 UncheckTheMenu(LastDataBitsID);
 UncheckTheMenu(LastBaudRateID);
}

void CheckAll(void)
{CheckTheMenu(LastPortID);
 CheckTheMenu(LastParityID);
 CheckTheMenu(LastStopBitsID);
 CheckTheMenu(LastDataBitsID);
 CheckTheMenu(LastBaudRateID);
}

int UpdateTheChecks(int OldMsgID,int NewMsgID)
{UncheckTheMenu(OldMsgID);
 CheckTheMenu(NewMsgID);
 return NewMsgID;
}

void SetTitle(void)
{wsprintf((LPSTR)Temp,"%s: COM%d @ %u baud %d%c%c %sLINE",
    (LPSTR)ConfigText,
    Config.Port+1,
    BaudRateValue[Config.BaudRateCode%10],
    Config.DataBits,
    ParityList[Config.ParityCode],
    StopBitList[Config.StopBitsCode],
    (LPSTR)LineText[1&OnLineFlag]);
    SetWindowText(hMainWnd,(LPSTR)Temp);
}

void SetPSL(int Parity, int StopBits, int DataBits)
{Config.ParityCode = Parity;
 Config.StopBitsCode = StopBits;
 Config.DataBits = DataBits;
 SetTitle();
}

void SetParity(int Parity)
{
 SetPSL(Parity, Config.StopBitsCode, Config.DataBits);
 LastParityID = UpdateTheChecks(LastParityID,ParityMsgID[Parity]);
}

void SetStopBits(int StopBits)
{
 SetPSL(Config.ParityCode, StopBits, Config.DataBits);
 LastStopBitsID = UpdateTheChecks(LastStopBitsID,StopBitsMsgID[StopBits]);
}

void SetWordLength(int DataBits)
{
 SetPSL(Config.ParityCode, Config.StopBitsCode, DataBits);
 LastDataBitsID = UpdateTheChecks(LastDataBitsID,DataBitsMsgID[DataBits]);
}

void RestorePSL(int Port)
{
 SioParms(Port, Config.ParityCode, Config.StopBitsCode, Config.DataBits);
}

void SetBaud(int BaudCode)
{int RetCode;
 Config.BaudRateCode = BaudCode;
 if(OnLineFlag)
   {RetCode = SioBaud(Config.Port,BaudRateValue[Config.BaudRateCode%10]);
    if(RetCode<0) SioError(RetCode,"SioBaud");
   }
 LastBaudRateID = UpdateTheChecks(LastBaudRateID,BaudRateMsgID[BaudCode]);
 SetTitle();
} // end SetBaud

void SetThePort(int Port)
{
 Config.Port = Port;
 LastPortID = UpdateTheChecks(LastPortID,PortMsgID[Port]);
 SetTitle();
} // end SetThePort

int GetBaud(void)
{return (Config.BaudRateCode);
}

int GetParity(void)
{return (Config.ParityCode);
}

int GetStopBits(void)
{return (Config.StopBitsCode);
}

int GetWordLength(void)
{return(Config.DataBits);
}

int GetPort(void)
{return (Config.Port);
}

void SetText(LPSTR String)
{lstrcpy((LPSTR)ConfigText,String);
}


