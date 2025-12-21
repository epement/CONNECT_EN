{$I-,X+,O+,F+}
unit CPUWin;

interface

uses Objects, Drivers, Views, Dialogs, CodeWin, DumpWin;

type
  PPattern = ^TPattern;
  TPattern = Array[11..74] of Byte;

  PSourceList = ^TSourceList;
  TSourceList = object(TCodeList)
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    function DisasmBreak(var Address: Pointer): String; virtual;
    procedure InsertBreakPoint(AnAddress: Pointer; AValue: Byte);
    procedure NewCSIP;
    procedure ToggleBreakPoint;
    procedure ClearBreakPoints;
    procedure Run;
    procedure ProgramReset;
    procedure GoToCursor;
    procedure TraceInto;
    procedure StepOver;
    procedure PopUp(AnOrigin: TPoint); virtual;
  end;

  PRegistersList = ^TRegistersList;
  TRegistersList = object(TListViewer)
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar);
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    function FocusedValue: Word;
    procedure Change(Initial: Char);
    procedure Modify(NewValue: Word);
    procedure PopUp(AnOrigin: TPoint); {virtual;}
  end;

  PFlagsList = ^TFlagsList;
  TFlagsList = object(TListViewer)
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar);
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Toggle;
  end;

  PCPUIndicator = ^TCPUIndicator;
  TCPUIndicator = object(TView)
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
  end;

  PMemList = ^TMemList;
  TMemList = object(TDumpList)
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar; AnIndicator: PDumpIndicator);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PStackList = ^TStackList;
  TStackList = object(TListViewer)
    Shift: Longint;
    Address: Byte;
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar);
    constructor Load(var S: TStream);
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure FocusItem(Item: Integer); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure GoToPos(APos: Word);
    procedure GoToAddress;
    procedure GoToOrigin;
    procedure Follow;
    procedure Change(Initial: Char);
    procedure Modify(NewValue: Word);
    procedure PopUp(AnOrigin: TPoint);
  end;

  PCPUWindow = ^TCPUWindow;
  TCPUWindow = object(TWindow)
    SourceList: PSourceList;
    RegistersList: PRegistersList;
    FlagsList: PFlagsList;
    MemList: PMemList;
    StackList: PStackList;
    Indicator: PCPUIndicator;
    NewGrowMode: Byte;
    constructor Init;
    constructor Load(var S: TStream);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    function GetPalette: PPalette; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
    procedure SetNewGrowMode(AMode: Byte);
  end;

procedure RSRCPUWindow(RSR: PResourceFile);
procedure GetTraceVectors;
procedure SetTraceVectors;

const
  CRegistersList = #9#9#10#2#10;
  CFlagsList     = #11#11#12#2#12;
  CStackList     = #14#14#15#2#15;

  CCPUColor      = #$38#$3F#$3A#$13#$13#$30#$4E#$1E#$30#$1E#$30#$1E#$30#$30#$1E;
  CCPUBlackWhite = #$07#$0F#$07#$70#$70#$07#$0F#$70#$07#$70#$07#$70#$07#$07#$70;
  CCPUMonochrome = #$07#$0F#$07#$70#$70#$07#$0F#$70#$07#$70#$07#$70#$07#$07#$70;
  CCPUWindow     = #113#114#115#116#117#118#119#120#121#122#123#124#125#126#127;

  MaxRegisters = 13;
  MaxFlags = 8;

implementation

uses Dos, CNCrt, Memory, Menus, App, MsgBox, StdDlg, HistList, History,
  EditMsg, FindDlg, PopUps, Disasm, Jump, Compiler, DosTools, Keyboard,
  AddrDlg, TPString, Consts, Commands, Defaults;

const
  gmInitial = 0;
  gmSourceRegsFlags = 1;
  gmMemStack = 2;
  gmSourceStack = 3;
  gmMemRegsFlags = 4;

var
  SaveInt1Vect,
  SaveInt3Vect, BreakFlag: Pointer;
  TempBreak: TBreakRec;
  MissBreak, F4Flag : Boolean;

procedure BreakMsgBox;
begin
  MessageBox(^C'Can''t set a breakpoint at that location.',
    nil, mfError + mfOkButton);
end;

constructor TSourceList.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
  Options := Options or ofFramed;
  HScrollBar^.Options := HScrollBar^.Options or ofPostProcess;
  VScrollBar^.Options := VScrollBar^.Options or ofPostProcess;
  Source := Ptr(CPUStatus.cs_, CPUStatus.ip_);
  SourceOrigin := Source;
  SourceCollection := New(PSourceCollection, Init(MaxSource, 1));
  Limit.X := ScreenWidth;
  Limit.Y := MaxSource;
end;

constructor TSourceList.Load(var S: TStream);
begin
  TScroller.Load(S);
  Source := Ptr(CPUStatus.cs_, CPUStatus.ip_);
  SourceOrigin := Source;
  SourceCollection := New(PSourceCollection, Init(MaxSource, 1));
end;

procedure TSourceList.Draw;
var
  C, Y, APos: Byte;
  Ch: Char;
  Index, FoundIndex: Integer;
  P: Pointer;
  B: TDrawBuffer;
  S: String;
begin
  for Y := 0 to Pred(Size.Y) do
  begin
    Index := Delta.Y + Y;
    P := SourceCollection^.At(Index);
    if P = SourceOrigin then Ch := #16 else Ch := #32;
    if Index = Focused then C := GetColor(3)
    else
    if (Byte(P^) = $CC) and
      BreaksCollection^.Search(P, FoundIndex) then C := GetColor(2)
    else C := GetColor(1);
    if Byte(P^) = $CC then S := DisasmBreak(P)
    else S := DisasmCom(P, True);
    MoveChar(B, ' ', C, Size.X);
    APos := Pos(':', S);
    S[APos + 5] := Ch;
    if Size.X < 44 then
    begin
      Delete(S, APos + 6, 15);
      if Size.X < 29 then Delete(S, 1, APos);
    end;
    MoveStr(B[1], System.Copy(S, Succ(Delta.X), Size.X - 2), C);
    WriteLine(0, Y, Size.X, 1, B);
  end;
  PCPUWindow(Owner)^.Indicator^.DrawView;
end;

procedure TSourceList.HandleEvent(var Event: TEvent);
var
  Handled: Boolean;
