{$F+,O+,X+}
unit AppCmnd;

interface

uses Drivers;

procedure HandleTopLineMouseEvent(var Event: TEvent);
procedure HandleMacroEvent(var Event: TEvent);
procedure WaitForHotKey(var Event: TEvent);
procedure DialogFromWithinDialog(var Event: TEvent);
procedure HandleAppHotKey(var Event: TEvent);
procedure HandleAppKeyCall(var Event: TEvent);
procedure HandleAppCommand(var Event: TEvent);
procedure HandleAppBroadcast(var Event: TEvent);

implementation

uses
  About, Alarm, App, ASCIITab, Calc, Calendar, CColors, CDPlayer,
  Clipbrd, ClipPrim, CmntDlg, CNMacros, CodeWin, Commands, Compiler,
  CopyScr, Country, Cursors, DataView, Decoders, Defaults, Desktops,
  DialDlg, DosTools, DumpWin, EditMsg, EnvDlg, ExecPrim, Exploder,
  FileMngr, FindDlg, GroupDlg, HideMain, HistList, HTMLView, KbdDlg,
  Keyboard, MacroDlg, Macros, MapWin, Mouse, MsgWin, Objects, OpenHelp,
  OpenPrim, Options, OutWin, Phones, RegExDlg, Ruler, SpoolDlg, StdDlg,
  Swaps, Terminal, TileAr, UserScr, Views, WatchWin, WinList;

procedure HandleTopLineMouseEvent(var Event: TEvent);
begin
  if (Event.Buttons = mbLeftButton) and (Event.Where.X = 0) and
     (HideOptions and hvMenuBar = 0) then
  begin
    Event.What := evCommand;
    Event.Command := cmList;
  end
  else if Event.Buttons = mbRightButton then
    if Event.Where.X = 0 then DragRuler(Event)
    else if (Event.Where.X <= 64) and
      (HideOptions and hvMenuBar <> 0) and
        NoModalWindows then MenuBar^.Show;
end;

procedure HandleMacroEvent(var Event: TEvent);
begin
  if EscPressed then
  begin
    ClearMacroEvents;
    repeat until not EscPressed;
    Event.What := evNothing;
  end
  else
  begin
    Application^.Idle;
    if Pending.What <> evNothing then
    begin
      Event := Pending;
      Pending.What := evNothing;
    end
    else GetMacroEvent(Event);
    if Event.What = evCommand then
      if Event.Command = cmPause then
      begin
        if Event.InfoWord = 0 then MacroWaiting := True
        else Pause(Event.InfoWord);
        Event.What := evNothing;
      end
      else if not Application^.CommandEnabled(Event.Command) then
        Event.What := evNothing
      else Event.InfoPtr := nil;
    if Event.What = evKeyDown then StatusLine^.HandleEvent(Event);
  end;
end;

procedure WaitForHotKey(var Event: TEvent);
begin
  GetMouseEvent(Event);
  if Event.What = evNothing then
  begin
    GetKeyEvent(Event);
    if Event.What = evNothing then Application^.Idle
    else if RecordKeys then RecordKeyProc(Event.KeyCode);
  end;
end;

procedure DialogFromWithinDialog(var Event: TEvent);
begin
  case Event.Command of
    cmEditorGroups: CommentDialog;
    cmEditorKeys: EditorKeys;
    cmGroups: GroupDialog;
    cmFMFiles: FMFiles;
    cmFMKeys: FMKeys;
  end;
  Event.What := evNothing;
end;

procedure HandleCommand(var Event: TEvent; ACommand: Word);
begin
  Event.What := evCommand;
  Event.Command := ACommand;
  Event.InfoPtr := nil;
  Application^.HandleEvent(Event);
end;

procedure HandleAppHotKey(var Event: TEvent);
var
  KeyState: Byte;
  AltDown, CtrlDown, ShiftDown: Boolean;
begin
  KeyState := GetShiftState;
  AltDown := KeyState and kbAltShift <> 0;
  CtrlDown := KeyState and kbCtrlShift <> 0;
  ShiftDown := KeyState and (kbLeftShift + kbRightShift) <> 0;
  case Event.KeyCode of
    kbAltF5: if not CtrlDown then HandleCommand(Event, cmUserScreen);
    kbAltF6: if (Equipment <> 0) and not CtrlDown then
      HandleCommand(Event, cmToggleEGALines);
    kbAltF7: if NoModalWindows then
      begin
        Message(Desktop, evBroadcast, cmFindFileDlg, Desktop);
        Event.What := evNothing;
      end;
    kbAltQ: if CtrlDown and (not ProgRunning or NoModalWindows) then
      HandleCommand(Event, cmDosShell);
    kbAltC: if CtrlDown then HandleCommand(Event, cmCalendar);
    kbAltL: if CtrlDown then HandleCommand(Event, cmCalculator);
    kbAltT: if CtrlDown then HandleCommand(Event, cmASCIITable);
    kbAltN: if CtrlDown then RegExpDialog
      else if NoModalWindows then HandleCommand(Event, cmNext);
    kbAltZ: if CtrlDown or NoModalWindows then
      HandleCommand(Event, cmZoom);
    kbCtrlTab: if NoModalWindows then
      if ShiftDown then HandleCommand(Event, cmPrev)
      else HandleCommand(Event, cmNext);
    kbCtrlIns: if AltDown then HandleCommand(Event, cmShowClipboard);
    kbCtrlF12: if not NoModalWindows and
      (MenuBar^.State and sfModal = 0) then
        HandleCommand(Event, cmCopyToMT);
    kbShiftF12: if not NoModalWindows and
      (MenuBar^.State and sfModal = 0) then
        HandleCommand(Event, cmPasteFromMT);
    kbAltTilde: if not CtrlDown then
      begin
        if ShiftDown then HideOptions := HideOptions xor hvMenuBar
        else if HideOptions <> 0 then HideOptions := 0
        else HideOptions := hvMenuBar + hvStatusLine + hvClock + hvHeap;
        UpdateMainViews;
        Event.What := evNothing;
      end;
  end;
