{$I-,F+,O+,X+}
unit FMDialog;

interface

uses Objects, Drivers, Views, Dialogs, FileMngr;

type
  PDateInputLine = ^TDateInputLine;
  TDateInputLine = object(TInputLine)
    procedure HandleEvent(var Event: TEvent); virtual;
    function Valid(Command: Word): Boolean; virtual;
  end;

  PTimeInputLine = ^TTimeInputLine;
  TTimeInputLine = object(TInputLine)
    procedure HandleEvent(var Event: TEvent); virtual;
    function Valid(Command: Word): Boolean; virtual;
  end;

  PSizeInputLine = ^TSizeInputLine;
  TSizeInputLine = object(TInputLine)
    function Valid(Command: Word): Boolean; virtual;
  end;

  TAdvancedFilterData = record
    Txt: String[255];
    Unix: Word;
    LoDate: String[8];
    LoTime: String[8];
    HiDate: String[8];
    HiTime: String[8];
    LoSize: String[10];
    HiSize: String[10];
    Attr: Word;
    Lists: Word;
  end;

  PAdvancedFilterDialog = ^TAdvancedFilterDialog;
  TAdvancedFilterDialog = object(TDialog)
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure GetMDY(const D: String; var Month, Day, Year: Word);

procedure SelectDrivePrim(FManager: PPanel; C: Char; CurDir: Boolean);
procedure ChangeTreeLevelPrim(FManager: PPanel; Grow, SetCur: Boolean);
procedure SelectGroupPrim(FManager: PPanel; On: Boolean);
procedure FileAttributesPrim(FManager: PPanel);
procedure FilterDialogPrim(FManager: PPanel);
function AdvancedFilterDlg(const AHeader, AOptions: String): PDialog;
procedure AdvancedFilterDialogPrim(FManager: PPanel);
procedure ReadAdvancedFilterPrim(FManager: PPanel; const Name: FNameStr);
procedure OperationFilterDialog;
procedure SortDialogPrim(FManager: PPanel);
procedure SettingsDialogPrim(FManager: PPanel);
procedure FindFileDlgPrim(FManager: PPanel);
procedure FMSetIndexAndColorPrim(FManager: PPanel);

implementation

uses Dos, Memory, HistList, App, MsgBox, StdDlg, Gauges, PanelRec,
  DirPrim, DiskBase, DiskPrim, FindFile, History, Swaps, ExecPrim,
  FMAbort, FMBars, FMBBS, FMDrvSel, FMGroups, FMSecond, ArcV, ArcRec,
  ArcDlg, Archives, DirTree, Trees, EditMsg, EditFile, UnixMask,
  RevPos, CNInputs, Disks, DosTools, HeapUMB, LFN, Keyboard, TPString,
  Consts, Commands, Defaults;

procedure GetAdvancedFilterName(const AHeader: String;
  var Name: FNameStr);
begin
  Name := HistoryStr(FilterNameHistoryID, 0);
  if Application^.ExecuteDialog(
    New(PFileDialog, Init('*.FLT', AHeader + ' advanced filter',
    '~A~dvanced filter file name', fdOkButton + fdHelpButton,
    FilterNameHistoryID)), @Name, False) = cmCancel then Name := '';
end;

function LoadAdvancedFilter(const Name: FNameStr;
  var Data: TAdvancedFilterData; ADialog: PDialog): Boolean;
var
  F: lFile;
begin
  LoadAdvancedFilter := False;
  lAssignFile(F, Name);
  lResetReadOnly(F, 1);
  if IOResult <> 0 then
  begin
    CouldNotOpenMsgBox(Name);
    Exit;
  end;
  if IsDevice(FileRec(F.F).Handle) then
  begin
    System.Close(F.F);
    InOutRes := 0;
    FileIsDeviceMsgBox(Name);
    Exit;
  end;
  FillChar(Data, SizeOf(TAdvancedFilterData), 0);
  BlockRead(F.F, Data.Txt[0], SizeOf(Char));
  BlockRead(F.F, Data.Txt[1], Byte(Data.Txt[0]));
  BlockRead(F.F, Data.Unix,
    SizeOf(TAdvancedFilterData) - SizeOf(Data.Txt));
  System.Close(F.F);
  InOutRes := 0;
  LoadAdvancedFilter := True;
  if ADialog <> nil then ADialog^.SetData(Data);
end;

procedure StoreAdvancedFilter(const Name: FNameStr;
  var Data: TAdvancedFilterData; ADialog: PDialog);
var
  F: lFile;
begin
  if ADialog <> nil then ADialog^.GetData(Data);
  lAssignFile(F, Name);
  lRewriteFile(F, 1);
  if IOResult <> 0 then
  begin
    CouldNotCreateMsgBox(Name);
    Exit;
  end;
  if NotAccessible(FileRec(F.F).Handle) then
  begin
    System.Close(F.F);
    InOutRes := 0;
    FileIsDeviceMsgBox(Name);
    Exit;
  end;
  BlockWrite(F.F, Data.Txt[0], SizeOf(Char));
  BlockWrite(F.F, Data.Txt[1], Byte(Data.Txt[0]));
  BlockWrite(F.F, Data.Unix,
    SizeOf(TAdvancedFilterData) - SizeOf(Data.Txt));
  System.Close(F.F);
  InOutRes := 0;
  UpdateFiles(Name);
end;

procedure TAdvancedFilterDialog.HandleEvent(var Event: TEvent);
var
  Name: FNameStr;
  Data: TAdvancedFilterData;
begin
  Inherited HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmRetrieveOptions:
        begin
          GetAdvancedFilterName('Load', Name);
          if Name <> '' then LoadAdvancedFilter(Name, Data, @Self);
        end;
      cmSaveOptions:
        begin
          GetAdvancedFilterName('Store', Name);
          if Name <> '' then StoreAdvancedFilter(Name, Data, @Self);
        end;
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

procedure SelectDrivePrim(FManager: PPanel; C: Char; CurDir: Boolean);
var
  ShiftDown: Boolean;
  S: FNameStr;
begin
  with FManager^ do
  begin
    if C = #0 then
    begin
      if Which = pnLeft then S := 'left' else S := 'right';
      SelectDriveDialog('Select ~' + S + '~ drive:', Which, ListDir^[1], S);
      if S = '' then Exit;
    end
    else if C in ['A'..'Z'] then S := C + ':'
    else Exit;
    ShiftDown := GetShiftState and (kbLeftShift + kbRightShift) <> 0;
    LogEvent := lcDiskRead;
    if S[1] = '\' then DrawStatusLine(
      'Trying to access the network resource ' + TrimmedName(S, 29) + '.')
    else DrawStatusLine('Checking the validity of drive ' + S + '.');
    if FMOptions and foDrawEmpty <> 0 then
    begin
      Empty := True;
      PWindow(Owner)^.Frame^.DrawView;
      DrawView;
      Empty := False;
    end;
    if S[1] <> '\' then
      if not CurDir then S := AddedSlash(S)
      else if (Opposite^.Status < stInfo) and
        (Opposite^.ListDir^[1] = S[1]) then S := Opposite^.ListDir^
      else if ListDir^[1] = S[1] then S := ListDir^
      else GetCurDir(Byte(S[1]) - $40, S);
    SwitchToDir(S, True);
    if State and sfVisible = 0 then
      TogglePanelPrim(PPanelWindow(Owner), FManager, tmByF);
    if ShiftDown then Select;
  end;
end;

procedure ChangeTreeLevelPrim(FManager: PPanel; Grow, SetCur: Boolean);
var
  B: Byte;
  I: Integer;
  SaveOpt: Longint;
  P: PTreeRec;
  S: FNameStr;
begin
  with FManager^ do
  begin
    if InArchive or (Settings and seList <> 0) or
      (Grow and (TheTree^.BranchLevel = TheTree^.MaxBranchLevel)) or
      (not Grow and (TheTree^.BranchLevel = 0)) then Exit;
    if SetCur then
    begin
      P := TheTree^.At(Focused);
      B := P^.Info and $7F;
      if B = TheTree^.BranchLevel then Exit;
    end
    else if GetShiftState and kbCtrlShift <> 0 then
      if Grow then B := TheTree^.MaxBranchLevel else B := 0
    else
    begin
      B := TheTree^.BranchLevel;
      if Grow then Inc(B) else Dec(B);
    end;
    if not SetTreeBranchLevel(RootName(ListDir^), B) then Exit;
    GetItemStr(Focused, S);
    SaveOpt := FMOptions;
    FMOptions := FMOptions and not foDrawEmpty;
    NewDir(ListDir^, True);
    FMOptions := SaveOpt;
    GetItemNum(S, I);
    FocusItem(I);
  end;
end;

procedure SelectGroupPrim(FManager: PPanel; On: Boolean);
type
  TSelData = record
    SelMask: FNameStr;
    UnixFlag: Word;
  end;
var
  All, ShiftDown, SingleShift, Found,
  RestoreUnixFlag, SaveUnixFlag: Boolean;
  KeyState, PipePos: Byte;
  C: Word;
  LoX, HiX: Integer;
  D: PDialog;
  Control: PView;
  H: PHistory;
  SR: PPanelRec;
  R: TRect;
  SelData: TSelData;
  S, Dir, Name, Ext: FNameStr;
  AHeader: String;
  States: TState;

procedure DoFindMatch(P: PPanelRec); far;
begin
  if All and not (P^.Name[1] in [':', '.']) then
  begin
    Found := True;
    FManager^.SetSelect(P, On);
    Exit;
  end;
  if SingleShift then
  begin
    if (P^.Attr and Directory = 0) and (P^.Color = SR^.Color) then
    begin
      Found := True;
      FManager^.SetSelect(P, On);
    end;
    Exit;
  end;
  AddNameExt('', P, Name);
  if not (P^.Name[1] in [':', '.']) and
    (((P^.Attr and Directory <> 0) and ShiftDown) or
     ((P^.Attr and Directory =  0) and not ShiftDown)) and
    ((UnixFlag and IsAcceptable(Name, States)) or
     (not UnixFlag and NameMatchesMultiMask(
       Name, SelData.SelMask, PipePos))) then
  begin
    Found := True;
    FManager^.SetSelect(P, On);
  end;
