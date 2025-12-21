#include <windows.h>
#include <stdio.h>

void main(void)
{
 if (timeBeginPeriod(1) == TIMERR_NOERROR) getch();
 /* while(1) Sleep(1); */
}