begin
  if (Event.What = evKeyDown) and (Event.CharCode <> #0) then
  begin
    Handled := True;
    case Event.CharCode of
      ^N: NewCSIP;
      ^T: ToggleBreakPoint;
      ^C: ClearBreakPoints;
      ^R: Run;
      ^P: ProgramReset;
      ^U: GoToCursor;
      ^A: TraceInto;
      ^V: StepOver;
     #27: Exit;
      else Handled := False;
    end;
    Event.What := evNothing;
  end;
  if (Event.What = evBroadcast) and (Event.Command = cmUpdateViews) then
    PtrRec(SourceOrigin).Ofs := CPUStatus.ip_;
  TCodeList.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmFollow: NewCSIP;
      cmToggleBreakPoint: ToggleBreakPoint;
      cmClearBreakPoints: ClearBreakPoints;
      else Exit;
    end;
    Event.What := evNothing;
  end
  else if Event.What = evBroadcast then
  begin
    case Event.Command of
      cmRun: Run;
      cmProgramReset: ProgramReset;
      cmGoToCursor: GoToCursor;
      cmTraceInto: TraceInto;
      cmStepOver: StepOver;
      else Exit;
    end;
    ClearEvent(Event);
  end;
end;

procedure TSourceList.SetState(AState: Word; Enable: Boolean);
begin
  TScroller.SetState(AState, Enable);
  if (AState = sfExposed) and Enable then
    SetLimit(Limit.X, Limit.Y);
  if (AState = sfFocused) and Enable then DrawView;
  if (AState = sfFocused) and Enable then
    EnableCommands(BreakpointCommands + FindCommands)
  else if ((AState = sfExposed) and not Enable) or
    ((AState and (sfActive + sfSelected) <> 0) and
    not Enable and GetState(sfExposed)) then
      DisableCommands(BreakpointCommands + FindCommands);
end;

procedure TSourceList.Store(var S: TStream);
begin
  TScroller.Store(S);
end;

function TSourceList.DisasmBreak(var Address: Pointer): String;
var
  Index: Integer;
  P: Pointer;
begin
  if Byte(Address^) = $CC then
  begin
    P := Address;
    if BreaksCollection^.Search(Address, Index) then
      Byte(Address^) := PBreakRec(BreaksCollection^.At(Index))^.Value
        else
    if Address = TempBreak.Address then
      Byte(Address^) := TempBreak.Value;
    DisasmBreak := DisasmCom(Address, True);
    Byte(P^) := $CC;
  end
  else DisasmBreak := DisasmCom(Address, True);
end;

procedure TSourceList.InsertBreakPoint(AnAddress: Pointer;
  AValue: Byte);
var
  NewBreak: PBreakRec;
begin
  if not LowMemory then with BreaksCollection^ do
  begin
    GetMem(NewBreak, SizeOf(TBreakRec));
    NewBreak^.Address := AnAddress;
    NewBreak^.Value := AValue;
    Insert(NewBreak);
    Byte(AnAddress^) := $CC;
  end;
end;

procedure TSourceList.NewCSIP;
var
  P: Pointer;
begin
  P := GetFocused;
  with CPUStatus do
  begin
    cs_ := PtrRec(P).Seg;
    ip_ := PtrRec(P).Ofs;
  end;
  SourceOrigin := P;
  GoToOrigin;
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure TSourceList.ToggleBreakPoint;
var
  Index: Integer;
  CurPtr: Pointer;
begin
  CurPtr := GetFocused;
  if PtrRec(CurPtr).Seg >= PtrRec(HeapOrg).Seg then
  begin
    with BreaksCollection^ do
    begin
      if Search(CurPtr, Index) then
      begin
        Byte(CurPtr^) := PBreakRec(At(Index))^.Value;
        AtFree(Index);
      end
        else InsertBreakPoint(CurPtr, Byte(CurPtr^));
    end;
    GoDown;
    Message(Desktop, evBroadcast, cmUpdateViews, nil);
  end
  else BreakMsgBox;
end;

procedure TSourceList.ClearBreakPoints;
begin
  BreaksCollection^.FreeAll;
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure SetTempBreak(AnAddress: Pointer);
begin
  TempBreak.Address := AnAddress;
  TempBreak.Value := Byte(AnAddress^);
  Byte(AnAddress^) := $CC;
end;

procedure RestoreTempBreak;
begin
  with TempBreak do
  if Address <> nil then
  begin
    Byte(Address^) := Value;
    Address := nil;
  end;
end;

procedure TSourceList.Run;
begin
  DebugCommand := dcRun;
end;

procedure TSourceList.ProgramReset;
begin
  DebugCommand := dcReset;
end;

procedure TSourceList.GoToCursor;
var
  NextAddress: Pointer;
begin
  NextAddress := GetFocused;
  if PtrRec(NextAddress).Seg >= PtrRec(HeapOrg).Seg then
  begin
    SetTempBreak(NextAddress);
    DebugCommand := dcRun;
  end
  else BreakMsgBox;
end;

procedure TSourceList.TraceInto;
var
  Index: Integer;
begin
  if BreaksCollection^.Search(SourceOrigin, Index) then
  begin
    if PBreakRec(BreaksCollection^.At(Index))^.Value = $CD then StepOver
    else DebugCommand := dcTrace;
  end
  else
  begin
    if Byte(SourceOrigin^) = $CD then StepOver
    else DebugCommand := dcTrace;
  end;
end;

procedure TSourceList.StepOver;
var
  NextAddress: Pointer;
  Command: String[30];
begin
  NextAddress := SourceOrigin;
  Command := DisasmBreak(NextAddress);
  if Pos('rep', Command)  +
     Pos('call', Command) +
     Pos('int', Command) <> 0 then
  begin
    SetTempBreak(NextAddress);
    Run;
  end
  else DebugCommand := dcTrace;
end;

procedure TSourceList.PopUp(AnOrigin: TPoint);
begin
  ShowPopup(AnOrigin, NewMenu(
    NewItem('~G~o to...', '', kbNoKey, cmGoTo, hcGoToAddress,
    NewItem('~O~rigin', '', kbNoKey, cmOrigin, hcOrigin,
    NewItem('~F~ind...', '', kbNoKey, cmFind, hcSHFind,
    NewItem('~S~earch again', '', kbNoKey, cmSearchAgain, hcSHSearchAgain,
    NewItem('~N~ew cs:ip', '', kbNoKey, cmFollow, hcFollow,
    NewLine(
    NewItem('~T~oggle breakpoint', '', kbNoKey, cmToggleBreakpoint, hcDToggleBreakpoint,
    NewItem('~C~lear breakpoints', '', kbNoKey, cmClearBreakpoints, hcDClearBreakpoints,
    NewLine(
    NewItem('~R~un', 'Ctrl+F9', kbNoKey, cmRun, hcRRun,
    NewItem('~P~rogram reset', 'Ctrl+F2', kbNoKey, cmProgramReset, hcRProgramReset,
    NewItem('Go to c~u~rsor', 'F4', kbNoKey, cmGoToCursor, hcRGoToCursor,
    NewItem('Tr~a~ce into', 'F7', kbNoKey, cmTraceInto, hcRTraceInto,
    NewItem('Step o~v~er', 'F8', kbNoKey, cmStepOver, hcRStepOver,
    NewItem('An~i~mate tracing', '', kbNoKey, cmAnimateTracing, hcRAnimateTracing,
    NewItem('Animate st~e~pping', '', kbNoKey, cmAnimateStepping, hcRAnimateStepping,
      nil))))))))))))))))));
end;

constructor TRegistersList.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TListViewer.Init(Bounds, 1, AHScrollBar, AVScrollBar);
  Options := (Options or ofFramed) and not ofFirstClick;
  HScrollBar^.Options := HScrollBar^.Options or ofPostProcess;
  VScrollBar^.Options := VScrollBar^.Options or ofPostProcess;
  Range := MaxRegisters;
end;

function TRegistersList.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else if GetShiftState and kbCtrlShift <> 0 then
    GetHelpCtx := hcRegistersList
  else GetHelpCtx := hcRegs;
end;

function TRegistersList.GetPalette: PPalette;
const
  P: String[Length(CRegistersList)] = CRegistersList;
begin
  GetPalette := @P;
end;

function TRegistersList.GetText(Item: Integer; MaxLen: Integer): String;
const
  RegNames: Array[0..MaxRegisters - 1] of String[2] =
    ('ax', 'bx', 'cx', 'dx', 'si', 'di',
     'bp', 'sp', 'ds', 'es', 'ss', 'cs', 'ip');
begin
  if Item < Range then GetText :=
    RegNames[Item] + ' ' + HexW(PWordArray(@CPUStatus)^[Item])
  else GetText := '';
end;

procedure TRegistersList.HandleEvent(var Event: TEvent);
var
  Spot: TPoint;
begin
  if Event.What = evMouseDown then
  begin
    if MouseInView(Event.Where) and (Event.Buttons = mbRightButton) and
      (State and sfSelected <> 0) then
    begin
      repeat until not MouseEvent(Event, evMouseDown);
      PopUp(Event.Where);
      Event.What := evNothing;
    end;
  end;
  if (Event.What = evKeyDown) and (Event.CharCode in
      ['0'..'9', 'A'..'F', 'a'..'f', ^N, ^D, ^Z, ^M, ^C, ^I, #27]) then
  begin
    case Event.CharCode of
      ^N: Modify(FocusedValue + 1);
      ^D: Modify(FocusedValue - 1);
      ^Z: Modify(0);
      ^C, ^M: Change(#0);
      ^I, #27: Exit;
      else Change(Event.CharCode);
    end;
    Event.What := evNothing;
  end;
  TListViewer.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmIncrement: Modify(FocusedValue + 1);
      cmDecrement: Modify(FocusedValue - 1);
      cmZero: Modify(0);
      cmChange: Change(#0);
      cmPopUp:
        begin
          Spot.X := 0;
          Spot.Y := 0;
          MakeGlobal(Spot, Spot);
          PopUp(Spot);
        end;
      else Exit;
    end;
    Event.What := evNothing;
  end
  else if Event.What = evBroadcast then
    if (Event.Command = cmListItemSelected) and
       (Event.InfoPtr = @Self) then
    begin
      Change(#0);
      Event.What := evNothing;
    end
    else if Event.Command = cmUpdateViews then DrawView;
end;

procedure TRegistersList.SetState(AState: Word; Enable: Boolean);
begin
  TListViewer.SetState(AState, Enable);
  if (AState = sfExposed) and Enable then
  begin
    SetRange(Range);
    HScrollBar^.SetRange(0, Size.X - 2);
  end;
  if (State and sfExposed <> 0) and
     (AState and (sfActive + sfSelected) <> 0) then
    if GetState(sfActive + sfSelected) then
    begin
      HScrollBar^.Show;
      VScrollBar^.Show;
    end
    else
    begin
      HScrollBar^.Hide;
      VScrollBar^.Hide;
    end;
end;

function TRegistersList.FocusedValue: Word;
begin
  FocusedValue := PWordArray(@CPUStatus)^[Focused];
end;

procedure TRegistersList.Change(Initial: Char);
var
  W: Word;
  Deselect: Boolean;
  S: String;
begin
  if Initial = #0 then S := '$' + System.Copy(GetText(Focused, 11), 4, 255)
    else if Initial in ['0'..'9', 'A'..'F', 'a'..'f'] then
      S := '$' + Initial
    else S := Initial;
  Deselect := Initial <> #0;
  if not GetValue(W, S, Deselect,
    'Modify registers', '~E~nter new value') then Exit;
  Modify(W);
end;

procedure TRegistersList.Modify(NewValue: Word);
begin
  PWordArray(@CPUStatus)^[Focused] := NewValue;
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure TRegistersList.PopUp(AnOrigin: TPoint);
begin
  ShowPopup(AnOrigin, NewMenu(
    NewItem('~I~ncrement', '', kbNoKey, cmIncrement, hcIncrement,
    NewItem('~D~ecrement', '', kbNoKey, cmDecrement, hcDecrement,
    NewItem('~Z~ero', '', kbNoKey, cmZero, hcZero,
    NewItem('~C~hange...', '', kbNoKey, cmChange, hcChange, nil))))));
end;

constructor TFlagsList.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TListViewer.Init(Bounds, 1, AHScrollBar, AVScrollBar);
  Options := (Options or ofFramed) and not ofFirstClick;
  HScrollBar^.Options := HScrollBar^.Options or ofPostProcess;
  VScrollBar^.Options := VScrollBar^.Options or ofPostProcess;
  Range := MaxFlags;
end;

function TFlagsList.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else if GetShiftState and kbCtrlShift <> 0 then
    GetHelpCtx := hcFlagsList
  else GetHelpCtx := hcFlags;
end;

function TFlagsList.GetPalette: PPalette;
const
  P: String[Length(CFlagsList)] = CFlagsList;
begin
  GetPalette := @P;
end;

function TFlagsList.GetText(Item: Integer; MaxLen: Integer): String;
const
  FlagNames: Array[0..MaxFlags - 1] of Char =
    ('c', 'z', 's', 'o', 'p', 'a', 'i', 'd');
  FlagMasks: Array[0..MaxFlags - 1] of Word =
    ($1, $40, $80, $800, $4, $10, $200, $400);
begin
  if Item < Range then GetText :=
    FlagNames[Item] + '=' + Chr(
      Byte(CPUStatus.fl_ and FlagMasks[Item] <> 0) + $30)
  else GetText := '';
end;

procedure TFlagsList.HandleEvent(var Event: TEvent);
begin
  TListViewer.HandleEvent(Event);
  if (Event.What = evKeyDown) and
    (Event.CharCode in [^M, ^T,  '0', '1']) then
  begin
    Toggle;
    Event.What := evNothing;
  end
  else if Event.What = evBroadcast then
    if (Event.Command = cmListItemSelected) and
       (Event.InfoPtr = @Self) then
    begin
      Toggle;
      Event.What := evNothing;
    end
    else if Event.Command = cmUpdateViews then DrawView;
end;

procedure TFlagsList.SetState(AState: Word; Enable: Boolean);
begin
  TListViewer.SetState(AState, Enable);
  if (AState and sfExposed <> 0) and Enable then
  begin
    SetRange(Range);
    HScrollBar^.SetRange(0, Size.X - 2);
  end;
  if (State and sfExposed <> 0) and
     (AState and (sfActive + sfSelected) <> 0) then
    if GetState(sfActive + sfSelected) then
    begin
      HScrollBar^.Show;
      VScrollBar^.Show;
    end
    else
    begin
      HScrollBar^.Hide;
      VScrollBar^.Hide;
    end;
end;

procedure TFlagsList.Toggle;
const
  Masks: Array[0..MaxFlags - 1] of Word =
    ($1, $40, $80, $800, $4, $10, $200, $400);
begin
  with CPUStatus do fl_ := fl_ xor Masks[Focused];
  DrawView;
end;

constructor TMemList.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar; AnIndicator: PDumpIndicator);
begin
  TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
  Indicator := AnIndicator;
  Options := Options or ofFramed;
  HScrollBar^.Options := HScrollBar^.Options or ofPostProcess;
  VScrollBar^.Options := VScrollBar^.Options or ofPostProcess;
  Limit.X := Size.X;
  ShowCursor;
  SetCursor(LeftLimit, 0);
end;

procedure TMemList.Draw;
var
  C, Y: Byte;
  W: Word;
  Index: Longint;
  B: TDrawBuffer;
  S, SegS: String;
begin
  C := GetColor(1);
  for Y := 0 to Pred(Size.Y) do
  begin
    MoveChar(B, ' ', C, Size.X);
    Index := Delta.Y + Y - Shift;
    if Index < 0 then Index := Index + Limit.Y
      else if Index > Limit.Y then Index := Index - Limit.Y;
    PtrRec(MemPtr).Ofs := Word(Ratio * Index + Address);
    StringConvert(MemPtr^, S, Ratio);
    W := PtrRec(MemPtr).Seg;
    if W = CPUStatus.ds_ then SegS := '  ds'
      else if W = CPUStatus.es_ then SegS := '  es'
      else if W = CPUStatus.ss_ then SegS := '  ss'
      else if W = CPUStatus.cs_ then SegS := '  cs'
    else SegS := HexW(W);
    S := SegS + ':' + S;
    MoveStr(B[1], System.Copy(S, Succ(Delta.X), Size.X - 2), C);
    WriteLine(0, Y, Size.X, 1, B);
  end;
end;

procedure TMemList.HandleEvent(var Event: TEvent);
begin
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbTab, kbEsc: Exit;
    end;
  TDumpList.HandleEvent(Event);
end;

constructor TStackList.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TListViewer.Init(Bounds, 1, AHScrollBar, AVScrollBar);
  Options := (Options or ofFramed) and not ofFirstClick;
  HScrollBar^.Options := HScrollBar^.Options or ofPostProcess;
  VScrollBar^.Options := VScrollBar^.Options or ofPostProcess;
  Range := MaxInt;
end;

constructor TStackList.Load(var S: TStream);
begin
  TListViewer.Load(S);
  S.Read(Shift, SizeOf(Longint));
  S.Read(Address, SizeOf(Byte));
end;

function TStackList.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else if GetShiftState and kbCtrlShift <> 0 then
    GetHelpCtx := hcStackList
  else GetHelpCtx := hcStack;
end;

function TStackList.GetPalette: PPalette;
const
  P: String[Length(CStackList)] = CStackList;
begin
  GetPalette := @P;
end;

function TStackList.GetText(Item: Integer; MaxLen: Integer): String;
var
  Ch: Char;
  Offset: Word;
  Index: Longint;
begin
  Index := Item - Shift;
  if Index < 0 then Index := Index + Range + 1
    else if Index > Range - 1 then Index := Index - Range;
  Offset := 2 * Index + Address;
  if Offset = CPUStatus.sp_ then Ch := #16 else Ch := #0;
  with CPUStatus do
    GetText := 'ss:' + HexW(Offset) + Ch + HexW(Word(Ptr(ss_, Offset)^));
end;

procedure TStackList.FocusItem(Item: Integer);
begin
  if Item = 0 then
  begin
    Focused := Size.Y;
    TopItem := Size.Y;
    Inc(Shift, Size.Y);
    if Shift >= Range then Shift := Shift - Range;
    DrawView;
  end
    else
  if Item = Range - 1 then
  begin
    Focused := Range - Size.Y - 1;
    TopItem := Range - 2 * Size.Y;
    Dec(Shift, Size.Y);
    if Shift < 0 then Shift := Shift + Range;
    DrawView;
  end
    else TListViewer.FocusItem(Item);
end;

procedure TStackList.HandleEvent(var Event: TEvent);
var
  Spot: TPoint;
begin
  if Event.What = evMouseDown then
  begin
    if MouseInView(Event.Where) and (Event.Buttons = mbRightButton) and
      (State and sfSelected <> 0) then
    begin
      repeat until not MouseEvent(Event, evMouseDown);
      PopUp(Event.Where);
      Event.What := evNothing;
    end;
  end;
  if (Event.What = evKeyDown) and (Event.CharCode in
      ['0'..'9', 'A'..'F', 'a'..'f', ^G, ^O, ^F, ^M, ^C, ^I, #27]) then
  begin
    case Event.CharCode of
      ^G: GoToAddress;
      ^O: GoToOrigin;
      ^F: Follow;
      ^C, ^M: Change(#0);
      ^I, #27: Exit;
      else Change(Event.CharCode);
    end;
    Event.What := evNothing;
  end;
  TListViewer.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmGoTo: GoToAddress;
      cmOrigin: GoToOrigin;
      cmFollow: Follow;
      cmChange: Change(#0);
      cmPopUp:
        begin
          Spot.X := 0;
          Spot.Y := 0;
          MakeGlobal(Spot, Spot);
          PopUp(Spot);
        end;
      else Exit;
    end;
    Event.What := evNothing;
  end
  else if Event.What = evBroadcast then
    if (Event.Command = cmListItemSelected) and
       (Event.InfoPtr = @Self) then
    begin
      Change(#0);
      Event.What := evNothing;
    end
    else if Event.Command = cmUpdateViews then GoToOrigin;
end;

procedure TStackList.SetState(AState: Word; Enable: Boolean);
begin
  TListViewer.SetState(AState, Enable);
  if (AState and sfExposed <> 0) and Enable then
  begin
    SetRange(Range);
    HScrollBar^.SetRange(0, Size.X - 3);
  end;
  if (State and sfExposed <> 0) and
     (AState and (sfActive + sfSelected) <> 0) then
    if GetState(sfActive + sfSelected) then
    begin
      HScrollBar^.Show;
      VScrollBar^.Show;
      FocusItem(Focused);
    end
    else
    begin
      HScrollBar^.Hide;
      VScrollBar^.Hide;
    end;
end;

procedure TStackList.Store(var S: TStream);
begin
  TListViewer.Store(S);
  S.Write(Shift, SizeOf(Longint));
  S.Write(Address, SizeOf(Byte));
end;

procedure TStackList.GoToPos(APos: Word);
var
  W: Word;
begin
  Shift := 0;
  Address := Byte(Odd(APos));
  FocusItem(APos div 2);
  DrawView;
end;

procedure TStackList.GoToAddress;
var
  W: Word;
  S: String;
begin
  S := '$' + System.Copy(GetText(Focused, 11), 4, 4);
  if not GetValue(W, S, False,
    'Go to address', '~N~ew address') then Exit;
  GoToPos(W);
end;

procedure TStackList.GoToOrigin;
begin
  with CPUStatus do GoToPos(sp_);
end;

procedure TStackList.Follow;
var
  Index: Longint;
  W, Offset: Word;
begin
  Index := Focused - Shift;
  if Index < 0 then Index := Index + Range + 1
    else if Index > Range - 1 then Index := Index - Range;
  Offset := 2 * Index + Address;
  with CPUStatus do W := Word(Ptr(ss_, Offset)^);
  GoToPos(W);
end;

procedure TStackList.Change(Initial: Char);
var
  Deselect: Boolean;
  W: Word;
  Index: Longint;
  S: String;
begin
  if Initial = #0 then S := '$' + System.Copy(GetText(Focused, 255), 9, 255)
    else if Initial in ['0'..'9', 'A'..'F', 'a'..'f'] then
      S := '$' + Initial
    else S := Initial;
  Deselect := Initial <> #0;
  if not GetValue(W, S, Deselect,
    'Modify stack', '~E~nter new value') then Exit;
  Modify(W);
end;

procedure TStackList.Modify(NewValue: Word);
var
  Index: Longint;
begin
  Index := Focused - Shift;
  if Index < 0 then Index := Index + Range + 1
    else if Index > Range - 1 then Index := Index - Range;
  with CPUStatus do
    Word(Ptr(ss_, 2 * Index + Address)^) := NewValue;
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure TStackList.PopUp(AnOrigin: TPoint);
begin
  ShowPopup(AnOrigin, NewMenu(
    NewItem('~G~o to...', '', kbNoKey, cmGoTo, hcGoToAddress,
    NewItem('~O~rigin', '', kbNoKey, cmOrigin, hcOrigin,
    NewItem('~F~ollow', '', kbNoKey, cmFollow, hcFollow,
    NewItem('~C~hange...', '', kbNoKey, cmChange, hcChange, nil))))));
end;

procedure TCPUIndicator.Draw;
var
  C: Byte;
  Ch: Char;
  B: TDrawBuffer;
  S: String;
begin
  if State and sfActive = 0 then
  begin
    C := GetColor(1);
    Ch := #196;
  end
  else if State and sfDragging <> 0 then
  begin
    C := GetColor(3);
    Ch := #196;
  end
  else
  begin
    C := GetColor(2);
    Ch := #205;
  end;
  MoveChar(B, Ch, C, Size.X);
  with PCPUWindow(Owner)^ do
  begin
    S := GetMemValue(SourceList^.GetFocused);
    if S <> '' then S := ' ' + S + ' ';
  end;
  MoveStr(B, S, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TCPUIndicator.GetPalette: PPalette;
const
  P: String[3] = #1#2#3;
begin
  GetPalette := @P;
end;

procedure TCPUIndicator.HandleEvent(var Event: TEvent);
var
  Limits: TRect;
begin
  TView.HandleEvent(Event);
  if Event.What = evMouseDown then with PWindow(Owner)^ do
  begin
    if Event.Double then
    begin
      Pending.What := evCommand;
      Pending.Command := cmZoom;
      Pending.InfoPtr := nil;
    end
    else
    begin
      Desktop^.GetExtent(Limits);
      DragView(Event, dmDragMove, Limits, Size, Size);
    end;
    Event.What := evNothing;
  end
  else if (Event.What = evBroadcast) and
    (Event.Command = cmUpdateViews) then DrawView;
end;

procedure TCPUIndicator.SetState(AState: Word; Enable: Boolean);
begin
  TView.SetState(AState, Enable);
  DrawView;
end;

procedure ResetCPUWindow;
begin
  CloseCPUWindow;
  SetTraceVectors;
  LongJump;
end;

constructor TCPUWindow.Init;
var
  HControl, VControl, IControl: PView;
  R: TRect;
begin
  R.Assign(0, 0, 62, ScreenHeight - 4);
  TWindow.Init(R, 'CPU window', wnNoNumber);
  Options := Options or ofCentered;

  R.Assign(1, 14, 45, 15);
  HControl := New(PScrollBar, Init(R));
  Insert(HControl);
  R.Assign(45, 1, 46, 14);
  VControl := New(PScrollBar, Init(R));
  Insert(VControl);
  R.Assign(1, 1, 45, 14);
  SourceList := New(PSourceList, Init(R,
    PScrollBar(HControl), PScrollBar(VControl)));
  Insert(SourceList);

  R.Assign(46, 14, 55, 15);
  HControl := New(PScrollBar, Init(R));
  Insert(HControl);
  R.Assign(55, 1, 56, 14);
  VControl := New(PScrollBar, Init(R));
  Insert(VControl);
  R.Assign(46, 1, 55, 14);
  RegistersList := New(PRegistersList, Init(R,
    PScrollBar(HControl), PScrollBar(VControl)));
  Insert(RegistersList);

  R.Assign(56, 14, 61, 15);
  HControl := New(PScrollBar, Init(R));
  Insert(HControl);
  R.Assign(61, 1, 62, 14);
  VControl := New(PScrollBar, Init(R));
  Insert(VControl);
  R.Assign(56, 1, 61, 14);
  FlagsList := New(PFlagsList, Init(R,
    PScrollBar(HControl), PScrollBar(VControl)));
  Insert(FlagsList);

  R.Assign(12, 20, 45, 21);
  HControl := New(PScrollBar, Init(R));
  Insert(HControl);
  R.Assign(45, 15, 46, 20);
  VControl := New(PScrollBar, Init(R));
  Insert(VControl);
  R.Assign(1, 20, 12, 21);
  IControl := New(PDumpIndicator, Init(R));
  IControl^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(IControl);
  IControl^.Hide;
  R.Assign(1, 15, 45, 20);
  MemList := New(PMemList, Init(R,
    PScrollBar(HControl), PScrollBar(VControl), PDumpIndicator(IControl)));
  Insert(MemList);

  R.Assign(46, 20, 61, 21);
  HControl := New(PScrollBar, Init(R));
  Insert(HControl);
  R.Assign(61, 15, 62, 20);
  VControl := New(PScrollBar, Init(R));
  Insert(VControl);
  R.Assign(46, 15, 61, 20);
  StackList := New(PStackList, Init(R,
    PScrollBar(HControl), PScrollBar(VControl)));
  Insert(StackList);

  GetExtent(R);
  Inc(R.A.X, 6); R.B.Y := R.A.Y + 1; R.B.X := R.A.X + 14;
  Indicator := New(PCPUIndicator, Init(R));
  Indicator^.EventMask := $FFFF;
  Insert(Indicator);

  SourceList^.Select;
end;

constructor TCPUWindow.Load(var S: TStream);
begin
  TWindow.Load(S);
  GetSubViewPtr(S, SourceList);
  GetSubViewPtr(S, RegistersList);
  GetSubViewPtr(S, FlagsList);
  GetSubViewPtr(S, MemList);
  GetSubViewPtr(S, StackList);
  GetSubViewPtr(S, Indicator);
end;

procedure TCPUWindow.ChangeBounds(var Bounds: TRect);
var
  Delta: Integer;
  Min, Max: TPoint;
begin
  SizeLimits(Min, Max);
  if Bounds.B.Y - Bounds.A.Y < Min.Y then Bounds.B.Y := Bounds.A.Y + Min.Y;
  Delta := Bounds.B.Y - Bounds.A.Y - Size.Y;
  if Current^.Origin.Y = 1 then
  begin
    if Delta > 0 then
      if RegistersList^.Size.Y + Delta > MaxRegisters then
        SetNewGrowMode(gmSourceStack)
      else SetNewGrowMode(gmSourceRegsFlags)
    else
      if (MemList^.Size.Y + Delta > 0) and
         (StackList^.Size.Y + Delta > 0) then
        SetNewGrowMode(gmMemStack)
      else if (MemList^.Size.Y + Delta > 0) and
         (RegistersList^.Size.Y + Delta > 0) then
        SetNewGrowMode(gmMemRegsFlags)
      else if (SourceList^.Size.Y + Delta > 0) and
         (StackList^.Size.Y + Delta > 0) then
        SetNewGrowMode(gmSourceStack)
      else if (SourceList^.Size.Y + Delta > 0) and
         (RegistersList^.Size.Y + Delta > 0) then
        SetNewGrowMode(gmSourceRegsFlags)
      else GetBounds(Bounds);
  end
  else
  begin
    if Delta > 0 then
      if RegistersList^.Size.Y + Delta > MaxRegisters then
        SetNewGrowMode(gmMemStack)
      else SetNewGrowMode(gmMemRegsFlags)
    else
      if (SourceList^.Size.Y + Delta > 0) and
         (StackList^.Size.Y + Delta > 0) then
        SetNewGrowMode(gmSourceStack)
      else if (SourceList^.Size.Y + Delta > 0) and
         (RegistersList^.Size.Y + Delta > 0) then
        SetNewGrowMode(gmSourceRegsFlags)
      else if (MemList^.Size.Y + Delta > 0) and
         (StackList^.Size.Y + Delta > 0) then
        SetNewGrowMode(gmMemStack)
      else if (MemList^.Size.Y + Delta > 0) and
         (RegistersList^.Size.Y + Delta > 0) then
        SetNewGrowMode(gmMemRegsFlags)
      else GetBounds(Bounds);
  end;
  TWindow.ChangeBounds(Bounds);
end;

function TCPUWindow.GetPalette: PPalette;
const
  P: String[Length(CCPUWindow)] = CCPUWindow;
begin
  GetPalette := @P;
end;

function TCPUWindow.GetTitle(MaxSize: Integer): TTitleStr;
begin
  if Size.X < 51 then GetTitle := ''
  else GetTitle := TWindow.GetTitle(MaxSize);
end;

procedure TCPUWindow.HandleEvent(var Event: TEvent);
var
  NV: PView;

function IsCurrent(P: PView): Boolean;
begin
  IsCurrent := P^.State and sfSelected <> 0;
end;

procedure GetNextView(KeyDirection: Word; var NextView: PView);
begin
  NextView := nil;
  case KeyDirection of
    kbRight:
      if IsCurrent(SourceList) then NextView := RegistersList
      else if IsCurrent(RegistersList) then NextView := FlagsList
      else if IsCurrent(MemList) then NextView := StackList;
    kbLeft:
      if IsCurrent(FlagsList) then NextView := RegistersList
      else if IsCurrent(RegistersList) then NextView := SourceList
      else if IsCurrent(StackList) then NextView := MemList;
    kbUp:
      if IsCurrent(MemList) then NextView := SourceList
      else if IsCurrent(StackList) then NextView := RegistersList;
    kbDown:
      if IsCurrent(SourceList) then NextView := MemList
      else if IsCurrent(RegistersList) then NextView := MemList
      else if IsCurrent(FlagsList) then NextView := StackList;
  end;
end;

begin
  if (Event.What = evKeyDown) and
     (GetShiftState and (kbLeftShift + kbRightShift) <> 0) then
    case Event.KeyCode of
      kbRight, kbLeft, kbUp, kbDown:
        begin
          GetNextView(Event.KeyCode, NV);
          if NV <> nil then NV^.Select;
          Event.What := evNothing;
        end;
      kbEsc:
        begin
          Event.What := evCommand;
          Event.Command := cmClose;
          Event.InfoPtr := @Self;
        end;
    end;
  if Event.What = evBroadcast then
    case Event.Command of
      cmIsCPU: ClearEvent(Event);
      cmDoneCPU:
        begin
          Event.What := evCommand;
          Event.Command := cmClose;
          if Icon <> nil then
          begin
            Deiconize;
            Show;
            Select;
          end;
        end;
    end;
  if (Event.What = evCommand) and (Event.Command = cmClose) and not
     ((Event.InfoPtr = @Self) and
      (GetShiftState and (kbLeftShift + kbRightShift) <> 0)) then
    DebugCommand := dcReset;
  TWindow.HandleEvent(Event);
end;

procedure TCPUWindow.SizeLimits(var Min, Max: TPoint);
begin
  TWindow.SizeLimits(Min, Max);
  Min.X := 32;
end;

procedure TCPUWindow.Store(var S: TStream);
begin
  TWindow.Store(S);
  PutSubViewPtr(S, SourceList);
  PutSubViewPtr(S, RegistersList);
  PutSubViewPtr(S, FlagsList);
  PutSubViewPtr(S, MemList);
  PutSubViewPtr(S, StackList);
  PutSubViewPtr(S, Indicator);
end;

procedure TCPUWindow.SetNewGrowMode(AMode: Byte);
begin
  if AMode = NewGrowMode then Exit;
  NewGrowMode := AMode;
  case AMode of
    gmSourceRegsFlags:
      begin
        with SourceList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowHiY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
        end;
        with RegistersList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
        end;
        with FlagsList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
        end;
        with MemList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowHiY + gfGrowLoY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
        end;
        with StackList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
        end;
      end;
      gmMemStack:
      begin
        with SourceList^ do
        begin
          GrowMode := gfGrowHiX;
          HScrollBar^.GrowMode := gfGrowHiX;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX;
        end;
        with RegistersList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX;
        end;
        with FlagsList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX;
        end;
        with MemList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowHiY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
        end;
        with StackList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
        end;
      end;
      gmSourceStack:
      begin
        with SourceList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowHiY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
        end;
        with RegistersList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX;
        end;
        with FlagsList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX;
        end;
        with MemList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowHiY + gfGrowLoY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
        end;
        with StackList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
        end;
      end;
      gmMemRegsFlags:
      begin
        with SourceList^ do
        begin
          GrowMode := gfGrowHiX;
          HScrollBar^.GrowMode := gfGrowHiX;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX;
        end;
        with RegistersList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
        end;
        with FlagsList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
        end;
        with MemList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowHiY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY;
        end;
        with StackList^ do
        begin
          GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
          HScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
          VScrollBar^.GrowMode := gfGrowHiX + gfGrowLoX + gfGrowHiY + gfGrowLoY;
        end;
      end;
  end;
end;

procedure RSRCPUWindow(RSR: PResourceFile);
var
  W: PCPUWindow;
begin
  W := New(PCPUWindow, Init);
  RSR^.Put(W, 'CPUWINDOW');
  Dispose(W, Done);
end;

procedure SetTraceFlag;
begin
  with CPUStatus do fl_ := fl_ or $100;
end;

procedure ClearTraceFlag;
begin
  with CPUStatus do fl_ := fl_ and $FEFF;
end;

procedure GetBreak;
var
  Index: Integer;
  P : Pointer;
begin
  P := Ptr(CPUStatus.cs_, CPUStatus.ip_);
  with BreaksCollection^ do
    if Search(P, Index) then
    begin
      Byte(P^) := PBreakRec(At(Index))^.Value;
      BreakFlag := P;
    end;
end;

procedure CPUWindow;
var
  First: Boolean;
  W: PCPUWindow;
  R: TRect;
  Event: TEvent;
begin
  W := Message(Desktop, evBroadcast, cmIsCPU, nil);
  if W = nil then
  begin
    W := PCPUWindow(Resource^.Get('CPUWINDOW'));
    if Application^.ValidView(W) <> nil then
    begin
      W^.Options := W^.Options or ofNotStorable;
      R.Assign(9, 2, 71, ScreenHeight - 2);
      W^.Locate(R);
      CPUInUse := True;
      BreaksCollection := New(PBreaksCollection, Init(16, 1));
      PtrRec(W^.MemList^.MemPtr).Seg := CPUStatus.ds_;
    end
    else ResourceNotFoundMsgBox('CPU window');
    First := True;
  end
  else First := False;
  if W <> nil then
  begin
    W^.SourceList^.SourceOrigin := Ptr(CPUStatus.cs_, CPUStatus.ip_);
    W^.SourceList^.FocusItem(W^.SourceList^.SourceOrigin);
    W^.StackList^.GoToOrigin;
    if First then Desktop^.Insert(W);
    Message(Desktop, evBroadcast, cmUpdateViews, nil);
    DebugCommand := dcNothing;
    OpenCPUWindow := SaveCPUFlag;
    repeat
      NestedEventCount := 0;
      Application^.GetEvent(Event);
      if AnimateEvent.What <> evNothing then
      begin
        if (Event.What = evKeyDown) or (Event.What = evMouseDown) then
        begin
          AnimateEvent.What := evNothing;
          Application^.ClearEvent(Event);
        end
        else Event := AnimateEvent;
        if AnimateDelay <> 0 then Pause(AnimateDelay);
      end;
      Application^.HandleEvent(Event);
    until not CPUInUse or (DebugCommand <> dcNothing);
    SaveCPUFlag := OpenCPUWindow;
    if DebugCommand = dcReset then ResetCPUWindow;
  end
  else MessageBox(^C'Could not open CPU window.', nil, mfError + mfOkButton);
end;

procedure HandleBreak; interrupt;
begin
 asm
  mov CPUStatus.sp_,bp
  add CPUStatus.sp_,24
  mov ax,[bp]
  mov CPUStatus.bp_,ax
  mov ax,[bp+2]
  mov CPUStatus.es_,ax
  mov ax,[bp+4]
  mov CPUStatus.ds_,ax
  mov ax,[bp+6]
  mov CPUStatus.di_,ax
  mov ax,[bp+8]
  mov CPUStatus.si_,ax
  mov ax,[bp+10]
  mov CPUStatus.dx_,ax
  mov ax,[bp+12]
  mov CPUStatus.cx_,ax
  mov ax,[bp+14]
  mov CPUStatus.bx_,ax
  mov ax,[bp+16]
  mov CPUStatus.ax_,ax
  mov ax,[bp+18]
  dec ax
  mov CPUStatus.ip_,ax
  mov ax,[bp+20]
  mov CPUStatus.cs_,ax
  mov ax,[bp+22]
  mov CPUStatus.fl_,ax
  mov ax,ss
  mov CPUStatus.ss_,ax
 end;
 with CPUStatus do
  begin
   if cs_ > PtrRec(HeapOrg).Seg then
    begin
     RestoreTempBreak;
     if BreakFlag <> nil then Byte(BreakFlag^) := $CC;
     BreakFlag := nil;
     if not MissBreak then CPUWindow;
     GetBreak;
     if Byte(Ptr(cs_,ip_)^) = $CC then Byte(Ptr(cs_,ip_)^) := $90;
     MissBreak := False;
     F4Flag := TempBreak.Address = Ptr(cs_,ip_);
     if F4Flag then Byte(TempBreak.Address^) := TempBreak.Value;
     case DebugCommand of
        dcReset: ResetCPUWindow;
        dcTrace: if not MissBreak then SetTraceFlag else ClearTraceFlag;
        dcRun  : SetTraceFlag;
        dcStep : ClearTraceFlag;
      end;
     end
    else Byte(Ptr(cs_,ip_)^) := $90;
   end;
 asm
  mov ax,CPUStatus.es_
  mov [bp+2],ax
  mov ax,CPUStatus.ds_
  mov [bp+4],ax
  mov ax,CPUStatus.di_
  mov [bp+6],ax
  mov ax,CPUStatus.si_
  mov [bp+8],ax
  mov ax,CPUStatus.dx_
  mov [bp+10],ax
  mov ax,CPUStatus.cx_
  mov [bp+12],ax
  mov ax,CPUStatus.bx_
  mov [bp+14],ax
  mov ax,CPUStatus.ax_
  mov [bp+16],ax
  mov ax,CPUStatus.ip_
  mov [bp+18],ax
  mov ax,CPUStatus.cs_
  mov [bp+20],ax
  mov ax,CPUStatus.fl_
  mov [bp+22],ax
 end;
end;

procedure SingleStep; interrupt;
begin
 asm
  mov CPUStatus.sp_,bp
  add CPUStatus.sp_,24
  mov ax,[bp]
  mov CPUStatus.bp_,ax
  mov ax,[bp+2]
  mov CPUStatus.es_,ax
  mov ax,[bp+4]
  mov CPUStatus.ds_,ax
  mov ax,[bp+6]
  mov CPUStatus.di_,ax
  mov ax,[bp+8]
  mov CPUStatus.si_,ax
  mov ax,[bp+10]
  mov CPUStatus.dx_,ax
  mov ax,[bp+12]
  mov CPUStatus.cx_,ax
  mov ax,[bp+14]
  mov CPUStatus.bx_,ax
  mov ax,[bp+16]
  mov CPUStatus.ax_,ax
  mov ax,[bp+18]
  mov CPUStatus.ip_,ax
  mov ax,[bp+20]
  mov CPUStatus.cs_,ax
  mov ax,[bp+22]
  mov CPUStatus.fl_,ax
  mov ax,ss
  mov CPUStatus.ss_,ax
 end;
 with CPUStatus do
  if cs_ > PtrRec(HeapOrg).Seg then
   begin
     if F4Flag then
       begin
        Byte(TempBreak.Address^) := $CC;
        ClearTraceFlag;
       end
     else
       begin
        if BreakFlag <> nil then Byte(BreakFlag^) := $CC;
        if (DebugCommand = dcRun) or (Byte(Ptr(cs_,ip_)^) = $CC) then
          ClearTraceFlag
        else
          begin
            CPUWindow;
            MissBreak := Byte(Ptr(cs_,ip_)^) = $CC;
            GetBreak;
            F4Flag := TempBreak.Address = Ptr(cs_,ip_);
            if F4Flag then
              begin
               Byte(TempBreak.Address^) := TempBreak.Value;
               MissBreak := False;
              end;
            case DebugCommand of
             dcReset: ResetCPUWindow;
             dcTrace: ;
             dcRun  : if F4Flag then SetTraceFlag else ClearTraceFlag;
             dcStep : ClearTraceFlag;
            end;
          end;
       end;
   end;
{  else ClearTraceFlag;}
 asm
  mov ax,CPUStatus.es_
  mov [bp+2],ax
  mov ax,CPUStatus.ds_
  mov [bp+4],ax
  mov ax,CPUStatus.di_
  mov [bp+6],ax
  mov ax,CPUStatus.si_
  mov [bp+8],ax
  mov ax,CPUStatus.dx_
  mov [bp+10],ax
  mov ax,CPUStatus.cx_
  mov [bp+12],ax
  mov ax,CPUStatus.bx_
  mov [bp+14],ax
  mov ax,CPUStatus.ax_
  mov [bp+16],ax
  mov ax,CPUStatus.ip_
  mov [bp+18],ax
  mov ax,CPUStatus.cs_
  mov [bp+20],ax
  mov ax,CPUStatus.fl_
  mov [bp+22],ax
 end;
end;

procedure GetTraceVectors;
begin
  GetIntVec(1, SaveInt1Vect);
  SetIntVec(1, @SingleStep);
  GetIntVec(3, SaveInt3Vect);
  SetIntVec(3, @HandleBreak);
  TempBreak.Address := nil;
  BreakFlag := nil;
  MissBreak := False;
  F4Flag := False;
  DebugCommand := dcNothing;
end;

procedure SetTraceVectors;
begin
  SetIntVec(1, SaveInt1Vect);
  SetIntVec(3, SaveInt3Vect);
  RestoreTempBreak;
end;

end.