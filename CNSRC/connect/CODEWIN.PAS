{$I-,X+,O+,F+}
unit CodeWin;

interface

uses Objects, Drivers, Views;

type
  PSourceCollection = ^TSourceCollection;
  TSourceCollection = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PCodeList = ^TCodeList;
  TCodeList = object(TScroller)
    Focused: Integer;
    Source, SourceOrigin: Pointer;
    SourceCollection: PSourceCollection;
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure FastScrollTo(Y: Integer);
    function DisasmBreak(var Address: Pointer): String; virtual;
    procedure InsertAddress;
    procedure StartFrom(Address: Pointer);
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
    function GetFocused: Pointer;
    function IsWithin(AnIndex: Integer): Boolean;
    procedure FocusItem(Item: Pointer);
    procedure GoToAddress;
    procedure GoToOrigin;
    function Search(const Match: String; AOptions: Word): Boolean;
    procedure Find;
    procedure PopUp(AnOrigin: TPoint); virtual;
  end;

  PCodeWindow = ^TCodeWindow;
  TCodeWindow = object(TWindow)
    CodeList: PCodeList;
    constructor Init;
    constructor Load(var S: TStream);
    function GetPalette: PPalette; virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
  end;

const
  MaxSource = 256;
  CSourceList = #6#7#8;

procedure RSRCodeWindow(RSR: PResourceFile);
procedure CodeWindow;

type
  TCodeSearchData = record
    MatchStr: String[255];
    Options: Word;
  end;

const
  CodeData: TCodeSearchData = (MatchStr: ''; Options: 0);

implementation

uses CNCrt, Dos, Menus, Dialogs, App, MsgBox, EditMsg, Popups, DosTools,
  Keyboard, AddrDlg, FindDlg, Disasm, WinPos, CNWinPos, TPString, Consts,
  Commands;

procedure TSourceCollection.FreeItem(Item: Pointer);
begin
end;

constructor TCodeList.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar);
var
  I: Integer;
begin
  TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
  GrowMode := gfGrowHiX + gfGrowHiY;
  HScrollBar^.Options := HScrollBar^.Options or ofPostProcess;
  VScrollBar^.Options := VScrollBar^.Options or ofPostProcess;
  SourceCollection := New(PSourceCollection, Init(MaxSource, 1));
  Limit.X := ScreenWidth;
  Limit.Y := MaxSource;
end;

constructor TCodeList.Load(var S: TStream);
begin
  CPU_Test;
  TScroller.Load(S);
  S.Read(Source, SizeOf(Pointer));
  SourceCollection := New(PSourceCollection, Init(MaxSource, 1));
end;

destructor TCodeList.Done;
begin
  if SourceCollection <> nil then Dispose(SourceCollection, Done);
  TScroller.Done;
end;

function TCodeList.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else if GetShiftState and kbCtrlShift <> 0 then
    GetHelpCtx := hcSourceList
  else GetHelpCtx := hcSource;
end;

function TCodeList.GetPalette: PPalette;
const
  P: String[Length(CSourceList)] = CSourceList;
begin
  GetPalette := @P;
end;

procedure TCodeList.Draw;
var
  Ch: Char;
  C, Y, APos: Byte;
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
    else C := GetColor(1);
    S := DisasmCom(P, False);
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
end;

procedure TCodeList.HandleEvent(var Event: TEvent);
var
  Spot: TPoint;
begin
  if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmClose;
    Pending.InfoPtr := Owner;
    Event.What := evNothing;
  end;
  TScroller.HandleEvent(Event);
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmGoTo: GoToAddress;
      cmOrigin: GoToOrigin;
      cmFind: Find;
      cmSearchAgain: Search(CodeData.MatchStr,
	CodeData.Options or frFromCursor);
      cmPopUp:
	begin
	  Spot.X := Size.X;
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
    if not IsWithin(Focused) then ScrollTo(Delta.X, Focused);
    case Event.CharCode of
      ^G: GoToAddress;
      ^O: GoToOrigin;
      ^F: Find;
      ^S: Search(CodeData.MatchStr, CodeData.Options or frFromCursor);
      else case CtrlToArrow(Event.KeyCode) of
	kbDown:      GoDown;
	kbUp:        GoUp;
	kbPgDn:      GoPgDn;
	kbPgUp:      GoPgUp;
	kbCtrlPgDn:  GoCtrlPgDn;
	kbCtrlPgUp:  GoCtrlPgUp;
	kbHome:      GoHome;
	kbEnd:       GoEnd;
	else Exit;
      end;
    end;
    Event.What := evNothing;
  end
  else if Event.What = evBroadcast then
  begin
    case Event.Command of
      cmNearCode: FocusItem(
	Ptr(PtrRec(Source).Seg, PtrRec(Event.InfoPtr).Ofs));
      cmFarCode: FocusItem(Event.InfoPtr);
      cmUpdateViews:
	begin
	  DrawView;
	  Exit;
	end;
      else Exit;
    end;
    ClearEvent(Event);
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
	Focused := Delta.Y + Spot.Y;
	DrawView;
      end
      else
      begin
	Spot.X := 0;
	Spot.Y := 0;
	MakeGlobal(Spot, Spot);
	if Event.Where.Y < Spot.Y then GoUp;
	if Event.Where.Y > Spot.Y + Size.Y - 1 then GoDown;
      end;
    until not MouseEvent(Event, evMouseMove + evMouseAuto);
  end;
