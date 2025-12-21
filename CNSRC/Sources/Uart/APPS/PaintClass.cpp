// PaintClass.cpp

#include "stdafx.h"      // this MUST be the 1st #include
#include <windows.h>
#include <string.h>
#include "ascii.h"
#include "wsc.h"

#define MIN(a,b) ((a<=b)?(a):(b))
#define MAX(a,b) ((a>=b)?(a):(b))
#define NROWS 25
#define NCOLS 80
int TheRow = 0;// current row
int TheCol = 0;// current col
int TopRow;
int LeftCol;
int RightCol;
char Buffer[NROWS][NCOLS];  // display buffer
char *RowPtr[NROWS];   // array of row pointers
TEXTMETRIC tm;
int CharHeight;
int CharWidth;
char EndOfLine[1] = {LF};
void DoTheScroll(void);
void ClearBuffer(void);

#include "PaintClass.h"

static HWND hMainWnd;

// PRIVATE functions

void DoTheScroll(void)
{int Row;
 int Col;
 char *Ptr;
 RECT rect;
 // scroll display buffer
 TheRow = NROWS-1;
 Ptr = RowPtr[0];
 for(Row=0;Row<NROWS-1;Row++) RowPtr[Row] = RowPtr[Row+1];
 RowPtr[NROWS-1] = Ptr;
 for(Col=0;Col<NCOLS;Col++) *Ptr++ = ' ';
 // scroll the display
 ScrollWindow(hMainWnd,0,0-CharHeight,NULL,NULL);
 // invalidate last row
 rect.left = 0;
 rect.top  = CharHeight * (NROWS-2);
 rect.right  = CharWidth * (RightCol+1);
 rect.bottom = CharHeight * (NROWS-1);
 InvalidateRect(hMainWnd,&rect,TRUE);
 // reset boundary
 TopRow = TheRow;
 LeftCol = TheCol;
 RightCol = TheCol;
} // end DoTheScroll

void ClearBuffer(void)
{int Row;
 int Col;
 // clear screen buffer
 for(Row=0;Row<NROWS;Row++)
   {for(Col=0;Col<NCOLS;Col++) Buffer[Row][Col] = ' ';
    RowPtr[Row] = &Buffer[Row][0];
   }
 TheRow = 0;
 TheCol = 0;
}

// Class functions

PaintClass::PaintClass(HWND hWnd)
{HDC hDC;
 // save window handle
 hMainWnd = hWnd;
 //
 hDC = GetDC(hMainWnd);
 SelectObject(hDC, GetStockObject(OEM_FIXED_FONT) );
 GetTextMetrics(hDC,&tm);
 CharHeight = tm.tmHeight + tm.tmExternalLeading;
 CharWidth = tm.tmMaxCharWidth;
 ReleaseDC(hMainWnd,hDC);
 // initialize screen buffer
 ClearBuffer();
};

// destructor

PaintClass::~PaintClass(void)
{//
};

int PaintClass::PaintGetRowPos(void)
{return (TheRow*CharHeight);
}

int PaintClass::PaintGetColPos(void)
{return (TheCol*CharWidth);
}

int PaintClass::PaintGetRow(void)
{return TheRow;
}

int PaintClass::PaintGetCol(void)
{return TheCol;
}

void PaintClass::PaintSetRow(int Row)
{RECT Rect;
 if((unsigned)Row<NROWS)
   {
    Rect.left   = 0;
    Rect.right  = CharWidth * (RightCol+1);
    Rect.top    = CharHeight * MIN(TheRow,Row);
    Rect.bottom = CharHeight * MAX(TheRow+1,Row+1);
    InvalidateRect(hMainWnd,&Rect,TRUE);
    TheRow = Row;
    SetCaretPos(CharWidth*TheCol,CharHeight*TheRow);
   }
}

void PaintClass::PaintSetCol(int Col)
{RECT Rect;
 if((unsigned)Col<NCOLS)
   {
    Rect.left   = CharWidth * MIN(TheCol,Col);
    Rect.right  = CharWidth * MAX(TheCol+1,Col+1);
    Rect.top    = 0;
    Rect.bottom = CharHeight * TheRow;
    InvalidateRect(hMainWnd,&Rect,TRUE);
    TheCol = Col;
    SetCaretPos(CharWidth*TheCol,CharHeight*TheRow);
   }
}

