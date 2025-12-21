{$I-,X+,O+,F+}
unit DumpWin;

interface

uses Objects, Drivers, Views;

type
  PPattern = ^TPattern;
  TPattern = Array[11..74] of Byte;

  PDumpIndicator = ^TDumpIndicator;
  TDumpIndicator = object(TView)
    Segment, Offset: Word;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
  end;

  PDumpList = ^TDumpList;
  TDumpList = object(TScroller)
    MemPtr: Pointer;
    Shift: Longint;
    Address, Ratio, RightLimit: Byte;
    Pattern: PPattern;
    Indicator: PDumpIndicator;
    Modified: Boolean;
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar; AnIndicator: PDumpIndicator);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure DrawIndicator;
    procedure FastScrollTo(Y: Integer);
    procedure SetNewParams(Bounds: TRect);
    function Hexy: Boolean;
    procedure GoRight;
    procedure GoLeft;
    procedure GoWhileKeyDown(Key: Byte);
    procedure GoDownPrim;
    procedure GoUpPrim;
    procedure GoPgDnPrim;
    procedure GoPgUpPrim;
    procedure GoDown;
    procedure GoUp;
    procedure GoPgDn;
    procedure GoPgUp;
    procedure GoCtrlPgDn;
    procedure GoCtrlPgUp;
    procedure GoEnd;
    procedure GoHome;
    procedure GoCtrlEnd;
    procedure GoCtrlHome;
    function GetLeftLimit: Byte;
    function GetRightLimit: Byte;
    function GetCurPattern: Byte;
    function GetCurPos: Word;
    function GetCursorPtr: Pointer;
    procedure GoToPos(APos: Word);
    procedure GoOpposite;
    procedure Scroll(Key: Word);
    procedure ConfirmChanges;
    procedure Modify(Initial: Char);
    procedure GoToAddressPrim(Segment, Offset: Word);
    procedure GoToAddress;
    function Search(const Match: String; AOptions: Word): Boolean;
    procedure Find;
    procedure DumpData(const FName: String; From, Count: Word);
    procedure ReadData(const FName: String; From, Count: Word);
    procedure WriteTo;
    procedure ReadFrom;
    procedure Follow(ACommand: Word);
    procedure PopUp(AnOrigin: TPoint);
  end;

  PDumpWindow = ^TDumpWindow;
  TDumpWindow = object(TWindow)
    DumpList: PDumpList;
    constructor Init;
    constructor Load(var S: TStream);
    function GetPalette: PPalette; virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
  end;

procedure RSRDumpWindow(RSR: PResourceFile);
procedure DumpWindow;

type
  TDumpSearchData = record
    MatchStr: String[255];
    Options: Word;
  end;

const
  MemData: TDumpSearchData = (MatchStr: ''; Options: 0);

  CMemList = #13;

  LeftLimit = 11;
  RightLimit4 = 26;
  RightLimit8 = 42;
  RightLimit16 = 74;
  Pattern4: TPattern =
    ($80, 0, $7F, $81, 1, $7F, $82, 2, $7F, $83, 3, $7F,
     0, 1, 2, 3,
     $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F,
     $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F,
     $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F,
     $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F);
  Pattern8: TPattern =
    ($80, 0, $7F, $81, 1, $7F, $82, 2, $7F, $83, 3, $7F,
     $84, 4, $7F, $85, 5, $7F, $86, 6, $7F, $87, 7, $7F,
     0, 1, 2, 3, 4, 5, 6, 7,
     $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F,
     $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F,
     $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F);
  Pattern16: TPattern =
    ($80, 0, $7F, $81, 1, $7F, $82, 2, $7F, $83, 3, $7F,
     $84, 4, $7F, $85, 5, $7F, $86, 6, $7F, $87, 7, $7F,
     $88, 8, $7F, $89, 9, $7F, $8A, $A, $7F, $8B, $B, $7F,
     $8C, $C, $7F, $8D, $D, $7F, $8E, $E, $7F, $8F, $F, $7F,
     0, 1, 2, 3, 4, 5, 6, 7, 8, 9, $A, $B, $C, $D, $E, $F);

implementation

uses CNCrt, Dos, Menus, Dialogs, App, MsgBox, StdDlg, PopUps,
  DirPrim, DosTools, Keyboard, Disasm, AddrDlg, FindDlg, EditFile,
  EditMsg, WinPos, CNWinPos, LFN, TPString, Consts, Commands, Defaults;

