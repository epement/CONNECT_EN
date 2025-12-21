{$I-,F+,O+,X+}
unit TxtView;

interface

uses Objects, Drivers, Views, EditFile, FindDlg, LFN;

const
  IncSearchLen = 63;

type
  PosCompareType = (PosLess, PosEqual, PosGreater);

  TPosRec = record
    FilePos: Longint;
    LinePos: Integer;
    LineLen: Integer;
  end;

  TPlaces = Array['0'..'9'] of TPosRec;

  PLineRec = ^TLineRec;
  TLineRec = record
    StrPtr: PString;
    StrPos: Longint;
  end;

  PLineBuffer = ^TLineBuffer;
  TLineBuffer = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
    function SafeInsert(Item: PLineRec; Index: Integer): Boolean;
  end;

  PViewIndicator = ^TViewIndicator;
  TViewIndicator = object(TView)
    Column: Integer;
    Character: Char;
    Percent: Byte;
    WrapStatus: Word;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    function GetMouseShape(var Event: TEvent): Char; virtual;
    function GetMousePos(X: Integer): Byte;
  end;

  PTextViewer = ^TTextViewer;
  TTextViewer = object(TView)
    Indicator: PViewIndicator;
    HScrollBar: PScrollBar;
    VScrollBar: PScrollBar;
    Source: Text;
    FullName: TNameZ;
    AssignTextMode: lAPIType;
{ storable fields }
    SourceName: PString;
    Delta: TPoint;
    BufOrg: Longint;
    BufEnd: Longint;
    SelOrg: TPosRec;
    SelEnd: TPosRec;
    Places: TPlaces;
    Status: Word;
    XLATTable: ConvertTable;
    HistLock: Byte;
{ non-storable fields }
    SourceSize: Longint;
    SourceTime: Longint;
{    SourceBuffer: PByteArray;}
    Buffer: PLineBuffer;
    CurPos: TPosRec;
    FindAllList: PCollection;
    FindAllStart: Longint;
    FindAllPos: Longint;
    FindAllData: TSearchData;
    TrackPos: Longint;
    IsValid: Boolean;
    IsSearchingAll: Boolean;
    NoSearchMsg: Boolean;
    DrawFlag: Boolean;
    UnixMode: Boolean;
    Open: Boolean;
    IncSearchStr: String[IncSearchLen];
    IncSearchPos: Longint;
    IncSearchOpt: Word;
    IncSearch: Boolean;
    IsSearchingFrom: Boolean;
    XLATKind: Byte;
    HelpName: PString;
{Added 2006.01.10 }
    UpdateTicks: Word;
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar;
      const AName: FNameStr; AIndicator: PViewIndicator);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Draw; virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    function Valid(Command: Word): Boolean; virtual;
    procedure InitSource;
    procedure DoneSource;
    procedure OpenSource;
    procedure CloseSource;
    procedure SetRanges;
    procedure AutoXLAT;
    procedure InitViewer;
    procedure ReadLine(var S: String);
    procedure FillBuffer(Pos: Longint; SkipFirst: Boolean);
    procedure ReadDown(var Count: Integer);
    procedure ReadUp(var Count: Integer);
    procedure ReadLastPortion(Limit: Longint);
    procedure ReRead(const AName: String);
    procedure ReReadScreen;
    procedure UpdateSourceTime;
    procedure GetLine(P: PLineRec; var S: String);
    procedure GetPartLine(P: PLineRec; var S: String);
    procedure GetWord(P: PLineRec; var W: String; var B, E: Integer);
    procedure GetMarkerLine(Pos: Longint; var S: String);
    procedure GoWhileKeyDown(Key: Byte);
    procedure GoDownPrim;
    procedure GoUpPrim;
    procedure CursorGoDownPrim;
    procedure CursorGoUpPrim;
    procedure GoDown;
    procedure GoUp;
    procedure GoPgDnPrim;
    procedure GoPgUpPrim;
    procedure GoPgDn;
    procedure GoPgUp;
    procedure GoCtrlPgDn;
    procedure GoCtrlPgUp;
    procedure GoRight;
    procedure GoLeft;
    procedure GoCtrlRight;
    procedure GoCtrlLeft;
    procedure GoEnd;
    procedure GoHome;
    procedure GoCtrlEnd;
    procedure GoCtrlHome;
    function GetNearestPos(APos: Longint): Longint;
    procedure GoToPosition(APos: Longint; AColumn: Byte);
    function GetCurLineNum: Integer;
    procedure GoToLineNum(ANum: Longint; APos: Integer);
    procedure GoToLineNumber;
    procedure TrackSource(APos: Longint);
    procedure SetPlaceMarker(AChar: Char);
    procedure GoToPlaceMarker(AChar: Char);
    procedure UpdatePosition;
    procedure SetSelect(ASelOrg, ASelEnd: TPosRec);
    procedure Unselect;
    procedure ToggleSelection;
    procedure GetSelection(P: PLineRec; var Lo, Hi: Integer);
    procedure GetSelectedPart(APos: Longint; var S: String;
      var Lo, Hi: Integer);
    procedure MarkBlockBegin;
    procedure MarkBlockEnd;
    procedure MarkCurLine;
    procedure MarkCurWord;
    procedure ToggleWrap(Ctrl: Boolean);
    function Search(const Match: String; AOptions: Word): Boolean;
    procedure Find(All: Boolean);
    procedure FindAllDlg;
    procedure InitIncSearch;
    procedure DoneIncSearch;
    procedure DoIncSearch(C: Char);
    procedure CopyToClipboard;
    procedure WriteBlockToFile(NamePtr: PString; Append: Boolean);
    procedure SetXLATTable(const Name: FNameStr; Prompt: Boolean);
    procedure ClearXLATTable;
    procedure GetLocalFields;
  end;

  PTextWindow = ^TTextWindow;
  TTextWindow = object(TWindow)
    Viewer: PTextViewer;
    constructor Init(Bounds: TRect; const AName: FNameStr);
    constructor Load(var S: TStream);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Close; virtual;
    function GetPalette: PPalette; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
    procedure Zoom; virtual;
  end;

const
  CViewerColor      = #$70#$7F#$7A#$31#$31#$70#$30#$7E#$07#$7F;
  CViewerBlackWhite = #$07#$0F#$07#$70#$70#$07#$70#$0F#$70#$7F;
  CViewerMonochrome = #$07#$0F#$07#$70#$70#$07#$70#$0F#$70#$7F;
  CViewer           = #6#7#8#9#10;
  CViewerWindow     = #175#176#177#178#179#180#181#182#183#184;

  CCurCol           = 201;

implementation

uses Dos, CNCrt, Memory, WinIcons, Dialogs, App, MsgBox, StdDlg, HistList,
  History, Swaps, Clipbrd, ClipPrim, CmntList, DirPrim, HeapUMB, EditCmnd,
  EditMsg, ViewFind, ViewPop, RegExp, RevPos, PlcHist, Spooler, CNInputs,
  Disks, DosTools, HTMLPrim, Keyboard, TPString, Consts, Commands, Defaults;

const
  SourceDelta: Word = $1000;
  BufSize: Integer  = $0080;

  sfCtrlKPressed    = $0001;
  sfCtrlQPressed    = $0002;
  sfHilit           = $0004;
  sfSelBack         = $0008;
  sfNeedRedraw      = $0010;
  sfWrapped         = $0020;
  sfXLAT            = $0080;
  sfHistLocked      = $0100;
  sfWordWrap        = $0200;

  TextViewerCommands =
    [cmPrint, cmUpdateASCII, cmUpdateHex, cmFind, cmFindAll,
     cmShowAllFound, cmSearchAgain, cmIncSearch, cmGoToLine];
  TxtViewCommands =
    [cmCopy, cmCtrlKW, cmCtrlQB, cmCtrlQK];

function NewLineRec(const Line: String; APos: Longint): PLineRec;
var
  R: PLineRec;
begin
{
  GetMem(R, SizeOf(TLineRec));
  R^.StrPtr := NewStr(Line);
}
  GetMemUMB(R, SizeOf(TLineRec));
  R^.StrPtr := NewStrUMB(Line);
  R^.StrPos := APos;
  NewLineRec := R;
end;

function PosCompare(Pos1, Pos2: TPosRec): PosCompareType;
begin
  if (Pos1.FilePos < Pos2.FilePos) or
     ((Pos1.FilePos = Pos2.FilePos) and
      (Pos1.LinePos < Pos2.LinePos)) then PosCompare := PosLess else
  if (Pos1.FilePos = Pos2.FilePos) and
     (Pos1.LinePos = Pos2.LinePos) then PosCompare := PosEqual else
    PosCompare := PosGreater;
end;

procedure TLineBuffer.FreeItem(Item: Pointer);
begin
  if Item <> nil then
  begin
{
    DisposeStr(PLineRec(Item)^.StrPtr);
    FreeMem(Item, SizeOf(TLineRec));
}
    DisposeStrUMB(PLineRec(Item)^.StrPtr);
    FreeMemUMB(Item, SizeOf(TLineRec));
  end;
end;

function TLineBuffer.SafeInsert(Item: PLineRec; Index: Integer): Boolean;
const
  SafetyPool = $2000;
var
  CanInsert: Boolean;
begin
  if Count < Limit then CanInsert := MaxAvail > SafetyPool
  else CanInsert := MaxAvail > LongMul(Limit + Delta, 4) + SafetyPool;
  if CanInsert then AtInsert(Index, Item)
  else
  begin
    FreeItem(Item);
    Application^.OutOfMemory;
  end;
  SafeInsert := CanInsert;
end;

procedure TViewIndicator.Draw;
var
  C: Char;
  Color: Byte;
  Params: Array[0..2] of Longint;
  EOLStr, EOFStr: String[3];
  IS: String[31];
  B: TDrawBuffer;
  S: String;
begin
  if State and sfActive = 0 then
  begin
    Color := GetColor(1);
    C := 'Ä';
  end
  else if State and sfDragging <> 0 then
  begin
    Color := GetColor(3);
    C := 'Ä';
  end
  else
  begin
    Color := GetColor(2);
    C := 'Í';
  end;
  MoveChar(B, C, Color, Size.X);
  IS := ' Col %-3d Char %-3s %3d%% ';
  Params[0] := Column;
  if Character = ^M then
  begin
    EOLStr := 'EOL';
    Params[1] := Longint(@EOLStr);
  end
  else if Character = ^Z then
  begin
    EOFStr := 'EOF';
    Params[1] := Longint(@EOFStr);
  end
  else
  begin
    IS[19] := 'd';
    Params[1] := Byte(Character);
  end;
  Params[2] := Percent;
  FormatStr(S, IS, Params);
  if WrapStatus and sfWordWrap <> 0 then
    MoveChar(B[Size.X - 5], '', Color, 1)
  else if WrapStatus and sfWrapped <> 0 then
    MoveChar(B[Size.X - 5], '<', Color, 1)
  else MoveChar(B[Size.X - 5], '>', Color, 1);
  MoveChar(B[Size.X - 3], '[', Color, 1);
  if MarkColumns then MoveChar(B[Size.X - 2], '', Color, 1)
  else MoveChar(B[Size.X - 2], '', Color, 1);
  MoveChar(B[Size.X - 1], ']', Color, 1);
  MoveStr(B, S, Color);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TViewIndicator.GetPalette: PPalette;
const
  P: String[3] = #1#2#3;
begin
  GetPalette := @P;
end;

const
  ipNo = 0;
  ipCol = 1;
  ipChar = 2;
  ipWrap = 3;

function TViewIndicator.GetMousePos(X: Integer): Byte;
begin
  if ((X >= 0) and (X <= 7)) or ((X >= 17) and (X <= 22)) then
    GetMousePos := ipCol
  else if (X >= 8) and (X <= 16) then GetMousePos := ipChar
  else if (X >= 22) and (X <= 24) then GetMousePos := ipWrap
  else GetMousePos := ipNo;
end;

procedure TViewIndicator.HandleEvent(var Event: TEvent);
var
  B: Byte;
  Mouse: TPoint;
begin
  Inherited HandleEvent(Event);
  if (Event.What = evMouseDown) and MouseInView(Event.Where) then
  begin
    MakeLocal(Event.Where, Mouse);
    B := GetMousePos(Mouse.X);
    if B = ipCol then Event.Command := cmGoToLine
    else if B = ipChar then Event.Command := cmASCIITable
    else if B = ipWrap then Event.Command := cmToggleWrap
    else if Mouse.X >= Size.X - 3 then Event.Command := cmToggleMarkMode
    else Exit;
    Message(Application, evCommand, Event.Command, nil);
    Event.What := evNothing;
  end;
end;