end;

procedure HandleAppKeyCall(var Event: TEvent);
begin
  if Event.What <> evKeyDown then
  begin
    Event.What := evKeyDown;
    Event.KeyCode := 0;
  end;
  if MacroCalled then MacroHotKey(Event)
  else if ProgramCalled then ExecHotKey(Event);
  Event.What := evNothing;
end;

procedure HandleAppCommand(var Event: TEvent);

procedure ProgramDebug(ACommand: Word);
begin
  if ProgRunning and not Debugging then
  begin
    Pending.What := evCommand;
    Pending.Command := ACommand;
    if not AbortUserProgram then Exit;
  end;
  DebugCommand := ACommand - cmRun + 1;
  if not Debugging or CPUInUse then
    Message(Desktop, evBroadcast, ACommand, nil);
  if not Debugging then
  begin
    CompileDebug;
    if CompileResult = 0 then
    begin
      SaveOnRun;
      RunDebug;
    end;
  end;
end;

var
  B: Boolean;
begin
  case Event.Command of
    cmRetrieveOptions:
      begin
        Pending := Event;
        if AbortUserProgram then RetrieveOptions;
      end;
    cmClearDesktop:
      begin
        Pending := Event;
        if AbortUserProgram then ClearDesktop;
      end;
    cmCompile:
      begin
        Pending := Event;
        if AbortUserProgram then Compile;
      end;
    cmChangeDirectory: ChangeDir;
    cmAbout:           LoadAboutDialog;
    cmSystemInfo:      SystemInfoDialog;
    cmAlarm:           AlarmDialog;
    cmSpooler:         SpoolerDialog;
    cmDialer:          DialDialog;
    cmCDPlayer:        LoadCDPlayer;
    cmCalendar:        if NoModalWindows then TCalendar else ExecCalendar;
    cmCalculator:      if NoModalWindows then LoadCalculator else ExecCalculator;
    cmASCIITable:      if NoModalWindows then LoadASCIITab else ExecASCIITab;
    cmColors:          LoadColorSel;
    cmKeyboard:        KbdDialog;
    cmMouse:           MouseDlg;
    cmCursor:          CursorDialog;
    cmCountry:         CountryDlg;
    cmSaveOptions:     SaveOptions;
    cmMode:            Mode;
    cmEditOptions:     EditorOptions('', EditOptions, NewEditOptions,
                         TabSize, MaxLineWidth, @WordDelims, True, False);
    cmFMOptions:       FManagerOptions;
    cmUserOptions:     UserOptions;
    cmLogFile:         LogFileOptions;
    cmOverlay:         OvrOptions;
    cmPrinterSetup:    PrinterSetup;
    cmCDOptions:       CDOptions;
    cmSetup:           Setup;
    cmConfirmations:   Confirmations;
    cmUpdateASCII:     Update(False);
    cmUpdateHex:       Update(True);
    cmRefreshDisplay:  RefreshDisplay;
    cmNewASCII:        LoadFile('', nil, False, False);
    cmNewHex:          LoadFile('', nil, False, True);
    cmSaveAll:         SaveAll;
    cmLoadIcon:        LoadIcon(Event.InfoPtr);
    cmShowClipboard:   if NoModalWindows then ShowClipboard else ExecClipboard;
    cmMultiSearch:     MultiSearchDialog;
    cmRun, cmGoToCursor, cmTraceInto,
    cmStepOver:        ProgramDebug(Event.Command);
    cmProgramReset:    DebugCommand := dcReset;
    cmOpenCPUWindow:   OpenCPUWindow := not OpenCPUWindow;
    cmList:            List;
    cmMessage:         MessageWindow;
    cmTerminal:        OpenTerminal;
    cmBack:            OpenBack;
    cmUserScreen:      UserScreen;
    cmUserMacros:      UserMacros(Event.InfoPtr);
    cmRecordMacro:     StartRecordingMacro;
    cmStopRecording:   StopRecordingMacro;
    cmMacro:           WaitForMacro;
    cmExecute:         WaitForProgram;
    cmUserPrograms:    ProgDlg(Event.InfoPtr);
    cmUserMenu:        UserMenuDlg(nil, GetShiftState and (kbLeftShift + kbRightShift) <> 0);
    cmPhoneBook:       PhoneBook;
    cmFileManager:     FileManager;
    cmCascade:         if GetTileArea then Desktop^.Cascade(TileArea);
    cmTile:            if GetTileArea then Desktop^.Tile(TileArea);
    cmReopen..
    cmReopen + 64:     Reopen(Event.Command - cmReopen);
    cmReopenHelp..
    cmReopenHelp + 64: ReopenHelp(Event.Command - cmReopenHelp);
    cmOpenASCII:
      if Event.InfoPtr <> nil then
        LoadFile(PString(Event.InfoPtr)^, Event.InfoPtr, False, False)
      else OpenFile(False);
    cmOpenHex:
      if Event.InfoPtr <> nil then
        LoadFile(PString(Event.InfoPtr)^, Event.InfoPtr, False, True)
      else OpenFile(True);
    cmOpenTextViewer:
      if Event.InfoPtr <> nil then
        LoadFile(PString(Event.InfoPtr)^, Event.InfoPtr, True, False)
      else
      begin
        ViewLine := True;
        OpenFile(False);
      end;
    cmOpenHexViewer:
      if Event.InfoPtr <> nil then
        LoadFile(PString(Event.InfoPtr)^, Event.InfoPtr, True, True)
      else
      begin
        ViewLine := True;
        OpenFile(True);
      end;
    cmOpenDataViewer:
      if Event.InfoPtr <> nil then
        OpenDataViewer(PString(Event.InfoPtr)^, Event.InfoPtr);
    cmOpenHTML:
      if Event.InfoPtr <> nil then
        LoadFile('', Event.InfoPtr, True, False);
    cmWatch:
      if Message(Desktop, evBroadcast, cmWatch, nil) = nil then Watch;
    cmAddWatch:
      if Message(Desktop, evBroadcast, cmAddWatch, nil) = nil then
      begin
        Watch;
        Message(Desktop, evBroadcast, cmAddWatch, nil);
      end;
    cmEditWatch:
      if Message(Desktop, evBroadcast, cmEditWatch, nil) = nil then
      begin
        Watch;
        Message(Desktop, evBroadcast, cmEditWatch, nil);
      end;
    cmDeleteWatch:
      Message(Desktop, evBroadcast, cmDeleteWatch, nil);
    cmClearWatches:
      Message(Desktop, evBroadcast, cmClearWatches, nil);
    cmModify:          Modify;
    cmOutput:          OpenOutput;
    cmClearOutput:
      Message(Desktop, evBroadcast, cmClearOutput, nil);
    cmMap:
      if Message(Desktop, evBroadcast, cmMap, nil) = nil then Map;
    cmCode:            CodeWindow;
    cmDump:            DumpWindow;
    cmEnvDlg:          EnvDialog;
    cmToggleExplode:   ExplodeDialog;
    cmSaveClipData:    SaveClipboardData := not SaveClipboardData;
    cmToggleMarkMode:
      begin
        MarkColumns := not MarkColumns;
        Message(Desktop, evBroadcast, cmToggleMarkMode, nil);
      end;
    cmToggleEGALines:
      begin
        CustomVideoMode := 0;
        SetScreen(ScreenMode xor smFont8x8);
      end;
    cmAnimateTracing, cmAnimateStepping:
      begin
        Dec(Event.Command, 2);
        AnimateEvent := Event;
        Pending := Event;
      end;
    cmClearHistory:
      begin
        B := GetShiftState and (kbAltShift + kbCtrlShift) =
          kbAltShift + kbCtrlShift;
        if ClearHistoryMsgBox(B) <> cmCancel then
          if B then ClearHistory else ClearUnlockedHistory;
      end;
    cmCopyToMT:        ClipCopyToMT('', Event);
    cmPasteFromMT:     ClipPasteFromMT(Event);
    cmAltHelpName:     SetAltHelpName;
    cmDecoderList:     UserDefinedDecoderList(True);
    cmDecoders:        UserDefinedDecoderList(False);
    cmRegExpDlg:       RegExpDialog;
    cmAutoRegExp:      AutoRegExp;
  end;
end;

procedure HandleAppBroadcast(var Event: TEvent);
var
  S: String;
begin
  case Event.Command of
    cmCopy:
      begin
        PutLineToClipboard(Event.InfoPtr);
        Event.What := evNothing;
      end;
    cmPaste:
      begin
        Message(Application, evBroadcast, cmUpdateViews, nil);
        GetClipLine(ClipArea^.KB, S);
        Event.What := evNothing;
        Event.InfoPtr := @S;
      end;
    cmCursor:
      begin
        DesktopData^.Cursor := PtrRec(Event.InfoPtr).Ofs;
        DesktopData^.BlockCursor := PtrRec(Event.InfoPtr).Seg;
      end;
    cmUserScreen:
      begin
        ClipCopyUserScreen;
        Event.What := evNothing;
      end;
  end;
end;

end.