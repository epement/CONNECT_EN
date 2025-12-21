//
//   ANSI.C
//
//   ANSI terminal emulator
//
//   Interprets ANSI escape sequences. Think of the keyboard
//   and terminal as an external device and ANSI.C as its
//   interface.
//
//   This module uses PAINT.C as its interface to the actual
//   screen.
//
//   FEATURE             SUPPORTED
//   =======             =========
//   Cursor positioning  Yes
//   Underlining         No
//   Blinking, inverse   No
//   Color               No
//


#include "windows.h"
#include "paint.h"
#include "ascii.h"
#include "wsc.h"

extern HWND hMainWnd;

#define SIZE 40

static int  Initialized = 0;
static int  Debug = 0;
static int  SavedRow = 0;
static int  SavedCol = 0;
static char ReportBuffer[SIZE];
static int  ReportLeft = 0;
static int  ReportRight = 0;
static char ListBuf[SIZE];      //  escape sequence buffer
static int  ListCnt  = 0;       //  # characters in ListBuf[]

static char EscSequence[4] = {27,'[','A','\0'};

//  add char to escape sequence list

static void Add2List(char C)
{if(ListCnt<SIZE-1) ListBuf[ListCnt++] = C;
}

//  clear escape sequence list

static void ClearList(void)
{int i;
 ListCnt = 0;
 for(i=0;i<SIZE;i++) ListBuf[i] ='\0';
}

//  is character a digit ?

static int IsDigit(char c)
{if((c>='0')&&(c<='9')) return TRUE;
 else return FALSE;
}

//  is character alphabetic ?

static int IsAlpha(char c)
{if((c>='a')&&(c<='z')) return TRUE;
 if((c>='A')&&(c<='Z')) return TRUE;
 return FALSE;
}

//
//  returns numeric parameter, advancing
//  list index to next non-numeric digit


static int EatDigits(int *IndexPtr)
{int  Value = 0;
 char Char;
 //  while characters in escape sequence list
 while(*IndexPtr < ListCnt)
   {Char = ListBuf[*IndexPtr];
    if(IsDigit(Char))
      {Value = 10*Value + (Char - '0');
       (*IndexPtr)++;
      }
    else break;
   }
 return Value;
}

//
//  The Escape sequence buffer is ready to interpret when:
//    1) Sequence starts with "ESC [" , and
//    2) Sequence ends with a alphabetic character.


