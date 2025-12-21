{$I-,O-,X+}
unit Desktops;

interface

uses Dos, Objects, Drivers, Views, App, LFN;

type
  ExchBufferType = record
    ProgrToExecute: String[80];
    CmdLine: String[127];
    Source: String[79];
    ReportName: Array[0..79] of Char;
    ConfigMask: String[79];
    OldDir: Array[0..70] of Char;
    UniqueName: String[8];
    Error: Byte;
    Opts: Byte;
    SnippFlag: Boolean;
    SnippInUse: Boolean;
    VideoSeg: Word;
    TxtBufferEnd: Word;
    TxtBufferPtr: Pointer;
    Snipp_Init: Pointer;
    Snipp_Done: Pointer;
    Snipp_ClearBuffer: procedure;
  end;

const
  xbRedirFlag      = $01;
  xbCommandFlag    = $02;
  xbNoMsgWinFlag   = $04;
  xbMultiExecFlag  = $08;
  xbRedirErrFlag   = $10;
  xbNotFirstTime   = $80;

type
  ModeData = record
    ComName, Baud, Parity, DataBits, StopBits, HWFlow: Byte;
    InSize, OutSize: Word;
  end;

  TMouseData = record
    Options: Byte;
    Delay: Word;
  end;

const
  CFGSignature = 'CONNECT Configuration File'#26;
  DSKSignature = 'CONNECT Desktop File'#26;

  PatternSignature: Longint = $4E525450 {'PTRN'} ;
  PatternChar: Char = #32;

type
  PDesktopData = ^TDesktopData;
  TDesktopData = record
    Signature: Array[1..Length(CFGSignature)] of Char;
    Dir, SwapDir: DirStr;
    Mouse: TMouseData;
    Colors: TPalette;
    Mode: ModeData;
    DialPref: String[31];
    DialSuff: String[31];
    RedialPause: String[5];
    HiEditOptions: Word;
    KeyboardFlags: Byte;
    HideOpts: Byte;
    TxtMode: Byte;
    DisableSystemInfo: Boolean;
    EndingBeep: String[5];
    ProtOpts: Byte;
    DisableBeeps: Boolean;
    PortAddr: Word;
    IRQNum: Byte;
    Vector: Byte;
    LocalAssoc: Boolean;
    SaveTime: String[5];
    KbdDelay: Word;
    Pattern: Char;
    HistoryDepth: Byte;
    DataSeparator: Char;
    LoEditOptions: Word;
    TabSize: Byte;
    SaverDelay: String[5];
    AnimationDelay: String[5];
    TileA: TPoint;
    TileB: TPoint;
    WordDelimiters: Set of Char;
    LineWidth: Byte;
    LoFManagerOptions: Word;
    UnixMaskFlag: Boolean;
    ProgIndex: Integer;
    MacroIndex: Integer;
    Confirms: Word;
    DisableVGAPal: Boolean;
    HiFManagerOptions: Word;
    LFNOpt: Byte;
    WinPosOpt: Word;
    Protocol: Byte;
    DownloadPath: String[63];
    ZMOptions: Byte;
    ZMOverwrite: Byte;
    RevBar: Byte;
    EnableLogFile: Word;
    LogFileClass: Word;
    LogFileName: String[79];
    DevLayer: Byte;
    ReturnToDirAtStart: Boolean;
    ReturnToDirOnExit: Boolean;
    SaveEnvironment: Boolean;
    RestoreScreenMode: Boolean;
    SaveEditorFiles: Boolean;
    SaveDesktop: Boolean;
    OpenCPUWindow: Boolean;
    LstFlag: Boolean;
    EGALinesOn: Boolean;
    EnhancedPaletteOn: Boolean;
    MarkColumns: Boolean;
    TerminalSetup: Word;
    TerminalColumns: Integer;
    TerminalRows: Integer;
    OutputSetup: Word;
    OutputColumns: Integer;
    OutputRows: Integer;
    ExplodeFlag: Boolean;
    ExpDelay: Byte;
    AbortProg: Byte;
    ImpExpOpt: Byte;
    DropMode: Byte;
    DirCompare: Byte;
    BBSWhites: Byte;
    FMIncrSearch: Byte;
    SWFlowCtl: Byte;
    BBSOpt: Byte;
    FMAutoReread: Byte;
    TimeSliceOpt: Byte;
    TimeSliceKind: Byte;
    BinaryPrint: Boolean;
    UseDOSCountry: Byte;
    NewEditOpt: Word;
    Reserved: String[6];
    FMDelay: Word;
    ArchiverFlags: Longint;
    MouseX: Word;
    MouseY: Word;
    PortOpts: Word;
    Cursor: Word;
    BlockCursor: Word;
    SaveRGB: Byte;
    SnowChecking: Boolean;
    VideoMode: Byte;
  end;

  PCBackground = ^TCBackground;
  TCBackground = object(TBackground)
    DrawUserScr: Boolean;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PCDesktop = ^TCDesktop;
  TCDesktop = object(TDesktop)
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitBackground; virtual;
  end;

const
  MaxBauds = 12;
  BaudTable: Array[0..MaxBauds - 1] of Longint =
    (110, 150, 300, 600, 1200, 2400, 4800, 9600, 19200,
     38400, 57600, 115200);

var
  DesktopData: PDesktopData;
  ExchBufferPtr: ^ExchBufferType;

procedure SetScreen(Mode: Word);
procedure UpdateScreen(Mode: Word);
procedure SetLFNSupport(APIType: lAPIType; DisplayError: Boolean);
procedure InitDesktopData;
procedure DoneDesktopData;
procedure SetConfigName(const Name: FNameStr);
procedure SetConfigExt(const Ext: ExtStr; var Name: FNameStr);
procedure CloseAllViews;
procedure ClearDesktop;
procedure SaveAll;
function  SaveOnExit: Boolean;
procedure SaveOnRun;
procedure LoadDesktop(var S: TStream);
procedure StoreDesktop(var S: TStream);
procedure RetrieveDesktop;
procedure SaveDesktop(Force: Boolean);
procedure InitClipboard(const AName: FNameStr);
procedure DoneClipboard(DoStore, DoErase: Boolean);
procedure CheckTimeDependables;

