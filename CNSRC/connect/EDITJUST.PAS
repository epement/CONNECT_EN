{$I-,F+,O+,X+}
unit EditJust;

interface

uses FEditor;

procedure IndentBlockPrim(Editor: PFileEditor);
procedure UnindentBlockPrim(Editor: PFileEditor);
procedure JustifyLinePrim(Editor: PFileEditor; AKey: Char);
procedure DeleteEmptyLinesPrim(Editor: PFileEditor);

implementation

uses Objects, Drivers, Views, App, MsgBox, Swaps, EditMsg, EditTabl,
  Keyboard, TPString, Defaults;

procedure IndentBlockPrim(Editor: PFileEditor);
var
  Index, I: Integer;
  Pos: TPos;
  S: String;
begin
  with Editor^ do
  begin
    if IsSelected then
    begin
      SaveLastLine;
      if Area^.PK = 1 then I := Area^.KK - 1
      else I := Area^.KK;
      NewUndoChain(I - Area^.KB + 1);
      DrawStatusLine('Moving the selected block.');
      FastGetLine := True;
      for Index := Area^.KB to I do
      begin
        GetValidLine(Index, S);
        GetPos(Area, Index, Pos);
        System.Insert(' ', S, Pos.AStart);
        ReplaceLine(Index, S);
        if PSwapLinesCollection(FileLines)^.Status = coOverflow then
        begin
          PSwapLinesCollection(FileLines)^.Status := 0;
          Break;
        end;
        if (KbdStatus = 1) and AbortAction then Break;
      end;
      AddUndoChain;
      if Area^.PK > 1 then SetArea(Area, Area^.KB, Area^.PB,
        Area^.KK, Area^.PK + 1);
      IsModified := True;
      DebugModified := True;
    end;
  end;
end;

procedure UnindentBlockPrim(Editor: PFileEditor);
var
  Changed: Boolean;
  Index, I: Integer;
  Pos: TPos;
  S: String;
begin
  with Editor^ do
  begin
    if IsSelected then
    begin
      Changed := False;
      SaveLastLine;
      if Area^.PK = 1 then I := Area^.KK - 1
      else I := Area^.KK;
      FastGetLine := True;
      for Index := Area^.KB to I do
      begin
        GetValidLine(Index, S);
        GetPos(Area, Index, Pos);
        if (Length(S) >= Pos.AStart) and
           (S[Pos.AStart] in [#0, #32, #255]) then
        begin
          System.Delete(S, Pos.AStart, 1);
          if not Changed and (UndoChain = nil) then
          begin
            NewUndoChain(I - Area^.KB + 1);
            DrawStatusLine('Moving the selected block.');
          end;
          ReplaceLine(Index, S);
          Changed := True;
          if PSwapLinesCollection(FileLines)^.Status = coOverflow then
          begin
            PSwapLinesCollection(FileLines)^.Status := 0;
            Break;
          end;
        end;
        if (KbdStatus = 1) and AbortAction then Break;
      end;
      if not Changed then Exit;
      AddUndoChain;
      if (Area^.PB > 1) and not MarkColumns then Dec(Area^.PB);
      if Area^.PK > 1 then Dec(Area^.PK);
      IsModified := True;
      DebugModified := True;
    end;
  end;
end;

procedure JustifyLinePrim(Editor: PFileEditor; AKey: Char);
var
  Pos, B, E, X: Byte;
  I, IB, IE: Integer;
  S: String;

procedure JustifyTableLine;
var
  SS: String;
begin
  with Editor^ do
    if IsSelected and MarkColumns then
      X := Area^.PB + (Area^.PK - Area^.PB) div 2;
  if (X = 0) or (X > Length(S)) then Exit;
  B := X - 1;
  while (B > 0) and not (S[B] in AnyTableChars) do Dec(B);
  Inc(B);
  E := B + 1;
  while (E <= Length(S)) and not (S[E] in AnyTableChars) do Inc(E);
  if E > Length(S) then Exit;
  Dec(E, B);
  SS := Copy(S, B, E);
  TrimSt(SS);
  Delete(S, B, E);
  case AKey of
    'C': SS := LeftPad(SS, E - ((E - Length(SS)) div 2) -
      Byte(Odd(E - Length(SS))));
    'E': SS := LeftPad(SS, E);
  end;
  PadSt(SS, E);
  Insert(SS, S, B);
end;

begin
  with Editor^ do
  begin
    SaveLastLine;
    if IsSelected then
    begin
      IB := Area^.KB;
      if Area^.PK = 1 then IE := Area^.KK - 1
      else IE := Area^.KK;
    end
    else
    begin
      IB := Delta.Y + Cursor.Y;
      IE := IB;
    end;
    X := Delta.X + Cursor.X + 1;
    if X <= 1 then
    begin
      Pos := (LocalEditOptions and not EditOptMask) shr 26;
      case AKey of
        'B': Inc(Pos);
        'C': Inc(Pos, (LocalMaxLineWidth - Pos) div 2);
        else Pos := LocalMaxLineWidth;
      end;
    end
    else Pos := X;
    NewUndoChain(IE - IB + 1);
    DrawStatusLine('Justifying text lines.');
    FastGetLine := True;
    for I := IB to IE do
    begin
      GetValidLine(I, S);
      if (State and sfDrawing <> 0) and
         (TableLine(S) = tlInside) then JustifyTableLine
      else
      begin
        TrimSt(S);
        case AKey of
          'B': S := LeftPad(S, Pos + Length(S) - 1);
          'C': S := LeftPad(S, Pos + Length(S) div 2);
          else S := LeftPad(S, Pos);
        end;
      end;
      ReplaceLine(I, S);
      if PSwapLinesCollection(FileLines)^.Status = coOverflow then
      begin
        PSwapLinesCollection(FileLines)^.Status := 0;
        Break;
      end;
      if (KbdStatus = 1) and AbortAction then Break;
    end;
    AddUndoChain;
    if IsSelected and not MarkColumns then
      if Area^.PK > 1 then SetArea(Area, Area^.KB, 1,
        Area^.KK, Length(S) + 1)
      else Area^.PB := 1;
    IsModified := True;
    DebugModified := True;
  end;
end;

procedure DeleteEmptyLinesPrim(Editor: PFileEditor);
var
  Del: Boolean;
  I, ILo, IHi: Integer;
  S: String[33];
begin
  with Editor^ do
  begin
    SaveLastLine;
    if IsSelected then
    begin
      ILo := Area^.KB;
      IHi := Area^.KK;
      S := 'the selected block';
    end
    else
    begin
      ILo := 0;
      IHi := FileLines^.Count - 1;
      S := '|' + FileName^ + '|';
    end;
    if (GetShiftState and kbCtrlShift = 0) and
       (MessageBox(^C'Delete all empty lines in'#13^C +
         S + ' ?', nil, mfConfirmation + mfOkCancel) <> cmOk) then Exit;
    Del := False;
    NewUndoChain(IHi - ILo + 1);
    DrawStatusLine('Removing empty lines from ' + S + '.');
    for I := IHi downto ILo do
    begin
      if PSwapLinesCollection(FileLines)^.ExtraAt(I) = nil then
      begin
        ClearLine(I);
        if IsSelected and (I <= Area^.KK) then Dec(Area^.KK);
        Del := True;
      end;
      if (KbdStatus = 1) and AbortAction then Break;
    end;
    AddUndoChain;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    if IsSelected then GoToPos(0, Area^.KB)
    else GoCtrlPgUp;
    DrawFlag := False;
    if Del then
    begin
      IsModified := True;
      DebugModified := True;
    end;
  end;
end;

end.