procedure TDumpIndicator.Draw;
type
  TParams = record
    Segment, Offset: Longint;
  end;
var
  C: Byte;
  Params: TParams;
  B: TDrawBuffer;
  S: String;
begin
  if State and sfActive = 0 then C := GetColor(1)
  else if State and sfDragging <> 0 then C := GetColor(3)
  else C := GetColor(2);
  Params.Segment := Segment;
  Params.Offset := Offset;
  FormatStr(S, ' %04x:%04x ', Params);
  MoveStr(B, S, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TDumpIndicator.GetPalette: PPalette;
const
  P: String[3] = #1#2#3;
begin
  GetPalette := @P;
end;

procedure TDumpIndicator.SetState(AState: Word; Enable: Boolean);
begin
  TView.SetState(AState, Enable);
  DrawView;
end;

constructor TDumpList.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar; AnIndicator: PDumpIndicator);
begin
  TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
  Indicator := AnIndicator;
  GrowMode := gfGrowHiX + gfGrowHiY;
  Limit.X := 28;
  ShowCursor;
  SetCursor(GetLeftLimit, 0);
end;

constructor TDumpList.Load(var S: TStream);
begin
  TScroller.Load(S);
  GetPeerViewPtr(S, Indicator);
  S.Read(MemPtr, SizeOf(Pointer));
  S.Read(Shift, SizeOf(Longint));
  S.Read(Address, SizeOf(Byte));
end;

function TDumpList.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else if GetShiftState and kbCtrlShift <> 0 then
    GetHelpCtx := hcMemList
  else GetHelpCtx := hcMem;
end;

function TDumpList.GetPalette: PPalette;
const
  P: String[Length(CMemList)] = CMemList;
begin
  GetPalette := @P;
end;

procedure TDumpList.Draw;
var
  C, Y: Byte;
  W: Word;
  Index: Longint;
  B: TDrawBuffer;
  S, SegS: String;
begin
  C := GetColor(1);
  for Y := 0 to Size.Y - 1 do
  begin
    MoveChar(B, ' ', C, Size.X);
    Index := Delta.Y + Y - Shift;
    if Index < 0 then Index := Index + Limit.Y
    else if Index > Limit.Y then Index := Index - Limit.Y;
    PtrRec(MemPtr).Ofs := Word(Ratio * Index + Address);
    StringConvert(MemPtr^, S, Ratio);
    W := PtrRec(MemPtr).Seg;
    SegS := HexW(W);
    S := SegS + ':' + S;
    MoveStr(B[1], System.Copy(S, Succ(Delta.X), Size.X - 2), C);
    WriteLine(0, Y, Size.X, 1, B);
  end;
end;

procedure TDumpList.HandleEvent(var Event: TEvent);
var
  Spot: TPoint;
begin
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbTab: Event.CharCode := ^O;
      kbEsc:
	begin
	  Pending.What := evCommand;
	  Pending.Command := cmClose;
	  Pending.InfoPtr := Owner;
	  Event.What := evNothing;
	end;
    end;
  TScroller.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmGoTo: GoToAddress;
      cmGoOpposite: GoOpposite;
      cmFind: Find;
      cmSearchAgain: Search(MemData.MatchStr,
	MemData.Options or frFromCursor);
      cmNearCode, cmFarCode, cmOffsetToData, cmSegmentToData, cmBaseToData:
	Follow(Event.Command);
      cmWriteTo: WriteTo;
      cmReadFrom: ReadFrom;
      cmPopUp:
	begin
	  Spot.X := Size.X div 2;
	  Spot.Y := 0;
	  MakeGlobal(Spot, Spot);
	  PopUp(Spot);
	end;
      else Exit;
    end;
    Event.What := evNothing;
  end
  else if Event.What = evKeyDown then
  begin
    if (Cursor.X < 0) or (Cursor.X >= Size.X) or
       (Cursor.Y < 0) or (Cursor.Y >= Size.Y) then
      ScrollTo(Delta.X + Cursor.X, Delta.Y + Cursor.Y);
    case Event.CharCode of
      ^G: GoToAddress;
      ^F: Find;
      ^O: GoOpposite;
      ^S: Search(MemData.MatchStr, MemData.Options or frFromCursor);
      ^W: WriteTo;
      ^R: ReadFrom;
      ^I: Exit;
       else if Event.CharCode >= #32 then Modify(Event.CharCode)
       else Scroll(CtrlToArrow(Event.KeyCode));
    end;
    Event.What := evNothing;
  end
  else if Event.What = evMouseDown then
  begin
    if MouseInView(Event.Where) and (Event.Buttons = mbRightButton) then
    begin
      repeat until not MouseEvent(Event, evMouseDown);
      PopUp(Event.Where);
      Event.What := evNothing;
    end
    else
    repeat
      if MouseInView(Event.Where) then
      begin
	MakeLocal(Event.Where, Spot);
	if Delta.X + Spot.X < GetLeftLimit then
	  Spot.X := GetLeftLimit - Delta.X
	else if Delta.X + Spot.X > GetRightLimit then
	  Spot.X := GetRightLimit - Delta.X;
	if Spot.X = 0 then Spot.X := 1
	else if Spot.X = Size.X - 1 then Spot.X := Size.X - 2;
	SetCursor(Spot.X, Spot.Y);
	if (Cursor.X < Size.X - 2) and
	   (Delta.X + Cursor.X < GetRightLimit) and
	   (GetCurPattern = $7F) then SetCursor(Cursor.X + 1, Cursor.Y);
	DrawIndicator;
      end
      else
      begin
	Spot.X := 0;
	Spot.Y := 0;
	MakeGlobal(Spot, Spot);
	if Event.Where.X < Spot.X then GoLeft;
	if Event.Where.X > Spot.X + Size.X - 1 then GoRight;
	if Event.Where.Y < Spot.Y then GoUp;
	if Event.Where.Y > Spot.Y + Size.Y - 1 then GoDown;
      end;
    until not MouseEvent(Event, evMouseMove + evMouseAuto);
  end
  else if (Event.What = evBroadcast) and
    (Event.Command = cmUpdateViews) then DrawView;
