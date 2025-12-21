{$I-,F+,O+,X+}
unit EditFind;

interface

uses FEDitor;

procedure ReplaceWithPrim(Editor: PFileEditor;
  const AString: String; ALength: Byte);
procedure FindPrim(Editor: PFileEditor; All: Boolean);
procedure ReplacePrim(Editor: PFileEditor; Prompt: Boolean);
procedure FindAllDlgPrim(Editor: PFileEditor);
procedure GoToLineNumberPrim(Editor: PFileEditor);
function SearchPrim(Editor: PFileEditor; const Match: String;
  AOptions: Word): Boolean;
procedure FindMatchingCharPrim(Editor: PFileEditor);

procedure InitIncSearchPrim(Editor: PFileEditor);
procedure DoneIncSearchPrim(Editor: PFileEditor);
procedure IncSearchPrim(Editor: PFileEditor; C: Char);

implementation

uses Objects, Drivers, Views, Dialogs, MsgBox, App, Swaps, HistList,
  History, CNInputs, Keyboard, EditMsg, FindDlg, RevPos, RegExp,
  Strings, TPString, Consts, Defaults;

procedure ReplaceWithPrim(Editor: PFileEditor;
  const AString: String; ALength: Byte);
var
  GroupUndo, SaveSelect, Back, OverNone, OverLess: Boolean;
  Pos, SavePos, SaveLen: Byte;
  Index, Len, D: Integer;
  SaveArea: TArea;
  RP: Array[0..255] of Char;
  S, RS: String;
begin
  with Editor^ do
  begin
    Index := Delta.Y + Cursor.Y;
    Pos := GetLinePos + 1;
    SavePos := Pos;
    SaveLen := ALength;
    GetValidLine(Index, S);
    if Pos + ALength - 1 > Length(S) then
      PadSt(S, Pos + ALength - 1);
    if RegExpr <> nil then
    begin
      Move(S[Pos], RP[0], ALength);
      RP[ALength] := #0;
      if ReplaceData.Options and frCaseSensitive = 0 then
        StrUpper(RP);
      if RegExec(RegExpr, RP) <> 0 then
      begin
        Move(S[Pos], RP[0], ALength);
        regsub(RegExpr, AString, RS);
      end
      else RS := '';
    end
    else RS := AString;
    Len := Length(RS);
    if not IsInsert then ALength := Len;
    Delete(S, Pos, ALength);
    Insert(RS, S, Pos);
    GroupUndo := ReplaceData.Options and frGroupUndo <> 0;
    if not GroupUndo then NewUndoChain(1);
    ReplaceLine(Index, S);
    if not GroupUndo then AddUndoChain;
    IsModified := True;
    DebugModified := True;
    Back := ReplaceData.Options and frBackward <> 0;
    OverNone := not IsInsert and (Len = 0);
    OverLess := not IsInsert and (Len < SaveLen);
    if Back then Dec(Pos)
    else if OverLess then Inc(Pos, SaveLen - 1)
    else if Pos + Len > 256 then Pos := 255
    else Inc(Pos, Len - 1);
    DrawFlag := True;
    GoToPos(Pos, Index);
    DrawFlag := False;
    SaveArea := Area^;
    SaveSelect := IsSelected;
    IsSelected := True;
    if Back then
      if OverNone then Pos := SavePos + SaveLen - 1
      else if OverLess then Pos := SavePos + Len - 1;
    SetArea(Area, Index, SavePos, Index, Pos + 1);
    DrawView;
    Area^ := SaveArea;
    IsSelected := SaveSelect;
    D := Len - ALength;
    if not MarkColumns and (D <> 0) then
    begin
      if Index = Area^.KB then
        if SavePos < Area^.PB then
          SetArea(Area, Area^.KB, Area^.PB + D, Area^.KK, Area^.PK);
      if Index = Area^.KK then
        if SavePos < Area^.PK then
          SetArea(Area, Area^.KB, Area^.PB, Area^.KK, Area^.PK + D);
    end;
  end;
end;

procedure FindPrim(Editor: PFileEditor; All: Boolean);
var
  DoShow: Boolean;
  B, E: Byte;
  C: Word;
  D: PDialog;
