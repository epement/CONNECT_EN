{$I-,X+,O+,F+}
unit TreeDlg;

interface

uses Objects, Drivers, Views, Dialogs, DirTree;

type
  PTreeViewer = ^TTreeViewer;
  TTreeViewer = object(TListViewer)
    Tree: PTreeCollection;
    Text: PLabel;
    SearchStr: String[63];
    SearchPos: Integer;
    CursorPos: Integer;
    DotPos: Integer;
    SearchLevel: Byte;
    CurDir: FNameStr;
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure FocusItem(Item: Integer); virtual;
    procedure GetData(var Rec); virtual;
    function GetCopyText(Item: Integer; MaxLen: Integer): String; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure NewDrive;
    procedure ReRead;
    procedure DirHistory;
    procedure ChangeTreeLevel(Grow, SetCur: Boolean);
    procedure Paste;
  end;

  PTreeInfoPane = ^TTreeInfoPane;
  TTreeInfoPane = object(TView)
    Dir: FNameStr;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure TreeDialog(var S: FNameStr);
procedure SearchDirDialog(var S: FNameStr);

implementation

uses Dos, App, DirPrim, DiskBase, PanelRec, Trees, Swaps, StrCol, ClipPrim,
  FMSecond, HistList, HistWin, History, HeapUMB, LFN, TPString, Consts,
  Commands, Defaults;

procedure NewLabelText(P: PLabel; const ADir: FNameStr);
var
  S: FNameStr;
begin
  S := '~T~he directory structure of ';
  if ADir[1] = '\' then S := S + 'resource ' + ADir
  else S := S + 'drive ' + ADir[1] + ':';
  DisposeStr(P^.Text);
  P^.Text := NewStr(S);
  P^.DrawView;
end;

destructor TTreeViewer.Done;
begin
  if Tree <> nil then Dispose(Tree, Done);
  TListViewer.Done;
end;

procedure TTreeViewer.Draw;
begin
  TListViewer.Draw;
  SetCursor(CursorPos - HScrollBar^.Value + 1, Cursor.Y);
end;

procedure TTreeViewer.FocusItem(Item: Integer);
var
  P: Pointer;
  S: FNameStr;
begin
  S := PTreeRec(Tree^.At(0))^.Name;
  if (CurDir = '') or ((S <> '') and (CurDir[1] <> S[1])) then
    GetCurDir(Byte(S[1]) - $40, CurDir);
  TListViewer.FocusItem(Item);
  S := Tree^.GetDirStr(Focused);
  if S = '' then P := nil else P := @S;
  Message(Owner, evBroadcast, cmListItemSelected, P);
  SearchStr := '';
  SearchPos := 1;
  CursorPos := 0;
  DotPos := -1;
  SearchLevel := $FF;
  if State and sfCursorVis <> 0 then HideCursor;
end;

procedure TTreeViewer.GetData(var Rec);
var
  S: FNameStr;
begin
  S := Tree^.GetDirStr(Focused);
  Move(S, Rec, Length(S) + 1);
end;

function TTreeViewer.GetCopyText(Item: Integer; MaxLen: Integer): String;
begin
  GetCopyText := Tree^.GetDirStr(Item);
end;

function TTreeViewer.GetText(Item: Integer; MaxLen: Integer): String;
begin
  GetText := Tree^.GetItemStr(Item, CurDir, False);
end;

procedure TTreeViewer.HandleEvent(var Event: TEvent);

procedure FocusChar(AChar: Char);
var
  Ch: Char;
  Level: Byte;
  Index, SavePos, SaveDot: Integer;
  SR: PTreeRec;
  SS, NS: String;

function SearchNameExists: Boolean;
var
  I: Integer;
  S: String;
begin
  for I := 0 to Tree^.Count - 1 do
  begin
    SR := Tree^.At(I);
    TreeAddNameExt('', SR, S, Tree^.ForceLong);
    S := JustName(S);
    if CompUCString(S, SearchStr) = Equal then
    begin
      Index := I;
      SearchNameExists := True;
      Exit;
    end;
  end;
  SearchNameExists := False;
end;