end;

procedure TDumpList.ChangeBounds(var Bounds: TRect);
begin
  SetNewParams(Bounds);
  TScroller.ChangeBounds(Bounds);
end;

procedure TDumpList.SetState(AState: Word; Enable: Boolean);
var
  R: TRect;
begin
  TScroller.SetState(AState, Enable);
  if (AState = sfExposed) and Enable then
  begin
    GetBounds(R);
    SetNewParams(R);
  end;
  if (AState = sfFocused) and Enable then
  begin
    DrawView;
    Indicator^.Show;
    DrawIndicator;
    EnableCommands(FindCommands);
  end
  else if ((AState = sfExposed) and not Enable) or
    ((AState and (sfActive + sfSelected) <> 0) and
    not Enable and GetState(sfExposed)) then
      DisableCommands(FindCommands);
  if (AState = sfSelected) and not Enable then Indicator^.Hide;
end;

procedure TDumpList.SetNewParams(Bounds: TRect);
var
  SaveRatio: Byte;
  SaveHexy: Boolean;
  SavePos: Word;
begin
  SaveRatio := Ratio;
  SavePos := GetCurPos;
  SaveHexy := Hexy;
  if Bounds.B.X - Bounds.A.X > 64 + GetLeftLimit then
  begin
    Ratio := 16;
    RightLimit := RightLimit16;
    Pattern := @Pattern16;
    SetLimit(Limit.X, MaxInt div 8 + 1);
  end
  else
  if Bounds.B.X - Bounds.A.X > 32 + GetLeftLimit then
  begin
    Ratio := 8;
    RightLimit := RightLimit8;
    Pattern := @Pattern8;
    SetLimit(Limit.X, MaxInt div 4 + 1);
  end
  else
  begin
    Ratio := 4;
    RightLimit := RightLimit4;
    Pattern := @Pattern4;
    SetLimit(Limit.X, MaxInt div 2 + 1);
  end;
  if (State and sfExposed <> 0) and (SaveRatio <> 0) then
  begin
    if SavePos <> GetCurPos then GoToPos(SavePos);
    if SaveHexy <> Hexy then GoOpposite;
    if Delta.X + Cursor.X > GetRightLimit then GoLeft;
  end;
end;

procedure TDumpList.Store(var S: TStream);
begin
  TScroller.Store(S);
  PutPeerViewPtr(S, Indicator);
  S.Write(MemPtr, SizeOf(Pointer));
  S.Write(Shift, SizeOf(Longint));
  S.Write(Address, SizeOf(Byte));
end;

procedure TDumpList.DrawIndicator;
begin
  if Indicator = nil then Exit;
  Indicator^.Segment := PtrRec(MemPtr).Seg;
  Indicator^.Offset := GetCurPos;
  Indicator^.DrawView;
