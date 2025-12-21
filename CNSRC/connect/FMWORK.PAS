{$I-,F+,O+,X+}
unit FMWork;

interface

uses FileMngr;

procedure FocusCharPrim(FManager: PPanel; AChar: Char);
procedure InvertPrim(FManager: PPanel);
procedure RestoreSelectionPrim(FManager: PPanel);
procedure SortSelPrim(FManager: PPanel);
procedure CompareDirsPrim(FManager: PPanel);
procedure SwapPanelsPrim(FManager: PPanel);

implementation

uses Dos, Objects, Drivers, Views, Dialogs, App, MsgBox, PanelRec, FMAbort,
  FMBars, FMDrvSel, DirPrim, DirTree, DosTools, Keyboard, HistList, History,
  UnixMask, LFN, TPString, Consts, Commands, Defaults;

procedure FocusCharPrim(FManager: PPanel; AChar: Char);
var
  Short: Boolean;
  Ch: Char;
  Level: Byte;
  Index: Integer;
  SR: PPanelRec;
  SS, NS: String;

procedure sAddNameExt(const Path: FNameStr; P: PPanelRec; var S: FNameStr);
var
  SavePath: PString;
begin
  with FManager^ do
    if Status = stTree then
      TreeAddNameExt(Path, PTreeRec(P), S, TheTree^.ForceLong)
    else
    begin
      SavePath := P^.ThePath;
      if Short then P^.ThePath := nil;
      AddNameExt(Path, P, S);
      P^.ThePath := SavePath;
    end;
end;

function SearchNameExists: Boolean;
var
  I: Integer;
  S: String;
begin
  with FManager^ do
    for I := 0 to List^.Count - 1 do
    begin
      SR := List^.At(I);
      sAddNameExt('', SR, S);
      S := JustName(S);
      if (FMSearchOptions and fsSearchCaseSensitive = 0) or
	 (SR^.Attr and Directory <> 0) then UpcaseSt(S)
      else LocaseSt(S);
      if S = SearchStr then
      begin
	Index := I;
	SearchNameExists := True;
	Exit;
      end;
    end;
  SearchNameExists := False;
end;

function GetMatch(Item:	Integer): String;
var
  S, N, E: String;
begin
  with FManager^ do
  begin
    SR := List^.At(Item);
    if (Status = stTree) and
       (PTreeRec(SR)^.Info and $7F > SearchLevel) then S := ''
    else sAddNameExt('', SR, S);
    N := JustName(S);
    E := JustExtension(S);
    if DotPos = 0 then
      if (SS = '.') and (Ch in [^B, ^L]) then
	if E = '' then GetMatch := '.' else GetMatch := ''
      else GetMatch := Concat('.', E)
    else if (DotPos > 0) and (Length(N) <> DotPos) then GetMatch := ''
    else GetMatch := Concat(N, E);
  end;
end;

procedure FindCursorPos;
var
  I, W: Integer;
  EmptyChars: TCharSet;
  S: String;
begin
  with FManager^ do
  begin
    CursorPos := 0;
    SR := List^.At(Index);
    I := Indent;
    W := Size.X;
    Size.X := 255;
    Indent := 0;
    S := GetText(Index,	255);
    Size.X := W;
    Indent := I;
    if Short then
    begin
      if S[0] > #12 then S[0] := #12;
      S[9] := '.';
    end;
    while S[Byte(S[0])]	= ' ' do Dec(S[0]);
    if (FMSearchOptions and fsSearchCaseSensitive = 0) or
       (SR^.Attr and Directory <> 0) then UpcaseSt(S)
    else LocaseSt(S);
    for	I := 1 to Byte(SearchStr[0]) do
    begin
      if CursorPos < Byte(S[0])	then Inc(CursorPos);
      while (CursorPos < Byte(S[0])) and
	(S[CursorPos] <> SearchStr[I]) do Inc(CursorPos);
    end;
    EmptyChars := ['.', '°'];
    if Short then Include(EmptyChars, ' ');
    while (CursorPos < Byte(S[0])) and
      (S[CursorPos + 1]	in EmptyChars) do Inc(CursorPos);
    if Status = stTree then Dec(CursorPos)
    else if Short and (CursorPos >= ColWidth - 1) then
      CursorPos := ColWidth - 2;
  end;
