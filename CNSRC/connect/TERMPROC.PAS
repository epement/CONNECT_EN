{$F+,O+,X+}
unit TermProc;

interface

procedure Backspace;
procedure BackTab;
procedure Bell;
procedure CarriageReturn;
procedure Clear;
procedure ClearToCursor;
procedure ClearToEOL;
procedure ClearToEOS;
procedure CRLF;
procedure CursorDown(I: Integer);
procedure CursorInvisible;
procedure CursorLeft(I: Integer);
procedure CursorLowerLeft;
procedure CursorRight(I: Integer);
procedure CursorUp(I: Integer);
procedure CursorVisible;
procedure DeleteChar(I: Integer);
procedure DeleteLine(I: Integer);
procedure EndInsertMode;
procedure EndUnderline;
procedure EraseChar(I: Integer);
procedure InsertChar(I: Integer);
procedure InsertLine(I: Integer);
procedure MoveDown;
procedure MoveUp;
procedure NewLine;
procedure RepeatChar(C: Char; I: Integer);
procedure RestoreCursor;
procedure SaveCursor;
procedure ScrollDown(I: Integer);
procedure ScrollUp(I: Integer);
procedure SetAttr(A: Pointer; I: Integer);
procedure SetBackColor(I: Integer);
procedure SetBlinking;
procedure SetBold;
procedure SetCursorTo(Y, X: Integer);
procedure SetDark;
procedure SetForeColor(I: Integer);
procedure SetGraphChars(var S: String; C: Char);
procedure SetGraphMode(M: Byte);
procedure SetHalfBright;
procedure SetInverse;
procedure SetNormal;
procedure SetScrollRegion(L, H: Integer);
procedure SetUnderline;
procedure StartInsertMode;
procedure Tab;
procedure UnderlineChar;

implementation

uses Objects, Drivers, Views, OutWin, Terminal, Defaults;

procedure Backspace;
var
  P: ^TDrawBuffer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    if Delta.X + Cursor.X > 0 then
    begin
      SetCursor(Cursor.X - 1, Cursor.Y);
      if Cursor.X < 0 then ScrollTo(Delta.X - 1, Delta.Y);
      if TerminalOptions and ooDestructiveBS <> 0 then
      begin
	P := OutputCollection^.At(Delta.Y + Cursor.Y);
	if P <> nil then WordRec(P^[Delta.X + Cursor.X]).Lo := 0;
      end;
    end;
  end;
end;

procedure BackTab;
var
  I: Integer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    I := (Delta.X + Cursor.X) mod 8;
    if I = 0 then I := 8;
    SetCursor(Cursor.X - I, Cursor.Y);
    if Cursor.X < 0 then ScrollTo(Delta.X + Cursor.X, Delta.Y);
    if Cursor.X < 0 then SetCursor(0, Cursor.Y);
  end;
end;

procedure Bell;
begin
  if not DisableSounds then Write(^G);
end;

procedure CR_LF(CR, LF: Boolean);
begin
  with PTerminal(TheTerminal)^ do
  begin
    if CR then
    begin
      ScrollTo(0, Delta.Y);
      SetCursor(0, Cursor.Y);
    end;
    if LF then Enter;
  end;
end;

procedure CarriageReturn;
begin
  CR_LF(True, TerminalOptions and ooAddLineFeed <> 0);
end;

procedure Clear;
begin
  PTerminal(TheTerminal)^.Clear;
end;

procedure ClearLine(Eol: Boolean);
var
  C: Byte;
  P: ^TDrawBuffer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    P := OutputCollection^.At(Delta.Y + Cursor.Y);
    if P = nil then Exit;
    C := CurColor;
    if C = 0 then C := $07;
    if Eol then MoveChar(P^[Delta.X + Cursor.X], ' ', C,
      MaxViewWidth - Delta.X - Cursor.X)
    else MoveChar(P^, ' ', C, Delta.X + Cursor.X + 1);
    DrawView;
  end;
end;

procedure ClearToCursor;
begin
  ClearLine(False);
end;

procedure ClearToEOL;
begin
  ClearLine(True);
end;

procedure ClearToEOS;
var
  C: Byte;
  I: Integer;
  P: ^TDrawBuffer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    C := CurColor;
    if C = 0 then C := $07;
    for I := Delta.Y + Cursor.Y + 1 to OutputCollection^.Count - 1 do
    begin
      P := OutputCollection^.At(I);
      if P = nil then Break;
      MoveChar(P^, ' ', C, MaxViewWidth);
    end;
    ClearLine(True);
  end;
end;

procedure CRLF;
begin
  CR_LF(True, True);
end;

procedure CursorDown(I: Integer);
begin
  with PTerminal(TheTerminal)^ do SetCursorTo(Delta.Y + Cursor.Y + I, -1);