end;

procedure TDumpList.FastScrollTo(Y: Integer);
var
  OldValue: Integer;
begin
  with VScrollBar^ do
  begin
    OldValue := Value;
    if Y < Min then Value := Min
      else if Y > Max then Value := Max
	else Value := Y;
    if Value <> OldValue then DrawView;
    Delta.Y := Value;
  end;
  DrawView;
  DrawIndicator;
end;

function TDumpList.Hexy: Boolean;
begin
  Hexy := Delta.X + Cursor.X < GetRightLimit - Ratio + 1;
end;

procedure TDumpList.GoRight;
begin
  if Delta.X + Cursor.X = GetRightLimit then
  begin
    GoDown;
    SetCursor(Cursor.X - Ratio + 1, Cursor.Y);
  end
  else
  repeat
    SetCursor(Cursor.X + 1, Cursor.Y);
    if Cursor.X >= Size.X - 1 then ScrollTo(Delta.X + 1, Delta.Y);
  until GetCurPattern <> $7F;
  DrawIndicator;
end;

procedure TDumpList.GoLeft;
begin
  if Delta.X + Cursor.X = GetLeftLimit then
  begin
    GoUp;
    GoEnd;
  end
  else
  repeat
    SetCursor(Cursor.X - 1, Cursor.Y);
    if Cursor.X < 1 then ScrollTo(Delta.X - 1, Delta.Y);
  until GetCurPattern <> $7F;
  DrawIndicator;
end;

procedure TDumpList.GoDownPrim;
begin
  if Delta.Y + Cursor.Y > Limit.Y - 2 then
  begin
    Dec(Shift);
    DrawView;
  end
  else FastScrollTo(Succ(Delta.Y));
end;

procedure TDumpList.GoUpPrim;
begin
  if Delta.Y + Cursor.Y = 0 then
  begin
    Inc(Shift);
    DrawView;
  end
  else FastScrollTo(Pred(Delta.Y));
end;

procedure TDumpList.GoPgDnPrim;
begin
  if Delta.Y + Size.Y > Limit.Y - 1 then
  begin
    Dec(Shift, Size.Y);
    DrawView;
  end
  else FastScrollTo(Delta.Y + Size.Y);
end;

procedure TDumpList.GoPgUpPrim;
begin
  if Delta.Y < Size.Y then
  begin
    Inc(Shift, Size.Y);
    DrawView;
  end
  else FastScrollTo(Delta.Y - Size.Y);
end;

procedure TDumpList.GoWhileKeyDown(Key: Byte);
begin
  repeat
    if (KbdStatus <> Key) and (KbdStatus <> 224) then Exit;
  until KeyPressed;
  repeat
    ClearKbd;
    if (KbdStatus <> Key) and (KbdStatus <> 224) then Exit;
    case Key of
      72: GoUpPrim;
      73: GoPgUpPrim;
      80: GoDownPrim;
      81: GoPgDnPrim;
    end;
    DrawIndicator;
    if KbdDelay <> 0 then Delay(KbdDelay);
  until False;
end;

procedure TDumpList.GoDown;
begin
  if Cursor.Y <> Size.Y - 1 then
  begin
    SetCursor(Cursor.X, Succ(Cursor.Y));
    DrawIndicator;
  end
  else
  begin
    GoDownPrim;
    DrawIndicator;
    if (KbdStatus = 80) or (KbdStatus = 224) then GoWhileKeyDown(80);
  end;
end;

procedure TDumpList.GoUp;
begin
  if Cursor.Y > 0 then
  begin
    SetCursor(Cursor.X, Pred(Cursor.Y));
    DrawIndicator;
  end
  else
  begin
    GoUpPrim;
    DrawIndicator;
    if (KbdStatus = 72) or (KbdStatus = 224) then GoWhileKeyDown(72);
  end;
end;

procedure TDumpList.GoPgDn;
begin
  GoPgDnPrim;
  DrawIndicator;
  if (KbdStatus = 81) or (KbdStatus = 224) then GoWhileKeyDown(81);
end;

procedure TDumpList.GoPgUp;
begin
  GoPgUpPrim;
  DrawIndicator;
  if (KbdStatus = 73) or (KbdStatus = 224) then GoWhileKeyDown(73);
end;

procedure TDumpList.GoCtrlPgDn;
begin
  if Hexy then
  begin
    ScrollTo(0, Limit.Y);
    SetCursor(GetLeftLimit, Size.Y - 1);
  end
  else
  begin
    ScrollTo(Limit.X, Limit.Y);
    SetCursor(GetRightLimit - Ratio + 1 - Delta.X, Size.Y - 1);
  end;
  DrawIndicator;