end;

label
  DoIt;
begin
  with FManager^ do
  begin
    if (State and sfVisible = 0) or (List^.Count = 0) or
       (Status > stTree) then Exit;
    if Status = stTree then
    begin
      ChangeTreeLevelPrim(FManager, On, False);
      Exit;
    end;
    All := False;
    KeyState := GetShiftState;
    ShiftDown := KeyState and (kbLeftShift + kbRightShift) <> 0;
    SingleShift := ShiftDown and
      (KeyState and (kbAltShift + kbCtrlShift) = 0) and
      (PPanelRec(List^.At(Focused))^.Attr and Directory = 0);
    if SingleShift or
      (KeyState and (kbAltShift + kbCtrlShift) <> 0) then
    begin
      SR := List^.At(Focused);
      if SR^.Attr and Directory <> 0 then
        if SR^.Name[1] in [':', '.'] then All := True
        else ShiftDown := True;
      if SingleShift or
        (KeyState and (kbAltShift + kbCtrlShift) =
          (kbAltShift + kbCtrlShift)) then SelData.SelMask := '*.*'
      else
      begin
        AddNameExt('', SR, S);
        lFSplit(S, Dir, Name, Ext);
        if Ext <> '' then System.Delete(Ext, 1, 1);
        if KeyState and kbAltShift <> 0 then
          SelData.SelMask := Name + '.*'
        else SelData.SelMask := '*.' + Ext;
      end;
      SaveUnixFlag := UnixFlag;
      UnixFlag := False;
      RestoreUnixFlag := True;
      Goto DoIt;
    end;
    if On then AHeader := 'Select group'
    else AHeader := 'Unselect group';
    if Which = pnLeft then
    begin
      LoX := 5;
      HiX := LoX + 28;
    end
    else
    begin
      HiX := ScreenWidth - 5;
      LoX := HiX - 28;
    end;
    R.Assign(LoX, 0, HiX, 9);
    if On then C := hcSelectGroup
    else C := hcUnselectGroup;
    D := InitSimpleDialog(R, AHeader, C);
    with D^ do
    begin
      Options := Options or ofCenterY;
      R.Assign(8, 2, 22, 3);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      H := StandardHistory(Control, MaskHistoryId);
      H^.HistoryPutFunc := UNIXPutHistoryFunc;
      H^.HistoryGetFunc := UNIXGetHistoryFunc;
      R.Assign(2, 2, 8, 3);
      Insert(New(PLabel, Init(R, '~M~ask', Control)));
      R.Assign(3, 4, 25, 5);
      Insert(New(PCheckBoxes, Init(R,
        NewSItem('~U~NIX style mask', nil))));
      Control^.Select;
    end;
    SelData.SelMask := HistoryStr(MaskHistoryID, 0);
    if SelData.SelMask = '' then
      if UnixFlag then SelData.SelMask := '*'
      else SelData.SelMask := '*.*';
    SelData.UnixFlag := Byte(UnixFlag);
    if (Application^.ExecuteDialog(D, @SelData, False) = cmCancel) or
       (SelData.SelMask = '') then Exit;
    UnixFlag := SelData.UnixFlag <> 0;
    RestoreUnixFlag := False;
    ShiftDown := GetShiftState and (kbLeftShift + kbRightShift) <> 0;
DoIt:
    DrawSelGroupStatus(SelData.SelMask);
    if UnixFlag then MakeAutomaton(SelData.SelMask, States);
    PipePos := Pos('|', SelData.SelMask);
    Found := False;
    List^.ForEach(@DoFindMatch);
    if RestoreUnixFlag then UnixFlag := SaveUnixFlag;
    if Found then FocusItem(Focused)
    else
    begin
      if ShiftDown then AHeader := 'dirs'
      else AHeader := 'files';
      MessageBox(^C'No ' + AHeader +
        ' match the specified mask:'#13#13^C'"' +
        System.Copy(SelData.SelMask, 1, 32) + '".',
	nil, mfError + mfOkButton + mfNoAdjust);
    end;
  end;
end;

function GetDateStr(D: Longint): String;
var
  Time: DateTime;
begin
  UnpackTime(D, Time);
  with Time do GetDateStr := FormatDateStr(Year, Month, Day);
end;

function GetTimeStr(D: Longint): String;
var
  B: Byte;
  Time: DateTime;
  SS: String;
begin
  UnpackTime(D, Time);
  B := CountryTime;
  CountryTime := cs24Hour;
  with Time do SS := FormatTimeStr(Hour, Min, Sec);
  CountryTime := B;
  GetTimeStr := SS;
end;

procedure SetBadValues(var Month, Day, Year: Word);
begin
  Month := $FFFF;
  Day := $FFFF;
  Year := $FFFF;
end;

procedure GetValue(var SS: String; Separator: Char;
  var V: Word; var Code: Integer);
var
  B: Byte;
begin
  B := 1;
  while (B <= Length(SS)) and (SS[B] <> Separator) do Inc(B);
  Val(System.Copy(SS, 1, B - 1), V, Code);
  System.Delete(SS, 1, B);
end;

procedure GetMDY(const D: String; var Month, Day, Year: Word);
var
  Code: Integer;
  SS: String;

function GetYear: Boolean;
begin
  GetValue(SS, DateSeparator, Year, Code);
  GetYear := Code = 0;
end;

function GetMonth: Boolean;
begin
  GetValue(SS, DateSeparator, Month, Code);
  GetMonth := (Month >= 1) and (Month <= 12);
end;

function GetDay: Boolean;
begin
  GetValue(SS, DateSeparator, Day, Code);
  GetDay := (Day >= 1) and (Day <= 31);
end;

begin
  SS := Trim(D);
  SetBadValues(Month, Day, Year);
  case CountryDate of
    csMMDDYY:
      begin
        if not GetMonth or not GetDay then Exit;
        if not GetYear then
        begin
          SetBadValues(Month, Day, Year);
          Exit;
        end;
      end;
    csDDMMYY:
      begin
        if not GetDay or not GetMonth then Exit;
        if not GetYear then
        begin
          SetBadValues(Month, Day, Year);
          Exit;
        end;
      end;
    csYYMMDD:
      begin
        if not GetYear or not GetMonth then Exit;
        if not GetDay then
        begin
          SetBadValues(Month, Day, Year);
          Exit;
        end;
      end;
    else
      begin
        if not GetYear or not GetDay then Exit;
        if not GetMonth then
        begin
          SetBadValues(Month, Day, Year);
          Exit;
        end;
      end;
  end;
  if Year < 80 then Inc(Year, 2000)
  else if Year < 100 then Inc(Year, 1900);
end;

procedure GetHMS(const T: String; var Hour, Min, Sec: Word);
var
  Code: Integer;
  SS: String;
begin
  SS := Trim(T);
  Hour := $FFFF;
  Min := $FFFF;
  Sec := 0;
  GetValue(SS, TimeSeparator, Hour, Code);
  if (Code <> 0) or (Hour > 23) then Exit;
  GetValue(SS, TimeSeparator, Min, Code);
  if (Code <> 0) or (Min > 59) then
  begin
    Hour := $FFFF;
    Min := $FFFF;
    Exit;
  end;
  GetValue(SS, TimeSeparator, Sec, Code);
end;

procedure TDateInputLine.HandleEvent(var Event: TEvent);
var
  Y, M, D, W: Word;
  T: String[15];
begin
  if (Event.What = evKeyDown) and
     ((Event.KeyCode = kbAltIns) or (Event.KeyCode = kbAltColon)) then
  begin
    GetDate(Y, M, D, W);
    T := FormatDateStr(Y, M, D);
    SetData(T);
    Event.What := evNothing;
  end;
  Inherited HandleEvent(Event);
end;

function TDateInputLine.Valid(Command: Word): Boolean;
var
  Time: DateTime;
begin
  if (Command = cmOk) and (Trim(Data^) <> '') then
  begin
    GetMDY(Data^, Time.Month, Time.Day, Time.Year);
    if (Time.Month = $FFFF) or
       (Time.Day = $FFFF) or
       (Time.Year = $FFFF) then
    begin
      Select;
      InvalidInputMsgBox(Data^, 'date');
      Valid := False;
      Exit;
    end;
  end;
  Valid := TInputLine.Valid(Command);
end;

procedure TTimeInputLine.HandleEvent(var Event: TEvent);
var
  B: Byte;
  H, M, S, HS: Word;
  T: String[15];
begin
  if (Event.What = evKeyDown) and
     ((Event.KeyCode = kbAltIns) or (Event.KeyCode = kbAltColon)) then
  begin
    GetTime(H, M, S, HS);
    B := CountryTime;
    CountryTime := cs24Hour;
    T := FormatTimeStr(H, M, S);
    CountryTime := B;
    SetData(T);
    Event.What := evNothing;
  end;
  Inherited HandleEvent(Event);
end;

function TTimeInputLine.Valid(Command: Word): Boolean;
var
  Time: DateTime;
begin
  if (Command = cmOk) and (Trim(Data^) <> '') then
  begin
    GetHMS(Data^, Time.Hour, Time.Min, Time.Sec);
    if (Time.Hour = $FFFF) or (Time.Min = $FFFF) then
    begin
      Select;
      InvalidInputMsgBox(Data^, 'time');
      Valid := False;
      Exit;
    end;
  end;
  Valid := TInputLine.Valid(Command);