begin
  with Editor^ do
  begin
    if LocalEditOptions and eoFindTextAtCursor <> 0 then
      SearchData.MatchStr := GetWord(B, E)
    else SearchData.MatchStr := HistoryStr(FindHistoryID, 0);
    C := Application^.ExecuteDialog(
      LoadFindDialog(All, False, frSelectedText * Byte(not IsSelected) +
        (frWholeWordsOnly + frRegExp + frBackward) *
         Byte(Options and ofHex <> 0)), @SearchData, False);
    if C = cmOk then Search(SearchData.MatchStr, SearchData.Options)
    else if C = cmYes then
    begin
      FindAllList^.FreeAll;
      FindAllIndex := 0;
      FindAllData := SearchData;
      FindAllData.Options := FindAllData.Options and not frSelectedText;
      IsSearchingAll := True;
      repeat until not Search(SearchData.MatchStr, SearchData.Options);
      DoShow := FindAllIndex <> -1;
      if DoShow then FindAllDlgPrim(Editor)
      else FindAllList^.FreeAll;
    end;
  end;
end;

procedure ReplacePrim(Editor: PFileEditor; Prompt: Boolean);
var
  M, B, E: Byte;
  Through, NotFound, GroupUndo, NewGroup, Hex: Boolean;
  Opt: Word;
  Spot: TPoint;
  R: TRect;
begin
  with Editor^ do
  begin
    if Byte(Prompt) = 1 then
    begin
      if LocalEditOptions and eoFindTextAtCursor <> 0 then
      begin
	ReplaceData.MatchStr := GetWord(B, E);
        ReplaceData.NewString := ReplaceData.MatchStr;
      end
      else
      begin
        ReplaceData.MatchStr := HistoryStr(FindHistoryID, 0);
        ReplaceData.NewString := HistoryStr(ReplaceHistoryID, 0);
      end;
      Through := Application^.ExecuteDialog(LoadReplaceDialog(
        frSelectedText * Byte(not IsSelected) +
        (frWholeWordsOnly + frRegExp + frBackward + frGroupUndo) *
        Byte(Options and ofHex <> 0)), @ReplaceData, False) <> cmCancel;
    end
    else Through := True;
    if Through then
    begin
      SaveLastLine;
      Opt := ReplaceData.Options;
{
      MS := ReplaceData.MatchStr;
      NS := ReplaceData.NewString;
}
      if (Options and ofHex <> 0) and
         (ReplaceData.NewString[1] = '$') then
        ReplaceData.NewString := Hex2Match(ReplaceData.NewString, Hex);
      IsReplacing := True;
      NotFound := True;
      GroupUndo := (Options and ofHex = 0) and
        (ReplaceData.Options and frGroupUndo <> 0);
      NewGroup := False;
      KeepRegExpr := True;
      repeat
        Through := not Search(ReplaceData.MatchStr, Opt);
        Opt := Opt or frFromCursor;
        IsSearchingFrom := True;
        if not Through then NotFound := False;
        if not Through then if Opt and frPromptOnReplace <> 0 then
        begin
          MakeGlobal(Cursor, Spot);
          if Spot.Y < ScreenHeight div 2 then
            R.Assign(19, Spot.Y + 1, 61, Spot.Y + 9)
          else R.Assign(19, Spot.Y - 9, 61, Spot.Y - 1);
          M := ConfirmReplaceMsgBox(R);
          if M = cmOk then Opt := Opt and not frPromptOnReplace;
        end
        else M := cmYes;
        if M = cmCancel then Through := True
        else if not Through and ((M = cmOk) or (M = cmYes)) then
        begin
          if GroupUndo and not NewGroup then
          begin
            NewUndoChain(8);
            NewGroup := True;
          end;
          ReplaceWith(ReplaceData.NewString, ReplaceLen);
          if PSwapLinesCollection(FileLines)^.Status = coOverflow then
          begin
            PSwapLinesCollection(FileLines)^.Status := 0;
            Through := True;
          end;
        end
        else IsSearchingFrom := False;
      until Through;
      KeepRegExpr := False;
      RegFree(RegExpr);
      RegExpr := nil;
      if NewGroup then AddUndoChain;
      IsSearchingFrom := False;
      IsReplacing := False;
      if NotFound and (Byte(Prompt) <= 1) then
        SearchStringNotFoundMsgBox;
      DrawView;
      Indicator^.DrawView;
    end;
  end;
end;

procedure FindAllDlgPrim(Editor: PFileEditor);
var
  P: Pointer;
