{$I-,X+,O+,F+}
unit MacroDlg;

interface

uses Objects, Drivers, Views, Dialogs, Macros, HotKeys, KeyDlg;

type
  PCommandCollection = ^TCommandCollection;
  TCommandCollection = object(TSortedCollection)
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PMacro = ^TMacro;
  TMacro = object(TObject)
    Title: PString;
    HotKey: Word;
    HotKeyCount: Word;
    HotKeySequence: PHotKeySequence;
    HotKeyOpt: Word;
    HotKeyReserved: Pointer;
    Events: PEventCollection;
    constructor Init;
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Store(var S: TStream); virtual;
    procedure GetData(var ATitle: String; var AHotKey: Word);
    procedure SetData(const ATitle: String; AHotKey: Word);
  end;

  PMacrosList = ^TMacrosList;
  TMacrosList = object(TListBox)
    FileName: PString;
    LockFocus: Boolean;
    SequenceText: PStaticText;
    constructor Init(var Bounds: TRect; FName: String;
      AScrollBar: PScrollBar);
    destructor Done; virtual;
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure FillList(const FName: String);
    procedure SaveList(const FName: String; ANew: Boolean);
    procedure FileOperation(ACommand: Word);
    procedure ModifyMacro;
    procedure NewMacro;
    procedure DeleteMacro;
    procedure NewItemPos;
    procedure CheckDuplicates(AKey: Word;
      ASequence: PHotKeySequence; ACount: Word);
    procedure UpdateCommands;
  end;

  PEventsList = ^TEventsList;
  TEventsList = object(TListBox)
    EventCollection: PEventCollection;
    constructor Init(var Bounds: TRect; ANumCols: Word;
      AScrollBar: PScrollBar; ASource: PEventCollection);
    destructor Done; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure FillList(Source: PEventCollection);
  end;

  PCommandsList = ^TCommandsList;
  TCommandsList = object(TListBox)
    CommandCollection: PCommandCollection;
    constructor Init(var Bounds: TRect; ANumCols: Word;
      AScrollBar: PScrollBar);
    destructor Done; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure FillList;
  end;

  PUserDialog = ^TUserDialog;
  TUserDialog = object(THotKeySeqDialog)
    CommandsList: PCommandsList;
    InputTitle: PInputLine;
    ContentsList: PEventsList;
    constructor Init(const AHeader, ATitle: String; AHotKey: Word;
      ASource: PEventCollection);
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PMacrosDialog = ^TMacrosDialog;
  TMacrosDialog = object(TDialog)
    MacrosList: PMacrosList;
    EventsList: PEventsList;
    LocalButton: PButton;
    constructor Init(const FName: String);
    procedure HandleEvent(var Event: TEvent); virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure GetMacro(var AMacro: PMacro);
  end;

function GetCommandName(Command: Word): String;
procedure UserMacros(P: PString);

implementation

uses Dos, Menus, Memory, App, MsgBox, StdDlg, KeyName, CNMacros,
  EditMsg, EditFile, HistList, History, CNInputs, CRC32, DirPrim,
  TPString, Consts, Commands, Defaults;

const
  UntitledStr: String[8] = 'Untitled';