end;

function TSizeInputLine.Valid(Command: Word): Boolean;
var
  Code: Integer;
  R: Real;
begin
  if (Command = cmOk) and (Trim(Data^) <> '') then
  begin
    R := SizeStrToSize(Data^, Code);
    if (Code <> 0) or (R < 0) or (R > MaxLongint) then
    begin
      Select;
      if Code > 0 then CurPos := Code - 1;
      DrawView;
      InvalidInputMsgBox(Data^, 'file size');
      Valid := False;
      Exit;
    end;
  end;
  Valid := TInputLine.Valid(Command);
end;

const
  AttrCheckBoxesValue: Word = 0;

procedure AttrDlgProc(V: PView; var Event: TEvent);

function IsAttrCheckBoxes(P: PView): Boolean; far;
begin
  IsAttrCheckBoxes := (TypeOf(P^) = TypeOf(TCheckBoxes)) and
    (P^.Origin.X = 3);
end;

var
  B: Byte;
  P: PCheckBoxes;
begin
  P := PCheckBoxes(PDialog(V)^.FirstThat(@IsAttrCheckBoxes));
  if P <> nil then
  begin
    if (P^.Value and $10 <> 0) and (P^.Value and $20 <> 0) then
    begin
      if AttrCheckBoxesValue and $20 = 0 then B := $10 else B := $20;
      P^.Value := P^.Value and not B;
      P^.DrawView;
    end;
    AttrCheckBoxesValue := P^.Value;
  end;
end;

procedure FileAttributesPrim(FManager: PPanel);
type
  TAttrData = record
    SetAttr, ClearAttr: Word;
    Date: String[8];
    Time: String[8];
    Date1: String[8];
    Time1: String[8];
    Date2: String[8];
    Time2: String[8];
  end;
const
  ReadOnlyStr = '~R~ead only';
  HiddenStr = '~H~idden';
  SystemStr = '~S~ystem';
  ArchiveStr = '~A~rchive';
  CompressedStr = '~C~ompressed';
  EncryptedStr = '~E~ncrypted ';
  WinNTStr = ' (Windows NT only)';
var
  Single, Dots: Boolean;
  W: Word;
  I, LoX, HiX, HiY, Code: Integer;
  L, L1, L2: Longint;
  SR: PPanelRec;
  D: PDialog;
  Control: PView;
  R: TRect;
  SS: String[38];
  Time: DateTime;
  AData: TAttrData;
  F: File;
  S: FNameStr;
begin
  with FManager^ do
  begin
    if State and sfVisible = 0 then Exit;
    if InArchive then
    begin
      if Archiver^.ArcID >= avUsr then
        UserArchiverDialog(ConfigPath + UserArchiverName)
      else ArchiverDialog(ConfigPath + ArchiverName, Archiver^.ArcID - 1);
      Exit;
    end;
    if (List^.Count = 0) or (Status > stTree) or
       (Options and ofValidate <> 0) then Exit;
    SR := PPanelRec(List^.At(Focused));
    if SR^.Attr and VolumeID <> 0 then Exit;
    Single := (SelCount = 0) or (Settings and seIgnoreSelection <> 0);
    Dots := SR^.Name[1] in [':', '.'];
    if Which = pnLeft then
    begin
      LoX := 6;
      HiX := LoX + 44;
    end
    else
    begin
      HiX := ScreenWidth - 6;
      LoX := HiX - 44;
    end;
    if not Single or Dots then HiY := 19
    else
    begin
      AddNameExt('', SR, S);
      if S = '' then S := ' ';
      if S[0] > #190 then S[0] := #190;
      HiY := 19 + (Length(S) - 1) div 38;
    end;
    R.Assign(LoX, 0, HiX, HiY);
    D := InitSimpleDialog(R, 'File attributes', hcFileAttributes);
    with D^ do
    begin
      Options := Options or ofCenterY;
      D^.PostProcessEvent := AttrDlgProc;

      if not Single or Dots then
      begin
	R.Assign(3, 3, 11, 9);
	Control := New(PCheckBoxes, Init(R,
	  NewSItem(' ',
	  NewSItem(' ',
	  NewSItem(' ',
	  NewSItem(' ',
	  NewSItem(' ',
	  NewSItem(' ', nil))))))));
	if not CN_NT then PCheckBoxes(Control)^.SetButtonState($30, False);
	Insert(Control);
	R.Assign(2, 2, 7, 3);
	Insert(New(PLabel, Init(R, 'Set', Control)));

	R.Assign(7, 3, Size.X - 3, 9);
	Control := New(PCheckBoxes, Init(R,
	  NewSItem(ReadOnlyStr,
	  NewSItem(HiddenStr,
	  NewSItem(SystemStr,
	  NewSItem(ArchiveStr,
	  NewSItem(CompressedStr + WinNTStr,
	  NewSItem(EncryptedStr + WinNTStr, nil))))))));
	if not CN_NT then PCheckBoxes(Control)^.SetButtonState($30, False);
	Insert(Control);
	R.Assign(7, 2, Size.X - 3, 3);
	Insert(New(PLabel, Init(R, 'Clear', Control)));
      end
      else
      begin
	R.Assign(3, Size.Y - 16, Size.X - 3, Size.Y - 10);
	Control := New(PCheckBoxes, Init(R,
	  NewSItem(ReadOnlyStr,
	  NewSItem(HiddenStr,
	  NewSItem(SystemStr,
	  NewSItem(ArchiveStr,
	  NewSItem(CompressedStr + WinNTStr,
	  NewSItem(EncryptedStr + WinNTStr, nil))))))));
	if not CN_NT then PCheckBoxes(Control)^.SetButtonState($30, False);
	Insert(Control);
	HiY := 2;
	repeat
	  SS := System.Copy(S, 1, 38);
	  System.Delete(S, 1, 38);
	  R.Assign(2, HiY, Size.X - 3, HiY + 1);
	  Insert(New(PVarLabel, Init(R, SS, Control, 0)));
	  Inc(HiY);
	until S = '';
	R.Assign(0, 0, 0, 0);
	Control := New(PCheckBoxes, Init(R, nil));
	Control^.Options := Control^.Options and not ofSelectable;
	Insert(Control);
      end;

      R.Assign(9, Size.Y - 9, 19, Size.Y - 8);
      Control := New(PDateInputLine, Init(R, 8));
      Insert(Control);
      StandardHistory(Control, DateHistoryId);
      R.Assign(2, Size.Y - 10, Size.X - 3, Size.Y - 9);
      Insert(New(PLabel, Init(R, 'Last modification', Control)));
      R.Assign(3, Size.Y - 9, 9, Size.Y - 8);
      Insert(New(PLabel, Init(R, '~D~ate', Control)));
      R.Assign(28, Size.Y - 9, 38, Size.Y - 8);
      Control := New(PTimeInputLine, Init(R, 8));
      Insert(Control);
      StandardHistory(Control, TimeHistoryId);
      R.Assign(22, Size.Y - 9, 28, Size.Y - 8);
      Insert(New(PLabel, Init(R, '~T~ime', Control)));

      R.Assign(9, Size.Y - 7, 19, Size.Y - 6);
      Control := New(PDateInputLine, Init(R, 8));
      Insert(Control);
      StandardHistory(Control, DateHistoryId);
      R.Assign(2, Size.Y - 8, Size.X - 3, Size.Y - 7);
      Insert(New(PLabel, Init(R, 'Last access' + WinNTStr, Control)));
      R.Assign(3, Size.Y - 7, 9, Size.Y - 6);
      Insert(New(PLabel, Init(R, 'Date', Control)));
      R.Assign(28, Size.Y - 7, 38, Size.Y - 6);
      Control := New(PTimeInputLine, Init(R, 8));
      Insert(Control);
      StandardHistory(Control, TimeHistoryId);
      R.Assign(22, Size.Y - 7, 28, Size.Y - 6);
      Insert(New(PLabel, Init(R, 'T~i~me', Control)));

      R.Assign(9, Size.Y - 5, 19, Size.Y - 4);
      Control := New(PDateInputLine, Init(R, 8));
      Insert(Control);
      StandardHistory(Control, DateHistoryId);
      R.Assign(2, Size.Y - 6, Size.X - 3, Size.Y - 5);
      Insert(New(PLabel, Init(R, 'File creation' + WinNTStr, Control)));
      R.Assign(3, Size.Y - 5, 9, Size.Y - 4);
      Insert(New(PLabel, Init(R, 'Date', Control)));
      R.Assign(28, Size.Y - 5, 38, Size.Y - 4);
      Control := New(PTimeInputLine, Init(R, 8));
      Insert(Control);
      StandardHistory(Control, TimeHistoryId);
      R.Assign(22, Size.Y - 5, 28, Size.Y - 4);
      Insert(New(PLabel, Init(R, 'Ti~m~e', Control)));

      for I := 0 to 5 do SelectNext(True);
      if not Single or Dots then SelectNext(True);
    end;
    FillChar(AData, SizeOf(TAttrData), 0);
    if Single and not Dots then
    begin
      AData.SetAttr := SR^.Attr;
      if SR^.HiAttr and haCompressed <> 0 then
	AData.SetAttr := AData.SetAttr or faCompressed;
      if SR^.HiAttr and haEncrypted <> 0 then
	AData.SetAttr := AData.SetAttr or faEncrypted;
      AData.Date := GetDateStr(SR^.Time);
      AData.Time := GetTimeStr(SR^.Time);

      if CN_NT then
      begin
	GetRecStr(SR, S);
{	AData.SetAttr := NT_GetFAttr(S);}

	if NT_GetFTime(S, L, 2) then
	begin
	  AData.Date := GetDateStr(L);
	  AData.Time := GetTimeStr(L);
	end;
	if NT_GetFTime(S, L1, 1) then
	begin
	  AData.Date1 := GetDateStr(L1);
	  AData.Time1 := GetTimeStr(L1);
	end;
	if NT_GetFTime(S, L2, 0) then
	begin
	  AData.Date2 := GetDateStr(L2);
	  AData.Time2 := GetTimeStr(L2);
	end;
      end;

      AData.SetAttr :=  AData.SetAttr and not
	(Directory + faDisplaySize + faSizeInKB);
      if AData.SetAttr and Archive <> 0 then
	AData.SetAttr := (AData.SetAttr and not Archive) or $08;
      if AData.SetAttr and faCompressed <> 0 then
	AData.SetAttr := (AData.SetAttr and not faCompressed) or $10;
      if AData.SetAttr and faEncrypted <> 0 then
	AData.SetAttr := (AData.SetAttr and not faEncrypted) or $20;
    end
    else
    begin
      AData.Date := HistoryStr(DateHistoryID, 0);
      AData.Time := HistoryStr(TimeHistoryID, 0);
    end;
    if Application^.ExecuteDialog(D, @AData, False) <> cmCancel then
    begin
      if AData.SetAttr and $20 <> 0 then
	AData.SetAttr := (AData.SetAttr and not $20) or faEncrypted;
      if AData.ClearAttr and $20 <> 0 then
	AData.ClearAttr := (AData.ClearAttr and not $20) or faEncrypted;
      if AData.SetAttr and $10 <> 0 then
	AData.SetAttr := (AData.SetAttr and not $10) or faCompressed;
      if AData.ClearAttr and $10 <> 0 then
	AData.ClearAttr := (AData.ClearAttr and not $10) or faCompressed;
      if AData.SetAttr and $08 <> 0 then
	AData.SetAttr := (AData.SetAttr and not $08) or Archive;
      if AData.ClearAttr and $08 <> 0 then
	AData.ClearAttr := (AData.ClearAttr and not $08) or Archive;

      GetMDY(AData.Date, Time.Month, Time.Day, Time.Year);
      GetHMS(AData.Time, Time.Hour, Time.Min, Time.Sec);
      PackTime(Time, L);
      if Trim(AData.Date) = '' then L := L or $FFFF0000;
      if Trim(AData.Time) = '' then L := L or $FFFF;
      if CN_NT then
      begin
	GetMDY(AData.Date1, Time.Month, Time.Day, Time.Year);
	GetHMS(AData.Time1, Time.Hour, Time.Min, Time.Sec);
	PackTime(Time, L1);
	if Trim(AData.Date1) = '' then L1 := L1 or $FFFF0000;
	if Trim(AData.Time1) = '' then L1 := L1 or $FFFF;

	GetMDY(AData.Date2, Time.Month, Time.Day, Time.Year);
	GetHMS(AData.Time2, Time.Hour, Time.Min, Time.Sec);
	PackTime(Time, L2);
	if Trim(AData.Date2) = '' then L2 := L2 or $FFFF0000;
	if Trim(AData.Time2) = '' then L2 := L2 or $FFFF;
      end
      else
      begin
	L1 := $FFFFFFFF;
	L2 := $FFFFFFFF;
      end;
      CopyStatus := dsOverwrite;
      CopyErrorStatus := deRetry;
      if not Single then
      begin
	DoneSelList;
	InitSelList;
	for I := 0 to List^.Count - 1 do
	begin
	  SR := List^.At(I);
	  if SR^.Selected then
	  begin
	    GetRecStr(SR, S);
{	    if CN_NT then W := NT_GetFAttr(S); }
	    W := SR^.Attr;
	    if SR^.HiAttr and haCompressed <> 0 then W := W or faCompressed;
	    if SR^.HiAttr and haEncrypted <> 0 then W := W or faEncrypted;
	    FSetAttrPrim(S, (W or AData.SetAttr) and not AData.ClearAttr,
	      L, L1, L2);
	    if DosError = 0 then
	    begin
	      SetSelect(SR, False);
	      if FMOptions and foUnsel <> 0 then FocusItem(Focused);
	    end;
	  end;
	  if (KbdStatus = 1) and FMAbortAction then Break;
	end;
      end
      else
      begin
	GetRecStr(SR, S);
	if Dots then DirSetAttr(AddedSlash(S), AData.SetAttr,
	  L, L1, L2, CRCList)
	else FSetAttrPrim(S, AData.SetAttr, L, L1, L2);
      end;
      Message(Desktop, evBroadcast, cmUpdateDisk, nil);
    end;
  end;