begin
  with Editor^ do
  begin
    if Options and ofHex = 0 then SaveLastLine;
    P := Editor;
    if (Application^.ExecuteDialog(
      FindAllDialog(FindAllList^.Count, Options and ofHex <> 0),
        @P, False) <> cmCancel) and (FindAllList^.Count <> 0) then
      if Options and ofHex = 0 then
      begin
        GoToPos(0, Integer(P));
        if FindAllData.Options and frBackward <> 0 then
          SetCursor(255, Cursor.Y)
        else SetCursor(-1, Cursor.Y);
        Search(FindAllData.MatchStr, FindAllData.Options or frFromCursor);
        if (Cursor.X < 0) or (Cursor.X >= Size.X) then
          SetCursor(0, Cursor.Y);
      end
      else
      begin
        if Integer(P) <> 0 then GoToPos(15, Integer(P) - 1)
        else GoToPos(0, 0);
        Search(FindAllData.MatchStr,
          FindAllData.Options or (frFromCursor * Byte(Integer(P) <> 0)));
      end;
  end;
end;

procedure GoToLineNumberPrim(Editor: PFileEditor);
const
  GoToLineData: String[6] = '';
var
  Id: Word;
  D: PDialog;
  Control: PView;
  LoIndex, Index: Longint;
  R: TRect;
  S: String;
begin
  with Editor^ do
  begin
    LoIndex := 1;
    Index := Limit.Y - Size.Y + 1;
    if Index < 1 then Index := 1;
    if Options and ofHex <> 0 then
    begin
      LoIndex := 0;
      Index := LongMul(Index - Byte(Index > 1), 16) - 1;
    end;
    R.Assign(0, 0, 40, 7);
    if Options and ofHex <> 0 then S := 'Go to address'
    else S := 'Go to line number';
    D := New(PDialog, Init(R, S));
    with D^ do
    begin
      Options := Options or ofCentered;
      HelpCtx := hcSHGoToLineNumber;

      if Editor^.Options and ofHex <> 0 then
      begin
        Id := GoToHexAddrHistoryID;
        R.Assign(21, 2, 34, 3);
      end
      else
      begin
        Id := GoToLineNumHistoryID;
        R.Assign(25, 2, 34, 3);
      end;
      Control := New(PCInputLine, Init(R, 6, LoIndex, Index));
      Insert(Control);
      StandardHistory(Control, Id);
      R.Assign(2, 2, R.A.X, 3);
      S := '~E~nter new ';
      if Editor^.Options and ofHex <> 0 then S := S + 'address'
      else S := S + 'line number';
      Insert(New(PLabel, Init(R, S, Control)));

      StandardButtonRow(D, True);
    end;
    if (Application^.ExecuteDialog(D, @GoToLineData, False) <> cmCancel) and
      Str2Long(GoToLineData, Index) then GoToLineNum(Index);
  end;
end;

function SearchPrim(Editor: PFileEditor; const Match: String;
  AOptions: Word): Boolean;
var
  FoundPos, CutLen, ColWid: Byte;
  SaveSelect, Hex, Back: Boolean;
  Index, EI: Integer;
  SelPos: TPos;
  SaveArea: TArea;
  Str, SubS, RGS: String;

procedure FindPos;
begin
  if AOptions and frWholeWordsOnly <> 0 then
    FoundPos := WordPos(SubS, Str, Editor^.LocalWordDelims, Back)
  else if Back then FoundPos := RPos(SubS, Str)
  else FoundPos := Pos(SubS, Str);
  if FoundPos <> 0 then Inc(FoundPos, CutLen - 1);
end;

