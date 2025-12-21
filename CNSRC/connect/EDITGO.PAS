{$F+,O+,X+}
unit EditGo;

interface

uses Drivers, FEditor;

procedure ScrollPrim(Editor: PFileEditor; var Event: TEvent);
procedure GoRightPrim(Editor: PFileEditor);
procedure GoLeftPrim(Editor: PFileEditor);
procedure GoWhileKeyDownPrim(Editor: PFileEditor; Key: Byte);
procedure GoDownPrim(Editor: PFileEditor);
procedure GoUpPrim(Editor: PFileEditor);
procedure GoPgDnPrim(Editor: PFileEditor);
procedure GoPgUpPrim(Editor: PFileEditor);
procedure GoCtrlPgDnPrim(Editor: PFileEditor);
procedure GoCtrlPgUpPrim(Editor: PFileEditor);
procedure GoCtrlRightPrim(Editor: PFileEditor);
procedure GoCtrlLeftPrim(Editor: PFileEditor);
procedure GoCtrlUpPrim(Editor: PFileEditor);
procedure GoCtrlDownPrim(Editor: PFileEditor);
procedure GoHomePrim(Editor: PFileEditor);
procedure GoEndPrim(Editor: PFileEditor);
procedure GoCtrlHomePrim(Editor: PFileEditor);
procedure GoCtrlEndPrim(Editor: PFileEditor);

implementation

uses CNCrt, Views, EditMsg, EditPrim, EditTabl, Keyboard,
  TPString, Defaults;

procedure ScrollPrim(Editor: PFileEditor; var Event: TEvent);
begin
  with Editor^ do
  begin
    case Event.KeyCode of
      kbDown:      GoDown;
      kbUp:        GoUp;
      kbRight:     GoRight;
      kbLeft:      GoLeft;
      kbPgDn:      GoPgDn;
      kbPgUp:      GoPgUp;
      kbCtrlPgDn:  GoCtrlPgDn;
      kbCtrlPgUp:  GoCtrlPgUp;
      kbCtrlRight: GoCtrlRight;
      kbCtrlLeft:  GoCtrlLeft;
      kbCtrlUp:    GoCtrlUp;
      kbCtrlDn:    GoCtrlDown;
      kbHome:      GoHome;
      kbEnd:       GoEnd;
      kbCtrlHome:  GoCtrlHome;
      kbCtrlEnd:   GoCtrlEnd;
      kbIns:       ToggleInsert;
      kbDel:       DeleteChar(Delta.Y + Cursor.Y, GetLinePos + 1, False);
      else         Exit;
    end;
    if (KeyboardOptions and koDisableMultiScroll = 0) and
       (GetShiftState and kbScrollState <> 0) and
       not MultiScrolling and IsScrollKey(Event.KeyCode) then
         MultiScroll(PWindow(Owner), Event.KeyCode);
  end;
  Event.What := evNothing;
end;

procedure GoRightPrim(Editor: PFileEditor);
begin
  with Editor^ do if Delta.X + Cursor.X < Pred(Limit.X) then
  begin
    SetCursor(Succ(Cursor.X), Cursor.Y);
    if Cursor.X = Size.X then ScrollTo(Succ(Delta.X), Delta.Y)
    else if LocalEditOptions and eoHilitCurColumn <> 0 then DrawView;
  end;
end;

procedure GoLeftPrim(Editor: PFileEditor);
begin
  with Editor^ do if Delta.X + Cursor.X > 0 then
  begin
    SetCursor(Pred(Cursor.X), Cursor.Y);
    if Cursor.X < 0 then ScrollTo(Pred(Delta.X), Delta.Y)
    else if LocalEditOptions and eoHilitCurColumn <> 0 then DrawView;
  end;
end;

procedure GoWhileKeyDownPrim(Editor: PFileEditor; Key: Byte);
begin
  if MultiScrolling or
    ((KeyboardOptions and koDisableMultiScroll = 0) and
     (GetShiftState and kbScrollState <> 0)) then Exit;
  repeat
    if (KbdStatus <> Key) and (KbdStatus <> 224) then Exit;
  until KeyPressed;
  with Editor^ do
  repeat
    ClearKbd;
    if (KbdStatus <> Key) and (KbdStatus <> 224) then Exit;
    case Key of
      72: if Delta.Y + Cursor.Y = 0 then Exit
          else FastScrollTo(Delta.Y - 1);
      73: if Delta.Y = 0 then Exit
          else FastScrollTo(Delta.Y - Size.Y + 1);
      80: if Delta.Y + Cursor.Y >= FileLines^.Count then Exit
          else FastScrollTo(Delta.Y + 1);
      81: if Delta.Y + Size.Y >= FileLines^.Count then Exit
          else FastScrollTo(Delta.Y + Size.Y - 1);
    end;
    Indicator^.DrawView;
    if KbdDelay <> 0 then Delay(KbdDelay);
  until False;