end;

procedure FilterDialogPrim(FManager: PPanel);
var
  C: Word;
  LoX, HiX, I: Integer;
  D: PDialog;
  Control: PView;
  H: PHistory;
  R: TRect;
  S: FNameStr;
begin
  with FManager^ do
  begin
    if (State and sfVisible = 0) or (Status >= stTree) then Exit;
    if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
    begin
      AdvancedFilterDialogPrim(FManager);
      Exit;
    end;
    if Which = pnLeft then
    begin
      LoX := 4;
      HiX := LoX + 30;
    end
    else
    begin
      HiX := ScreenWidth - 4;
      LoX := HiX - 30;
    end;
    R.Assign(LoX, 0, HiX, 9);
    D := InitSimpleDialog(R, 'Filter', hcFilter);
    with D^ do
    begin
      Options := Options or ofCenterY;
      R.Assign(10, 2, 24, 3);
      Control := New(PInputLine, Init(R, 12));
      Insert(Control);
      H := StandardHistory(Control, MaskHistoryId);
      H^.HistoryPutFunc := UNIXPutHistoryFunc;
      H^.HistoryGetFunc := UNIXGetHistoryFunc;
      R.Assign(2, 2, 10, 3);
      Insert(New(PLabel, Init(R, '~F~ilter', Control)));
      R.Assign(3, 4, Size.X - 3, 6);
      Insert(New(PButton, Init(R, '~A~dvanced filter...', cmYes, bfNormal)));
      Control^.Select;
    end;
    S := Filter;
    C := Application^.ExecuteDialog(D, @S, False);
    if C = cmCancel then Exit;
    if C = cmYes then AdvancedFilterDialogPrim(FManager)
    else
    begin
      Filter := S;
      GetItemStr(Focused, S);
      NewDir(ListDir^, True);
      GetItemNum(S, I);
      FocusItem(I);
    end;
  end;
end;

const
  flReadOnly  = $01;
  flHidden    = $02;
  flSystem    = $04;
  flDirectory = $08;
  flArchive   = $10;
  flAnyFile   = $20;

procedure Filter2Data(var AdvancedFilter: TFilterRec;
  var Data: TAdvancedFilterData);
var
  C: Char;
  S: String;
begin
  FillChar(Data, SizeOf(TAdvancedFilterData), 0);
  if AdvancedFilter.Text <> nil then
  begin
    Data.Txt := AdvancedFilter.Text^;
    if AdvancedFilter.Unix and (Pos(UNIXHistStr, Data.Txt) = 0) then
      Data.Txt := Data.Txt + UNIXHistStr;
    Data.Unix := Byte(AdvancedFilter.Unix);
    if AdvancedFilter.LoTime <> -1 then
    begin
      Data.LoDate := GetDateStr(AdvancedFilter.LoTime);
      Data.LoTime := GetTimeStr(AdvancedFilter.LoTime);
    end;
    if AdvancedFilter.HiTime <> -1 then
    begin
      Data.HiDate := GetDateStr(AdvancedFilter.HiTime);
      Data.HiTime := GetTimeStr(AdvancedFilter.HiTime);
    end;
    C := ThousandsSeparator;
    ThousandsSeparator := #0;
    if AdvancedFilter.LoSize >= 0 then
    begin
      FormatFloatBytes(S, AdvancedFilter.LoSize, 1000000000);
      Data.LoSize := Trim(DelChar(' ', S));
    end;
    if AdvancedFilter.HiSize >= 0 then
    begin
      FormatFloatBytes(S, AdvancedFilter.HiSize, 1000000000);
      Data.HiSize := Trim(DelChar(' ', S));
    end;
    ThousandsSeparator := C;
    if AdvancedFilter.Attr and AnyFile = AnyFile then
      Data.Attr := flAnyFile
    else
    begin
      Data.Attr := 0;
      if AdvancedFilter.Attr and ReadOnly <> 0 then
        Data.Attr := flReadOnly;
      if AdvancedFilter.Attr and Hidden <> 0 then
        Data.Attr := Data.Attr or flHidden;
      if AdvancedFilter.Attr and SysFile <> 0 then
        Data.Attr := Data.Attr or flSystem;
      if AdvancedFilter.Attr and Directory <> 0 then
        Data.Attr := Data.Attr or flDirectory;
      if AdvancedFilter.Attr and Archive <> 0 then
        Data.Attr := Data.Attr or flArchive;
    end;
    Data.Lists := Byte(not AdvancedFilter.UseForLists);
  end
  else
  begin
    Data.Unix := Byte(UnixFlag);
    Data.Attr := flAnyFile;
  end;
end;

procedure Data2Filter(var AdvancedFilter: TFilterRec;
  var Data: TAdvancedFilterData; ACommand: Word);
var
  I, Code: Integer;
  R: Real;
  Time: DateTime;
