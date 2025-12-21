#include <windows.h>
#include <stdio.h>

/*
typedef struct _KEY_EVENT_RECORD { // ker
    BOOL bKeyDown;
    WORD wRepeatCount;
    WORD wVirtualKeyCode;         // bx
    WORD wVirtualScanCode;        // cx
    union {
        WCHAR UnicodeChar;
        CHAR  AsciiChar;          // ax
    } uChar;
    DWORD dwControlKeyState;      // dx
} KEY_EVENT_RECORD;

typedef struct _MOUSE_EVENT_RECORD { // mer
    COORD dwMousePosition;
    DWORD dwButtonState;
    DWORD dwControlKeyState;
    DWORD dwEventFlags;
} MOUSE_EVENT_RECORD;

*/



void main(void)
{
HANDLE StdIn;
INPUT_RECORD inBuff[128];
DWORD NumberOfEventsRead;
DWORD i;
BOOL Res;



  StdIn = GetStdHandle(STD_INPUT_HANDLE);


while (1)
 {
  Res = PeekConsoleInput(
         StdIn,                     // handle of a console input buffer
         &inBuff,                   // address of the buffer for read data
         128,                         // number of records to read
         &NumberOfEventsRead        // address of number of records read
        );
  if (Res != 0)
   for( i = 0; i < NumberOfEventsRead; i++)
    {
  //printf("wait\n");
  if ((inBuff[i].EventType == KEY_EVENT) &&
      (inBuff[i].Event.KeyEvent.bKeyDown))
   printf(" wRepeatCount = %x\n\r wVirtualKeyCode = %x\n\r\
 wVirtualScanCode = %x\n\r dwControlKeyState = %x\n\r AsciiChar = %c\n\r",
 inBuff[i].Event.KeyEvent.wRepeatCount,
 inBuff[i].Event.KeyEvent.wVirtualKeyCode,
 inBuff[i].Event.KeyEvent.wVirtualScanCode,
 inBuff[i].Event.KeyEvent.dwControlKeyState,
 inBuff[i].Event.KeyEvent.uChar.AsciiChar);

  if ((inBuff[i].EventType == MOUSE_EVENT)&&
      (inBuff[i].Event.MouseEvent.dwEventFlags ==4 ))
   printf(" dwMousePosition %x\n\r dwButtonState %x\n\r dwControlKeyState %x\n\r\
 dwEventFlags %x\n\r",
 inBuff[i].Event.MouseEvent.dwMousePosition,
 inBuff[i].Event.MouseEvent.dwButtonState,
 inBuff[i].Event.MouseEvent.dwControlKeyState,
 inBuff[i].Event.MouseEvent.dwEventFlags);
  }
 }
}