implementation

uses
  Memory, AppPrim, AppCmnd, HistList, Dialogs, StdDlg, UserScr, Gauges,
  Keyboard, Terminal, Clipbrd, Compiler, FindDlg, Swaps, Streams,
  DosTools, DirPrim, DiskBase, RGBColor, RGBDlg, DragDrop, APCom,
  APPort, AsynPrim, DevLayer, TileAr, CopyScr, ScrSaver, Mouse,
  HelpFile, HelpPrim, ClipPrim, LogFile, Tags, ArcV, TermComp,
  HideMain, EditMsg, FindFile, PanelRec, WinPos, CNWinPos, DosCase,
  HeapUMB, Disks, DrvList, TPDate, TPString, Consts, Commands, Defaults;

const
  LastTime: Time = 0;

procedure SetScreen(Mode: Word);
begin
  if (ScreenMode <> Mode) or (CustomVideoMode <> 0) then
  begin
    SetScreenModePrim(Mode);
    if CustomVideoMode = 0 then
      EGALinesOn := ScreenMode and smFont8x8 <> 0;
  end;
  RefreshDisplay;
end;

procedure UpdateScreen(Mode: Word);
begin
  if EGALinesOn then Mode := Mode or smFont8x8
  else if not RestoreVideoMode then Mode := ScreenMode
  else Mode := Mode and not smFont8x8;
  SetScreen(Mode);
end;

procedure SetDefaultMode;
begin
  DesktopData^.Mode.ComName := 1;
  DesktopData^.Mode.Baud := 7;
  DesktopData^.Mode.Parity := 0;
  DesktopData^.Mode.DataBits := 3;
  DesktopData^.Mode.StopBits := 1;
  DesktopData^.Mode.HWFlow := hfUseRTS + hfRequireCTS;
  DesktopData^.Mode.InSize := 4096;
  DesktopData^.Mode.OutSize := 4096;
end;

procedure Mode2Data;
var
  B: Byte;
begin
  DesktopData^.Mode.ComName := Ord(ComName);
  for B := 0 to MaxBauds - 1 do if BaudTable[B] = Baud then Break;
  DesktopData^.Mode.Baud := B;
  DesktopData^.Mode.Parity := Ord(Parity);
  DesktopData^.Mode.DataBits := Ord(DataBits) - 5;
  DesktopData^.Mode.StopBits := Ord(StopBits) - 1;
  DesktopData^.Mode.HWFlow := HWFlow;
  DesktopData^.Mode.InSize := InBufSize;
  DesktopData^.Mode.OutSize := OutBufSize;
end;

procedure Data2Mode;
begin
  ComName := ComNameType(DesktopData^.Mode.ComName);
  Baud := BaudTable[DesktopData^.Mode.Baud];
  if DesktopData^.Mode.Baud < MaxBauds then
    Baud := BaudTable[DesktopData^.Mode.Baud]
  else Baud := 9600;
  Parity := ParityType(DesktopData^.Mode.Parity);
  DataBits := DesktopData^.Mode.DataBits + 5;
  StopBits := DesktopData^.Mode.StopBits + 1;
  HWFlow := DesktopData^.Mode.HWFlow;
  InBufSize := DesktopData^.Mode.InSize;
  OutBufSize := DesktopData^.Mode.OutSize;
end;

procedure SetLFNSupport(APIType: lAPIType; DisplayError: Boolean);
begin
  if (APIType = lWIN95) and (lAPI = lDOS) then
    if not OS2Installed and lWIN95APIAllowed then
    begin
      lAPI := lWIN95;
      fAPI := fWIN95;
    end
    else
    begin
      lAPI := lDOS;
      fAPI := fDOS;
      if DisplayError then LFNNotSupportedMsgBox(lWIN95);
    end;
end;

procedure InitDesktopData;
begin
{  GetMem(DesktopData, SizeOf(TDesktopData));}
  GetMemUMB(DesktopData, SizeOf(TDesktopData));
  with DesktopData^ do
  begin
    FillChar(DesktopData^, SizeOf(TDesktopData), 0);
    Move(TByteArray(GetStrAddr(CFGSignature)^)[1],
      Signature, Length(CFGSignature));
    SwapDir := ConfigPath;
    Mouse.Delay := 8;
    Colors := DefaultPalette;
    Colors[255] := #$07;
    SetDefaultMode;
    EndingBeep := 'No';
    SaveTime := 'No';
    Pattern := '°';
    HistoryDepth := 10;
    DataSeparator := ':';
    LoEditOptions := DefEditOptions;
    LoFManagerOptions := DefFMOptions;
    FMDelay := DefFMAutoDelay;
    ZMOptions := DefZmodemOptions;
    ZMOverwrite := DefZmodemOverwrite;
    RevBar := DefReverseBar;
    LogFileClass := DefLogClass;
    EnableLogFile := DefEnableLog;
    LogFileName := DefLogName;
    ReturnToDirAtStart := True;
    ReturnToDirOnExit := True;
    SaveEditorFiles := True;
    SaveEnvironment := True;
    SaveDesktop := True;
    RestoreScreenMode := True;
    TabSize := 8;
    LineWidth := 64;
    SaverDelay := '2';
    AnimationDelay := 'No';
    Desktop^.GetExtent(TileArea);
    WordDelimiters := DefWordDelims;
    TerminalSetup := DefTerminalOptions;
    TerminalColumns := 80;
    TerminalRows := 24;
    OutputSetup := DefOutputOptions;
    OutputColumns := 80;
    OutputRows := 24;
    AbortProg := DefAbortUser;
    ImpExpOpt := DefImpExpOptions;
    DropMode := DefddMode;
    DirCompare := DefCompareOptions;
    BBSWhites := DefBBSSpaces;
    FMIncrSearch := DefFMSearchOptions;
    SWFlowCtl := DefSWFOpt;
    PortOpts := DefPortOptionsSimple;
    Cursor := DefaultCursor;
    BlockCursor := $0007;
    SaveRGB := RGBOptions;
    SnowChecking := DoCheckSnow;
{
    TermcapName := '';
    TermcapIden := '';
    InputXLATName := '';
    OutputXLATName := '';
    ModemInitStr := '';
    ModemHangupStr := '';
    ModemAnswerStr := '';
    ModemCancelStr := '';
    ModemConnectStr := '';
    ModemBusyStr := '';
    ModemRingStr := '';
    ModemBreakStr := '';
}
  end;