begin
  if ACommand = cmCancel then Exit;
{  DisposeStr(AdvancedFilter.Text);}
  DisposeStrUMB(AdvancedFilter.Text);
  TrimSt(Data.Txt);
  if (ACommand = cmYes) or (Data.Txt = '') then
    AdvancedFilter.Text := nil
  else
  begin
{    AdvancedFilter.Text := NewStr(Data.Txt);}
    AdvancedFilter.Text := NewStrUMB(Data.Txt);
    AdvancedFilter.PipePos := Pos('|', Data.Txt);
    AdvancedFilter.Unix := Data.Unix <> 0;
    GetMDY(Data.LoDate, Time.Month, Time.Day, Time.Year);
    GetHMS(Data.LoTime, Time.Hour, Time.Min, Time.Sec);
    if (Time.Hour = $FFFF) or (Time.Min = $FFFF) then
    begin
      Time.Hour := 0;
      Time.Min := 0;
    end;
    if (Time.Month = $FFFF) or
       (Time.Day = $FFFF) or
       (Time.Year = $FFFF) then AdvancedFilter.LoTime := -1
    else PackTime(Time, AdvancedFilter.LoTime);
    GetMDY(Data.HiDate, Time.Month, Time.Day, Time.Year);
    GetHMS(Data.HiTime, Time.Hour, Time.Min, Time.Sec);
    if (Time.Hour = $FFFF) or (Time.Min = $FFFF) then
    begin
      Time.Hour := 0;
      Time.Min := 0;
    end;
    if (Time.Month = $FFFF) or (Time.Day = $FFFF) or
       (Time.Year = $FFFF) then AdvancedFilter.HiTime := -1
    else PackTime(Time, AdvancedFilter.HiTime);
    R := SizeStrToSize(Data.LoSize, Code);
    if Abs(R) > MaxLongint then AdvancedFilter.LoSize := -1
    else AdvancedFilter.LoSize := Trunc(R);
    R := SizeStrToSize(Data.HiSize, Code);
    if Abs(R) > MaxLongint then AdvancedFilter.HiSize := -1
    else AdvancedFilter.HiSize := Trunc(R);
    if Data.Attr and flAnyFile <> 0 then
      AdvancedFilter.Attr := AnyFile
    else
    begin
      AdvancedFilter.Attr := 0;
      if Data.Attr and flReadOnly <> 0 then
	AdvancedFilter.Attr := ReadOnly;
      if Data.Attr and flHidden <> 0 then
	AdvancedFilter.Attr := AdvancedFilter.Attr or Hidden;
      if Data.Attr and flSystem <> 0 then
	AdvancedFilter.Attr := AdvancedFilter.Attr or SysFile;
      if Data.Attr and flDirectory <> 0 then
        AdvancedFilter.Attr := AdvancedFilter.Attr or Directory;
      if Data.Attr and flArchive <> 0 then
        AdvancedFilter.Attr := AdvancedFilter.Attr or Archive;
    end;
    AdvancedFilter.UseForLists := Data.Lists = 0;
  end;
  UnixFlag := Data.Unix <> 0;
end;

procedure AdvancedFilterToData(FManager: PPanel;
  var Data: TAdvancedFilterData);
begin
  Filter2Data(FManager^.AdvancedFilter, Data);
end;

procedure DataToAdvancedFilter(FManager: PPanel;
  var Data: TAdvancedFilterData; ACommand: Word);
var
  I: Integer;
  S: FNameStr;
begin
  if ACommand <> cmCancel then with FManager^ do
  begin
    Data2Filter(AdvancedFilter, Data, ACommand);
    if AdvancedFilter.Text <> nil then
      Settings := Settings or seAdvancedFilter
    else Settings := Settings and not seAdvancedFilter;
    GetItemStr(Focused, S);
    NewDir(ListDir^, True);
    GetItemNum(S, I);
    FocusItem(I);
  end;
end;

function AdvancedFilterDlg(const AHeader, AOptions: String): PDialog;
var
  D: PDialog;
  Control: PView;
  H: PHistory;
  R: TRect;