end;

procedure TDumpList.GoCtrlPgUp;
begin
  if Hexy then
  begin
    ScrollTo(0, 0);
    SetCursor(GetLeftLimit, 0);
  end
  else
  begin
    ScrollTo(Limit.X, 0);
    SetCursor(GetRightLimit - Ratio + 1 - Delta.X, 0);
  end;
  DrawIndicator;
end;

procedure TDumpList.GoEnd;
begin
  ScrollTo(Limit.Y, Delta.Y);
  if Hexy then SetCursor(GetRightLimit - Ratio - 2 - Delta.X, Cursor.Y)
  else SetCursor(GetRightLimit - Delta.X, Cursor.Y);
  DrawIndicator;
end;

procedure TDumpList.GoHome;
begin
  if Hexy then
  begin
    ScrollTo(0, Delta.Y);
    SetCursor(GetLeftLimit - Delta.X, Cursor.Y);
  end
  else
  begin
    ScrollTo(Limit.Y, Delta.Y);
    SetCursor(GetRightLimit - Ratio + 1 - Delta.X, Cursor.Y);
  end;
  DrawIndicator;
end;

procedure TDumpList.GoCtrlEnd;
begin
  SetCursor(Cursor.X, Size.Y - 1);
  DrawIndicator;
end;

procedure TDumpList.GoCtrlHome;
begin
  SetCursor(Cursor.X, 0);
  DrawIndicator;
end;

function TDumpList.GetLeftLimit: Byte;
begin
  GetLeftLimit := LeftLimit;
end;

function TDumpList.GetRightLimit: Byte;
begin
  GetRightLimit := RightLimit;
end;

function TDumpList.GetCurPattern: Byte;
begin
  GetCurPattern := Pattern^[Delta.X + Cursor.X];
end;

function TDumpList.GetCurPos: Word;
var
  Index: Longint;
begin
  Index := Delta.Y + Cursor.Y - Shift;
  if Index < 0 then Index := Index + Limit.Y
  else if Index > Limit.Y then Index := Index - Limit.Y;
  GetCurPos := Word(Ratio * Index + GetCurPattern and $7F + Address);
end;

function TDumpList.GetCursorPtr: Pointer;
begin
  GetCursorPtr := Pointer(Ptr(PtrRec(MemPtr).Seg, GetCurPos)^);
end;

procedure TDumpList.GoToPos(APos: Word);
var
  SaveHexy: Boolean;
  TopByte, X, Y, SX, SY: Integer;
  Index: Longint;
begin
  SaveHexy := Hexy;
  Index := Delta.Y - Shift;
  if Index < 0 then Index := Index + Limit.Y
  else if Index > Limit.Y then Index := Index - Limit.Y;
  TopByte := Integer(Index * Ratio + Address);
  if SaveHexy then X := GetLeftLimit + ((APos - Address) mod Ratio) * 3
  else X := GetRightLimit - Ratio + 1 + ((APos - Address) mod Ratio);
  if X <= Delta.X then SX := 0
  else if X >= Size.X - 1 then SX := Limit.X
  else SX := Delta.X;
  if (Integer(APos) < TopByte) or
     (Integer(APos) >= TopByte + Integer(Size.Y * Ratio)) then
  begin
    Y := (APos - Address) div Ratio;
    SY := Y;
    Shift := 0;
  end
  else
  begin
    Y := Delta.Y + (Integer(APos) - TopByte) div Ratio;
    SY := Delta.Y;
  end;
  ScrollTo(SX, SY);
  SetCursor(X - Delta.X, Y - Delta.Y);
  DrawView;
  DrawIndicator;
end;

procedure TDumpList.GoOpposite;
var
  SavePos: Word;
begin
  SavePos := GetCurPos;
  if Hexy then SetCursor(GetRightLimit - Delta.X, Cursor.Y)
  else SetCursor(GetLeftLimit - Delta.X, Cursor.Y);
  GoToPos(SavePos);
end;

procedure TDumpList.Scroll(Key: Word);
begin
  case Key of
    kbDown:     GoDown;
    kbUp:       GoUp;
    kbRight:    GoRight;
    kbLeft:     GoLeft;
    kbPgDn:     GoPgDn;
    kbPgUp:     GoPgUp;
    kbCtrlPgDn: GoCtrlPgDn;
    kbCtrlPgUp: GoCtrlPgUp;
    kbHome:     GoHome;
    kbEnd:      GoEnd;
    kbCtrlHome: GoCtrlHome;
    kbCtrlEnd:  GoCtrlEnd;
  end;