end;

procedure CursorInvisible;
begin
  PTerminal(TheTerminal)^.HideCursor;
end;

procedure CursorLeft(I: Integer);
begin
  with PTerminal(TheTerminal)^ do SetCursorTo(-1, Delta.X + Cursor.X - I);
end;

procedure CursorLowerLeft;
begin
  with PTerminal(TheTerminal)^ do SetCursorTo(Delta.Y + Size.Y -1, 0);
end;

procedure CursorRight(I: Integer);
begin
  with PTerminal(TheTerminal)^ do SetCursorTo(-1, Delta.X + Cursor.X + I);
end;

procedure CursorUp(I: Integer);
begin
  with PTerminal(TheTerminal)^ do SetCursorTo(Delta.Y + Cursor.Y - I, -1);
end;

procedure CursorVisible;
begin
  PTerminal(TheTerminal)^.ShowCursor;
end;

procedure DeleteChar(I: Integer);
var
  P: ^TDrawBuffer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    P := OutputCollection^.At(Delta.Y + Cursor.Y);
    if P = nil then Exit;
    if Delta.X + Cursor.X + I > GetWidth then
      I := GetWidth - Delta.X - Cursor.X;
    Move(P^[Delta.X + Cursor.X + I], P^[Delta.X + Cursor.X],
      (GetWidth - Delta.X - Cursor.X - I) * 2);
    MoveChar(P^[GetWidth - I], ' ', 0, I);
    DrawFlag := True;
    DrawView;
    DrawFlag := False;
  end;
end;

procedure DeleteLine(I: Integer);
var
  C: Integer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    ValidLoHi;
    if Delta.Y + Cursor.Y > HiY then Exit;
    if Delta.Y + Cursor.Y + I > HiY + 1 then
      I := HiY + 1 - Delta.Y - Cursor.Y;
    for C := 1 to I do
    begin
      OutputCollection^.AtFree(Delta.Y + Cursor.Y);
      NewLine(HiY);
    end;
    DrawView;
  end;
end;

procedure EndInsertMode;
begin
  TerminalOptions := TerminalOptions and not toInsMode;
end;

procedure EndUnderline;
begin
  SetNormal;
end;

procedure EraseChar(I: Integer);
begin
  RepeatChar(' ', I);
end;

procedure InsertChar(I: Integer);
var
  P: ^TDrawBuffer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    P := OutputCollection^.At(Delta.Y + Cursor.Y);
    if P = nil then Exit;
    if Delta.X + Cursor.X + I > GetWidth then
      I := GetWidth - Delta.X - Cursor.X;
    Move(P^[Delta.X + Cursor.X], P^[Delta.X + Cursor.X + I],
      (GetWidth - Delta.X - Cursor.X - I) * 2);
    MoveChar(P^[Delta.X + Cursor.X], ' ', 0, I);
    DrawFlag := True;
    DrawView;
    DrawFlag := False;
  end;
end;

procedure InsertLine(I: Integer);
var
  C: Integer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    ValidLoHi;
    if Delta.Y + Cursor.Y > HiY then Exit;
    if Delta.Y + Cursor.Y + I > HiY + 1 then
      I := HiY - Delta.Y - Cursor.Y;
    for C := 1 to I do
    begin
      OutputCollection^.AtFree(HiY);
      NewLine(Delta.Y + Cursor.Y);
    end;
    DrawView;
  end;
end;

procedure MoveDown;
begin
  PTerminal(TheTerminal)^.EscDn;
end;

procedure MoveUp;
begin
  PTerminal(TheTerminal)^.EscUp;
end;

procedure NewLine;
begin
  CR_LF(TerminalOptions and ooAddReturn <> 0, True);
end;

procedure RepeatChar(C: Char; I: Integer);
var
  P: ^TDrawBuffer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    P := OutputCollection^.At(Delta.Y + Cursor.Y);
    if P = nil then Exit;
    if Delta.X + Cursor.X + I > GetWidth then
      I := GetWidth - Delta.X - Cursor.X;
    MoveChar(P^[Delta.X + Cursor.X], C, 0, I);
    DrawFlag := True;
    DrawView;
    DrawFlag := False;
  end;
end;

procedure RestoreCursor;
begin
  with PTerminal(TheTerminal)^ do
  begin
    ScrollTo(SaveDelta.X, SaveDelta.Y);
    SetCursor(SaveCursor.X, SaveCursor.Y);
  end;
end;

procedure SaveCursor;
begin
  with PTerminal(TheTerminal)^ do
  begin
    SaveDelta := Delta;
    SaveCursor := Cursor;
  end;
end;

procedure ScrollDown(I: Integer);
var
  C: Integer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    ValidLoHi;
    if I > HiY - LoY + 1 then I := HiY - LoY + 1;
    for C := 1 to I do
    begin
      OutputCollection^.AtFree(HiY);
      NewLine(LoY);
    end;
    DrawView;
  end;
