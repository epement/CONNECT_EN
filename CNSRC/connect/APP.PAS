{*******************************************************}
{                                                       }
{       Copyright (c) 1990 Borland International	}
{                                                       }
{*******************************************************}

unit App;

{$X+,O-,F+}

interface

uses Objects, Drivers, Memory, HistList, Views, Menus, Dialogs;

const

{ TApplication palette entries }

  apColor      = 0;
  apBlackWhite = 1;
  apMonochrome = 2;

{ TApplication palettes }

  CColor =
	#$71#$70#$78#$74#$50#$58#$54#$17#$1F#$1A#$31#$31#$1E#$71#$14 +
    #$38#$3F#$3A#$13#$13#$3E#$51#$34#$70#$7F#$7A#$13#$13#$70#$7F#$5E +
    #$70#$7F#$7A#$13#$13#$70#$70#$7F#$7E#$50#$5B#$5F#$78#$5E#$70#$30 +
    #$3F#$3E#$1F#$5F#$1A#$20#$72#$31#$31#$30#$5F#$3E#$31#$13#$38#$5E;

  CBlackWhite =
	#$70#$70#$78#$7F#$07#$07#$0F#$07#$0F#$07#$70#$70#$07#$70#$0F +
    #$07#$0F#$07#$70#$70#$07#$70#$0F#$70#$7F#$7F#$70#$07#$70#$07#$0F +
    #$70#$7F#$7F#$70#$07#$70#$70#$7F#$7F#$07#$0F#$0F#$78#$0F#$78#$07 +
    #$0F#$0F#$0F#$70#$0F#$07#$70#$70#$70#$07#$70#$0F#$07#$07#$70#$0F;

  CMonochrome =
	#$70#$07#$07#$0F#$70#$70#$70#$07#$0F#$07#$70#$70#$07#$70#$0F +
    #$07#$0F#$07#$70#$70#$07#$70#$0F#$70#$70#$70#$07#$07#$70#$07#$0F +
    #$70#$70#$70#$07#$07#$70#$70#$70#$0F#$07#$07#$0F#$70#$0F#$70#$07 +
    #$0F#$0F#$07#$70#$07#$07#$70#$07#$07#$07#$70#$0F#$07#$07#$70#$0F;


{ TBackground palette }

  CBackground = #1;

type

{ TBackground object }

  PBackground = ^TBackground;
  TBackground = object(TView)
    Pattern: Char;
    constructor Init(var Bounds: TRect; APattern: Char);
{    constructor Load(var S: TStream);}
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
{    procedure Store(var S: TStream);}
  end;

{ TDesktop object }

  PDesktop = ^TDesktop;
  TDesktop = object(TGroup)
    Background: PBackground;
    constructor Init(var Bounds: TRect);
    procedure Cascade(var R: TRect);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitBackground; virtual;
    procedure Tile(var R: TRect);
    procedure TileError; {virtual;}
  end;

{ TProgram object }

  { Palette layout }
  {     1 = TBackground }
  {  2- 7 = TMenuView and TStatusLine }
  {  8-15 = TWindow(Blue) }
  { 16-23 = TWindow(Cyan) }
  { 24-31 = TWindow(Gray) }
  { 32-63 = TDialog }

  PProgram = ^TProgram;
  TProgram = object(TGroup)
    constructor Init;
    destructor Done; virtual;
    function CanMoveFocus: Boolean;
    function ExecuteDialog(P: PDialog; Data: Pointer; Top: Boolean): Word;
    procedure GetEvent(var Event: TEvent); virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Idle; virtual;
    procedure InitDesktop; virtual;
    procedure InitMenuBar; virtual;
    procedure InitResource; virtual;
    procedure InitScreen; virtual;
    procedure InitStatusLine; virtual;
    function InsertWindow(P: PWindow): PWindow;
    procedure OutOfMemory; virtual;
    procedure PutEvent(var Event: TEvent); virtual;
    procedure RegisterTypes;
    procedure Run; virtual;
{    procedure SetScreenMode(Mode: Word);}
    function ValidView(P: PView): PView;
  end;

{ TApplication object }

  PApplication = ^TApplication;
  TApplication = object(TProgram)
    constructor Init;
    destructor Done; virtual;
  end;