end;

procedure TDumpList.ConfirmChanges;
begin
  Modified := (ConfirmOptions and coModifyMemory = 0) or
    (MessageBox(^C'Changes in memory may crash your'#13^C +
      'system or cause run-time'#13^C'application errors. Continue ?',
      nil, mfWarning + mfOkCancel) = cmOk);
end;

procedure TDumpList.Modify(Initial: Char);
var
  W: Word;
  HS: String;
begin
  if not Modified then
  begin
    ConfirmChanges;
    if not Modified then Exit;
  end;
  PtrRec(MemPtr).Ofs := GetCurPos;
  if Hexy then
  begin
    if not (Initial in ['0'..'9', 'A'..'F', 'a'..'f']) then
    begin
      if not DisableSounds then Write(^G);
      Exit;
    end
    else
    begin
      HS := HexB(Byte(MemPtr^));
      if GetCurPattern > $F then Str2Word('$' + Initial + HS[2], W)
      else Str2Word('$' + HS[1] + Initial, W);
      Byte(MemPtr^) := Byte(W);
    end;
  end
  else Byte(MemPtr^) := Ord(Initial);
  if Hexy and (GetCurPattern = Ratio - 1) then
  begin
    GoDown;
    GoHome;
  end
  else GoRight;
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure TDumpList.GoToAddressPrim(Segment, Offset: Word);
begin
  PtrRec(MemPtr).Seg := Segment;
  Shift := 0;
  Address := Offset mod Ratio;
  GoToPos(Offset);
end;

procedure TDumpList.GoToAddress;
var
  Segment, Offset: Word;
begin
  if not GetAddress(Segment, Offset, True, MemPtr,
    'Go to address', '~N~ew address', hcGoToAddress) then Exit;
  GoToAddressPrim(Segment, Offset);
end;

function TDumpList.Search(const Match: String;
  AOptions: Word): Boolean;
const
  BufLen = $8000;
  UpperLim = $FFFFF;
  SegDelta = $700;
var
  Hex: Boolean;
  BytesToSearch, BytesSearched: Word;
  L: Longint;
  BufPtr: Pointer;
  BT: BTable;
  SS: String;

procedure AdjustPointer;
var
  LO: Longint;
begin
  LO := LongInt(PtrRec(BufPtr).Seg) shl 4 + PtrRec(BufPtr).Ofs +
    BytesSearched - LongInt(PtrRec(MemPtr).Seg) shl 4;
  if (LO >= 0) and (LO < $FFFF) then
  begin
    PtrRec(BufPtr).Seg := PtrRec(MemPtr).Seg;
    PtrRec(BufPtr).Ofs := 0;
    BytesSearched := LO;
  end;
end;

label
  NotFound;
begin
  Search := False;
  if Match = '' then Exit;
  DrawStatusLine('Searching for text in memory. Esc aborts.');
  SS := Match;
  if AOptions and frCaseSensitive = 0 then UpcaseSt(SS);
  if SS[1] = '$' then SS := Hex2Match(SS, Hex);
  BMMakeTable(SS, BT);
  if AOptions and frFromCursor <> 0 then
  begin
    L := LongInt(PtrRec(MemPtr).Seg) shl 4 + GetCurPos + 1;
    if L >= UpperLim then Goto NotFound;
    BufPtr := Ptr(Word(L shr 4), Word(L and $F));
  end
  else BufPtr := nil;
  repeat
    if EscPressed then Break;
    L := LongInt(PtrRec(BufPtr).Seg) shl 4 + PtrRec(BufPtr).Ofs;
    if L + BufLen > UpperLim then BytesToSearch := UpperLim - L
    else BytesToSearch := BufLen;
    if (AOptions and frCaseSensitive <> 0) or ((Match[1] = '$') and Hex) then
      BytesSearched := BMSearch(BufPtr^, BytesToSearch, BT, SS)
    else BytesSearched := BMSearchUC(BufPtr^, BytesToSearch, BT, SS);
    if BytesSearched <> $FFFF then
    begin
      AdjustPointer;
      if PtrRec(BufPtr).Seg = PtrRec(MemPtr).Seg then
	GoToPos(PtrRec(BufPtr).Ofs + BytesSearched)
      else GoToAddressPrim(
	PtrRec(BufPtr).Seg, PtrRec(BufPtr).Ofs + BytesSearched);
      Search := True;
      Exit;
    end;
    if BytesToSearch <> BufLen then Break;
    Inc(PtrRec(BufPtr).Seg, SegDelta);
  until False;
