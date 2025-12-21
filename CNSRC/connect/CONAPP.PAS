{$I-,F-,O-,X+}
unit ConApp;

interface

uses Dos, Objects, Drivers, Views, App;

type
  PConnect = ^TConnect;
  TConnect = object(TApplication)
    constructor Init;
    destructor Done; virtual;
    procedure GetEvent(var Event: TEvent); virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Idle; virtual;
    procedure InitDesktop; virtual;
    procedure InitMenuBar; virtual;
    procedure InitResource; virtual;
    procedure InitStatusLine; virtual;
    procedure OutOfMemory; virtual;
  end;

  TSwapExecFunc = function(const Command: String; UseSecond: Boolean;
    EDP: Pointer; const SwapFName: PathStr;
    UseEMS, UseXMS, EMSOver, SwapMsg: Boolean): Integer;

var
  Connect: TConnect;
  SwapExecFunc: TSwapExecFunc;

procedure RunConnect;

implementation

uses
  CNCrt, AllTypes, AppCmnd, BarWin, Bounds, CDPlayer, CmntList, CNHist,
  CNMacros, Commands, Compiler, ConOvr, Consts, CPUWin, DataView, Date,
  Defaults, Desktops, Dialogs, DirPrim, DosTools, DrvList, EditMsg, ExecPrim,
  FEditor, FileMngr, FMBars, FMDrvSel, FMGroups, Gauges, HeapUMB, HelpFile,
  HelpPrim, HideMain, HistList, History, Keyboard, LFN, LogFile, MacroDlg,
  Macros, MapWin, Memory, MsgBox, MsgWin, OpenHelp, OpenPrim, Options,
  OS2Clip, OutWin, Overlay, OvrUMB, PanelRec, ProgPath, Redirect, RGBDlg,
  RMenus, Ruler, ScrSaver, Snipper, Spooler, StrCol, Streams, Strings,
  Swaps, Tags, Terminal, Timer, TPString, TxtView, UserScr, WatchWin,
  Disks, WinClip, WinIcons, OvrPrim, OPEnhKbd;

const
  CNewColor: String = CColor + CHelpColor + COutputColor +
    CBarColor + CMessageColor + CEditorColor + CWatchColor +
    CCPUColor + CMapColor + CPanelColor + CScreenSaverColor +
    CBoundsColor + CTerminalColor + CSyntaxColor + CViewerColor +
    CDataColor + CHelpExtraColor + CRulerColor + CDrvSelColor +
    CDBExtraColor + CCDColor + CClockColor + CHeapColor +
    CPanelBarColor + CInfoBoxColor;
  CNewBlackWhite: String = CBlackWhite + CHelpBlackWhite +
    COutputBlackWhite + CBarBlackWhite + CMessageBlackWhite +
    CEditorBlackWhite + CWatchBlackWhite + CCPUBlackWhite +
    CMapBlackWhite + CPanelBlackWhite + CScreenSaverBlackWhite +
    CBoundsBlackWhite + CTerminalBlackWhite + CSyntaxBlackWhite +
    CViewerBlackWhite + CDataBlackWhite + CHelpExtraBW + CRulerBW +
    CDrvSelBW + CDBExtraBW + CCDBW + CClockBW + CHeapBW +
    CPanelBarBW + CInfoBoxBW;
  CNewMonochrome: String = CMonochrome + CHelpMonochrome +
    COutputMonochrome + CBarMonochrome + CMessageMonochrome +
    CEditorMonochrome + CWatchMonochrome + CCPUMonochrome +
    CMapMonochrome + CPanelMonochrome + CScreenSaverMonochrome +
    CBoundsMonochrome + CTerminalMonochrome + CSyntaxMonochrome +
    CViewerMonochrome + CDataMonochrome + CHelpExtraMono + CRulerMono +
    CDrvSelMono + CDBExtraMono + CCDMono + CClockMono + CHeapMono +
    CPanelBarMono + CInfoBoxMono;
  Palettes: Array[apColor..apMonochrome] of PPalette =
    (@CNewColor, @CNewBlackWhite, @CNewMonochrome);