{ Record key procedure }

  TRecordKeyProc = procedure(Key: Word);

{ Draw status procedure }

procedure DrawStatusLine(const S: String);

{ Default Record key procedure }

procedure DefRecordKeyProc(Key: Word);

{ App registration procedure }

procedure RegisterApp;

{ Is there any modal window on ? }

function NoModalWindows: Boolean;

{ Idle call }

const
  FirstIdleCall: Boolean = True;
  IdleState: Boolean = False;

  tsAll = 0;
  tsIdle = 1;
  TimeSliceOptions: Byte = tsAll;

  ttNo = 0;
  ttInt28 = 1;
  ttInt2F = 2;
  TimeSliceType: Byte = ttNo;

  OS2Installed: Boolean = False;

procedure GiveTicks;

const

{ Public variables }

  Application: PProgram = nil;
  Desktop: PDesktop = nil;
  Resource: PResourceFile = nil;
  StatusLine: PStatusLine = nil;
  MenuBar: PMenuView = nil;
  AppPalette: Integer = apColor;

  Pending: TEvent = (What: evNothing);

  RecordKeys: Boolean = False;
  RecordKeyProc: TRecordKeyProc = DefRecordKeyProc;

  CreatingResource: Boolean = False;

{ Stream registration records }

{
  RBackground: TStreamRec = (
    ObjType: 30;
    VmtLink: Ofs(TypeOf(TBackground)^);
    Load: @TBackground.Load;
    Store: @TBackground.Store);

  RDesktop: TStreamRec = (
    ObjType: 31;
    VmtLink: Ofs(TypeOf(TDesktop)^);
    Load: @TDesktop.Load;
    Store: @TDesktop.Store);
}

implementation

uses Dos, AppPrim, Gauges, TilePrim, Defaults;

{ TBackground }

constructor TBackground.Init(var Bounds: TRect; APattern: Char);
begin
  TView.Init(Bounds);
  Options := Options or ofNotStorable;
  GrowMode := gfGrowHiX + gfGrowHiY;
  Pattern := APattern;
end;

{
constructor TBackground.Load(var S: TStream);
begin
  TView.Load(S);
  S.Read(Pattern, SizeOf(Pattern));
end;
}

procedure TBackground.Draw;
var
  B: TDrawBuffer;
begin
  MoveChar(B, Pattern, GetColor($01), Size.X);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

function TBackground.GetPalette: PPalette;
const
  P: String[Length(CBackground)] = CBackground;
begin
  GetPalette := @P;
end;

{
procedure TBackground.Store(var S: TStream);
begin
  TView.Store(S);
  S.Write(Pattern, SizeOf(Pattern));
end;
}

{ TDesktop object }

constructor TDesktop.Init(var Bounds: TRect);
begin
  TGroup.Init(Bounds);
  GrowMode := gfGrowHiX + gfGrowHiY;
  InitBackground;
  if Background <> nil then Insert(Background);
end;

procedure TDesktop.Cascade(var R: TRect);
begin
  CascadeViews(R);
end;

procedure TDesktop.HandleEvent(var Event: TEvent);
begin
  TGroup.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmNext: SelectNext(False);
      cmPrev: Current^.PutInFrontOf(Background);
    else
      Exit;
    end;
    Event.What := evNothing;
  end;
end;

procedure TDesktop.InitBackground;
var
  R: TRect;
