{$I-,F+,O+,X+}
unit EditMisc;

interface

uses FEditor;

type
  TTimeStamp = (tsDate, tsTime, tsBoth);

procedure SortBlockPrim(Editor: PFileEditor);
procedure MathOperationPrim(Editor: PFileEditor);
procedure CalcWordsAndCharsPrim(Editor: PFileEditor);
procedure TimeStampPrim(Editor: PFileEditor; What: TTimeStamp);
procedure DrawLinePrim(Editor: PFileEditor; Key: Word);
procedure OpenFileAtCursorPrim(Editor: PFileEditor);
procedure MkDirAtCursorPrim(Editor: PFileEditor);

implementation

uses Dos, Objects, Drivers, Views, Memory, Dialogs, MsgBox, App,
  StdDlg, Gauges, Swaps, HistList, History, EditMsg, EditPrim,
  DirPrim, DiskPrim, Keyboard, RevPos, StrCalc, LFN, TPString,
  Consts, Commands, Defaults;

type
  PSortList = ^TSortList;
  TSortList = object(TSortedCollection)
    Editor: PFileEditor;
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    procedure FreeItem(Item: Pointer); virtual;
  end;

const
  smAscend = 0;
  smDescend = 1;
  SortMode: Word = smAscend;
  SortCase: Word = 0;
  SortPos: String[3] = '';
  SortPosVal: Byte = 0;

function TSortList.Compare(Key1, Key2: Pointer): Integer;
var
  S1, S2: String;

procedure GetSortLine(Pos: Longint; var Line: String);
begin
  if Pos = 0 then Line := ''
  else with Editor^.SwapStream^ do
  begin
    Seek(Pos);
    Read(Line[0], 1);
    Read(Line[1], Byte(Line[0]));
    if SortPosVal > 1 then Line := System.Copy(Line, SortPosVal, 255)
    else TrimSt(Line);
    if SortCase = 0 then UpcaseSt(Line);
  end;
end;

begin
  GetSortLine(Longint(Key1), S1);
  GetSortLine(Longint(Key2), S2);
  if S1 = S2 then Compare := 0
  else if S1 > S2 then
    if SortMode = smAscend then Compare := 1 else Compare := -1
  else if SortMode = smAscend then Compare := -1 else Compare := 1;
end;

procedure TSortList.FreeItem(Item: Pointer);
begin
end;

procedure SortBlockPrim(Editor: PFileEditor);
var
  LoI, HiI, I, N, SaveCount: Integer;
  Percent, OldPercent: Longint;
  List: PSortList;
  R: PUndoRec;
  S: String;