function GetCommandName(Command: Word): String;
begin
  case Command of
    cmQuit: GetCommandName := 'Exit';
    cmMenu: GetCommandName := 'Menu';
    cmClose: GetCommandName := 'Close';
    cmZoom: GetCommandName := 'Zoom';
    cmResize: GetCommandName := 'Resize';
    cmNext: GetCommandName := 'Next';
    cmPrev: GetCommandName := 'Previous';
    cmHelp: GetCommandName := 'Help';
    cmOk: GetCommandName := 'OK';
    cmCancel: GetCommandName := 'Cancel';
    cmYes: GetCommandName := 'Yes';
    cmNo: GetCommandName := 'No';
    cmCut: GetCommandName := 'Cut';
    cmCopy: GetCommandName := 'Copy';
    cmPaste: GetCommandName := 'Paste';
    cmClear: GetCommandName := 'Clear';
    cmCopyToMT:
      if MultitaskerDetected then GetCommandName := 'Copy to WinClip'
      else GetCommandName := 'Copy to AddClip';
    cmPasteFromMT:
      if MultitaskerDetected then GetCommandName := 'Paste from Win'
      else GetCommandName := 'Paste from Add';
    cmTile: GetCommandName := 'Tile';
    cmCascade: GetCommandName := 'Cascade';
    cmToggleEGALines: GetCommandName := 'EGA/VGA lines';
    cmShowClipboard: GetCommandName := 'Show Clipboard';
    cmCompile: GetCommandName := 'Compile';
    cmRun: GetCommandName := 'Run';
    cmProgramReset: GetCommandName := 'Program reset';
    cmGoToCursor: GetCommandName := 'Go to cursor';
    cmHideBlock: GetCommandName := 'Hide block';
    cmDisplayBlock: GetCommandName := 'Display block';
    cmSaveBlock: GetCommandName := 'Save block';
    cmRestoreBlock: GetCommandName := 'Restore block';
    cmSaveCursor: GetCommandName := 'Save cursor';
    cmRestoreCursor: GetCommandName := 'Restore cursor';
    cmTraceInto: GetCommandName := 'Trace into';
    cmStepOver: GetCommandName := 'Step over';
    cmAnimateTracing: GetCommandName := 'Animate tracing';
    cmAnimateStepping: GetCommandName := 'Animate stepping';
    cmClearBreakpoints: GetCommandName := 'Clear breakpnts';
    cmToggleBreakpoint: GetCommandName := 'Toggle breakpnt';
    cmRegExpDlg: GetCommandName := 'Regexp debugger';
    cmSave: GetCommandName := 'Save';
    cmSaveAs: GetCommandName := 'Save as';
    cmSaveAll: GetCommandName := 'Save all';
    cmPrint: GetCommandName := 'Print';
    cmUndo: GetCommandName := 'Undo';
    cmRedo: GetCommandName := 'Redo';
    cmSaveClipData: GetCommandName := 'Save Clipboard';
    cmToggleMarkMode: GetCommandName := 'Mark columns';
    cmToggleExplode: GetCommandName := 'Window settings';
    cmFind: GetCommandName := 'Find';
    cmReplace: GetCommandName := 'Replace';
    cmFindAll: GetCommandName := 'Find all';
    cmShowAllFound: GetCommandName := 'Show all found';
    cmSearchAgain: GetCommandName := 'Search again';
    cmIncSearch: GetCommandName := 'Incremntl search';
    cmGoToLine: GetCommandName := 'Go to line';
    cmMultiSearch: GetCommandName := 'Multiple search';
    cmUpdateASCII: GetCommandName := 'Reload as ASCII';
    cmUpdateHex: GetCommandName := 'Reload as Hex';
    cmPause: GetCommandName := 'Pause';
    cmContents: GetCommandName := 'Help contents';
    cmTopicSearch: GetCommandName := 'Topic search';
    cmPreviousTopic: GetCommandName := 'Previous topic';
    cmAbout: GetCommandName := 'About';
    cmSystemInfo: GetCommandName := 'System info';
    cmRefreshDisplay: GetCommandName := 'Refresh display';
    cmClearDesktop: GetCommandName := 'Clear desktop';
    cmClearHistory: GetCommandName := 'Clear history';
    cmMap: GetCommandName := 'Memory map';
    cmCode: GetCommandName := 'Code';
    cmDump: GetCommandName := 'Dump';
    cmEnvDlg: GetCommandName := 'Environment';
    cmAlarm: GetCommandName := 'Alarm clock';
    cmASCIITable: GetCommandName := 'ASCII table';
    cmCalculator: GetCommandName := 'Calculator';
    cmCalendar: GetCommandName := 'Calendar';
    cmSpooler: GetCommandName := 'Spooler';
    cmDialer: GetCommandName := 'Dialer';
    cmCDPlayer: GetCommandName := 'CD Player';
    cmOpenASCII: GetCommandName := 'Open';
    cmNewASCII: GetCommandName := 'New';
    cmOpenHex: GetCommandName := 'Open Hex';
    cmNewHex: GetCommandName := 'New Hex';
    cmChangeDirectory: GetCommandName := 'Change dir';
    cmDOSShell: GetCommandName := 'DOS shell';
    cmOpenCPUWindow: GetCommandName := 'Open CPU window';
    cmModify: GetCommandName := 'Modify';
    cmMessage: GetCommandName := 'Message';
    cmTerminal: GetCommandName := 'Terminal';
    cmBack: GetCommandName := 'Back';
    cmUserScreen: GetCommandName := 'User screen';
    cmOutput: GetCommandName := 'Output';
    cmClearOutput: GetCommandName := 'Clear output';
    cmWatch: GetCommandName := 'Watch';
    cmAddWatch: GetCommandName := 'Add watch';
    cmEditWatch: GetCommandName := 'Edit watch';
    cmDeleteWatch: GetCommandName := 'Delete watch';
    cmClearWatches: GetCommandName := 'Clear watches';
    cmList: GetCommandName := 'List';
    cmMode: GetCommandName := 'Communication';
    cmKeyboard: GetCommandName := 'Keyboard';
    cmMouse: GetCommandName := 'Mouse';
    cmCursor: GetCommandName := 'Cursor';
    cmColors: GetCommandName := 'Colors';
    cmCountry: GetCommandName := 'Country';
    cmEditOptions: GetCommandName := 'Editor options';
    cmFMOptions: GetCommandName := 'FManager options';
    cmUserOptions: GetCommandName := 'User programs';
    cmLogFile: GetCommandName := 'Log file';
    cmOverlay: GetCommandName := 'Overlay';
    cmPrinterSetup: GetCommandName := 'Printer setup';
    cmCDOptions: GetCommandName := 'Player options';
    cmSetup: GetCommandName := 'Setup';
    cmConfirmations: GetCommandName := 'Confirmations';
    cmSaveOptions: GetCommandName := 'Save options';
    cmRetrieveOptions: GetCommandName := 'Retrieve options';
    cmMacro: GetCommandName := 'Execute macro';
    cmRecordMacro: GetCommandName := 'Record macro';
    cmStopRecording: GetCommandName := 'Stop recording';
    cmUserMacros: GetCommandName := 'Macro list';
    cmExecute: GetCommandName := 'Execute program';
    cmUserPrograms: GetCommandName := 'Program list';
    cmLoadIcon: GetCommandName := 'Load icon';
    cmPhoneBook: GetCommandName := 'Phone book';
    cmDecoders: GetCommandName := 'Decoders';
    cmFileManager: GetCommandName := 'File Manager';
    cmAltHelpName: GetCommandName := 'Help file';
    cmPopUp: GetCommandName := 'Pop-up';
    else GetCommandName := '';
  end;
end;

function TCommandCollection.Compare(Key1, Key2: Pointer): Integer;
begin
  if GetCommandName(Word(Key1)) < GetCommandName(Word(Key2)) then
    Compare := -1
  else if GetCommandName(Word(Key1)) > GetCommandName(Word(Key2)) then
    Compare := 1
  else Compare := 0;
end;

procedure TCommandCollection.FreeItem(Item: Pointer);
begin
end;

constructor TMacro.Init;
begin
  TObject.Init;
  Events := New(PEventCollection, Init(8, 8));
end;

constructor TMacro.Load(var S: TStream);
begin
  TObject.Init;
  Title := S.ReadStr;
  S.Read(HotKey, SizeOf(Word));
  if HotKey = hkSeq then
  begin
    S.Read(HotKeyCount, SizeOf(Word));
    GetMem(HotKeySequence, HotKeyCount * SizeOf(Word));
    S.Read(HotKeySequence^, HotKeyCount * SizeOf(Word));
    S.Read(HotKeyOpt, SizeOf(Word));
    S.Read(HotKeyReserved, SizeOf(Pointer));
  end;
  Events := PEventCollection(S.Get);
