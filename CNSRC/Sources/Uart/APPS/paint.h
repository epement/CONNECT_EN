void PaintInit(void);
void PaintMain(HDC,PAINTSTRUCT *);
void ScrollBuffer(void);
void WriteTheString(LPSTR,int);
int  PaintGetRowPos(void);
int  PaintGetColPos(void);
int  PaintGetRow(void);
int  PaintGetCol(void);
void PaintSetRow(int);
void PaintSetCol(int);
void PaintClearScreen(void);
void PaintClearEOL(void);
void DisplayLine(LPSTR);
void DisplayString(LPSTR);
void DisplayChar(char);

#define NROWS 25
#define NCOLS 80