function SetupOk: Boolean;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 27, 13);
  D := New(PDialog, Init(R, 'Sort lines'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcCtrlQX;

    R.Assign(3, 3, Size.X - 3, 5);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~A~scending',
      NewSItem('~D~escending', nil))));
    Insert(Control);
    R.Assign(2, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(R, 'Sort direction', Control)));

    R.Assign(3, 6, Size.X - 3, 7);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~C~ase sensitive', nil)));
    Insert(Control);

    R.Assign(17, 8, Size.X - 3, 9);
    Control := New(PInputLine, Init(R, 3));
    Insert(Control);
    R.Assign(2, 8, 17, 9);
    Insert(New(PLabel, Init(R, '~L~ine position', Control)));

    R.Assign(2, Size.Y - 3, 12, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(15, Size.Y - 3, 25, Size.Y - 1);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  SetupOk := Application^.ExecuteDialog(D, @SortMode, False) <> cmCancel;
end;

label
  Quit;
begin
  with Editor^ do
  begin
    if not IsSelected or not SetupOk then Exit;
    SaveLastLine;
    Val(SortPos, SortPosVal, I);
    LoI := Area^.KB;
    if (Area^.PK = 1) or (Area^.KK = FileLines^.Count) then
      HiI := Area^.KK - 1
    else HiI := Area^.KK;
    N := HiI - LoI + 1;
    if N <= 1 then Exit;
    if (N >= MaxCollectionSize) or (MaxAvail < 10000) or
       (MaxAvail - 10000 < N * SizeOf(Pointer)) then
    begin
      Application^.OutOfMemory;
      Exit;
    end;
    List := New(PSortList, Init(N, 1));
    List^.Duplicates := True;
    List^.Editor := Editor;
    OldPercent := -1;
    for I := LoI to HiI do
    begin
      if (KbdStatus = 1) and AbortAction then Goto Quit;
      Percent := Trunc(((I - LoI + 1) / N) * 100);
      if Percent <> OldPercent then
      begin
        OldPercent := Percent;
        FormatStr(S, ' %d  done', Percent);
        S[Length(S) - 5] := '%';
        LogEvent := 0;
        DrawStatusLine('Sorting lines in the selected block:' + S);
      end;
      List^.Insert(PSwapLinesCollection(FileLines)^.ExtraAt(I));
    end;
    NewUndoChain(N);
    OldPercent := -1;
    for I := LoI to HiI do
    begin
      if (KbdStatus = 1) and AbortAction then Goto Quit;
      Percent := Trunc(((I - LoI + 1) / N) * 100);
      if Percent <> OldPercent then
      begin
        OldPercent := Percent;
        FormatStr(S, ' %d  done', Percent);
        S[Length(S) - 5] := '%';
        LogEvent := 0;
        DrawStatusLine('Rearranging sorted lines:' + S);
      end;
      if UndoChain <> nil then
      begin
        R := MemAlloc(SizeOf(TUndoRec));
        if R <> nil then
        begin
          R^.Address := Longint(PSwapLinesCollection(FileLines)^.ExtraAt(I));
          R^.Index := I;
          R^.Action := unRep;
          SaveCount := UndoChain^.Count;
          UndoChain^.Insert(R);
          if SaveCount = UndoChain^.Count then
          begin
            FreeMem(R, SizeOf(TUndoRec));
            UndoError;
          end
        end
        else UndoError;
      end;
      PSwapLinesCollection(FileLines)^.ExtraAtFree(I);
      PSwapLinesCollection(FileLines)^.ExtraAtInsert(I, List^.At(I - LoI));
    end;
Quit:
    AddUndoChain;
    if not MarkColumns then
    begin
      Area^.PB := 1;
      if Area^.PK > 1 then
      begin
        GetValidLine(Area^.KK, S);
        SetArea(Area, Area^.KB, Area^.PB, Area^.KK, Length(S) + 1);
      end;
    end;
    Dispose(List, Done);
    TopLine := MaxInt;
    IsModified := True;
    DebugModified := True;
  end;
end;

const
  moAdd = 0;
  moSub = 1;
  moMul = 2;
  moDiv = 3;
  moFormula = 4;
  moProgram = 5;
  MathOp: Word = moAdd;

procedure MathOperationPrim(Editor: PFileEditor);
var
  P: Byte;
  First: Boolean;
  I, LoI, HiI, Code: Integer;
  R: Extended;
  S, CS: String;

function SetupOk: Boolean;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 27, 13);
  D := New(PDialog, Init(R, 'Math operation'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcCtrlQM;

    R.Assign(3, 3, Size.X - 3, 9);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~+~ (Add)', NewSItem('~-~ (Subtract)',
      NewSItem('~*~ (Multiply)', NewSItem('~/~ (Divide)',
      NewSItem('~F~ormula', NewSItem('~P~rogram', nil))))))));
    Insert(Control);
    R.Assign(2, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(R, 'Operation', Control)));

    R.Assign(2, 10, 12, 12);
    StandardOkButton(R, D);
    R.Assign(15, 10, 25, 12);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  SetupOk := Application^.ExecuteDialog(D, @MathOp, False) <> cmCancel;
end;

function CalcLine: Boolean;
const
  Digits = ['0'..'9'];
  Expo = ['E', 'e'];
  Minus = ['-'];
  Point = ['.'];
  MaxReal = 1E2465;
var
  Result: Boolean;
  L: Longint;
  ValidDigits: TCharSet;
  E: Extended;
  C: String;