end;

procedure ConvertChar;
var
  IsLo:	Boolean;
begin
  IsLo := Ch <>	TPString.Upcase(Ch);
  Ch :=	LatinChar(Ch);
  if IsLo then Ch := Locase(Ch);
end;

begin
  with FManager^ do
  begin
{
    if (List^.Count = 0) or (Status >= stInfo) or
       ((AChar = #8) and (SearchPos <= 1)) or
       ((Status = stBrief) and
	((Settings and seLongNames <> 0) or (ColWidth <> 13)) and
	(SearchPos >= ColWidth - 1) and (AChar <> #8)) or
       ((Status = stFull) and
	(Settings and seLongNames = 0) and (ColWidth <> 13) and
	(SearchPos >= ColWidth - 1) and	(AChar <> #8)) then Exit;
}

   if (List^.Count = 0) or (Status >= stInfo) or
      ((AChar = #8) and (SearchPos <= 1)) or
      (not (AChar in [#8, ^B, ^L]) and
      (SearchPos >= ColWidth - 2)) then Exit;
    if (Status = stTree) or
       (FMSearchOptions	and fsSearchCaseSensitive = 0) then
      Ch := Upcase(AChar)
    else Ch := AChar;
    if FMSearchOptions and fsIgnoreInterChar <>	0 then ConvertChar;
    Short := (Settings and seLongNames = 0) and
      (Status <> stTree) and (ColWidth = 13);
    if (Ch = '\') and (Status = stTree) then
    begin
      if SearchStr = '' then
      begin
	Level := 0;
	Index := 1;
      end
      else
      begin
	Level := PTreeRec(TheTree^.At(Focused))^.Info and $7F + 1;
	Index := Focused + 1;
      end;
      SR := TheTree^.At(Index);
      if (SR = nil) or (PTreeRec(SR)^.Info and $7F <> Level) then Exit;
      FocusItem(Index);
      Owner^.State := Owner^.State or sfSearching;
      SearchLevel := Level;
      CursorPos := (Level + 1) * 3 + 1;
      DrawView;
      Exit;
    end;
    if Ch = '.'	then
    begin
      if (SearchStr <> '') and SearchNameExists then SS := SearchStr
      else if SearchPos <= 1 then SS := '.'
      else
      begin
	SR := List^.At(Focused);
	sAddNameExt('', SR, SS);
	SS := JustName(SS);
	if (FMSearchOptions and fsSearchCaseSensitive = 0) or
	   (SR^.Attr and Directory <> 0) then UpcaseSt(SS)
	else LocaseSt(SS);
      end;
      SearchPos := Length(SS);
      if SS = '.' then DotPos := 0
      else DotPos := SearchPos;
    end
    else if SearchPos =	1 then SS := Ch
    else if Ch in [^B, ^L] then SS := SearchStr
    else if Ch = #8 then
    begin
      Dec(SearchPos, 2);
      if SearchPos < DotPos then DotPos := -1;
      if SearchPos = 0 then
      begin
	SearchStr := '';
	SearchPos := 1;
	CursorPos := 0;
	DotPos := -1;
	Indent := 0;
	DrawView;
	Exit;
      end;
      SS := SearchStr;
      Dec(SS[0]);
    end
    else SS := SearchStr + Ch;
    if Ch = ^B then Index := Focused - 1
    else if Ch = ^L then Index := Focused + 1
    else if SearchLevel <> $FF then Index := Focused
    else Index := 0;
    while (Index >= 0) and (Index < Range) do
    begin
      if (Status = stTree) and (SearchLevel <> $FF) and
	 (PTreeRec(TheTree^.At(Index))^.Info and $7F < SearchLevel) then
	Exit;
      NS := System.Copy(GetMatch(Index), 1, SearchPos);
      if (FMSearchOptions and fsSearchCaseSensitive = 0) or
	 (SR^.Attr and Directory <> 0) then UpcaseSt(NS)
      else LocaseSt(NS);
      if Pos(SS, NS) = 1 then
      begin
	SearchStr := SS;
	if Index <> Focused then
	begin
	  Owner^.State := Owner^.State and not sfSearching;
	  FocusItem(Index);
	  Owner^.State := Owner^.State or sfSearching;
	end;
	Dec(Cursor.X, CursorPos);
	if not (Ch in [^B, ^L]) then Inc(SearchPos);
	if Short and (SearchPos >= ColWidth) then
	  SearchPos := ColWidth - 1;
	FindCursorPos;
	if not Short and (Status <> stTree) then
	begin
	  while (Indent > 0) and (CursorPos - Indent < 0) do
	    Dec(Indent);
	  while (Indent < 255) and (CursorPos - Indent >= Size.X) do
	    Inc(Indent);
	  DrawView;
	end
	else SetCursor(Cursor.X + CursorPos, Cursor.Y);
	Exit;
      end
      else if Ch = ^B then Dec(Index) else Inc(Index);
    end;
  end;
end;

procedure InvertPrim(FManager: PPanel);
var
  CtrlDown: Boolean;
  I: Integer;
  SR: PPanelRec;
begin
  with FManager^ do
  begin
    if (State and sfVisible = 0) or (List^.Count = 0) or
       (Status >= stTree) then Exit;
    CtrlDown := GetShiftState and kbCtrlShift <> 0;
    for	I := 0 to List^.Count -	1 do
    begin
      SR := List^.At(I);
      if (SR^.Attr and Directory <> 0) = CtrlDown then
	SetSelect(SR, not SR^.Selected);
      if (KbdStatus = 1) and FMAbortAction then	Break;
    end;
    FocusItem(Focused);
  end;
end;

procedure RestoreSelectionPrim(FManager: PPanel);
begin
  with FManager^ do
  begin
    if (State and sfVisible = 0) or (List^.Count = 0) or
       (Status >= stInfo) then Exit;
    if SelList^.Count = 0 then
    begin
      if SelCount = 0 then Exit;
      DrawStatusLine('Unselecting panel items.');
      UnselectAll;
    end
    else
    begin
      DrawStatusLine('Restoring panel selection.');
      RestoreTags(SelList);
      DoneSelList;
      InitSelList;
    end;
    FocusItem(Focused);
  end;
end;

procedure SortSelPrim(FManager: PPanel);
var
  I: Integer;
  S: FNameStr;
begin
  with FManager^ do
  begin
    if (State and sfVisible = 0) or (Status >= stTree) or
       (Files^.Count = 0) then Exit;
    GetItemStr(Focused, S);
    Files^.Sort;
    GetItemNum(S, I);
    FocusItem(I);
    SelChanged := False;
  end;
end;

function CompareOptionsDialog(var CompareMask: FNameStr): Word;
type
  TData = record
    Opt: Word;
    AdvOpt: Longint;
    Mask: FNameStr;
    Unix: Word;
    Cnt: Word;
  end;
var
  C: Word;
  D: PDialog;
  Control: PView;
  H: PHistory;
  R: TRect;
  Data: TData;
begin
  R.Assign(0, 0, 42, 21);
  D := InitSimpleDialog(R, 'File compare options', hcCompareDirectories);
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Assign(3, 3, Size.X - 3, 9);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Compare by si~z~e',
      NewSItem('Compare by ti~m~e',
      NewSItem('Compare by at~t~ribute',
      NewSItem('Select in bot~h~ panels',
      NewSItem('Unse~l~ect same files',
      NewSItem('~P~rompt on compare', nil))))))));
    Insert(Control);
    R.Assign(2, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(R, 'Options', Control)));

    R.Assign(Size.X - 8, 3, Size.X - 3, 5);
    Control := New(PMultiCheckBoxes, Init(R,
      NewSItem(' ', NewSItem(' ', nil)), 3, cfTwoBits, ' <>'));
    Insert(Control);

    R.Assign(13, 10, Size.X - 6, 11);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    H := StandardHistory(Control, MaskHistoryId);
    H^.HistoryPutFunc := UNIXPutHistoryFunc;
    H^.HistoryGetFunc := UNIXGetHistoryFunc;
    R.Assign(2, 10, 13, 11);
    Insert(New(PLabel, Init(R, '~N~ame mask', Control)));
    R.Assign(3, 12, Size.X - 3, 13);
    Insert(New(PCheckBoxes, Init(R,
      NewSItem('~U~NIX style mask', nil))));

    R.Assign(3, 15, Size.X - 3, 17);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~C~ompare same files by contents',
      NewSItem('~D~o not select missing files', nil))));
    Insert(Control);
    R.Assign(2, 14, Size.X - 3, 15);
    Insert(New(PLabel, Init(R,
      'Additional file compare options', Control)));

    SelectNext(True);
    SelectNext(True);
  end;
  Data.Opt := CompareOptions;
  Data.AdvOpt := CmpAdvOpt;
  Data.Mask := HistoryStr(MaskHistoryID, 0);
  Data.Unix := Byte(UnixFlag);
  Data.Cnt := AddCmpOpt;
  C := Application^.ExecuteDialog(D, @Data, False);
  if C <> cmCancel then
  begin
    CompareOptions := Data.Opt;
    CmpAdvOpt := Data.AdvOpt;
    CompareMask := Data.Mask;
    UnixFlag :=	Data.Unix <> 0;
    AddCmpOpt := Data.Cnt;
  end;
  CompareOptionsDialog := C;
end;

procedure CompareDirsPrim(FManager: PPanel);
var
  CtrlDown, ShiftDown, Found, UseMask, Abort: Boolean;
  PipePos, AdvSize, AdvTime: Byte;
  I, SI: Integer;
  SR, OSR: PPanelRec;
  S, Mask: FNameStr;
  States: TState;

procedure NameLengthsToFit(var L1, L2: Byte; Len: Byte);
begin
  repeat
    if L1 + L2 <= Len then Exit;
    if L1 >= L2 then Dec(L1);
    if L2 >= L1 then Dec(L2);
  until False;
end;

function SameBuffers(B1, B2: PByteArray; Size: Word): Boolean;
var
  I: Word;
begin
  if Size <> 0 then for I := 0 to Size - 1 do
    if B1^[I] <> B2^[I] then
    begin
      SameBuffers := False;
      Exit;
    end;
  SameBuffers := True;
end;

function SameFiles(Name1, Name2: FNameStr): Boolean;
var
  Same: Boolean;
  Len1, Len2: Byte;
  BufSize, Bytes1, Bytes2, Bytes: Word;
  L: Longint;
  B1, B2: PByteArray;
  F1, F2: lFile;
begin
  if CompUCString(Name1, Name2) = Equal then
  begin
    SameFiles := True;
    Exit;
  end;
  L := MaxAvail;
  if L > 65536 + 8192 then BufSize := 32768
  else if L > 32768 + 8192 then BufSize := 16384
  else if L > 16384 + 8192 then BufSize := 8192
  else if L > 8192 + 8192 then BufSize := 4096
  else BufSize := 512;
  GetMem(B1, BufSize);
  GetMem(B2, BufSize);
  lAssignFile(F1, Name1);
  lResetFile(F1, 1);
  lAssignFile(F2, Name2);
  lResetFile(F2, 1);
  Len1 := Length(Name1);
  Len2 := Length(Name2);
  NameLengthsToFit(Len1, Len2, 52);
  LogEvent := lcDiskRead;
  DrawStatusLine('Comparing ' +
    TrimmedName(Name1, Len1) + ' and ' +
    TrimmedName(Name2, Len2) + '.');
  Same := True;
  repeat
    BlockRead(F1.F, B1^, BufSize, Bytes1);
    BlockRead(F2.F, B2^, BufSize, Bytes2);
    if Bytes2 < Bytes1 then Bytes := Bytes2
    else Bytes := Bytes1;
    if not SameBuffers(B1, B2, Bytes) then
    begin
      Same := False;
      Break;
    end;
  until (Bytes <> BufSize) or (IOResult <> 0);
  FreeMem(B1, BufSize);
  FreeMem(B2, BufSize);
  Close(F2.F);
  Close(F1.F);
  InOutRes := 0;
  SameFiles := Same;
end;

function SizesMatch(S1, S2: Longint): Boolean;
begin
  SizesMatch :=
    ((AdvSize = caNo) and (S1 = S2)) or
    ((AdvSize = caGreater) and (S1 <= S2)) or
    ((AdvSize = caLess) and (S1 >= S2));
end;

function TimesMatch(T1, T2: Longint): Boolean;
begin
  TimesMatch :=
    ((AdvTime = caNo) and (T1 = T2)) or
    ((AdvTime = caGreater) and (T1 <= T2)) or
    ((AdvTime = caLess) and (T1 >= T2));
end;

function FilesMatch(P1, P2: PPanel; R1, R2: PPanelRec): Boolean;
var
  B: Boolean;
  S1, S2: FNameStr;
begin
  B :=
    ((CompareOptions and dcSize	= 0) or
      SizesMatch(SR^.Size, OSR^.Size)) and
    ((CompareOptions and dcTime	= 0) or
      TimesMatch(SR^.Time, OSR^.Time)) and
    ((CompareOptions and dcAttr	= 0) or
     (SR^.Attr = OSR^.Attr));
  if B and (AddCmpOpt and caCompareContents <> 0) and
    not P1^.InArchive and not P2^.InArchive then
  begin
    P1^.GetRecStr(R1, S1);
    P2^.GetRecStr(R2, S2);
    B := SameFiles(S1, S2);
  end;
  FilesMatch := B;
end;

label
  Quit;
begin
  with FManager^ do
  begin
    if (State and sfVisible = 0) or (Opposite^.State and sfVisible = 0) or
       (Status >= stTree) or (Opposite^.Status >= stTree) then
    begin
      MessageBox(
	^C'You need two file panels to use the Compare Directories command.',
	nil, mfError + mfOkButton);
      Exit;
    end;
    if (Status >= stTree) or (Opposite^.Status >= stTree) then Exit;
    Mask := '';
    if CompareOptions and dcPrompt <> 0 then
    begin
      if CompareOptionsDialog(Mask) = cmCancel then Exit;
      CtrlDown := GetShiftState and kbCtrlShift <> 0;
    end
    else CtrlDown := False;
    ShiftDown := CtrlDown or
      (GetShiftState and (kbLeftShift + kbRightShift) <> 0);
    UseMask := not CtrlDown and (Mask <> '') and (Mask <> '*.*');
    if UseMask and UnixFlag then MakeAutomaton(Mask, States);
    PipePos := Pos('|',	Mask);
    AdvSize := CmpAdvOpt and 3;
    AdvTime := (CmpAdvOpt shr 2) and 3;
    Abort := False;
    DrawStatusLine('Comparing two directories.');
    for	I := 0 to List^.Count -	1 do
    begin
      SR := List^.At(I);
      if ShiftDown or (SR^.Attr and Directory = 0) then
      begin
	if CtrlDown and (SR^.Attr and Directory = 0) then Continue;
	SI := 0;
	AddNameExt('', SR, S);
	if UseMask and (SR^.Attr and Directory = 0) then
	  if (UnixFlag and not IsAcceptable(S, States)) or
	     (not UnixFlag and not NameMatchesMultiMask(
	       S, Mask, PipePos)) then Continue;
	Opposite^.FindByName(S, SI);
	if SI =	-1 then	Found := {False}
	  AddCmpOpt and caDoNotSelectMissing <> 0
	else
	begin
	  OSR := Opposite^.List^.At(SI);
	  if ShiftDown and (SR^.Attr and Directory <> 0) then
	    Found := OSR^.Attr and Directory <> 0
	  else Found := FilesMatch(FManager, Opposite, SR, OSR);
	end;
	if CompareOptions and dcUnselSame <> 0 then
	  SetSelect(SR,	not Found)
	else if	not Found then SetSelect(SR, True);
      end;
      if Abort or ((KbdStatus = 1) and FMAbortAction) then Goto Quit;
    end;
    if CompareOptions and dcBoth <> 0 then
    for	I := 0 to Opposite^.List^.Count	- 1 do
    begin
      SR := Opposite^.List^.At(I);
      if ShiftDown or (SR^.Attr and Directory = 0) then
      begin
	if CtrlDown and (SR^.Attr and Directory = 0) then Continue;
	SI := 0;
	AddNameExt('', SR, S);
	if UseMask and (SR^.Attr and Directory = 0) then
	  if (UnixFlag and not IsAcceptable(S, States)) or
	     (not UnixFlag and not NameMatchesMultiMask(
	       S, Mask, PipePos)) then Continue;
	FindByName(S, SI);
	if SI =	-1 then	Found := {False}
	  AddCmpOpt and caDoNotSelectMissing <> 0
	else
	begin
	  OSR := List^.At(SI);
	  if ShiftDown and (SR^.Attr and Directory <> 0) then
	    Found := OSR^.Attr and Directory <> 0
	  else Found := FilesMatch(FManager, Opposite, SR, OSR);
	end;
	if CompareOptions and dcUnselSame <> 0 then
	  Opposite^.SetSelect(SR, not Found)
	else if	not Found then Opposite^.SetSelect(SR, True);
      end;
      if Abort or ((KbdStatus = 1) and FMAbortAction) then Goto Quit;
    end;
Quit:
    FocusItem(Focused);
    Opposite^.FocusItem(Opposite^.Focused);
  end;
end;

procedure SwapPanelsPrim(FManager: PPanel);
var
  B: Byte;
  P: PPanel;
  R, RO: TRect;
begin
  with FManager^ do
  begin
    Owner^.Owner^.Lock;
    GetBounds(R);
    Opposite^.GetBounds(RO);
    Locate(RO);
    Which := Byte(not Boolean(Which));
    Opposite^.Locate(R);
    Opposite^.Which := Byte(not	Boolean(Which));
    with PPanelWindow(Owner)^ do
    begin
      P	:= LeftPanel;
      LeftPanel	:= RightPanel;
      RightPanel := P;
      PView(P) := LeftSelector;
      LeftSelector := RightSelector;
      PView(RightSelector) := P;
      B := LeftPanel^.DrvSelAlignment;
      LeftPanel^.DrvSelAlignment := RightPanel^.DrvSelAlignment;
      RightPanel^.DrvSelAlignment := B;
      B := LeftPanel^.DrvSelSize;
      LeftPanel^.DrvSelSize := RightPanel^.DrvSelSize;
      RightPanel^.DrvSelSize := B;
      if LeftSelector <> nil then
	PDriveSelector(LeftSelector)^.AdjustBounds;
      if RightSelector <> nil then
	PDriveSelector(RightSelector)^.AdjustBounds;
      PView(P) := LeftBar;
      LeftBar := RightBar;
      PView(RightBar) := P;
      B := LeftPanel^.BarAlignment;
      LeftPanel^.BarAlignment := RightPanel^.BarAlignment;
      RightPanel^.BarAlignment := B;
      if LeftBar <> nil then PPanelBar(LeftBar)^.AdjustBounds;
      if RightBar <> nil then PPanelBar(RightBar)^.AdjustBounds;
      Frame^.DrawView;
    end;
    Owner^.Owner^.Unlock;
  end;
end;

end.