end;

destructor TMacro.Done;
begin
  if HotKey = hkSeq then
    FreeMem(HotKeySequence, HotKeyCount * SizeOf(Word));
  DisposeStr(Title);
  if Events <> nil then Dispose(Events, Done);
  TObject.Done;
end;

procedure TMacro.Store(var S: TStream);
begin
  S.WriteStr(Title);
  S.Write(HotKey, SizeOf(Word));
  if HotKey = hkSeq then
  begin
    S.Write(HotKeyCount, SizeOf(Word));
    S.Write(HotKeySequence^, HotKeyCount * SizeOf(Word));
    S.Write(HotKeyOpt, SizeOf(Word));
    S.Write(HotKeyReserved, SizeOf(Pointer));
  end;
  S.Put(Events);
end;

procedure TMacro.GetData(var ATitle: String; var AHotKey: Word);
begin
  if Title = nil then ATitle := ''
  else ATitle := Title^;
  AHotKey := HotKey;
end;

procedure TMacro.SetData(const ATitle: String; AHotKey: Word);
begin
  DisposeStr(Title);
  Title := NewStr(ATitle);
  HotKey := AHotKey;
end;

constructor TMacrosList.Init(var Bounds: TRect; FName: String;
  AScrollBar: PScrollBar);
begin
  TListBox.Init(Bounds, 1, AScrollBar);
  FileName := NewStr(FName);
  FillList(FName);
end;

destructor TMacrosList.Done;
begin
  LastMacroIndex := Focused;
  LastMacroNameCRC := GetStringCRC32UC(FileName^);
  if List <> nil then Dispose(List, Done);
  DisposeStr(FileName);
  TListBox.Done;
end;

procedure TMacrosList.FocusItem(Item: Integer);
var
  M: PMacro;
  S: String[79];
begin
  TListBox.FocusItem(Item);
  if LockFocus then Exit;
  M := List^.At(Focused);
  Message(Owner, evBroadcast, cmNewItem, M);
  if SequenceText <> nil then with SequenceText^ do
  begin
    if (M = nil) or (M^.HotKey <> hkSeq) then S := ''
    else S := 'Sequence:' + GetSequenceStr(M^.HotKeySequence,
      M^.HotKeyCount - 1, Size.X - 9, False);
    DisposeStr(Text);
    Text := NewStr(S);
    DrawView;
  end;
end;

procedure GetTitleStr(P: Pointer; var S: String; ForList: Boolean);
const
  TitleWidth = 28;
var
  HKS: String;
begin
  FillChar(S, SizeOf(String), 0);
  if P = nil then Exit;
  if PMacro(P)^.Title <> nil then S := PMacro(P)^.Title^;
  if S = '' then S := UntitledStr;
  if not ForList then Exit;
  S[0] := Char(TitleWidth);
  HKS := ' ' + GetKeyName(PMacro(P)^.HotKey);
  Move(HKS[1], S[Byte(S[0]) - Byte(HKS[0])], Byte(HKS[0]));
end;

function TMacrosList.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: Pointer;
  S: String;
begin
  P := List^.At(Item);
  if P = nil then GetText := ''
  else
  begin
    GetTitleStr(P, S, True);
    GetText := S;
  end;
end;

procedure TMacrosList.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  if (Focused <> Range - 1) and CommandEnabled(cmRunItem) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmRunItem;
    Event.What := evNothing;
  end else Event.What := evNothing;
  TListBox.HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    case Event.KeyCode of
      kbCtrlUp: if not MoveListItem(@Self, List, True) then Exit;
      kbCtrlDn: if not MoveListItem(@Self, List, False) then Exit;
      else Exit;
    end;
    SaveList(FileName^, False);
    Event.What := evNothing;
  end;
end;

procedure TMacrosList.FillList(const FName: String);
var
  L: PCollection;
begin
  ReadMacros(FName, L);
  L^.Insert(nil);
  NewList(L);
  UpdateCommands;
end;

procedure TMacrosList.SaveList(const FName: String; ANew: Boolean);
var
  Append: Boolean;
  C: Word;
  I: Integer;
  L: Longint;
  P: PMacro;
  S: TDosStream;
  A: String[7];
  F: File;
begin
  Append := False;
  if ANew then
  begin
    if ThisFileExists(FName) then
    begin
      C := AppendMessageBox(FName);
      if C = cmYes then Append := True
      else if C = cmCancel then Exit;
    end;
    if Append then A := 'Append' else A := 'Creat';
  end
  else A := 'Updat';
  LogEvent := lcDiskWrite;
  DrawStatusLine(A + 'ing macro list file ' +
    TrimmedName(FName, 42) + '.');
  if List^.Count = 1 then
  begin
    if not Append then
    begin
      Assign(F, FName);
      Reset(F);
      if IOResult = 0 then
      begin
        Close(F);
        Erase(F);
      end;
    end;
    Exit;
  end;
  if Append then C := stOpenWrite else C := stCreate;
  S.Init(FName, C);
  if Append then
  begin
    L := S.GetSize;
    if L > 1 then Dec(L, 2);
    S.Seek(L);
  end;
  I := 0;
  while (I < List^.Count) and (S.Status = stOk) do
  begin
    P := List^.At(I);
    S.Put(P);
    Inc(I);
  end;
  S.Done;
  UpdateFiles(FName);
  Message(Desktop, evBroadcast, cmUserMacros, @FName);
end;

procedure SetButtonTitle(B: PButton);
var
  S: String[8];
begin
  if B <> nil then with B^ do
  begin
    if (Title <> nil) and (Title^[2] = 'L') then
      S := 'G~l~obal'
    else S := '~L~ocal';
    DisposeStr(Title);
    Title := NewStr(S);
    DrawView;
  end;
end;

procedure TMacrosList.FileOperation(ACommand: Word);
var
  C: Word;
  S: FNameStr;
