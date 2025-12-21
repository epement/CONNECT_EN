#include <windows.h>
#include <conio.h>
#include <stdio.h>

void main(void)
{
 char cc;
 do
  {
   if (kbhit())
    {
     cc = getch();
     putch(cc);
    }
  }
 while (cc != 27);

}
