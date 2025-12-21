// PaintClass.h

class PaintClass
  {//private:
   public:
     PaintClass(HWND hWnd);
     ~PaintClass(void);
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
   };