begin
  Result := True;
  P := 1;
  repeat
    if P > Length(S) then Break;
    ValidDigits := Digits + Minus + Point;
    while (P < Length(S)) and not (S[P] in ValidDigits) do Inc(P);
    if not (S[P] in ValidDigits) then Break;
    C := '';
    while (P <= Length(S)) and (S[P] in ValidDigits) do
    begin
      C := C + S[P];
      if C = '.' then ValidDigits := Digits + Expo
      else if C = '-' then ValidDigits := Digits + Expo + Point
      else if Length(C) = 1 then ValidDigits := Digits + Expo + Point;
      if S[P] in Expo then ValidDigits := ValidDigits - Expo + Minus - Point
      else if S[P] in Minus then ValidDigits := ValidDigits - Minus
      else if S[P] in Point then ValidDigits := ValidDigits - Point;
      Inc(P);
    end;
    while (C[0] > #0) and not (C[Length(C)] in Digits) do Dec(C[0]);
    if C = '' then Continue;
    Val(C, E, Code);
    if (not First and (Abs(R) > MaxReal)) or (Abs(E) > MaxReal) then
    begin
      E := 0;
      Code := 1;
    end;
    if E <> 0 then
    begin
      if First then R := E
      else case MathOp of
        moAdd: R := R + E;
        moSub: R := R - E;
        moMul: R := R * E;
        moDiv: R := R / E;
      end;
      First := False;
    end
    else if (Code = 0) and (MathOp = moDiv) then
    begin
      L := I + 1;
      if MessageBox(^C'Division by zero at line %d. Continue ?',
        @L, mfError + mfOkCancel) = cmOk then Continue;
      Result := False;
      Break;
    end
    else if Code <> 0 then
    begin
      L := I + 1;
      if MessageBox(^C'Arithmetic overflow at line %d.'#13^C +
        'Number found: ' + C + '.'#13^C'Ignore the number and continue ?',
        @L, mfError + mfOkCancel) = cmOk then Continue;
      Result := False;
      Break;
    end;
  until False;
  CalcLine := Result;
end;

function ConcatLine: Boolean;
begin
  S := DelChar(' ', S);
  if Length(CS) + Length(S) > 255 then
  begin
    MessageBox(
      ^C'Formula exceeds line.'#13 +
      ^C'There should be less than 255 chars'#13 +
      ^C'(excluding spaces) to process.', nil, mfError + mfOkButton);
    ConcatLine := False;
  end
  else
  begin
    CS := Concat(CS, S);
    ConcatLine := True;
  end;
end;

begin
  with Editor^ do
  begin
    if not SetupOk then Exit;
    case MathOp of
      moAdd: S := 'Adding numbers';
      moSub: S := 'Subtracting numbers';
      moMul: S := 'Multiplying numbers';
      moDiv: S := 'Dividing numbers';
      moFormula: S := 'Solving expressions';
      moProgram: S := 'Executing program';
    end;
    if IsSelected then CS := 'selected block'
    else CS := 'current line';
    DrawStatusLine(S + ' in the ' + CS + '.');
    if MathOp = moProgram then CalcStrInit;
    CS := '';
    First := True;
    FastGetLine := True;
    if IsSelected then
    begin
      LoI := Area^.KB;
      if Area^.PK = 1 then HiI := Area^.KK - 1
      else HiI := Area^.KK;
    end
    else
    begin
      LoI := Delta.Y + Cursor.Y;
      HiI := LoI;
    end;
    for I := LoI to HiI do
    begin
      if IsSelected then GetSelectedString(I, S)
      else GetValidLine(I, S);
      TrimSt(S);
      if S <> '' then case MathOp of
        moProgram:
          begin
            CS := CalcStr(S, fAuto);
            if StrCalc.ErrorCode <> 0 then Break;
          end;
        moFormula: if not ConcatLine then Exit;
        else if not CalcLine then Exit;
      end;
      if (KbdStatus = 1) and AbortAction then
      begin
        if MathOp = moProgram then CalcStrDone;
        Exit;
      end;
    end;
    if MathOp = moProgram then CalcStrDone;
    if MathOp >= moFormula then
    begin
      if MathOp = moProgram then S := CS
      else
      begin
        while CS[Length(CS)] in
          ['+', '-', '*', '/', '%', '^', '='] do Dec(CS[0]);
        S := CalcStr(CS, fAuto);
      end;
      if StrCalc.ErrorCode <> 0 then
      begin
        MessageBox(^C + S + '.', nil, mfError + mfOkButton);
        Exit;
      end;
    end
    else
    begin
      if First then Exit;
      Str(R:0:10, S);
    end;
    if Pos('.', S) <> 0 then
    begin
      while S[Length(S)] = '0' do Dec(S[0]);
      if S[Length(S)] = '.' then Dec(S[0]);
    end;
    PutStrPrim(Editor, S);
  end;
end;

procedure CalcWordsAndCharsPrim(Editor: PFileEditor);
var
  P: Byte;
  I, LoI, HiI: Integer;
  Params: Array[0..1] of Longint;
  Delims: TCharSet;
  S: String;

procedure CalcLineWordsAndChars;
begin
  P := 1;
  repeat
    while (P <= Length(S)) and (S[P] in Delims) do Inc(P);
    if P <= Length(S) then Inc(Params[0]);
    while (P <= Length(S)) and not (S[P] in Delims) do
    begin
      Inc(P);
      Inc(Params[1]);
    end;
  until P > Length(S);
  if (Length(S) > 1) and (S[Length(S)] = '-') and
    not (S[Length(S) - 1] in Delims) then Dec(Params[0]);
end;

begin
  with Editor^ do
  begin
    if IsSelected then
    begin
      LoI := Area^.KB;
      if Area^.PK = 1 then HiI := Area^.KK - 1
      else HiI := Area^.KK;
      S := 'the selected block';
    end
    else
    begin
      LoI := 0;
      HiI := FileLines^.Count - 1;
      S := TrimmedName(FileName^, 29);
    end;
    DrawStatusLine('Counting words and word characters in '+ S + '.');
    Delims := Editor^.LocalWordDelims;
    FastGetLine := True;
    Params[0] := 0;
    Params[1] := 0;
    for I := LoI to HiI do
    begin
      if IsSelected then GetSelectedString(I, S)
      else GetValidLine(I, S);
      TrimSt(S);
      if S <> '' then CalcLineWordsAndChars;
      if (KbdStatus = 1) and AbortAction then Exit;
    end;
    MessageBox(
      'Number of words:      %d'#13 +
      'Number of word chars: %d',
      @Params, mfInformation + mfOkButton);
  end;
end;

procedure TimeStampPrim(Editor: PFileEditor; What: TTimeStamp);
var
  Year, Month, Day, DW, Hour, Min, Sec, SH: Word;
  S: String[31];
begin
  GetDate(Year, Month, Day, DW);
  GetTime(Hour, Min, Sec, SH);
  if (CountryDate in [csMMDDYY, csDDMMYY]) and
     (CountryCalendar in [csRusHorCal, csRusVerCal]) then S := '£.'
  else if What = tsBoth then S := ','
  else S := '';
  if What = tsDate then S := FormatDateStr(Year, Month, Day) + S
  else if What = tsTime then S := FormatTimeStr(Hour, Min, Sec)
  else S := FormatDateStr(Year, Month, Day) + S + ' ' +
    FormatTimeStr(Hour, Min, Sec);
  if S[Length(S)] <> ' ' then
  begin
    Inc(S[0]);
    S[Length(S)] := ' ';
  end;
  PutStrPrim(Editor, S);
end;

procedure DrawLinePrim(Editor: PFileEditor; Key: Word);
const
  Codes: Array[179..218] of Byte = (
     5, 13, 133, 88, 72, 132, 208, 80, 192, 144, 24, 129, 12,
     3, 11, 14, 7, 10, 15, 37, 82, 48, 96, 176, 224, 112, 160,
     240, 161, 26, 164, 74, 18, 33, 36, 66, 90, 165, 9, 6);
  BackChars = [#1..#7, #15, #19, '*', #176..#178, #219..#223,
    #249, #250, #254, #255];
var
  Ch, C1, C2, C4, C8: Char;
  Pos, B, Code: Byte;
  Double: Boolean;
  Index: Integer;
  S: String;

procedure GetLocalChars;
begin
  with Editor^ do
  begin
    if (Key = kbUp) or (Index = 0) then S := ''
    else GetValidLine(Index - 1, S);
    if Length(S) < Pos then C1 := ' '
    else C1 := S[Pos];
    GetValidLine(Index, S);
    if (Key = kbRight) or (Length(S) < Pos + 1) then C2 := ' '
    else C2 := S[Pos + 1];
    if (Key = kbLeft) or (Pos = 1) or (Length(S) < Pos - 1) then C8 := ' '
    else C8 := S[Pos - 1];
    if Key = kbDown then S := ''
    else GetValidLine(Index + 1, S);
    if Length(S) < Pos then C4 := ' '
    else C4 := S[Pos];
  end;
end;

procedure Char2Code(const AChar: Char; var C: Byte);
begin
  if not (AChar in [#179..#218]) then C := 0
  else C := Codes[Byte(AChar)];
end;

procedure Code2Char(const ACode: Byte; var C: Char);
var
  I: Byte;
begin
  for I := 179 to 218 do
    if Codes[I] = ACode then
    begin
      C := Char(I);
      Exit;
    end;
  C := #0;
end;

procedure AdjustCode(var C: Byte);
begin
  if Double then
  begin
    if C and 1 <> 0 then C := (C or $10) and not 1;
    if C and 2 <> 0 then C := (C or $20) and not 2;
    if C and 4 <> 0 then C := (C or $40) and not 4;
    if C and 8 <> 0 then C := (C or $80) and not 8;
  end
  else
  begin
    if C and $10 <> 0 then C := (C or 1) and not $10;
    if C and $20 <> 0 then C := (C or 2) and not $20;
    if C and $40 <> 0 then C := (C or 4) and not $40;
    if C and $80 <> 0 then C := (C or 8) and not $80;
  end;
end;

begin
  case Key of
    kbUp: B := 1;
    kbRight: B := 2;
    kbDown: B := 4;
    kbLeft: B := 8;
    else Exit;
  end;
  with Editor^ do
  begin
    Double := State and sfDrawDouble <> 0;
    if Double then B := B shl 4;
    Index := Delta.Y + Cursor.Y;
    Pos := Delta.X + Cursor.X + 1;
    GetLocalChars;
    Char2Code(C1, Code);
    if Code and $40 <> 0 then B := B or $10
    else if Code and 4 <> 0 then B := B or 1;
    Char2Code(C2, Code);
    if Code and $80 <> 0 then B := B or $20
    else if Code and 8 <> 0 then B := B or 2;
    Char2Code(C4, Code);
    if Code and $10 <> 0 then B := B or $40
    else if Code and 1 <> 0 then B := B or 4;
    Char2Code(C8, Code);
    if Code and $20 <> 0 then B := B or $80
    else if Code and 2 <> 0 then B := B or 8;
    Code2Char(B, Ch);
    if Ch = #0 then
    begin
      AdjustCode(B);
      Code2Char(B, Ch);
      if Ch = #0 then
        if C8 in BackChars then Ch := C8
        else if C4 in BackChars then Ch := C4
        else if C1 in BackChars then Ch := C1
        else if C2 in BackChars then Ch := C2
        else case Key of
          kbUp, kbDown: if Double then Ch := 'º' else Ch := '³';
          kbRight, kbLeft: if Double then Ch := 'Í' else Ch := 'Ä';
        end;
    end;
    Drawing := True;
{    if IsInsert and (Key <> kbLeft) then
       InsertCharPrim(Editor, Ch, Index, Pos)
    else}
    ReplaceCharPrim(Editor, Ch, Index, Pos);
    Drawing := False;
  end;
end;

procedure GetNameAtCursor(Editor: PFileEditor; var S: FNameStr);
var
  B, E: Byte;
  SaveDelims: TCharSet;
begin
  SaveDelims := Editor^.LocalWordDelims;
  Editor^.LocalWordDelims :=
    [' ', ';', ',', '=', '+', '<', '>', '|', '"', '[', ']'];
  S := Trim(Editor^.GetWord(B, E));
  Editor^.LocalWordDelims := SaveDelims;
  if S <> '' then S := lFExpand(S);
end;

function CreateDirPrim(const S: String): Boolean;
begin
  if MessageBox(
    ^C'Create the directory'#13^C'|' + S + '| ?',
    nil, mfConfirmation + mfOkCancel) = cmOk then
  begin
    MkDirPrim(S, nil);
    Message(Desktop, evBroadcast, cmUpdateDisk, nil);
    CreateDirPrim := DirPresent(S);
  end
  else CreateDirPrim := False;
end;

procedure OpenFileAtCursorPrim(Editor: PFileEditor);
var
  B: Boolean;
  S, D: FNameStr;
begin
  GetNameAtCursor(Editor, S);
  if S = '' then Exit;
  if IsWild(S) then
  begin
    HistoryAdd(HistoryID, S, True);
    Pending.What := evCommand;
    Pending.Command := cmOpenASCII;
  end
  else
  begin
    CancelSysErrors := False;
    D := JustPathName(S);
    B := DirPresent(D);
    if CancelSysErrors then Exit;
    if B or CreateDirPrim(D) then
    begin
      if (JustExtension(S) = '') and (S[Length(S)] <> '.') then
      begin
        D := JustExtension(Editor^.FileName^);
        if D <> '' then S := ForceExtension(S, D);
      end;
      D := AddedSlash(JustPathName(Editor^.FileName^)) + JustFileName(S);
      if ThisFileExists(D) then S := D;
      Message(Application, evCommand, cmOpenASCII, @S);
    end;
  end;
end;

procedure MkDirAtCursorPrim(Editor: PFileEditor);
var
  Attr: Word;
  C: String[15];
  S: FNameStr;
  F: lFile;
begin
  GetNameAtCursor(Editor, S);
  if S = '' then Exit;
  S := lFExpand(S);
  while S[Length(S)] = '\' do Dec(S[0]);
  lAssignFile(F, S);
  CancelSysErrors := False;
  lGetFAttr(F, Attr);
  if CancelSysErrors then Exit;
  if DosError = 0 then
  begin
    if Attr and Directory = 0 then C := 'file' else C := 'directory';
    MessageBox(^C'The ' + C + #13^C'|' + S + '|'#13^C'already exists.',
      nil, mfWarning + mfOkButton);
    Exit;
  end;
  CreateDirPrim(S);
end;

end.