uses
 Dos, Crt, Win, TpString;

var
 SWin: WinState;
 SWinBuf : Array[0..700] of byte;
 Upr: Byte;
 ErrAddr: Longint;
 SaveCursor: Word;

function GetCursorState: Word; assembler;
asm
        MOV      AH,3
        XOR      BH,BH
        INT      10H
        MOV      AX,CX
end;

procedure SetCursorState(State: Word); assembler;
asm
        MOV      AH,1
        XOR      BH,BH
        MOV      CX,State
        INT      10H
end;

Procedure MoveBar(Max, Current: Longint);
const
 BarLength = 40;
var
 Width: Byte;
 SBar: String[BarLength + 2];
begin
 SBar := '';
 if Max = -1 then AddStr(SBar, ' ', BarLength)
 else
  begin
   if Current <> 0 then
     Width := Byte(Trunc(BarLength / (Max / (Current+1))))
   else Width := 0;
   if Width > BarLength then Width := BarLength;
   AddStr(SBar, 'Û', Width);
   AddStr(SBar, '°', BarLength - Width);
  end;
 WriteStr(3, 3, SBar, TextAttr);
 if Current > 0 then
  WriteStr(3, 4, Long2Str(Current) + '           ', $7e)
 else WriteStr(3, 4, '           ', $7e)
end;

begin

 SaveWin(SWin);
 Window(18, 10, 63, 16);
 ReadWin(SWinBuf);
 FrameWin(' Programmator ', DoubleFrame, $7f, $7f);
 TextColor(0);
 TextBackground(7);
 ClrScr;
 SaveCursor := GetCursorState;
 SetCursorState($2000);

 {.....}

 SetCursorState(SaveCursor);
 UnFrameWin;
 WriteWin(SWinBuf);
 RestoreWin(SWin);

end.