end;

procedure TCodeList.SetState(AState: Word; Enable: Boolean);
begin
  TScroller.SetState(AState, Enable);
  if (AState = sfExposed) and Enable then
    SetLimit(Limit.X, Limit.Y);
  if (AState = sfFocused) and Enable then DrawView;
  if AState and sfActive <> 0 then
    if GetState(sfActive) then EnableCommands(FindCommands)
    else DisableCommands(FindCommands);
end;

procedure TCodeList.Store(var S: TStream);
var
  P: Pointer;
begin
  TScroller.Store(S);
  P := GetFocused;
  S.Write(P, SizeOf(Pointer));
end;

procedure TCodeList.FastScrollTo(Y: Integer);
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
end;

function TCodeList.DisasmBreak(var Address: Pointer): String;
begin
  DisasmBreak := DisasmCom(Address, False);
end;

procedure TCodeList.InsertAddress;
begin
  with SourceCollection^ do
  begin
    if Count = MaxSource then AtFree(0);
    Insert(Source);
    DisasmBreak(Source);
  end;
end;

procedure TCodeList.StartFrom(Address: Pointer);
var
  I: Integer;
begin
  Source := Address;
  SourceCollection^.FreeAll;
  for I := 0 to MaxSource - 1 do InsertAddress;
end;

procedure TCodeList.GoDownPrim;
begin
  if Focused = Limit.Y - 1 then InsertAddress
  else Inc(Focused);
  if Focused = Delta.Y + Size.Y then FastScrollTo(Delta.Y + 1)
  else DrawView;
end;

procedure TCodeList.GoUpPrim;
var
  P, O: Pointer;
begin
  if Focused = 0 then with SourceCollection^ do
  begin
    P := At(0);
    O := P;
    DisasmBack(P, True);
    if O = P then Exit;
    AtFree(Count - 1);
    AtInsert(0, P);
    DrawView;
  end
  else
  begin
    Dec(Focused);
    if Focused < Delta.Y then FastScrollTo(Delta.Y - 1)
    else DrawView;
  end;
end;

procedure TCodeList.GoPgDnPrim;
var
  I, Index, LastPos: Integer;
begin
  Index := Delta.Y + Size.Y - 1;
  LastPos := Index + Size.Y - 1;
  if LastPos > Limit.Y - 1 then
    for I := 1 to LastPos - (Limit.Y - 1) do InsertAddress;
  if Index < Limit.Y - 1 then
  begin
    Focused := Focused + Size.Y - 1;
    if Index > Limit.Y - Size.Y then
      Focused := Focused - (Index - (Limit.Y - Size.Y));
    ScrollTo(Delta.X, Index);
  end
  else DrawView;
end;

procedure TCodeList.GoPgUpPrim;
var
  Index: Integer;
begin
  Index := Focused - (Size.Y - 1);
  if Index < 0 then Index := 0;
  Focused := Index;
  Index := Delta.Y - (Size.Y - 1);
  if Index < 0 then Index := 0;
  if Delta.Y = Index then DrawView else ScrollTo(Delta.X, Index);
end;

procedure TCodeList.GoWhileKeyDown(Key: Byte);
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
    if KbdDelay <> 0 then Delay(KbdDelay);
  until False;
end;

procedure TCodeList.GoDown;
begin
  GoDownPrim;
  if (KbdStatus = 80) or (KbdStatus = 224) then GoWhileKeyDown(80);
end;

procedure TCodeList.GoUp;
begin
  GoUpPrim;
  if (KbdStatus = 72) or (KbdStatus = 224) then GoWhileKeyDown(72);
end;

procedure TCodeList.GoPgDn;
begin
  GoPgDnPrim;
  if (KbdStatus = 81) or (KbdStatus = 224) then GoWhileKeyDown(81);
end;

procedure TCodeList.GoPgUp;
begin
  GoPgUpPrim;
  if (KbdStatus = 73) or (KbdStatus = 224) then GoWhileKeyDown(73);
end;

procedure TCodeList.GoCtrlPgDn;
begin
  Focused := Limit.Y - 1;
  if Delta.Y = Limit.Y - Size.Y then DrawView
  else ScrollTo(Delta.X, Focused);
end;

procedure TCodeList.GoCtrlPgUp;
begin
  Focused := 0;
  if Delta.Y > 0 then ScrollTo(Delta.X, Focused)
  else DrawView;
end;

procedure TCodeList.GoEnd;
begin
  Focused := Delta.Y + Size.Y - 1;
  DrawView;
end;

procedure TCodeList.GoHome;
begin
  Focused := Delta.Y;
  DrawView;
end;

function TCodeList.GetFocused: Pointer;
begin
  GetFocused := SourceCollection^.At(Focused);