procedure WriteLogExecStr(const S: String);
begin
  if EnableLog and loEnable <> 0 then
  begin
    LogEvent := lcExec;
    WriteToLog(S);
    LogEvent := lcOther;
  end;
end;

constructor TConnect.Init;
const
  Signature = #1#2#3#4#5;
var
  TempByte: Byte absolute $40:$40;
  TempWord: Word absolute $40:$6C;
  DoOpen: Boolean;
  P: Integer;
  Params: PString;
  Names: PStringsCollection;
  Name, Mask: FNameStr;
begin
  Mask := 'CN' + HexB(TempByte) + HexW(TempWord);
  Params := Ptr(PrefixSeg, $80);
  P := Pos(Signature, Params^);
  if P <> 0 then
  begin
    Auto := False;
    ExchBufferPtr := Pointer(Ptr(PrefixSeg, $85 + P)^);
    Params^[0] := Char(P - 1);
    with ExchBufferPtr^ do
    begin
      ProgrToExecute := '';
      CmdLine := '';
      if (UniqueName[1] <> 'C') or (UniqueName[2] <> 'N') then
        UniqueName := Mask;
      TempName := UniqueName;
    end;
  end
  else TempName := Mask;
  if not Auto and (ExchBufferPtr^.Opts and xbNotFirstTime <> 0) then
    Mask := ''
  else Mask := GetEnv('CNCFG');
  LowMemSize := 512;
  WinIconHelpCtx := hcWinIcon;
  RegisterRMenus;
  RegisterType(RStringList);
  InitUMBHeap;
  InitUserScreen;
  HideGauges := hgHeap + hgClock;
  TApplication.Init;
  InitKbd;
  EnhKbd := HasEnhancedKbd;
  OS2Installed := OS2Detected;
  MultitaskerDetected := IdentifyWinOldAp;
{ Added 2005.12.25 }
  Inst_CN_NT;
  RegisterAllTypes;
  FillChar(PrevHelps, SizeOf(TPrevHelpArray), 0);
  HistoryStrProc := CNHistoryStr;
  DisableCommands(BlockCommands + PasteCommands + MTCommands +
    UndoCommands + RedoCommands + HexCommands + ASCIICommands +
    SaveAllCommands + DebugCommands + BreakpointCommands + FindCommands +
    SnipperCommands + EGACommands + WatchCommands + OutputCommands);
  if Equipment <> 0 then EnableCommands(EGACommands);
  SwapName := TempName + '.$$$';
  ClipName := TempName + '.@@@';
  DoOpen := False;
  if ParamCount = 0 then Names := nil
  else
  begin
    Names := New(PStringsCollection, Init(4, 4));
    FillStartOpenList(Names, Mask, DoOpen);
  end;
  if Auto then SourceName := ''
  else SourceName := ExchBufferPtr^.Source;
  DefaultPalette := GetPalette^;
  DefaultPalette[255] := Char(ShadowAttr);
  if (Mask = '') or DoOpen then
    if Auto then SetConfigName(ProgramPath + 'CONNECT')
    else SetConfigName(StUpcase(ExchBufferPtr^.ConfigMask))
  else SetConfigName(Mask);
  InitDesktopData;
  SetCNConfigName(Name, 'ALR');
  LoadDates(Name);
  SetCNConfigName(Name, 'EVN');
  LoadMacroEvents(Name);
  SetCNConfigName(Name, 'CMT');
  InitComments(Name);
  SetCNConfigName(Name, 'GRP');
  InitGroups(Name);
  TheSpooler := New(PSpooler, Init(1, 1));
  InitTagList;
  NetList := New(PStringsCollection, Init(8, 8));
  RetrieveDesktop;
  P := FileHandlesLeft;
  if P <= 4 then FileHandlesMsgBox(P);
  if DoOpen then
  begin
    HistoryAdd(OptionsHistoryID, Mask, True);
    RetrieveOptions;
  end;
  if Names <> nil then
  begin
    ProcessStartOpenList(Names);
    Dispose(Names, Done);
  end;
  if not Auto then
  begin
    if ExchBufferPtr^.Error <> 0 then
      SystemErrorMsgBox(ExchBufferPtr^.Error)
    else if (ExchBufferPtr^.Opts and xbRedirFlag <> 0) and
      (ExchBufferPtr^.Opts and xbNoMsgWinFlag = 0) then MessageWindow;
    if ExchBufferPtr^.Opts and xbMultiExecFlag <> 0 then LoadMultiExecRec;
  end;