static void Interpret(void)
{int i;
 int Index;  //  index into ListBuf[]
 int Value;  //  parameter value
 int Row;
 int Col;
 if(Debug)
   {DisplayChar('[');
    for(i=0;i<ListCnt;i++) DisplayChar(ListBuf[i]);
    DisplayChar(']');
   }
 Row = PaintGetRow();
 Col = PaintGetCol();
 Index = 2;
 switch(ListBuf[ListCnt-1])
   {
    case 'A':  // //  ESC [ * A //
      Value = EatDigits(&Index);
      if(Value==0) Value = 1;
      if(Index==ListCnt-1)
        {//  move up 1 row
         Row -= Value;
         if(Row<0) Row = 0;
         PaintSetRow(Row);
         PaintSetCol(Col);
        }
      break;
    case 'B':  // //  ESC [ * B //
      Value = EatDigits(&Index);
      if(Value==0) Value = 1;
      if(Index==ListCnt-1)
        {//  move down 1 row
         Row += Value;
         if(Row>NROWS) Row = NROWS;
         PaintSetRow(Row);
        }
      break;
    case 'C':  // //  ESC [ * C //
      Value = EatDigits(&Index);
      if(Value==0) Value = 1;
      if(Index==ListCnt-1)
        {//  move right 1 column
         Col += Value;
         if(Col>NCOLS) Col = NCOLS;
         PaintSetCol(Col);
        }
      break;
    case 'D':  // //  ESC [ * D //
      Value = EatDigits(&Index);
      if(Value==0) Value = 1;
      if(Index==ListCnt-1)
        {//  move left 1 column
         Col -= Value;
         if(Col<0) Col = 0;
         PaintSetCol(Col);
        }
      break;
    case 'f':  // //   ESC [ * ; * f  //
    case 'H':  // //   ESC [ * ; * H  //
               // //   ESC [ = * H    //
      if(ListBuf[2]=='=')
         {Index++;
          EatDigits(&Index);
          break;
         }
      Row = EatDigits(&Index) - 1;
      if(ListBuf[Index]==';')
        {Index++;
         Col = EatDigits(&Index) - 1;
        }
      if(Index==ListCnt-1)
        {PaintSetRow(Row);
         PaintSetCol(Col);
        }
      break;
    case 'J':  // //   ESC [ 2 J  //
      if((ListBuf[2]=='2')&&(ListCnt==4))
         {//  erase display
          PaintClearScreen();
          break;
         }
      break;
    case 'K': // //   ESC [ 2 K  //
      if((ListBuf[2]=='2')&&(ListCnt==4))
        {//  erase to EOL
         PaintClearEOL();
        }
      break;
    case 'n': // //   ESC [ 6 n  //
      if((ListBuf[2]=='6')&&(ListCnt==4))
         {//  output Cursor Position ReportBuffer (CPR)
          Row = PaintGetRow();
          Col = PaintGetCol();
          //  save up position report
          wsprintf((LPSTR)ReportBuffer,"%c[%d;%dR",ESC,Row+1,Col+1);
          ReportLeft = 0;
          ReportRight = lstrlen((LPSTR)ReportBuffer) - 1;
          break;
         }
      break;
    case 'u':  // //   ESC [ u  //
      if((ListBuf[2]=='u')&&(ListCnt==3))
        {//  restore saved cursor position
         PaintSetRow(SavedRow);
         PaintSetCol(SavedCol);
        }
      break;
    case 's':  // //   ESC [ s  //
      if((ListBuf[2]=='S')&&(ListCnt==3))
        {//  save cursor position
         SavedRow = PaintGetRow();
         SavedCol = PaintGetCol();
        }
      break;
    default:
      //  sequence not recognized or not supported
      break;
   } //  end-switch
 ClearList();
}


//*** PUBLIC functions ***


//  set/clear Debug flag

void AnsiDebug(int Flag)
{Debug = Flag;
}

//  display character

int AnsiPutc(char C)
{//  initialized ?
 if(!Initialized)
    {ClearList();
     Initialized = 1;
    }
 //  process character C
 if(C==ESC)
    {//  start new escape sequence
     ListCnt = 0;
     Add2List(ESC);
     return 0;
    }
 else
    {//  escape sequence started ?
     if(ListCnt==0)
        {DisplayChar(C);
         return 1;
        }
     else
        {//  add to escape sequence
         Add2List(C);
         //  last char in ListBuf[] alphabetic ?
         if(IsAlpha(ListBuf[ListCnt-1]))
           {//  ready to interpret
            if(ListBuf[1]=='[') Interpret();
            else ListCnt = 0;
           }
         return 0;
        }
    }
}

//  display (null terminated) string

int AnsiPuts(LPSTR String)
{int i;
 int Len = lstrlen(String);
 for(i=0;i<Len;i++) AnsiPutc(*String++);
 return Len;
}

//  (virtual) ANSI keyboard

int AnsiGetc(void)
{if(ReportLeft==ReportRight) return -1;
 return ReportBuffer[ReportLeft++];
}

void AnsiUp(int Port)
{EscSequence[2] = 'A';
 SioPuts(Port,(LPSTR)EscSequence,3);
}

void AnsiDown(int Port)
{EscSequence[2] = 'B';
 SioPuts(Port,(LPSTR)EscSequence,3);
}

void AnsiRight(int Port)
{EscSequence[2] = 'C';
 SioPuts(Port,(LPSTR)EscSequence,3);
}

void AnsiLeft(int Port)
{EscSequence[2] = 'D';
 SioPuts(Port,(LPSTR)EscSequence,3);
}