NotFound:
  SearchStringNotFoundMsgBox;
end;

procedure TDumpList.Find;
begin
  if Application^.ExecuteDialog(LoadFindDialog(False, True,
    frRegExp + frSelectedText + frBackward),
      @MemData, False) <> cmCancel then
	Search(MemData.MatchStr, MemData.Options);
end;

procedure TDumpList.DumpData(const FName: String; From, Count: Word);
var
  Append: Boolean;
  C: Word;
  F: lFile;
begin
  Append := False;
  if ThisFileExists(FName) then
  begin
    C := AppendMessageBox(FName);
    case C of
      cmYes: Append := True;
      cmCancel: Exit;
    end;
  end;
  lAssignFile(F, FName);
  if Append then
  begin
    lResetFile(F, 1);
    if IOResult <> 0 then lRewriteFile(F, 1)
    else Seek(F.F, FileSize(F.F));
  end
  else lRewriteFile(F, 1);
  if IOResult <> 0 then
  begin
    CouldNotOpenMsgBox(FName);
    Exit;
  end;
  if NotAccessible(FileRec(F.F).Handle) then
  begin
    Close(F.F);
    InOutRes := 0;
    FileIsDeviceMsgBox(FName);
    Exit;
  end;
  PtrRec(MemPtr).Ofs := From;
  DrawWriteDataStatus(FName);
  if Count < $FFFF then BlockWrite(F.F, MemPtr^, Count + 1)
  else
  begin
    BlockWrite(F.F, MemPtr^, Count);
    PtrRec(MemPtr).Ofs := $FFFF;
    BlockWrite(F.F, MemPtr^, 1);
  end;
  Close(F.F);
  InOutRes := 0;
  UpdateFiles(FName);
end;

procedure TDumpList.ReadData(const FName: String; From, Count: Word);
var
  F: lFile;
begin
  if not Modified then
  begin
    ConfirmChanges;
    if not Modified then Exit;
  end;
  lAssignFile(F, FName);
  lResetReadOnly(F, 1);
  if IOResult <> 0 then
  begin
    CouldNotOpenMsgBox(FName);
    Exit;
  end;
  if IsDevice(FileRec(F.F).Handle) then
  begin
    Close(F.F);
    InOutRes := 0;
    FileIsDeviceMsgBox(FName);
    Exit;
  end;
  PtrRec(MemPtr).Ofs := From;
  DrawReadDataStatus(FName);
  BlockRead(F.F, MemPtr^, Count);
  Close(F.F);
  InOutRes := 0;
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure TDumpList.WriteTo;
var
  Segment, Offset: Word;
  FName: FNameStr;
begin
  if not GetAddress(Segment, Offset, False, nil,
    'Write block to file', '~E~nter range', hcWriteTo) then Exit;
  FName := '';
  if Application^.ExecuteDialog(
    New(PFileDialog, Init('*.*', 'Write block to file',
    '~W~rite block to', fdOkButton + fdHelpButton, 100)),
    @FName, False) = cmCancel then Exit;
  if Segment > Offset then Segment := 0;
  DumpData(FName, Segment, Offset - Segment);
end;

procedure TDumpList.ReadFrom;
var
  APos: Word;
  FName: FNameStr;
begin
  FName := '';
  if Application^.ExecuteDialog(
    New(PFileDialog, Init('*.*', 'Read block from file',
    '~R~ead block from', fdOkButton + fdHelpButton, 100)),
    @FName, False) = cmCancel then Exit;
  APos := GetCurPos;
  ReadData(FName, APos, $FFFF - APos);
end;

procedure TDumpList.Follow(ACommand: Word);
var
  P: Pointer;
begin
  P := GetCursorPtr;
  case ACommand of
    cmNearCode, cmFarCode:
      Message(Desktop, evBroadcast, ACommand, P);
    cmOffsetToData, cmSegmentToData:
      begin
	if ACommand = cmSegmentToData then
	  PtrRec(MemPtr).Seg := PtrRec(P).Seg;
	Shift := 0;
	Address := PtrRec(P).Ofs mod Ratio;
	ScrollTo(0, PtrRec(P).Ofs div Ratio);
	SetCursor(GetLeftLimit, 0);
	DrawView;
	DrawIndicator;
      end;
    cmBaseToData:
      begin
	PtrRec(MemPtr).Seg := PtrRec(P).Ofs;
	Shift := 0;
	Address := 0;
	ScrollTo(0, 0);
	SetCursor(GetLeftLimit, 0);
	DrawView;
	DrawIndicator;
      end;
  end;