function GetMatch(Item: Integer): String;
var
  S, N, E: String;
begin
  SR := Tree^.At(Item);
  if SR^.Info and $7F > SearchLevel then S := ''
  else TreeAddNameExt('', SR, S, Tree^.ForceLong);
  N := JustName(S);
  E := JustExtension(S);
  if DotPos = 0 then
    if (SS = '.') and (Ch in [^B, ^L]) then
      if E = '' then GetMatch := '.' else GetMatch := ''
    else GetMatch := Concat('.', E)
  else if (DotPos > 0) and (Length(N) <> DotPos) then GetMatch := ''
  else GetMatch := Concat(N, E);
end;

procedure FindCursorPos;
var
  I: Integer;
  S: String;
begin
  CursorPos := 0;
  S := GetText(Index, 255);
  for I := 1 to Byte(SearchStr[0]) do
  begin
    if CursorPos < Byte(S[0]) - 1 then Inc(CursorPos);
    while (CursorPos < Byte(S[0]) - 1) and
      (TPString.Upcase(S[CursorPos]) <>
       TPString.Upcase(SearchStr[I])) do Inc(CursorPos);
  end;
  while (CursorPos < Byte(S[0]) - 1) and (S[CursorPos + 1] = '.') do
    Inc(CursorPos);
end;