end;

function TCodeList.IsWithin(AnIndex: Integer): Boolean;
begin
  IsWithin := (AnIndex >= Delta.Y) and (AnIndex < Delta.Y + Size.Y);
end;

procedure TCodeList.FocusItem(Item: Pointer);
var
  Index, SY, I: Integer;
begin
  Index := SourceCollection^.IndexOf(Item);
  if Index = -1 then
  begin
    StartFrom(Item);
    GoCtrlPgUp;
  end
  else
  begin
    if (Index + Size.Y div 2 > MaxSource) and not IsWithin(Index) then
      for I := 1 to Index + Size.Y div 2 - MaxSource do
      begin
	InsertAddress;
	Dec(Index);
      end;
    SY := Index - Size.Y div 2;
    if SY < 0 then SY := 0;
    Focused := Index;
    if IsWithin(Focused) then DrawView else ScrollTo(0, SY);
  end;
end;

procedure TCodeList.GoToAddress;
var
  Segment, Offset: Word;
begin
  if GetAddress(Segment, Offset, True, Source,
    'Go to address', '~N~ew address', hcGoToAddress) then
      FocusItem(Ptr(Segment, Offset));
end;

procedure TCodeList.GoToOrigin;
begin
  FocusItem(SourceOrigin);
end;

function TCodeList.Search(const Match: String;
  AOptions: Word): Boolean;
var
  Found: Boolean;
  P, Address: Pointer;
  S, SS: String;
begin
  if Match = '' then Exit;
  DrawStatusLine(SearchMsg);
  SS := StUpcase(Match);
  Found := False;
  Search := True;
  P := GetFocused;
  if AOptions and frFromCursor <> 0 then DisasmBreak(P)
  else PtrRec(P).Ofs := 0;
  while (KbdStatus <> 1) and not Found and (PtrRec(P).Ofs < $FFF0) do
  begin
    Address := P;
    S := DisasmBreak(P);
    Found := Pos(SS, StUpcase(S)) <> 0;
  end;
  ClearKbd;
  if not Found then
  begin
    MessageBox(^C'Instruction not found.', nil, mfError + mfOkButton);
    Search := False;
  end
  else FocusItem(Address);
end;

procedure TCodeList.Find;
begin
  if Application^.ExecuteDialog(LoadFindDialog(False, True,
    frCaseSensitive + frWholeWordsOnly + frRegExp +
    frSelectedText + frBackward), @CodeData, False) <> cmCancel then
      Search(CodeData.MatchStr, CodeData.Options);
end;

procedure TCodeList.PopUp(AnOrigin: TPoint);
begin
  ShowPopup(AnOrigin, NewMenu(
    NewItem('~G~o to...', '', kbNoKey, cmGoTo, hcGoToAddress,
    NewItem('~O~rigin', '', kbNoKey, cmOrigin, hcOrigin,
    NewItem('~F~ind...', '', kbNoKey, cmFind, hcSHFind,
    NewItem('~S~earch again', '', kbNoKey, cmSearchAgain, hcSHSearchAgain,
      nil))))));
end;

constructor TCodeWindow.Init;
var
  R: TRect;
begin
  R.Assign(5, 1, 52, 16);
  TWindow.Init(R, 'Code', wnNoNumber);
  GetExtent(R);
  R.Grow(-1, -1);
  CodeList := New(PCodeList, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard)));
  Insert(CodeList);
  WinPos := @CodeWinPos;
end;

constructor TCodeWindow.Load(var S: TStream);
begin
  TWindow.Load(S);
  GetSubViewPtr(S, CodeList);
  CodeList^.FocusItem(CodeList^.Source);
  WinPos := @CodeWinPos;
end;

function TCodeWindow.GetPalette: PPalette;
const
  CCPUWindow = #113#114#115#116#117#118#119#120#121#122#123#124#125#126#127;
  P: String[Length(CCPUWindow)] = CCPUWindow;
begin
  GetPalette := @P;
end;

procedure TCodeWindow.SizeLimits(var Min, Max: TPoint);
begin
  TWindow.SizeLimits(Min, Max);
  Min.X := 16;
end;

procedure TCodeWindow.Store(var S: TStream);
begin
  TWindow.Store(S);
  PutSubViewPtr(S, CodeList);
end;

procedure RSRCodeWindow(RSR: PResourceFile);
var
  W: PCodeWindow;
begin
  W := New(PCodeWindow, Init);
  RSR^.Put(W, 'CODEWINDOW');
  Dispose(W, Done);
end;

procedure CodeWindow;
var
  R: TRect;
  W: PCodeWindow;
begin
  W := PCodeWindow(Resource^.Get('CODEWINDOW'));
  if W <> nil then
  begin
    if (WinPosMask and wpCode <> 0) and ValidWinPos(CodeWinPos) then
    begin
      SetWinPos(Desktop, CodeWinPos, R);
      W^.Locate(R);
    end;
    Application^.InsertWindow(W);
  end
  else ResourceNotFoundMsgBox('Code window');
end;

end.