begin
  Select;
  C := ACommand;
  if C = cmFileInit then
    if PMacrosDialog(Owner)^.LocalButton^.Title^[2] = 'L' then
      SetMacroLocalName(S)
    else SetMacroFileName(nil, S)
  else
  begin
    S := '';
    C := Application^.ExecuteDialog(New(PFileDialog, Init(
      '*.MAC', 'Load/store macro list', '~N~ame',
      fdLoadButton + fdStoreButton + fdHelpButton,
      MacroNameHistoryID)), @S, False);
  end;
  if (C = cmFileOpen) or (C = cmFileInit) then
  begin
    Dispose(List, Done);
    List := nil;
    FillList(S);
  end
  else if C = cmFileReplace then SaveList(S, True)
  else Exit;
  DisposeStr(FileName);
  FileName := NewStr(S);
  PWindow(Owner)^.Frame^.DrawView;
  if C = cmFileInit then
    SetButtonTitle(PMacrosDialog(Owner)^.LocalButton);
end;

procedure TMacrosList.ModifyMacro;
var
  D: PUserDialog;
  M: PMacro;
  E: PEvent;
  I: Integer;
  C: Word;
  S: String;
begin
  M := List^.At(Focused);
  if M = nil then
  begin
    NewMacro;
    Exit;
  end;
  D := New(PUserDialog, Init('Modify macro',
    M^.Title^, M^.HotKey, M^.Events));
  if Application^.ValidView(D) <> nil then
  begin
    if M^.HotKey = hkSeq then
    begin
      D^.HotKeyCount := M^.HotKeyCount;
      Move(M^.HotKeySequence^, D^.HotKeySequence,
        M^.HotKeyCount * SizeOf(Word));
      D^.HotKeyOpt := M^.HotKeyOpt;
    end;
    C := Desktop^.ExecView(D);
    if C <> cmCancel then with List^ do
    begin
      if D^.InputTitle^.Data^ = '' then S := UntitledStr
      else S := D^.InputTitle^.Data^;
      M := New(PMacro, Init);
      if M <> nil then
      begin
        M^.SetData(S, D^.KeyView^.Key);
        if D^.ContentsList^.Range > 1 then
        for I := 0 to D^.ContentsList^.Range - 2 do
        begin
          E := MemAlloc(SizeOf(TEvent));
          if E <> nil then
          begin
            E^ := PEvent(D^.ContentsList^.EventCollection^.At(I))^;
            M^.Events^.Insert(E);
          end;
        end;
        if D^.HotKeyCount <> 0 then
        begin
          M^.HotKey := hkSeq;
          M^.HotKeyCount := D^.HotKeyCount;
          GetMem(M^.HotKeySequence, M^.HotKeyCount * SizeOf(Word));
          Move(D^.HotKeySequence, M^.HotKeySequence^,
            M^.HotKeyCount * SizeOf(Word));
          M^.HotKeyOpt := D^.HotKeyOpt;
        end;
        AtFree(Focused);
        AtInsert(Focused, M);
        SaveList(FileName^, False);
        FocusItem(Focused);
        DrawView;
        if M^.HotKey <> 0 then CheckDuplicates(
          M^.HotKey, M^.HotKeySequence, M^.HotKeyCount);
      end;
    end;
    Dispose(D, Done);
  end;
  Select;
end;

procedure TMacrosList.NewMacro;
var
  D: PUserDialog;
  M: PMacro;
  E: PEvent;
  I: Integer;
  C: Word;
  S: String;
begin
  D := New(PUserDialog, Init('New macro', '', 0, nil));
  if Application^.ValidView(D) <> nil then
  begin
    C := Desktop^.ExecView(D);
    if C <> cmCancel then with List^ do
    begin
      if D^.InputTitle^.Data^ = '' then S := UntitledStr
      else S := D^.InputTitle^.Data^;
      M := New(PMacro, Init);
      if M <> nil then
      begin
        M^.SetData(S, D^.KeyView^.Key);
        if D^.ContentsList^.Range > 1 then
        for I := 0 to D^.ContentsList^.Range - 2 do
        begin
          E := MemAlloc(SizeOf(TEvent));
          if E <> nil then
          begin
            E^ := PEvent(D^.ContentsList^.EventCollection^.At(I))^;
            M^.Events^.Insert(E);
          end;
        end;
        if D^.HotKeyCount <> 0 then
        begin
          M^.HotKey := hkSeq;
          M^.HotKeyCount := D^.HotKeyCount;
          GetMem(M^.HotKeySequence, M^.HotKeyCount * SizeOf(Word));
          Move(D^.HotKeySequence, M^.HotKeySequence^,
            M^.HotKeyCount * SizeOf(Word));
          M^.HotKeyOpt := D^.HotKeyOpt;
        end;
        AtInsert(Focused, M);
        SetRange(List^.Count);
        SaveList(FileName^, False);
        UpdateCommands;
        FocusItem(Focused);
        DrawView;
        if M^.HotKey <> 0 then CheckDuplicates(
          M^.HotKey, M^.HotKeySequence, M^.HotKeyCount);
      end;
    end;
    Dispose(D, Done);
  end;
  Select;
end;

procedure TMacrosList.DeleteMacro;
begin
  with List^ do
    if (Focused < Count - 1) and (DeleteItemMsgBox = cmOk) then
  begin
    AtFree(Focused);
    SetRange(Count);
    SaveList(FileName^, False);
    UpdateCommands;
    FocusItem(Focused);
    DrawView;
  end;
  Select;
end;

procedure TMacrosList.NewItemPos;
var
  SaveFocused, LastFocused: Integer;
  SaveCtx: Word;
  P: Pointer;
  Event: TEvent;
