{$I-,X+,F+,O+}
unit DiskBase;

interface

uses Dos, Objects, Drivers, Views, Dialogs, BarWin;

type
  TCopyNameData = record
    ToName: FNameStr;
    Options: Word;
    DirFilter: String[12];
    NewMask: String[12];
  end;

  TShiftCopyNameData = record
    FromName, ToName: FNameStr;
    Options: Word;
  end;

  PArrowDialog = ^TArrowDialog;
  TArrowDialog = object(TDialog)
    FirstButton: PButton;
    LastButton: PButton;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SelectClosest(ADirection: Word);
  end;

  PDriveDialog = ^TDriveDialog;
  TDriveDialog = object(TArrowDialog)
    RedirList: PCollection;
    RedirName: ^FNameStr;
    procedure EndModal(Command: Word); virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PCopyDialog = ^TCopyDialog;
  TCopyDialog = object(TDialog)
    InputLine: PInputLine;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PShiftCopyDialog = ^TShiftCopyDialog;
  TShiftCopyDialog = object(TDialog)
    FromInput, ToInput: PInputLine;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PCopyBarWindow = ^TCopyBarWindow;
  TCopyBarWindow = object(TBarWindow)
    constructor Init(const FromName, ToName: FNameStr;
      AVolume: Longint; MoveCopy, CopyLeft: Boolean);
    procedure UpdateSubViews(const FromName, ToName: FNameStr;
      AVolume: Longint; MoveCopy, CopyLeft: Boolean);
  end;

  PStatInfo = ^TStatInfo;
  TStatInfo = object(TStaticText)
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
  end;

  TStatTimeStr = String[9];

  PCopyStatWindow = ^TCopyStatWindow;
  TCopyStatWindow = object(TBarWindow)
    TotalInfo, CopiedInfo, RemainingInfo,
    PercentInfo, RateInfo, TimeInfo: PStatInfo;
    InitTime, PrevTime, PrevTitlePercent: Longint;
    constructor Init(CopyLeft: Boolean);
    procedure UpdateSubViews;
  end;

  PVarLabel = ^TVarLabel;
  TVarLabel = object(TLabel)
    VarPos: Byte;
    constructor Init(var Bounds: TRect; const AText: String;
      ALink: PView; AVarPos: Byte);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

const
  cmAppend    = 65;
  cmNew       = 66;
  cmAppendAll = 67;
  cmResume    = 68;
  cmResumeAll = 69;

  CopyBarWindow: PCopyBarWindow = nil;
  CopyStatWindow: PCopyStatWindow = nil;

function DeviceDest(const AName: FNameStr): FNameStr;
function InitCopyDialog(var Bounds: TRect; const ALabel: FNameStr;
  DoubleButtons, DisableFilter: Boolean): PCopyDialog;
function InitDirCopyDialog(var Bounds: TRect; const ALabel: FNameStr;
  DisableFilter: Boolean): PCopyDialog;
function InitShiftCopyDialog(var Bounds: TRect): PShiftCopyDialog;
function InitRenMovDialog(var Bounds: TRect; const ALabel: FNameStr;
  DoubleButtons, DisableFilter: Boolean): PCopyDialog;
function InitDirRenMovDialog(var Bounds: TRect; const ALabel: FNameStr;
  DisableFilter: Boolean): PCopyDialog;
function InitShiftRenMovDialog(var Bounds: TRect): PShiftCopyDialog;
procedure SelectDriveDialog(const ALabel: FNameStr;
  ALocation: Byte; ACurDrive: Char; var S: FNameStr);
procedure ValidNames(var Source, Dest: FNameStr);
function CopySkipDialog(const FromName, ToName: FNameStr;
  FromTime, ToTime: Longint; FromSize, ToSize: Real): Word;
function DelSkipDialog(const AName, AIden: FNameStr): Word;
function DiskErrorDialog(const ACaption, ALabel: String): Word;
procedure OpenCopyBarWindow(const FromName, ToName: FNameStr;
  AVolume: Longint; MoveCopy, CopyLeft: Boolean);
procedure OpenCopyStatWindow(CopyLeft: Boolean);
procedure DoneFileOperation;
{ Added 2005.08.30 to support regexp file operations }
procedure DisposeFileRegExp;
procedure PreprocessFileRegExp(var S: String);

implementation

uses App, Gauges, FileMngr, DirPrim, DiskPrim, TreeDlg, Options, StrCol,
  FMDialog, DrvList, PanelRec, HistList, History, HistWin, UnixMask,
  HeapUMB, RegExp, LFN, DosTools, Timer, MsgBox, TPString, Consts, Commands,
  Defaults;

function DeviceDest(const AName: FNameStr): FNameStr;
var
  C: Char;
  S: FNameStr;

function ContainsName(const Name: FNameStr): Boolean;
var
  I: Integer;
  SS: FNameStr;