end;

procedure GoDownPrim(Editor: PFileEditor);
begin
  with Editor^ do if Delta.Y + Cursor.Y < FileLines^.Count then
  begin
    DrawFromTop := False;
    if Cursor.Y <> Size.Y - 1 then
    begin
      SetCursor(Cursor.X, Cursor.Y + 1);
      if LocalEditOptions and eoHilitCurLine <> 0 then DrawView;
    end
    else
    begin
      FastScrollTo(Delta.Y + 1);
      if ((KbdStatus = 80) or (KbdStatus = 224)) and
         (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
        GoWhileKeyDown(80);
    end;
  end;
end;

procedure GoUpPrim(Editor: PFileEditor);
begin
  with Editor^ do if Delta.Y + Cursor.Y > 0 then
  begin
    DrawFromTop := True;
    if Cursor.Y > 0 then
    begin
      SetCursor(Cursor.X, Cursor.Y - 1);
      if LocalEditOptions and eoHilitCurLine <> 0 then DrawView;
    end
    else
    begin
      FastScrollTo(Delta.Y - 1);
      if ((KbdStatus = 72) or (KbdStatus = 224)) and
         (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
        GoWhileKeyDown(72);
    end;
  end;
end;

procedure GoPgDnPrim(Editor: PFileEditor);
begin
  with Editor^ do
  begin
    if Delta.Y + Size.Y >= FileLines^.Count then GoCtrlPgDn
    else
    begin
      DrawFromTop := False;
      FastScrollTo(Delta.Y + Size.Y - 1);
      if ((KbdStatus = 81) or (KbdStatus = 224)) and
         (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
        GoWhileKeyDown(81);
    end;
    if Delta.Y + Cursor.Y > FileLines^.Count then
      SetCursor(Cursor.X, FileLines^.Count - Delta.Y);
  end;
end;

procedure GoPgUpPrim(Editor: PFileEditor);
begin
  with Editor^ do
  begin
    DrawFromTop := True;
    if Delta.Y = 0 then GoCtrlPgUp
    else
    begin
      FastScrollTo(Delta.Y - Size.Y + 1);
      if ((KbdStatus = 73) or (KbdStatus = 224)) and
         (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
        GoWhileKeyDown(73);
    end;
  end;
end;

procedure GoCtrlPgDnPrim(Editor: PFileEditor);
begin
  with Editor^ do
  begin
    DrawFromTop := True;
    GoToPos(0, FileLines^.Count);
    GoEnd;
  end;
end;

procedure GoCtrlPgUpPrim(Editor: PFileEditor);
begin
  with Editor^ do
  begin
    DrawFromTop := True;
    GoToPos(0, 0);
  end;
end;

procedure GoCtrlRightPrim(Editor: PFileEditor);
var
  S: String;
begin
  with Editor^ do
  begin
    GetValidLine(Delta.Y + Cursor.Y, S);
    if (GetLinePos >= Byte(S[0])) or (GetLinePos >= Limit.X - 1) then
    begin
      GoDown;
      GoHome;
    end
    else
    begin
      DrawFlag := True;
      if GetShiftState and (kbAltShift + kbCtrlShift) =
	kbAltShift + kbCtrlShift then
      begin
	while (GetLinePos < Byte(S[0])) and (GetLinePos < Limit.X - 1) and
	  not WordChar(S[GetLinePos + 1]) do GoRight;
	while (GetLinePos < Byte(S[0])) and (GetLinePos < Limit.X - 1) and
	  WordChar(S[GetLinePos + 1]) do GoRight;
      end
      else
      begin
	while (GetLinePos < Byte(S[0])) and (GetLinePos < Limit.X - 1) and
	  WordChar(S[GetLinePos + 1]) do GoRight;
	while (GetLinePos < Byte(S[0])) and (GetLinePos < Limit.X - 1) and
	  not WordChar(S[GetLinePos + 1]) do GoRight;
      end;
      DrawFlag := False;
      DrawView;
    end;
  end;
end;

procedure GoCtrlLeftPrim(Editor: PFileEditor);
var
  S: String;
begin
  with Editor^ do
  begin
    GetValidLine(Delta.Y + Cursor.Y, S);
    if GetLinePos = 0 then
    begin
      GoUp;
      GoEnd;
    end
    else
    begin
      DrawFlag := True;
      if GetShiftState and (kbAltShift + kbCtrlShift) =
	kbAltShift + kbCtrlShift then
      begin
	if GetLinePos > Byte(S[0]) then GoEnd
	else
	begin
	  while (GetLinePos > 0) and
	    WordChar(S[GetLinePos]) do GoLeft;
	  while (GetLinePos > 0) and
	    not WordChar(S[GetLinePos]) do GoLeft;
	end;
      end
      else
      begin
	if GetLinePos > Byte(S[0]) then GoEnd;
	while (GetLinePos > 0) and
	  not WordChar(S[GetLinePos]) do GoLeft;
	while (GetLinePos > 0) and
	  WordChar(S[GetLinePos]) do GoLeft;
      end;
      DrawFlag := False;
      DrawView;
    end;
  end;
end;

procedure GoCtrlUpPrim(Editor: PFileEditor);
begin
  with Editor^ do
    if not MultiScrolling and
      (GetShiftState and (kbAltShift + kbCtrlShift) =
	kbAltShift + kbCtrlShift) then SwapLinesPrim(
	  Editor, Delta.Y + Cursor.Y, True)
    else FastScrollTo(Delta.Y - 1);
end;

procedure GoCtrlDownPrim(Editor: PFileEditor);
begin
  with Editor^ do
    if not MultiScrolling and
      (GetShiftState and (kbAltShift + kbCtrlShift) =
	kbAltShift + kbCtrlShift) then SwapLinesPrim(
	  Editor, Delta.Y + Cursor.Y, False)
  else
  begin
    FastScrollTo(Delta.Y + 1);
    if Delta.Y + Cursor.Y > FileLines^.Count then
    begin
      SetCursor(Cursor.X, Cursor.Y - 1);
      if LocalEditOptions and eoHilitCurLine <> 0 then DrawView;
    end;
  end;
end;

procedure GoHomePrim(Editor: PFileEditor);
var
  X: Byte;
  Y: Integer;
  S: String;
begin
  with Editor^ do
  begin
    Y := Delta.Y + Cursor.Y;
    if State and sfDrawing <> 0 then
      X := GetNextVertPos(Editor, Y, Delta.X + Cursor.X + 1, True)
    else if NewLocalOptions and neoHomeToggles = 0 then X := 0
    else
    begin
      GetValidLine(Y, S);
      X := 1;
      while (X <= Length(S)) and (S[X] = ' ') do Inc(X);
      Dec(X);
      if Delta.X + Cursor.X = X then X := 0;
    end;
    GoToPos(X, Y);
  end;
end;

procedure GoEndPrim(Editor: PFileEditor);
var
  X: Byte;
  Y: Integer;
  S: String;
begin
  with Editor^ do
  begin
    Y := Delta.Y + Cursor.Y;
    if State and sfDrawing <> 0 then
      X := GetNextVertPos(Editor, Y, Delta.X + Cursor.X + 1, False)
    else
    begin
      GetValidLine(Y, S);
      if NewLocalOptions and neoTrailingBlanks = 0 then	TrailTrim(S);
      X := Length(S);
    end;
    GoToPos(X, Y);
  end;
end;

procedure GoCtrlHomePrim(Editor: PFileEditor);
begin
  with Editor^ do
  begin
    SetCursor(Cursor.X, 0);
    if LocalEditOptions and eoHilitCurLine <> 0 then DrawView;
  end;
end;

procedure GoCtrlEndPrim(Editor: PFileEditor);
var
  NewY: Integer;
begin
  with Editor^ do
  begin
    if Delta.Y + Size.Y > FileLines^.Count then
      NewY := FileLines^.Count - Delta.Y else NewY := Size.Y - 1;
    SetCursor(Cursor.X, NewY);
    if LocalEditOptions and eoHilitCurLine <> 0 then DrawView;
  end;
end;

end.