procedure TViewIndicator.SetState(AState: Word; Enable: Boolean);
begin
  Inherited SetState(AState, Enable);
  DrawView;
end;

function TViewIndicator.GetMouseShape(var Event: TEvent): Char;
var
  B: Byte;
  C: Char;
  P: TPoint;
begin
  C := #0;
  if (State and sfActive <> 0) and (Owner^.State and sfFocused <> 0) then
  begin
    MakeLocal(Event.Where, P);
    B := GetMousePos(P.X);
    if B = ipCol then C := ''
    else if B = ipChar then C := '#'
    else if B = ipWrap then C := '';
  end;
  GetMouseShape := C;
end;

constructor TTextViewer.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar;
  const AName: FNameStr; AIndicator: PViewIndicator);
begin
  Inherited Init(Bounds);
  Options := Options or ofSelectable;
  EventMask := EventMask or evBroadcast;
  GrowMode := gfGrowHiX + gfGrowHiY;
  HScrollBar := AHScrollBar;
  VScrollBar := AVScrollBar;
  Indicator := AIndicator;
{  SourceName := NewStr(AName);}
  SourceName := NewStrUMB(AName);
  Buffer := New(PLineBuffer, Init(BufSize, BufSize));
  FindAllList := New(PSwapLinesCollection, Init(8, 8));
  InitSource;
  if IsValid then InitViewer;
end;

constructor TTextViewer.Load(var S: TStream);
begin
  Inherited Load(S);
  GetPeerViewPtr(S, HScrollBar);
  GetPeerViewPtr(S, VScrollBar);
  GetPeerViewPtr(S, Indicator);
{  SourceName := S.ReadStr;}
  SourceName := ReadStrUMB(@S);
  S.Read(Delta, SizeOf(Delta) + SizeOf(BufOrg) + SizeOf(BufEnd) +
    SizeOf(SelOrg) + SizeOf(SelEnd) + SizeOf(Places) + SizeOf(Status));
  if Status and sfXLAT <> 0 then S.Read(XLATTable, SizeOf(ConvertTable));
  if Status and sfHistLocked <> 0 then S.Read(HistLock, SizeOf(HistLock));
  Buffer := New(PLineBuffer, Init(BufSize, BufSize));
  FindAllList := New(PSwapLinesCollection, Init(8, 8));
  InitSource;
end;

destructor TTextViewer.Done;
begin
  DoneSource;
  Dispose(FindAllList, Done);
  Dispose(Buffer, Done);
{  DisposeStr(SourceName);}
  DisposeStrUMB(SourceName);
  Inherited Done;
end;

procedure TTextViewer.ChangeBounds(var Bounds: TRect);
begin
  SetBounds(Bounds);
  HScrollBar^.SetParams(HScrollBar^.Value,
    0, $FF, Size.X - 1, HScrollBar^.ArStep);
  if Status and sfWrapped <> 0 then ReReadScreen;
  if (Delta.Y + Size.Y > Buffer^.Count) and
     (BufEnd < SourceSize) then ReadDown(Delta.Y);
  DrawView;
end;

procedure TTextViewer.Draw;
var
  Color, SelColor, TrackColor, CurColor: Byte;
  I, Lo, Hi, BP, Len: Integer;
  P: PLineRec;
  B: TDrawBuffer;
  S: String;