begin
  with List^ do
  begin
    if Focused >= Count - 1 then Exit;
    P := At(Focused);
    SaveFocused := Focused;
    SaveCtx := Owner^.HelpCtx;
    Owner^.HelpCtx := hcNewItemPos;
    repeat
      LockFocus := True;
      GetEvent(Event);
      HandleEvent(Event);
      LockFocus := False;
      LastFocused := IndexOf(P);
      if (Focused < Count - 1) and
         (LastFocused <> -1) and (LastFocused <> Focused) then
      begin
        AtDelete(LastFocused);
        AtInsert(Focused, P);
        FocusItem(Focused);
        DrawView;
      end;
      if ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) or
         ((Event.What = evCommand) and (Event.Command = cmOk)) then
      begin
        SaveList(FileName^, False);
        Break;
      end
      else if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
      begin
        AtDelete(LastFocused);
        AtInsert(SaveFocused, P);
        FocusItem(SaveFocused);
        DrawView;
        Break;
      end;
    until False;
    Owner^.HelpCtx := SaveCtx;
  end;
  Select;
end;

procedure TMacrosList.CheckDuplicates(AKey: Word;
  ASequence: PHotKeySequence; ACount: Word);
var
  P: PMacro;
  I: Integer;
  C: String[31];
  S: String;
begin
  for I := 0 to List^.Count - 1 do
    if I <> Focused then
    begin
      P := List^.At(I);
      if (P <> nil) and
        ((P^.HotKey <> hkSeq) and SameKey(AKey, P^.HotKey)) or
        ((P^.HotKey = hkSeq) and (AKey = hkSeq) and
         (ACount = P^.HotKeyCount) and
          SameSequence(ASequence^, P^.HotKeySequence^, ACount)) then
      begin
        if AKey = hkSeq then C := 'sequence' +
          GetSequenceStr(ASequence, ACount - 1, 14, False)
        else C := GetKeyName(AKey);
        GetTitleStr(P, S, False);
        DupHotKeyMsgBox(C, S);
      end;
  end;
end;

procedure TMacrosList.UpdateCommands;
begin
  EnableCommands(NewCommands);
  if List^.Count > 1 then
    EnableCommands(ModifyCommands + DeleteCommands + RunItemCommands +
      ShowCommands + NewItemPosCommands)
  else DisableCommands(ModifyCommands + DeleteCommands + RunItemCommands +
    ShowCommands + NewItemPosCommands);
end;

constructor TEventsList.Init(var Bounds: TRect; ANumCols: Word;
  AScrollBar: PScrollBar; ASource: PEventCollection);
begin
  TListBox.Init(Bounds, ANumCols, AScrollBar);
  EventCollection := New(PEventCollection, Init(16, 16));
  FillList(ASource);
  NewList(EventCollection);
end;

destructor TEventsList.Done;
begin
  if EventCollection <> nil then Dispose(EventCollection, Done);
  TListBox.Done;
end;

function TEventsList.GetText(Item: Integer; MaxLen: Integer): String;
const
  PauseStr = 'Pause %d ms';
var
  E: PEvent;
  S, C: String;
begin
  E := PEvent(List^.At(Item));
  if E = nil then GetText := ''
  else
  begin
    if (E^.What = evCommand) and (E^.Command = cmPause) then
    begin
      if E^.InfoWord = 0 then S := 'Wait for Alt+F8'
      else FormatStr(S, PauseStr, E^.InfoPtr);
    end
    else
    begin
      if E^.What = evCommand then
        S := GetCommandName(E^.Command)
      else if E^.CharCode = #255 then S := '#255'
      else S := GetKeyName(E^.KeyCode);
      if E^.InfoWord > 0 then
      begin
        PadSt(S, Size.X - 2);
        Str(E^.InfoWord + 1, C);
        C := ' ' + C;
        Move(C[1], S[Length(S) - Length(C) + 1], Length(C));
      end;
    end;
    GetText := S;
  end;
end;

procedure TEventsList.FillList(Source: PEventCollection);
var
  E: PEvent;

procedure MoveEvent(Event: PEvent); far;
begin
  E := MemAlloc(SizeOf(TEvent));
  if E <> nil then
  begin
    E^ := Event^;
    EventCollection^.Insert(E);
  end;
end;

begin
  if Source <> nil then Source^.ForEach(@MoveEvent);
  EventCollection^.Insert(nil);
end;

constructor TCommandsList.Init(var Bounds: TRect; ANumCols: Word;
  AScrollBar: PScrollBar);
begin
  TListBox.Init(Bounds, ANumCols, AScrollBar);
  CommandCollection := New(PCommandCollection, Init(128, 8));
  FillList;
  NewList(CommandCollection);
end;

destructor TCommandsList.Done;
begin
  if CommandCollection <> nil then Dispose(CommandCollection, Done);
  TListBox.Done;
end;

function TCommandsList.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: Pointer;
begin
  P := CommandCollection^.At(Item);
  if P = nil then GetText := ''
  else GetText := GetCommandName(Word(P));
end;