begin
  if (Tree^.Count = 0) or
     ((AChar = #8) and (SearchPos <= 1)) then Exit;
  Ch := AChar;
  if Ch = '\' then
  begin
    if SearchStr = '' then
    begin
      Level := 0;
      Index := 1;
    end
    else
    begin
      Level := PTreeRec(Tree^.At(Focused))^.Info and $7F + 1;
      Index := Focused + 1;
    end;
    SR := Tree^.At(Index);
    if (SR = nil) or (SR^.Info and $7F <> Level) then Exit;
    FocusItem(Index);
    SearchLevel := Level;
    CursorPos := (Level + 1) * 3 + 1;
    DrawView;
    ShowCursor;
    Exit;
  end;
  if Ch = '.' then
  begin
    if (SearchStr <> '') and SearchNameExists then SS := SearchStr
    else if SearchPos <= 1 then SS := '.'
    else
    begin
      SR := Tree^.At(Focused);
      TreeAddNameExt('', SR, SS, Tree^.ForceLong);
      SS := JustName(SS);
    end;
    SearchPos := Length(SS);
    if SS = '.' then DotPos := 0
    else DotPos := SearchPos;
  end
  else if SearchPos = 1 then SS := Ch
  else if Ch in [^B, ^L] then SS := SearchStr
  else if Ch = #8 then
  begin
    Dec(SearchPos, 2);
    if SearchPos < DotPos then DotPos := -1;
    if SearchPos = 0 then
    begin
      FocusItem(Focused);
      DrawView;
      HScrollBar^.SetValue(0);
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
    if (SearchLevel <> $FF) and
       (PTreeRec(Tree^.At(Index))^.Info and $7F < SearchLevel) then
      Exit;
    NS := System.Copy(GetMatch(Index), 1, SearchPos);
    if UCPos(SS, NS) = 1 then
    begin
      SavePos := SearchPos + Byte(not (Ch in [^B, ^L]));
      SaveDot := DotPos;
      Level := SearchLevel;
      if Index <> Focused then FocusItem(Index)
      else Dec(Cursor.X, CursorPos);
      SearchStr := SS;
      SearchPos := SavePos;
      DotPos := SaveDot;
      SearchLevel := Level;
      FindCursorPos;
      SetCursor(Cursor.X + CursorPos, Cursor.Y);
      if State and sfCursorVis = 0 then ShowCursor;
      if Cursor.X < 1 then
	HScrollBar^.SetValue(HScrollBar^.Value + Cursor.X - 1)
      else if Cursor.X >= Size.X then
	HScrollBar^.SetValue(HScrollBar^.Value + Cursor.X - Size.X + 1);
      Exit;
    end
    else if Ch = ^B then Dec(Index) else Inc(Index);
  end;
end;

procedure FocusNextPeer(Up: Boolean);
var
  I: Integer;
  Level: Byte;
  Index, SavePos, SaveDot: Integer;
  SR: PTreeRec;
begin
  SR := Tree^.At(Focused);
  if SR = nil then Exit;
  Level := SR^.Info and $7F;
  I := Focused;
  repeat
    if Up then Dec(I) else Inc(I);
    SR := Tree^.At(I);
    if (SR = nil) or (SR^.Info and $7F < Level) then Exit;
    if SR^.Info and $7F = Level then
    begin
      FocusItem(I);
      Exit;
    end;
  until False;
end;

begin
  if (Event.What = evKeyDown) and
     ((Event.KeyCode = kbGrayPlus) or
      (Event.KeyCode = kbGrayMinus) or
      (Event.KeyCode = kbGrayMul)) then
  begin
    ChangeTreeLevel(Event.KeyCode = kbGrayPlus, Event.KeyCode = kbGrayMul);
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and (Event.KeyCode = kbSpace) and
    (SearchStr = '') and (CurDir <> '') then
  begin
    FocusItem(Tree^.GetDirNum(CurDir, 0, Focused));
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and
    (Event.CharCode in [^B, ^L, #8, #32..#255]) then
  begin
    FocusChar(Event.CharCode);
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and (Event.CharCode = ^W) then
  begin
    DirHistory;
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and (Event.KeyCode = kbShiftIns) then
  begin
    Paste;
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and
    ((Event.KeyCode = kbCtrlDn) or (Event.KeyCode = kbCtrlUp)) then
  begin
    FocusNextPeer(Event.KeyCode = kbCtrlUp);
    Event.What := evNothing;
  end
  else if (Event.What = evMouseDown) and Event.Double then
  begin
    Pending.What := evCommand;
    Pending.Command := cmOk;
    Event.What := evNothing;
  end
  else if Event.What = evCommand then
  begin
    case Event.Command of
      cmSelectLeftDrive: NewDrive;
      cmSelectRightDrive: DirHistory;
      cmReRead: ReRead;
      else Exit;
    end;
    Event.What := evNothing;
  end
  else TListViewer.HandleEvent(Event);
end;

procedure TTreeViewer.SetData(var Rec);
var
  S: FNameStr;
begin
  Tree := New(PTreeCollection, Init(32, 16));
  S := ClearedSlash(lFExpand(PString(@Rec)^));
  PString(@Rec)^ := '';
  if not DirPresent(S) then GetCurDir(Byte(S[1]) - $40, S);
  NewTree(RootName(S), Tree);
  NewLabelText(Text, S);
  SetRange(Tree^.Count);
  FocusItem(Tree^.GetDirNum(S, 0, Focused));
end;

procedure TTreeViewer.NewDrive;
var
  Ch: Char;
  S: FNameStr;
begin
  SelectDriveDialog('Select new ~Tree~ drive:', 2, GetCurDrive, S);
  if S = '' then Exit;
  NewTree(RootName(S), Tree);
  NewLabelText(Text, S);
  SetRange(Tree^.Count);
  TopItem := 0;
  if S[1] = '\' then FocusItem(0)
  else
  begin
    GetCurDir(Byte(S[1]) - $40, S);
    FocusItem(Tree^.GetDirNum(S, 0, Focused));
  end;
  Select;
  DrawView;
end;

procedure TTreeViewer.ReRead;
var
  S: FNameStr;
begin
  S := Tree^.GetDirStr(Focused);
  EraseTreeInfo(RootName(S));
  NewTree(RootName(S), Tree);
  NewLabelText(Text, RootName(S));
  SetRange(Tree^.Count);
  FocusItem(Tree^.GetDirNum(S, 0, Focused));
  Select;
  DrawView;
end;

procedure TTreeViewer.DirHistory;
var
  I: Integer;
  S: String;
begin
  GetDirHistStr(S, 'Directory history', True, True);
  if S <> '' then
  begin
    if S[Length(S)] = #255 then
    begin
      Dec(S[0], 3);
      S := ClearedSlash(JustPathName(S));
    end;
    if CompUCString(
      RootName(S), RootName(Tree^.GetDirStr(Focused))) <> Equal then
	NewTree(RootName(S), Tree);
    NewLabelText(Text, RootName(S));
    SetRange(Tree^.Count);
    FocusItem(Tree^.GetDirNum(S, 0, Focused));
    Select;
    DrawView;
  end;
end;

procedure TTreeViewer.ChangeTreeLevel(Grow, SetCur: Boolean);
var
  B: Byte;
  P: PTreeRec;
  S: FNameStr;
begin
  if (Grow and (Tree^.BranchLevel = Tree^.MaxBranchLevel)) or
     (not Grow and (Tree^.BranchLevel = 0)) then Exit;
  if SetCur then
  begin
    P := Tree^.At(Focused);
    B := P^.Info and $7F;
    if B = Tree^.BranchLevel then Exit;
  end
  else if GetShiftState and kbCtrlShift <> 0 then
    if Grow then B := Tree^.MaxBranchLevel else B := 0
  else
  begin
    B := Tree^.BranchLevel;
    if Grow then Inc(B) else Dec(B);
  end;
  S := Tree^.GetDirStr(Focused);
  if not SetTreeBranchLevel(RootName(S), B) then Exit;
  NewTree(RootName(S), Tree);
  SetRange(Tree^.Count);
  FocusItem(Tree^.GetDirNum(S, 0, Focused));
  Select;
  DrawView;
end;

procedure TTreeViewer.Paste;
var
  I, N: Integer;
  E: TEvent;
  S: String;
begin
  if (DiskClipStream = nil) or not ClipAreaSelected then Exit;
  Select;
  GetClipLine(ClipArea^.KB, S);
  for I := 1 to Length(S) do
  begin
    E.What := evKeyDown;
    E.CharCode := S[I];
    N := SearchPos;
    HandleEvent(E);
    if N = SearchPos then Exit;
  end;
end;

procedure TTreeInfoPane.Draw;
var
  Color: Word;
  B: TDrawBuffer;
begin
  Color := GetColor(1);
  MoveChar(B, ' ', Color, Size.X);
  MoveStr(B[1], Dir, Color);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TTreeInfoPane.GetPalette: PPalette;
const
  P: String[1] = #30;
begin
  GetPalette := @P;
end;

procedure TTreeInfoPane.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  if (Event.What = evBroadcast) and
     (Event.Command = cmListItemSelected) then
  begin
    if Event.InfoPtr = nil then Dir := ''
    else Dir := TrimmedName(PString(Event.InfoPtr)^, Size.X - 2);
    if Length(Dir) = 2 then
    begin
      Inc(Dir[0]);
      Dir[Length(Dir)] := '\';
    end;
    DrawView;
  end;
end;

procedure TreeDialog(var S: FNameStr);
var
  R: TRect;
  D: PDialog;
  VBar, HBar: PScrollBar;
  Control: PView;
begin
  R.Assign(0, 0, 71, ScreenHeight - 4);
  D := New(PDialog, Init(R, 'Tree'));
  with D^ do
  begin
    Options := Options or ofCentered;
    GrowMode := GrowMode + gfGrowHiY;
    HelpCtx := hcTreeDialog;

    R.Assign(2, Size.Y - 4, Size.X - 15, Size.Y - 3);
    HBar := New(PScrollBar, Init(R));
    HBar^.Options := HBar^.Options or ofPostProcess;
    HBar^.SetRange(0, Size.X);

    R.Assign(Size.X - 15, 2, Size.X - 14, Size.Y - 4);
    VBar := New(PScrollBar, Init(R));
    VBar^.Options := VBar^.Options or ofPostProcess;

    R.Assign(2, 2, Size.X - 15, Size.Y - 4);
    Control := New(PTreeViewer, Init(R, 1, HBar, VBar));
    Control^.Options := Control^.Options or ofPostProcess;
    Control^.GrowMode := gfGrowHiY;
    Insert(Control);
    R.Assign(1, 1, Size.X - 14, 2);
    PTreeViewer(Control)^.Text := New(PLabel, Init(R, '', Control));
    Insert(PTreeViewer(Control)^.Text);
    Insert(HBar);
    Insert(VBar);

    R.Assign(1, Size.Y - 2, Size.X - 1, Size.Y - 1);
    Control := New(PTreeInfoPane, Init(R));
    Control^.GrowMode := gfGrowLoY + gfGrowHiY;
    Control^.EventMask := Control^.EventMask or evBroadcast;
    Insert(Control);

    R.Assign(Size.X - 13, 2, Size.X - 2, 4);
    StandardOkButton(R, D);
    Inc(R.A.Y, 3); Inc(R.B.Y, 3);
    Insert(New(PButton, Init(R, '~D~rive', cmSelectLeftDrive, bfNormal)));
    Inc(R.A.Y, 3); Inc(R.B.Y, 3);
    Insert(New(PButton, Init(R, '~H~istory', cmSelectRightDrive, bfNormal)));
    Inc(R.A.Y, 3); Inc(R.B.Y, 3);
    Insert(New(PButton, Init(R, '~R~escan', cmReRead, bfNormal)));
    Inc(R.A.Y, 3); Inc(R.B.Y, 3);
    StandardCancelButton(R, D);
    Inc(R.A.Y, 3); Inc(R.B.Y, 3);
    StandardHelpButton(R, D);
    SelectNext(False);
  end;
  Application^.ExecuteDialog(D, @S, True);
end;

procedure SearchDirDialog(var S: FNameStr);
var
  B: Byte;
  C: Char;
  I: Integer;
  L: PStringsCollection;
  P: PTreeRec;
  T: PTreeCollection;
  H: PHistoryRec;
  W: PHistoryWindow;
  R: TRect;
  Drives: TDrivesArray;
  Name, SS: FNameStr;
begin
  Name := JustFileName(ClearedSlash(S));
  if (Name = '') or (FMOptions and foNoAutoUpdateTree <> 0) or
     (IsWild(Name) and OnlyWildChars(Name)) then
  begin
    TreeDialog(S);
    Exit;
  end;

  L := New(PStringsCollection, Init(8, 8));
  GetDrives(B, Drives);
  for C	:= 'A' to 'Z' do
    if Drives[C] = 1 then
    begin
      FailSysErrors := True;
      LoadTree(C + ':\', T);
      FailSysErrors := False;
      if T = nil then Continue;
      for I := 1 to T^.Count - 1 do
      begin
	P := T^.At(I);
	TreeAddNameExt('', P, SS, False);
	if WildCardMatch(SS, Name) then
{          L^.Insert(NewStr(T^.GetDirStr(I));}
	  L^.Insert(NewStrUMB(T^.GetDirStr(I)));
      end;
      Dispose(T, Done);
    end;

  if L^.Count = 0 then
  begin
    Dispose(L, Done);
    TreeDialog(S);
    Exit;
  end;

  if L^.Count = 1 then
  begin
    S := PString(L^.At(0))^;
    Dispose(L, Done);
    Exit;
  end;

  for I := L^.Count - 1 downto 0 do
  begin
{
    GetMem(H, SizeOf(THistoryRec));
    H^.StrPtr := NewStr(PString(L^.At(I))^);
}
    GetMemUMB(H, SizeOf(THistoryRec));
    H^.StrPtr := NewStrUMB(PString(L^.At(I))^);
    H^.Id := SearchDirHistoryID;
    if I < 9 then Byte(H^.Lock) := I + $31
    else H^.Lock := False;
    HistoryList^.Insert(H);
  end;
  Dispose(L, Done);

  S := '';
  SS := 'Select a directory to change to';
  GetHistWinBounds(SearchDirHistoryID, SS, R);
  W := New(PSpecialHistWindow, Init(R, SearchDirHistoryID));
  DisposeStr(W^.Title);
  W^.Title := NewStr(SS);
  W^.Options := W^.Options or ofCentered;
  W^.HelpCtx := hcSearchDirHistory;
  if Application^.ValidView(W) <> nil then
  begin
    if Desktop^.ExecView(W) = cmOk then
      S := HistoryStr(SearchDirHistoryID, W^.Viewer^.Focused);
    Dispose(W, Done);
  end;
  ClearHistoryId(SearchDirHistoryID);
end;

end.