end;

procedure DoneDesktopData;
begin
{  FreeMem(DesktopData, SizeOf(TDesktopData));}
  FreeMemUMB(DesktopData, SizeOf(TDesktopData));
end;

procedure SetConfigName(const Name: FNameStr);
begin
  ConfigPath := AddBackSlash(JustPathName(Name));
  ConfigMask := JustName(Name);
  if not Auto then ExchBufferPtr^.ConfigMask := Name;
end;

procedure SetConfigExt(const Ext: ExtStr; var Name: FNameStr);
begin
  Name := ConfigPath + ConfigMask + '.' + Ext;
end;

function SaveOnExit: Boolean;
begin
  SaveOnExit := Message(Desktop, evBroadcast, cmQuit, nil) = nil;
end;

procedure SaveAll;
begin
  Message(Desktop, evBroadcast, cmSaveAll, nil);
end;

procedure SaveOnRun;
begin
  if not Debugging then
  begin
    if DesktopData^.SaveEditorFiles then SaveAll;
    SaveDesktop(False);
  end;
end;

procedure CloseAllViews;

procedure CloseView(P: PView); far;
begin
  Message(P, evCommand, cmClose, nil);
end;

begin
  Desktop^.ForEach(@CloseView);
  if TheClipboard <> nil then Dispose(TheClipboard, Done);
  if TheTerminal <> nil then Dispose(PView(TheTerminal)^.Owner, Done);
  if TheBack <> nil then Dispose(PView(TheBack)^.Owner, Done);
end;

procedure ClearDesktop;
begin
  if SaveOnExit then
  begin
    Message(Desktop, evBroadcast, cmQuit, Pointer(1));
    CloseAllViews;
  end;
end;

procedure LoadDesktop(var S: TStream);
var
  SaveExplode: Boolean;
  I: Integer;
  P: PView;
begin
  SaveExplode := DoExplode;
  DoExplode := False;
  HistoryList^.Locked := True;
  DoneTagList;
  TagList := PTagList(S.Get);
  if TagList = nil then InitTagList
  else
  begin
    I := TagList^.Count + TagList^.Delta;
    if MaxAvail > LongMul(I, 4) then TagList^.SetLimit(I);
  end;
  repeat
    P := PView(S.Get);
    Desktop^.InsertBefore(Application^.ValidView(P), Desktop^.Last);
  until P = nil;
  HistoryList^.Locked := False;
  DoExplode := SaveExplode;
  LoadHistory(S);
  if PrevHelpUsed then LoadPrevHelpArray(S);
end;

procedure StoreDesktop(var S: TStream);

procedure WriteView(P: PView); far;
begin
  if (S.Status = stOk) and (P <> Desktop^.Last) and
     (P^.State and sfModal = 0) and
     (P^.Options and ofnotStorable = 0) then S.Put(P);
end;

begin
  S.Put(TagList);
  Desktop^.ForEach(@WriteView);
  S.Put(nil);
  StoreHistory(S);
  if PrevHelpUsed then StorePrevHelpArray(S);
end;

procedure RetrieveDesktop;

procedure LoadConfigFile;
var
  B: Boolean;
  I, H, M, S: Word;
  Code, NetCount, N: Integer;
  Buf: PDesktopData;
  ClockOrigin, HeapOrigin: TPoint;
  F: File;
  Name: FNameStr;
  SS: String;

procedure LoadString(var S: String; MaxLen: Byte);
begin
  BlockRead(F, S[0], SizeOf(Byte));
  if Length(S) > MaxLen then S := ''
  else BlockRead(F, S[1], Length(S));
end;

procedure LoadRGB;
var
  T: Text;