procedure TCommandsList.HandleEvent(var Event: TEvent);
var
  I: Integer;
  B: Boolean;
  S: String;
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode in [#13, #32])) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmCommand;
    Event.What := evNothing;
  end
  else TListBox.HandleEvent(Event);
  if (Event.What = evKeyDown) and (Event.CharCode <> #0) then
  begin
    B := False;
    I := 0;
    while (I < CommandCollection^.Count) and not B do
    begin
      S := GetText(I, 1);
      B := Upcase(Event.CharCode) = Upcase(S[1]);
      Inc(I);
    end;
    if B then
    begin
      FocusItem(I - 1);
      Event.What := evNothing;
    end;
  end;
end;

procedure TCommandsList.FillList;
var
  SubMenu: PMenu;
  BigItem, Item: PMenuItem;
  I: Integer;
begin
  with MenuBar^.Menu^ do
  begin
    BigItem := Items;
    while BigItem <> nil do
    begin
      SubMenu := BigItem^.SubMenu;
      Item := SubMenu^.Items;
      while Item <> nil do
      begin
        if Item^.Name <> nil then
          CommandCollection^.Insert(Pointer(Item^.Command));
        Item := Item^.Next;
      end;
      BigItem := BigItem^.Next;
    end;
  end;
  for I := cmOk to cmNo do CommandCollection^.Insert(Pointer(I));
  I := cmMenu;
  CommandCollection^.Insert(Pointer(I));
  I := cmPause;
  CommandCollection^.Insert(Pointer(I));
  I := cmPopUp;
  CommandCollection^.Insert(Pointer(I));
  I := cmSaveBlock;
  CommandCollection^.Insert(Pointer(I));
  I := cmRestoreBlock;
  CommandCollection^.Insert(Pointer(I));
  I := cmSaveCursor;
  CommandCollection^.Insert(Pointer(I));
  I := cmRestoreCursor;
  CommandCollection^.Insert(Pointer(I));
  I := cmHideBlock;
  CommandCollection^.Insert(Pointer(I));
  I := cmDisplayBlock;
  CommandCollection^.Insert(Pointer(I));
end;

function MacroInputBox(ATitle: String; ALabel: String; var S: String): Word;
var
  D: PDialog;
  Control: PInputLine;
  R: TRect;
  C: Word;
  Data: String[255];
begin
  R.Assign(0, 0, 60, 7);
  R.Move((Application^.Size.X - R.B.X) div 2,
    (Application^.Size.Y - R.B.Y) div 2);
  D := New(PDialog, Init(R, ATitle));
  with D^ do
  begin
    HelpCtx := hcMacroInputBox;
    R.Assign(4 + CStrLen(ALabel), 2, Size.X - 6, 3);
    Control := New(PInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, MacroInputBoxHistoryId);
    R.Assign(2, 2, 4 + CStrLen(ALabel), 3);
    Insert(New(PLabel, Init(R, ALabel, Control)));

    R.Assign(16, Size.Y - 3, 26, Size.Y - 1);
    StandardOkButton(R, D);
    Inc(R.A.X, 29); Inc(R.B.X, 29);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;

  Data := S;
  C := Application^.ExecuteDialog(D, @Data, False);
  if C <> cmCancel then S := Data;
  MacroInputBox := C;
end;

function GetPause(var Value: Word): Boolean;
const
  W: Word = 0;
var
  D: PDialog;
  R: TRect;
  Control: PInputLine;
  Data: String[5];
  L: Longint;
  Code: Integer;
begin
  GetPause := False;
  R.Assign(0, 0, 23, 7);
  R.Move((Desktop^.Size.X - R.B.X) div 2, (Desktop^.Size.Y - R.B.Y) div 2);
  D := New(PDialog, Init(R, 'Pause'));
  with D^ do
  begin
    HelpCtx := hcValueDialog;
    R.Assign(13, 2, Size.X - 3, 3);
    Control := New(PCInputLine, Init(R, 5, 0, 65535));
    Insert(Control);
    R.Assign(2, 2, 13, 3);
    Insert(New(PLabel, Init(R, '~P~ause, ms', Control)));
    R.Assign(3, Size.Y - 3, 9, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  if Value <> 0 then Str(Value, Data)
  else Str(W, Data);
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    Val(Data, L, Code);
    W := Word(L);
    Value := W;
    GetPause := True;
  end;
end;

function GetCount(var Value: Word): Boolean;
const
  W: Word = 2;
var
  D: PDialog;
  R: TRect;
  Control: PInputLine;
  Data: String[5];
  C: Word;
  Code: Integer;
begin
  GetCount := False;
  R.Assign(0, 0, 23, 7);
  R.Move((Desktop^.Size.X - R.B.X) div 2, (Desktop^.Size.Y - R.B.Y) div 2);
  D := New(PDialog, Init(R, 'Repeat'));
  with D^ do
  begin
    HelpCtx := hcValueDialog;
    R.Assign(9, 2, Size.X - 3, 3);
    Control := New(PCInputLine, Init(R, 5, 1, 65535));
    Insert(Control);
    R.Assign(2, 2, 9, 3);
    Insert(New(PLabel, Init(R, '~C~ount', Control)));
    R.Assign(3, Size.Y - 3, 9, Size.Y - 1);
    StandardOkButton(R, D);
    R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  if Value <> 0 then Str(Value + 1, Data)
  else Str(W, Data);
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    Val(Data, C, Code);
    W := C;
    Value := W - 1;
    GetCount := True;
  end;
end;

constructor TUserDialog.Init(const AHeader, ATitle: String; AHotKey: Word;
  ASource: PEventCollection);
var
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 80, 21);
  THotKeySeqDialog.Init(R, AHeader);
  Options := Options or ofCentered;
  HelpCtx := hcUserDialog;
  SeqTitle := 'Macro';

  R.Assign(41, 3, 52, 4);
  InputTitle := New(PInputLine, Init(R, 16));
  if Length(ATitle) > 16 then InputTitle^.Data^ := ''
    else InputTitle^.Data^ := ATitle;
  Insert(InputTitle);
  StandardHistory(InputTitle, MacroTitleHistoryId);
  R.Assign(40, 2, 55, 3);
  Insert(New(PLabel, Init(R, '~T~itle', InputTitle)));

  R.Assign(43, 6, 53, 7);
  KeyView := New(PKeyView, Init(R));
  KeyView^.Key := AHotKey;
  Insert(KeyView);
  R.Assign(42, 5, 53, 6);
  Insert(New(PLabel, Init(R, 'Hot ke~y~', KeyView)));

  R.Assign(3, Size.Y - 5, 40, Size.Y - 4);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3, 3, 40, Size.Y - 5);
  CommandsList := New(PCommandsList, Init(R, 2, PScrollBar(Control)));
  Insert(CommandsList);
  R.Assign(2, 2, 40, 3);
  Insert(New(PLabel, Init(R, 'C~o~mmands', CommandsList)));

  R.Assign(76, 3, 77, Size.Y - 2);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(55, 3, 76, Size.Y - 2);
  ContentsList := New(
    PEventsList, Init(R, 1, PScrollBar(Control), ASource));
  Insert(ContentsList);
  R.Assign(54, 2, 77, 3);
  Insert(New(PLabel, Init(R, '~C~ontents', ContentsList)));

  R.Assign(41, 8, 53, 10);
  Insert(New(PButton, Init(R, '~H~ot keys', cmKeySequence, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'Comma~n~d', cmCommand, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'K~e~y', cmKey, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~S~tring', cmString, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~R~epeat', cmModifyItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));

  R.Assign(2, Size.Y - 3, 12, Size.Y - 1);
  StandardOkButton(R, @Self);
  R.Assign(16, Size.Y - 3, 26, Size.Y - 1);
  StandardCancelButton(R, @Self);
  R.Assign(30, Size.Y - 3, 40, Size.Y - 1);
  StandardHelpButton(R, @Self);
  InputTitle^.Select;
end;

procedure TUserDialog.HandleEvent(var Event: TEvent);
const
  W: Word = 0;
var
  R: TRect;
  D: PHotKeyDialog;
  E: PEvent;
  C, Cmd: Word;
  I: Integer;
  P: Pointer;
  S: String;
begin
  if (Event.What = evKeyDown) and (Event.KeyCode = kbDel) and
     (ContentsList^.State and sfSelected <> 0) then
  begin
    Event.What := evCommand;
    Event.Command := cmDeleteItem;
  end;
  if Event.What = evCommand then
  case Event.Command of
    cmCommand:
      begin
        P := nil;
        Cmd := Word(CommandsList^.CommandCollection^.At(
          CommandsList^.Focused));
        if Cmd = cmPause then
        begin
          C := 0;
          if not GetPause(C) then Exit;
          P := Pointer(C);
        end;
        E := MemAlloc(SizeOf(TEvent));
        if E <> nil then
        begin
          E^.What := evCommand;
          E^.Command := Cmd;
          E^.InfoPtr := P;
          with ContentsList^ do
          begin
            EventCollection^.AtInsert(Focused, E);
            SetRange(EventCollection^.Count);;
            CommandsList^.Select;
            FocusItem(Succ(Focused));
          end;
        end;
        Event.What := evNothing;
      end;
    cmKey:
      begin
        R.Assign(0, 0, 26, 7);
        D := New(PHotKeyDialog, Init(R, 'Macro key'));
        with D^ do
        begin
          HelpCtx := hcKeyView;
          Options := Options or ofCentered;
          R.Assign(1, 2, Size.X - 1, 3);
          KeyView := New(PKeyView, Init(R));
          Insert(KeyView);
          KeyView^.Options := KeyView^.Options or ofCentered;
          R.Assign(2, 4, 12, 6);
          StandardOkButton(R, D);
          R.Assign(13, 4, 23, 6);
          StandardCancelButton(R, D);
          SelectNext(False);
        end;
        if (Application^.ExecuteDialog(D, @W, False) <> cmCancel) and
           (W <> 0) then
        begin
          E := MemAlloc(SizeOf(TEvent));
          if E <> nil then
          begin
            E^.What := evKeyDown;
            E^.KeyCode := W;
            E^.InfoPtr := nil;
            with ContentsList^ do
            begin
              EventCollection^.AtInsert(Focused, E);
              SetRange(EventCollection^.Count);
              FocusItem(Succ(Focused));
            end;
          end;
        end;
        Event.What := evNothing;
      end;
    cmString:
      begin
        S := HistoryStr(MacroInputBoxHistoryID, 0);
        if (MacroInputBox(
           'Macro string', '~T~ype a string', S) <> cmCancel) and
           (S <> '') then with ContentsList^ do
        begin
          for I := 1 to Length(S) do
          begin
            E := MemAlloc(SizeOf(TEvent));
            if E <> nil then
            begin
              E^.What := evKeyDown;
              E^.KeyCode := 0;
              E^.CharCode := S[I];
              E^.InfoPtr := nil;
              EventCollection^.AtInsert(Focused + Pred(I), E);
            end
            else I := Length(S);
          end;
          SetRange(EventCollection^.Count);
          FocusItem(Focused + I);
        end;
        Event.What := evNothing;
      end;
    cmModifyItem:
      begin
        with ContentsList^ do
        begin
          if Focused < Pred(Range) then
          begin
            E := EventCollection^.At(Focused);
            C := E^.InfoWord;
            if (E^.What = evCommand) and (E^.Command = cmPause) then
              if not GetPause(C) then Exit else
            else if not GetCount(C) then Exit;
            E^.InfoPtr := Pointer(C);
            DrawView;
          end;
          Select;
          Event.What := evNothing;
        end;
      end;
    cmDeleteItem:
      with ContentsList^ do
      begin
        if Focused < Pred(Range) then
        begin
          EventCollection^.AtFree(Focused);
          SetRange(EventCollection^.Count);
          DrawView;
        end;
        Select;
        Event.What := evNothing;
      end;
  end;
  THotKeySeqDialog.HandleEvent(Event);
end;

constructor TMacrosDialog.Init(const FName: String);
var
  Local: Boolean;
  Control: PView;
  R: TRect;
begin
  Local := Message(Application, evBroadcast, cmGetMacroName, nil) <> nil;
  R.Assign(0, 0, 70, ScreenHeight - 2);
  TDialog.Init(R, '');
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcMacrosDialog;

  R.Assign(32, 3, 33, Size.Y - 2);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(3, 3, 32, Size.Y - 2);
  MacrosList := New(PMacrosList, Init(R, FName, PScrollBar(Control)));
  MacrosList^.GrowMode := gfGrowHiY;
  Insert(MacrosList);
  R.Assign(2, 2, 33, 3);
  Control := New(PLabel, Init(R, ' M~a~cros              Hot key',
    MacrosList));
  Insert(Control);

  R.Assign(3, Size.Y - 2, 56, Size.Y - 1);
  MacrosList^.SequenceText := New(PStaticText, Init(R, ''));
  MacrosList^.SequenceText^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(MacrosList^.SequenceText);

  R.Assign(55, 3, 56, Size.Y - 2);
  Control := New(PScrollBar, Init(R));
  Insert(Control);
  R.Assign(34, 3, 55, Size.Y - 2);
  EventsList := New(PEventsList, Init(R, 1, PScrollBar(Control), nil));
  EventsList^.GrowMode := gfGrowHiY;
  Insert(EventsList);
  R.Assign(33, 2, 56, 3);
  Control := New(PLabel, Init(R, '~C~ontents', EventsList));
  Insert(Control);

  R.Assign(57, 3, 67, 5);
  Insert(New(PButton, Init(R, '~R~un', cmRunItem, bfDefault)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'R~e~peat', cmShow, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'F~i~le', cmFileOpen, bfNormal)));
  if Local then
  begin
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    LocalButton := New(PButton, Init(R, '', cmFileInit, bfNormal));
    Insert(LocalButton);
    SetButtonTitle(LocalButton);
  end;
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~M~odify', cmModifyItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~N~ew', cmNewItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, 'Ad~j~ust', cmNewItemPos, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardCancelButton(R, @Self);
  if not Local then
  begin
    Inc(R.A.Y, 2); Inc(R.B.Y, 2);
    StandardHelpButton(R, @Self);
  end;
  MacrosList^.Select;
  if MacroJustRecorded then LastMacroIndex := MacrosList^.Range - 2
  else if (LastMacroIndex >= MacrosList^.Range) or
    (LastMacroNameCRC <> GetStringCRC32UC(FName)) then
      LastMacroIndex := 0;
  MacrosList^.FocusItem(LastMacroIndex);
  MacroJustRecorded := False;
end;

const
  RepeatCount: Word = 0;

procedure TMacrosDialog.HandleEvent(var Event: TEvent);

function HotKeyFound: Boolean;
var
  I: Integer;
  P: PMacro;
begin
  with MacrosList^ do for I := 0 to List^.Count - 2 do
  begin
    P := List^.At(I);
    if (P <> nil) and (P^.HotKey <> hkSeq) and
      SameKey(Event.KeyCode, P^.HotKey) then
    begin
      if I <> Focused then FocusItem(I);
      Event.What := evNothing;
      HotKeyFound := True;
      Exit;
    end;
  end;
  HotKeyFound := False;
end;

var
  M: PMacro;
  S: String;
begin
  if (Event.What = evKeyDown) and
     (MacrosList^.State and sfSelected <> 0) then
    case Event.KeyCode of
      kbCtrlEnter:
        begin
          Event.What := evCommand;
          Event.Command := cmModifyItem;
        end;
      kbIns:
        begin
          Event.What := evCommand;
          Event.Command := cmNewItem;
        end;
      kbDel:
        begin
          Event.What := evCommand;
          Event.Command := cmDeleteItem;
        end;
      kbUp, kbDown, kbPgUp, kbPgDn, kbCtrlPgUp, kbCtrlPgDn,
      kbCtrlHome, kbCtrlEnd, kbAltRight, kbAltLeft, kbAltUp, kbAltDn,
      kbTab, kbShiftTab, kbCtrlIns, kbEnter, kbSpace: ;
      else if HotKeyFound then EndModal(cmRunItem);
    end;
  TDialog.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmRunItem: EndModal(Event.Command);
      cmShow: if MacroRunning then MessageBox(
        ^C'Cannot repeat macros while current macro is running.',
        nil, mfError + mfOkButton)
        else if GetCount(RepeatCount) then EndModal(Event.Command);
      cmFileOpen, cmFileInit: MacrosList^.FileOperation(Event.Command);
      cmModifyItem: MacrosList^.ModifyMacro;
      cmNewItem: MacrosList^.NewMacro;
      cmDeleteItem: MacrosList^.DeleteMacro;
      cmNewItemPos: MacrosList^.NewItemPos;
      else Exit;
    end;
    Event.What := evNothing;
  end;
  if (Event.What = evBroadcast) and (Event.Command = cmNewItem) then
  begin
    with EventsList^ do
    begin
      if Event.InfoPtr = nil then
      begin
        List := nil;
        SetRange(0);
      end
      else
      begin
        List := PMacro(Event.InfoPtr)^.Events;
        SetRange(List^.Count);
      end;
      FocusItem(0);
      DrawView;
    end;
    Event.What := evNothing;
  end;
end;

function TMacrosDialog.GetTitle(MaxSize: Integer): TTitleStr;
var
  S: TTitleStr;
begin
  S := 'Macro list';
  if (MacrosList <> nil) and (MacrosList^.FileName <> nil) then
    S := S + ': ' + TrimmedName(MacrosList^.FileName^, 48);
  GetTitle := S;
end;

procedure TMacrosDialog.GetMacro(var AMacro: PMacro);
var
  E: PEvent;
  P: PMacro;
  I: Integer;
begin
  AMacro := nil;
  with MacrosList^, MacrosList^.List^ do
  begin
    P := At(Focused);
    if P = nil then Exit;
    AMacro := New(PMacro, Init);
    AMacro^.SetData(P^.Title^, P^.HotKey);
    if P^.Events^.Count > 0 then
    for I := 0 to P^.Events^.Count - 1 do
    begin
      E := MemAlloc(SizeOf(TEvent));
      if E <> nil then
      begin
        E^ := PEvent(P^.Events^.At(I))^;
        AMacro^.Events^.Insert(E);
      end;
    end;
  end;
end;

procedure UserMacros(P: PString);
var
  D: PMacrosDialog;
  M: PMacro;
  C: Word;
  I: Integer;
  Name: FNameStr;
begin
  if MacroJustRecorded then SetMacroLocalName(Name)
  else SetMacroFileName(P, Name);
  D := New(PMacrosDialog, Init(Name));
  if Application^.ValidView(D) <> nil then
  begin
    C := Desktop^.ExecView(D);
    if C <> cmCancel then D^.GetMacro(M);
    Dispose(D, Done);
    if (C <> cmCancel) and (M <> nil) then with M^.Events^ do
    begin
      if C = cmShow then MacroRepeat := RepeatCount;
      if MacroWaiting then MacroEvents^.Index := MacroEvents^.Count
      else MacroEvents^.Index := 0;
      for I := 0 to Count - 1 do
        NewMacroEvent(PEvent(At(I))^, C = cmShow);
      Dispose(M, Done);
      MacroRunning := True;
    end;
  end;
end;

end.