begin
  GetExtent(R);
  New(Background, Init(R, #176));
end;

procedure TDesktop.Tile(var R: TRect);
begin
  TileViews(R);
end;

procedure TDesktop.TileError;
begin
  StandardTileError;
end;

{ TProgram }

constructor TProgram.Init;
var
  R: TRect;
begin
  Application := @Self;
  InitScreen;
  R.Assign(0, 0, ScreenWidth, ScreenHeight);
  TGroup.Init(R);
  State := sfVisible + sfSelected + sfFocused + sfModal + sfExposed;
  Options := 0;
  Buffer := ScreenBuffer;
  InitResource;
  InitDesktop;
  InitStatusLine;
  InitMenuBar;
  if Desktop <> nil then Insert(Desktop);
  if StatusLine <> nil then Insert(StatusLine);
  if MenuBar <> nil then Insert(MenuBar);
  InitHeap;
  InitClock;
end;

destructor TProgram.Done;
begin
  Dispose(Clock, Done);
  Dispose(Heap, Done);
  if Desktop <> nil then Dispose(Desktop, Done);
  if MenuBar <> nil then Dispose(MenuBar, Done);
  if StatusLine <> nil then Dispose(StatusLine, Done);
  if Resource <> nil then Dispose(Resource, Done);
  Application := nil;
end;

function TProgram.CanMoveFocus: Boolean;
begin
  CanMoveFocus := Desktop^.Valid(cmReleasedFocus);
end;

function TProgram.ExecuteDialog(P: PDialog; Data: Pointer; Top: Boolean): Word;
begin
  ExecuteDialog := ExecuteDialogPrim(P, Data, Top);
end;

procedure TProgram.GetEvent(var Event: TEvent);

function ContainsMouse(P: PView): Boolean; far;
begin
  ContainsMouse := (P^.State and sfVisible <> 0) and
    P^.MouseInView(Event.Where);
end;

begin
  Inc(NestedEventCount); { Added 12.26.97 }
  if UpdateMouseShape then
  begin
    Event.What := evMouseMove;
    Event.Where := MouseWhere;
    HandleEvent(Event);
    UpdateMouseShape := False;
  end;
  if Pending.What <> evNothing then
  begin
    Event := Pending;
    Pending.What := evNothing;
  end else
  begin
    GetMouseEvent(Event);
    if Event.What = evNothing then
    begin
      GetKeyEvent(Event);
      if Event.What = evNothing then Idle
      else if RecordKeys then RecordKeyProc(Event.KeyCode);
    end;
    if MouseShape <> #0 then
      if Event.What = evKeyDown then SetMouseShape(#0)
      else if Event.What = evMouseUp then UpdateMouseShape := True;
  end;
  if Event.What = evKeyDown then
    if Event.KeyCode = kbIns then EmulateAutoIns(Event)
    else if (NestedEventCount = 1) and
      (ScreenSaver = nil) and (Desktop^.Current <> nil) and
      (Desktop^.Current^.EventMask and emHiBit = 0) then
	Desktop^.Current^.HandleEvent(Event);
  if StatusLine <> nil then
    if (Event.What = evKeyDown) or
       ((Event.What = evMouseDown) and
	(FirstThat(@ContainsMouse) = PView(StatusLine))) then
    begin
      {if StatusLine^.HelpCtx = $FFFF then}  { Fixed 11.15.95 }
      StatusLine^.Update;
      StatusLine^.HandleEvent(Event);
    end;
end;

function TProgram.GetPalette: PPalette;
const
  P: Array[apColor..apMonochrome] of String[Length(CColor)] =
    (CColor, CBlackWhite, CMonochrome);
begin
  GetPalette := @P[AppPalette];
end;

procedure TProgram.HandleEvent(var Event: TEvent);
var
  I: Word;
  C: Char;
begin
  if Event.What = evKeyDown then
  begin
    C := GetAltChar(Event.KeyCode);
    if C in ['1'..'9'] then
      if Message(Desktop, evBroadcast, cmSelectWindowNum,
	Pointer(Byte(C) - $30)) <> nil then Event.What := evNothing;
  end;
  TGroup.HandleEvent(Event);
  if Event.What = evCommand then
    if Event.Command = cmQuit then
    begin
      EndModal(cmQuit);
      Event.What := evNothing;
    end;
end;

procedure TProgram.Idle;
begin
  GiveTicks;
  if Clock <> nil then Clock^.Update;
  if Heap <> nil then Heap^.Update;
  if StatusLine <> nil then StatusLine^.Update;
  if CommandSetChanged then
  begin
    Message(@Self, evBroadcast, cmCommandSetChanged, nil);
    CommandSetChanged := False;
  end;
end;

procedure TProgram.InitDesktop;
var
  R: TRect;
begin
  GetExtent(R);
  Inc(R.A.Y);
  Dec(R.B.Y);
  New(Desktop, Init(R));
end;

procedure TProgram.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R, nil));
end;

procedure TProgram.InitResource;
begin
end;

procedure TProgram.InitScreen;
begin
  if Lo(ScreenMode) <> smMono then
  begin
    if ScreenMode and smFont8x8 <> 0 then
      ShadowSize.X := 1 else
      ShadowSize.X := 2;
    ShadowSize.Y := 1;
    ShowMarkers := False;
    if Lo(ScreenMode) = smBW80 then
      AppPalette := apBlackWhite else
      AppPalette := apColor;
  end else
  begin
    ShadowSize.X := 0;
    ShadowSize.Y := 0;
    ShowMarkers := True;
    AppPalette := apMonochrome;
  end;
end;

procedure TProgram.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  New(StatusLine, Init(R,
{    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt+X~ Exit', kbAltX, cmQuit,
      NewStatusKey('', kbF10, cmMenu,
      NewStatusKey('', kbAltF3, cmClose,
      NewStatusKey('', kbF5, cmZoom,
      NewStatusKey('', kbCtrlF5, cmResize,
      NewStatusKey('', kbF6, cmNext, nil)))))),} nil {)} ));