begin
  SetConfigExt('RGB', Name);
  Assign(T, Name);
  Reset(T);
  if IOResult <> 0 then Exit;
  if not IsDevice(TextRec(T).Handle) then
  begin
    Readln(T, SaveRGB);
    if (SaveRGB[0] = #48) and IsVGA then SetRGB;
  end;
  Close(T);
  InOutRes := 0;
end;

begin
  DoneEvents;
  ButtonCount := 0;
  Longint(ClockOrigin) := -1;
  Longint(HeapOrigin) := -1;
  Longint(CDClockOrigin) := -1;
{  DisposeStr(CopyRenameFilter.Text);}
  DisposeStrUMB(CopyRenameFilter.Text);
  CopyRenameFilter.Text := nil;
  B := False;
  LogEvent := lcConfig;
  DrawStatusLine('Reading configuration file.');
  InOutRes := 0;
  SetConfigExt('CFG', Name);
  Assign(F, Name);
  ResetReadOnly(F, 1);
  if IOResult <> 0 then ConfigOpenErrorMsgBox
  else if IsDevice(FileRec(F).Handle) then
  begin
    Close(F);
    InOutRes := 0;
    FileIsDeviceMsgBox(Name)
  end
  else
  begin
{    GetMem(Buf, SizeOf(TDesktopData));}
    GetMemUMB(Buf, SizeOf(TDesktopData));
    BlockRead(F, Buf^, SizeOf(TDesktopData));
    I := IOResult;
    LoadString(TermcapName, NameLen);
    LoadString(TermcapIden, ParamLen);
    LoadString(InputXLATName, NameLen);
    LoadString(OutputXLATName, NameLen);
    LoadString(ModemInitStr, ModemInitLen);
    LoadString(ModemHangupStr, ModemHangupLen);
    LoadString(ModemAnswerStr, ModemAnswerLen);
    LoadString(ModemCancelStr, ModemCancelLen);
    LoadString(ModemConnectStr, ModemConnectLen);
    LoadString(ModemBusyStr, ModemBusyLen);
    BlockRead(F, ASCIICharDelay, SizeOf(Word) * 2);
    LoadString(PrnDeviceName, NameLen);
    LoadString(PrnFontName, NameLen);
    BlockRead(F, PrnOptions, SizeOf(Word));
    LoadString(PrnInitString, PrnInitLen);
    LoadString(PrnLeftMargin, PrnMarginLen);
    LoadString(PrnTopMargin, PrnMarginLen);
    LoadString(PrnBottomMargin, PrnMarginLen);
    LoadString(PrnLinesPerPage, PrnLinesLen);
    LoadString(PrnInterval, PrnIntervalLen);
    LoadString(PrnCharsPerCycle, PrnCycleLen);
    LoadString(AltHelpName, NameLen);
    BlockRead(F, CountryDate, SizeOf(Byte) * 5);
    BlockRead(F, ClockOrigin, SizeOf(TPoint));
    BlockRead(F, HeapOrigin, SizeOf(TPoint));
    BlockRead(F, CDClockOrigin, SizeOf(TPoint));
    LoadString(DirinfoNames, NameLen);
    LoadString(BBSNames, NameLen);
    LoadString(ModemRingStr, ModemRingLen);
    LoadString(ModemBreakStr, ModemBreakLen);
    BlockRead(F, cdSettings, SizeOf(Byte) * 2 + SizeOf(Integer) * 2);
    LoadString(cdAlbumDir, AlbumDirLen);
    LoadString(cdMixerCommand, MixerCommandLen);
    BlockRead(F, HelpViewerBounds, SizeOf(TRect) * 2);
    BlockRead(F, B, SizeOf(Boolean));
    if B then
    begin
      LoadString(SS, 255);
{      CopyRenameFilter.Text := NewStr(SS);}
      CopyRenameFilter.Text := NewStrUMB(SS);
      BlockRead(F, CopyRenameFilter.Unix,
	SizeOf(TFilterRec) - SizeOf(Pointer));
    end;
    BlockRead(F, FileExistsAction, SizeOf(Word) * 5);
    BlockRead(F, MMapWinPos, SizeOf(TWinPosRec) * NumWinPos);
    BlockRead(F, CustomVideoMode, SizeOf(Byte));
    BlockRead(F, B, SizeOf(Boolean));
    if B then BlockRead(F, SearchDrives,
      SizeOf(TDrivesArray) + SizeOf(Word) +
      SizeOf(Boolean) * 2 + SizeOf(Word) * 2);
    BlockRead(F, ThousandsSeparator, SizeOf(Char));
    LoadString(ArcNameFilter, 255);
    BlockRead(F, PrevHelpUsed, SizeOf(Boolean));
    BlockRead(F, ArcCopyCRC, SizeOf(Longint));
    BlockRead(F, CopyResultAs, SizeOf(Byte) * 2);
    BlockRead(F, SaveClipboardData, SizeOf(Boolean));
    if SaveClipboardData then LoadString(ClipName, 12);
    BlockRead(F, DriveListOptions, SizeOf(Byte));
    LoadString(FMMacroName, NameLen);
    LoadString(TermMacroName, NameLen);
    BlockRead(F, ProtocolPrompt, SizeOf(Boolean));
    BlockRead(F, LastMacroNameCRC, SizeOf(Longint));
    BlockRead(F, TagChar, SizeOf(Char));
    BlockRead(F, AutoDecode, SizeOf(Byte));
    BlockRead(F, UserDrives, SizeOf(TUserDrives));
    NetCount := 0;
    BlockRead(F, NetCount, SizeOf(Integer));
    for N := 0 to NetCount - 1 do
    begin
      LoadString(SS, 255);
{      if SS <> '' then NetList^.Insert(NewStrUMB(SS));}
      if SS <> '' then NetList^.Insert(NewStrUMB(SS));
    end;
    BlockRead(F, CmpAdvOpt, SizeOf(Longint) + SizeOf(Word));
    BlockRead(F, WordStarKeys, SizeOf(Word));
    BlockRead(F, StdDlg.ViewLine, SizeOf(Boolean) + SizeOf(Boolean) +
      SizeOf(Byte) + SizeOf(Byte));
    Close(F);
    InOutRes := 0;
    if (I <> 0) or (Buf^.Signature <> CFGSignature) then
    begin
      DesktopData^.SaveEnvironment := False;
      ConfigReadErrorMsgBox;
    end
    else
    begin
      Move(Buf^, DesktopData^, SizeOf(TDesktopData));
      if DesktopData^.ReturnToDirAtStart then
      begin
        FailSysErrors := True;
        ChDir(DesktopData^.Dir);
        FailSysErrors := False;
        InOutRes := 0;
      end;
    end;
{    FreeMem(Buf, SizeOf(TDesktopData));}
    FreeMemUMB(Buf, SizeOf(TDesktopData));
  end;
  MouseOptions := DesktopData^.Mouse.Options;
  DoubleDelay := DesktopData^.Mouse.Delay;
  Data2Mode;
  if (Lo(ScreenMode) = DesktopData^.VideoMode) or
     (DesktopData^.VideoMode = 0) or (CustomVideoMode <> 0) then
  begin
    Move(DesktopData^.Colors[1], Application^.GetPalette^[1],
      Byte(Application^.GetPalette^[0]));
    Application^.GetPalette^[255] := DesktopData^.Colors[255];
    ShadowAttr := Byte(DesktopData^.Colors[255]);
  end;
  DialPrefix := DesktopData^.DialPref;
  DialSuffix := DesktopData^.DialSuff;
  RedialDelay := DesktopData^.RedialPause;
  KbdDelay := DesktopData^.KbdDelay;
  KeyboardOptions := DesktopData^.KeyboardFlags;
  TextReadMode := DesktopData^.TxtMode;
  DisableSysinfo := DesktopData^.DisableSystemInfo;
  DisableSounds := DesktopData^.DisableBeeps;
  LocalAssocs := DesktopData^.LocalAssoc;
  PortAddress := DesktopData^.PortAddr;
  IRQNumber := DesktopData^.IRQNum;
  COMVector := DesktopData^.Vector;
  HistoryDepth := DesktopData^.HistoryDepth;
  FieldSeparator := DesktopData^.DataSeparator;
  LongRec(EditOptions).Lo := DesktopData^.LoEditOptions;
  LongRec(EditOptions).Hi := DesktopData^.HiEditOptions;
  LongRec(FMOptions).Lo := DesktopData^.LoFManagerOptions;
  LongRec(FMOptions).Hi := DesktopData^.HiFManagerOptions;
  LFNOptions := DesktopData^.LFNOpt;
  WinPosMask := DesktopData^.WinPosOpt;
  FMAutoDelay := DesktopData^.FMDelay;
  ArcFlags := DesktopData^.ArchiverFlags;
  UnixFlag := DesktopData^.UnixMaskFlag;
  LastProgIndex := DesktopData^.ProgIndex;
  LastMacroIndex := DesktopData^.MacroIndex;
  ConfirmOptions := DesktopData^.Confirms;
  DisableVGAPalette := DesktopData^.DisableVGAPal;
  ModemProtocol := DesktopData^.Protocol;
  DownloadDir := DesktopData^.DownloadPath;
  ProtOptions := DesktopData^.ProtOpts;
  ZmodemOptions := DesktopData^.ZMOptions;
  ZmodemOverwrite := DesktopData^.ZMOverwrite;
  ReverseBar := DesktopData^.RevBar;
  EnableLog := DesktopData^.EnableLogFile;
  LogClass := DesktopData^.LogFileClass;
  LogName := DesktopData^.LogFileName;
  DeviceLayer := DesktopData^.DevLayer;
  TabSize := DesktopData^.TabSize;
  MaxLineWidth := DesktopData^.LineWidth;
  Val(DesktopData^.EndingBeep, EndingBeepTime, Code);
  Val(DesktopData^.SaveTime, AutoSaveTime, Code);
  Val(DesktopData^.SaverDelay, SaverDelay, Code);
  Val(DesktopData^.AnimationDelay, AnimateDelay, Code);
  TileArea.A := DesktopData^.TileA;
  TileArea.B := DesktopData^.TileB;
  WordDelims := DesktopData^.WordDelimiters;
  TerminalOptions := DesktopData^.TerminalSetup;
  TerminalWidth := DesktopData^.TerminalColumns;
  if TerminalWidth < 1 then TerminalWidth := 1
  else if TerminalWidth > MaxViewWidth then
    TerminalWidth := MaxViewWidth;
  TerminalHeight := DesktopData^.TerminalRows;
  if TerminalHeight < 1 then TerminalHeight := 1
  else if TerminalHeight > MaxOutputLines then
    TerminalHeight := MaxOutputLines;
  OutputOptions := DesktopData^.OutputSetup;
  OutputWidth := DesktopData^.OutputColumns;
  if OutputWidth < 1 then OutputWidth := 1
  else if OutputWidth > MaxViewWidth then
    OutputWidth := MaxViewWidth;
  OutputHeight := DesktopData^.OutputRows;
  if OutputHeight < 1 then OutputHeight := 1
  else if OutputHeight > MaxOutputLines then
    OutputHeight := MaxOutputLines;
  OpenCPUWindow := DesktopData^.OpenCPUWindow;
  LstFlag := DesktopData^.LstFlag;
  DoCheckSnow := DesktopData^.SnowChecking;
  Desktop^.Background^.Pattern := DesktopData^.Pattern;
  EnhancedPaletteOn := DesktopData^.EnhancedPaletteOn;
  RestoreVideoMode := DesktopData^.RestoreScreenMode;
  EGALinesOn := DesktopData^.EGALinesOn and (Equipment <> 0);
  MarkColumns := DesktopData^.MarkColumns;
  DoExplode := DesktopData^.ExplodeFlag;
  if DesktopData^.ExpDelay > 15 then ExplodeDelay := 0
  else ExplodeDelay := DesktopData^.ExpDelay;
  AbortUser := DesktopData^.AbortProg;
  DBImpExpOptions := DesktopData^.ImpExpOpt;
  ddMode := Byte(Boolean(DesktopData^.DropMode));
  CompareOptions := DesktopData^.DirCompare;
  BBSSpaces := DesktopData^.BBSWhites;
  FMSearchOptions := DesktopData^.FMIncrSearch;
  SWFlow := DesktopData^.SWFlowCtl;
  BBSOptions := DesktopData^.BBSOpt;
  FMAutoRereadOptions := DesktopData^.FMAutoReread;
  TimeSliceOptions := DesktopData^.TimeSliceOpt;
  TimeSliceType := DesktopData^.TimeSliceKind;
  BinaryPrinting := DesktopData^.BinaryPrint;
  UseDOSCountryInfo := DesktopData^.UseDOSCountry;
  NewEditOptions := DesktopData^.NewEditOpt;
  PortOptions := DesktopData^.PortOpts;
  CursorLines := DesktopData^.Cursor;
  BlockCursorLines := DesktopData^.BlockCursor;
  Move(FileExistsAction, SaveFileExistsAction, SizeOf(Word) * 5);
  SaveFMOptions := FMOptions;
  RGBOptions := DesktopData^.SaveRGB;
  if RGBOptions and 1 <> 0 then LoadRGB;
  if UseDOSCountryInfo and
    (ciDate + ciTime + ciDateSep + ciTimeSep + ciThouSep +
     ciCharMap) <> 0 then SetCountrySpecificInfo;
  UpdateScreen(ScreenMode);
  if ValidGaugeOrigin(ClockOrigin) then
    Clock^.MoveTo(ClockOrigin.X, ClockOrigin.Y);
  if ValidGaugeOrigin(HeapOrigin) then
    Heap^.MoveTo(HeapOrigin.X, HeapOrigin.Y);
  if DesktopData^.HideOpts <> HideOptions then
  begin
    Clock^.LastTime.Sec := $FF;
    Clock^.Update;
    HideOptions := DesktopData^.HideOpts;
    UpdateMainViews;
  end;
  SwapDir := DesktopData^.SwapDir;
  GetValidSwapDir(Name, True);
  InitDiskSwapStream(Name + SwapName, EditOptions and eoUseEMS <> 0);
  InitClipboard(Name + ClipName);
  InitLog;
  ReportFile := Name + 'CONNECT.RPT';
  LastTime := 0;
  LastIdleTime := 0;
  FirstIdleCall := True;
  if LFNOptions and loEnableWIN95LFN <> 0 then
    SetLFNSupport(lWIN95, False);
end;

procedure LoadDesktopFile;
var
  Result: Boolean;
  S: TDosStream;
  Signature: Array[1..Length(DSKSignature)] of Char;
  Name: FNameStr;
begin
  LogEvent := lcConfig;
  DrawStatusLine('Reading desktop file.');
  SetConfigExt('DSK', Name);
  S.Init(Name, stOpenRead);
  if S.Status <> stOk then DesktopOpenErrorMsgBox
  else if IsDevice(S.Handle) then FileIsDeviceMsgBox(Name)
  else if MaxAvail <= S.GetSize + $4000 then Application^.OutOfMemory
  else
  begin
    S.Read(Signature, Length(DSKSignature));
    Result := Signature = DSKSignature;
    if Result then LoadDesktop(S);
    if (S.Status <> stOk) or not Result then
    begin
      DesktopData^.SaveDesktop := False;
      DesktopReadErrorMsgBox;
    end;
  end;
  S.Done;
end;

begin
  LoadConfigFile;
  LoadDesktopFile;
  if (TerminalOptions and toUseBack <> 0) and
     (TheTerminal <> nil) and (TheBack = nil) then PrepareBack;
  RevProg := True;
end;

procedure SaveDesktop(Force: Boolean);

procedure SaveConfigFile;
var
  B: Boolean;
  I: Word;
  N: Integer;
  F: File;
  Name: FNameStr;

procedure StoreString(var S: String);
begin
  BlockWrite(F, S, Length(S) + 1);
end;

procedure StoreRGB;
var
  T: Text;
begin
  if (SaveRGB[0] = #48) and IsVGA then
  begin
    SetConfigExt('RGB', Name);
    Assign(T, Name);
    Rewrite(T);
    if IOResult <> 0 then Exit;
    if not IsDevice(TextRec(T).Handle) then Writeln(T, SaveRGB);
    Close(T);
    InOutRes := 0;
  end;
end;

begin
  LogEvent := lcConfig;
  DrawStatusLine('Writing configuration file.');
  GetDir(0, DesktopData^.Dir);
  DesktopData^.SwapDir := SwapDir;
  DesktopData^.Mouse.Options := MouseOptions;
  DesktopData^.Mouse.Delay := DoubleDelay;
  Mode2Data;
  DesktopData^.Colors := Application^.GetPalette^;
  DesktopData^.Colors[255] := Char(ShadowAttr);
  DesktopData^.DialPref := DialPrefix;
  DesktopData^.DialSuff := DialSuffix;
  DesktopData^.RedialPause := RedialDelay;
  DesktopData^.KbdDelay := KbdDelay;
  DesktopData^.KeyboardFlags := KeyboardOptions;
  DesktopData^.Pattern := Desktop^.Background^.Pattern;
  DesktopData^.HideOpts := HideOptions;
  DesktopData^.TxtMode := TextReadMode;
  DesktopData^.DisableSystemInfo := DisableSysinfo;
  DesktopData^.DisableBeeps := DisableSounds;
  DesktopData^.LocalAssoc := LocalAssocs;
  DesktopData^.PortAddr := PortAddress;
  DesktopData^.IRQNum := IRQNumber;
  DesktopData^.Vector := COMVector;
  DesktopData^.HistoryDepth := HistoryDepth;
  DesktopData^.DataSeparator := FieldSeparator;
  DesktopData^.LoEditOptions := LongRec(EditOptions).Lo;
  DesktopData^.HiEditOptions := LongRec(EditOptions).Hi;
  DesktopData^.LoFManagerOptions := LongRec(FMOptions).Lo;
  DesktopData^.HiFManagerOptions := LongRec(FMOptions).Hi;
  DesktopData^.LFNOpt := LFNOptions;
  DesktopData^.WinPosOpt := WinPosMask;
  DesktopData^.FMDelay := FMAutoDelay;
  DesktopData^.ArchiverFlags := ArcFlags;
  DesktopData^.UnixMaskFlag := UnixFlag;
  DesktopData^.ProgIndex := LastProgIndex;
  DesktopData^.MacroIndex := LastMacroIndex;
  DesktopData^.Confirms := ConfirmOptions;
  DesktopData^.DisableVGAPal := DisableVGAPalette;
  DesktopData^.Protocol := ModemProtocol;
  DesktopData^.DownloadPath := DownloadDir;
  DesktopData^.ProtOpts := ProtOptions;
  DesktopData^.ZMOptions := ZmodemOptions;
  DesktopData^.ZMOverwrite := ZmodemOverwrite;
  DesktopData^.RevBar := ReverseBar;
  DesktopData^.EnableLogFile := EnableLog;
  DesktopData^.LogFileClass := LogClass;
  DesktopData^.LogFileName := LogName;
  DesktopData^.DevLayer := DeviceLayer;
  DesktopData^.TabSize := TabSize;
  DesktopData^.LineWidth := MaxLineWidth;
  DesktopData^.TileA := TileArea.A;
  DesktopData^.TileB := TileArea.B;
  DesktopData^.WordDelimiters := WordDelims;
  DesktopData^.OpenCPUWindow := OpenCPUWindow;
  DesktopData^.LstFlag := LstFlag;
  DesktopData^.EGALinesOn := EGALinesOn;
  DesktopData^.EnhancedPaletteOn := EnhancedPaletteOn;
  DesktopData^.RestoreScreenMode := RestoreVideoMode;
  DesktopData^.MarkColumns := MarkColumns;
  DesktopData^.TerminalSetup := TerminalOptions;
  DesktopData^.TerminalColumns := TerminalWidth;
  DesktopData^.TerminalRows := TerminalHeight;
  DesktopData^.OutputSetup := OutputOptions;
  DesktopData^.OutputColumns := OutputWidth;
  DesktopData^.OutputRows := OutputHeight;
  DesktopData^.ExplodeFlag := DoExplode;
  DesktopData^.ExpDelay := ExplodeDelay;
  DesktopData^.AbortProg := AbortUser;
  DesktopData^.ImpExpOpt := DBImpExpOptions;
  DesktopData^.DropMode := ddMode;
  DesktopData^.DirCompare := CompareOptions;
  DesktopData^.BBSWhites := BBSSpaces;
  DesktopData^.FMIncrSearch := FMSearchOptions;
  DesktopData^.SWFlowCtl := SWFlow;
  DesktopData^.BBSOpt := BBSOptions;
  DesktopData^.FMAutoReread := FMAutoRereadOptions;
  DesktopData^.TimeSliceOpt := TimeSliceOptions;
  DesktopData^.TimeSliceKind := TimeSliceType;
  DesktopData^.BinaryPrint := BinaryPrinting;
  DesktopData^.UseDOSCountry := UseDOSCountryInfo;
  DesktopData^.NewEditOpt := NewEditOptions;
  DesktopData^.PortOpts := PortOptions;
  DesktopData^.Cursor := CursorLines;
  DesktopData^.BlockCursor := BlockCursorLines;
  DesktopData^.SaveRGB := RGBOptions;
  DesktopData^.SnowChecking := DoCheckSnow;
  DesktopData^.VideoMode := Lo(ScreenMode);
  if (MouseOptions and moSavePos <> 0) and (ButtonCount <> 0) then
  begin
    DesktopData^.MouseX := MouseWhere.X shl 3;
    DesktopData^.MouseY := MouseWhere.Y shl 3;
  end;
  InOutRes := 0;
  SetConfigExt('CFG', Name);
  Assign(F, Name);
  Rewrite(F, 1);
  if IOResult = 0 then
  begin
    BlockWrite(F, DesktopData^, SizeOf(TDesktopData));
    StoreString(TermcapName);
    StoreString(TermcapIden);
    StoreString(InputXLATName);
    StoreString(OutputXLATName);
    StoreString(ModemInitStr);
    StoreString(ModemHangupStr);
    StoreString(ModemAnswerStr);
    StoreString(ModemCancelStr);
    StoreString(ModemConnectStr);
    StoreString(ModemBusyStr);
    BlockWrite(F, ASCIICharDelay, SizeOf(Word) * 2);
    StoreString(PrnDeviceName);
    StoreString(PrnFontName);
    BlockWrite(F, PrnOptions, SizeOf(Word));
    StoreString(PrnInitString);
    StoreString(PrnLeftMargin);
    StoreString(PrnTopMargin);
    StoreString(PrnBottomMargin);
    StoreString(PrnLinesPerPage);
    StoreString(PrnInterval);
    StoreString(PrnCharsPerCycle);
    StoreString(AltHelpName);
    BlockWrite(F, CountryDate, SizeOf(Byte) * 5);
    BlockWrite(F, Clock^.Origin, SizeOf(TPoint));
    BlockWrite(F, Heap^.Origin, SizeOf(TPoint));
    if TheTerminal <> nil then with PTerminal(TheTerminal)^ do
      if CDClock <> nil then CDClockOrigin := CDClock^.Origin;
    BlockWrite(F, CDClockOrigin, SizeOf(TPoint));
    StoreString(DirinfoNames);
    StoreString(BBSNames);
    StoreString(ModemRingStr);
    StoreString(ModemBreakStr);
    BlockWrite(F, cdSettings, SizeOf(Byte) * 2 + SizeOf(Integer) * 2);
    StoreString(cdAlbumDir);
    StoreString(cdMixerCommand);
    BlockWrite(F, HelpViewerBounds, SizeOf(TRect) * 2);
    B := CopyRenameFilter.Text <> nil;
    BlockWrite(F, B, SizeOf(Boolean));
    if B then
    begin
      StoreString(CopyRenameFilter.Text^);
      BlockWrite(F, CopyRenameFilter.Unix,
	SizeOf(TFilterRec) - SizeOf(Pointer));
    end;
    BlockWrite(F, FileExistsAction, SizeOf(Word) * 5);
    BlockWrite(F, MMapWinPos, SizeOf(TWinPosRec) * NumWinPos);
    BlockWrite(F, CustomVideoMode, SizeOf(Byte));
    B := FindSaveOptions and fsSaveOptions <> 0;
    BlockWrite(F, B, SizeOf(Boolean));
    if B then BlockWrite(F, SearchDrives,
      SizeOf(TDrivesArray) + SizeOf(Word) +
      SizeOf(Boolean) * 2 + SizeOf(Word) * 2);
    BlockWrite(F, ThousandsSeparator, SizeOf(Char));
    StoreString(ArcNameFilter);
    BlockWrite(F, PrevHelpUsed, SizeOf(Boolean));
    BlockWrite(F, ArcCopyCRC, SizeOf(Longint));
    BlockWrite(F, CopyResultAs, SizeOf(Byte) * 2);
    BlockWrite(F, SaveClipboardData, SizeOf(Boolean));
    if SaveClipboardData then StoreString(ClipName);
    BlockWrite(F, DriveListOptions, SizeOf(Byte));
    StoreString(FMMacroName);
    StoreString(TermMacroName);
    BlockWrite(F, ProtocolPrompt, SizeOf(Boolean));
    BlockWrite(F, LastMacroNameCRC, SizeOf(Longint));
    BlockWrite(F, TagChar, SizeOf(Char));
    BlockWrite(F, AutoDecode, SizeOf(Byte));
    BlockWrite(F, UserDrives, SizeOf(TUserDrives));
    BlockWrite(F, NetList^.Count, SizeOf(Integer));
    for N := 0 to NetList^.Count - 1 do
      StoreString(PString(NetList^.At(N))^);
    BlockWrite(F, CmpAdvOpt, SizeOf(Longint) + SizeOf(Word));
    BlockWrite(F, WordStarKeys, SizeOf(Word));
    BlockWrite(F, StdDlg.ViewLine, SizeOf(Boolean) + SizeOf(Boolean) +
      SizeOf(Byte) + SizeOf(Byte));
    if IOResult <> 0 then ConfigWriteErrorMsgBox;
    Close(F);
    InOutRes := 0;
  end
  else ConfigCreateErrorMsgBox;
  if RGBOptions and 1 <> 0 then StoreRGB;
end;

procedure SaveDesktopFile;
var
  S: TDosStream;
  EF: File;
  Name: FNameStr;
begin
  LogEvent := lcConfig;
  DrawStatusLine('Writing desktop file.');
  SetConfigExt('DSK', Name);
  S.Init(Name, stCreate);
  if S.Status <> stOk then DesktopCreateErrorMsgBox
  else
  begin
    S.Write(TByteArray(GetStrAddr(DSKSignature)^)[1], Length(DSKSignature));
    StoreDesktop(S);
    if S.Status <> stOk then
    begin
      DesktopWriteErrorMsgBox;
      Assign(EF, Name);
      Erase(EF);
      InOutRes := 0;
    end;
  end;
  S.Done;
end;

begin
  if Force or DesktopData^.SaveEnvironment then SaveConfigFile;
  if Force or DesktopData^.SaveDesktop then SaveDesktopFile;
end;

procedure SetClipSaveName(var Name: FNameStr);
begin
  Name := ForceExtension(DiskClipName, '###');
end;

procedure LoadClipboard;
var
  S: TDosStream;
  Name: FNameStr;
begin
  SetClipSaveName(Name);
  S.Init(Name, stOpenRead);
  if S.Status = stOk then
  begin
    ClipLines := PSwapLinesCollection(S.Get);
    if ClipLines = nil then
      ClipLines := New(PSwapLinesCollection, Init(16, 128))
    else if (DiskClipStream = nil) or (DiskClipStream^.GetSize = 0) then
      ClipLines^.FreeAll;
{    GetMem(ClipArea, SizeOf(TArea));}
    GetMemUMB(ClipArea, SizeOf(TArea));
    S.Read(ClipArea^, SizeOf(TArea));
    S.Read(ClipAreaSelected, SizeOf(Boolean));
  end
  else
  begin
    ClipLines := New(PSwapLinesCollection, Init(16, 128));
{    GetMem(ClipArea, SizeOf(TArea));}
    GetMemUMB(ClipArea, SizeOf(TArea));
    SetArea(ClipArea, 0, 1, 0, 1);
  end;
  S.Done;
end;

procedure StoreClipboard;
var
  S: TDosStream;
  Name: FNameStr;
begin
  Message(TheClipboard, evBroadcast, cmUpdateViews, nil);
  SetClipSaveName(Name);
  S.Init(Name, stCreate);
  if S.Status = stOk then
  begin
    S.Put(ClipLines);
    S.Write(ClipArea^, SizeOf(TArea));
    S.Write(ClipAreaSelected, SizeOf(Boolean));
  end;
  S.Done;
end;

procedure InitClipboard(const AName: FNameStr);
begin
  InitDiskClipStream(AName);
  LoadClipboard;
end;

procedure DoneClipboard(DoStore, DoErase: Boolean);
var
  F: File;
  Name: FNameStr;
begin
  if SaveClipboardData then
  begin
    DoStore := True;
    DoErase := False;
  end;
  if DoStore then StoreClipboard;
{  FreeMem(ClipArea, SizeOf(TArea));}
  FreeMemUMB(ClipArea, SizeOf(TArea));
  Dispose(ClipLines, Done);
  DoneDiskClipStream(DoErase);
  if DoErase then
  begin
    SetClipSaveName(Name);
    Assign(F, Name);
    Erase(F);
    InOutRes := 0;
  end;
end;

procedure CheckTimeDependables;
var
  Second: Byte;
  SaveTime: Word;
  NowTime: Time;
begin
  if AutoSaveTime <> 0 then
  begin
    NowTime := CurrentTime;
    if NowTime < LastTime then Inc(NowTime, SecondsInDay);
    if NowTime > LastTime + AutoSaveTime * 60 then
    begin
      SaveTime := AutoSaveTime;
      AutoSaveTime := 0;
      SaveAll;
      AutoSaveTime := SaveTime;
      LastTime := CurrentTime;
    end;
  end;
  if EndingBeepTime <> 0 then
  begin
    NowTime := CurrentTime;
    if NowTime < LastIdleTime then Inc(NowTime, SecondsInDay);
    if NowTime > LastIdleTime + EndingBeepTime then
      if LastIdleTime <> 0 then PlayEndingSignal;
    LastIdleTime := CurrentTime;
  end;
  if (SaverDelay <> 0) and (ScreenSaver = nil) then
  begin
    NowTime := CurrentTime;
    Second := NowTime mod 60;
    if NowSecond <> Second then
    begin
      NowSecond := Second;
      Inc(IdleSeconds);
      if (IdleSeconds - 1) div 60 >= Abs(SaverDelay) then
      begin
	Pending.What := evMouseMove;
	Pending.Buttons := 0;
	Pending.Double := True;
	Pending.Where.X := ScreenWidth - 1;
	Pending.Where.Y := 0;
      end;
    end;
  end;
end;

procedure TCBackground.Draw;
var
  I, Y: Integer;
  B: TDrawBuffer;
begin
  if not DrawUserScr and not (Pattern in [#0, #32]) then
    TBackground.Draw
  else for I := 0 to Size.Y - 1 do
  begin
    Y := I + Desktop^.Origin.Y;
    MoveChar(B, ' ', $07, Size.X);
    if (UserScreenBuffer <> nil) and (Y < UserScreenRows) then
      Move(UserScreenBuffer^[Y * UserScreenCols], B, UserScreenCols * 2);
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure TCBackground.HandleEvent(var Event: TEvent);
begin
  TBackground.HandleEvent(Event);
  if (Event.What = evMouseDown) and Event.Double and
     MouseInView(Event.Where) then
  begin
    DrawUserScr := not DrawUserScr;
    DrawView;
    Event.What := evNothing;
  end;
end;

procedure TCDesktop.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evKeyDown) and (Event.KeyCode = kbShiftF10) then
  begin
    Event.What := evBroadcast;
    Event.Command := cmFileManager;
  end;
  if Event.What = evBroadcast then
    case Event.Command of
      cmCopy, cmPaste, cmCursor, cmUserScreen:
	HandleAppBroadcast(Event);
      cmUpdateDisk: DoneFileOperation;
      cmReceivedFocus, cmReleasedFocus: Exit;
    end;
  TDesktop.HandleEvent(Event);
end;

procedure TCDesktop.InitBackground;
var
  R: TRect;
begin
  GetExtent(R);
  Background := New(PCBackground, Init(R, PatternChar));
end;

end.