begin
  R.Assign(0, 0, 61, 18);
  D := New(PAdvancedFilterDialog, Init(R, AHeader));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcAdvancedFilter;

    R.Assign(10, 2, Size.X - 28, 3);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    H := StandardHistory(Control, AdvancedFilterHistoryID);
    H^.HistoryPutFunc := UNIXPutHistoryFunc;
    H^.HistoryGetFunc := UNIXGetHistoryFunc;
    R.Assign(2, 2, 10, 3);
    Insert(New(PLabel, Init(R, '~F~ilter', Control)));
    R.Assign(Size.X - 24, 2, Size.X - 3, 3);
    Insert(New(PCheckBoxes, Init(R,
      NewSItem('~U~NIX style mask', nil))));

    R.Assign(10, 4, 19, 5);
    Insert(New(PStaticText, Init(R, 'File date')));
    R.Assign(23, 4, 32, 5);
    Insert(New(PStaticText, Init(R, 'File time')));

    R.Assign(10, 5, 20, 6);
    Control := New(PDateInputLine, Init(R, 8));
    Insert(Control);
    StandardHistory(Control, DateHistoryId);
    R.Assign(2, 5, 10, 6);
    Insert(New(PLabel, Init(R, '~A~fter', Control)));
    R.Assign(23, 5, 33, 6);
    Control := New(PTimeInputLine, Init(R, 8));
    Insert(Control);
    StandardHistory(Control, TimeHistoryId);

    R.Assign(10, 6, 20, 7);
    Control := New(PDateInputLine, Init(R, 8));
    Insert(Control);
    StandardHistory(Control, DateHistoryId);
    R.Assign(2, 6, 10, 7);
    Insert(New(PLabel, Init(R, '~B~efore', Control)));
    R.Assign(23, 6, 33, 7);
    Control := New(PTimeInputLine, Init(R, 8));
    Insert(Control);
    StandardHistory(Control, TimeHistoryId);

    R.Assign(43, 4, 52, 5);
    Insert(New(PStaticText, Init(R, 'File size')));

    R.Assign(43, 5, 55, 6);
    Control := New(PSizeInputLine, Init(R, 10));
    Insert(Control);
    StandardHistory(Control, FilterSizeHistoryID);
    R.Assign(36, 5, 43, 6);
    Insert(New(PLabel, Init(R, 'Ab~o~ve', Control)));

    R.Assign(43, 6, 55, 7);
    Control := New(PSizeInputLine, Init(R, 10));
    Insert(Control);
    StandardHistory(Control, FilterSizeHistoryID);
    R.Assign(36, 6, 43, 7);
    Insert(New(PLabel, Init(R, 'Belo~w~', Control)));

    R.Assign(3, 9, Size.X - 3, 11);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~R~ead only',
      NewSItem('~H~idden',
      NewSItem('S~y~stem',
      NewSItem('~D~irectory',
      NewSItem('Arch~i~ve',
      NewSItem('A~n~y file', nil))))))));
    Insert(Control);
    R.Assign(2, 8, Size.X - 3, 9);
    Insert(New(PLabel, Init(R, 'File attributes', Control)));

    R.Assign(3, 13, Size.X - 3, 14);
    Control := New(PCheckBoxes, Init(R,
      NewSItem(AOptions, nil)));
    Insert(Control);
    R.Assign(2, 12, Size.X - 3, 13);
    Insert(New(PLabel, Init(R, 'Options', Control)));

    R.Assign(2, Size.Y - 3, 10, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(11, Size.Y - 3, 20, Size.Y - 1);
    Insert(New(PButton, Init(R, '~C~lear', cmYes, bfNormal)));
    R.Assign(21, Size.Y - 3, 29, Size.Y - 1);
    Insert(New(PButton, Init(R, '~L~oad', cmRetrieveOptions, bfNormal)));
    R.Assign(30, Size.Y - 3, 39, Size.Y - 1);
    Insert(New(PButton, Init(R, '~S~tore', cmSaveOptions, bfNormal)));
    R.Assign(40, Size.Y - 3, 50, Size.Y - 1);
    StandardCancelButton(R, D);
    R.Assign(51, Size.Y - 3, 59, Size.Y - 1);
    StandardHelpButton(R, D);

    SelectNext(False);
  end;
  AdvancedFilterDlg := D;
end;

procedure AdvancedFilterDialogPrim(FManager: PPanel);
var
  Data: TAdvancedFilterData;
begin
  with FManager^ do
    if (State and sfVisible = 0) or (Status >= stTree) then Exit;
  AdvancedFilterToData(FManager, Data);
  DataToAdvancedFilter(FManager, Data,
    Application^.ExecuteDialog(AdvancedFilterDlg(
      'Advanced panel filter', 'Do no~t~ apply to archives or file lists'),
      @Data, False));
end;

procedure ReadAdvancedFilterPrim(FManager: PPanel;
  const Name: FNameStr);
var
  C: Word;
  Data: TAdvancedFilterData;
begin
  Data.Unix := Byte(UnixFlag);
  if Name = '' then C := cmYes
  else if not LoadAdvancedFilter(Name, Data, nil) then Exit
  else C := cmOk;
  DataToAdvancedFilter(FManager, Data, C);
end;

procedure OperationFilterDialog;
var
  Data: TAdvancedFilterData;
begin
  Filter2Data(CopyRenameFilter, Data);
  Data2Filter(CopyRenameFilter, Data,
    Application^.ExecuteDialog(AdvancedFilterDlg(
      'Advanced Copy/Rename filter',
      'Clear on comple~t~ing the Copy/Rename operation'),
      @Data, False));
end;

procedure GetPanelColorsPrim(FManager: PPanel);
var
  I: Integer;
  P: PPanelRec;
begin
  with FManager^ do
  begin
    InitTempGroups;
    I := 0;
    while I < List^.Count do
    begin
      P := List^.At(I);
      GetGroupInfo(P^.Name, P^.Ext, P^.Attr and Directory <> 0,
        P^.Color, P^.Index);
      if P^.Color = 0 then
      begin
        List^.AtFree(I);
        if I < FilesBBS^.Count then FilesBBS^.AtFree(I);
      end
      else Inc(I);
    end;
    DoneTempGroups;
    SetRange(List^.Count);
  end;
end;

const
  BothCommands = [cmYes];

procedure SortDialogPrim(FManager: PPanel);
type
  TData = record
    Mode: Word;
    DirByName: Word;
    DigitsAsChars: Word;
    Direction: Word;
    Priority: Word;
    Selection: Longint;
    CaseSens: Word;
    Groups: Word;
    IndexStr: String[255];
    Times: Word;
{ Added 2005.12.29 to support NT size on disk }
    Sizes: Word;
    Action: Word;
    InverseMixed: Word;
    LinePos: String[3];
  end;
var
  DoReread: Boolean;
  B, T: Byte;
  C: Word;
  I: Integer;
  D: PDialog;
  Control, DirControl: PView;
  Panel: PPanel;
  R: TRect;
  Data: TData;
  S: FNameStr;
label
  ApplySettings;
begin
  with FManager^ do
  begin
    if (State and sfVisible = 0) or (Status >= stTree) then Exit;
    if Which = pnLeft then S := 'Left' else S := 'Right';
    R.Assign(0, 0, 73, 23);
    D := New(PDialog, Init(R, S + ' panel sort and display options'));
    with D^ do
    begin
      Options := Options or ofCentered;
      HelpCtx := hcSort;

      R.Assign(3, 2, 37, 10);
      Control := New(PRadioButtons, Init(R,
	NewSItem('~N~ame',
	NewSItem('E~x~tension',
	NewSItem('~T~ime',
	NewSItem('Si~z~e',
	NewSItem('D~e~scription',
	NewSItem('De~s~cription order',
	NewSItem('Disk ~o~rder',
	NewSItem('Digital num~b~er', nil))))))))));
      Insert(Control);
      R.Assign(2, 1, 37, 2);
      Insert(New(PLabel, Init(R, 'Sort files by', Control)));

      R.Assign(20, 2, 37, 3);
      DirControl := New(PCheckBoxes, Init(R,
	NewSItem('Dirs always', nil)));
      Insert(DirControl);

      R.Assign(22, 9, 37, 10);
      DirControl := New(PCheckBoxes, Init(R,
	NewSItem('As string', nil)));
      Insert(DirControl);

      R.Assign(39, 2, 70, 3);
      DirControl := New(PRadioButtons,  Init(R,
	NewSItem('~A~scending',
	NewSItem('~D~escending', nil))));
      Insert(DirControl);
      R.Assign(38, 1, 67, 2);
      Insert(New(PLabel, Init(R, 'Sort direction', DirControl)));

      R.Assign(39, 4, 70, 7);
      DirControl := New(PRadioButtons,  Init(R,
	NewSItem('Di~r~ectories first',
	NewSItem('F~i~les first',
	NewSItem('Mixed', nil)))));
      Insert(DirControl);
      R.Assign(38, 3, 70, 4);
      Insert(New(PLabel, Init(R, 'Sort priority', DirControl)));

      R.Assign(39, 7, 70, 8);
      DirControl := New(PMultiCheckBoxes, Init(R,
	NewSItem('Selected first~/~last', nil), 3, cfTwoBits, ' FL'));
      Insert(DirControl);

      R.Assign(3, 11, 37, 14);
      DirControl := New(PCheckBoxes, Init(R,
	NewSItem('~F~ile names',
	NewSItem('Directory names',
	NewSItem('Descriptions', nil)))));
      Insert(DirControl);
      R.Assign(2, 10, 37, 11);
      Insert(New(PLabel, Init(R, 'Case sensitive sort', DirControl)));

      R.Assign(39, 9, 70, 12);
      DirControl := New(PCheckBoxes, Init(R,
	NewSItem('Group ~h~ighlight',
	NewSItem('Selection t~u~rns off',
	NewSItem('Sort by ~g~roup index', nil)))));
      Insert(DirControl);
      R.Assign(38, 8, 70, 9);
      Insert(New(PLabel, Init(R, 'File group options', DirControl)));

      R.Assign(64, 11, 70, 12);
      DirControl := New(PInputLine, Init(R, 255));
      Insert(DirControl);

      R.Assign(3, 15, 37, 18);
      DirControl := New(PRadioButtons,  Init(R,
	NewSItem('~L~ast modification time',
	NewSItem('Last a~c~cess time',
	NewSItem('File creation time', nil)))));
      Insert(DirControl);
{ Added 2005.12.29 to support NT size on disk }
      R.Assign(3, 18, 37, 19);
      DirControl := New(PCheckBoxes, Init(R,
	NewSItem('Size on disk (~W~in NT only)', nil)));
      if not CN_NT then PCheckBoxes(DirControl)^.SetButtonState($01, False);
      Insert(DirControl);
      R.Assign(2, 14, 37, 15);
      Insert(New(PLabel, Init(R, 'Win95/NT file time/size options', DirControl)));

      R.Assign(39, 13, 70, 15);
      DirControl := New(PRadioButtons,  Init(R,
	NewSItem('Sort in memor~y~',
	NewSItem('Re~-~read directory', nil))));
      Insert(DirControl);
      R.Assign(38, 12, 70, 13);
      Insert(New(PLabel, Init(R, 'Sort action', DirControl)));

      R.Assign(39, 16, 70, 19);
      DirControl := New(PCheckBoxes, Init(R,
	NewSItem('In~v~erse long/short',
	NewSItem('~M~ixed char/numerical',
	NewSItem('Sort by "name~.~ext" string', nil)))));
      Insert(DirControl);
      R.Assign(38, 15, 70, 16);
      Insert(New(PLabel, Init(R, 'Sort by name/extension', DirControl)));

      R.Assign(63, 20, 70, 21);
      DirControl := New(PCInputLine, Init(R, 3, 1, 255));
      Insert(DirControl);
      R.Assign(38, 20, 63, 21);
      Insert(New(PLabel, Init(R,
	'Description compare ~p~os', DirControl)));

      R.Assign(2, Size.Y - 3, 8, Size.Y - 1);
      StandardOkButton(R, D);
      R.Assign(9, Size.Y - 3, 17, Size.Y - 1);
      Insert(New(PButton, Init(R, 'Both', cmYes, bfNormal)));
      R.Assign(18, Size.Y - 3, 28, Size.Y - 1);
      StandardCancelButton(R, D);
      R.Assign(29, Size.Y - 3, 37, Size.Y - 1);
      StandardHelpButton(R, D);

      SelectNext(False);
    end;

    Data.Mode := SortMode;
    if GroupOptions and fgSortDirsByName <> 0 then Data.DirByName := 1
    else Data.DirByName := 0;
    if GroupOptions and fgSortDigitsAsChars <> 0 then Data.DigitsAsChars := 1
    else Data.DigitsAsChars := 0;
    if GroupOptions and fgSortInverse <> 0 then Data.InverseMixed := 1
    else Data.InverseMixed := 0;
    if GroupOptions and fgSortMixed <> 0 then Data.InverseMixed :=
      Data.InverseMixed or 2;
    if GroupOptions and fgSortNameExt <> 0 then Data.InverseMixed :=
      Data.InverseMixed or 4;
    Data.Direction := SortDirection;
    Data.Priority := SortPriority;
    Data.Selection := Byte(SortSel);
    Data.CaseSens := SortCaseSens;
    if SortDescrPos = 0 then Data.LinePos := '1'
    else Str(SortDescrPos, Data.LinePos);
    if SortIndexStr = nil then Data.IndexStr := ''
    else Data.IndexStr := SortIndexStr^;
    Data.Groups := GroupOptions and not
      (fgSortDirsByName + fgSortDigitsAsChars + fgSortInverse +
       fgSortMixed + fgSortNameExt);
    Data.Times := TimeMode and 3;
{ Added 2005.12.29 to support NT size on disk }
    Data.Sizes := Byte(TimeMode and ltSZD <> 0);
    Data.Action := SortAction;
    B := GroupOptions and (fgGroupHighlight + fgSortByIndex);
    T := TimeMode;

    if FManager^.Opposite^.State and sfVisible = 0 then
      Application^.DisableCommands(BothCommands);
    C := Application^.ExecuteDialog(D, @Data, False);
    Application^.EnableCommands(BothCommands);
    if C <> cmCancel then
    begin
      Panel := FManager;
ApplySettings:
      with Panel^ do
      begin
	SortMode := Data.Mode;
	SortDirection := Data.Direction;
	SortPriority := Data.Priority;
	Byte(SortSel) := Byte(Data.Selection);
	SortCaseSens := Data.CaseSens;
	Val(Data.LinePos, SortDescrPos, I);
{
	DisposeStr(SortIndexStr);
	SortIndexStr := NewStr(Data.IndexStr);
}
	DisposeStrUMB(SortIndexStr);
	SortIndexStr := NewStrUMB(Data.IndexStr);
	GroupOptions := Data.Groups;
	if Data.DirByName <> 0 then
	  GroupOptions := GroupOptions or fgSortDirsByName;
	if Data.DigitsAsChars <> 0 then
	  GroupOptions := GroupOptions or fgSortDigitsAsChars;
	if Data.InverseMixed and 1 <> 0 then
	  GroupOptions := GroupOptions or fgSortInverse;
	if Data.InverseMixed and 2 <> 0 then
	  GroupOptions := GroupOptions or fgSortMixed;
	if Data.InverseMixed and 4 <> 0 then
	  GroupOptions := GroupOptions or fgSortNameExt;
	TimeMode := Data.Times;
{ Added 2005.12.29 to support NT size on disk }
	if Data.Sizes <> 0 then TimeMode := TimeMode or ltSZD;
	SortAction := Data.Action;
	if (SortAction = 0) and
	   (((B and fgGroupHighlight = 0) and
	     (GroupOptions and fgGroupHighlight <> 0)) or
	    ((B and fgSortByIndex = 0) and
             (GroupOptions and fgSortByIndex <> 0))) then
          GetPanelColorsPrim(FManager);
        DoReread :=
	  (SortMode = smDisk) or (T <> TimeMode) or (SortAction <> 0);
	GetItemStr(Focused, S);
	if DoReread then NewDir(ListDir^, True)
	else
        begin
          DrawStatusLine('Rearranging the Panel file list.');
          Files^.Sort;
        end;
        GetItemNum(S, I);
        FocusItem(I);
      end;
      if (C = cmYes) and (Panel = FManager) then
      begin
        Panel := Panel^.Opposite;
        goto ApplySettings;
      end;
    end;
  end;
end;

procedure SettingsDialogPrim(FManager: PPanel);
type
  TData = record
    Status: Word;
    FullWide: Word;
    Layout: Word;
    DrvSize: Word;
    DrvAlign: Word;
    BarOpt: Word;
    BarAlign: Word;
    BoxStyle: Word;
  end;
const
  ssBrief = 0;
  ssBriefLong = 1;
  ssFull = 2;
  ssFullLong = 3;
  ssFullDescr = 4;
  ssTree = 5;
  ssInfo = 6;
  ssQuickView = 7;
  ssLongDescr = 8;

  slTitles = $0001;
  slInfoPane = $0002;
  slSelBox = $0004;
  slDriveSel = $0008;
  slDrivePanel = $0010;
  slHidden = $0020;
  slExecutable = $0040;
  slDirSizes = $0080;
  slUnfold = $0100;

  sbEnable = 1;
  sbAlways = 2;
  sbMax = 4;

  sbLeft = 0;
  sbRight = 1;
var
  DoReread: Boolean;
  C, W, W1, W2: Word;
  D: PDialog;
  Control: PView;
  P: PDriveSelector;
  Panel: PPanel;
  R: TRect;
  Data: TData;
  S: FNameStr;

procedure ToggleRereadBit(var Dest: Word;
  SrcMask, DstMask: Word; RereadCondition: Boolean);
begin
  if (W and SrcMask <> 0) <> (W2 and SrcMask <> 0) then
  begin
    if W and SrcMask <> 0 then Dest := Dest or DstMask
    else Dest := Dest and not DstMask;
    DoReread := RereadCondition;
  end;
end;

procedure SetW(APanel: PPanel);
begin
  with APanel^ do
  begin
    if Status = stBrief then
      if Settings and seLongNames <> 0 then W1 := ssBriefLong
      else W1 := ssBrief
    else if Status = stFull then
      if Settings and seLongNames <> 0 then W1 := ssFullLong
      else if Options and ofFilesBBS <> 0 then W1 := ssFullDescr
      else W1 := ssFull
    else W1 := Status + 3;

    W2 := 0;
    if Settings and seMaxi = 0 then W2 := W2 or slTitles;
    if State and sfMiniStatus <> 0 then W2 := W2 or slInfoPane;
    if Settings and seSepSelInfo <> 0 then W2 := W2 or slSelBox;
    if Settings and seDriveSelector <> 0 then W2 := W2 or slDriveSel;
    if State and sfDrivePanel <> 0 then W2 := W2 or slDrivePanel;
    if State and sfShowHidden <> 0 then W2 := W2 or slHidden;
    if State and sfExOnly <> 0 then W2 := W2 or slExecutable;
    if Settings and seCalcDirSize <> 0 then W2 := W2 or slDirSizes;
    if Settings and seUnfold <> 0 then W2 := W2 or slUnfold;
  end;
end;

label
  ApplySettings;
begin
  with FManager^ do
  begin
    if State and sfVisible = 0 then Exit;
    if Which = pnLeft then S := 'Left' else S := 'Right';
    R.Assign(0, 0, 75, 22);
    D := New(PDialog, Init(R, S + ' panel settings'));
    with D^ do
    begin
      Options := Options or ofCentered;
      HelpCtx := hcPanelSettings;

      R.Assign(3, 3, 31, 12);
      Control := New(PRadioButtons, Init(R,
	NewSItem('~B~rief',
	NewSItem('B~r~ief long names',
	NewSItem('~F~ull',
	NewSItem('Full ~l~ong names',
	NewSItem('~N~ames and descriptions',
	NewSItem('~T~ree',
	NewSItem('~I~nfo',
	NewSItem('~Q~uick view',
	NewSItem('Long descri~p~tions', nil)))))))))));
      Insert(Control);
      R.Assign(2, 2, 31, 3);
      Insert(New(PLabel, Init(R, 'Panel status', Control)));

      R.Assign(21, 5, 31, 6);
      Control := New(PCheckBoxes, Init(R, NewSItem('Wide', nil)));
      Insert(Control);

      R.Assign(33, 3, 72, 12);
      Control := New(PCheckBoxes, Init(R,
        NewSItem('Enable colu~m~n titles at the top',
        NewSItem('Enable inf~o~ pane at the bottom',
        NewSItem('Enable ~s~election info box',
        NewSItem('Display ~D~rive selector',
        NewSItem('Include Drive panel item (~:~)',
        NewSItem('Show ~h~idden files and directories',
        NewSItem('Display e~x~ecutable files only',
        NewSItem('Display directory si~z~es',
        NewSItem('~U~nfold subdirectories', nil)))))))))));
      Insert(Control);
      R.Assign(32, 2, 72, 3);
      Insert(New(PLabel, Init(R, 'Panel layout', Control)));

      R.Assign(3, 14, 31, 15);
      Control := New(PCheckBoxes, Init(R,
        NewSItem('Disable double~-~spacing', nil)));
      Insert(Control);
      R.Assign(2, 13, 31, 14);
      Insert(New(PLabel, Init(R, 'Drive selector size', Control)));

      R.Assign(33, 14, 72, 15);
      Control := New(PRadioButtons, Init(R,
        NewSItem('L~e~ft',
        NewSItem('~C~enter',
        NewSItem('Ri~g~ht', nil)))));
      Insert(Control);
      R.Assign(32, 13, 72, 14);
      Insert(New(PLabel, Init(R, 'Drive selector alignment', Control)));

      R.Assign(3, 17, 31, 20);
      Control := New(PCheckBoxes, Init(R,
        NewSItem('En~a~ble scroll bar',
        NewSItem('Display if inacti~v~e',
        NewSItem('Maximum height alwa~y~s', nil)))));
      Insert(Control);
      R.Assign(2, 16, 31, 17);
      Insert(New(PLabel, Init(R, 'Vertical scroll bar options', Control)));

      R.Assign(33, 17, 54, 18);
      Control := New(PRadioButtons, Init(R,
        NewSItem('Left',
        NewSItem('Right', nil))));
      Insert(Control);
      R.Assign(32, 16, 54, 17);
      Insert(New(PLabel, Init(R, 'Scroll bar alignment', Control)));

      R.Assign(56, 17, 72, 18);
      Control := New(PCheckBoxes, Init(R,
        NewSItem('Ne~w~ style', nil)));
      Insert(Control);
      R.Assign(55, 16, 72, 17);
      Insert(New(PLabel, Init(R, 'Info box', Control)));

      R.Assign(32, Size.Y - 3, 38, Size.Y - 1);
      StandardOkButton(R, D);
      R.Assign(38, Size.Y - 3, 53, Size.Y - 1);
      Insert(New(PButton, Init(R, 'Both panels', cmYes, bfNormal)));
      R.Assign(53, Size.Y - 3, 63, Size.Y - 1);
      StandardCancelButton(R, D);
      R.Assign(63, Size.Y - 3, 73, Size.Y - 1);
      StandardHelpButton(R, D);

      SelectNext(False);
    end;

    SetW(FManager);

    Data.Status := W1;
    Data.Layout := W2;
    Data.DrvSize := DrvSelSize;
    Data.DrvAlign := DrvSelAlignment;
    Data.BarOpt := 0;
    if Settings and sePanelBar <> 0 then
      Data.BarOpt := Data.BarOpt or sbEnable;
    if Settings and seBarAlways <> 0 then
      Data.BarOpt := Data.BarOpt or sbAlways;
    if Settings and seBarMax <> 0 then
      Data.BarOpt := Data.BarOpt or sbMax;
    if BarAlignment = baLeft then Data.BarAlign := sbLeft
    else Data.BarAlign := sbRight;
    if Settings and seOldInfoBox <> 0 then Data.BoxStyle := 0
    else Data.BoxStyle := 1;
    if Settings and seFullWide <> 0 then Data.FullWide := 1
    else Data.FullWide := 0;
  end;

  if FManager^.Opposite^.State and sfVisible = 0 then
    Application^.DisableCommands(BothCommands);
  C := Application^.ExecuteDialog(D, @Data, False);
  Application^.EnableCommands(BothCommands);
  if C <> cmCancel then
  begin
    Panel := FManager;
ApplySettings:
    with Panel^ do
    begin
      DoReread := Data.Status <> W1;
      W := Data.Layout;
      if W and slTitles <> 0 then Settings := Settings and not seMaxi
      else Settings := Settings or seMaxi;
      if W and slInfoPane <> 0 then State := State or sfMiniStatus
      else State := State and not sfMiniStatus;
      if W and slSelBox <> 0 then Settings := Settings or seSepSelInfo
      else Settings := Settings and not seSepSelInfo;
      if (W and slDriveSel <> 0) <> (W2 and slDriveSel <> 0) then
        ToggleDriveSelector;
      ToggleRereadBit(State, slDrivePanel, sfDrivePanel,
        not InArchive and (Data.Status < ssTree) and
          (Length(ListDir^) = 2) and (Options and ofValidate = 0));
      ToggleRereadBit(State, slHidden, sfShowHidden,
        (Data.Status < ssTree) and (Options and ofValidate = 0));
      ToggleRereadBit(State, slExecutable, sfExOnly,
        (Data.Status < ssTree) and (Options and ofValidate = 0));
      ToggleRereadBit(Settings, slDirSizes, seCalcDirSize,
        (Data.Status < ssTree) and (Options and ofValidate = 0) and
	(W2 and slUnfold = 0));
      ToggleRereadBit(Settings, slUnfold, seUnfold,
        (Data.Status < ssTree));

      DrvSelSize := Data.DrvSize;
      DrvSelAlignment := Data.DrvAlign;
      if Settings and seDriveSelector <> 0 then
      begin
        if Which = pnLeft then
          P := PDriveSelector(PPanelWindow(Owner)^.LeftSelector)
        else P := PDriveSelector(PPanelWindow(Owner)^.RightSelector);
        if P <> nil then P^.AdjustBounds;
      end;

      if Data.BarAlign = sbLeft then BarAlignment := baLeft
      else BarAlignment := baRight;

      if Data.BoxStyle = 0 then Settings := Settings or seOldInfoBox
      else Settings := Settings and not seOldInfoBox;
      if Data.FullWide <> 0 then Settings := Settings or seFullWide
      else Settings := Settings and not seFullWide;

      if Data.BarOpt and sbAlways <> 0 then
        Settings := Settings or seBarAlways
      else Settings := Settings and not seBarAlways;
      if Data.BarOpt and sbMax <> 0 then
        Settings := Settings or seBarMax
      else Settings := Settings and not seBarMax;
      if ((Data.BarOpt and sbEnable <> 0) and
          (Settings and sePanelBar = 0)) or
         ((Data.BarOpt and sbEnable = 0) and
          (Settings and sePanelBar <> 0)) then TogglePanelBar;

      if DoReread then
      begin
        W := Data.Status;
        if W = ssBrief then FilePanel(stBrief, False)
        else if W = ssBriefLong then FilePanel(stBrief, True)
        else if W = ssFull then
        begin
	  Options := Options and not ofFilesBBS;
          FilePanel(stFull, False);
        end
        else if W = ssFullLong then FilePanel(stFull, True)
        else if W = ssFullDescr then
        begin
          Options := Options or ofFilesBBS;
          FilePanel(stFull, False);
        end
        else if W = ssTree then Tree
        else if W = ssInfo then Info
        else if W = ssQuickView then QuickView
        else QuickDescr;
      end
      else
      begin
        FocusItem(Focused);
        PPanelWindow(Owner)^.Frame^.DrawView;
      end;
    end;
    if (C = cmYes) and (Panel = FManager) then
    begin
      Panel := Panel^.Opposite;
      if Panel^.State and sfVisible <> 0 then
      begin
        SetW(Panel);
        goto ApplySettings;
      end;
    end;
  end;
end;

procedure FindFileDlgPrim(FManager: PPanel);
var
  C: Word;
  I: Integer;
  D: PFindFileDialog;
  FR: PFindFileRec;
  Panel: PPanel;
  PS: PString;
  S, LS: FNameStr;

procedure SaveFound;
begin
  GetValidSwapDir(LS, False);
  LS := Concat(LS, 'FINDFILE.LST');
  D^.FindFileList^.WriteToList(LS, True);
end;

begin
  with FManager^ do
  begin
    D := New(PFindFileDialog, Init(FoundFiles));
    if Application^.ValidView(D) = nil then Exit;
    with D^.FindFileList^ do
      if (FoundFocused > 0) and (FoundFocused < Range) then
        FocusItem(FoundFocused);
    if TypeOf(Desktop^.Current^) <> TypeOf(TPanelWindow) then
    begin
      PS := Message(Desktop^.Current, evBroadcast, cmGetSource, nil);
      if PS <> nil then
      begin
        S := AddedSlash(JustPathName(PS^)) + '*.' + JustExtension(PS^);
        if Pos(' ', S) <> 0 then S := '"' + S + '"';
        D^.FileInput^.SetData(S);
      end;
      PS := Message(Desktop^.Current, evBroadcast, cmGetWord, nil);
      if PS <> nil then
      begin
        S := PS^;
        D^.TextInput^.SetData(S);
      end;
    end;
    C := Application^.ExecView(D);
    FoundFocused := D^.FindFileList^.Focused;
    if C <> cmCancel then with D^.FindFileList^ do
    begin
      FR := List^.At(Selected);
      List^.GetItemName(Selected, S);
      if C = cmRunItem then SaveFound;
    end;
    Dispose(D, Done);
    if C <> cmCancel then
    begin
      Panel := FManager;
      if Status = stTree then
        if Opposite^.Status = stTree then Exit
        else Panel := Opposite;
      Panel^.PrepareSwitch;
      if C = cmRunItem then
      begin
{
        DisposeStr(Panel^.ListDir);
        Panel^.ListDir := NewStr(ClearedSlash(JustPathName(S)));
}
        DisposeStrUMB(Panel^.ListDir);
        Panel^.ListDir := NewStrUMB(ClearedSlash(JustPathName(S)));
        IgnoreListSpaces := True;
        Message(Panel, evCommand, cmReadFileList, @LS);
      end;
      if FR^.Info <> 0 then IntoArchive(Panel, S, FR^.Info)
      else
      begin
        if C <> cmRunItem then
          Panel^.NewDir(ClearedSlash(JustPathName(S)), True);
        if FR^.Attr and Directory = 0 then Panel^.GetItemNum(S, I)
        else I := 0;
        Panel^.FocusItem(I);
      end;
      PWindow(Owner)^.Deiconize;
      Owner^.Show;
      Owner^.Select;
    end;
  end;
end;

const
  ItemIndex: Byte = 0;
  ItemColor: Byte = 0;

procedure FMSetIndexAndColorPrim(FManager: PPanel);
type
  TData = record
    IndexStr: String[3];
    ColorStr: String[3];
  end;
var
  Sel, Special: Boolean;
  Index, Color: Byte;
  I, N: Integer;
  SR: PPanelRec;
  FR: PFilesBBSRec;
  D: PDialog;
  Control: PView;
  R: TRect;
  Data: TData;
  S: FNameStr;

function GetNewItemPos(AList: PCollection; P: Pointer): Integer;
var
  II: Integer;
begin
  for II := 0 to AList^.Count - 1 do
    if AList^.At(II) = P then
    begin
      GetNewItemPos := II;
      Exit;
    end;
  GetNewItemPos := -1;
end;

procedure SetNewFields;
begin
  with FManager^ do
  begin
    if Status = stTree then PTreeRec(SR)^.Color := ItemColor
    else
    begin
      if Data.IndexStr <> '' then SR^.Index := ItemIndex;
      if Data.ColorStr <> '' then SR^.Color := ItemColor;
      List^.AtDelete(I);
      List^.Insert(SR);
      if FilesBBS^.Count > I then
      begin
        FR := FilesBBS^.At(I);
        FilesBBS^.AtDelete(I);
        N := GetNewItemPos(List, SR);
        if N <> -1 then FilesBBS^.AtInsert(N, FR)
        else FreeMem(FR, SizeOf(TFilesBBSRec));
      end;
    end;
  end;
end;

begin
  with FManager^ do
  begin
    if (List^.Count = 0) or (Status > stTree) then Exit;
    Sel := (SelCount > 0) and (Settings and seIgnoreSelection = 0);
    if Sel then S := 'Selected files'
    else
    begin
      SR := List^.At(Focused);
      AddNameExt('', SR, S);
    end;
    Special := not Sel and
      ((SR^.Attr and VolumeID <> 0) or
       (SR^.Name[1] in [':', '.']));
    R.Assign(0, 0, 27, 9);
    D := InitSimpleDialog(R, S, hcNewGroup);
    with D^ do
    begin
      Options := Options or ofCentered;
      R.Assign(9, 2, Size.X - 3, 3);
      Control := New(PCInputLine, Init(R, 3, 0, 255));
      Insert(Control);
      R.Assign(2, 2, 9, 3);
      Insert(New(PLabel, Init(R, '~I~ndex', Control)));
      R.Assign(9, 4, Size.X - 3, 5);
      Control := New(PCInputLine, Init(R, 3, 0, 255));
      Insert(Control);
      R.Assign(2, 4, 9, 5);
      Insert(New(PLabel, Init(R, '~C~olor', Control)));
      if (Status <> stTree) and not Special then SelectNext(True);
    end;
    if (Status = stTree) or Special then Data.IndexStr := ''
    else if not Sel then Str(SR^.Index, Data.IndexStr)
    else if ItemIndex = 0 then Data.IndexStr := ''
    else Str(ItemIndex, Data.IndexStr);
    if not Sel then
      if Status = stTree then
        Data.ColorStr := '$' + HexB(PTreeRec(SR)^.Color)
      else Data.ColorStr := '$' + HexB(SR^.Color)
    else if ItemColor = 0 then Data.ColorStr := ''
    else Data.ColorStr := '$' + HexB(ItemColor);
    if Application^.ExecuteDialog(D, @Data, False) = cmCancel then Exit;
    TrimSt(Data.IndexStr);
    TrimSt(Data.ColorStr);
    if (Data.IndexStr = '') and (Data.ColorStr = '') then Exit;
    Val(Data.IndexStr, ItemIndex, I);
    Val(Data.ColorStr, ItemColor, I);
    GetItemStr(Focused, S);
    if Sel then
    begin
      DrawStatusLine('Rearranging the Panel file list.');
      I := List^.Count - 1;
      while I >= 0 do
      begin
        SR := PPanelRec(List^.At(I));
        if (SR <> nil) and SR^.Selected then
        begin
          SetSelect(SR, False);
          SetNewFields;
        end
        else Dec(I);
      end;
    end
    else
    begin
      I := Focused;
      if SR^.Selected and (ItemColor = 0) then SetSelect(SR, False);
      SetNewFields;
    end;
    SetRange(List^.Count);
    GetItemNum(S, I);
    FocusItem(I);
  end;
end;

end.