begin
  I := Pos(Name, S);
  if I <> 0 then
  begin
    SS := S;
    repeat
      if ((I = 1) or (SS[I - 1] in ['\', ':'])) and
         ((Length(SS) < I + Length(Name)) or
          (SS[I + Length(Name)] = '\')) then
      begin
        ContainsName := True;
        DeviceDest := Name;
        Exit;
      end;
      Delete(SS, 1, I + Length(Name));
      I := Pos(Name, SS);
    until I = 0;
  end;
  ContainsName := False;
end;

begin
  S := StUpcase(AName);
  if ContainsName('AUX') or ContainsName('CON') or
     ContainsName('NUL') or ContainsName('PRN') then Exit;
  if Pos('COM', S) <> 0 then
    for C := '1' to '8' do
      if ContainsName('COM' + C) then Exit;
  if Pos('LPT', S) <> 0 then
    for C := '1' to '8' do
      if ContainsName('LPT' + C) then Exit;
  DeviceDest := '';
end;

procedure ValidNames(var Source, Dest: FNameStr);
var
  C: String[1];
  SourceExt, DestExt, SourceName, DestName, SourceDir, DestDir, N: String;
begin
  Dest := lFExpand(Dest);
  lGetShortFileName(Source, SourceName);
  if (CompUCString(Source, Dest) <> Equal) and
     (CompUCString(SourceName, Dest) <> Equal) and
      DirPresent(Dest) and not DirPresent(Source) then
    Dest := AddedSlash(Dest);
  lFSplit(Source, SourceDir, SourceName, SourceExt);
  lFSplit(Dest, DestDir, DestName, DestExt);
  if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
    LFNDisabled(Dest) then
  begin
    N := JustFileName(Dest);
    if (N = '') or IsWild(N) or
       (CompUCString(JustFileName(Source), N) = Equal) then
    begin
      lGetShortFileName(Source, Source);
      lFSplit(Source, SourceDir, SourceName, SourceExt);
      if not IsWild(N) then
      begin
        DestName := '';
        DestExt := '';
      end;
    end;
  end;

{ Fixed 10.31.03 to support .ext filenames }
{
  if DestExt = '' then
    if DestName = '' then DestExt := '*' else
  else System.Delete(DestExt, 1, 1);
  if DestName = '' then DestName := '*';
}

  if (DestName = '') and (DestExt = '') then
  begin
    DestName := '*';
    DestExt := '*';
  end
  else if DestExt <> '' then System.Delete(DestExt, 1, 1);
  if SourceExt <> '' then System.Delete(SourceExt, 1, 1);
  ExpandWildCards(DestName, DestExt, SourceName, SourceExt);
  if DestExt = '' then C := '' else C := '.';
  Dest := Concat(DestDir, DestName, C, DestExt);
end;

function CopySkipDialog(const FromName, ToName: FNameStr;
  FromTime, ToTime: Longint; FromSize, ToSize: Real): Word;
var
  NameWidth: Byte;
  C, Item: Word;
  D: PDialog;
  R: TRect;
  DT: DateTime;
  S, SS: String;

function CompareResult: Word;
var
  lC: lCompareType;
begin
  lC := lCompareSizes(FromSize, ToSize);
  if FromTime > ToTime then
    if lC = lLess then Item := fcNewerLonger
    else if lC = lGreater then Item := fcNewerShorter
    else Item := fcNewerSame
  else if FromTime < ToTime then
    if lC = lLess then Item := fcOlderLonger
    else if lC = lGreater then Item := fcOlderShorter
    else Item := fcOlderSame
  else
    if lC = lLess then Item := fcSameLonger
    else if lC = lGreater then Item := fcSameShorter
    else Item := fcSame;
  C := (FileCompareAction shr (Item * 3)) and 7;
  if (CopyStatus = dsAll) and (C <> faSkip) then C := faOverwrite;
  case C of
    faResume: CompareResult := cmResume;
    faOverwrite: CompareResult := cmYes;
    faAppend: CompareResult := cmAppend;
    faNew: CompareResult := cmNew;
    faSkip: CompareResult := cmNo;
    else CompareResult := $FFFF;
  end;
end;

procedure GetInfoStr(const Name: FNameStr; Time: Longint; Size: Real);
begin
  UnpackTime(Time, DT);
  with DT do
  begin
    S := FormatDateStr(Year, Month, Day);
    SS := FormatTimeStr(Hour, Min, Sec);
    System.Delete(SS, 6, 3);
  end;
  S := '  ' + S + ' ' + SS + ' ';
  FormatFloatBytes(SS, Size, 100000000);
  S := Pad(TrimmedName(Name, NameWidth), NameWidth) +
    S + LeftPad(SS, 11) + ' bytes';
end;

begin
  if FileExistsAction = feOverwrite then CopySkipDialog := cmOk
  else if FileExistsAction = feSkip then CopySkipDialog := cmDefault
  else
  begin
    if FileExistsAction = feCompare then
    begin
      C := CompareResult;
      if C <> $FFFF then
      begin
        CopySkipDialog := C;
        Exit;
      end;
    end;
    if Length(FromName) > Length(ToName) then
      NameWidth := Length(FromName)
    else NameWidth := Length(ToName);
    if NameWidth > 29 then NameWidth := 29;
    R.A.X := 0; R.B.X := 78;
    if CopyBarWindow = nil then R.A.Y := 0
    else R.A.Y := CopyBarWindow^.Origin.Y + 5;
    R.B.Y := R.A.Y + 14;
    D := New(PArrowDialog, Init(R, 'Warning'));
    with D^ do
    begin
      Options := Options or ofCenterX;
      HelpCtx := hcCopySkipDialog;
      if CopyBarWindow = nil then Options := Options or ofCenterY;
      R.Assign(3, 2, Size.X - 3, 3);
      Insert(New(PStaticText, Init(R,
        ^C'The file ' + TrimmedName(ToName, 46) + ' already exists.')));
      GetInfoStr(FromName, FromTime, FromSize);
      R.Assign(3, 4, Size.X - 3, 5);
      Insert(New(PStaticText, Init(R, ^C'Source: ' + S)));
      GetInfoStr(ToName, ToTime, ToSize);
      R.Assign(3, 5, Size.X - 3, 6);
      Insert(New(PStaticText, Init(R, ^C'Exists: ' + S)));
      R.Assign(3, 7, Size.X - 3, 8);
      Insert(New(PStaticText, Init(R,
        ^C'Do you wish to write over the old file ?')));
      R.Assign(2, Size.Y - 5, 15, Size.Y - 1);
      Insert(New(PButton, Init(R, '~O~verwrite', cmYes, bfDefault)));
      Inc(R.A.X, 14); Inc(R.B.X, 8); Dec(R.B.Y, 2);
      Insert(New(PButton, Init(R, '~A~ll', cmOk, bfNormal)));
      Inc(R.A.X, 8); Inc(R.B.X, 11);
      Insert(New(PButton, Init(R, 'A~p~pend', cmAppend, bfNormal)));
      Inc(R.A.X, 11); Inc(R.B.X, 15);
      Insert(New(PButton, Init(R, 'Appen~d~ all', cmAppendAll, bfNormal)));
      Inc(R.A.X, 15); Inc(R.B.X, 11);
      Insert(New(PButton, Init(R, '~R~esume', cmResume, bfNormal)));
      Inc(R.A.X, 11); Inc(R.B.X, 15);
      Insert(New(PButton, Init(R, 'Resu~m~e all', cmResumeAll, bfNormal)));
      R.Assign(16, Size.Y - 3, 23, Size.Y - 1);
      Insert(New(PButton, Init(R, '~N~ew', cmNew, bfNormal)));
      Inc(R.A.X, 8); Inc(R.B.X, 11);
      Insert(New(PButton, Init(R, '~S~kip', cmNo, bfNormal)));
      Inc(R.A.X, 11); Inc(R.B.X, 15);
      Insert(New(PButton, Init(R, 'Sk~i~p all', cmDefault, bfNormal)));
      Inc(R.A.X, 15); Inc(R.B.X, 11);
      StandardCancelButton(R, D);
      Inc(R.A.X, 11); Inc(R.B.X, 15);
      StandardHelpButton(R, D);
      SelectNext(False);
    end;
    DisableIgnoreAllReset := True;
    CopySkipDialog := Application^.ExecView(D);
    Dispose(D, Done);
    DisableIgnoreAllReset := False;
  end;
end;

function DelSkipDialog(const AName, AIden: FNameStr): Word;
var
  D: PDialog;
  R: TRect;
begin
  R.Assign(0, 0, 69, 9);
  D := New(PArrowDialog, Init(R, 'Warning'));
  with D^ do
  begin
    HelpCtx := hcDeleteSkipDialog;
    Options := Options or ofCentered;
    GetExtent(R);
    R.Grow(-3, -1); Inc(R.A.Y);
    Insert(New(PStaticText, Init(R,
      ^C'The ' + AIden + ' ' + TrimmedName(
      AName, Size.X - Length(AIden) - 11) + #13 +
      ^C'is marked ''Read only'' or ''Hidden''.'#13 +
      ^C'Do you still wish to delete it ?')));
    R.Assign(2, Size.Y - 3, 14, Size.Y - 1);
    Insert(New(PButton, Init(R, '~D~elete', cmYes, bfDefault)));
    Inc(R.A.X, 13); Inc(R.B.X, 13);
    Insert(New(PButton, Init(R, '~A~ll', cmOk, bfNormal)));
    Inc(R.A.X, 13); Inc(R.B.X, 13);
    Insert(New(PButton, Init(R, '~S~kip', cmNo, bfNormal)));
    Inc(R.A.X, 13); Inc(R.B.X, 13);
    Insert(New(PButton, Init(R, 'Sk~i~p all', cmDefault, bfNormal)));
    Inc(R.A.X, 13); Inc(R.B.X, 13);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  DisableIgnoreAllReset := True;
  DelSkipDialog := Application^.ExecView(D);
  Dispose(D, Done);
  DisableIgnoreAllReset := False;
end;

function DiskErrorDialog(const ACaption, ALabel: String): Word;
var
  D: PDialog;
  R: TRect;
begin
  R.Assign(0, 0, 69, 8);
  D := New(PArrowDialog, Init(R, ACaption + ' error'));
  with D^ do
  begin
    HelpCtx := hcDiskErrorDialog;
    Options := Options or ofCentered;
    GetExtent(R);
    R.Grow(-3, -1); Inc(R.A.Y);
    Insert(New(PStaticText, Init(R, ALabel)));
    R.Assign(2, Size.Y - 3, 11, Size.Y - 1);
    Insert(New(PButton, Init(R, '~R~etry', cmYes, bfDefault)));
    Inc(R.A.X, 16); Inc(R.B.X, 17);
    Insert(New(PButton, Init(R, '~I~gnore', cmNo, bfNormal)));
    Inc(R.A.X, 17); Inc(R.B.X, 21);
    Insert(New(PButton, Init(R, 'Ignore ~a~ll', cmDefault, bfNormal)));
    Inc(R.A.X, 21); Inc(R.B.X, 17);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  DisableIgnoreAllReset := True;
  DiskErrorDialog := Application^.ExecView(D);
  Dispose(D, Done);
  DisableIgnoreAllReset := False;
end;

procedure TArrowDialog.HandleEvent(var Event: TEvent);
begin
  TDialog.HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    case CtrlToArrow(Event.KeyCode) of
      kbRight: SelectNext(False);
      kbLeft: SelectNext(True);
      kbUp, kbDown: SelectClosest(CtrlToArrow(Event.KeyCode));
      kbPgUp, kbHome: if FirstButton <> nil then FirstButton^.Select;
      kbPgDn, kbEnd: if LastButton <> nil then LastButton^.Select;
      else Exit;
    end;
    Event.What := evNothing;
  end
  else if (Event.What = evCommand) and
    ((Event.Command = cmDefault) or
     (Char(Event.Command) in ['A'..'\'])) then
  begin
    EndModal(Event.Command);
    Event.What := evNothing;
  end;
end;

procedure TArrowDialog.SelectClosest(ADirection: Word);
var
  X, Y: Integer;
  V: PView;

function IsClosest(P: PView): Boolean; far;
begin
  IsClosest := (P^.Options and ofSelectable <> 0) and
    (P^.Origin.X = X) and (P^.Origin.Y = Y);
end;

begin
  X := Current^.Origin.X;
  Y := Current^.Origin.Y;
  if ADirection = kbUp then Dec(Y, 2) else Inc(Y, 2);
  V := FirstThat(@IsClosest);
  if V <> nil then V^.Select;
end;

procedure TDriveDialog.EndModal(Command: Word);

function GetRedirName: Boolean;
var
  I: Integer;
  P: PHistoryRec;
  W: PHistoryWindow;
  R: TRect;
  S: String[31];
begin
  RedirName^ := '';
  for I := RedirList^.Count - 1 downto 0 do
  begin
{
    GetMem(P, SizeOf(THistoryRec));
    P^.StrPtr := NewStr(PString(RedirList^.At(I))^);
}
    GetMemUMB(P, SizeOf(THistoryRec));
    P^.StrPtr := NewStrUMB(PString(RedirList^.At(I))^);
    P^.Id := RedirHistoryId;
    if I < 9 then Byte(P^.Lock) := I + $31
    else P^.Lock := False;
    HistoryList^.Insert(P);
  end;
  S := 'Select redirected device entry';
  GetHistWinBounds(RedirHistoryID, S, R);
  W := New(PSpecialHistWindow, Init(R, RedirHistoryID));
  DisposeStr(W^.Title);
  W^.Title := NewStr(S);
  W^.Options := W^.Options or ofCentered;
  W^.HelpCtx := hcRedirList;
  if Application^.ValidView(W) <> nil then
  begin
    if Application^.ExecView(W) = cmOk then
      RedirName^ := W^.GetSelection;
    Dispose(W, Done);
  end;
  ClearHistoryId(RedirHistoryId);
  GetRedirName := RedirName^ <> '';
end;

begin
  if (Char(Command) = '\') and not GetRedirName then Exit;
  TArrowDialog.EndModal(Command);
end;

const
  CDriveDialog = #32#33#34#35#36#37#38#39#40#146#146#83#146#146#84;

function TDriveDialog.GetPalette: PPalette;
const
  P: String[Length(CDriveDialog)] = CDriveDialog;
begin
  GetPalette := @P;
end;

procedure TDriveDialog.HandleEvent(var Event: TEvent);
begin
  TArrowDialog.HandleEvent(Event);
  if ((Event.What = evKeyDown) and
      ((Event.KeyCode = kbAltGreat) or
       (Event.CharCode in ['.', '>', 'ž', 'î']))) or
     ((Event.What = evCommand) and
      (Event.Command = cmDriveSelector)) then
  begin
    if TypeOf(Current^) = TypeOf(TButton) then
      Event.InfoChar := PButton(Current)^.Title^[2]
    else Event.InfoChar := #0;
    DriveListDlg(Event.InfoChar);
    if RedisplayDriveDialog then EndModal(cmOk);
    Event.What := evNothing;
  end;
end;

procedure PrepareArcDlgEvent(D: PDialog; Dest: String);
var
  P: PString;
begin
  if D^.Title^[1] <> 'C' then Dest := Dest + #0;
  D^.EndModal(cmCancel);
  P := NewStr(Dest);
  Pending.What := evCommand;
  Pending.Command := cmArcCopyDlg;
  Pending.InfoPtr := P;
end;

procedure TCopyDialog.HandleEvent(var Event: TEvent);
var
  S: FNameStr;
begin
  TDialog.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmTree:
        begin
          InputLine^.GetData(S);
          TreeDialog(S);
          if S <> '' then
          begin
            S := AddedSlash(S);
            InputLine^.SetData(S);
            InputLine^.Select;
          end;
        end;
      cmFilter: OperationFilterDialog;
      cmFMOptions:
        begin
          InputLine^.GetData(S);
          TrimSt(S);
          if (S <> '') and (S[1] <> '/') and (Pos(':', S) > 2) then
            PrepareArcDlgEvent(@Self, InputLine^.Data^)
          else FMCopyOptions;
        end;
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

procedure TShiftCopyDialog.HandleEvent(var Event: TEvent);
var
  InputLine: PInputLine;
  S: FNameStr;
begin
  TDialog.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmTree:
        begin
          if FromInput^.State and sfSelected <> 0 then
            InputLine := FromInput
          else InputLine := ToInput;
          InputLine^.GetData(S);
          TreeDialog(S);
          if S <> '' then
          begin
            S := AddedSlash(S);
            InputLine^.SetData(S);
            InputLine^.Select;
          end;
        end;
      cmFilter: OperationFilterDialog;
      cmFMOptions:
        begin
          ToInput^.GetData(S);
          TrimSt(S);
          if (S <> '') and (S[1] <> '/') and (Pos(':', S) > 2) then
            PrepareArcDlgEvent(@Self, ToInput^.Data^)
          else FMCopyOptions;
        end;
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

procedure SingleCopyRenMovButtons(D: PDialog);
var
  R: TRect;
begin
  with D^ do
  begin
    R.Assign(17, Size.Y - 3, 25, Size.Y - 1);
    StandardOkButton(R, D);
    Inc(R.A.X, 9); Inc(R.B.X, 9);
    Insert(New(PButton, Init(R, 'T~r~ee', cmTree, bfNormal)));
    Inc(R.A.X, 9); Inc(R.B.X, 12);
    Insert(New(PButton, Init(R, '~O~ptions', cmFMOptions, bfNormal)));
    Inc(R.A.X, 12); Inc(R.B.X, 11);
    StandardCancelButton(R, D);
    Inc(R.A.X, 11); Inc(R.B.X, 9);
    StandardHelpButton(R, D);
  end;
end;

procedure DoubleCopyRenMovButtons(D: PDialog; DisableFilter: Boolean);
var
  B: PButton;
  R: TRect;
begin
  with D^ do
  begin
    R.Assign(3, Size.Y - 5, 13, Size.Y - 3);
    Insert(New(PButton, Init(R, 'T~r~ee', cmTree, bfNormal)));
    R.Assign(Size.X div 2 - 10, Size.Y - 5, Size.X div 2 + 9, Size.Y - 3);
    B := New(PButton, Init(R, '~A~dvanced filter', cmFilter, bfNormal));
    Insert(B);
    if DisableFilter then B^.State := B^.State or sfDisabled;
    R.Assign(Size.X - 14, Size.Y - 5, Size.X - 3, Size.Y - 3);
    Insert(New(PButton, Init(R, '~O~ptions', cmFMOptions, bfNormal)));

    R.Assign(3, Size.Y - 3, 13, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(Size.X div 2 - 5, Size.Y - 3, Size.X div 2 + 5, Size.Y - 1);
    StandardCancelButton(R, D);
    R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardHelpButton(R, D);
  end;
end;

procedure ConfCopyRenMovButtons(D: PDialog);
var
  R: TRect;
begin
  with D^ do
  begin
    R.Assign(3, Size.Y - 3, 13, Size.Y - 1);
    Insert(New(PButton, Init(R, '~Y~es', cmYes, bfDefault)));
    Inc(R.A.X, 13); Inc(R.B.X, 13);
    Insert(New(PButton, Init(R, '~A~ll', cmOk, bfNormal)));
    Inc(R.A.X, 13); Inc(R.B.X, 14);
    Insert(New(PButton, Init(R, '~N~o', cmNo, bfNormal)));
    Inc(R.A.X, 14); Inc(R.B.X, 13);
    StandardCancelButton(R, D);
    Inc(R.A.X, 13); Inc(R.B.X, 13);
    StandardHelpButton(R, D);
  end;
end;

procedure FilterMaskInputs(D: PDialog);
var
  Control: PView;
  H: PHistory;
  R: TRect;
begin
  with D^ do
  begin
    R.Assign(26, 5, 40, 6);
    Control := New(PInputLine, Init(R, 12));
    Insert(Control);
    H := StandardHistory(Control, MaskHistoryId);
    H^.HistoryPutFunc := UNIXPutHistoryFunc;
    H^.HistoryGetFunc := UNIXGetHistoryFunc;
    R.Assign(18, 5, 26, 6);
    Insert(New(PLabel, Init(R, '~F~ilter', Control)));

    R.Assign(Size.X - 20, 5, Size.X - 6, 6);
    Control := New(PInputLine, Init(R, 12));
    Insert(Control);
    H := StandardHistory(Control, MaskHistoryId);
    H^.HistoryPutFunc := UNIXPutHistoryFunc;
    H^.HistoryGetFunc := UNIXGetHistoryFunc;
    R.Assign(Size.X - 30, 5, Size.X - 20, 6);
    Insert(New(PLabel, Init(R, '~N~ew mask', Control)));
  end;
end;

function CopyRenMovDialog(var Bounds: TRect;
  const AHeader, ALabel: FNameStr; AHelpCtx: Word;
  DoubleButtons, DisableFilter: Boolean): PCopyDialog;
var
  P: Byte;
  C: PCheckBoxes;
  D: PCopyDialog;
begin
  D := New(PCopyDialog, Init(Bounds, AHeader));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := AHelpCtx;

    if Byte(DoubleButtons) = 2 then ConfCopyRenMovButtons(D)
    else if DoubleButtons then DoubleCopyRenMovButtons(D, DisableFilter)
    else SingleCopyRenMovButtons(D);

    Bounds.Assign(3, 3, Size.X - 6, 4);
    InputLine := New(PInputLine, Init(Bounds, 255));
    Insert(InputLine);
    StandardHistory(InputLine, FNameHistoryId);
    Bounds.Assign(2, 2, Size.X - 3, 3);
    if Upcase(ALabel[1]) = 'R' then P := 11 else P := 1;
    Insert(New(PVarLabel, Init(Bounds, ALabel, InputLine, P)));

    if Byte(DoubleButtons) <> 2 then
    begin
      Bounds.Assign(3, 5, 16, 6);
      C := New(PCheckBoxes, Init(Bounds, NewSItem('~S~ysCopy', nil)));
      if not CN_NT then C^.SetButtonState($01, False);
      Insert(C);
    end;

    InputLine^.Select;
  end;
  CopyRenMovDialog := D;
end;

function ShiftCopyRenMovDialog(var Bounds: TRect;
  const AHeader, ALabel: FNameStr; AHelpCtx: Word): PShiftCopyDialog;
var
  C: PCheckBoxes;
  D: PShiftCopyDialog;
begin
  D := New(PShiftCopyDialog, Init(Bounds, AHeader));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := AHelpCtx;

    DoubleCopyRenMovButtons(D, False);

    Bounds.Assign(3, 3, Size.X - 6, 4);
    FromInput := New(PInputLine, Init(Bounds, 255));
    Insert(FromInput);
    StandardHistory(FromInput, FNameHistoryId);
    Bounds.Assign(2, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(Bounds, ALabel, FromInput)));

    Bounds.Assign(3, 5, Size.X - 20, 6);
    ToInput := New(PInputLine, Init(Bounds, 255));
    Insert(ToInput);
    StandardHistory(ToInput, FNameHistoryId);
    Bounds.Assign(2, 4, Size.X - 20, 5);
    Insert(New(PLabel, Init(Bounds, '~t~o', ToInput)));

    Bounds.Assign(Size.X - 16, 5, Size.X - 3, 6);
    C := New(PCheckBoxes, Init(Bounds, NewSItem('~S~ysCopy', nil)));
    if not CN_NT then C^.SetButtonState($01, False);
    Insert(C);

    FromInput^.Select;
  end;
  ShiftCopyRenMovDialog := D;
end;

function InitCopyDialog(var Bounds: TRect;
  const ALabel: FNameStr;
  DoubleButtons, DisableFilter: Boolean): PCopyDialog;
begin
  InitCopyDialog := CopyRenMovDialog(
    Bounds, 'Copy', ALabel, hcCopyDialog,
    DoubleButtons, DisableFilter);
end;

function InitDirCopyDialog(var Bounds: TRect;
  const ALabel: FNameStr; DisableFilter: Boolean): PCopyDialog;
var
  D: PCopyDialog;
begin
  D := InitCopyDialog(Bounds, ALabel, True, DisableFilter);
  FilterMaskInputs(D);
  D^.InputLine^.Select;
  InitDirCopyDialog := D;
end;

function InitShiftCopyDialog(var Bounds: TRect): PShiftCopyDialog;
begin
  InitShiftCopyDialog := ShiftCopyRenMovDialog(
    Bounds, 'Copy', '~C~opy', hcShiftCopyDialog);
end;

function InitRenMovDialog(var Bounds: TRect;
  const ALabel: FNameStr;
  DoubleButtons, DisableFilter: Boolean): PCopyDialog;
begin
  InitRenMovDialog := CopyRenMovDialog(
    Bounds, 'Rename/Move', ALabel, hcRenMovDialog,
    DoubleButtons, DisableFilter);
end;

function InitDirRenMovDialog(var Bounds: TRect;
  const ALabel: FNameStr; DisableFilter: Boolean): PCopyDialog;
var
  D: PCopyDialog;
  Control: PView;
begin
  D := InitRenMovDialog(Bounds, ALabel, True, DisableFilter);
  FilterMaskInputs(D);
  D^.InputLine^.Select;
  InitDirRenMovDialog := D;
end;

function InitShiftRenMovDialog(var Bounds: TRect): PShiftCopyDialog;
begin
  InitShiftRenMovDialog := ShiftCopyRenMovDialog(
    Bounds, 'Rename/Move', 'Rename or ~m~ove', hcShiftRenMovDialog);
end;

procedure SelectDriveDialog(const ALabel: FNameStr;
  ALocation: Byte; ACurDrive: Char; var S: FNameStr);
var
  NumDrives, NumRows: Byte;
  Ch: Char;
  LoX, HiX: Integer;
  C: Word;
  D: PDriveDialog;
  Control, SelControl: PView;
  List: PStringsCollection;
  R: TRect;
  Drives: TDrivesArray;
label
  Loop;
begin
  if DriveListOptions and dlListNotLetter <> 0 then
  begin
    DriveListDlg(ACurDrive);
    if Pending.What = evKeyDown then
    begin
      Pending.What := evNothing;
      S := Pending.CharCode + ':';
    end
    else S := '';
    Exit;
  end;

Loop:
  RedisplayDriveDialog := False;
  GetDrives(NumDrives, Drives);
  List := New(PStringsCollection, Init(8, 8));
  GetRedirDevices(List);
  if List^.Count <> 0 then
  begin
    Drives['\'] := 1;
    Inc(NumDrives);
  end;
  Inc(NumDrives);
  NumRows := (NumDrives - 1) div 10 + 1;
  if ALocation = 0 then
  begin
    LoX := 2;
    HiX := LoX + 6 + NumDrives * 6;
    if HiX > 68 then HiX := 68
    else if HiX < 38 then HiX := 38;
  end
  else
  begin
    HiX := 78;
    LoX := HiX - 6 - NumDrives * 6;
    if LoX < 12 then LoX := 12
    else if LoX > 42 then LoX := 42;
  end;
  R.Assign(LoX, 5, HiX, 12 + (NumRows - 1) * 2);
  D := New(PDriveDialog, Init(R, 'Drive letter'));
  with D^ do
  begin
    if ALocation > 1 then Options := Options or ofCentered;
    HelpCtx := hcDriveDialog;

    LoX := (Size.X - CStrLen(ALabel)) div 2 - 1 + Byte(ALocation = 1);
    HiX := LoX + 1 + CStrLen(ALabel);
    R.Assign(LoX, 2, HiX, 3);
    Control := New(PLabel, Init(R, ALabel, nil));
    Control^.Options := Control^.Options and not ofSelectable;
    Insert(Control);
    SelControl := nil;
    LoX := Size.X div 2 - NumDrives * 3;
    if LoX < 3 then LoX := 3;
    HiX := LoX + 5;
    R.Assign(LoX, 4, HiX, 6);
    for Ch := 'A' to '\' do
    if Drives[Ch] = 1 then
    begin
      Control := New(PButton, Init(
        R, '~' + Ch + '~' , Ord(Ch), bfNormal));
      if Ch = ACurDrive then SelControl := Control;
      Insert(Control);
      if FirstButton = nil then FirstButton := PButton(Control);
      Inc(R.A.X, 6); Inc(R.B.X, 6);
      if R.B.X > Size.X - 3 then
      begin
        R.A.X := Size.X div 2 - NumDrives * 3;
        if R.A.X < 3 then R.A.X := 3;
        R.B.X := R.A.X + 5; Inc(R.A.Y, 2); Inc(R.B.Y, 2);
      end;
    end;
    LastButton := New(PButton, Init(R, '~.~' , cmDriveSelector, bfDefault));
    Insert(LastButton);
    RedirList := List;
    RedirName := @S;
    if SelControl <> nil then SelControl^.Select;
  end;
  S := '';
  C := Application^.ExecuteDialog(D, nil, True);
  if (C <> cmCancel) and (S = '') then S := Char(C) + ':';
  Dispose(List, Done);
  if (C = cmOk) and RedisplayDriveDialog then goto Loop;
end;

procedure SetBarBounds(var Bounds: TRect; const Name: FNameStr);
var
  I: Integer;
begin
  I := Length(Name) + 4;
  if I < 36 then I := 36
  else if I > 78 then I := 78
  else if I > ScreenWidth - 2 then I := ScreenWidth - 2;
  Bounds.Assign(ScreenWidth div 2 - I div 2, ScreenHeight div 2 - 8,
    ScreenWidth div 2 + I div 2 + Byte(Odd(I)), ScreenHeight div 2 - 1);
end;

function GetCopyBarTitle(MoveCopy: Boolean): TTitleStr;
begin
{ Added 05-12-03 to support file splitting }
  if SplitCopy then GetCopyBarTitle := 'Split'
  else if CopyStatus in AppendAllSet then GetCopyBarTitle := 'Append'
  else if CopyStatus in ResumeAllSet then GetCopyBarTitle := 'Resume'
  else if MoveCopy then GetCopyBarTitle := 'Move'
  else GetCopyBarTitle := 'Copy';
end;

procedure TStatInfo.Draw;
var
  Color: Word;
  B: TDrawBuffer;
begin
  Color := GetColor($0201);
  MoveChar(B[0], ' ', Color, Size.X);
  if Text <> nil then MoveCStr(B[0], Text^, Color);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TStatInfo.GetPalette: PPalette;
const
  P: String[2] = #6#1;
begin
  GetPalette := @P;
end;

constructor TCopyBarWindow.Init(const FromName, ToName: FNameStr;
  AVolume: Longint; MoveCopy, CopyLeft: Boolean);
var
  R: TRect;
begin
  SetBarBounds(R, ToName);
  TWindow.Init(R, GetCopyBarTitle(MoveCopy), wnNoNumber);
  Options := (Options or ofCenterX) and not (ofSelectable + ofTopSelect);
  GrowMode := gfGrowHiX + gfExplode;
  Flags := wfMove;
  Frame^.State := Frame^.State or sfActive;

  R.Assign(2, 1, Size.X - 2, 5);
  NotReady := New(PStaticText, Init(R, ''));
  NotReady^.GrowMode := gfGrowHiX;
  Insert(NotReady);

  R.Assign(2, 5, Size.X - 2, 6);
  Bar := New(PBarView, Init(R, AVolume, CopyLeft));
  Bar^.GrowMode := gfGrowHiX;
  Insert(Bar);

  UpdateSubViews(FromName, ToName, AVolume, MoveCopy, CopyLeft);
end;

procedure TCopyBarWindow.UpdateSubViews(const FromName, ToName: FNameStr;
  AVolume: Longint; MoveCopy, CopyLeft: Boolean);
var
  R: TRect;
  S: TTitleStr;
begin
  SetBarBounds(R, ToName);
  S := GetCopyBarTitle(MoveCopy);
  if S <> Title^ then
  begin
    DisposeStr(Title);
    Title := NewStr(S);
    Frame^.DrawView;
  end;
{ Added 05-12-03 to support file splitting }
  if SplitCopy then S := 'Splitt'
  else if S[1] in ['M', 'R'] then Dec(S[0]);
  with NotReady^ do
  begin
    DisposeStr(Text);
    Text := NewStr(^C + S + 'ing the file'#13^C + FromName +
      #13^C'to'#13^C + TrimmedName(ToName, R.B.X - R.A.X - 4));
    DrawView;
  end;
  with Bar^ do
  begin
    Volume := AVolume;
    Count := 0;
    Width := 0;
    Left := CopyLeft;
    DrawView;
  end;
  Locate(R);
end;

constructor TCopyStatWindow.Init(CopyLeft: Boolean);
var
  Y: Integer;
  R: TRect;
begin
  if CopyBarWindow = nil then Y := ScreenHeight div 2 - 5
  else Y := ScreenHeight div 2;
  R.Assign(0, Y, 71, Y + 10);
  TWindow.Init(R, 'Copy progress statistics', wnNoNumber);
{ Fixed 2006.03.11 [workaround for SysCopy root crash] }
{  Options := (Options or ofCenterX) and not (ofSelectable + ofTopSelect)};
  Options := Options or ofCenterX;
  if NoModalWindows then State := State or sfModal
  else Options := Options and not (ofSelectable + ofTopSelect);

  GrowMode := gfExplode;
  Flags := 0;
  Frame^.State := Frame^.State or sfActive;

  R.Assign(2, 1, Size.X - 2, 2);
  TotalInfo := New(PStatInfo, Init(R, ''));
  Insert(TotalInfo);

  R.Assign(2, 2, Size.X - 2, 3);
  CopiedInfo := New(PStatInfo, Init(R, ''));
  Insert(CopiedInfo);

  R.Assign(2, 3, Size.X - 2, 4);
  RemainingInfo := New(PStatInfo, Init(R, ''));
  Insert(RemainingInfo);

  R.Assign(Size.X div 2 - 3, 4, Size.X div 2 + 7, 5);
  PercentInfo := New(PStatInfo, Init(R, ''));
  Insert(PercentInfo);

  R.Assign(2, 5, Size.X - 2, 6);
  Bar := New(PBarView, Init(R, 0, CopyLeft));
  Insert(Bar);

  R.Assign(Size.X div 2 - 18, 6, Size.X div 2 + 14, 7);
  RateInfo := New(PStatInfo, Init(R, ''));
  Insert(RateInfo);

  R.Assign(2, 8, Size.X - 2, 9);
  TimeInfo := New(PStatInfo, Init(R, ''));
  Insert(TimeInfo);

  InitTime := MemL[$40:$6C];
{ Added 2005.12.28 }
  PrevTitlePercent := -1;

  UpdateSubViews;
end;

procedure TicksToTimeStr(L: Longint; var S: TStatTimeStr);
type
  TFormatTimeRec = record
    Hour, Min, Sec: Longint;
  end;
var
  R: Real;
  FTR: TFormatTimeRec;
  SS: String;
begin
  R := L * 0.055;
  if L < 0 then S := ''
  else if R >= 3600000 then
  begin
    Str((R / (3600 * 24)):4:0, S);
    TrimSt(S);
    S := S + ' days';
  end
  else
  begin
    L := Trunc(R);
    with FTR do
    begin
      Hour := L div 3600;
      Dec(L, Hour * 3600);
      Min := L div 60;
      Dec(L, Min * 60);
      Sec := L;
    end;
    FormatStr(SS, '%03d:%02d:%02d', FTR);
    S := SS;
  end;
end;

procedure UpdateInfo(P: PStatInfo; const InfoText: String; var Params);
var
  S: String;
begin
  FormatStr(S, InfoText, Params);
  DisposeStr(P^.Text);
  P^.Text := NewStr(S);
  P^.DrawView;
end;

procedure TCopyStatWindow.UpdateSubViews;
const
  TotalInfoText =
    'Bytes total:     ~%12s~          Files total:    ~%12d~';
  CopiedInfoText =
    'Bytes copied:    ~%12s~          Files copied:   ~%12d~';
  RemainingInfoText =
    'Bytes remaining: ~%12s~          Files remaining:~%12d~';
  PercentInfoText =
    '~%d%%~ done';
  RateInfoText =
    'Transfer rate: ~%d~ KB/sec';
  TimeInfoText =
    'Estimated time: ~%9s~  Elapsed: ~%9s~  Remaining: ~%9s~';
var
  NewWidth: Byte;
  R: Real;
  Params: Array[0..2] of Longint;
  Time, EstTime, ElpTime, RemTime: Longint;
  EstTimeStr, ElpTimeStr, RemTimeStr: TStatTimeStr;
  S: String;
begin
  FormatFloatBytes(S, BytesTotal, 1000000000);
  Params[0] := Longint(@S);
  Params[1] := FilesTotal;
  UpdateInfo(TotalInfo, TotalInfoText, Params);

  FormatFloatBytes(S, BytesCopied, 1000000000);
  Params[0] := Longint(@S);
  Params[1] := FilesCopied;
  UpdateInfo(CopiedInfo, CopiedInfoText, Params);

  FormatFloatBytes(S, BytesTotal - BytesCopied, 1000000000);
  Params[0] := Longint(@S);
  Params[1] := FilesTotal - FilesCopied;
  UpdateInfo(RemainingInfo, RemainingInfoText, Params);

  if BytesTotal = 0 then
    if FilesTotal = 0 then R := 100
    else R := (FilesCopied / FilesTotal) * 100
  else R := (BytesCopied / BytesTotal) * 100;
  Params[0] := Trunc(R);
  UpdateInfo(PercentInfo, PercentInfoText, Params);

{ Added 01.22.01 to support SetApplicationTitle under Win95 }
  if Params[0] <> PrevTitlePercent then
  begin
    PrevTitlePercent := Params[0];
    FormatStr(S, 'Copy: %d%%', Params);
    SetApplicationTitle(S);
  end;

  with Bar^ do
  begin
    NewWidth := Trunc(Size.X * (R / 100));
    if NewWidth > Size.X then NewWidth := Size.X;
    if NewWidth <> Width then
    begin
      Width := NewWidth;
      DrawView;
    end;
  end;

  Time := MemL[$40:$6C];
  if (PrevTime <> 0) and (Time - PrevTime < 18) then Exit;

  PrevTime := Time;
  ElpTime := Time - InitTime;
  if BytesCopied < 32 then
  begin
    EstTime := -1;
    RemTime := -1;
  end
  else
  begin
    R := (ElpTime / BytesCopied) * BytesTotal;
    if R > MaxLongint then EstTime := MaxLongint
    else EstTime := Trunc(R);
    RemTime := EstTime - ElpTime + 19;
  end;

  TicksToTimeStr(EstTime, EstTimeStr);
  TicksToTimeStr(ElpTime, ElpTimeStr);
  TicksToTimeStr(RemTime, RemTimeStr);
  Params[0] := Longint(@EstTimeStr);
  Params[1] := Longint(@ElpTimeStr);
  Params[2] := Longint(@RemTimeStr);
  UpdateInfo(TimeInfo, TimeInfoText, Params);

  if ElpTime > 0 then
  begin
    R := (BytesCopied / 1024) / (ElpTime * 0.055);
    if R > MaxLongint then Params[0] := MaxLongint
    else Params[0] := Trunc(R);
    UpdateInfo(RateInfo, RateInfoText, Params);
  end;
end;

procedure OpenCopyBarWindow(const FromName, ToName: FNameStr;
  AVolume: Longint; MoveCopy, CopyLeft: Boolean);
begin
  if CopyBarWindow = nil then
  begin
    CopyBarWindow := New(PCopyBarWindow, Init(
      FromName, ToName, AVolume, MoveCopy, CopyLeft));
    Application^.Insert(CopyBarWindow);
  end
  else CopyBarWindow^.UpdateSubViews(FromName, ToName,
    AVolume, MoveCopy, CopyLeft);
end;

procedure OpenCopyStatWindow(CopyLeft: Boolean);
begin
  if FilesTotal <= 0 then Exit;
  if CopyStatWindow = nil then
  begin
    CopyStatWindow := New(PCopyStatWindow, Init(CopyLeft));
    Application^.Insert(CopyStatWindow);
  end
  else CopyStatWindow^.UpdateSubViews;
end;

{ Added 2005.08.30 to support regexp file operations }
procedure DisposeFileRegExp;
begin
{ Added 2005.09.16 to support prompt before file operation }
  FileCopyOptions := FileCopyOptions and not fsConfirmFileOperation;
  RegFree(FileRegExp);
  FileRegExp := nil;
{  DisposeStr(FileRegExpStr2);}
  DisposeStrUMB(FileRegExpStr2);
  FileRegExpStr2 := nil;
{  DisposeStr(FileRegExpStr1);}
  DisposeStrUMB(FileRegExpStr1);
  FileRegExpStr1 := nil;
  FileRegExpInitDirLen := 0;
end;

procedure FileRegExpError(var S: String; const M: String);
begin
  DisposeFileRegExp;
  MessageBox(M, nil, mfError + mfOkButton);
  S := '';
end;

procedure PreprocessFileRegExp(var S: String);
var
  I: Integer;
  S1, S2: Integer;
begin
  DisposeFileRegExp;
{ Added 2005.09.16 to support prompt before file operation }
  if (S <> '') and (S[1] = '?') then
  begin
    FileCopyOptions := FileCopyOptions or fsConfirmFileOperation;
    Delete(S, 1, 1);
    TrimSt(S);
  end;
  if (S = '') or (S[1] <> '>') then Exit;
  Delete(S, 1, 1);
  I := Pos('>', S);
  if I = 0 then I := Length(S) + 1;
{  FileRegExpStr1 := NewStr(Copy(S, 1, I - 1));}
  FileRegExpStr1 := NewStrUMB(Copy(S, 1, I - 1));
{  FileRegExpStr2 := NewStr(Copy(S, I + 1, 255));}
  FileRegExpStr2 := NewStrUMB(Copy(S, I + 1, 255));
  if (FileRegExpStr1 = nil) or (FileRegExpStr2 = nil) then
  begin
    FileRegExpError(S, ^C'Regular expression not specified:'#13#13^C +
      '>' + S);
    Exit;
  end;
  FileRegExp := RegCompile(StUpcase(FileRegExpStr1^));
  if FileRegExp = nil then FileRegExpError(
    S, ^C'Invalid regular expression:'#13#13^C + RegError + '.')
  else S := '>';
end;

procedure DoneFileOperation;
begin
  DoneRoller;

{ Added 2005.08.30 to support regexp file operations }
  DisposeFileRegExp;

  if CopyRenameStates <> nil then
  begin
{    FreeMem(CopyRenameStates, SizeOf(TState));}
    FreeMemUMB(CopyRenameStates, SizeOf(TState));
    CopyRenameStates := nil;
  end;

  if (CopyRenameFilter.Text <> nil) and
    not CopyRenameFilter.UseForLists then
  begin
{    DisposeStr(CopyRenameFilter.Text);}
    DisposeStrUMB(CopyRenameFilter.Text);
    CopyRenameFilter.Text := nil;
  end;

  if FMCopySettings and frRestoreFMOptions <> 0 then
    FMOptions := SaveFMOptions;
  if FMCopySettings and frRestoreCopySettings <> 0 then
    Move(SaveFileExistsAction, FileExistsAction, SizeOf(Word) * 5);

  if CopyStatWindow <> nil then
  begin
    Message(CopyStatWindow, evBroadcast, cmCloseBar, nil);
    CopyStatWindow := nil;
  end;

  if CopyBarWindow <> nil then
  begin
    Message(CopyBarWindow, evBroadcast, cmCloseBar, nil);
    CopyBarWindow := nil;
  end;

{ Added 2005.09.29 to avoid loops copying with regexps }
  if FileCRCList <> nil then
  begin
    Dispose(FileCRCList, Done);
    FileCRCList := nil;
  end;

{ Added 04.17.03 to support directory recursive copy/move }
  DirCRCListInUse := False;
  if DirCRCList <> nil then
  begin
    Dispose(DirCRCList, Done);
    DirCRCList := nil;
  end;

  Message(Application, evBroadcast, cmUpdateTime, nil);

{ Added 01.22.01 to support SetApplicationTitle under Win95 }
  if NoModalWindows then Desktop^.Current^.SetState(sfFocused, True)
  else Application^.TopView^.SetState(sfFocused, True);
end;

constructor TVarLabel.Init(var Bounds: TRect; const AText: String;
  ALink: PView; AVarPos: Byte);
begin
  TLabel.Init(Bounds, AText, ALink);
  VarPos := AVarPos;
end;

procedure TVarLabel.Draw;
var
  SCOff: Byte;
  Color: Word;
  B: TDrawBuffer;
begin
  if Light then
  begin
    Color := GetColor($0402);
    SCOff := 0;
  end
  else
  begin
    Color := GetColor($0301);
    SCOff := 4;
  end;
  MoveChar(B[0], ' ', Byte(Color), Size.X);
  if Text <> nil then MoveStr(B[1], Text^, Color);
  if ShowMarkers then Char(B[0]) := SpecialChars[SCOff];
  if VarPos <> 0 then WordRec(B[VarPos]).Hi := WordRec(Color).Hi;
  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TVarLabel.HandleEvent(var Event: TEvent);
var
  C: Char;
begin
  if (Event.What = evKeyDown) and
     (VarPos <> 0) and (VarPos <= Length(Text^)) then
  begin
    C := Upcase(Text^[VarPos]);
    if ((C <> #0) and (Event.KeyCode = GetAltCode(C))) or
       ((C <> #0) and (Owner^.Phase = phPostProcess) and
        (Upcase(Event.CharCode) = C)) then
    begin
      if Link <> nil then Link^.Select;
      Event.What := evNothing;
    end;
  end;
  TLabel.HandleEvent(Event);
end;

end.