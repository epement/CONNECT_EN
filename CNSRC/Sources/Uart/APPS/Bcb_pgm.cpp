//---------------------------------------------------------------------------
#include <vcl\vcl.h>
#pragma hdrstop

#define WIN32
#include "bcb_pgm.h"
#include "wsc.h"
#include "keycode.h"

//---------------------------------------------------------------------------
//
//*** NOTES ***
//
// Compile with BCB_PRJ.MAK if running BCB version 1 through 3, and compile with
// BCB_PRJ.BPR if running BCB version 4 or above.
//
//---------------------------------------------------------------------------
#pragma resource "*.dfm"

// set default port and baud rate
static int ThePort = COM1;
static int TheBaud = WSC_Baud38400;

//---------------------------------------------------------------------------
 TBCB_PGM *BCB_PGM;
//---------------------------------------------------------------------------
__fastcall TBCB_PGM::TBCB_PGM(TComponent* Owner)
   : TForm(Owner)
{//TheDC = GetDeviceContext(&WindowHandle);
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::ExitClick(TObject *Sender)
{
 SioDone(ThePort);
 Close();
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::TimerTimer(TObject *Sender)
{int  i, Code;
 char Ch = '\0';
 static int LineCount = 0;
 AnsiString Text;
 // gather incoming chars
 for(i=0;i<128;i++)
   {Code = SioGetc(ThePort);
    if(Code<0) break;
    // got incoming
    if(i==0)
      {// fetch current line
       Text = Memo->Lines->Strings[LineCount];
      }
    // get character, ignoring CR
    Ch = (char)Code;
    if(Ch=='\n') break;
    if(Ch=='\r') continue;
    // append to current line
    Text = Text + Ch;
   }
 // return now if no incoming
 if(Ch=='\0') return;
 // update current line
 Memo->Lines->Strings[LineCount] = Text;
 // add a new line if last incoming char was LF
 if(Ch=='\n')
   {Memo->Lines->Add("");
    LineCount++;
   }
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::OnLineClick(TObject *Sender)
{int Code;
 // pass the key code
 if(SioKeyCode(WSC_KEY_CODE)<0)
   {BCB_PGM->Caption = "ERROR: Bad Key Code!";
    return;
   }
 // open the port
 Code = SioReset(ThePort,2048,1024);
 if(Code<0)
   {char Temp[80];
    SioWinError((LPSTR)Temp,80);
    BCB_PGM->Caption = Temp;
    return;
   }
 // set baud rate, DTR, and RTS
 SioBaud(ThePort,TheBaud);
 SioDTR(ThePort,'S');
 SioRTS(ThePort,'S');
 // update menu items
 OnLine->Checked = true;
 OffLine->Checked = false;
 OnLine->Enabled = false;
 OffLine->Enabled = true;
 Port->Enabled = false;
 Baud->Enabled = false;
 BCB_PGM->Caption = "BCB_PGM OnLine";
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::OffLineClick(TObject *Sender)
{
 SioDone(ThePort);
 OnLine->Checked = false;
 OffLine->Checked = true;
 OnLine->Enabled = true;
 OffLine->Enabled = false;
 Port->Enabled = true;
 Baud->Enabled = true;
 BCB_PGM->Caption = "BCB_PGM";
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::mCOM1Click(TObject *Sender)
{
 mCOM1->Checked = true;
 mCOM2->Checked = false;
 mCOM3->Checked = false;
 mCOM4->Checked = false;
 ThePort = COM1;
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::mCOM2Click(TObject *Sender)
{
 mCOM1->Checked = false;
 mCOM2->Checked = true;
 mCOM3->Checked = false;
 mCOM4->Checked = false;
 ThePort = COM2;
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::mCOM3Click(TObject *Sender)
{
 mCOM1->Checked = false;
 mCOM2->Checked = false;
 mCOM3->Checked = true;
 mCOM4->Checked = false;
 ThePort = COM3;
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::mCOM4Click(TObject *Sender)
{
 mCOM1->Checked = false;
 mCOM2->Checked = false;
 mCOM3->Checked = false;
 mCOM4->Checked = true;
 ThePort = COM4;
}
//----------------------------------------------------------------------------
void __fastcall TBCB_PGM::N9600Click(TObject *Sender)
{N9600->Checked = true;
 N19200->Checked = false;
 N38400->Checked = false;
 N57600->Checked = false;
 TheBaud = WSC_Baud9600;
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::N19200Click(TObject *Sender)
{N9600->Checked = false;
 N19200->Checked = true;
 N38400->Checked = false;
 N57600->Checked = false;
 TheBaud = WSC_Baud19200;
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::N38400Click(TObject *Sender)
{N9600->Checked = false;
 N19200->Checked = false;
 N38400->Checked = true;
 N57600->Checked = false;
 TheBaud = WSC_Baud38400;
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::N57600Click(TObject *Sender)
{N9600->Checked = false;
 N19200->Checked = false;
 N38400->Checked = false;
 N57600->Checked = true;
 TheBaud = WSC_Baud57600;
}
//---------------------------------------------------------------------------
void __fastcall TBCB_PGM::OnKeyPress(TObject *Sender, char &Key)
{
 SioPutc(ThePort, (char)Key );
}
//---------------------------------------------------------------------------