end;

procedure ScrollUp(I: Integer);
var
  C: Integer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    ValidLoHi;
    if I > HiY - LoY + 1 then I := HiY - LoY + 1;
    for C := 1 to I do
    begin
      OutputCollection^.AtFree(LoY);
      NewLine(HiY);
    end;
    DrawView;
  end;
end;

procedure SetAttr(A: Pointer; I: Integer);
var
  B, C: Integer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    for B := 0 to I - 1 do
    begin
      C := PWordArray(A)^[B];
      case C of
	0: CurColor := $07;
	1: CurColor := CurColor or $8;
	2: CurColor := CurColor and not $8;
	4: CurColor := $01;
	5: CurColor := CurColor or $80;
	7: CurColor := (CurColor and $0F) shl 4 or
	  (CurColor and $F0) shr 4;
	8: CurColor := 0;
	30..37: CurColor := CurColor and $F0 or ANSIColors[C] or
	  (CurColor and $0F and $8);
	40..47: CurColor := CurColor and $0F or
	  (ANSIColors[C - 10] shl 4) or (CurColor and $F0 and $80);
      end;
    end;
    CurColor := MapColor(CurColor);
  end;
end;

procedure SetSingleAttr(I: Integer);
begin
  SetAttr(@I, 1);
end;

procedure SetBackColor(I: Integer);
begin
  SetSingleAttr(I);
end;

procedure SetBlinking;
begin
  SetSingleAttr(5);
end;

procedure SetBold;
begin
  SetSingleAttr(1);
end;

procedure SetCursorTo(Y, X: Integer);
begin
  with PTerminal(TheTerminal)^ do
  begin
    if Y < 0 then Y := Delta.Y + Cursor.Y
    else if Y >= Limit.Y then Y := Limit.Y - 1;
    if X < 0 then X := Delta.X + Cursor.X
    else if X >= Limit.X then X := Limit.X - 1;
    SetCursor(X - Delta.X, Y - Delta.Y);
    if Cursor.X < 0 then ScrollTo(Delta.X + Cursor.X, Delta.Y)
    else if Cursor.X >= Size.X then
      ScrollTo(Delta.X + Cursor.X - Size.X + 1, Delta.Y);
    if Cursor.Y < 0 then ScrollTo(Delta.X, Delta.Y + Cursor.Y)
    else if Cursor.Y >= Size.Y then
      ScrollTo(Delta.X, Delta.Y + Cursor.Y - Size.Y + 1);
  end;
end;

procedure SetDark;
begin
  SetSingleAttr(8);
end;

procedure SetForeColor(I: Integer);
begin
  SetSingleAttr(I);
end;

procedure SetGraphChars(var S: String; C: Char);
var
  B, L: Byte;
begin
  if C = 't' then B := 1
  else B := (Byte(C) - $30) shl 4 + 1;
  L := Length(S);
  if L > $10 then L := $10;
  Move(S[1], PTerminal(TheTerminal)^.GraphChars[B], L);
end;

procedure SetGraphMode(M: Byte);
begin
  PTerminal(TheTerminal)^.GraphMode := M;
end;

procedure SetHalfBright;
begin
  SetSingleAttr(2);
end;

procedure SetInverse;
begin
  SetSingleAttr(7);
end;

procedure SetNormal;
begin
  SetSingleAttr(0);
end;

procedure SetScrollRegion(L, H: Integer);
begin
  with PTerminal(TheTerminal)^ do
  begin
    LoY := L;
    HiY := H;
    ScrollTo(0, 0);
    SetCursor(0, 0)
  end;
end;

procedure SetUnderline;
begin
  SetSingleAttr(4);
end;

procedure StartInsertMode;
begin
  TerminalOptions := TerminalOptions or toInsMode;
end;

procedure Tab;
var
  I: Integer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    I := 9 - ((Delta.X + Cursor.X + 1) mod 8);
    if I = 9 then I := 1;
    SetCursor(Cursor.X + I, Cursor.Y);
    if Cursor.X >= Size.X then
      ScrollTo(Delta.X + Cursor.X - Size.X + 1, Delta.Y);
    if Cursor.X >= Size.X then SetCursor(Size.X - 1, Cursor.Y);
  end;
end;

procedure UnderlineChar;
var
  P: ^TDrawBuffer;
begin
  with PTerminal(TheTerminal)^ do
  begin
    P := OutputCollection^.At(Delta.Y + Cursor.Y);
    if P = nil then Exit;
    MoveChar(P^[Delta.X + Cursor.X], #0, $01, 1);
    DrawFlag := True;
    DrawView;
    DrawFlag := False;
  end;
  CursorRight(1);
end;

end.