begin
  with Editor^ do
  begin
    SearchPrim := False;
    if Match = '' then Exit;
    if Byte(IsSearchingAll) <= 1 then DrawStatusLine(SearchMsg);
    SubS := Match;
    if AOptions and frCaseSensitive = 0 then UpcaseSt(SubS);
{    if (SubS[1] = '$') and not IncSearch then SubS := Hex2Match(SubS, Hex);}
    if (AOptions and frRegExp <> 0) and (RegExpr = nil) then
      RegExpr := RegCompile(SubS);
    Back := AOptions and frBackward <> 0;
    if not IsSelected then AOptions := AOptions and not frSelectedText;
    if Byte(IsSearchingAll) > 1 then Index := FindAllIndex
    else if AOptions and frSelectedText <> 0 then
    begin
      if Back then Index := Area^.KK
      else Index := Area^.KB;
      if AOptions and frFromCursor <> 0 then
      begin
        EI := Delta.Y + Cursor.Y;
        if (EI >= Area^.KB) and (EI <= Area^.KK) then Index := EI
        else if (Back and (EI < Area^.KB)) or
          (not Back and (EI > Area^.KK)) then Index := -1;
      end;
    end
    else if AOptions and frFromCursor <> 0 then Index := Delta.Y + Cursor.Y
    else if Back then Index := FileLines^.Count - 1
    else Index := 0;
    if AOptions and frSelectedText <> 0 then
      if Back then EI := Area^.KB
      else EI := Area^.KK
    else if Back then EI := 0
    else EI := FileLines^.Count - 1;
    if Back and IncSearch and (EI < IncSearchPos) then
      EI := IncSearchPos;
    FoundPos := 0;
    FastGetLine := not Back;
    if (Back and (Index >= EI)) or (not Back and (Index <= EI)) then
    repeat
      if (AOptions and frSelectedText <> 0) and Selected(Index) then
      begin
        GetSelectedString(Index, Str);
        if MarkColumns then
        begin
          if Area^.PK < Area^.PB then ColWid := Area^.PB - Area^.PK
          else ColWid := Area^.PK - Area^.PB;
          if Length(Str) < ColWid then PadSt(Str, ColWid);
        end;
        GetPos(Area, Index, SelPos);
        CutLen := SelPos.AStart;
        if Back and (SelPos.AnEnd <= Length(Str)) then
          Str[0] := Char(SelPos.AnEnd - 1);
      end
      else
      begin
        GetValidLine(Index, Str);
        CutLen := 1;
      end;
      if (Index = Delta.Y + Cursor.Y) and
         (AOptions and frFromCursor <> 0) then
        if Back and (Delta.X + Cursor.X + 1 < Length(Str) + CutLen) then
          if Delta.X + Cursor.X < CutLen then Str := ''
          else Str[0] := Char(Delta.X + Cursor.X + 1 - CutLen)
        else if not Back and
          (Delta.X + Cursor.X + 1 + Byte(not IsSearchingFrom) > CutLen) then
        begin
          System.Delete(Str, 1,
            Delta.X + Cursor.X + 1 + Byte(not IsSearchingFrom) - CutLen);
          CutLen := Delta.X + Cursor.X + 1 + Byte(not IsSearchingFrom);
        end;
      if Str <> '' then
      begin
        if (AOptions and frCaseSensitive = 0) {and
           ((Match[1] <> '$') or not Hex)} then UpcaseSt(Str);
        if (AOptions and frRegExp <> 0) and (RegExpr <> nil) then
        begin
          if Back then RGS := RegSearchBack(RegExpr, Str)
          else RGS := RegSearch(RegExpr, Str);
          if RGS <> '' then SubS := RGS;
        end;
        FindPos;
      end;
      if (KbdStatus = 1) and AbortAction then
      begin
        FoundPos := 0;
        FindAllIndex := -1;
        IsSearchingAll := True;
        Break;
      end;
      if FoundPos <> 0 then Break;
      if Back then
      begin
        Dec(Index);
        if Index < EI then Break;
      end
      else
      begin
        Inc(Index);
        if Index > EI then Break;
      end;
    until False;
    if not KeepRegExpr then
    begin
      RegFree(RegExpr);
      RegExpr := nil;
    end;
    if FoundPos = 0 then
      if not IsSearchingAll and not IsReplacing then
        SearchStringNotFoundMsgBox
      else IsSearchingAll := False
    else
    begin
      if IsSearchingAll then
      begin
        if Back then
          if Index = 0 then FindAllIndex := -2
          else FindAllIndex := Index - 1
        else FindAllIndex := Index + 1;
        FindAllList^.Insert(Pointer(Index));
        Byte(IsSearchingAll) := 2;
      end
      else
      begin
        ReplaceLen := Length(SubS);
        DrawFlag := True;
        GoToPos(FoundPos - 1, Index);
{ Fixed 04.17.03 to scroll found substring into view }
        if Cursor.X + ReplaceLen > Size.X - 1 then
          ScrollTo(Delta.X + Cursor.X + ReplaceLen - (Size.X - 1), Delta.Y);
        DrawFlag := False;
        SaveArea := Area^;
        SaveSelect := IsSelected;
        IsSelected := True;
        SetArea(Area, Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1,
          Delta.Y + Cursor.Y, Delta.X + Cursor.X + Length(SubS) + 1);
        DrawView;
        Area^ := SaveArea;
        IsSelected := SaveSelect;
        DoRedraw := True;
      end;
      SearchPrim := True;
    end;
  end;
