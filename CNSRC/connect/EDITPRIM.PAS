{$I-,F+,O+,X+}
unit EditPrim;

interface

uses FEditor;

procedure CharPressedPrim(Editor: PFileEditor; AChar: Char);
procedure InsertCharPrim(Editor: PFileEditor; AChar: Char; AnIndex: Integer;
  APos: Byte);
procedure InsertTabPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte;
  NonDestructive: Boolean);
procedure ReplaceCharPrim(Editor: PFileEditor; AChar: Char; AnIndex: Integer;
  APos: Byte);
procedure PutStrPrim(Editor: PFileEditor; const S: String);
procedure DeleteCharPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte;
  Backward: Boolean);
procedure DeleteToEndOfFilePrim(Editor: PFileEditor);
procedure DeleteWordLeftPrim(Editor: PFileEditor; AnIndex: Integer;
  APos: Byte);
procedure DeleteWordRightPrim(Editor: PFileEditor; AnIndex: Integer;
  APos: Byte);
procedure DeleteLinePrim(Editor: PFileEditor; AnIndex: Integer);
procedure DeleteToEndPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
procedure EnterPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
procedure SplitEnterPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
function GetWordPrim(Editor: PFileEditor; var B, E: Byte): String;
function GetLinePrim(Editor: PFileEditor): String;
function GetPrintLinePrim(Editor: PFileEditor; AnIndex: Integer;
  Sel: Boolean; var ALine: String): Boolean;
procedure ToggleBreakPointPrim(Editor: PFileEditor);
procedure DubbLinePrim(Editor: PFileEditor; AnIndex: Integer);
procedure CharAbovePrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
procedure SwapWordsPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
procedure SwapLinesPrim(Editor: PFileEditor; AnIndex: Integer; Up: Boolean);
procedure SetNewSizePrim(EditorWindow: PEditorWindow);

implementation

uses Objects, Drivers, Memory, MsgBox, Swaps, EditFind, EditMsg, EditTabl,
  EditWrap, FindDlg, Keyboard, TPString, Defaults;

