{$F+,I-,O+,X+}
unit FMArcDlg;

interface

uses Objects, Drivers, Views, Dialogs, ArcDlg;

const
  MaxIndex = 32;

type
  PArcCopyList = ^TArcCopyList;
  TArcCopyList = object(TListViewer)
    MoveToggled: Boolean;
    CopyDirs, ListNeeded, MoveFiles: ^Boolean;
    ListChar: ^Char;
    Indexes: Array[0..MaxIndex - 1] of Byte;
    ArchiveList: PArchiveList;
    UserArchiveList: PUserArchiveList;
    constructor Init(var Bounds: TRect; AScrollBar: PScrollBar);
    destructor Done; virtual;
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function GetArcRecPtr(Item: Integer): Pointer;
    procedure FillLists;
    procedure ReloadLists;
    function ModifyUserItem: Word;
    procedure FocusLastItem;
  end;

  PArcCopyDialog = ^TArcCopyDialog;
  TArcCopyDialog = object(TDialog)
    Caller: Pointer;
    DestInput: PInputLine;
    FilterInput: PInputLine;
    PathInput: PInputLine;
    ParamsInput: PInputLine;
    PrefixInput: PInputLine;
    PasswordInput: PInputLine;
    ExtInput: PInputLine;
    ArchiveList: PArcCopyList;
    OptionCheck: PCheckBoxes;
    MoveCheck: PCheckBoxes;
    EmptyCheck: PCheckBoxes;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure CopyToArcDlg(FManager: Pointer; Dest: PString);

implementation

uses Dos, App, ArcRec, ArcV, Archives, FileMngr, FMAction,
  PanelRec, TreeDlg, DirPrim, DiskPrim, RevPos, CRC32, History,
  UnixMask, HeapUMB, TPString, Consts, Commands, Defaults;

constructor TArcCopyList.Init(var Bounds: TRect; AScrollBar: PScrollBar);
begin
  Inherited Init(Bounds, 1, nil, AScrollBar);
  ArchiveList := New(PArchiveList, Init(10, 10));
  UserArchiveList := New(PUserArchiveList, Init(8, 8));
end;

destructor TArcCopyList.Done;
begin
  if Owner^.EndState = cmOk then ArcCopyCRC :=
    GetStringCRC32(GetText(Focused, 255));
  Dispose(UserArchiveList, Done);
  Dispose(ArchiveList, Done);
  Inherited Done;
end;

function TArcCopyList.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: PUserArchiveRec;
begin
  if Item < ArchiveList^.Count then GetText :=
    DelChar('~', ArchiveTradeMark(Indexes[Item]))
  else
  begin
    P := UserArchiveList^.At(Item - ArchiveList^.Count);
    if (P = nil) or (P^.TradeMark = nil) then GetText := ''
    else GetText := P^.TradeMark^;
  end;
end;

procedure ChangeInputData(I: PInputLine; P: PString);
var
  S: String;
begin
  if P = nil then S := '' else S := P^;
  I^.SetData(S);
end;

procedure TArcCopyList.FocusItem(Item: Integer);
var
  CanMove: Boolean;
  P: PArchiveRec;
  PS: PString;
begin
  Inherited FocusItem(Item);
  P := GetArcRecPtr(Focused);
  if P <> nil then with PArcCopyDialog(Owner)^ do
  begin
    CanMove :=
      (not CopyDirs^ and (P^.Move <> nil)) or
      (CopyDirs^ and (P^.MoveWithDirs <> nil));
    MoveCheck^.SetButtonState(1, CanMove);
    MoveCheck^.DrawView;
    MoveFiles^ := CanMove and (MoveCheck^.Value <> 0);
    if MoveFiles^ then
      if CopyDirs^ then PS := P^.MoveWithDirs
      else PS := P^.Move
    else
      if CopyDirs^ then PS := P^.AddWithDirs
      else PS := P^.Add;
    ChangeInputData(ParamsInput, PS);
    if not MoveToggled then
    begin
      ChangeInputData(PathInput, P^.PackerName);
      ChangeInputData(PrefixInput, P^.Password);
      ChangeInputData(ExtInput, P^.Extension);
      OptionCheck^.Value := P^.Main;
      OptionCheck^.DrawView;
      ListChar^ := P^.ListChar;
    end;
  end;