end;

procedure FindMatchingCharPrim(Editor: PFileEditor);
const
  MatchingChars = ['(', '[', '{', '''', '"', '<'];
  PairChars     = [')', ']', '}', '>'];
var
  Back: Boolean;
  B: Byte;
  C, CC: Char;
  I: Integer;
  Count, PairCount: Longint;
  S, SS: String;
begin
  with Editor^ do
  begin
    I := Delta.Y + Cursor.Y;
    GetValidLine(I, S);
    B := GetLinePos + 1;
    if B > Length(S) then Exit;
    C := S[B];
    if not (C in (MatchingChars + PairChars)) then Exit;
    case C of
      '(': CC := ')';
      ')': CC := '(';
      '[': CC := ']';
      ']': CC := '[';
      '{': CC := '}';
      '}': CC := '{';
      '<': CC := '>';
      '>': CC := '<';
      else CC := C;
    end;
    Back := C in PairChars;
    Count := 0;
    PairCount := 0;
    KbdStatus := 0;
    if Back then SS := 'back for ' else SS := 'for next ';
    DrawStatusLine('Searching ' + SS + CC +
      ' character to match ' + C + '.');
    repeat
      if Back then Dec(B) else Inc(B);
      if (B = 0) or (B > Length(S)) then
      begin
        if Back then Dec(I) else Inc(I);
        if (I < 0) or (I >= FileLines^.Count) then Exit;
        GetValidLine(I, S);
        if Back then B := Length(S) else B := 1;
        if S = '' then Continue;
      end;
      if S[B] = C then
        if C = CC then Break else Inc(Count)
      else if S[B] = CC then
        if Count = PairCount then Break else Inc(PairCount);
      if (KbdStatus = 1) and AbortAction then Exit;
    until False;
    GoToPos(B - 1, I);
  end;
end;

procedure InitIncSearchPrim(Editor: PFileEditor);
begin
  with Editor^ do
  begin
    IncSearchStr := '';
    IncSearchPos := Delta.Y + Cursor.Y;
    IncSearchOpt := (SearchData.Options or frFromCursor) and
      not (frWholeWordsOnly + frRegExp);
    if not IsSelected then
      IncSearchOpt := IncSearchOpt and not frSelectedText;
    IncSearch := True;
  end;
end;

procedure DoneIncSearchPrim(Editor: PFileEditor);
begin
  with Editor^ do
  begin
    if IncSearchStr <> '' then
      SearchData.MatchStr := IncSearchStr;
    DrawView;
    DoRedraw := False;
    IncSearch := False;
  end;
end;

procedure IncSearchPrim(Editor: PFileEditor; C: Char);
begin
  with Editor^ do
  begin
    if C = #27 then
    begin
      DoneIncSearchPrim(Editor);
      Exit;
    end;
    if C = #9 then C := #32;
    if C = #8 then
    begin
      if IncSearchStr <> '' then Dec(IncSearchStr[0]);
      if IncSearchStr = '' then
      begin
        DoneIncSearchPrim(Editor);
        Exit;
      end;
      IncSearchOpt := IncSearchOpt or frBackward;
      IsReplacing := True;
    end
    else
    begin
      if C = ^B then IncSearchOpt := IncSearchOpt or frBackward
      else IncSearchOpt := IncSearchOpt and not frBackward;
      if not (C in [^B, ^L]) then
      begin
        if Length(IncSearchStr) = IncSearchLen then
        begin
          SearchStringTooLongMsgBox;
          Exit;
        end;
        Inc(IncSearchStr[0]);
        IncSearchStr[Length(IncSearchStr)] := C;
        IsSearchingFrom := True;
        IsReplacing := True;
      end;
    end;
    if not Search(IncSearchStr, IncSearchOpt) then
      if C = #8 then
      begin
        Inc(Cursor.X, Length(IncSearchStr));
        if not Search(IncSearchStr, IncSearchOpt) then
          Dec(Cursor.X, Length(IncSearchStr));
      end
      else if not (C in [^B, ^L]) then Dec(IncSearchStr[0]);
    IsSearchingFrom := False;
    IsReplacing := False;
  end;
end;

end.