end;

destructor TConnect.Done;
var
  ForGood: Boolean;
  I: Integer;
  S: String;
begin
  ForGood := Auto or (ExchBufferPtr^.ProgrToExecute = '');
  if ForGood then
  begin
    SaveDesktop(False);
    if not Auto and not DesktopData^.ReturnToDirOnExit then
    begin
      GetDir(0, S);
      StrPCopy(ExchBufferPtr^.OldDir, S);
    end;
  end;
  if MacroRecording then StopRecordingMacro;
  SetCNConfigName(S, 'EVN');
  StoreMacroEvents(S);
{  DisposeStr(CopyRenameFilter.Text);}
  DisposeStrUMB(CopyRenameFilter.Text);
  DoneClipboard(not ForGood, ForGood);
  DoneDiskSwapStream;
  Dispose(NetList, Done);
  DoneTagList;
  if TheSpooler^.Count <> 0 then TheSpooler^.DonePrinter;
  Dispose(TheSpooler, Done);
  DoneGroups;
  DoneComments;
  DoneMacroEvents;
  Dispose(Dates, Done);
  DoneDesktopData;
  DoneKbd;
  DoExplode := False;
  TApplication.Done;
  for I := 0 to MaxHelps - 1 do
{    DisposeStr(PrevHelps[I].PrevName);}
    DisposeStrUMB(PrevHelps[I].PrevName);
  DoneUserScreen;
  if not ForGood then
  begin
    if ExchBufferPtr^.Opts and xbRedirFlag = 0 then
      S := PromptLikeStr(ExchBufferPtr^.ProgrToExecute) + ' ' +
        ExchBufferPtr^.CmdLine
    else S := 'Running ' + ExchBufferPtr^.ProgrToExecute + '.';
    PrintStr(S + #13#10);
    WriteLogExecStr(S);
{ Added 2006.01.03 }
    SetApplicationTitle(S);
  end;
end;

procedure TConnect.Idle;
begin
{ Added 04.17.03 to support Ignore All SysErrors }
  if not DisableIgnoreAllReset then IgnoreAllSysErrors := False;
  IdleState := not MacroRunning and (TheSpooler^.Count = 0);
  if MacroCalled or ProgramCalled then
  begin
    GiveTicks;
    Clock^.Update;
    Heap^.Update;
  end
  else
  begin
    CheckAltCtrlStroke;
    TApplication.Idle;
    if not MacroRunning or MacroWaiting then CheckTimeDependables;
    if not ProtInProg then Dates^.ProcessItems;
    if TheSpooler^.Count <> 0 then TheSpooler^.ProcessItems;
    if TimerInUse then ExecTimer;
    if DisableSysinfo then DisableCommands(SysinfoCommands)
    else EnableCommands(SysinfoCommands);
    if not Auto and ExchBufferPtr^.SnippInUse and
      (ExchBufferPtr^.TxtBufferEnd <> 0) then CopySnipper;
    if RevProg then RevProgram;
  end;
  if FirstIdleCall then
  begin
    if MouseOptions and moDisable = 0 then
    begin
      DetectMouse;
      RefreshDisplay;
      if MouseOptions and moSavePos <> 0 then
        SetMouseCursor(DesktopData^.MouseX, DesktopData^.MouseY);
    end;
    DelayInit;
    FirstIdleCall := False;
  end;
  IdleState := False;
end;

procedure TConnect.GetEvent(var Event: TEvent);
begin
  XVideoMode := 0;
  if MacroRunning and not MacroWaiting then HandleMacroEvent(Event)
  else if MacroCalled or ProgramCalled then WaitForHotKey(Event)
  else TApplication.GetEvent(Event);
  if (Event.What <> evNothing) or (GetShiftState and
     (kbLeftShift + kbRightShift + kbAltShift + kbCtrlShift) <> 0) then
  begin
    IdleSeconds := 0;
    if TimerActionClears and (Event.What <> evMouseMove) then
      TimerInUse := False;
    if Event.What <> evNothing then AltCtrlEvent := True;
  end;
  if MacroRecording and CtrlBreakHit then BreakRecordingMacro;
  if ScreenSaver <> nil then PGroup(ScreenSaver)^.HandleEvent(Event);
  if TheTerminal <> nil then
  begin
    PTerminal(TheTerminal)^.CheckRS(Event);
    if (Event.What <> evNothing) and
       not MacroCalled and not ProgramCalled and
       (PTerminal(TheTerminal)^.Owner <> nil) and
       (PTerminal(TheTerminal)^.Owner^.State and
       (sfActive + sfFocused + sfDragging) = (sfActive + sfFocused)) then
      PTerminal(TheTerminal)^.HandleEvent(Event)
  end;
  if CDPlayers <> nil then UpdateCDPlayers;
  if Event.What = evCommand then
    case Event.Command of
      cmExecRec: HandleEvent(Event);
      cmHelp, cmContents, cmTopicSearch, cmPreviousTopic: CallHelp(Event);
      cmEditorGroups, cmEditorKeys, cmGroups, cmFMFiles, cmFMKeys:
        DialogFromWithinDialog(Event);
    end
  else if (Event.What = evMouseMove) and (Event.Buttons = 0) and
    (Event.Where.X = ScreenWidth - 1) and (Event.Where.Y = 0) and
    ((SaverDelay > 0) or Event.Double) and
    not (MacroCalled or ProgramCalled) then
  begin
    Event.What := evNothing;
    DrawScreenSaver;
  end
  else if (Event.What = evMouseDown) and (Event.Where.Y = 0) then
    HandleTopLineMouseEvent(Event)
  else if Event.What = evKeyDown then
    if MacroWaiting and (Event.KeyCode = kbAltF8) and
      (GetShiftState and kbCtrlShift = 0) then
    begin
      MacroWaiting := False;
      Event.What := evNothing;
    end
    else if not MacroCalled and not ProgramCalled then
      case Event.KeyCode of
        kbAltF5, kbAltF6, kbAltF7,
        kbAltQ, kbAltC, kbAltL, kbAltT,
        kbAltN, kbAltZ, kbCtrlTab, kbCtrlIns,
        kbCtrlF12, kbShiftF12, kbAltTilde: HandleAppHotKey(Event);
      end;
end;

function TConnect.GetPalette: PPalette;
begin
  GetPalette := Palettes[AppPalette];
end;

procedure TConnect.InitDesktop;
var
  R: TRect;
begin
  GetExtent(R);
  Dec(R.B.Y);
  Desktop := New(PCDesktop, Init(R));
end;

procedure TConnect.InitMenuBar;
begin
  MenuBar := PRMenuBar(Resource^.Get('MENUBAR'));
  MenuBar^.Hide;
end;

procedure TConnect.InitResource;
const
  Volume = $EFFF;
var
  DiskStream, MemStream: PStream;
begin
  DiskStream := New(PDosStream, Init(ParamStr(0), stOpenRead));
  Resource := New(PResourceFile, Init(DiskStream));
  case ovPref of
    ovEMSOnly, ovEMSOver: MemStream := New(PEMSStream, Init(Volume, Volume));
    ovXMSOnly, ovXMSOver: MemStream := New(PXMSStream, Init(Volume, Volume));
  end;
  if MemStream^.Status <> stOk then
  begin
    Dispose(MemStream, Done);
    case ovPref of
      ovEMSOver: MemStream := New(PXMSStream, Init(Volume, Volume));
      ovXMSOver: MemStream := New(PEMSStream, Init(Volume, Volume));
      else Exit;
    end;
  end;
  if MemStream^.Status = stOk then
  begin
    DiskStream := Resource^.SwitchTo(MemStream, False);
    Dispose(DiskStream, Done);
  end
  else Dispose(MemStream, Done);
end;

procedure TConnect.InitStatusLine;
begin
  StatusLine := PRStatusLine(Resource^.Get('STATUSLINE'));
  StatusLine^.MoveTo(0, ScreenHeight - 1);
  PRStatusLine(StatusLine)^.HintsList := PStringList(Resource^.Get('HINTS'));
end;

procedure TConnect.OutOfMemory;
begin
  OutOfMemoryMsgBox;
end;

procedure FillExchBuffer;
begin
  with ExchBufferPtr^ do
  begin
    FillChar(ProgrToExecute,
      SizeOf(ProgrToExecute) + SizeOf(CmdLine), 0);
    ProgrToExecute := ExecRec.Path;
    CmdLine := ExecRec.Params;
    Source := SourceName;
    StrPCopy(ReportName, ReportFile);
    Error := 0;
    Opts := xbNotFirstTime;
    if ExecRec.Options and opMessage <> 0 then
    begin
      Opts := Opts or xbRedirFlag;
      if ExecRec.Options and opStdError <> 0 then
        Opts := Opts or xbRedirErrFlag;
    end;
    if ExecRec.Options and opNoMsgWin <> 0 then
      Opts := Opts or xbNoMsgWinFlag;
    if ExecRec.Options and opLoadCOMMANDCOM <> 0 then
      Opts := Opts or xbCommandFlag;
    if MultiExec then Opts := Opts or xbMultiExecFlag;
    SnippFlag := ExecRec.Setup and suLoadSnipper <> 0;
    VideoSeg := PtrRec(ScreenBuffer).Seg;
  end;
end;

procedure TConnect.HandleEvent(var Event: TEvent);

procedure SaveEMSCtx(Handle: Word); assembler;
asm
        MOV     DX,Handle
        MOV     AH,47H
        INT     67H
end;

procedure RestoreEMSCtx(Handle: Word); assembler;
asm
        MOV     DX,Handle
        MOV     AH,48H
        INT     67H
end;

procedure SaveEMSMap;
begin
  if OvrEMSHandle <> $FFFF then SaveEMSCtx(OvrEMSHandle);
  if (Resource <> nil) and
     (TypeOf(Resource^.Stream^) = TypeOf(TEMSStream)) then
    SaveEMSCtx(PEMSStream(Resource^.Stream)^.Handle);
  if (DiskSwapStream <> nil) and
     (TypeOf(DiskSwapStream^) = TypeOf(TEMSStream)) then
    SaveEMSCtx(PEMSStream(Resource^.Stream)^.Handle);
end;

procedure RestoreEMSMap;
begin
  if OvrEMSHandle <> $FFFF then RestoreEMSCtx(OvrEMSHandle);
  if (Resource <> nil) and
     (TypeOf(Resource^.Stream^) = TypeOf(TEMSStream)) then
    RestoreEMSCtx(PEMSStream(Resource^.Stream)^.Handle);
  if (DiskSwapStream <> nil) and
     (TypeOf(DiskSwapStream^) = TypeOf(TEMSStream)) then
    RestoreEMSCtx(PEMSStream(Resource^.Stream)^.Handle);
end;

procedure OpenDiskStreams(SwapOnDisk: Boolean);
begin
  if SwapOnDisk then
    PDosStream(DiskSwapStream)^.Open(DiskSwapName, stOpen);
  if DiskClipStream <> nil then
    PDosStream(DiskClipStream)^.Open(DiskClipName, stOpen);
end;

procedure CloseDiskStreams(var SwapOnDisk: Boolean);
begin
  if DiskClipStream <> nil then PDosStream(DiskClipStream)^.Close;
  if (DiskSwapStream <> nil) and
     (TypeOf(DiskSwapStream^) = TypeOf(TDosStream)) then
  begin
    PDosStream(DiskSwapStream)^.Close;
    SwapOnDisk := True;
  end
  else SwapOnDisk := False;
end;

procedure MoveHeap;
var
  H, O: Word;
begin
  DoneMemory;
  OvrClearBuf;
  if OvrUMBSeg <> 0 then MoveHeapToUMB
  else
  begin
    H := PtrRec(HeapOrg).Seg;
    O := OvrHeapOrg;
    repeat
      Move(Ptr(H, 0)^, Ptr(O, 0)^, 16);
      Inc(H);
      if H > PtrRec(HeapPtr).Seg then Break;
      Inc(O);
    until False;
    PtrRec(HeapPtr).Seg := O;
  end;
end;

procedure RestoreHeap;
var
  H, O: Word;
begin
  if OvrUMBSeg <> 0 then RestoreHeapFromUMB
  else
  begin
    H := PtrRec(HeapOrg).Seg + PtrRec(HeapPtr).Seg - OvrHeapOrg;
    O := PtrRec(HeapPtr).Seg;
    PtrRec(HeapPtr).Seg := H;
    repeat
      Move(Ptr(O, 0)^, Ptr(H, 0)^, 16);
      Dec(O);
      if O < OvrHeapOrg then Exit;
      Dec(H);
    until False;
  end;
end;

{ Added 2006.01.03 }
procedure SetApplicationTitleState;
var
  P: PView;
begin
  if NoModalWindows then P := Desktop^.Current
  else P := Application^.TopView;
  if P <> nil then P^.SetState(sfFocused, True);
end;

procedure DosShell;
var
  OnDisk: Boolean;
  SaveMode: Word;
begin
  SaveMode := ScreenMode;
  if DesktopData^.SaveEditorFiles then SaveAll;
  SaveDesktop(False);
  if TheTerminal <> nil then PTerminal(TheTerminal)^.DoneComPort;
  CloseDiskStreams(OnDisk);
  SaveEMSMap;
  DoneKbd;
  DoneSysError;
  DoneEvents;
  DoneVideo;
  PrintStr('Type EXIT to return to The IBM HandShaker...'#13#10);
{ Added 2006.01.03 }
  SetApplicationTitle('COMMAND');
  DoneEnhKbd;
  MoveHeap;
  DoneDosMem;
  SwapVectors;
  Exec(GetEnv('COMSPEC'), '');
  SwapVectors;
  InitDosMem;
  RestoreHeap;
  InitEnhKbd;
  InitVideo;
  InitEvents;
  InitSysError;
  InitKbd;
  RestoreEMSMap;
  OpenDiskStreams(OnDisk);
  if (RGBOptions and 1 <> 0) and (SaveRGB[0] = #48) then SetRGB;
  if FMOptions and foDrawEmpty <> 0 then GlobalEmptyFlag := True;
  UpdateScreen(SaveMode);
  GlobalEmptyFlag := False;
  LastIdleTime := 0;
  if TheTerminal <> nil then PTerminal(TheTerminal)^.InitComPort;
  Message(Desktop, evBroadcast, cmReRead, nil);
  Message(Desktop, evBroadcast, cmUpdateTime, nil);
{ Added 2006.01.03 }
  SetApplicationTitleState;
  RevProg := True;
end;

function TransferDialog(const Msg: String; {OnDesktop: Boolean;}
  var DlgOwner: PGroup): PDialog;
var
  C: Word;
  D: PDialog;
  R: TRect;
begin
  C := Application^.GetHelpCtx;
  R.Assign(0, 0, Length(Msg) + 8, 5);
  D := New(PDialog, Init(R, 'Transfer'));
  with D^ do
  begin
    Options := Options or (ofCentered + ofNotStorable);
    HelpCtx := C;
    Flags := 0;
    R.Assign(4, 2, Size.X - 3, 3);
    Insert(New(PStaticText, Init(R, Msg)));
{
    if OnDesktop then
    begin
      State := State or sfModal;
      DlgOwner := Desktop;
    end
    else
    begin
}
      Options := Options and not (ofSelectable + ofTopSelect);
      Frame^.State := Frame^.State or sfActive;
      DlgOwner := Application;
{
    end;
}
  end;
  TransferDialog := D;
end;

procedure RunAuto;
var
  UseMem, UseEMS, UseXMS, EMSOver, OnDisk,
  SwitchToUserScr, Xfer, XNT: Boolean;
  SaveMode: Word;
  SaveMouse: TPoint;
  L: Longint;
  D: PDialog;
  DlgOwner: PGroup;
  S: FNameStr;
  SS: String;
begin
  XNT := ExecRec.Main = mnXNT;
  SaveMode := ScreenMode;
  SaveMouse := MouseWhere;
  if XNT then
  begin
    SwitchToUserScr := False;
    Xfer := ExecRec.Options and opNoXfer = 0;
  end
  else
  begin
    if (ExecRec.Main = mnSwap) and (MemAvail + ovBufSize > ExecMem) then
      ExecRec.Main := mnNone;
    GetValidSwapDir(S, False);
    UseMem := ExecRec.Options and opSwapToDisk = 0;
    UseEMS := UseMem and (ovPref <> ovXMSOnly);
    UseXMS := UseMem and (ovPref <> ovEMSOnly);
    EMSOver := ovPref = ovEMSOver;
    CloseDiskStreams(OnDisk);
    SwitchToUserScr :=
      (ExecRec.Options and opMessage = 0) or
      (ExecRec.Options and opUserScr <> 0);
    Xfer := ExecRec.Options and opNoXfer = 0;
    SaveEMSMap;
    DoneKbd;
    DoneSysError;
    DoneEvents;
  end;
  if TheTerminal <> nil then PTerminal(TheTerminal)^.DoneComPort;
  if not SwitchToUserScr then
  begin
    {SS := Concat('Running ', ExecRec.Path, '.');}
    if XNT then SS := 'Running NT executor.'
    else SS := Concat('Running ', ExecRec.Path, '.');
    if Xfer then
    begin
      D := TransferDialog(SS, {NoModalWindows,} DlgOwner);
      DlgOwner^.Insert(D);
    end;
    WriteLogExecStr(SS);
    LogEvent := 0;
    DrawStatusLine('Executing an external program.');
asm
        MOV     AH,2
        XOR     BH,BH
        XOR     DX,DX
        INT     10H
end;
  end
  else
  begin
    DoneVideo;
    SS := Concat(PromptLikeStr(ExecRec.Path), ' ', ExecRec.Params);
    PrintStr(Concat(SS, #13#10));
    WriteLogExecStr(SS);
    LastIdleTime := 0;
  end;
{ Added 2006.01.03 }
  SetApplicationTitle(SS);
  if XNT then L := ExecNT
  else
  begin
    DoneEnhKbd;
    MoveHeap;
    DoneDosMem;
    if ExecRec.Options and opMessage <> 0 then
      Output2File(ReportFile, ExecRec.Options and opStdError <> 0);
    if ExecRec.Main = mnNone then
    begin
      SwapVectors;
      if ExecRec.Options and opLoadCOMMANDCOM <> 0 then Exec(
        GetEnv('COMSPEC'), Concat('/C ', ExecRec.Path, ' ', ExecRec.Params))
      else Exec(ExecRec.Path, ExecRec.Params);
      SwapVectors;
      L := DosError;
    end
    else L := SwapExecFunc(Concat(ExecRec.Path, ' ', ExecRec.Params),
      ExecRec.Options and opLoadCOMMANDCOM <> 0, nil,
      Concat(S, TempName, '.!!!'), UseEMS, UseXMS, EMSOver, SwitchToUserScr);
    if ExecRec.Options and opMessage <> 0 then
      StdOutput(ExecRec.Options and opStdError <> 0);
    InitDosMem;
    RestoreHeap;
    InitEnhKbd;
    if SwitchToUserScr then InitVideo;
    InitEvents;
    InitSysError;
    InitKbd;
    RestoreEMSMap;
    OpenDiskStreams(OnDisk);
  end;
  if TheTerminal <> nil then PTerminal(TheTerminal)^.InitComPort;
  if (RGBOptions and 1 <> 0) and (SaveRGB[0] = #48) then SetRGB;
  SetMouseCursor(SaveMouse.X shl 3, SaveMouse.Y shl 3);
  if ExecRec.Options and opNoRedraw = 0 then
  begin
    StatusLine^.Update;
    if (FMOptions and foDrawEmpty <> 0) and
       (ExecRec.Options and opNoReread = 0) then GlobalEmptyFlag := True;
    UpdateScreen(SaveMode);
    GlobalEmptyFlag := False;
  end
  else if not GlobalRedrawLock then UpdateScreen(SaveMode);
  if ExecRec.Options and opNoReread = 0 then
  begin
    Message(Desktop, evBroadcast, cmReRead, nil);
    Message(Desktop, evBroadcast, cmUpdateTime, nil);
  end;
  if L <> 0 then ExecErrorMsgBox(L, ExecRec.Path);
  if not SwitchToUserScr and Xfer then
  begin
    DlgOwner^.Delete(D);
    Dispose(D, Done);
  end;
  if (ExecRec.Options and opMessage <> 0) and
     (ExecRec.Options and opNoMsgWin = 0) then MessageWindow;
{ Added 2006.01.03 }
  SetApplicationTitleState;
  RevProg := True;
  if MultiExec then LoadMultiExecRec;
end;

procedure ExecuteProg;
var
  SelfExec: Boolean;
begin
  SelfExec := Auto or (ExecRec.Main <> mnUnload);
  if ExecRec.Setup and suSaveEditorFiles <> 0 then SaveAll
  else if not SelfExec and not SaveOnExit then
  begin
    CancelExecution;
    Exit;
  end;
  if ExecRec.Setup and suSaveDesktop <> 0 then
    SaveDesktop(DesktopData^.SaveDesktop);
  if ExecRec.Options and opMessage <> 0 then SaveMsgFilters;
  if SelfExec then RunAuto
  else
  begin
    FillExchBuffer;
    EndModal(cmQuit);
  end;
end;

begin
  if (MacroCalled or ProgramCalled) and
     ((Event.What = evKeyDown) or (Event.What = evMouseDown)) then
    HandleAppKeyCall(Event);
  if (Event.What = evCommand) and (Event.Command = cmQuit) then
  begin
    if (ConfirmOptions and coExit <> 0) and (ExitMsgBox <> cmYes) then
    begin
      Event.What := evNothing;
      Exit;
    end;
    PutEvent(Event);
    if not AbortUserProgram or not SaveOnExit then Event.What := evNothing;
  end;
  TApplication.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmExecRec:
        if (ExecRec.Options and opPrepared <> 0) or PrepareExecPrim then
        begin
          PutEvent(Event);
          if AbortUserProgram then ExecuteProg;
        end;
      cmDosShell:
        begin
          PutEvent(Event);
          if AbortUserProgram then DosShell;
        end;
      else HandleAppCommand(Event);
    end;
    Event.What := evNothing;
  end;
end;

var
  ExitSave: Pointer;

procedure ConnectExitProc; far;
var
  Params: Array[0..2] of Longint;
  S: String;
begin
  DoneKbd;
  DoneSysError;
  DoneEvents;
  DoneVideo;
  Params[0] := ExitCode;
  Params[1] := LongRec(ErrorAddr).Hi;
  Params[2] := LongRec(ErrorAddr).Lo;
  FormatStr(S,
    'Unrecoverable application error %d at %04x:%04x.'#13#10, Params);
  PrintStr(S);
  ErrorAddr := nil;
  ExitProc := ExitSave;
end;

procedure RunConnect;
begin
  ExitSave := ExitProc;
  ExitProc := @ConnectExitProc;
  Connect.Init;
  Connect.Run;
  Connect.Done;
  ExitProc := ExitSave;
  OvrDisposeStreams;
end;

end.