end;

function TProgram.InsertWindow(P: PWindow): PWindow;
begin
  InsertWindow := nil;
  if ValidView(P) <> nil then
  begin
    Desktop^.Insert(P);
    InsertWindow := P;
  end;
end;

procedure TProgram.OutOfMemory;
begin
end;

procedure TProgram.PutEvent(var Event: TEvent);
begin
  Pending := Event;
end;

procedure TProgram.RegisterTypes;
begin
{  RegisterObjects;
  RegisterViews;
  RegisterMenus;
  RegisterDialogs;
  RegisterApp;}
end;

procedure TProgram.Run;
begin
  Execute;
end;

{
procedure TProgram.SetScreenMode(Mode: Word);
begin
  SetScreenModePrim(Mode);
end;
}

function TProgram.ValidView(P: PView): PView;
begin
  ValidView := nil;
  if P <> nil then
  begin
    if LowMemory then
    begin
      Dispose(P, Done);
      OutOfMemory;
      Exit;
    end;
    if not P^.Valid(cmValid) then
    begin
      Dispose(P, Done);
      Exit;
    end;
    ValidView := P;
  end;
end;

{ TApplication }

constructor TApplication.Init;
begin
  {DetectMouse;} { Added 02.29.96 }
  InitMemory;
  InitVideo;
  {InitEvents;}  { First idle call performs mouse initialization }
  InitSysError;
  InitHistory;
  TProgram.Init;
end;

destructor TApplication.Done;
begin
  TProgram.Done;
  DoneHistory;
  DoneSysError;
  DoneEvents;
  DoneVideo;
  DoneMemory;
end;

{ Draw status procedure }

procedure DrawStatusLine(const S: String);
begin
  if S <> '' then StatusLine^.StatusMsg := S;
  StatusLine^.DrawStatusMsg;
end;

{ Default Record key procedure }

procedure DefRecordKeyProc(Key: Word);
begin
end;

{ App registration procedure }

procedure RegisterApp;
begin
{  RegisterType(RBackground);
  RegisterType(RDesktop);}
end;

{ Is there any modal window on ? }

function NoModalWindows: Boolean;
begin
  NoModalWindows := Application^.TopView = PView(Application);
end;

{ Added 2005.12.25 }
const
  CTRL_C_EVENT           = 1;
  CTRL_CLOSE_EVENT       = 2;
  CTRL_BREAK_EVENT       = 3;
  CTRL_LOGOFF_EVENT      = 4;
  CTRL_SHUTDOWN_EVENT    = 5;

procedure GiveTicks;
var
  L: Longint;
  Regs: Registers;
begin
  if not IdleState and (TimeSliceOptions = tsIdle) then Exit;
  if TimeSliceType and ttInt28 <> 0 then
asm
	INT     28H
end;
  if TimeSliceType and ttInt2F <> 0 then
asm

	MOV	AX,1680H
	INT     2FH
end;

{ Added 2005.12.25 }
  if CN_NT then with Regs do
  begin
    ax := $170f; {}
    Intr($2f, Regs);
    L := longint(Regs.bx) shl 16 + Regs.ax;
    if (L = CTRL_CLOSE_EVENT) or (L = CTRL_LOGOFF_EVENT) or
       (L = CTRL_SHUTDOWN_EVENT) then
    begin
      Pending.What := evCommand;
      Pending.Command := cmQuit;
      Pending.InfoPtr := nil;
    end;
  end;
end;

end.