end;

procedure TArcCopyList.HandleEvent(var Event: TEvent);
begin
  Inherited HandleEvent(Event);
  if ((Event.What = evKeyDown) and
      (Event.KeyCode = kbCtrlEnter)) or
     ((Event.What = evBroadcast) and
      (Event.Command = cmListItemSelected)) then
  begin
    if ((Focused < ArchiveList^.Count) and
	(ArchiverDialog(ConfigPath + ArchiverName,
	  Indexes[Focused] - 1) <> cmCancel)) or
       ((Focused >= ArchiveList^.Count) and
	(ModifyUserItem <> cmCancel)) then ReloadLists;
    Event.What := evNothing;
  end;
end;

function TArcCopyList.GetArcRecPtr(Item: Integer): Pointer;
var
  P: Pointer;
begin
  if Item < ArchiveList^.Count then
    P := ArchiveList^.At(Item)
  else
  begin
    P := UserArchiveList^.At(Item - ArchiveList^.Count);
    if P <> nil then P := PUserArchiveRec(P)^.ArchiveRec;
  end;
  GetArcRecPtr := P;
end;

procedure TArcCopyList.FillLists;
var
  A, C: Byte;
  P: PArchiveRec;
  Q: PUserArchiveRec;
  S: TDosStream;

procedure MoveItemUp(FromIndex, ToIndex: Integer);
begin
  if (FromIndex >= 0) and (ToIndex >= 0) and (ToIndex < FromIndex) then
  begin
    with ArchiveList^ do
    begin
      P := At(FromIndex);
      AtDelete(FromIndex);
      AtInsert(ToIndex, P);
    end;
    A := Indexes[FromIndex];
    Move(Indexes[ToIndex], Indexes[ToIndex + 1], FromIndex - ToIndex);
    Indexes[ToIndex] := A;
  end;
end;

procedure FindIndexes(ArcIndex, ArWIndex: Integer;
  var FromIndex, ToIndex: Integer);
var
  I: Integer;
begin
  FromIndex := -1;
  ToIndex := -1;
  for I := 0 to C - 1 do
    if Indexes[I] = ArcIndex then ToIndex := I
    else if Indexes[I] = ArWIndex then FromIndex := I;
end;

procedure RearrangeItems;
var
  FromIndex, ToIndex: Integer;
begin
  FindIndexes(avNo, avArj, FromIndex, ToIndex);
  MoveItemUp(FromIndex, 0);
  FindIndexes(avNo, avRar, FromIndex, ToIndex);
  MoveItemUp(FromIndex, 0);
  FindIndexes(avNo, avZip, FromIndex, ToIndex);
  MoveItemUp(FromIndex, 0);

  FindIndexes(avZip, avZiW, FromIndex, ToIndex);
  MoveItemUp(FromIndex, ToIndex);
  FindIndexes(avArj, avArW, FromIndex, ToIndex);
  MoveItemUp(FromIndex, ToIndex);
  FindIndexes(avRar, avRaW, FromIndex, ToIndex);
  MoveItemUp(FromIndex, ToIndex);
end;

begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Reading the archiver setup files.');

  S.Init(ConfigPath + ArchiverName, stOpenRead);
  A := avZip;
  C := 0;
  repeat
    P := NewArchiveRec;
    ReadArchiveRec(@S, P);
    if S.Status <> stOk then
    begin
      DisposeArchiveRec(P);
      Break;
    end;
    if (P^.PackerName = nil) or
       (not CopyDirs^ and (P^.Add = nil)) or
       (CopyDirs^ and (P^.AddWithDirs = nil)) or
       (ListNeeded^ and (P^.ListChar = #0)) then
      DisposeArchiveRec(P)
    else
    begin
      ArchiveList^.Insert(P);
      Indexes[C] := A;
      Inc(C);
    end;
    Inc(A);
  until (A >= avUsr) or (C >= MaxIndex);
  S.Done;
  RearrangeItems;

  S.Init(ConfigPath + UserArchiverName, stOpenRead);
  repeat
    Q := NewUserArchiveRec;
    ReadUserArchiveRec(@S, Q);
    if S.Status <> stOk then
    begin
      DisposeUserArchiveRec(Q);
      Break;
    end;
    if not UserArchiveEnabled(Q) or (Q^.ArchiveRec^.PackerName = nil) or
       (not CopyDirs^ and (Q^.ArchiveRec^.Add = nil)) or
       (CopyDirs^ and (Q^.ArchiveRec^.AddWithDirs = nil)) or
       (ListNeeded^ and (Q^.ArchiveRec^.ListChar = #0)) then
      DisposeUserArchiveRec(Q)
    else UserArchiveList^.Insert(Q);
  until False;
  S.Done;

  SetRange(ArchiveList^.Count + UserArchiveList^.Count);
end;

procedure TArcCopyList.ReloadLists;
begin
  UserArchiveList^.FreeAll;
  ArchiveList^.FreeAll;
  FillLists;
  FocusItem(Focused);
  DrawView;
end;

function TArcCopyList.ModifyUserItem: Word;
var
  I: Integer;
  P, Q: PUserArchiveRec;
  D: PUserArchiveDialog;
begin
  ModifyUserItem := cmCancel;
  P := UserArchiveList^.At(Focused - ArchiveList^.Count);
  if (P = nil) or (P^.TradeMark = nil) then Exit;
  D := New(PUserArchiveDialog, Init(ConfigPath + UserArchiverName));
  for I := 0 to D^.UserArchiveViewer^.List^.Count - 1 do
  begin
    Q := D^.UserArchiveViewer^.List^.At(I);
    if (Q <> nil) and (Q^.TradeMark <> nil) and
       (Q^.TradeMark^ = P^.TradeMark^) then
    begin
      D^.UserArchiveViewer^.FocusItem(I);
      if D^.UserArchiveViewer^.ModifyItem then
      begin
	ModifyUserItem := cmOk;
	Break;
      end;
    end;
  end;
  Dispose(D, Done);
end;

procedure TArcCopyList.FocusLastItem;
var
  I: Integer;
begin
  for I := 0 to Range - 1 do
    if GetStringCRC32(GetText(I, 255)) = ArcCopyCRC then
    begin
      FocusItem(I);
      Exit;
    end;
  FocusItem(0);
end;

procedure TArcCopyDialog.HandleEvent(var Event: TEvent);
var
  W: Word;
  S: FNameStr;
begin
  W := MoveCheck^.Value;
  if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
    with ArchiveList^ do
  begin
    Options := Options and not ofPostProcess;
    VScrollBar^.Options := VScrollBar^.Options and not ofPostProcess;
  end;
  Inherited HandleEvent(Event);
  with ArchiveList^ do
  begin
    Options := Options or ofPostProcess;
    VScrollBar^.Options := VScrollBar^.Options or ofPostProcess;
    if MoveCheck^.Value <> W then
    begin
      MoveToggled := True;
      FocusItem(Focused);
      MoveToggled := False;
    end;
  end;
  if Event.What = evCommand then
    if Event.Command = cmUpdateViews then
    begin
      ArchiveList^.FocusLastItem;
      Event.What := evNothing;
    end
    else if Event.Command = cmTree then
    begin
      DestInput^.GetData(S);
      TreeDialog(S);
      if S <> '' then
      begin
	S := AddedSlash(S);
	DestInput^.SetData(S);
	DestInput^.Select;
      end;
      Event.What := evNothing;
    end;
end;

function NeedList(FManager: PPanel): Boolean;
var
  SR: PPanelRec;
begin
  NeedList := True;
  with FManager^ do
    if (SelCount = 0) or (Settings and seIgnoreSelection <> 0) then
    begin
      SR := List^.At(Focused);
      if (SR^.Attr and Directory = 0) or
	 ((SR^.Name[1] = '.') and (Settings and seUnfold = 0) and
	  (CRCList = nil)) then NeedList := False;
    end;
end;

procedure SetDialogHeaderStr(FManager: PPanel; var S: TTitleStr);
var
  L: Longint;
  SR: PPanelRec;
  SS: String;
begin
  with FManager^ do
  begin
    if (SelCount <> 0) and (Settings and seIgnoreSelection = 0) then
    begin
      L := SelCount;
      if Options and ofValidate <> 0 then
	SS := 'the contents of %d selected drives'
      else SS := '%d selected files';
      if L = 1 then Dec(SS[0]);
      FormatStr(S, SS, L);
    end
    else
    begin
      SR := List^.At(Focused);
      if SR^.Name[1] = ':' then SS := RootName(ListDir^)
      else if SR^.Name[1] = '\' then GetRecStr(SR, SS)
      else AddNameExt('', SR, SS);
      if SR^.Attr and Directory = 0 then
	S := 'the file "' + TrimmedName(SS, 31) + '"'
      else
      begin
	if SS[1] = '\' then S := 'network resource'
	else if (SS[0] = #2) and (SS[2] = ':') then S := 'drive ' + SS
	else if SS[1] = '.' then S := 'current directory'
	else
	begin
	  S := 'the directory "' + TrimmedName(SS, 31) + '"';
	  Exit;
	end;
	S := 'the contents of the ' + S;
      end;
    end;
  end;
end;

procedure SetDefaultDestName(FManager: PPanel; var S: FNameStr);
var
  I: Integer;
  SS: FNameStr;
begin
  with FManager^ do
  begin
    if (SelCount <> 0) and (Settings and seIgnoreSelection = 0) then
    begin
      if SelCount = 1 then for I := 0 to List^.Count - 1 do
      begin
	S := '';
	if PPanelRec(List^.At(I))^.Selected then
	begin
	  GetItemStr(I, S);
	  Break;
	end;
      end
      else GetListDir(S);
    end
    else GetItemStr(Focused, S);
    S := JustName(S);

    if GetShiftState and (kbLeftShift + kbRightShift) =
      kbLeftShift + kbRightShift then
    begin
      Opposite^.GetListDir(SS);
      S := AddedSlash(SS) + S;
    end;
  end;
end;

procedure CopyToArcDlg(FManager: Pointer; Dest: PString);
type
  PArcCopyData = ^TArcCopyData;
  TArcCopyData = record
    Dest: String[255];
    Filter: String[12];
    Path: String[255];
    Params: String[255];
    Prefix: String[255];
    Password: String[255];
    Extension: String[3];
    Options: Word;
    MoveFiles: Word;
    EmptyDirs: Word;
  end;
const
  ArcMoveFiles: Byte = 0;
  ArcEmptyDirs: Byte = 0;
var
  CopyDirs, ListNeeded, MoveFiles, ShowEmptyCheck: Boolean;
  ListChar: Char;
  I: Integer;
  D: PArcCopyDialog;
  VBar: PScrollBar;
  H: PHistory;
  P: PArchiveRec;
  R: TRect;
  Data: PArcCopyData;
  Dst, S: String;
begin
  if Dest <> nil then
  begin
    Dst := Dest^;
    DisposeStr(Dest);
    if (Dst <> '') and (Dst[Length(Dst)] = #0) then
    begin
      Dec(Dst[0]);
      ArcMoveFiles := 1;
    end
    else ArcMoveFiles := 0;
  end
  else Dst := '';
  with PPanel(FManager)^ do
    if InArchive or (Status >= stInfo) or (List^.Count = 0) then Exit;

  CopyDirs := AreDirs(PPanel(FManager), False);
  ListNeeded := NeedList(PPanel(FManager));
  ShowEmptyCheck := CopyDirs and (PPanel(FManager)^.SelDirCount <> 0);
  SetDialogHeaderStr(PPanel(FManager), S);

  R.Assign(0, 0, 80, 23);
  D := New(PArcCopyDialog, Init(R, 'Copy/move ' + S + ' to archive'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcArcCopyDlg;
    Caller := FManager;

    R.Assign(16, 2, Size.X - 6 - 26 * Byte(CopyDirs), 3);
    DestInput := New(PInputLine, Init(R, 255));
    Insert(DestInput);
    StandardHistory(DestInput, FNameHistoryId);
    R.Assign(2, 2, 16, 3);
    Insert(New(PLabel, Init(R, '~D~estination', DestInput)));

    R.Assign(Size.X - 20, 2, Size.X - 6, 3);
    FilterInput := New(PInputLine, Init(R, 12));
    Insert(FilterInput);
    if CopyDirs then
    begin
      H := StandardHistory(FilterInput, MaskHistoryId);
      H^.HistoryPutFunc := UNIXPutHistoryFunc;
      H^.HistoryGetFunc := UNIXGetHistoryFunc;
      R.Assign(Size.X - 28, 2, Size.X - 20, 3);
      Insert(New(PLabel, Init(R, '~F~ilter', FilterInput)));
    end
    else FilterInput^.Hide;

    R.Assign(16, 4, Size.X - 6, 5);
    PathInput := New(PInputLine, Init(R, 255));
    Insert(PathInput);
    StandardHistory(PathInput, PathHistoryId);
    R.Assign(2, 4, 16, 5);
    Insert(New(PLabel, Init(R, '~P~acker name', PathInput)));

    R.Assign(16, 6, Size.X - 6, 7);
    ParamsInput := New(PInputLine, Init(R, 255));
    Insert(ParamsInput);
    StandardHistory(ParamsInput, ParamsHistoryId);
    R.Assign(2, 6, 16, 7);
    Insert(New(PLabel, Init(R, '~C~ommand line', ParamsInput)));

    R.Assign(36, 9, 37, Size.Y - 2);
    VBar := New(PScrollBar, Init(R));
    VBar^.Options := VBar^.Options or ofPostProcess;
    Insert(VBar);

    R.Assign(3, 9, 36, Size.Y - 2);
    ArchiveList := New(PArcCopyList, Init(R, VBar));
    ArchiveList^.Options := ArchiveList^.Options or ofPostProcess;
    ArchiveList^.CopyDirs := @CopyDirs;
    ArchiveList^.ListNeeded := @ListNeeded;
    ArchiveList^.MoveFiles := @MoveFiles;
    ArchiveList^.ListChar := @ListChar;
    Insert(ArchiveList);
    ArchiveList^.FillLists;
    R.Assign(2, 8, 37, 9);
    Insert(New(PLabel, Init(R, '~A~rchivers', ArchiveList)));

    R.Assign(46, 8, 50, 9);
    PrefixInput := New(PInputLine, Init(R, 255));
    Insert(PrefixInput);
    R.Assign(38, 8, 46, 9);
    Insert(New(PLabel, Init(R, 'Prefi~x~', PrefixInput)));

    R.Assign(61, 8, Size.X - 3, 9);
    PasswordInput := New(PPasswordInput, Init(R, 255));
    Insert(PasswordInput);
    R.Assign(51, 8, 61, 9);
    Insert(New(PLabel, Init(R, 'Pass~w~ord', PasswordInput)));

    R.Assign(61, 9, Size.X - 3, 10);
    ExtInput := New(PInputLine, Init(R, 3));
    Insert(ExtInput);
    ExtInput^.Hide;

    R.Assign(39, 11, Size.X - 3, 16);
    OptionCheck := New(PCheckBoxes, Init(R,
      NewSItem('Swap main ~b~ody',
      NewSItem('~S~witch to user screen',
      NewSItem('Load COMMAND~.~COM',
      NewSItem('Enable Win9~5~ long filenames',
      NewSItem('Prompt on overwrite', nil)))))));
    Insert(OptionCheck);
    R.Assign(38, 10, Size.X - 3, 11);
    Insert(New(PLabel, Init(R, 'Exec options', OptionCheck)));

    R.Assign(39, 18, Size.X - 3 - Byte(ShowEmptyCheck) * 13, 19);
    MoveCheck := New(PCheckBoxes, Init(R,
      NewSItem('D~e~lete source files', nil)));
    Insert(MoveCheck);
    R.Assign(38, 17, Size.X - 3 - Byte(ShowEmptyCheck) * 13, 18);
    Insert(New(PLabel, Init(R, 'Copy or move', MoveCheck)));

    if ShowEmptyCheck then
    begin
      R.Assign(66, 18, Size.X - 3, 19);
      EmptyCheck := New(PCheckBoxes, Init(R,
	NewSItem('Sk~i~p', nil)));
      Insert(EmptyCheck);
      R.Assign(65, 17, Size.X - 3, 18);
      Insert(New(PLabel, Init(R, 'Empty dirs', EmptyCheck)));
    end;

    R.Assign(38, Size.Y - 3, 48, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(48, Size.Y - 3, 58, Size.Y - 1);
    Insert(New(PButton, Init(R, 'T~r~ee', cmTree, bfNormal)));
    R.Assign(58, Size.Y - 3, 68, Size.Y - 1);
    StandardCancelButton(R, D);
    R.Assign(68, Size.Y - 3, 78, Size.Y - 1);
    StandardHelpButton(R, D);

    SelectNext(False);
  end;

  if D^.ArchiveList^.Range = 0 then Dispose(D, Done)
  else
  begin
    GetMem(Data, SizeOf(TArcCopyData));
    FillChar(Data^, SizeOf(TArcCopyData), 0);
    if Dst <> '' then
    begin
      I := Pos(':', Dst);
      Data^.Dest := Copy(Dst, I + 1, 255);
      if I > 2 then
      begin
	Dst[0] := Char(I - 1);
	TrimSt(Dst);
	for I := 0 to D^.ArchiveList^.Range - 1 do
	begin
	  P := D^.ArchiveList^.GetArcRecPtr(I);
	  if (P <> nil) and (P^.Extension <> nil) and
	     (CompUCString(Trim(P^.Extension^), Dst) = Equal) then
	  begin
	    ArcCopyCRC := GetStringCRC32(
	      D^.ArchiveList^.GetText(I, 255));
	    Break;
	  end;
	end;
      end;
    end
    else SetDefaultDestName(PPanel(FManager), Data^.Dest);
    if CopyDirs then
      if PPanel(FManager)^.Filter = '*.*' then
	Data^.Filter := DirFilter
      else Data^.Filter := PPanel(FManager)^.Filter;
    Data^.MoveFiles := ArcMoveFiles;
    Data^.EmptyDirs := ArcEmptyDirs;
    Pending.What := evCommand;
    Pending.Command := cmUpdateViews;
    if Application^.ExecuteDialog(D, Data, False) = cmOk then
    begin
      if Data^.Filter <> '' then DirFilter := Data^.Filter;
      ArcMoveFiles := Data^.MoveFiles;
      ArcEmptyDirs := Data^.EmptyDirs;
      P := NewArchiveRec;

{      P^.PackerName := NewStr(Data^.Path);}
      P^.PackerName := NewStrUMB(Data^.Path);
      S := Data^.Params;
      if (Data^.Prefix <> '') and (Data^.Password <> '') then
	S := S + ' ' + Data^.Prefix + Data^.Password;
{
      if MoveFiles then
	if CopyDirs then P^.MoveWithDirs := NewStr(S)
	else P^.Move := NewStr(S)
      else
	if CopyDirs then P^.AddWithDirs := NewStr(S)
	else P^.Add := NewStr(S);
}
      if MoveFiles then
	if CopyDirs then P^.MoveWithDirs := NewStrUMB(S)
	else P^.Move := NewStrUMB(S)
      else
	if CopyDirs then P^.AddWithDirs := NewStrUMB(S)
	else P^.Add := NewStrUMB(S);
{      P^.Extension := NewStr(Data^.Extension);}
      P^.Extension := NewStrUMB(Data^.Extension);
      P^.ListChar := ListChar;
      P^.Main := Data^.Options;
      if ShowEmptyCheck and (ArcEmptyDirs <> 0) then
	SelListIncludeEmptyDirs := False;
      CopyToArchive(FManager, False, MoveFiles,
	':' + Data^.Dest, Data^.Filter, P);
      SelListIncludeEmptyDirs := True;
    end;
    FreeMem(Data, SizeOf(TArcCopyData));
  end;
end;

end.