end;

procedure TDumpList.PopUp(AnOrigin: TPoint);
begin
  ShowPopup(AnOrigin, NewMenu(
    NewItem('~G~o to...', '', kbNoKey, cmGoTo, hcGoToAddress,
    NewItem('~O~pposite', '', kbNoKey, cmGoOpposite, hcGoOpposite,
    NewItem('~F~ind...', '', kbNoKey, cmFind, hcSHFind,
    NewItem('~S~earch again', '', kbNoKey, cmSearchAgain, hcSHSearchAgain,
    NewSubMenu('Fo~l~low', hcFollow, NewMenu(
      NewItem('~N~ear code', '', kbNoKey, cmNearCode, hcNearCode,
      NewItem('~F~ar code', '', kbNoKey, cmFarCode, hcFarCode,
      NewLine(
      NewItem('~O~ffset to data', '', kbNoKey, cmOffsetToData, hcOffsetToData,
      NewItem('~S~egment:offset to data', '', kbNoKey, cmSegmentToData, hcSegmentToData,
      NewItem('~B~ase segment:0 to data', '', kbNoKey, cmBaseToData, hcBaseToData,
	nil))))))),
    NewLine(
    NewItem('~W~rite to...', '', kbNoKey, cmWriteTo, hcWriteTo,
    NewItem('~R~ead from...', '', kbNoKey, cmReadFrom, hcReadFrom,
      nil))))))))));
end;

constructor TDumpWindow.Init;
var
  HControl, IControl: PView;
  R: TRect;
begin
  Desktop^.GetExtent(R); R.A.Y := R.B.Y - 8;
  TWindow.Init(R, 'Dump', wnNoNumber);
  R.Assign(12, Size.Y - 1, Size.X - 2, Size.Y);
  HControl := New(PScrollBar, Init(R));
  Insert(HControl);
  R.Assign(1, Size.Y - 1, 12, Size.Y);
  IControl := New(PDumpIndicator, Init(R));
  IControl^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(IControl);
  IControl^.Hide;
  GetExtent(R);
  R.Grow(-1, -1);
  DumpList := New(PDumpList, Init(R,
    PScrollBar(HControl),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    PDumpIndicator(IControl)));
  Insert(DumpList);
  WinPos := @DumpWinPos;
end;

constructor TDumpWindow.Load(var S: TStream);
begin
  TWindow.Load(S);
  GetSubViewPtr(S, DumpList);
  WinPos := @DumpWinPos;
end;

function TDumpWindow.GetPalette: PPalette;
const
  CCPUWindow = #113#114#115#116#117#118#119#120#121#122#123#124#125#126#127;
  P: String[Length(CCPUWindow)] = CCPUWindow;
begin
  GetPalette := @P;
end;

procedure TDumpWindow.SizeLimits(var Min, Max: TPoint);
begin
  TWindow.SizeLimits(Min, Max);
  Min.X := 19;
end;

procedure TDumpWindow.Store(var S: TStream);
begin
  DumpList^.Indicator^.State :=
    DumpList^.Indicator^.State and not sfVisible;
  TWindow.Store(S);
  PutSubViewPtr(S, DumpList);
end;

procedure RSRDumpWindow(RSR: PResourceFile);
var
  W: PDumpWindow;
begin
  W := New(PDumpWindow, Init);
  RSR^.Put(W, 'DUMPWINDOW');
  Dispose(W, Done);
end;

procedure DumpWindow;
var
  W: PDumpWindow;
  R: TRect;
begin
  W := PDumpWindow(Resource^.Get('DUMPWINDOW'));
  if W <> nil then
  begin
    if (WinPosMask and wpDump <> 0) and ValidWinPos(DumpWinPos) then
      SetWinPos(Desktop, DumpWinPos, R)
    else
    begin
      Desktop^.GetExtent(R);
      R.A.Y := R.B.Y - 8;
    end;
    W^.Locate(R);
    Application^.InsertWindow(W);
  end
  else ResourceNotFoundMsgBox('Dump window');
end;

end.