procedure HilitBuf;
begin
  BP := Lo - Delta.X - 1;
  if BP < Size.X then
  begin
    if BP < 0 then BP := 0;
    Len := Hi - Delta.X - 1 - BP;
    if Len > Size.X - BP then Len := Size.X - BP;
    if Len > 0 then MoveChar(B[BP], #0, SelColor, Len);
  end;
end;

begin
  if DrawFlag then Exit;
  Color := GetColor(1);
  SelColor := GetColor(2);
  TrackColor := GetColor(4);
  CurColor := GetColor(5);
  for I := 0 to Size.Y - 1 do
  begin
    MoveChar(B, ' ', Color, Size.X);
    Lo := 0;
    P := Buffer^.At(Delta.Y + I);
    if P <> nil then
    begin
      GetLine(P, S);
      MoveStr(B, Copy(S, Delta.X + 1, Size.X), Color);
      if P^.StrPos = TrackPos then MoveChar(B, #0, TrackColor, Size.X)
      else
      begin
        if (I = Cursor.Y) and (EditOptions and eoHilitCurLine <> 0) then
          MoveChar(B, #0, CurColor, Size.X);
        if Status and sfHilit <> 0 then
        begin
          GetSelection(P, Lo, Hi);
          if Lo > 0 then HilitBuf;
        end;
      end;
      if (EditOptions and eoHilitCurColumn <> 0) and
         (Cursor.X >= 0) and (Cursor.X < MaxViewWidth) and
         ((Lo = 0) or (Delta.X + Cursor.X + 1 < Lo) or
          (Delta.X + Cursor.X + 1 >= Hi)) then
        MoveChar(B[Cursor.X], #0,
          Byte(Application^.GetPalette^[cCurCol]), 1);
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

function TTextViewer.GetHelpCtx: Word;
var
  B: Boolean;
  L: Longint;
begin
  if State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else if IncSearch then
    GetHelpCtx := hcEditIncSearch
  else if GetShiftState and kbAltShift <> 0 then
    GetHelpCtx := hcAltTextViewer
  else if Status and sfCtrlKPressed <> 0 then
    GetHelpCtx := hcViewerCtrlKPressed
  else if Status and sfCtrlQPressed <> 0 then
    GetHelpCtx := hcViewerCtrlQPressed
  else if Status and sfWrapped <> 0 then
    GetHelpCtx := hcWrapTextViewer
  else GetHelpCtx := hcTextViewer;

{Added 2006.01.10 }
  if (MemW[$40:$6C] - UpdateTicks >= 50) then
  begin
    UpdateTicks := MemW[$40:$6C];
    if not GetFileTime(SourceName^, L) then UpdateSourceTime
    else if L <> SourceTime then
    begin
      B := CurPos.FilePos + CurPos.LinePos >= SourceSize;
      ReRead(SourceName^);
      if B then
      begin
	GoCtrlPgDn;
	UpdatePosition;
      end;
    end;
  end;
end;

function TTextViewer.GetPalette: PPalette;
const
  P: String[Length(CViewer)] = CViewer;
begin
  GetPalette := @P;
end;

procedure TTextViewer.HandleEvent(var Event: TEvent);
var
  SameName, ShiftDown, MouseOut, SaveFlag, WasSelected: Boolean;
  Y, B, E: Integer;
  C: Word;
  V: PTextViewer;
  P: PSpoolerRec;
  Spot: TPoint;
  SavePos: TPosRec;
  S: String;

procedure OpenAnother;
var
  SaveExplode: Boolean;
begin
  SaveExplode := DoExplode;
  DoExplode := False;
  Desktop^.Lock;
  Desktop^.EventMask := EventMask and not evBroadcast;
  Message(Application, evCommand, cmOpenTextViewer, SourceName);
  Desktop^.EventMask := EventMask or evBroadcast;
  V := Message(Desktop, evBroadcast, cmOpenTextViewer, SourceName);
  if (V <> nil) and (V <> @Self) and
     (V^.Owner^.State and sfActive <> 0) then
  begin
    V^.GoToPosition(CurPos.FilePos, CurPos.LinePos);
    V^.UpdatePosition;
  end;
  Desktop^.Unlock;
  DoExplode := SaveExplode;
end;

procedure HScrollDraw;
begin
  Delta.X := HScrollBar^.Value;
  while Delta.X + Cursor.X > HScrollBar^.Max do Dec(Cursor.X);
  DrawView;
  UpdatePosition;
end;

procedure VScrollDraw;
var
  SaveMask: Word;
begin
  SaveMask := EventMask;
  EventMask := 0;
  if VScrollBar^.Value = Indicator^.Percent - 1 then
    if (BufOrg = 0) and (Delta.Y = 0) then GoCtrlPgUp else GoUpPrim
  else if VScrollBar^.Value = Indicator^.Percent + 1 then GoDownPrim
  else if VScrollBar^.Value = Indicator^.Percent - 2 then GoPgUpPrim
  else if VScrollBar^.Value = Indicator^.Percent + 2 then GoPgDnPrim
  else if VScrollBar^.Value = VScrollBar^.Min then GoCtrlPgUp
  else if VScrollBar^.Value = VScrollBar^.Max then GoCtrlPgDn
  else GoToPosition(Round((SourceSize / 100) * VScrollBar^.Value), 0);
  VScrollBar^.Value := VScrollBar^.Min;
  UpdatePosition;
  EventMask := SaveMask;
end;

procedure ExpandSelection;
begin
  if PosCompare(CurPos, SavePos) <> PosEqual then
    if (PosCompare(SavePos, SelOrg) = PosEqual) and
       (Status and sfSelBack <> 0) then SetSelect(SelEnd, CurPos) else
    if (PosCompare(SavePos, SelEnd) = PosEqual) and
       (Status and sfSelBack = 0) then SetSelect(SelOrg, CurPos) else
    SetSelect(SavePos, CurPos);
end;

procedure SelectAll;
begin
  if SourceSize = 0 then Exit;
  if MarkColumns then Message(
    Application, evCommand, cmToggleMarkMode, nil);
  SelOrg.FilePos := 0;
  SelEnd.FilePos := SourceSize;
  SelOrg.LinePos := 1;
  SelEnd.LinePos := 256;
  SetSelect(SelOrg, SelEnd);
  DrawView;
end;

label
  CannotHandle;
begin
  if Event.What = evKeyDown then
    if (Event.KeyCode = kbCtrlHome) or (Event.KeyCode = kbCtrlEnd) or
       (Event.KeyCode = kbCtrlPgUp) or (Event.KeyCode = kbCtrlPgDn) or
       (Event.CharCode in WordStarChars) then
      if (Event.CharCode = #0) or
         (Status and (sfCtrlKPressed + sfCtrlQPressed) = 0) then
        ConvertWSKey(WordStarKeys, Event);
  Inherited HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    if IncSearch then
    begin
      if Event.CharCode <> #0 then
      begin
        DoIncSearch(Event.CharCode);
        Event.What := evNothing;
        Exit;
      end;
      if (Event.KeyCode = kbShiftIns) or
         (Event.KeyCode = kbShiftF12) then
      begin
        if Event.KeyCode = kbShiftF12 then
          if MultitaskerDetected then
            Pending.Command := cmPasteFromMT
          else Exit
        else Pending.Command := cmPaste;
        Pending.What := evCommand;
        Event.What := evNothing;
        Exit;
      end;
      DoneIncSearch;
    end
    else if Status and sfNeedRedraw <> 0 then
    begin
      Status := Status and not sfNeedRedraw;
      DrawView;
    end;
    if (Cursor.X >= Size.X) or (Cursor.Y >= Size.Y) then
    begin
      if Cursor.X >= Size.X then
      begin
        Y := Cursor.X - Size.X + 1;
        Inc(Delta.X, Y);
        Dec(Cursor.X, Y);
      end;
      if Cursor.Y >= Size.Y then
      begin
        Y := Cursor.Y - Size.Y + 1;
        Inc(Delta.Y, Y);
        Dec(Cursor.Y, Y);
      end;
      DrawView;
      UpdatePosition;
    end;
    ShiftDown := GetShiftState and (kbLeftShift + kbRightShift) <> 0;
    if ShiftDown then
    begin
      SavePos := CurPos;
      SaveFlag := DrawFlag;
      DrawFlag := True;
    end;
    if (Event.CharCode <> #0) and
       (Status and (sfCtrlKPressed + sfCtrlQPressed) <> 0) then
    begin
      C := 0;
      if Status and sfCtrlKPressed <> 0 then
        case Event.CharCode of
          'Q', 'q', '©', '‰', ^Q:
            begin
              Pending.What := evCommand;
              Pending.Command := cmMenu;
            end;
          '0'..'9': SetPlaceMarker(Event.CharCode);
          else GetCtrlKCommand(Event.CharCode, C);
        end
      else if Status and sfCtrlQPressed <> 0 then
        case Event.CharCode of
          '0'..'9': GoToPlaceMarker(Event.CharCode);
          else GetCtrlQCommand(Event.CharCode, C);
        end;
      Status := Status and not (sfCtrlKPressed + sfCtrlQPressed);
      if C <> 0 then
      begin
        Event.What := evCommand;
        Event.Command := C;
        HandleEvent(Event);
      end;
    end
    else case CtrlToArrow(Event.KeyCode) of
      kbDown: GoDown;
      kbUp: GoUp;
      kbCtrlDn: GoDownPrim;
      kbCtrlUp: GoUpPrim;
      kbPgDn: GoPgDn;
      kbPgUp: GoPgUp;
      kbCtrlPgDn: GoCtrlPgDn;
      kbCtrlPgUp: GoCtrlPgUp;
      kbRight: GoRight;
      kbLeft: GoLeft;
      kbCtrlRight: GoCtrlRight;
      kbCtrlLeft: GoCtrlLeft;
      kbEnd: GoEnd;
      kbHome: GoHome;
      kbCtrlEnd: GoCtrlEnd;
      kbCtrlHome: GoCtrlHome;
      kbCtrl2: InitIncSearch;
      kbCtrlIns: Message(Application, evCommand, cmCopy, nil);
      kbCtrlF12: Message(Application, evCommand, cmCopyToMT, nil);
      kbAltY: PlaceMarkerDlg(@Self, Status and sfCtrlQPressed = 0);
      kbGrayMinus: Message(Desktop, evBroadcast, cmFMViewPrev, SourceName);
      kbGrayPlus: Message(Desktop, evBroadcast, cmFMViewNext, SourceName);
      else case Event.CharCode of
        ^K: Status := Status or sfCtrlKPressed;
        ^Q: Status := Status or sfCtrlQPressed;
        ^L: Search(SearchData.MatchStr,
              SearchData.Options or frFromCursor);
        ^B: Search(SearchData.MatchStr,
              SearchData.Options or (frFromCursor + frBackward));
        ^U: Search(SearchData.MatchStr,
              (SearchData.Options or frFromCursor) and not frBackward);
       #27:
          begin
            Pending.What := evCommand;
            Pending.Command := cmClose;
            Pending.InfoPtr := Owner;
          end;
        #32: GetWord(PLineRec(Buffer^.At(Delta.Y + Cursor.Y)),
          SearchData.MatchStr, B, E);
        ^\: Message(Desktop, evBroadcast, cmReopen, SourceName);
        else Goto CannotHandle;
      end;
    end;
    if (KeyboardOptions and koDisableMultiScroll = 0) and
       (GetShiftState and kbScrollState <> 0) and
       not MultiScrolling and IsScrollKey(Event.KeyCode) then
         MultiScroll(PWindow(Owner), Event.KeyCode);
    Event.What := evNothing;
CannotHandle:
    UpdatePosition;
    if ShiftDown then
    begin
      ExpandSelection;
      DrawFlag := SaveFlag;
      DrawView;
    end;
  end
  else if (Event.What = evMouseDown) and MouseInView(Event.Where) then
  begin
    if IncSearch then DoneIncSearch
    else if Status and sfNeedRedraw <> 0 then
    begin
      Status := Status and not sfNeedRedraw;
      DrawView;
    end;
    if Event.Buttons = mbRightButton then
    begin
      repeat until not MouseEvent(Event, evMouseDown);
      ViewerPopup(Event.Where, True, not UnixMode);
      Event.What := evNothing;
    end
    else
    begin
      WasSelected := Status and sfHilit <> 0;
      repeat
        SaveFlag := DrawFlag;
        DrawFlag := True;
        MakeLocal(Event.Where, Spot);
        if MouseInView(Event.Where) then
        begin
          MouseOut := False;
          if (Status and sfHilit = 0) and
             (Event.What and evMouseMove <> 0) then
          begin
            SavePos := CurPos;
            SetSelect(CurPos, CurPos);
          end;
          while Delta.X + Spot.X > $FF do Dec(Spot.X);
          while Delta.Y + Spot.Y > Buffer^.Count do Dec(Spot.Y);
          SetCursor(Spot.X, Spot.Y);
        end
        else
        begin
          MouseOut := True;
          Spot.X := 0;
          Spot.Y := 0;
          MakeGlobal(Spot, Spot);
          if Event.Where.X < Spot.X then GoLeft;
          if Event.Where.X > Spot.X + Size.X - 1 then GoRight;
          if Event.Where.Y < Spot.Y then CursorGoUpPrim;
          if Event.Where.Y > Spot.Y + Size.Y - 1 then CursorGoDownPrim;
        end;
        UpdatePosition;
        if Event.Double then
        begin
          if Status and sfHilit <> 0 then Unselect
          else MarkCurLine;
          DrawFlag := SaveFlag;
          DrawView;
          Event.What := evNothing;
          Break;
        end;
        if not WasSelected and
          ((Event.What and evMouseMove <> 0) or MouseOut) then
            SetSelect(SavePos, CurPos)
        else if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
          (Status and sfHilit <> 0) then
            if Status and sfSelBack <> 0 then
              SetSelect(SelEnd, CurPos)
            else SetSelect(SelOrg, CurPos);
        DrawFlag := SaveFlag;
        DrawView;
      until not MouseEvent(Event, evMouseMove + evMouseAuto);
    end;
  end
  else if Event.What = evBroadcast then
  begin
    case Event.Command of
      cmScrollBarChanged:
        if (Event.InfoPtr = HScrollBar) and
           (HScrollBar^.Value <> Delta.X) then
        begin
          HScrollDraw;
          Event.What := evNothing;
        end
        else if (Event.InfoPtr = VScrollBar) and
          (VScrollBar^.Value <> Indicator^.Percent) then
        begin
          VScrollDraw;
          Event.What := evNothing;
        end;
      cmToggleMarkMode:
        begin
          DrawView;
          Indicator^.DrawView;
        end;
      cmGetWord:
        begin
          Event.What := evNothing;
          GetWord(PLineRec(Buffer^.At(Delta.Y + Cursor.Y)), S, B, E);
          if S = '' then Event.InfoPtr := nil
          else Event.InfoPtr := @S;
        end;
      cmGetLine:
        begin
          Event.What := evNothing;
          GetPartLine(PLineRec(Buffer^.At(Delta.Y + Cursor.Y)), S);
          if S = '' then Event.InfoPtr := nil
          else Event.InfoPtr := @S;
        end;
      cmGetMarkerLine:
        begin
          Event.What := evNothing;
          if (Event.InfoChar in ['0'..'9']) and
             (Places[Event.InfoChar].LinePos <> 0) then
          begin
            GetMarkerLine(Places[Event.InfoChar].FilePos, S);
            Event.InfoPtr := @S;
          end
          else Event.InfoPtr := nil;
        end;
      cmOpenTextViewer:
        begin
          SameName :=
            CompUCString(PString(Event.InfoPtr)^, SourceName^) = Equal;
          if not SameName and not SameWinFlag then Exit;
	  if not SameName then ReRead(PString(Event.InfoPtr)^);
          PWindow(Owner)^.Deiconize;
          Owner^.Show;
          Owner^.Select;
          ClearEvent(Event);
        end;
      cmIsTextViewer:
        if Owner^.State and sfVisible <> 0 then ClearEvent(Event);
      cmUpdateTime:
        if (Event.InfoPtr = nil) or
           (CompUCString(PString(Event.InfoPtr)^, SourceName^) = Equal) then
	  UpdateSourceTime;
      cmGetSource: if Owner^.State and sfVisible <> 0 then
        begin
          Event.What := evNothing;
          Event.InfoPtr := SourceName;
        end;
      cmTrackSource: if Owner^.State and sfVisible <> 0 then
        begin
          TrackSource(Event.InfoLong);
          Event.What := evNothing;
        end;
      cmGoToLine: if Owner^.State and sfVisible <> 0 then
        begin
          GoToLineNum(LongRec(Event.InfoPtr).Hi + 1,
            LongRec(Event.InfoPtr).Lo + 1);
          Event.What := evNothing;
        end;
      cmCtrlKW:
        begin
          WriteBlockToFile(Event.InfoPtr, False);
          ClearEvent(Event);
        end;
      cmEditOptions:
        begin
          GetLocalFields;
          DrawView;
        end;
      cmHelp:
        begin
          C := GetHelpCtx;
          if (C = hcAltTextViewer) or (C = hcWrapTextViewer) or
             (C = hcTextViewer) then
          begin
            Event.What := evNothing;
            Event.InfoPtr := HelpName;
          end;
        end;
      cmlAPIChanged:
        begin
          lGetFileNameForChangedAPI(lAPIType(Event.InfoByte),
            SourceName^, S);
{
          DisposeStr(SourceName);
          SourceName := NewStr(S);
}
          DisposeStrUMB(SourceName);
          SourceName := NewStrUMB(S);
          DisposeStr(PWindow(Owner)^.Title);
          PWindow(Owner)^.Title := NewStr(S);
          PWindow(Owner)^.Frame^.DrawView;
          if PWindow(Owner)^.Icon <> nil then
            PWinIcon(PWindow(Owner)^.Icon)^.Update;
        end;
    end;
  end
  else if Event.What = evCommand then
  begin
    if IncSearch and
      (Event.Command <> cmPaste) and
      (Event.Command <> cmPasteFromMT) and
      (Event.Command <> cmCtrlQB {Search uses this command}) then
        DoneIncSearch;
    case Event.Command of
      cmCopy: CopyToClipboard;
      cmPaste:
        if IncSearch then IncSearchFromClipboard(@Self) else Exit;
      cmFind: Find(False);
      cmReplace: OpenAnother;
      cmFindAll: Find(True);
      cmShowAllFound: FindAllDlg;
      cmSearchAgain: Search(SearchData.MatchStr,
        SearchData.Options or frFromCursor);
      cmIncSearch: InitIncSearch;
      cmGoToLine: GoToLineNumber;
      cmToggleWrap, cmCtrlToggleWrap:
        ToggleWrap(Event.Command = cmCtrlToggleWrap);
      cmSetTextMode:
        begin
          UnixMode := not UnixMode;
          ReReadScreen;
          PWindow(Owner)^.Frame^.DrawView;
        end;
      cmPrint:
        begin
          SaveFlag := BinaryPrinting;
          BinaryPrinting := False;
          P := TheSpooler^.NewSource(SourceName^);
          if (P <> nil) and (Status and sfXLAT <> 0) then
            SetSpoolerXLAT(P, XLATTable);
          BinaryPrinting := SaveFlag;
        end;
      cmSelectAll: SelectAll;
      cmPopUp:
        begin
          Spot.X := Size.X div 2;
          Spot.Y := 0;
          MakeGlobal(Spot, Spot);
          ViewerPopup(Spot, True, not UnixMode);
        end;
      else
      begin
        case Event.Command of
          cmCtrlKB: MarkBlockBegin;
          cmCtrlKK: MarkBlockEnd;
          cmCtrlKH: ToggleSelection;
          cmCtrlKL: MarkCurLine;
          cmCtrlKT: MarkCurWord;
          cmCtrlKW,
          cmCtrlKA: WriteBlockToFile(nil, Event.Command = cmCtrlKA);
          cmCtrlQW, cmCtrlQQ: SetXLATTable('', Event.Command = cmCtrlQQ);
          cmCtrlQX: ClearXLATTable;
          cmCtrlQB, cmCtrlQK:
            begin
              DrawFlag := True;
              if Event.Command = cmCtrlQB then SavePos := SelOrg
              else SavePos := SelEnd;
              if SavePos.LinePos > SavePos.LineLen then
                Inc(SavePos.LineLen)
              else SavePos.LineLen := SavePos.LinePos;
              GoToPosition(SavePos.FilePos, SavePos.LineLen);
              while Delta.X + Cursor.X < SavePos.LinePos - 1 do GoRight;
              DrawFlag := False;
            end;
          else Exit;
        end;
        DrawView;
        UpdatePosition;
      end;
    end;
    Event.What := evNothing;
  end;
end;

procedure TTextViewer.SetState(AState: Word; Enable: Boolean);

procedure ShowSBar(SBar: PView);
begin
  if SBar <> nil then
    if GetState(sfActive + sfSelected + sfExposed) then SBar^.Show
    else SBar^.Hide;
end;

begin
  Inherited SetState(AState, Enable);
  if (State and sfExposed <> 0) and
     (AState and (sfActive + sfSelected) <> 0) then
  begin
    ShowSBar(HScrollBar);
    ShowSBar(VScrollBar);
  end;
  if Enable and (AState = sfExposed) then Indicator^.Hide;
  if Enable and (AState = sfFocused) then
  begin
    Indicator^.Show;
    EnableCommands(TextViewerCommands);
    if Status and sfHilit <> 0 then
      EnableCommands(TxtViewCommands + MTCopyCommands)
    else DisableCommands(TxtViewCommands + MTCopyCommands);
    if IncSearch then EnableCommands(PasteCommands + MTPasteCommands)
    else DisableCommands(PasteCommands + MTPasteCommands);
  end
  else if not Enable and
    (((AState = sfActive) and GetState(sfExposed)) or
     (AState = sfExposed)) then DisableCommands(
       TextViewerCommands + TxtViewCommands +
       PasteCommands + MTCopyCommands + MTPasteCommands);
end;

procedure TTextViewer.Store(var S: TStream);
begin
  Inherited Store(S);
  PutPeerViewPtr(S, HScrollBar);
  PutPeerViewPtr(S, VScrollBar);
  PutPeerViewPtr(S, Indicator);
  S.WriteStr(SourceName);
  S.Write(Delta, SizeOf(Delta) + SizeOf(BufOrg) + SizeOf(BufEnd) +
    SizeOf(SelOrg) + SizeOf(SelEnd) + SizeOf(Places) + SizeOf(Status));
  if Status and sfXLAT <> 0 then S.Write(XLATTable, SizeOf(ConvertTable));
  if Status and sfHistLocked <> 0 then S.Write(HistLock, SizeOf(HistLock));
end;

function TTextViewer.Valid(Command: Word): Boolean;
begin
  Valid := IsValid and Inherited Valid(Command);
end;

procedure TTextViewer.InitSource;
var
  S: String;
begin
  IsValid := False;
  SourceSize := 0;
  SourceTime := 0;
  UnixMode := False;
  LogEvent := lcDiskRead;
  DrawStatusLine('Loading text viewer ' +
    TrimmedName(SourceName^, 49) + '.');
  lAssignText(lText(Addr(Source)^), SourceName^);
  OpenSource;
  if IOResult <> 0 then CouldNotOpenMsgBox(SourceName^)
  else if IsDevice(TextRec(Source).Handle) then
    FileIsDeviceMsgBox(SourceName^)
  else
  begin
    if (TextReadMode = trAuto) and not Eof(Source) then
    begin
      SetUNIXTextMode;
      Readln(Source, S);
      SetDOSTextMode;
      UnixMode := S[Length(S)] <> #13;
      TextSeek(Source, 0);
    end
    else UnixMode := TextReadMode = trUNIX;
    SourceSize := TextFileSize(Source);
    if SourceSize < 0 then SourceSize := MaxLongint;
(*
    if SourceSize >= SourceDelta then
    begin
{      GetMem(SourceBuffer, SourceDelta);}
      GetMemUMB(SourceBuffer, SourceDelta);
      SetTextBuf(Source, SourceBuffer^, SourceDelta);
    end;
*)
    GetFileTime(SourceName^, SourceTime);
    IsValid := True;
  end;
end;

procedure TTextViewer.DoneSource;
begin
  CloseSource;
(*
  if SourceBuffer <> nil then
  begin
{    FreeMem(SourceBuffer, SourceDelta);}
    FreeMemUMB(SourceBuffer, SourceDelta);
    SourceBuffer := nil;
  end;
*)
end;

procedure TTextViewer.OpenSource;
begin
  if not Open then
  begin
    Reset(Source);
    Open := True;
  end;
end;

procedure TTextViewer.CloseSource;
begin
  if Open then
  begin
    Close(Source);
    InOutRes := 0;
    Open := False;
  end;
end;

procedure TTextViewer.SetRanges;
var
  SaveMask: Word;
begin
  SaveMask := EventMask;
  EventMask := 0;
  HScrollBar^.SetParams(HScrollBar^.Value,
    0, $FF, Size.X - 1, HScrollBar^.ArStep);
  VScrollBar^.SetParams(VScrollBar^.Value, -1, 101, 2, VScrollBar^.ArStep);
  VScrollBar^.Options := VScrollBar^.Options or ofBuffered; { Smooth scroll }
  EventMask := SaveMask;
end;

procedure TTextViewer.AutoXLAT;
const
  AltSet = [#160 .. #175, #224 .. #239];
  KoiSet = [#193 .. #208, #210 .. #213, #198, #195, #219 .. #223, #217, #216, #192, #209];
  WinSet = [#224 .. #239, #240 .. #255];
{
  AltSet = [' '..'¯', 'à'..'ï'];
  KoiSet = ['Á'..'Ð', 'Ò'..'Ñ'];
  WinSet = ['à'..'ï', 'ð'..#255];
}
var
  I, J: Integer;
  Alt, Koi, Win, L: Longint;
  P: PLineRec;
begin
  Alt := 0;
  Koi := 0;
  Win := 0;
  for I := 0 to Buffer^.Count - 1 do
  begin
    P := Buffer^.At(I);
    if (P <> nil) and (P^.StrPtr <> nil) then
      for J := 1 to Length(P^.StrPtr^) do
      begin
        if P^.StrPtr^[J] in AltSet then Inc(Alt);
        if P^.StrPtr^[J] in KoiSet then Inc(Koi);
        if P^.StrPtr^[J] in WinSet then Inc(Win);
      end;
  end;
  L := Alt;
  if Koi > L then L := Koi;
  if Win > L then L := Win;
  if L <> 0 then
  begin
    if L = Koi then XLATKind := xKoi
    else if L = Win then XLATKind := xWin;
    if XLATKind <> xAlt then
    begin
      FillXLATTable(XLATKind, XLATTable);
      Status := Status or sfXLAT;
      for I := 0 to Buffer^.Count - 1 do
      begin
        P := Buffer^.At(I);
        if (P <> nil) and (P^.StrPtr <> nil) then
          for J := 1 to Length(P^.StrPtr^) do
            P^.StrPtr^[J] := XLATTable[P^.StrPtr^[J]];
      end;
    end;
  end;
end;

procedure TTextViewer.InitViewer;

function ScanHistory: Boolean;
var
  P: Byte;
  I: Integer;
  R: PHistoryRec;
  X, Y: String[15];
  S: String;
begin
  ScanHistory := False;
  I := HistoryIndex(ReopenHistoryID, 'View  ' + SourceName^ + #$FF);
  if I = -1 then Exit;
  R := HistoryList^.At(I);
  S := R^.StrPtr^;
  if R^.Lock then
  begin
    HistLock := Byte(R^.Lock);
    Status := Status or sfHistLocked;
  end
  else Status := Status and not sfHistLocked;
  HistoryList^.AtFree(I);
  P := Pos(#$FF, S);
  S := Copy(S, P + 1, 255);
  P := Pos(#$FF, S);
  if P = 0 then Exit;
  X := Copy(S, 1, P - 1);
  Y := System.Copy(S, P + 1, 10);
  Val(X, CurPos.LinePos, I);
  Val(Y, CurPos.FilePos, I);
  P := Pos(#$FF'PLACES', S);
  if P <> 0 then Move(S[P + 7], Places, SizeOf(TPlaces));
  ScanHistory := True;
end;

function LocalXLAT: Boolean;
var
  B: Boolean;
  I, J: Integer;
  P: PLineRec;
begin
  if ReadLocalConvertTable(XLATTable, B) then
  begin
    Status := Status or sfXLAT;
    for I := 0 to Buffer^.Count - 1 do
    begin
      P := Buffer^.At(I);
      if (P <> nil) and (P^.StrPtr <> nil) then
        for J := 1 to Length(P^.StrPtr^) do
          P^.StrPtr^[J] := XLATTable[P^.StrPtr^[J]];
    end;
    LocalXLAT := True;
  end
  else LocalXLAT := False;
end;

var
  DoAutoXLAT: Boolean;
begin
  DoAutoXLAT := (AutoDecode and adText <> 0) and
    (GetShiftState and kbAltShift = 0);
  XLATKind := xAlt;
  Unselect;
  FillChar(Places, SizeOf(TPlaces), 0);
  TrackPos := -1;
  if ScanHistory and (SourceSize <> 0) then
    GoToPosition(CurPos.FilePos, CurPos.LinePos)
  else
  begin
    FillBuffer(BufOrg, False);
    if Delta.Y + Cursor.Y > Buffer^.Count then GoCtrlPgDn;
  end;
  ShowCursor;
  UpdatePosition;
  if not LocalXLAT and DoAutoXLAT then AutoXLAT;
  GetLocalFields;
end;

procedure _ReadLn(var F: Text; var S: String; Len: Word);
begin
asm
      les       di,F
      push      es
      push      di
      les       di,S
      push      es
      push      di
      mov       ax,Len
      push      ax
@@1:  jmp       @@1+11H
end;
  ReadLn(F, S);
end;

procedure TTextViewer.ReadLine(var S: String);
var
  B, C: Byte;
  Len: Word;
begin
  if Status and sfWrapped <> 0 then Len := Size.X
  else Len := $FF;
  if UnixMode then SetUNIXTextMode;
  _Readln(Source, S, Len);
  SetDOSTextMode;
  if Status and sfXLAT <> 0 then
    for C := 1 to Length(S) do S[C] := XLATTable[S[C]];

  if (Status and (sfWrapped + sfWordWrap) = (sfWrapped + sfWordWrap)) and
     (Length(S) = Len) then
  begin
    B := Len;
    while (Len - B < 32) and (S[B] <> ' ') do Dec(B);
    if S[B] = ' ' then
    begin
      S[0] := Char(B - 1);
      TextSeek(Source, TextPos(Source) - Len + B);
    end;
  end;
end;

procedure TTextViewer.FillBuffer(Pos: Longint; SkipFirst: Boolean);
var
  S: String;
begin
  Buffer^.FreeAll;
  OpenSource;
  TextSeek(Source, Pos);
  if (Pos <> 0) and SkipFirst then
  begin
    ReadLine(S);
    Pos := TextPos(Source);
  end;
  BufOrg := Pos;
  repeat
    if Eof(Source) then Break;
    ReadLine(S);
    if IOResult <> 0 then Break;
    if not Buffer^.SafeInsert(NewLineRec(S, Pos), Buffer^.Count) then Break;
    Pos := TextPos(Source);
    if Buffer^.Count >= BufSize then Break;
  until False;
  BufEnd := Pos;
  CloseSource;
  SetRanges;
end;

procedure TTextViewer.ReadDown(var Count: Integer);
var
  Pos: Longint;
  S: String;
begin
  while Count > 0 do
  begin
    Buffer^.AtFree(0);
    Dec(Count);
  end;
  OpenSource;
  TextSeek(Source, BufEnd);
  Pos := BufEnd;
  repeat
    if Eof(Source) then Break;
    ReadLine(S);
    if IOResult <> 0 then Break;
    if not Buffer^.SafeInsert(NewLineRec(S, Pos), Buffer^.Count) then Break;
    Pos := TextPos(Source);
    if Buffer^.Count >= BufSize then Break;
  until False;
  BufOrg := PLineRec(Buffer^.At(0))^.StrPos;
  BufEnd := Pos;
  CloseSource;
  SetRanges;
end;

procedure TTextViewer.ReadUp(var Count: Integer);
var
  Pos: Longint;
  S: String;
begin
  while Buffer^.Count > Count do
  begin
    BufEnd := PLineRec(Buffer^.At(Buffer^.Count - 1))^.StrPos;
    Buffer^.AtFree(Buffer^.Count - 1);
  end;
  Pos := BufOrg - SourceDelta;
  if Pos < 0 then Pos := 0;
  OpenSource;
  TextSeek(Source, Pos);
  if Pos <> 0 then
  begin
    ReadLine(S);
    Pos := TextPos(Source);
  end;
  Count := 0;
  repeat
    if Eof(Source) then Break;
    ReadLine(S);
    if IOResult <> 0 then Break;
    if Buffer^.Count >= BufSize then
    begin
      Buffer^.AtFree(0);
      Dec(Count);
    end;
    if not Buffer^.SafeInsert(NewLineRec(S, Pos), Count) then Break;
    Inc(Count);
    Pos := TextPos(Source);
    if Pos >= BufOrg then Break;
  until False;
  BufOrg := PLineRec(Buffer^.At(0))^.StrPos;
  CloseSource;
  SetRanges;
end;

procedure TTextViewer.ReadLastPortion(Limit: Longint);
var
  Count: Integer;
  Pos: Longint;
  S: String;
begin
  Buffer^.FreeAll;
  Pos := SourceSize - SourceDelta;
  if Pos < 0 then Pos := 0;
  OpenSource;
  TextSeek(Source, Pos);
  if Pos <> 0 then
  begin
    ReadLine(S);
    Pos := TextPos(Source);
  end;
  Count := 0;
  repeat
    if Eof(Source) or (Pos < 0) then Break;
    ReadLine(S);
    if IOResult <> 0 then Break;
    if Buffer^.Count >= BufSize then
    begin
      if (Limit < SourceSize) and
         (PLineRec(Buffer^.At(1))^.StrPos > Limit) then Break;
      Buffer^.AtFree(0);
      Dec(Count);
    end;
    if not Buffer^.SafeInsert(NewLineRec(S, Pos), Count) then Break;
    Inc(Count);
    Pos := TextPos(Source);
  until False;
  BufOrg := PLineRec(Buffer^.At(0))^.StrPos;
  BufEnd := Pos;
  CloseSource;
  SetRanges;
end;

procedure TTextViewer.ReRead(const AName: String);
begin
  if CompUCString(AName, SourceName^) <> Equal then
  begin
{
    DisposeStr(SourceName);
    SourceName := NewStr(AName);
}
    DisposeStrUMB(SourceName);
    SourceName := NewStrUMB(AName);
    DisposeStr(PWindow(Owner)^.Title);
    PWindow(Owner)^.Title := NewStr(AName);
    Longint(Delta) := 0;
    Longint(Cursor) := 0;
    BufOrg := 0;
    BufEnd := 0;
  end;
  FindAllList^.FreeAll;
  DoneSource;
  InitSource;
  IsValid := True;
  InitViewer;
  DrawView;
  PWindow(Owner)^.Frame^.DrawView;
end;

procedure TTextViewer.ReReadScreen;
var
  P: PLineRec;
begin
  P := Buffer^.At(Delta.Y);
  if P = nil then Exit;
  FillBuffer(GetNearestPos(P^.StrPos), False);
  Delta.Y := 0;
  if CurPos.FilePos < BufOrg then
  begin
    CurPos.FilePos := BufOrg;
    CurPos.LinePos := 1;
  end
  else if CurPos.LinePos > CurPos.LineLen then
    CurPos.LinePos := CurPos.LineLen + 1;
  GoToPosition(CurPos.FilePos, CurPos.LinePos);
  UpdatePosition;
end;

procedure TTextViewer.UpdateSourceTime;
var
  L: Longint;
begin
  if not GetFileTime(SourceName^, L) then
    if SourceTime <> -1 then
    begin
      SourceTime := -1;
      InvalidViewerMsgBox('Text viewer', SourceName^);
    end else
  else if L <> SourceTime then
    if TimeChangedMsgBox('Text viewer', SourceName^) = cmOk then
      ReRead(SourceName^)
    else SourceTime := L;
end;

procedure TTextViewer.GetLine(P: PLineRec; var S: String);
begin
  if (P = nil) or (P^.StrPtr = nil) then S := ''
  else
  begin
    S := Detab(P^.StrPtr^, TabSize);
    TrailTrim(S);
  end;
end;

procedure TTextViewer.GetPartLine(P: PLineRec; var S: String);
var
  X: Integer;
begin
  X := Delta.X + Cursor.X + 1;
  GetLine(P, S);
  if X > Length(S) then X := 1;
  while (X > 0) and (S[X] in WordDelims) do Dec(X);
  while (X > 0) and not (S[X] in WordDelims) do Dec(X);
  S := Copy(S, X + 1, 255);
end;

procedure TTextViewer.GetWord(P: PLineRec; var W: String;
  var B, E: Integer);
var
  X, BPos, EPos: Integer;
  S: String;
begin
  W := '';
  B := 0;
  E := 0;
  GetLine(P, S);
  X := Delta.X + Cursor.X + 1;
  if X > Length(S) then Exit;
  EPos := X;
  while (EPos > 1) and (S[EPos] in WordDelims) do Dec(EPos);
  if S[EPos] in WordDelims then Exit;
  BPos := EPos;
  while (BPos > 0) and not (S[BPos] in WordDelims) do Dec(BPos);
  while (EPos <= Length(S)) and not (S[EPos] in WordDelims) do Inc(EPos);
  B := BPos + 1;
  E := EPos;
  W := Copy(S, B, EPos - BPos - 1);
end;

procedure TTextViewer.GetMarkerLine(Pos: Longint; var S: String);
begin
  OpenSource;
  TextSeek(Source, Pos);
  if Eof(Source) then S := ''
  else
  begin
    ReadLine(S);
    S := Detab(S, TabSize);
  end;
  CloseSource;
end;

procedure TTextViewer.GoDownPrim;
begin
  if Delta.Y >= Buffer^.Count then Exit;
  if (Delta.Y + Size.Y >= Buffer^.Count) and
     (BufEnd < SourceSize) then ReadDown(Delta.Y);
  Inc(Delta.Y);
  if Delta.Y + Cursor.Y > Buffer^.Count then Dec(Cursor.Y);
  DrawView;
end;

procedure TTextViewer.GoUpPrim;
var
  I: Integer;
begin
  if Delta.Y = 0 then
  begin
    if BufOrg = 0 then Exit;
    I := Size.Y - 1;
    ReadUp(I);
    Delta.Y := I;
  end;
  Dec(Delta.Y);
  DrawView;
end;

procedure TTextViewer.CursorGoDownPrim;
begin
  if Delta.Y + Cursor.Y >= Buffer^.Count then Exit;
  if Cursor.Y <> Size.Y - 1 then
  begin
    SetCursor(Cursor.X, Cursor.Y + 1);
    if EditOptions and eoHilitCurLine <> 0 then DrawView;
  end
  else GoDownPrim;
end;

procedure TTextViewer.CursorGoUpPrim;
begin
  if Cursor.Y > 0 then
  begin
    SetCursor(Cursor.X, Cursor.Y - 1);
    if EditOptions and eoHilitCurLine <> 0 then DrawView;
  end
  else GoUpPrim;
end;

procedure TTextViewer.GoWhileKeyDown(Key: Byte);
begin
  UpdatePosition;
  if MultiScrolling or
    ((KeyboardOptions and koDisableMultiScroll = 0) and
     (GetShiftState and kbScrollState <> 0)) then Exit;
  repeat
    if (KbdStatus <> Key) and (KbdStatus <> 224) then Exit;
  until KeyPressed;
  repeat
    ClearKbd;
    if (KbdStatus <> Key) and (KbdStatus <> 224) then Exit;
    case Key of
      72: CursorGoUpPrim;
      73: GoPgUpPrim;
      80: CursorGoDownPrim;
      81: GoPgDnPrim;
    end;
    UpdatePosition;
    if KbdDelay <> 0 then Delay(KbdDelay);
  until False;
end;

procedure TTextViewer.GoDown;
begin
  CursorGoDownPrim;
  if (Cursor.Y = Size.Y - 1) and
     ((KbdStatus = 80) or (KbdStatus = 224)) and
     (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
    GoWhileKeyDown(80);
end;

procedure TTextViewer.GoUp;
begin
  CursorGoUpPrim;
  if (Cursor.Y = 0) and
     ((KbdStatus = 72) or (KbdStatus = 224)) and
     (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
    GoWhileKeyDown(72);
end;

procedure TTextViewer.GoPgDnPrim;
var
  SaveFlag: Boolean;
  I: Integer;
begin
  if (BufEnd = SourceSize) and (Delta.Y + Size.Y > Buffer^.Count) then
  begin
    Delta.X := 0;
    SetCursor(0, Buffer^.Count - Delta.Y);
    if EditOptions and (eoHilitCurLine + eoHilitCurColumn) <> 0 then
      DrawView;
  end
  else
  begin
    SaveFlag := DrawFlag;
    DrawFlag := True;
    for I := 0 to Size.Y - 2 do GoDownPrim;
    DrawFlag := SaveFlag;
    DrawView;
  end;
end;

procedure TTextViewer.GoPgUpPrim;
var
  SaveFlag: Boolean;
  I: Integer;
begin
  if (BufOrg = 0) and (Delta.Y = 0) then
  begin
    Delta.X := 0;
    SetCursor(0, 0);
    if EditOptions and (eoHilitCurLine + eoHilitCurColumn) <> 0 then
      DrawView;
  end
  else
  begin
    SaveFlag := DrawFlag;
    DrawFlag := True;
    for I := 0 to Size.Y - 2 do GoUpPrim;
    DrawFlag := SaveFlag;
    DrawView;
  end;
end;

procedure TTextViewer.GoPgDn;
begin
  GoPgDnPrim;
  if ((KbdStatus = 81) or (KbdStatus = 224)) and
     (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
    GoWhileKeyDown(81);
end;

procedure TTextViewer.GoPgUp;
begin
  GoPgUpPrim;
  if ((KbdStatus = 73) or (KbdStatus = 224)) and
     (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
    GoWhileKeyDown(73);
end;

procedure TTextViewer.GoCtrlPgDn;
begin
  if (BufEnd <> SourceSize) or (Delta.Y + Cursor.Y > Buffer^.Count) then
  begin
    ReadLastPortion(SourceSize);
    Delta.Y := -MaxInt;
  end;
  Delta.X := 0;
  if Delta.Y + Size.Y - 1 < Buffer^.Count then
    Delta.Y := Buffer^.Count - Size.Y + 1;
  if Delta.Y < 0 then Delta.Y := 0;
  SetCursor(0, Buffer^.Count - Delta.Y);
  DrawView;
end;

procedure TTextViewer.GoCtrlPgUp;
begin
  if BufOrg <> 0 then FillBuffer(0, True);
  Longint(Delta) := 0;
  Longint(Cursor) := 0;
  DrawView;
end;

procedure TTextViewer.GoRight;
begin
  if Delta.X + Cursor.X >= HScrollBar^.Max then Exit;
  if Cursor.X < Size.X - 1 then
  begin
    SetCursor(Cursor.X + 1, Cursor.Y);
    if EditOptions and eoHilitCurColumn <> 0 then DrawView;
  end
  else
  begin
    Inc(Delta.X);
    DrawView;
  end;
end;

procedure TTextViewer.GoLeft;
begin
  if Delta.X + Cursor.X = 0 then Exit;
  if Cursor.X > 0 then
  begin
    SetCursor(Cursor.X - 1, Cursor.Y);
    if EditOptions and eoHilitCurColumn <> 0 then DrawView;
  end
  else
  begin
    Dec(Delta.X);
    DrawView;
  end;
end;

procedure TTextViewer.GoCtrlRight;
var
  P: PLineRec;
  S: String;
begin
  P := Buffer^.At(Delta.Y + Cursor.Y);
  GetLine(P, S);
  if Delta.X + Cursor.X >= Length(S) then
  begin
    CursorGoDownPrim;
    GoHome;
  end
  else
  begin
    DrawFlag := True;
    if GetShiftState and (kbAltShift + kbCtrlShift) =
      kbAltShift + kbCtrlShift then
    begin
      while (Delta.X + Cursor.X < Length(S)) and
        (S[Delta.X + Cursor.X + 1] in WordDelims) do GoRight;
      while (Delta.X + Cursor.X < Length(S)) and
        not (S[Delta.X + Cursor.X + 1] in WordDelims) do GoRight;
    end
    else
    begin
      while (Delta.X + Cursor.X < Length(S)) and
        not (S[Delta.X + Cursor.X + 1] in WordDelims) do GoRight;
      while (Delta.X + Cursor.X < Length(S)) and
        (S[Delta.X + Cursor.X + 1] in WordDelims) do GoRight;
    end;
    DrawFlag := False;
    DrawView;
  end;
end;

procedure TTextViewer.GoCtrlLeft;
var
  P: PLineRec;
  S: String;
begin
  P := Buffer^.At(Delta.Y + Cursor.Y);
  GetLine(P, S);
  if Delta.X + Cursor.X = 0 then
  begin
    CursorGoUpPrim;
    GoEnd;
  end
  else
  begin
    DrawFlag := True;
    if GetShiftState and (kbAltShift + kbCtrlShift) =
      kbAltShift + kbCtrlShift then
    begin
      if Delta.X + Cursor.X > Length(S) then GoEnd
      else
      begin
        while (Delta.X + Cursor.X > 0) and
          not (S[Delta.X + Cursor.X] in WordDelims) do GoLeft;
        while (Delta.X + Cursor.X > 0) and
          (S[Delta.X + Cursor.X] in WordDelims) do GoLeft;
      end;
    end
    else
    begin
      if Delta.X + Cursor.X > Length(S) then GoEnd;
      while (Delta.X + Cursor.X > 0) and
        (S[Delta.X + Cursor.X] in WordDelims) do GoLeft;
      while (Delta.X + Cursor.X > 0) and
        not (S[Delta.X + Cursor.X] in WordDelims) do GoLeft;
    end;
    DrawFlag := False;
    DrawView;
  end;
end;

procedure TTextViewer.GoEnd;
var
  I: Integer;
  P: PLineRec;
  S: String;
begin
  P := Buffer^.At(Delta.Y + Cursor.Y);
  GetLine(P, S);
  I := Length(S);
  if (I <= Delta.X) or (I >= Delta.X + Size.X) then
  begin
    Dec(I, Size.X - 1);
    if I < 0 then I := 0;
    Delta.X := I;
    DrawView;
  end;
  SetCursor(Length(S) - Delta.X, Cursor.Y);
  if EditOptions and eoHilitCurColumn <> 0 then DrawView;
end;

procedure TTextViewer.GoHome;
begin
  Delta.X := 0;
  SetCursor(0, Cursor.Y);
  DrawView;
end;

procedure TTextViewer.GoCtrlEnd;
begin
  Cursor.Y := Size.Y - 1;
  while Delta.Y + Cursor.Y > Buffer^.Count do Dec(Cursor.Y);
  SetCursor(Cursor.X, Cursor.Y);
  if EditOptions and eoHilitCurLine <> 0 then DrawView;
end;

procedure TTextViewer.GoCtrlHome;
begin
  SetCursor(Cursor.X, 0);
  if EditOptions and eoHilitCurLine <> 0 then DrawView;
end;

function TTextViewer.GetNearestPos(APos: Longint): Longint;
var
  LastPos, NowPos: Longint;
  S: String;
begin
  GetNearestPos := APos;
  NowPos := APos - $FF;
  if NowPos < 0 then NowPos := 0;
  OpenSource;
  repeat
    LastPos := NowPos;
    TextSeek(Source, NowPos);
    if Eof(Source) then
    begin
      CloseSource;
      Exit;
    end;
    if UnixMode then SetUNIXTextMode;
    Readln(Source, S);
    SetDOSTextMode;
    if IOResult <> 0 then
    begin
      CloseSource;
      Exit;
    end;
    NowPos := TextPos(Source);
    if NowPos >= APos then
    begin
      if NowPos = APos then LastPos := NowPos;
      Break;
    end;
  until False;
  CloseSource;
  GetNearestPos := LastPos;
end;

procedure TTextViewer.GoToPosition(APos: Longint; AColumn: Byte);
var
  X, Y, Len: Integer;
  P: PLineRec;
begin
  if APos >= SourceSize then
  begin
    GoCtrlPgDn;
    Exit;
  end;
  if AColumn = 0 then AColumn := 1;
  if (APos < BufOrg) or (APos >= BufEnd) then
    if APos + SourceDelta - $FF > SourceSize then
    begin
      ReadLastPortion(APos);
      Delta.Y := -MaxInt;
    end
    else
    begin
      FillBuffer(GetNearestPos(APos), False);
      Delta.Y := 0;
    end;
  Y := 0;
  repeat
    P := Buffer^.At(Y);
    if P = nil then
    begin
      AColumn := 1;
      Break;
    end;
    if P^.StrPtr = nil then Len := 0
    else Len := Length(P^.StrPtr^);
    if (P^.StrPos = APos) and (AColumn <= Len + 1) then Break;
    if P^.StrPos > APos then
    begin
      if APos + AColumn > P^.StrPos + Len then
      begin
        Inc(Y);
        Continue;
      end;
      if APos + AColumn > P^.StrPos then
      begin
        X := P^.StrPos - APos;
        if X < AColumn then Dec(AColumn, X)
        else AColumn := 1;
      end
      else if Y > 0 then
      begin
        Dec(Y);
        P := Buffer^.At(Y);
        if P^.StrPtr = nil then Len := 0
        else Len := Length(P^.StrPtr^);
        X := APos - P^.StrPos;
        if X + AColumn > Len then AColumn := Len + 1
        else Inc(AColumn, X);
      end
      else AColumn := 1;
      Break;
    end;
    Inc(Y);
  until False;
  if (Buffer^.Count < BufSize) and (BufEnd < SourceSize) then
  begin
    X := 0;
    ReadDown(X);
  end;
  if (Y < Delta.Y) or (Y >= Delta.Y + Size.Y) then
    if (Y + Size.Y > Buffer^.Count) and
       (Buffer^.Count - Size.Y + Byte(BufEnd = SourceSize) >= 0) then
      Delta.Y := Buffer^.Count - Size.Y + Byte(BufEnd = SourceSize)
    else Delta.Y := Y;
  X := AColumn - 1;
  if (X <= Delta.X) or (X >= Delta.X + Size.X) then
  begin
    Dec(X, Size.X - 1);
    if X < 0 then X := 0;
    Delta.X := X;
  end;
  SetCursor(AColumn - Delta.X - 1, Y - Delta.Y);
  DrawView;
end;

procedure TTextViewer.TrackSource(APos: Longint);
begin
  if APos = -1 then TrackPos := CurPos.FilePos
  else TrackPos := APos;
  DrawFlag := True;
  GoToPosition(TrackPos, 1);
  if not NoModalWindows and (Size.Y > 3) and
    (Delta.Y + Cursor.Y >= 2) then
  begin
    Delta.Y := Delta.Y + Cursor.Y - 2;
    Cursor.Y := 2;
    if (Delta.Y + Size.Y > Buffer^.Count) and
       (BufEnd < SourceSize) then ReadDown(Delta.Y);
  end;
  DrawFlag := False;
  DrawView;
  UpdatePosition;
  TrackPos := -1;
  Status := Status or sfNeedRedraw;
end;

function TTextViewer.GetCurLineNum: Integer;
var
  Count: Integer;
  Pos: Longint;
  S: String;
begin
  DrawStatusLine('Calculating the current line number.');
  Count := 0;
  Pos := 0;
  OpenSource;
  TextSeek(Source, 0);
  repeat
    if Eof(Source) or (Pos >= SourceSize) or
       (Pos >= CurPos.FilePos) or (Count > 32632) then Break;
    if UnixMode then SetUNIXTextMode;
    Readln(Source, S);
    SetDOSTextMode;
    Inc(Count);
    if (KbdStatus = 1) and AbortAction then Break;
    Pos := TextPos(Source);
  until False;
  CloseSource;
  GetCurLineNum := Count;
end;

procedure TTextViewer.GoToLineNum(ANum: Longint; APos: Integer);
var
  Count, Pos: Longint;
  S: String;
begin
  DrawStatusLine('Searching for the specified line.');
  Count := 0;
  Pos := 0;
  OpenSource;
  TextSeek(Source, 0);
  repeat
    if Eof(Source) or (Pos >= SourceSize) then Break;
    if UnixMode then SetUNIXTextMode;
    Readln(Source, S);
    SetDOSTextMode;
    Inc(Count);
    if Count = ANum then
    begin
      GoToPosition(Pos, APos);
      CloseSource;
      UpdatePosition;
      Exit;
    end;
    if (KbdStatus = 1) and AbortAction then
    begin
      CloseSource;
      Exit;
    end;
    Pos := TextPos(Source);
  until False;
  CloseSource;
  MessageBox(^C'Line %d not found.', @ANum, mfError + mfOkButton);
end;

procedure TTextViewer.GoToLineNumber;
const
  GoToLineData: String[6] = '';
var
  D: PDialog;
  Control: PView;
  R: TRect;
  L: Longint;
  S: String;
begin
  R.Assign(0, 0, 40, 7);
  D := New(PDialog, Init(R, 'Go to line number'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcSHGoToLineNumber;
    R.Assign(25, 2, 34, 3);
    Control := New(PCInputLine, Init(R, 7, 1, 9999999));
    Insert(Control);
    StandardHistory(Control, GoToLineNumHistoryID);
    R.Assign(2, 2, 25, 3);
    Insert(New(PLabel, Init(R, '~E~nter new line number', Control)));

    StandardButtonRow(D, True);
  end;
  if (Application^.ExecuteDialog(D, @GoToLineData, False) <> cmCancel) and
    Str2Long(GoToLineData, L) then GoToLineNum(L, 1);
end;

procedure TTextViewer.SetPlaceMarker(AChar: Char);
begin
  Places[AChar] := CurPos;
end;

procedure TTextViewer.GoToPlaceMarker(AChar: Char);
var
  SavePos: TPosRec;
begin
  if Places[AChar].LinePos = 0 then Exit;
  SavePos := Places[AChar];
  if SavePos.LinePos > SavePos.LineLen then Inc(SavePos.LineLen)
  else SavePos.LineLen := SavePos.LinePos;
  DrawFlag := True;
  GoToPosition(SavePos.FilePos, SavePos.LineLen);
  while Delta.X + Cursor.X < SavePos.LinePos - 1 do GoRight;
  DrawFlag := False;
  DrawView;
end;

procedure TTextViewer.UpdatePosition;
var
  P: PLineRec;
  L: Longint;
  R: Real;

procedure UpdateScrollBars;
begin
  if HScrollBar^.Value <> Delta.X then
  begin
    HScrollBar^.SetValue(Delta.X);
    HScrollBar^.DrawView;
  end;
  if VScrollBar^.Value <> Indicator^.Percent then
  begin
    VScrollBar^.SetValue(Indicator^.Percent);
    VScrollBar^.DrawView;
  end;
end;

procedure UpdateIndicator;
begin
  Indicator^.Column := CurPos.LinePos;
  if CurPos.LinePos > CurPos.LineLen then
    if CurPos.FilePos + CurPos.LinePos >= SourceSize then
      Indicator^.Character := ^Z
    else Indicator^.Character := ^M
  else Indicator^.Character := P^.StrPtr^[CurPos.LinePos];
  if CurPos.LinePos > CurPos.LineLen then
    L := CurPos.FilePos + CurPos.LineLen
  else L := CurPos.FilePos + CurPos.LinePos - 1;
  if L > SourceSize - 4 + Byte(UnixMode) then L := 100
  else
  begin
    R := L;
    R := R * 100 / SourceSize;
    L := Trunc(R);
  end;
  Indicator^.Percent := L;
  Indicator^.WrapStatus := Status;
  Indicator^.DrawView;
end;

begin
  P := Buffer^.At(Delta.Y + Cursor.Y);
  if P = nil then CurPos.FilePos := SourceSize
  else CurPos.FilePos := P^.StrPos;
  CurPos.LinePos := Delta.X + Cursor.X + 1;
  if (P = nil) or (P^.StrPtr = nil) then CurPos.LineLen := 0
  else CurPos.LineLen := Length(P^.StrPtr^);
  UpdateIndicator;
  UpdateScrollBars;
end;

procedure TTextViewer.SetSelect(ASelOrg, ASelEnd: TPosRec);
begin
  if ASelOrg.LinePos = 0 then ASelOrg.LinePos := 1;
  if ASelEnd.LinePos = 0 then ASelEnd.LinePos := 1;
  if PosCompare(ASelOrg, ASelEnd) = PosGreater then
  begin
    SelOrg := ASelEnd;
    SelEnd := ASelOrg;
    Status := Status or sfSelBack;
  end
  else
  begin
    SelOrg := ASelOrg;
    SelEnd := ASelEnd;
    Status := Status and not sfSelBack;
  end;
  if PosCompare(SelOrg, SelEnd) <> PosEqual then
  begin
    Status := Status or sfHilit;
    EnableCommands(TxtViewCommands + MTCopyCommands);
  end
  else
  begin
    Status := Status and not sfHilit;
    DisableCommands(TxtViewCommands + MTCopyCommands);
  end;
end;

procedure TTextViewer.Unselect;
begin
  SelOrg.FilePos := 0;
  SelOrg.LinePos := 1;
  SelEnd.FilePos := 0;
  SelEnd.LinePos := 1;
  SetSelect(SelOrg, SelEnd);
end;

procedure TTextViewer.ToggleSelection;
begin
  if PosCompare(SelOrg, SelEnd) = PosEqual then
    Status := Status and not sfHilit
  else Status := Status xor sfHilit;
  if Status and sfHilit <> 0 then
    EnableCommands(TxtViewCommands + MTCopyCommands)
  else DisableCommands(TxtViewCommands + MTCopyCommands);
end;

procedure TTextViewer.GetSelection(P: PLineRec; var Lo, Hi: Integer);
begin
  if (P^.StrPos < SelOrg.FilePos) or (P^.StrPos > SelEnd.FilePos) then
  begin
    Lo := 0;
    Hi := 0;
    Exit;
  end;
  if MarkColumns then
  begin
    if SelOrg.LinePos > SelEnd.LinePos then
    begin
      Lo := SelEnd.LinePos;
      Hi := SelOrg.LinePos;
    end
    else
    begin
      Lo := SelOrg.LinePos;
      Hi := SelEnd.LinePos;
    end;
  end
  else
  begin
    if P^.StrPos = SelOrg.FilePos then Lo := SelOrg.LinePos
    else Lo := 1;
    if P^.StrPos = SelEnd.FilePos then Hi := SelEnd.LinePos
    else Hi := 256;
  end;
end;

procedure TTextViewer.GetSelectedPart(APos: Longint; var S: String;
  var Lo, Hi: Integer);
var
  R: TLineRec;
begin
  R.StrPos := APos;
  GetSelection(@R, Lo, Hi);
  if Lo = 0 then S := ''
  else S := Copy(S, Lo, Hi - Lo);
end;

procedure TTextViewer.MarkBlockBegin;
begin
  if PosCompare(CurPos, SelEnd) = PosLess then
    SetSelect(CurPos, SelEnd)
  else SetSelect(CurPos, CurPos);
end;

procedure TTextViewer.MarkBlockEnd;
begin
  if PosCompare(CurPos, SelOrg) = PosGreater then
    SetSelect(SelOrg, CurPos)
  else SetSelect(CurPos, CurPos);
end;

procedure TTextViewer.MarkCurLine;
var
  P: PLineRec;
begin
  P := Buffer^.At(Delta.Y + Cursor.Y);
  if P = nil then Exit;
  SelOrg.FilePos := P^.StrPos;
  SelEnd.FilePos := P^.StrPos;
  SelOrg.LinePos := 1;
  SelEnd.LinePos := 256;
  SetSelect(SelOrg, SelEnd);
end;

procedure TTextViewer.MarkCurWord;
var
  B, E: Integer;
  P: PLineRec;
  S: String;
begin
  P := Buffer^.At(Delta.Y + Cursor.Y);
  GetWord(P, S, B, E);
  if E <= B then Exit;
  SelOrg.FilePos := P^.StrPos;
  SelEnd.FilePos := P^.StrPos;
  SelOrg.LinePos := B;
  SelEnd.LinePos := E;
  SetSelect(SelOrg, SelEnd);
end;

procedure TTextViewer.ToggleWrap(Ctrl: Boolean);
begin
  if GetShiftState and kbCtrlShift <> 0 then Ctrl := True;
  if Ctrl then Status := Status or (sfWrapped + sfWordWrap)
  else Status := (Status xor sfWrapped) and not sfWordWrap;
  ReReadScreen;
end;

function TTextViewer.Search(const Match: String; AOptions: Word): Boolean;
var
  FoundPos, CutLen: Byte;
  Hex, Back, Through: Boolean;
  SaveStatus: Word;
  I, SB, SE: Integer;
  RegExpr: Pointer;
  SaveBufOrg, SaveBufEnd, SPos, BPos, EPos,
  Percent, OldPercent: Longint;
  SaveOrg, SaveEnd: TPosRec;
  P: PLineRec;
  Event: TEvent;
  S, SS, Str, SubS, RGS, PercentStr: String;

procedure GetBufIndex;
begin
  if SPos <= BufOrg then I := 0
  else if SPos >= BufEnd then I := Buffer^.Count - 1
  else
  begin
    I := 0;
    while I < Buffer^.Count do
    begin
      P := Buffer^.At(I);
      if P^.StrPos >= SPos then Break;
      Inc(I);
    end;
  end;
end;

procedure StartBuffer;
begin
  if (SPos >= BufOrg) and ((SPos < BufEnd) or
     ((SPos = BufEnd) and (BufEnd = SourceSize))) then
  else if SPos = SourceSize then ReadLastPortion(SourceSize)
  else FillBuffer(SPos, False);
  GetBufIndex;
end;

procedure GetNextLine;
begin
  if I < 0 then
    if BufOrg <= EPos then
    begin
      Through := True;
      Exit;
    end
    else
    begin
      GiveTicks;
      I := 0;
      ReadUp(I);
      GetBufIndex;
    end
  else if I >= Buffer^.Count then
    if BufEnd >= EPos then
    begin
      Through := True;
      Exit;
    end
    else
    begin
      GiveTicks;
      I := Buffer^.Count;
      ReadDown(I);
      GetBufIndex;
    end;
  P := Buffer^.At(I);
  if P = nil then
  begin
    Through := True;
    Exit;
  end;
  if P^.StrPtr = nil then S := ''
  else S := P^.StrPtr^;
  SPos := P^.StrPos;
  if Back then
  begin
    if SPos < EPos then
    begin
      Through := True;
      Exit;
    end;
    Dec(I);
  end
  else
  begin
    if SPos > EPos then
    begin
      Through := True;
      Exit;
    end;
    Inc(I);
  end;
end;

procedure FindPos;
begin
  if AOptions and frWholeWordsOnly <> 0 then
    FoundPos := WordPos(SubS, Str, WordDelims, Back)
  else if Back then FoundPos := RPos(SubS, Str)
  else FoundPos := Pos(SubS, Str);
  if FoundPos <> 0 then Inc(FoundPos, CutLen - 1);
end;

procedure GetFindAllPos;
begin
  if Back then
    if SPos = 0 then FindAllPos := -2
    else if I >= 0 then
      FindAllPos := PLineRec(Buffer^.At(I))^.StrPos
    else FindAllPos := GetNearestPos(SPos - 1)
  else if I < Buffer^.Count then
    FindAllPos := PLineRec(Buffer^.At(I))^.StrPos
  else if BufEnd = SourceSize then FindAllPos := -2
  else FindAllPos := BufEnd;
end;

begin
  Search := False;
  if Match = '' then Exit;
  if Byte(IsSearchingAll) <= 1 then DrawStatusLine(SearchMsg);
  SubS := Match;
  if AOptions and frCaseSensitive = 0 then UpcaseSt(SubS);
{  if (SubS[1] = '$') and not IncSearch then SubS := Hex2Match(SubS, Hex);}
  if AOptions and frRegExp <> 0 then RegExpr := RegCompile(SubS)
  else RegExpr := nil;
  Back := AOptions and frBackward <> 0;
  if Status and sfHilit = 0 then
    AOptions := AOptions and not frSelectedText;
  if Byte(IsSearchingAll) > 1 then SPos := FindAllPos
  else if AOptions and frSelectedText <> 0 then
  begin
    if Back then SPos := SelEnd.FilePos
    else SPos := SelOrg.FilePos;
    if AOptions and frFromCursor <> 0 then
      if (CurPos.FilePos >= SelOrg.FilePos) and
         (CurPos.FilePos <= SelEnd.FilePos) then SPos := CurPos.FilePos
      else if (Back and (CurPos.FilePos < SelOrg.FilePos)) or
        (not Back and (CurPos.FilePos > SelEnd.FilePos)) then SPos := -1;
  end
  else if AOptions and frFromCursor <> 0 then SPos := CurPos.FilePos
  else if Back then SPos := SourceSize
  else SPos := 0;
  if Byte(IsSearchingAll) > 1 then BPos := FindAllStart
  else
  begin
    BPos := SPos;
    FindAllStart := SPos;
  end;
  if AOptions and frSelectedText <> 0 then
    if Back then EPos := SelOrg.FilePos
    else EPos := SelEnd.FilePos
  else if Back then EPos := 0
  else EPos := SourceSize;
  if Back and IncSearch and (EPos < IncSearchPos) then
    EPos := IncSearchPos;
  FoundPos := 0;
  OldPercent := 0;
  SaveBufOrg := BufOrg;
  SaveBufEnd := BufEnd;
  Through := False;
  if SPos <> -1 then
  begin
    StartBuffer;
    repeat
      GetNextLine;
      if Through then Break;
      if S <> '' then
      begin
        Str := Detab(S, TabSize);
        TrailTrim(Str);
        if AOptions and frSelectedText <> 0 then
        begin
          GetSelectedPart(SPos, Str, SB, SE);
          CutLen := SB;
          if Back and (SE <= Length(Str)) then Str[0] := Char(SE - 1);
        end
        else CutLen := 1;
        if (SPos = CurPos.FilePos) and
           (AOptions and frFromCursor <> 0) then
          if Back and (Delta.X + Cursor.X + 1 < Length(Str) + CutLen) then
            if Delta.X + Cursor.X < CutLen then Str := ''
            else Str[0] := Char(Delta.X + Cursor.X + 1 - CutLen)
          else if not Back and
            (Delta.X + Cursor.X + 1 +
              Byte(not IsSearchingFrom) > CutLen) then
          begin
            Delete(Str, 1,
              Delta.X + Cursor.X + 1 + Byte(not IsSearchingFrom) - CutLen);
            CutLen := Delta.X + Cursor.X + 1 + Byte(not IsSearchingFrom);
          end;
        if Str <> '' then
        begin
          if (AOptions and frCaseSensitive = 0) {and
             ((Match[1] <> '$') or not Hex)} then UpcaseSt(Str);
          if (AOptions and frRegExp <> 0) and (RegExpr <> nil) then
          begin
            if Back then RGS := RegSearchBack(RegExpr, Str)
            else RGS := RegSearch(RegExpr, Str);
            if RGS <> '' then SubS := RGS;
          end;
          FindPos;
        end;
      end;
      if (KbdStatus = 1) and AbortAction then
      begin
        FoundPos := 0;
        FindAllPos := -1;
        IsSearchingAll := True;
        Break;
      end;
      if FoundPos <> 0 then Break;
      if (Back and (SPos - $FF <= EPos)) or
         (not Back and (SPos + $FF >= EPos)) then Percent := 100
      else if Back then Percent :=
        Trunc(((BPos - SPos) / (BPos - EPos)) * 100)
      else Percent :=
        Trunc(((SPos - BPos) / (EPos - BPos)) * 100);
      if Percent <> OldPercent then
      begin
        OldPercent := Percent;
        FormatStr(PercentStr, ' %d ', Percent);
        PercentStr[Length(PercentStr)] := '%';
        SS := SearchMsg;
        SS[Length(SS)] := ':';
        LogEvent := 0;
        DrawStatusLine(SS + PercentStr);
      end;
    until False;
  end;
  RegFree(RegExpr);
  if FoundPos = 0 then
  begin
    if (BufOrg <> SaveBufOrg) or (BufEnd <> SaveBufEnd) then
      FillBuffer(SaveBufOrg, False);
    if not IsSearchingAll and not NoSearchMsg then
      SearchStringNotFoundMsgBox
    else IsSearchingAll := False;
  end
  else
  begin
    if IsSearchingAll then
    begin
      GetFindAllPos;
      FindAllList^.Insert(Pointer(SPos));
      Byte(IsSearchingAll) := 2;
    end
    else
    begin
      SaveStatus := Status;
      Status := Status or sfHilit;
      SaveOrg := SelOrg;
      SaveEnd := SelEnd;
      SelOrg.FilePos := SPos;
      SelEnd.FilePos := SPos;
      SelOrg.LinePos := FoundPos;
      SelEnd.LinePos := FoundPos + Length(SubS);
      SelOrg.LineLen := Length(S);
      Event.What := evCommand;
      Event.Command := cmCtrlQB;
      HandleEvent(Event);
      while (Cursor.X + Length(SubS) > Size.X) and (Cursor.X > 0) do
      begin
        Inc(Delta.X);
        Dec(Cursor.X);
      end;
      DrawView;
      UpdatePosition;
      Status := SaveStatus or sfNeedRedraw;
      SelOrg := SaveOrg;
      SelEnd := SaveEnd;
    end;
    Search := True;
  end;
end;

procedure TTextViewer.Find(All: Boolean);
var
  DoShow: Boolean;
  B, E: Integer;
  C: Word;
  SaveBufOrg, SaveBufEnd: Longint;
begin
  if EditOptions and eoFindTextAtCursor <> 0 then
    GetWord(PLineRec(Buffer^.At(Delta.Y + Cursor.Y)),
      SearchData.MatchStr, B, E)
  else SearchData.MatchStr := HistoryStr(FindHistoryID, 0);
  SaveBufOrg := BufOrg;
  SaveBufEnd := BufEnd;
  C := Application^.ExecuteDialog(LoadFindDialog(All, False,
    frSelectedText * Byte(Status and sfHilit = 0)), @SearchData, False);
  if C = cmOk then Search(SearchData.MatchStr, SearchData.Options)
  else if C = cmYes then
  begin
    FindAllList^.FreeAll;
    FindAllPos := 0;
    FindAllData := SearchData;
    FindAllData.Options := FindAllData.Options and not frSelectedText;
    IsSearchingAll := True;
    repeat until not Search(SearchData.MatchStr, SearchData.Options);
    if (BufOrg <> SaveBufOrg) or (BufEnd <> SaveBufEnd) then
      FillBuffer(SaveBufOrg, False);
    DoShow := FindAllPos <> -1;
    if DoShow then FindAllDlg
    else FindAllList^.FreeAll;
  end;
end;

procedure TTextViewer.FindAllDlg;
var
  P: Pointer;
begin
  P := @Self;
  if (Application^.ExecuteDialog(
    ViewerFindAllDialog(FindAllList^.Count, False),
      @P, False) <> cmCancel) and (FindAllList^.Count <> 0) then
  begin
    GoToPosition(Longint(P), 1);
    UpdatePosition;
    if FindAllData.Options and frBackward <> 0 then Cursor.X := 255
    else Cursor.X := -1;
    if not Search(
      FindAllData.MatchStr, FindAllData.Options or frFromCursor) then
        Cursor.X := 0;
  end;
end;

procedure TTextViewer.InitIncSearch;
begin
  IncSearchStr := '';
  IncSearchPos := CurPos.FilePos;
  IncSearchOpt := (SearchData.Options or frFromCursor) and
    not (frWholeWordsOnly + frRegExp);
  if Status and sfHilit = 0 then
    IncSearchOpt := IncSearchOpt and not frSelectedText;
  IncSearch := True;
  SetState(sfFocused, True);
end;

procedure TTextViewer.DoneIncSearch;
begin
  if IncSearchStr <> '' then
    SearchData.MatchStr := IncSearchStr;
  DrawView;
  Status := Status and not sfNeedRedraw;
  IncSearch := False;
  SetState(sfFocused, True);
end;

procedure TTextViewer.DoIncSearch(C: Char);
begin
  if C = #27 then
  begin
    DoneIncSearch;
    Exit;
  end;
  if C = #9 then C := #32;
  if C = #8 then
  begin
    if IncSearchStr <> '' then Dec(IncSearchStr[0]);
    if IncSearchStr = '' then
    begin
      DoneIncSearch;
      Exit;
    end;
    IncSearchOpt := IncSearchOpt or frBackward;
    NoSearchMsg := True;
  end
  else
  begin
    if C = ^B then IncSearchOpt := IncSearchOpt or frBackward
    else IncSearchOpt := IncSearchOpt and not frBackward;
    if not (C in [^B, ^L]) then
    begin
      if Length(IncSearchStr) = IncSearchLen then
      begin
        SearchStringTooLongMsgBox;
        Exit;
      end;
      Inc(IncSearchStr[0]);
      IncSearchStr[Length(IncSearchStr)] := C;
      IsSearchingFrom := True;
      NoSearchMsg := True;
    end;
  end;
  if not Search(IncSearchStr, IncSearchOpt) then
    if C = #8 then
    begin
      Inc(Cursor.X, Length(IncSearchStr));
      if not Search(IncSearchStr, IncSearchOpt) then
        Dec(Cursor.X, Length(IncSearchStr));
    end
    else if not (C in [^B, ^L]) then Dec(IncSearchStr[0]);
  IsSearchingFrom := False;
  NoSearchMsg := False;
end;

procedure TTextViewer.CopyToClipboard;
var
  SaveCount, SB, SE: Integer;
  SaveOrg, SaveEnd: TPosRec;
  Pos: Longint;
  P: PLineRec;
  S: String;
begin
  if DiskClipStream = nil then Exit;
  DrawClipCopyStatus;
  SetExpandClipAreaFlag;
  SaveCount := ClipLines^.Count;
  SaveOrg := SelOrg;
  SaveEnd := SelEnd;
  if Status and sfHilit = 0 then
  begin
    P := Buffer^.At(Delta.Y + Cursor.Y);
    GetLine(P, S);
    SelOrg.FilePos := CurPos.FilePos;
    SelOrg.LinePos := 1;
    SelEnd.FilePos := CurPos.FilePos;
    SelEnd.LinePos := Length(S) + 1;
  end;
  Pos := SelOrg.FilePos;
  OpenSource;
  if Pos < SourceSize then TextSeek(Source, Pos);
  while not Eof(Source) and
    (Pos < SourceSize) and (Pos <= SelEnd.FilePos) do
  begin
    ReadLine(S);
    S := Detab(S, TabSize);
    TrailTrim(S);
    GetSelectedPart(Pos, S, SB, SE);
    PutClipLine(S);
    if ClipOverflow or ((KbdStatus = 1) and AbortAction) then Break;
    Pos := TextPos(Source);
  end;
  CloseSource;
  SetOrExpandClipArea(SaveCount, Length(S) + 1);
  if MarkColumns then SetArea(ClipArea, ClipArea^.KB, ClipArea^.PB,
    ClipArea^.KK, SelEnd.LinePos - SelOrg.LinePos + 1);
  SelOrg := SaveOrg;
  SelEnd := SaveEnd;
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure TTextViewer.WriteBlockToFile(NamePtr: PString; Append: Boolean);
var
  C: Word;
  SB, SE: Integer;
  Pos: Longint;
  FName: FNameStr;
  F: lText;
  S: String;

procedure WriteBlock;
begin
  lAssignText(F, FName);
  if Append then
  begin
    System.Append(F.T);
    if IOResult <> 0 then Rewrite(F.T);
  end
  else Rewrite(F.T);
  if IOResult <> 0 then
  begin
    CouldNotOpenMsgBox(FName);
    Exit;
  end;
  if NotAccessible(TextRec(F.T).Handle) then
  begin
    Close(F.T);
    InOutRes := 0;
    FileIsDeviceMsgBox(FName);
    Exit;
  end;
  Pos := SelOrg.FilePos;
  OpenSource;
  if Pos < SourceSize then TextSeek(Source, Pos);
  while not Eof(Source) and
    (Pos < SourceSize) and (Pos <= SelEnd.FilePos) do
  begin
    ReadLine(S);
    if EditOptions and eoUseTabs = 0 then S := Detab(S, TabSize);
    TrailTrim(S);
    GetSelectedPart(Pos, S, SB, SE);
    if UnixMode then SetUNIXTextMode;
    Writeln(F.T, S);
    SetDOSTextMode;
    if IOResult <> 0 then
    begin
      CouldNotWriteMsgBox(FName);
      Break;
    end;
    if (KbdStatus = 1) and AbortAction then Break;
    Pos := TextPos(Source);
  end;
  CloseSource;
  Close(F.T);
  InOutRes := 0;
end;

begin
  if Status and sfHilit = 0 then Exit;
  if NamePtr <> nil then FName := NamePtr^
  else
  begin
    if Append then S := 'Append' else S := 'Write';
    FName := '';
    if Application^.ExecuteDialog(
      New(PFileDialog, Init('*.*', S + ' block to file',
        '~W~rite block to', fdOkButton + fdHelpButton, HistoryID)),
        @FName, False) = cmCancel then Exit;
  end;
  if CompUCString(FName, SourceName^) = Equal then
  begin
    CannotWriteToItselfMsgBox;
    Exit;
  end;
  if (NamePtr = nil) and not Append and ThisFileExists(FName) then
  begin
    C := AppendMessageBox(FName);
    case C of
      cmYes: Append := True;
      cmCancel: Exit;
    end;
  end;
  DrawWriteDataStatus(FName);
  WriteBlock;
  UpdateFiles(FName);
end;

procedure TTextViewer.SetXLATTable(const Name: FNameStr; Prompt: Boolean);
var
  B, C: Boolean;
begin
  if Name <> '' then B := ReadConvertTable(XLATTable, Name, C)
  else B := GetConvertTable(XLATTable, Prompt, C);
  if B then Status := Status or sfXLAT
  else if C then Status := Status and not sfXLAT;
  XLATKind := xAlt;
  ReReadScreen;
  PWindow(Owner)^.Frame^.DrawView;
end;

procedure TTextViewer.ClearXLATTable;
begin
  Status := Status and not sfXLAT;
  XLATKind := xAlt;
  ReReadScreen;
  PWindow(Owner)^.Frame^.DrawView;
end;

procedure TTextViewer.GetLocalFields;
var
  CS: CommentStr;
  EO: Longint;
  TS, MW: Byte;
  WD: TCharSet;
  NO: Word;
  IXN, OXN, MN, SN: PString;
  PR: PPrnRec;
  SO: Boolean;
begin
  HelpName := nil;
  GetComment(SourceName^, CS, EO, TS, MW, WD, NO,
    HelpName, IXN, OXN, MN, SN, PR, SO);
end;

constructor TTextWindow.Init(Bounds: TRect; const AName: FNameStr);
var
  Control: PScrollBar;
  IControl: PViewIndicator;
  R: TRect;
begin
  Inherited Init(Bounds, AName, WindowNumAvail);
  Options := Options or ofTileable;

  GetExtent(R);
  Inc(R.A.X, 33); Dec(R.B.X, 2); R.A.Y := R.B.Y - 1;
  Control := New(PScrollBar, Init(R));
  Insert(Control);

  GetExtent(R);
  Inc(R.A.X, 4); R.A.Y := R.B.Y - 1; R.B.X := R.A.X + 28;
  IControl := New(PViewIndicator, Init(R));
  IControl^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(IControl);

  GetExtent(R);
  R.Grow(-1, -1);
  Viewer := New(PTextViewer, Init(
    R, Control, StandardScrollBar(sbVertical), AName, IControl));
  Insert(Viewer);
end;

constructor TTextWindow.Load(var S: TStream);
begin
  Inherited Load(S);
  GetSubViewPtr(S, Viewer);
  with Viewer^ do if IsValid then
  begin
    TrackPos := -1;
    FillBuffer(BufOrg, False);
    if Delta.Y + Cursor.Y > Buffer^.Count then GoCtrlPgDn;
    UpdatePosition;
  end;
end;

procedure TTextWindow.ChangeBounds(var Bounds: TRect);
var
  R: TRect;
begin
  TWindow.ChangeBounds(Bounds);
  if ((Size.X = Viewer^.Size.X) and (Size.X < Owner^.Size.X)) or
     ((Size.Y = Viewer^.Size.Y) and (Size.Y < Owner^.Size.Y)) then
  begin
    GetExtent(R);
    R.Grow(-1, -1);
    Viewer^.Locate(R);
  end;
end;

procedure TTextWindow.Close;
var
  I: Integer;
  X, Y: String[15];
  S: String;
begin
  with Viewer^ do if Length(SourceName^) <= 222 then
  begin
    S := 'View  ' + SourceName^;
    if HistoryIndex(ReopenHistoryID, S) = -1 then
    begin
      Str(CurPos.LinePos, X);
      Str(CurPos.FilePos:10, Y);
      S := S + #$FF + X + #$FF + Y + #$FF#$FF;
      if Self.Size.X = Viewer^.Size.X then
        FillChar(S[Length(S) + 1], 8, OpenWideFiller)
      else Move(Self.Origin, S[Length(S) + 1], 8);
      Inc(S[0], 8);
      if Length(S) < 254 - SizeOf(TPlaces) - 8 then
      begin
        S := S + #$FF'PLACES';
        Move(Places, S[Length(S) + 1], SizeOf(TPlaces));
        Inc(S[0], SizeOf(TPlaces));
      end;
      HistoryAdd(ReopenHistoryID, S, False);
      if Status and sfHistLocked <> 0 then
      begin
        I := HistoryIndex(ReopenHistoryID, S);
        if I <> -1 then
          Byte(PHistoryRec(HistoryList^.At(I))^.Lock) := HistLock;
      end;
    end;
  end;
  Inherited Close;
end;

function TTextWindow.GetPalette: PPalette;
const
  P: String[Length(CViewerWindow)] = CViewerWindow;
begin
  GetPalette := @P;
end;

function TTextWindow.GetTitle(MaxSize: Integer): TTitleStr;
var
  I: Integer;
  S, C: String;
begin
  FormatStr(S, ' (%d bytes)', Viewer^.SourceSize);
  if Viewer^.SourceSize = 1 then System.Delete(S, Length(S) - 1, 1);
  C := 'Text view: ';
  if Viewer^.UnixMode then C := Concat('UNIX ', C);
  if Viewer^.Status and sfXLAT <> 0 then
    if Viewer^.XLATKind = xKoi then C := Concat('KOI ', C)
    else if Viewer^.XLATKind = xWin then C := Concat('WIN ', C);
  I := MaxSize - Length(C) - Length(S) + 2;
  if I < 12 then I := 12;
  GetTitle := Concat(C, TrimmedName(Title^, Byte(I)), S);
end;

procedure TTextWindow.SizeLimits(var Min, Max: TPoint);
begin
  Inherited SizeLimits(Min, Max);
  Min.X := 38;
end;

procedure TTextWindow.Store(var S: TStream);
begin
  Inherited Store(S);
  PutSubViewPtr(S, Viewer);
end;

procedure TTextWindow.Zoom;
var
  CtrlDown, Full, Wide: Boolean;
  R: TRect;
begin
  CtrlDown := GetShiftState and
    (kbCtrlShift + kbLeftShift + kbRightShift) <> 0;
  Full := Longint(Size) = Longint(Owner^.Size);
  Wide := Longint(Size) = Longint(Viewer^.Size);
  if not CtrlDown or not Full then TWindow.Zoom;
  if CtrlDown or Wide then
  begin
    GetExtent(R);
    if Wide then R.Grow(-1, -1);
    Viewer^.Locate(R);
  end;
end;

end.