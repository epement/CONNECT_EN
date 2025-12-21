{$M 16384,0,655360}
{.$A+,B-,D+,E+,F-,G-,I-,L+,N+,O-,P-,Q-,R-,S-,T-,V+,X+,Y+}
{$A+,B-,D+,E+,F+,G-,I-,L+,N+,O+,P-,Q-,R-,S-,T-,V-,X+,Y-}

uses
 Dos, Crt, Win, TpString, int2f;

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

procedure AddStr(var S: String; C: Char; Count: Byte); assembler;
asm
 mov cl, Count
 xor ch, ch
 jcxz @@1
@@0:
 les di, S
 inc byte ptr es:[di]
 mov al, byte ptr es:[di]
 xor ah, ah
 add di, ax
 mov al, C
 mov byte ptr es:[di], al
 loop @@0
@@1:
end;

function Size2str(Size: Real): String;
var
 S: String;
 c: Char;
begin
 if Size > 1073741824.0 then
  begin
   Size := Size / 1073741824.0;
   c := 'G';
  end
 else
 if Size > 1048576.0 then
  begin
   Size := Size / 1048576.0;
   c := 'M';
  end
 else
 if Size > 1024.0 then
  begin
   Size := Size / 1024.0;
   c := 'K';
  end
 else c := ' ';

 Str(Size:4:0, S);
 Size2str := S+c;
end;

function HexL(L: Longint): String;
var
 S: String;
begin
 if L >= $10000 then S := tpString.HexL(L)
 else S := tpString.HexW(L);
 while (S[1] = '0') and (Length(S) > 4) do Delete(S, 1, 1);
 HexL := S;
end;

function Confirm: Boolean;
var
 SWin: WinState;
 SWinBuf : Array[0..260] of byte;
 SaveCursor: Word;
 Result: Boolean;
begin
 SaveWin(SWin);
 Window(28, 8, 53, 12);
 ReadWin(SWinBuf);
 FrameWin(' Confirm ', DoubleFrame, $4e, $4e);
 TextColor($e);
 TextBackground($4);
 ClrScr;
 SaveCursor := GetCursorState;
 SetCursorState($2000);

 WriteStr(4,2,'Abort Copy ? (Y/N)', $4e);
 Result := not (ReadKey in ['Y', 'y']);

 SetCursorState(SaveCursor);
 UnFrameWin;
 WriteWin(SWinBuf);
 RestoreWin(SWin);
 Confirm := Result;
end;

function MoveBar(Max, Current: Real): Longint;
const
 BarLength = 40;
var
 Width: Byte;
 Result: Longint;
 SBar: String[BarLength + 2];
begin
 SBar := ''; Result := 0;
 if Max < 0 then AddStr(SBar, ' ', BarLength)
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
 if (Max > 0) and (Current > 0) then
  begin
   WriteStr(21, 4, Long2Str(Trunc(100*Current/Max)) + '%    ', $7e);
   WriteStr(15,2,Size2str(Current) + '  of ' + Size2str(Max) + '   ', $7e);
  end;
 if KeyPressed and (ReadKey = #27) then
  begin
   if Confirm then Result := 0
   else
    begin
     Result := 1;
     WriteStr(3, 3, SBar, $70);
    end;
  end;
 MoveBar := Result;
end;

function WriteProgress(LowLowCopy, LowHighCopy,
                       HighLowCopy, HighHighCopy,
                       LowLowSize, LowHighSize,
                       HighLowSize, HighHighSize: Word): Longint;
var
 Result: Longint; {Low = 0 - continue copy, Low = 1 - cancel copy}
                  {High = CopyProgressRoutine return value}
 Copy, Size: Real;
 Key: Char;

 L, L1: Longint;
begin
 Copy := LowLowCopy + LowHighCopy * 65536.0 +
         HighLowCopy * 4294967296.0;

 Size := LowLowSize + LowHighSize * 65536.0 +
         HighLowSize * 4294967296.0;

 Result := MoveBar(Size, Copy);

 for L := 0 to 100 do
 for L1 := 0 to 1000000 do
  begin
  asm
   nop
  end;
  end;

 WriteProgress := Result;
end;

procedure progress; far; assembler;
asm
 push ax
 push bx
 push cx
 push dx
 push si
 push di
 push es
 push ds
 mov ax, SEG @Data
 mov ds, ax
 call WriteProgress
 nop
 nop
 dw $0C4C4 {VDDUnSimulate16}
 db $0FE
end;


var
 Result: Boolean;

begin
 Inst_CN_NT;
 SaveWin(SWin);
 Window(18, 10, 63, 16);
 ReadWin(SWinBuf);
 FrameWin(' Copy progress ', DoubleFrame, $7f, $7f);
 TextColor(0);
 TextBackground(7);
 ClrScr;
 SaveCursor := GetCursorState;
 SetCursorState($2000);

 Result := SysCopy(ParamStr(1),
                   ParamStr(2),
                   2,
                   @progress);

 MoveBar(-1, -1);
 if Result then WriteStr(10,3,'Copy OK.  Press any key.', $70)
 else WriteStr(10,3,'Copy FAIL. Press any key.', $70);
 ReadKey;

 SetCursorState(SaveCursor);
 UnFrameWin;
 WriteWin(SWinBuf);
 RestoreWin(SWin);

end.