procedure CharPressedPrim(Editor: PFileEditor; AChar: Char);
begin
  with Editor^ do
  case AChar of
    ^M: EnterPrim(Editor, Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
    ^N: SplitEnterPrim(Editor, Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
    ^G: DeleteChar(Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X), False);
    ^H: DeleteChar(Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X), True);
    ^I: InsertTabPrim(Editor, Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X),
	  False);
    ^Y: DeleteLinePrim(Editor, Delta.Y + Cursor.Y);
  #127: DeleteWordLeftPrim(
          Editor, Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
    ^T: DeleteWordRightPrim(
          Editor, Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
   '': CharAbovePrim(Editor, Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
   '': DubbLinePrim(Editor, Delta.Y + Cursor.Y);
   '': SwapWordsPrim(Editor, Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
    ^K: IsCtrlKPressed := True;
    ^Q: IsCtrlQPressed := True;
    ^P: IsCtrlPPressed := True;
    ^O: IsCtrlOPressed := True;
    ^L: SearchPrim(Editor, SearchData.MatchStr,
          SearchData.Options or frFromCursor);
    ^B: SearchPrim(Editor, SearchData.MatchStr,
          SearchData.Options or (frFromCursor + frBackward));
    ^U: SearchPrim(Editor, SearchData.MatchStr,
          (SearchData.Options or frFromCursor) and not frBackward);
    ^J: GoHome;
    ^S: GoLeft;
    ^D: GoRight;
    ^A: GoCtrlLeft;
    ^F: GoCtrlRight;
    ^E: GoUp;
    ^X: GoDown;
    ^R: GoPgUp;
    ^C: GoPgDn;
    ^V: ToggleInsert;
    ^W: GoCtrlUp;
    ^Z: GoCtrlDown;
    else if IsInsert then InsertCharPrim(Editor,
      AChar, Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X))
    else ReplaceCharPrim(Editor,
      AChar, Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
  end;
end;

procedure InsertCharPrim(Editor: PFileEditor; AChar: Char; AnIndex: Integer;
  APos: Byte);
const
  MatchingChars = ['(', '[', '{', '''', '"'];
  QuoteChars = ['''', '"'];
  StopChars = [',', '.', ':', ';', '!', '?'];

function GetMatchChar: Char;
begin
  case AChar of
    '(': GetMatchChar := ')';
    '[': GetMatchChar := ']';
    '{': GetMatchChar := '}';
    else GetMatchChar := AChar;
  end;
end;

function AddMatchChar: Boolean;
var
  PC, CC: Char;
begin
  with Editor^ do
  begin
    if APos <= 2 then PC := #32
    else PC := LastLine.Line[APos - 2];
    if APos > Length(LastLine.Line) then CC := #32
    else CC := LastLine.Line[APos];
  end;
  if AChar in QuoteChars then
    AddMatchChar := (PC = #32) and (CC = #32)
  else AddMatchChar := CC = #32;
end;

function SpacesOnly: Boolean;
var
  B: Byte;
begin
  for B := APos - 1 downto 1 do
    if Editor^.LastLine.Line[B] <> #32 then
    begin
      SpacesOnly := False;
      Exit;
    end;
  SpacesOnly := True;
end;

var
  Double, SaveDrawFlag: Boolean;
  LineType: Byte;
  CurChar: Char;
label
  DoIns;
begin
  with Editor^ do
  begin
    if IsSelected and (LocalEditOptions and eoOverwriteBlocks <> 0) then
    begin
      Clear(True, False);
      AnIndex := Delta.Y + Cursor.Y;
      APos := Delta.X + Cursor.X + 1;
    end;
    UpdateLastLine(AnIndex);
    Double := False;
DoIns:
    with LastLine do
    begin
      if Length(Line) = 255 then
      begin
        if not DisableSounds then Write(^G);
        Exit;
      end;
      if APos > Length(Line) then
	if (AChar <> #32) or
	   (NewLocalOptions and neoTrailingBlanks <> 0) then
        begin
          PadSt(Line, APos);
          Line[Length(Line)] := AChar;
        end
        else CurChar := #32
      else
      begin
        if AChar = #32 then
          if SpacesOnly then CurChar := #$FF
          else if Line[APos - 1] = #32 then CurChar := #32
          else CurChar := Line[APos];
        System.Insert(AChar, Line, APos);
      end;
    end;
    if IsSelected and not MarkColumns then if Selected(AnIndex) then
    begin
      if AnIndex = Area^.KB then
        if APos < Area^.PB then
          SetArea(Area, Area^.KB, Area^.PB + 1, Area^.KK, Area^.PK);
      if AnIndex = Area^.KK then
        if APos < Area^.PK then
          SetArea(Area, Area^.KB, Area^.PB, Area^.KK, Area^.PK + 1);
    end;
    IsModified := True;
    DebugModified := True;

    if State and sfDrawing <> 0 then
    begin
      LineType := TableLine(LastLine.Line);
      if LineType <> tlNo then
      begin
        ExpandTableColumnPrim(Editor, AnIndex, APos, LineType);
        AChar := #32;
        CurChar := #32;
      end;
      DrawFlag := False;
    end;

    if not Drawing then
    begin
      if Cursor.X = Size.X - 1 then
        ScrollTo(Delta.X + Size.X div 4, Delta.Y);
      if not Double then
        if (AChar in MatchingChars) and
           (LocalEditOptions and eoInsertPairs <> 0) then
        begin
          Double := True;
          AChar := GetMatchChar;
          Inc(APos);
          if (APos > 0) and AddMatchChar then Goto DoIns;
        end
        else if (AChar in StopChars) and
          (LocalEditOptions and eoAutoSpaces <> 0) then
        begin
          if (Length(LastLine.Line) >= 3) and
             (LastLine.Line[APos - 1] = #32) and
             (LastLine.Line[APos - 2] in StopChars) then
          begin
            Dec(APos);
            System.Delete(LastLine.Line, APos, 1);
            Dec(Cursor.X);
          end;
          Double := True;
          AChar := #32;
          Inc(APos);
          GoRight;
          if (APos > 0) and (APos <= Length(LastLine.Line)) and
             (LastLine.Line[APos] <> #32) then Goto DoIns;
        end;
      SaveDrawFlag := DrawFlag;
      DrawFlag := True;
      GoRight;
      if (LocalEditOptions and eoEnableWrap <> 0) and
         (Length(LastLine.Line) > LocalMaxLineWidth) and
         ((AChar <> #32) or (CurChar <> #32)) then
        WrapLinePrim(Editor, AnIndex);
      DrawFlag := SaveDrawFlag;
    end;
    DrawView;
  end;
end;

procedure FindTabPosPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte;
  var I: Integer);
var
  B: Integer;
  S: String;
begin
  while AnIndex > 0 do
  begin
    Dec(AnIndex);
    Editor^.GetValidLine(AnIndex, S);
    if S <> '' then
    begin
      if APos <= Length(S) then
      begin
        B := APos;
        while (B <= Length(S)) and (S[B] <> ' ') do Inc(B);
	while (B <= Length(S)) and (S[B] = ' ') do Inc(B);
	I := B - APos;
      end;
      Exit;
    end;
  end;
end;

procedure InsertTabPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte;
  NonDestructive: Boolean);
var
  MayBeATable: Boolean;
  I, Count: Integer;
begin
  with Editor^ do
  begin
    if IsSelected and (LocalEditOptions and eoOverwriteBlocks <> 0) then
    begin
      Clear(True, False);
      AnIndex := Delta.Y + Cursor.Y;
      APos := Delta.X + Cursor.X + 1;
    end;
    UpdateLastLine(AnIndex);
    I := LocalTabSize + 1 - APos mod LocalTabSize;
    if I > LocalTabSize then I := I - LocalTabSize;
    MayBeATable := (State and sfDrawing <> 0) and
      (TableLine(LastLine.Line) <> tlNo);
    if MayBeATable then
    begin
      NewUndoChain(16);
      SaveLastLine;
    end
    else
    begin
      if NewLocalOptions and neoSmartTabs <> 0 then
	FindTabPosPrim(Editor, AnIndex, APos, I);
      DrawFlag := True;
    end;
    EditorAborted := False;
    for Count := 1 to I do
    begin
      if NonDestructive then GoRight
      else CharPressedPrim(Editor, ' ');
      if EditorAborted then Break;
    end;
    if MayBeATable then AddUndoChain;
    DrawFlag := False;
    DrawView;
  end;
end;

procedure ReplaceCharPrim(Editor: PFileEditor; AChar: Char; AnIndex: Integer;
  APos: Byte);
begin
  with Editor^ do
  begin
    if IsSelected and (LocalEditOptions and eoOverwriteBlocks <> 0) then
    begin
      Clear(True, False);
      AnIndex := Delta.Y + Cursor.Y;
      APos := Delta.X + Cursor.X + 1;
    end;
    UpdateLastLine(AnIndex);
    with LastLine do
    begin
      if APos > Length(Line) then PadSt(Line, APos);
      Line[APos] := AChar;
    end;
    IsModified := True;
    DebugModified := True;
    if not Drawing then
    begin
      if Cursor.X = Size.X - 1 then
        ScrollTo(Delta.X + Size.X div 4, Delta.Y);
      GoRight;
    end;
    DrawView;
  end;
end;

procedure PutStrPrim(Editor: PFileEditor; const S: String);
var
  P: Byte;
  SaveOptions: Longint;
  Event: TEvent;
begin
  with Editor^ do
  begin
    SaveOptions := LocalEditOptions;
    LocalEditOptions := LocalEditOptions and not
      (eoInsertPairs + eoAutoSpaces);
    EditorAborted := False;
    for P := 1 to Length(S) do
    begin
      DrawFlag := True;
      Event.What := evKeyDown;
      Event.CharCode := S[P];
      HandleEvent(Event);
      if EditorAborted then Break;
    end;
    LocalEditOptions := SaveOptions;
    DrawFlag := False;
    DrawView;
  end;
end;

function GetLineIndent(const S: String): Byte;
var
  B, C: Byte;
begin
  B := 0;
  for C := 1 to Length(S) do
    if S[C] = ' ' then Inc(B) else Break;
  GetLineIndent := B;
end;

function GetIndentPrim(Editor: PFileEditor; AnIndex: Integer;
  MaxIndent: Byte): Byte;
var
  B: Byte;
  S: String;
begin
  GetIndentPrim := 0;
  while AnIndex > 0 do
  begin
    Dec(AnIndex);
    Editor^.GetValidLine(AnIndex, S);
    if S <> '' then
    begin
      B := GetLineIndent(S);
      if B < MaxIndent then
      begin
	GetIndentPrim := B;
	Exit;
      end;
    end;
  end;
end;

procedure DeleteCharPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte;
  Backward: Boolean);
var
  LineType: Byte;
  I, BackCount: Integer;
  NS: String;
begin
  with Editor^ do
  begin
    if IsSelected and (LocalEditOptions and eoOverwriteBlocks <> 0) then
    begin
      Clear(True, True);
      Exit;
    end;
    if AnIndex = FileLines^.Count then
    begin
      if Backward then
      begin
        GoUp;
        if Delta.Y + Cursor.Y = AnIndex then Exit;
        GoEnd;
        DeleteChar(Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1, False);
      end;
      Exit;
    end;
    UpdateLastLine(AnIndex);
    with LastLine do
    begin
      if Backward then
      begin
        if APos < 2 then
        begin
          GoUp;
          if Delta.Y + Cursor.Y = AnIndex then Exit;
          GoEnd;
          DeleteChar(Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1, False);
          Exit;
        end;
        if (Line = '') and (LocalEditOptions and eoAutoIndentMode <> 0) then
        begin
	  GoToPos(GetIndentPrim(Editor, AnIndex, APos - 1),
	    Delta.Y + Cursor.Y);
          Exit;
        end;
        if APos > Length(Line) + 1 then
        begin
          GoLeft;
          Exit;
        end;
        BackCount := 1;
	if (LocalEditOptions and eoAutoIndentMode <> 0) and
	   (State and sfDrawing = 0) and (APos <= Length(Line)) and
           (Line[APos] <> ' ') and (Line[APos - 1] = ' ') then
        begin
          I := GetLineIndent(Line);
          if APos = I + 1 then
	    BackCount := I - GetIndentPrim(Editor, AnIndex, I);
        end;

	if not IsInsert then
	begin
	  for I := APos - BackCount to APos - 1 do
	    if (I > 0) and (I <= Length(Line)) then
	      Line[I] := ' ';
	end
	else Delete(Line, APos - BackCount, BackCount);
        if IsSelected and not MarkColumns then if Selected(AnIndex) then
        begin
          if AnIndex = Area^.KB then
            if Pred(APos) < Area^.PB then Dec(Area^.PB, BackCount);
          if AnIndex = Area^.KK then
            if Pred(APos) < Area^.PK then Dec(Area^.PK, BackCount);
        end;

        if State and sfDrawing <> 0 then
        begin
          LineType := TableLine(Line);
          if LineType <> tlNo then
            ShrinkTableColumnPrim(Editor, AnIndex, APos - 1, LineType);
        end;

	GoToPos(Delta.X + Cursor.X - BackCount, Delta.Y + Cursor.Y);
        DrawView;
      end
      else
      begin
        if APos > Length(Line) then
        begin
          GetValidLine(Succ(AnIndex), NS);
          if APos + Length(NS) <= 256 then
          begin
            if AnIndex = FileLines^.Count - 1 then
            begin
              if Line <> '' then Exit;
              NewUndoChain(1);
              ClearLine(AnIndex);
            end
            else
            begin
              PadSt(Line, APos - 1);
              Line := Line + NS;
              NewUndoChain(2);
              ClearLine(Succ(AnIndex));
              ReplaceLine(AnIndex, Line);
            end;
            AddUndoChain;
            if IsSelected then
            begin
              if Succ(AnIndex) < Area^.KB then
              begin
                Dec(Area^.KB);
                Dec(Area^.KK);
              end
              else if (Succ(AnIndex) = Area^.KB) and
                (Area^.KB = Area^.KK) then
              begin
                IsSelected := False;
                Highlight(AnIndex, APos + Area^.PB - 1,
                  AnIndex, APos + Area^.PK - 1);
              end
              else if Succ(AnIndex) = Area^.KB then
              begin
                Dec(Area^.KK);
                if not MarkColumns then
                begin
                  IsSelected := False;
                  Highlight(AnIndex, APos + Area^.PB - 1,
                    Area^.KK, Area^.PK);
                end;
              end
              else if Succ(AnIndex) < Area^.KK then Dec(Area^.KK)
              else if Succ(AnIndex) = Area^.KK then
              begin
                if MarkColumns then Dec(Area^.KK)
                else
                begin
                  IsSelected := False;
                  Highlight(Area^.KB, Area^.PB,
                    AnIndex, APos + Area^.PK - 1);
                end;
              end;
            end;
            SetLastLine('', -1);
            DrawFlag := True;
            SetLimit(Limit.X, FileLines^.Count + Size.Y);
            DrawFlag := False;
          end
          else if not DisableSounds then Write(^G);
        end
        else
        begin
          Delete(Line, APos, 1);
          if IsSelected and not MarkColumns then if Selected(AnIndex) then
          begin
            if AnIndex = Area^.KB then if APos < Area^.PB then Dec(Area^.PB);
            if AnIndex = Area^.KK then if APos < Area^.PK then Dec(Area^.PK);
          end;

          if State and sfDrawing <> 0 then
          begin
            LineType := TableLine(Line);
            if LineType <> tlNo then
              ShrinkTableColumnPrim(Editor, AnIndex, APos, LineType);
          end;
        end;
        DrawView;
      end;
    end;
    IsModified := True;
    DebugModified := True;
  end;
end;

procedure DeleteToEndOfFilePrim(Editor: PFileEditor);
var
  Pos: Byte;
  Index, I: Integer;
  S: String;
begin
  with Editor^ do
  begin
    SaveLastLine;
    Index := Delta.Y + Cursor.Y;
    Pos := Delta.X + Cursor.X + 1;
    NewUndoChain(FileLines^.Count - Index + 1);
    GetValidLine(Index, S);
    if Pos <= Length(S) then
    begin
      Delete(S, Pos, 255);
      ReplaceLine(Index, S);
    end;
    for I := Index + 1 to FileLines^.Count - 1 do
    begin
      ClearLine(Index + 1);
      if (KbdStatus = 1) and AbortAction then Break;
    end;
    AddUndoChain;
    if IsSelected and (Area^.KK >= FileLines^.Count) then
      if Area^.KB >= FileLines^.Count then Unselect
      else
      begin
	Area^.KK := FileLines^.Count;
        if not MarkColumns then Area^.PK := 1;
      end;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    DrawFlag := False;
    IsModified := True;
    DebugModified := True;
  end;
end;

procedure DeleteWordLeftPrim(Editor: PFileEditor; AnIndex: Integer;
  APos: Byte);
var
  P: Byte;
  I: Integer;
begin
  if APos <= 1 then DeleteCharPrim(Editor, AnIndex, APos, True)
  else with Editor^ do
  begin
    UpdateLastLine(AnIndex);
    with LastLine do
    begin
      if APos > Byte(Line[0]) + 1 then
      begin
	GoEnd;
	Exit;
      end;
      P := APos - 1;
      if WordChar(Line[P]) then
      begin
	while (P > 0) and WordChar(Line[P]) do Dec(P);
	if NewLocalOptions and neoTrailingBlanks = 0 then
	  while (P > 0) and (Line[P] = ' ') do Dec(P);
      end
      else while (P > 0) and not WordChar(Line[P]) do Dec(P);
      if IsInsert then System.Delete(Line, P + 1, APos - P - 1)
      else for I := P + 1 to APos - 1 do
	if (I > 0) and (I <= Length(Line)) then Line[I] := ' ';
    end;
    DrawFlag := True;
    GoToPos(P, AnIndex);
    DrawFlag := False;
    IsModified := True;
    DebugModified := True;
    DrawView;
  end;
end;

procedure DeleteWordRightPrim(Editor: PFileEditor; AnIndex: Integer;
  APos: Byte);
begin
  with Editor^ do
  begin
    UpdateLastLine(AnIndex);
    with LastLine do
    begin
      if APos > Byte(Line[0]) then
	if IsInsert then DeleteChar(AnIndex, APos, False)
	else
	begin
	  GoCtrlRight;
	  Exit;
	end
      else if WordChar(Line[APos]) then
      begin
	while (APos <> 0) and (APos <= Byte(Line[0])) and
	  WordChar(Line[APos]) do
	  if IsInsert then System.Delete(Line, APos, 1)
	  else
	  begin
	    Line[APos] := ' ';
	    Inc(APos);
	  end;
	while (APos <> 0) and (APos <= Byte(Line[0])) and
	  (Line[APos] = ' ') do
	  if IsInsert then System.Delete(Line, APos, 1)
	  else
	  begin
	    Line[APos] := ' ';
	    Inc(APos);
	  end;
      end
      else while (APos <> 0) and (APos <= Byte(Line[0])) and
	not WordChar(Line[APos]) do
	if IsInsert then System.Delete(Line, APos, 1)
	else
	begin
	  Line[APos] := ' ';
	  Inc(APos);
	end;
    end;
    DrawFlag := True;
    GoToPos(APos - 1, AnIndex);
    DrawFlag := False;
    IsModified := True;
    DebugModified := True;
    DrawView;
  end;
end;

procedure DeleteLinePrim(Editor: PFileEditor; AnIndex: Integer);
var
  I: Integer;
begin
  with Editor^ do
  begin
    if AnIndex = FileLines^.Count then Exit;
    SaveLastLine;
    NewUndoChain(1);
    ClearLine(AnIndex);
    AddUndoChain;
    if IsSelected then
    begin
      if AnIndex < Area^.KB then
      begin
        Dec(Area^.KB);
        Dec(Area^.KK);
      end
      else if AnIndex < Area^.KK then
      begin
        Dec(Area^.KK);
        if not MarkColumns and (AnIndex = Area^.KB) then Area^.PB := 1;
      end
      else if AnIndex = Area^.KK then
        if MarkColumns then Dec(Area^.KK)
        else Area^.PK := 1;
    end;
    IsModified := True;
    DebugModified := True;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    DrawFlag := False;
    GoHome;
    DrawView;
  end;
end;

procedure DeleteToEndPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
begin
  with Editor^ do
  begin
    UpdateLastLine(AnIndex);
    with LastLine do
    begin
      if APos > Length(Line) then Exit;
      Line := System.Copy(Line, 1, Pred(APos));
    end;
    IsModified := True;
    DebugModified := True;
  end;
end;

procedure EnterPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
var
  X, NX, LineType: Byte;
  S, NS: String;

function NewCursorX(Index: Integer): Byte;
var
  PrevPos: Byte;
  PrevS: String;
begin
  with Editor^ do
  begin
    GetValidLine(Index, PrevS);
    while (Index > 0) and (PrevS = '') do
    begin
      Dec(Index);
      GetValidLine(Index, PrevS);
    end;
    PrevPos := 0;
    if PrevS <> '' then while (PrevS[PrevPos + 1] = #32) and
      (PrevPos < LocalMaxLineWidth) do Inc(PrevPos);
    if (Index = AnIndex) and (PrevPos >= APos) then PrevPos := APos - 1;
    NewCursorX := PrevPos;
  end;
end;

begin
  with Editor^ do
  begin
    X := (LocalEditOptions and not EditOptMask) shr 26;
    if LocalEditOptions and eoAutoIndentMode <> 0 then
      NX := NewCursorX(AnIndex) else NX := 0;
    if NX < X then NX := X;
    if IsInsert then
    begin
      GetValidLine(AnIndex, S);
      SaveLastLine;
      NewUndoChain(2);
      if State and sfDrawing <> 0 then LineType := TableLine(S)
      else LineType := tlNo;
      if LineType <> tlNo then
      begin
        ExpandTableRowPrim(Editor,
	  AnIndex + Byte(LineType <> tlBottom), APos, LineType,
	  GetShiftState and (kbLeftShift + kbRightShift) <> 0, S, NX);
        if LineType = tlBottom then Dec(Cursor.Y);
      end
      else if APos > Length(S) then
      begin
        if AnIndex = FileLines^.Count then NewLine(AnIndex, '')
        else if AnIndex < FileLines^.Count - 1 then NewLine(AnIndex + 1, '')
      end
      else
      begin
        ReplaceLine(AnIndex, System.Copy(S, 1, APos - 1));
        NS := System.Copy(S, APos, Length(S) - APos + 1);
        NewLine(AnIndex + 1, LeftPad(NS, Length(NS) + NX));
      end;
      AddUndoChain;
      if IsSelected then
      begin
        if AnIndex < Area^.KB then
        begin
          Inc(Area^.KB);
          Inc(Area^.KK);
        end
        else if not MarkColumns and
          (AnIndex = Area^.KB) and (APos < Area^.PB) then
        begin
          IsSelected := False;
          if Area^.KB = Area^.KK then
            Highlight(AnIndex + 1, Area^.PB - APos + NX + 1,
              AnIndex + 1, Area^.PK - APos + NX + 1)
          else Highlight(AnIndex + 1, Area^.PB - APos + NX + 1,
            Area^.KK + 1, Area^.PK);
        end
        else if AnIndex < Area^.KK then Inc(Area^.KK)
        else if not MarkColumns and
          (AnIndex = Area^.KK) and (APos < Area^.PK) then
        begin
          IsSelected := False;
          Highlight(Area^.KB, Area^.PB, AnIndex + 1,
            Area^.PK - APos + NX + 1);
        end;
      end;
      IsModified := True;
      DebugModified := True;
      DrawFlag := True;
      SetLimit(Limit.X, FileLines^.Count + Size.Y);
    end;
    DrawFlag := True;
    GoDown;
    GoToPos(NX, Delta.Y + Cursor.Y);
    DrawFlag := False;
    DrawView;
  end;
end;

procedure SplitEnterPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
var
  SaveOptions: Longint;
begin
  with Editor^ do
  begin
    SaveOptions := LocalEditOptions;
    LocalEditOptions := LocalEditOptions and not eoAutoIndentMode;
    EnterPrim(Editor, AnIndex, APos);
    LocalEditOptions := SaveOptions;
    GoToPos(APos - 1, AnIndex);
  end;
end;

function GetWordPrim(Editor: PFileEditor; var B, E: Byte): String;
var
  APos, BPos, EPos: Byte;
  AnIndex: Integer;
  S: String;
begin
  with Editor^ do
  begin
    APos := Succ(Delta.X + Cursor.X);
    AnIndex := Delta.Y + Cursor.Y;
    GetWordPrim := '';
    B := 0; E := 0;
    GetValidLine(AnIndex, S);
    if APos > Length(S) then Exit;
    EPos := APos;
    while (EPos > 1) and not WordChar(S[EPos]) do Dec(EPos);
    if not WordChar(S[EPos]) then Exit;
    BPos := EPos;
    while (BPos > 0) and WordChar(S[BPos]) do Dec(BPos);
    while (EPos < 255) and (EPos <= Length(S)) and
      WordChar(S[EPos]) do Inc(EPos);
    B := BPos + 1; E := EPos;
    GetWordPrim := System.Copy(S, B, EPos - BPos - 1);
  end;
end;

function GetLinePrim(Editor: PFileEditor) : String;
var
  APos: Byte;
  AnIndex: Integer;
  S: String;
begin
  with Editor^ do
  begin
    APos := Succ(Delta.X + Cursor.X);
    AnIndex := Delta.Y + Cursor.Y;
    GetValidLine(AnIndex, S);
    if APos > Length(S) then APos := 1;
    while (APos > 0) and not WordChar(S[APos]) do Dec(APos);
    while (APos > 0) and WordChar(S[APos]) do Dec(APos);
    GetLinePrim := System.Copy(S, APos + 1, 255);
  end;
end;

function GetPrintLinePrim(Editor: PFileEditor; AnIndex: Integer;
  Sel: Boolean; var ALine: String): Boolean;
begin
  with Editor^ do
    if (AnIndex >= 0) and (AnIndex < FileLines^.Count) then
    begin
      if Sel and IsSelected then GetSelectedString(AnIndex, ALine)
      else GetValidLine(AnIndex, ALine);
      GetPrintLinePrim := True;
    end
    else GetPrintLinePrim := False;
end;

procedure ToggleBreakPointPrim(Editor: PFileEditor);
var
  I, Index: Integer;
begin
  with Editor^ do
  begin
    Index := Delta.Y + Cursor.Y;
    I := IsBreakPoint(Index);
    if (I >= 0) and (I < MaxBreakPoints) then
    begin
      Move(BreakPoints[I + 1], BreakPoints[I],
        (MaxBreakPoints - I - 1) * SizeOf(Integer));
      BreakPoints[MaxBreakPoints - 1] := -1;
    end
    else
    begin
      I := 0;
      while (I < MaxBreakPoints) and (BreakPoints[I] <> -1) do Inc(I);
      if I < MaxBreakPoints then BreakPoints[I] := Index
      else MessageBox(^C'Too many breakpoints.', nil, mfError + mfOkButton);
    end;
    DrawView;
  end;
end;

procedure DubbLinePrim(Editor: PFileEditor; AnIndex: Integer);
var
  S: String;
begin
  with Editor^ do
  begin
    GetValidLine(AnIndex, S);
    SaveLastLine;
    NewUndoChain(1);
    NewLine(AnIndex, S);
    AddUndoChain;
    if IsSelected then
    begin
      if AnIndex < Area^.KB then Inc(Area^.KB);
      if AnIndex < Area^.KK then Inc(Area^.KK);
    end;
    IsModified := True;
    DebugModified := True;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    GoDown;
    DrawFlag := False;
    DrawView;
  end;
end;

procedure CharAbovePrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
var
  C: Char;
  I: Integer;
  SaveOptions: Longint;
  S: String;
begin
  if AnIndex <= 0 then Exit;
  I := AnIndex - 1;
  repeat
    Editor^.GetValidLine(I, S);
    Dec(I);
  until (I < 0) or (Length(S) >= APos);
  if APos <= Length(S) then C := S[APos]
  else C := ' ';
  with Editor^ do
  begin
    SaveOptions := LocalEditOptions;
    LocalEditOptions := LocalEditOptions and not
      (eoInsertPairs + eoAutoSpaces);
    if IsInsert then InsertCharPrim(Editor, C, AnIndex, APos)
    else ReplaceCharPrim(Editor, C, AnIndex, APos);
    LocalEditOptions := SaveOptions;
  end;
end;

procedure SwapWordsPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
var
  BL, BR, E: Byte;
  S, SL, SR: String;
begin
  with Editor^ do
  begin
    GetValidLine(AnIndex, S);
    if (APos <= 1) or (APos >= Length(S)) then Exit;
    BL := APos;
    while (BL > 0) and WordChar(S[BL]) do Dec(BL);
    if BL = 0 then Exit;
    while (BL > 0) and not WordChar(S[BL]) do Dec(BL);
    if BL = 0 then Exit;
    E := BL + 1;
    while (BL > 0) and WordChar(S[BL]) do Dec(BL);
    Inc(BL);
    SL := System.Copy(S, BL, E - BL);
    BR := APos;
    while (BR > 0) and (BR <= Length(S)) and WordChar(S[BR]) do Inc(BR);
    if (BR = 0) or (BR > Length(S)) then Exit;
    while (BR > 0) and (BR <= Length(S)) and not WordChar(S[BR]) do Inc(BR);
    if (BR = 0) or (BR > Length(S)) then Exit;
    E := BR;
    while (E > 0) and (E <= Length(S)) and WordChar(S[E]) do Inc(E);
    SR := System.Copy(S, BR, E - BR);
    System.Delete(S, BR, Length(SR));
    System.Insert(SL, S, BR);
    System.Delete(S, BL, Length(SL));
    System.Insert(SR, S, BL);
    Inc(Cursor.X, Length(SR) - Length(SL));
    SaveLastLine;
    NewUndoChain(1);
    ReplaceLine(AnIndex, S);
    AddUndoChain;
    IsModified := True;
    DebugModified := True;
    DrawView;
  end;
end;

procedure SwapLinesPrim(Editor: PFileEditor; AnIndex: Integer; Up: Boolean);
var
  UndoErrorFlag: Boolean;
  I, SaveCount: Integer;
  L: Longint;
  R: PUndoRec;
begin
  with Editor^ do
  begin
    if Up then I := AnIndex - 1
    else I := AnIndex + 1;
    if (I < 0) or (I >= FileLines^.Count) then Exit;
    SaveLastLine;
    L := Longint(PSwapLinesCollection(FileLines)^.ExtraAt(AnIndex));
    UndoErrorFlag := True;
    NewUndoChain(2);
    if UndoChain <> nil then
    begin
      R := MemAlloc(SizeOf(TUndoRec));
      if R <> nil then
      begin
        R^.Address := L;
        R^.Index := AnIndex;
        R^.Action := unIns;
        SaveCount := UndoChain^.Count;
        UndoChain^.Insert(R);
        if SaveCount = UndoChain^.Count then
          FreeMem(R, SizeOf(TUndoRec))
        else
        begin
          R := MemAlloc(SizeOf(TUndoRec));
          if R <> nil then
          begin
            R^.Address := L;
            R^.Index := I;
            R^.Action := unDel;
            SaveCount := UndoChain^.Count;
            UndoChain^.Insert(R);
            if SaveCount = UndoChain^.Count then
              FreeMem(R, SizeOf(TUndoRec))
            else UndoErrorFlag := False;
          end;
        end
      end;
    end;
    PSwapLinesCollection(FileLines)^.ExtraAtFree(AnIndex);
    PSwapLinesCollection(FileLines)^.ExtraAtInsert(I, Pointer(L));
    if UndoErrorFlag then UndoError
    else AddUndoChain;
    TopLine := MaxInt;
    IsModified := True;
    DebugModified := True;
    DrawFlag := True;
    GoToPos(Delta.X + Cursor.X, I);
    DrawFlag := False;
    DrawView;
  end;
end;

procedure SetNewSizePrim(EditorWindow: PEditorWindow);
var
  R: TRect;
begin
  with EditorWindow^ do
  begin
    Options := Options or ofNewSize;
    if Size.X < 35 then
    begin
      GetBounds(R);
      R.B.X := R.A.X + 35;
      Locate(R);
    end;
    GetExtent(R);
    Inc(R.A.X, 30); Dec(R.B.X, 2); R.A.Y := Pred(R.B.Y);
    Editor^.HScrollBar^.Locate(R);
    GetExtent(R);
    Inc(R.A.X, 2); R.A.Y := Pred(R.B.Y); R.B.X := R.A.X + 27;
    PFileEditor(Editor)^.Indicator^.Locate(R);
  end;
end;

end.