void PaintClass::PaintClearScreen(void)
{HBRUSH hBrush;
 RECT   Rect;
 HDC    hDC;
 ClearBuffer();
 hDC = GetDC(hMainWnd);
 hBrush = CreateSolidBrush(RGB(255,255,255));
 SetRect(&Rect, 0,0, NCOLS*CharWidth, NROWS*CharHeight);
 FillRect(hDC,&Rect,hBrush);
 SetCaretPos(0,0);
 InvalidateRect(hMainWnd,&Rect,TRUE);
 ReleaseDC(hMainWnd,hDC);
}

void PaintClass::PaintClearEOL(void)
{int    i;
 HBRUSH hBrush;
 RECT   Rect;
 HDC    hDC;
 char   *Ptr;
 Ptr = RowPtr[TheRow] + TheCol;
 for(i=TheCol;i<NCOLS;i++) *(Ptr++) = ' ';
 hDC = GetDC(hMainWnd);
 hBrush = CreateSolidBrush(RGB(255,255,255));
 SetRect(&Rect,
         TheCol*CharWidth, TheRow*CharHeight,
         NCOLS*CharWidth,  (TheRow+1)*CharHeight);
 FillRect(hDC,&Rect,hBrush);
 InvalidateRect(hMainWnd,&Rect,TRUE);
 ReleaseDC(hMainWnd,hDC);
}

void PaintClass::PaintMain(HDC hDC,PAINTSTRUCT *ps)
{int Row;
 int FirstRow;
 int FirstCol;
 int NbrRows;
 int NbrCols;
 int ColWidth;
 int X;
 int Y;
 RECT rect;
 // set colors
 // compute row & col stuff
 FirstRow = ps->rcPaint.top  / CharHeight;
 FirstCol = ps->rcPaint.left / CharWidth;
 NbrRows = (ps->rcPaint.bottom - ps->rcPaint.top)  / CharHeight;
 ColWidth = ps->rcPaint.right  - ps->rcPaint.left;
 NbrCols = MIN(NCOLS,(1+ColWidth) / CharWidth);
 X = ps->rcPaint.left;
 // consider each row
 for(Row=FirstRow;Row<FirstRow+NbrRows;Row++)
   {// paint part of row
    if((Row>=0)&&(Row<NROWS))
      {// good row number
       Y = CharHeight*Row;
       // compute bounding rectangle
       rect.left = X;
       rect.top  = Y;
       rect.right  = X + ColWidth;
       rect.bottom = Y + CharHeight;
       // paint it
       SetBkMode(hDC,OPAQUE);
       ExtTextOut(hDC,X,Y,ETO_OPAQUE|ETO_CLIPPED,&rect,RowPtr[Row]+FirstCol,NbrCols,NULL);
      }
   }
} // end PaintMain

void PaintClass::WriteTheString(LPSTR String, int Count)
{int i;
 char TheChar;
 RECT rect;
 TopRow = TheRow;
 LeftCol = TheCol;
 RightCol = TheCol;
 for(i=0;i<Count;i++)
   {TheChar = (char) (0x7f & (*String++));
    switch(TheChar)
     {case BS:
        if(TheCol>0)
          {*(RowPtr[TheRow]+TheCol) = ' ';
           TheCol--;
          }
        break;
      case LF:
        // next line
        if(++TheRow>=NROWS) DoTheScroll();
        //break;
      case CR:
        TheCol = 0;
        LeftCol = 0;
        break;
      default:
        // put char into display buffer
        *(RowPtr[TheRow]+TheCol) = (char)TheChar;
        // increment 'cursor'
        if(++TheCol>=NCOLS)
          {// next line
           TheCol = 0;
           LeftCol = 0;
           if(++TheRow>=NROWS) DoTheScroll();
          }
        else RightCol++;
        break;
     } // end switch
   } // end for
 // compute invalid rectangle
 if((TopRow!=TheRow)||(LeftCol!=TheCol)||(RightCol!=TheCol))
   {rect.left = CharWidth * LeftCol;
    rect.top  = CharHeight * TopRow;
    rect.right  = CharWidth * (RightCol+1);
    rect.bottom = CharHeight * (TheRow+1);
    InvalidateRect(hMainWnd,&rect,TRUE);
    UpdateWindow(hMainWnd);
   }
}  // end WriteTheString

void PaintClass::DisplayLine(LPSTR Ptr)
{WriteTheString(Ptr,lstrlen(Ptr));
 WriteTheString(EndOfLine,1);
} // end DisplayLine

void PaintClass::DisplayString(LPSTR Ptr)
{WriteTheString(Ptr,lstrlen(Ptr));
}

void PaintClass::DisplayChar(char Chr)
{WriteTheString(&Chr,1);
}
