{$I-,F+,O+,X+}
unit HexView;

interface

uses Objects, Drivers, Views, LongView, FindDlg, LFN;

type
  TLongPoint = record
    X: Byte;
    Y: Longint;
  end;

  TLongPlaces = Array['0'..'9'] of Longint;

  PHexViewIndicator = ^THexViewIndicator;
  THexViewIndicator = object(TView)
    Position: Longint;
    Percent: Byte;
    Modified: Boolean;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    function GetMouseShape(var Event: TEvent): Char; virtual;
    function GetMousePos(X: Integer): Byte;
  end;

  PHexViewer = ^THexViewer;
  THexViewer = object(TView)
    Indicator: PHexViewIndicator;
    HScrollBar: PScrollBar;
    VScrollBar: PLongScrollBar;
    Source: lFile;
{ storable fields }
    SourceName: PString;
    Delta: TLongPoint;
    BufOrg: Longint;
    SelOrg: Longint;
    SelEnd: Longint;
    Places: TLongPlaces;
    Status: Word;
    HistLock: Byte;
{ non-storable fields }
    SourceSize: Longint;
    SourceTime: Longint;
    SourceAttr: Word;
    Buffer: PByteArray;
    ModifiedBuffer: PWordArray;
    BufBytes: Word;
    CurPos: Longint;
    FindAllList: PCollection;
    FindAllStart: Longint;
    FindAllPos: Longint;
    FindAllData: TSearchData;
    IsSearchingAll: Boolean;
    IsReplacing: Boolean;
    NoSearchMsg: Boolean;
    IsValid: Boolean;
    DrawFlag: Boolean;
    Open: Boolean;
{Added 2006.01.10 }
    UpdateTicks: Word;
    constructor Init(var Bounds: TRect;
      AHScrollBar: PScrollBar; AVScrollBar: PLongScrollBar;
      const AName: FNameStr; AIndicator: PHexViewIndicator);
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
    procedure InitViewer;
    procedure InitModifiedBuffer;
    procedure DoneModifiedBuffer;
    procedure FillBuffer(Pos: Longint);
    procedure ReadLastPortion;
    procedure ReRead(const AName: String);
    procedure UpdateSourceTime;
    procedure GetLine(APos: Longint; var S: String);
    procedure GetPartLine(APos: Longint; var S: String);
    procedure GetWord(APos: Longint; var W: String; var B, E: Integer);
    procedure GetMarkerLine(Pos: Longint; var S: String);
    procedure JustifyX;
    procedure JustifyY;
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
    procedure GoOpposite;
    procedure GoToPosition(APos: Longint);
    procedure GoToLineNumber;
    procedure SetPlaceMarker(AChar: Char);
    procedure GoToPlaceMarker(AChar: Char);
    procedure UpdatePosition;
    procedure SetSelect(ASelOrg, ASelEnd: Longint);
    procedure Unselect;
    procedure ToggleSelection;
    procedure GetSelection(APos: Longint; var Lo, Hi: Integer);
    procedure GetSelectedPart(APos: Longint; var S: String;
      var Lo, Hi: Integer);
    procedure MarkBlockBegin;
    procedure MarkBlockEnd;
    procedure MarkCurLine;
    procedure MarkCurWord;
    function Search(const Match: String; AOptions: Word): Boolean;
    procedure Find(All: Boolean);
    procedure FindAllDlg;
    procedure ReplaceDlg;
    procedure CopyToClipboard;
    procedure WriteBlockToFile(NamePtr: PString; Append: Boolean);
    function Modify(AChar: Char): Boolean;
    procedure Save;
    function SaveOnExit: Word;
  end;

  PHexWindow = ^THexWindow;
  THexWindow = object(TWindow)
    Viewer: PHexViewer;
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
  CViewer           = #6#7#8#9#10;
  CViewerWindow     = #175#176#177#178#179#180#181#182#183#184;

  CCurCol           = 201;

implementation

uses Dos, CNCrt, Memory, WinIcons, Menus, Dialogs, App, MsgBox, StdDlg,
  HistList, History, Swaps, ClipPrim, DirPrim, DosTools, Keyboard,
  EditCmnd, EditFile, EditMsg, ViewFind, ViewPop, PlcHist, CNInputs,
  HeapUMB, Disks, TPString, Consts, Commands, Defaults;

const
  BufSize: Word     = $1000;

  sfCtrlKPressed    = $0001;
  sfCtrlQPressed    = $0002;
  sfHilit           = $0004;
  sfSelBack         = $0008;
  sfNeedRedraw      = $0010;
  sfModified        = $0020;
  sfCursorAtHex     = $0040;
  sfHistLocked      = $0100;

  HexViewerCommands =
    [cmSave, cmUpdateASCII, cmUpdateHex, cmFind, cmReplace,
     cmFindAll, cmShowAllFound, cmSearchAgain, cmGoToLine];
  XViewCommands =
    [cmCopy, cmCtrlKW, cmCtrlQB, cmCtrlQK];

  Pattern: Array[8..77] of Byte =
    ($80, 0, $7F, $81, 1, $7F, $82, 2, $7F, $83, 3, $7F, $7F, $7F,
     $84, 4, $7F, $85, 5, $7F, $86, 6, $7F, $87, 7, $7F, $7F, $7F,
     $88, 8, $7F, $89, 9, $7F, $8A, $A, $7F, $8B, $B, $7F, $7F, $7F,
     $8C, $C, $7F, $8D, $D, $7F, $8E, $E, $7F, $8F, $F, $7F,
     0, 1, 2, 3, 4, 5, 6, 7, 8, 9, $A, $B, $C, $D, $E, $F);
  HexPos: Array[$0..$F] of Byte =
    (8, 11, 14, 17, 22, 25, 28, 31, 36, 39, 42, 45, 50, 53, 56, 59);

procedure StringConvert(var SStr, DStr; Num: Longint);
begin
asm
	jmp @Start
@Conv:  db '0123456789ABCDEF'
@Str:   mov ah,al
	and al,0fh
SEGCS   xlat
	xchg ah,al
	and al,0f0h
	shr al,1
	shr al,1
	shr al,1
	shr al,1
SEGCS   xlat
	retn
@Start: push ds
	lds si,SStr
	mov al,Byte ptr ds:[si]
	inc si
	les di,DStr
	mov byte ptr es:[di],78
	inc di
	mov bx, OFFSET @Conv
	mov ax,word ptr Num[2]
	xchg ah,al
	push ax
	call @Str
	xchg ah,al
	stosb
	pop ax
	mov al,ah
	call @Str
	stosw
	mov ax,word ptr Num[0]
	xchg ah,al
	push ax
	call @Str
	stosw
	pop ax
	mov al,ah
	call @Str
	stosw
	mov al,20h
	stosb
	mov cx,4
@l1:    push cx
	mov cx,4
@l0:    lodsb
	call @Str
	stosw
	mov al,20h
	stosb
	loop @l0
	mov ax,20b3h {³}
	stosw
	pop cx
	loop @l1
	dec di
	dec di
	sub si,16
	mov cl,16 {Count}
rep     movsb
	pop ds
end;
end;

procedure THexViewIndicator.Draw;
var
  C: Char;
  Color: Byte;
  Params: Array[0..1] of Longint;
  IS: String[15];
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
  if Modified then MoveChar(B, '', Color, 1);
  Params[0] := Position;
  Params[1] := Percent;
  IS := ' %07x %d%% ';
  if Position > $FFFFFFF then IS[4] := '8';
  FormatStr(S, IS, Params);
  MoveStr(B[3], S, Color);
  WriteLine(0, 0, Size.X, 1, B);
end;

function THexViewIndicator.GetPalette: PPalette;
const
  P: String[3] = #1#2#3;
begin
  GetPalette := @P;
end;

const
  ipNo = 0;
  ipModified = 1;
  ipAddr = 2;

function THexViewIndicator.GetMousePos(X: Integer): Byte;
begin
  if Modified and (X = 0) then GetMousePos := ipModified
  else GetMousePos := ipAddr;
end;

procedure THexViewIndicator.HandleEvent(var Event: TEvent);
var
  B: Byte;
  Mouse: TPoint;
begin
  Inherited HandleEvent(Event);
  if (Event.What = evMouseDown) and MouseInView(Event.Where) then
  begin
    MakeLocal(Event.Where, Mouse);
    B := GetMousePos(Mouse.X);
    if B = ipModified then Event.Command := cmSave
    else if B = ipAddr then Event.Command := cmGoToLine
    else Exit;
    Message(Application, evCommand, Event.Command, nil);
    Event.What := evNothing;
  end;
end;

procedure THexViewIndicator.SetState(AState: Word; Enable: Boolean);
begin
  Inherited SetState(AState, Enable);
  DrawView;
end;

function THexViewIndicator.GetMouseShape(var Event: TEvent): Char;
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
    if B = ipModified then C := ''
    else if B = ipAddr then C := '';
  end;
  GetMouseShape := C;
end;

constructor THexViewer.Init(var Bounds: TRect;
  AHScrollBar: PScrollBar; AVScrollBar: PLongScrollBar;
  const AName: FNameStr; AIndicator: PHexViewIndicator);
begin
  Inherited Init(Bounds);
  Cursor.X := HexPos[0];
  Options := Options or ofSelectable;
  EventMask := EventMask or evBroadcast;
  GrowMode := gfGrowHiX + gfGrowHiY;
  HScrollBar := AHScrollBar;
  VScrollBar := AVScrollBar;
  Indicator := AIndicator;
{
  SourceName := NewStr(AName);
  GetMem(Buffer, BufSize);
}
  SourceName := NewStrUMB(AName);
  GetMemUMB(Buffer, BufSize);
  FindAllList := New(PSwapLinesCollection, Init(8, 8));
  InitSource;
  if IsValid then InitViewer;
end;

constructor THexViewer.Load(var S: TStream);
begin
  Inherited Load(S);
  GetPeerViewPtr(S, HScrollBar);
  GetPeerViewPtr(S, VScrollBar);
  GetPeerViewPtr(S, Indicator);
{  SourceName := S.ReadStr;}
  SourceName := ReadStrUMB(@S);
  S.Read(Delta, SizeOf(Delta) + SizeOf(BufOrg) + SizeOf(SelOrg) +
    SizeOf(SelEnd) + SizeOf(Places) + SizeOf(Status));
  if Status and sfHistLocked <> 0 then S.Read(HistLock, SizeOf(HistLock));
{  GetMem(Buffer, BufSize);}
  GetMemUMB(Buffer, BufSize);
  FindAllList := New(PSwapLinesCollection, Init(8, 8));
  InitSource;
end;

destructor THexViewer.Done;
begin
  DoneSource;
  Dispose(FindAllList, Done);
{
  FreeMem(Buffer, BufSize);
  DisposeStr(SourceName);
}
  FreeMemUMB(Buffer, BufSize);
  DisposeStrUMB(SourceName);
  Inherited Done;
end;

procedure THexViewer.ChangeBounds(var Bounds: TRect);
begin
  SetBounds(Bounds);
  HScrollBar^.SetParams(HScrollBar^.Value,
    0, 78 - Size.X, Size.X - 1, HScrollBar^.ArStep);
  VScrollBar^.SetParams(VScrollBar^.Value,
    0, SourceSize shr 4, Size.Y - 1, VScrollBar^.ArStep);
  if ((Delta.Y + Size.Y) shl 4 > BufOrg + BufBytes) and
     (BufOrg + BufBytes <> SourceSize) then
    FillBuffer(Delta.Y shl 4);
  DrawView;
end;

procedure THexViewer.Draw;
var
  Color, SelColor, ModColor, CurColor, StrPos: Byte;
  I, X, Lo, Hi, BP, EP, Len: Integer;
  ModBufWord: Word;
  L: Longint;
  B: TDrawBuffer;
  S, P, HS: String;

procedure ModHilitBuf;
var
  C: Word;
begin
  for C := 0 to $F do
  begin
    if ModBufWord and (1 shl C) <> 0 then
    begin
      BP := HexPos[C] - Delta.X;
      if BP = -1 then MoveChar(B, #0, ModColor, 1)
      else if BP >= 0 then MoveChar(B[BP], #0, ModColor, 2);
      MoveChar(B[62 - Delta.X + C], #0, ModColor, 1);
    end;
  end;
end;

procedure HilitBuf;
begin
  BP := HexPos[Lo - 1] - Delta.X;
  if BP < 0 then BP := 0;
  EP := HexPos[Hi - 1] - Delta.X;
  if EP >= -1 then MoveChar(B[BP], #0, SelColor, EP - BP + 2);
  MoveChar(B[61 + Lo - Delta.X], #0, SelColor, Hi - Lo + 1);
end;

begin
  if DrawFlag then Exit;
  Color := GetColor(1);
  SelColor := GetColor(2);
  ModColor := GetColor(3);
  CurColor := GetColor(5);
  for I := 0 to Size.Y - 1 do
  begin
    Lo := 0;
    MoveChar(B, ' ', Color, Size.X);
    L := (Delta.Y + I) shl 4;
    if L <= SourceSize then
    begin
      GetLine(L, P);
      if L <= SourceSize - 16 then StringConvert(P, S, L)
      else
      begin
	FormatStr(S, '%07x', L);
	S := S +
	  '             ³             ³             ³             ' + P;
	for StrPos := 0 to 15 do
	  if L + StrPos < SourceSize then
	  begin
	    HS := HexB(Byte(P[StrPos + 1]));
	    Move(HS[1], S[HexPos[StrPos] + 1], 2);
	  end;
      end;
      MoveStr(B, Copy(S, Delta.X + 1, Size.X), Color);
      if (I = Cursor.Y) and (EditOptions and eoHilitCurLine <> 0) then
	MoveChar(B, #0, CurColor, Size.X);
      if (Status and sfModified <> 0) and (L < SourceSize) then
      begin
	ModBufWord := ModifiedBuffer^[(L - BufOrg) shr 4];
	if ModBufWord <> 0 then ModHilitBuf;
      end;
      if Status and sfHilit <> 0 then
      begin
	GetSelection(L, Lo, Hi);
	if (Lo > 0) and (Hi >= Lo) then HilitBuf;
      end;
    end;
    if (EditOptions and eoHilitCurColumn <> 0) and
       (Cursor.X >= 0) and (Cursor.X < MaxViewWidth) and
       ((Lo = 0) or (Pattern[Delta.X + Cursor.X] and $7F < Lo - 1) or
	(Pattern[Delta.X + Cursor.X] and $7F >= Hi)) then
{ Added 01.22.01 }
    begin
      MoveChar(B[Cursor.X], #0, Byte(Application^.GetPalette^[cCurCol]), 1);
      if Status and sfCursorAtHex <> 0 then
	MoveChar(B[62 - Delta.X + Pattern[Delta.X + Cursor.X] and $7F], #0,
	  Byte(Application^.GetPalette^[cCurCol]), 1)
      else
      begin
	MoveChar(B[Cursor.X], #0, Byte(Application^.GetPalette^[cCurCol]), 1);
	X := HexPos[Pattern[Delta.X + Cursor.X] and $7F] - Delta.X;
	if X = -1 then MoveChar(B[0], #0,
	  Byte(Application^.GetPalette^[cCurCol]), 1)
	else if X >= 0 then MoveChar(B[X], #0,
	  Byte(Application^.GetPalette^[cCurCol]), 2);
      end;
    end;

    WriteLine(0, I, Size.X, 1, B);
  end;
end;

function THexViewer.GetHelpCtx: Word;
var
  B: Boolean;
  L: Longint;
begin
  if State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else if GetShiftState and kbAltShift <> 0 then
    GetHelpCtx := hcAltHexViewer
  else if Status and sfCtrlKPressed <> 0 then
    GetHelpCtx := hcHexViewerCtrlKPressed
  else if Status and sfCtrlQPressed <> 0 then
    GetHelpCtx := hcHexViewerCtrlQPressed
  else GetHelpCtx := hcHexViewer;

{Added 2006.01.10 }
  if (MemW[$40:$6C] - UpdateTicks >= 50) then
  begin
    UpdateTicks := MemW[$40:$6C];
    if not GetFileTime(SourceName^, L) then UpdateSourceTime
    else if L <> SourceTime then
      if Status and sfModified <> 0 then UpdateSourceTime
      else
      begin
	B := CurPos >= SourceSize - 1;
	ReRead(SourceName^);
	if B then
	begin
	  GoCtrlPgDn;
	  UpdatePosition;
	end;
      end;
  end;
end;

function THexViewer.GetPalette: PPalette;
const
  P: String[Length(CViewer)] = CViewer;
begin
  GetPalette := @P;
end;

procedure THexViewer.HandleEvent(var Event: TEvent);
var
  SameName, ShiftDown, MouseOut, SaveFlag, WasSelected, Modified: Boolean;
  Y, B, E: Integer;
  C: Word;
  Spot: TPoint;
  SavePos: Longint;
  S: String;

procedure HScrollDraw;
begin
  Inc(Cursor.X, Delta.X - HScrollBar^.Value);
  Delta.X := HScrollBar^.Value;
  DrawView;
  UpdatePosition;
end;

procedure VScrollDraw;
begin
  Delta.Y := VScrollBar^.Value;
  if (Delta.Y shl 4 < BufOrg) or
     ((Delta.Y + Size.Y) shl 4 > BufOrg + BufBytes) then
    FillBuffer(Delta.Y shl 4);
  while Delta.Y + Cursor.Y > VScrollBar^.Max do Dec(Cursor.Y);
  DrawView;
  UpdatePosition;
end;

procedure ExpandSelection;
begin
  if CurPos <> SavePos then
    if (SavePos = SelOrg) and
       (Status and sfSelBack <> 0) then SetSelect(SelEnd, CurPos) else
    if (SavePos = SelEnd) and
       (Status and sfSelBack = 0) then SetSelect(SelOrg, CurPos) else
    SetSelect(SavePos, CurPos);
end;

procedure SelectAll;
begin
  if SourceSize = 0 then Exit;
  SetSelect(0, SourceSize);
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
    if Status and sfNeedRedraw <> 0 then
    begin
      Status := Status and not sfNeedRedraw;
      DrawView;
    end;
    if (Cursor.X < 0) or (Cursor.X >= Size.X) or (Cursor.Y >= Size.Y) then
    begin
      JustifyX;
      JustifyY;
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
    Modified := False;
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
    else if (Event.CharCode = #32) and
      (GetShiftState and kbCtrlShift <> 0) then
	GetWord(CurPos, SearchData.MatchStr, B, E)
    else if Event.CharCode = ^\ then
      Message(Desktop, evBroadcast, cmReopen, SourceName)
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
      kbTab, kbShiftTab: GoOpposite;
      kbAltY: PlaceMarkerDlg(@Self, Status and sfCtrlQPressed = 0);
      else case Event.CharCode of
	^K: Status := Status or sfCtrlKPressed;
	^Q: Status := Status or sfCtrlQPressed;
	^L: Search(SearchData.MatchStr,
	      SearchData.Options or frFromCursor);
       #27:
	  begin
	    Pending.What := evCommand;
	    Pending.Command := cmClose;
	    Pending.InfoPtr := Owner;
	  end;
	else
	begin
	  Modified := (Event.CharCode <> #0) and Modify(Event.CharCode);
	  if not Modified then Goto CannotHandle;
	end;
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
      if not Modified then ExpandSelection;
      DrawFlag := SaveFlag;
      DrawView;
    end;
  end
  else if (Event.What = evMouseDown) and MouseInView(Event.Where) then
  begin
    if Status and sfNeedRedraw <> 0 then
    begin
      Status := Status and not sfNeedRedraw;
      DrawView;
    end;
    if Event.Buttons = mbRightButton then
    begin
      repeat until not MouseEvent(Event, evMouseDown);
      ViewerPopup(Event.Where, False, False);
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
	  if Delta.X + Spot.X < HexPos[0] then
	    Spot.X := HexPos[0] - Delta.X;
	  while Pattern[Delta.X + Spot.X] = $7F do Inc(Spot.X);
	  while Delta.Y + Spot.Y > SourceSize shr 4 do Dec(Spot.Y);
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
	  (VScrollBar^.Value <> Delta.Y) then
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
	  GetWord(CurPos, S, B, E);
	  if S = '' then Event.InfoPtr := nil
	  else Event.InfoPtr := @S;
	end;
      cmGetLine:
	begin
	  Event.What := evNothing;
	  GetPartLine(CurPos, S);
	  if S = '' then Event.InfoPtr := nil
	  else Event.InfoPtr := @S;
	end;
      cmGetMarkerLine:
	begin
	  Event.What := evNothing;
	  if (Event.InfoChar in ['0'..'9']) and
	     (Places[Event.InfoChar] <> -1) then
	  begin
	    GetMarkerLine(Places[Event.InfoChar], S);
	    Event.InfoPtr := @S;
	  end
	  else Event.InfoPtr := nil;
	end;
      cmOpenHexViewer:
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
      cmIsHexViewer:
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
      cmSaveAll: if Status and sfModified <> 0 then Save;
      cmQuit:
	if Event.InfoPtr <> nil then DoneModifiedBuffer
	else
	begin
	  C := SaveOnExit;
	  if C = cmCancel then ClearEvent(Event)
	  else if C = cmYes then Save;
	end;
      cmCtrlKW:
        begin
	  WriteBlockToFile(Event.InfoPtr, False);
          ClearEvent(Event);
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
    case Event.Command of
      cmSave: Save;
      cmCopy: CopyToClipboard;
      cmFind: Find(False);
      cmReplace: ReplaceDlg;
      cmFindAll: Find(True);
      cmShowAllFound: FindAllDlg;
      cmSearchAgain: Search(SearchData.MatchStr,
	SearchData.Options or frFromCursor);
      cmGoToLine: GoToLineNumber;
      cmSelectAll: SelectAll;
      cmPopUp:
	begin
	  Spot.X := Size.X div 2;
	  Spot.Y := 0;
	  MakeGlobal(Spot, Spot);
	  ViewerPopup(Spot, False, False);
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
	  cmCtrlQB: GoToPosition(SelOrg);
	  cmCtrlQK: GoToPosition(SelEnd);
	  else Exit;
	end;
	DrawView;
	UpdatePosition;
      end;
    end;
    Event.What := evNothing;
  end;
end;

procedure THexViewer.SetState(AState: Word; Enable: Boolean);

procedure ShowSBar(SBar: PView);
begin
  if SBar <> nil then
    if GetState(sfActive + sfSelected) then SBar^.Show
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
    EnableCommands(HexViewerCommands);
    if Status and sfHilit <> 0 then
      EnableCommands(XViewCommands + MTCopyCommands)
    else DisableCommands(XViewCommands + MTCopyCommands);
  end
  else if not Enable and
    (((AState = sfActive) and GetState(sfExposed)) or
     (AState = sfExposed)) then DisableCommands(
       HexViewerCommands + XViewCommands + MTCopyCommands);
end;

procedure THexViewer.Store(var S: TStream);
var
  SaveStatus: Word;
begin
  SaveStatus := Status;
  Status := Status and not (sfNeedRedraw + sfModified);
  Inherited Store(S);
  PutPeerViewPtr(S, HScrollBar);
  PutPeerViewPtr(S, VScrollBar);
  PutPeerViewPtr(S, Indicator);
  S.WriteStr(SourceName);
  S.Write(Delta, SizeOf(Delta) + SizeOf(BufOrg) + SizeOf(SelOrg) +
    SizeOf(SelEnd) + SizeOf(Places) + SizeOf(Status));
  if Status and sfHistLocked <> 0 then S.Write(HistLock, SizeOf(HistLock));
  Status := SaveStatus;
end;

function THexViewer.Valid(Command: Word): Boolean;
begin
  Valid := IsValid and Inherited Valid(Command);
end;

procedure THexViewer.InitSource;
begin
  IsValid := False;
  SourceSize := 0;
  SourceTime := 0;
  LogEvent := lcDiskRead;
  DrawStatusLine('Loading Hex viewer ' + TrimmedName(SourceName^, 49) + '.');
  lAssignFile(Source, SourceName^);
  lGetFAttr(Source, SourceAttr);
  OpenSource;
  if IOResult <> 0 then CouldNotOpenMsgBox(SourceName^)
  else if IsDevice(FileRec(Source.F).Handle) then
    FileIsDeviceMsgBox(SourceName^)
  else
  begin
    SourceSize := FileSize(Source.F);
    if SourceSize < 0 then SourceSize := MaxLongint;
    GetFileTime(SourceName^, SourceTime);
    IsValid := True;
  end;
end;

procedure THexViewer.DoneSource;
begin
  CloseSource;
  DoneModifiedBuffer;
end;

procedure THexViewer.OpenSource;
begin
  if not Open then
  begin
    lResetReadOnly(Source, 1);
    Open := True;
  end;
end;

procedure THexViewer.CloseSource;
begin
  if Open then
  begin
    Close(Source.F);
    InOutRes := 0;
    Open := False;
  end;
end;

procedure THexViewer.SetRanges;
var
  SaveMask: Word;
begin
  SaveMask := EventMask;
  EventMask := 0;
  HScrollBar^.SetParams(HScrollBar^.Value,
    0, 78 - Size.X, Size.X - 1, HScrollBar^.ArStep);
  VScrollBar^.SetParams(VScrollBar^.Value,
    0, SourceSize shr 4, Size.Y - 1, VScrollBar^.ArStep);
  EventMask := SaveMask;
end;

procedure THexViewer.InitViewer;

function ScanHistory: Boolean;
var
  P: Byte;
  I: Integer;
  R: PHistoryRec;
  S: String;
begin
  ScanHistory := False;
  I := HistoryIndex(ReopenHistoryID, 'XView ' + SourceName^ + #$FF);
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
  if S[Length(S)] = #$FF then
  begin
    Dec(S[0]);
    Status := Status and not sfCursorAtHex;
  end;
  P := Pos(#$FF'PLACES', S);
  if P <> 0 then Move(S[P + 7], Places, SizeOf(TLongPlaces));
  P := Pos(#$FF, S);
  S := Copy(S, P + 1, 10);
  Val(S, CurPos, I);
  ScanHistory := True;
end;

begin
  SetRanges;
  Status := Status or sfCursorAtHex;
  Unselect;
  FillChar(Places, SizeOf(TLongPlaces), $FF);
  if ScanHistory then GoToPosition(CurPos)
  else
  begin
    FillBuffer(BufOrg);
    if Delta.Y + Cursor.Y > SourceSize shr 4 then GoCtrlPgDn;
  end;
  BlockCursor;
  ShowCursor;
  UpdatePosition;
end;

procedure THexViewer.InitModifiedBuffer;
begin
  if ModifiedBuffer = nil then
  begin
{    GetMem(ModifiedBuffer, BufSize shr 2);}
    GetMemUMB(ModifiedBuffer, BufSize shr 2);
    FillChar(ModifiedBuffer^, BufSize shr 2, 0);
  end;
end;

procedure THexViewer.DoneModifiedBuffer;
begin
  if ModifiedBuffer <> nil then
  begin
{    FreeMem(ModifiedBuffer, BufSize shr 2);}
    FreeMemUMB(ModifiedBuffer, BufSize shr 2);
    ModifiedBuffer := nil;
    Status := Status and not sfModified;
    UpdatePosition;
  end;
end;

procedure THexViewer.FillBuffer(Pos: Longint);
begin
  if Status and sfModified <> 0 then
    if MessageBox(
      ^C'Save changes to disk'#13 +
      ^C'before loading another portion of'#13^C'|' + SourceName^ + '| ?',
      nil, mfConfirmation + mfYesButton + mfNoButton) = cmYes then Save
    else DoneModifiedBuffer;
  FillChar(Buffer^, BufSize, 0);
  if Pos < 0 then Pos := 0;
  BufOrg := (Pos shr 4) shl 4;
  OpenSource;
  Seek(Source.F, BufOrg);
  BlockRead(Source.F, Buffer^, BufSize, BufBytes);
  CloseSource;
end;

procedure THexViewer.ReadLastPortion;
begin
  FillBuffer(SourceSize - BufSize + $10);
end;

procedure THexViewer.ReRead(const AName: String);
var
  C: Word;
begin
  C := SaveOnExit;
  if C = cmCancel then Exit;
  if C = cmYes then Save;
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
    Delta.X := 0;
    Delta.Y := 0;
    if Status and sfCursorAtHex <> 0 then Cursor.X := HexPos[0]
    else Cursor.X := 62;
    Cursor.Y := 0;
    BufOrg := 0;
    BufBytes := 0;
  end;
  DoneSource;
  InitSource;
  IsValid := True;
  InitViewer;
  DrawView;
  PWindow(Owner)^.Frame^.DrawView;
end;

procedure THexViewer.UpdateSourceTime;
var
  L: Longint;
begin
  if not GetFileTime(SourceName^, L) then
    if SourceTime <> -1 then
    begin
      SourceTime := -1;
      InvalidViewerMsgBox('Hex viewer', SourceName^)
    end else
  else if L <> SourceTime then
    if TimeChangedMsgBox('Hex viewer', SourceName^) = cmOk then
      ReRead(SourceName^)
    else SourceTime := L;
end;

procedure THexViewer.GetLine(APos: Longint; var S: String);
var
  Count: Byte;
  BufPos: Word;
  SS: String;
begin
  SS[0] := #16;
  FillChar(SS[1], 16, 0);
  APos := (APos shr 4) shl 4;
  if (APos >= BufOrg) and (APos < BufOrg + BufBytes) then
  begin
    BufPos := APos - BufOrg;
    if BufPos + 16 > BufBytes then Count := 16 - (BufPos mod 16)
    else Count := 16;
    Move(Buffer^[BufPos], SS[1], Count);
  end;
  S := SS;
end;

procedure THexViewer.GetPartLine(APos: Longint; var S: String);
var
  X: Integer;
begin
  S := '';
  if Status and sfCursorAtHex <> 0 then Exit;
  X := APos mod $10 + 1;
  GetLine(APos, S);
  while (X > 0) and (S[X] in WordDelims) do Dec(X);
  while (X > 0) and not (S[X] in WordDelims) do Dec(X);
  S := Copy(S, X + 1, 255);
end;

procedure THexViewer.GetWord(APos: Longint; var W: String;
  var B, E: Integer);
var
  S: String;
begin
  W := '';
  B := 0;
  E := 0;
  if APos >= SourceSize then Exit;
  B := APos mod $10 + 1;
  if B = $10 then Dec(B);
  E := B + 2;
  GetLine(APos, S);
  if Status and sfCursorAtHex <> 0 then
    W := '$' + HexB(Byte(S[B])) + HexB(Byte(S[B + 1]))
  else W := Copy(S, B, 2);
end;

procedure THexViewer.GetMarkerLine(Pos: Longint; var S: String);
begin
  OpenSource;
  S[0] := #16;
  FillChar(S[1], 16, 0);
  Seek(Source.F, Pos - Pos mod 16);
  BlockRead(Source.F, S[1], 16);
  CloseSource;
end;

procedure THexViewer.JustifyX;
begin
  while Cursor.X < 0 do
  begin
    Dec(Delta.X);
    Inc(Cursor.X);
  end;
  while Cursor.X >= Size.X do
  begin
    Inc(Delta.X);
    Dec(Cursor.X);
  end;
end;

procedure THexViewer.JustifyY;
begin
  while Cursor.Y >= Size.Y do
  begin
    Inc(Delta.Y);
    Dec(Cursor.Y);
  end;
end;

procedure THexViewer.GoDownPrim;
begin
  if Delta.Y = VScrollBar^.Max then Exit;
  if (Delta.Y + Size.Y = (BufOrg + BufBytes) shr 4) and
     (BufOrg + BufBytes < SourceSize) then
    FillBuffer(Delta.Y shl 4);
  Inc(Delta.Y);
  if Delta.Y + Cursor.Y > VScrollBar^.Max then Dec(Cursor.Y);
  DrawView;
end;

procedure THexViewer.GoUpPrim;
var
  L: Longint;
begin
  if Delta.Y = 0 then Exit;
  if Delta.Y shl 4 = BufOrg then
  begin
    L := Delta.Y shl 4 + Size.Y shl 4 - BufSize;
    if L < 0 then L := 0;
    FillBuffer(L);
  end;
  Dec(Delta.Y);
  DrawView;
end;

procedure THexViewer.CursorGoDownPrim;
begin
  if Delta.Y + Cursor.Y = VScrollBar^.Max then Exit;
  if Cursor.Y <> Size.Y - 1 then
  begin
    SetCursor(Cursor.X, Cursor.Y + 1);
    if EditOptions and eoHilitCurLine <> 0 then DrawView;
  end
  else GoDownPrim;
end;

procedure THexViewer.CursorGoUpPrim;
begin
  if Cursor.Y > 0 then
  begin
    SetCursor(Cursor.X, Cursor.Y - 1);
    if EditOptions and eoHilitCurLine <> 0 then DrawView;
  end
  else GoUpPrim;
end;

procedure THexViewer.GoWhileKeyDown(Key: Byte);
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

procedure THexViewer.GoDown;
begin
  CursorGoDownPrim;
  if (Cursor.Y = Size.Y - 1) and
     ((KbdStatus = 80) or (KbdStatus = 224)) and
     (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
    GoWhileKeyDown(80);
end;

procedure THexViewer.GoUp;
begin
  CursorGoUpPrim;
  if (Cursor.Y = 0) and
     ((KbdStatus = 72) or (KbdStatus = 224)) and
     (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
    GoWhileKeyDown(72);
end;

procedure THexViewer.GoPgDnPrim;
var
  SaveFlag: Boolean;
  I: Integer;
begin
  if Delta.Y + Size.Y > VScrollBar^.Max then GoCtrlPgDn
  else
  begin
    SaveFlag := DrawFlag;
    DrawFlag := True;
    for I := 0 to Size.Y - 2 do GoDownPrim;
    DrawFlag := SaveFlag;
    DrawView;
  end;
end;

procedure THexViewer.GoPgUpPrim;
var
  SaveFlag: Boolean;
  I: Integer;
begin
  if Delta.Y = 0 then GoCtrlPgUp
  else
  begin
    SaveFlag := DrawFlag;
    DrawFlag := True;
    for I := 0 to Size.Y - 2 do GoUpPrim;
    DrawFlag := SaveFlag;
    DrawView;
  end;
end;

procedure THexViewer.GoPgDn;
begin
  GoPgDnPrim;
  if ((KbdStatus = 81) or (KbdStatus = 224)) and
     (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
    GoWhileKeyDown(81);
end;

procedure THexViewer.GoPgUp;
begin
  GoPgUpPrim;
  if ((KbdStatus = 73) or (KbdStatus = 224)) and
     (GetShiftState and (kbLeftShift + kbRightShift) = 0) then
    GoWhileKeyDown(73);
end;

procedure THexViewer.GoCtrlPgDn;
begin
  if (BufOrg + BufBytes <> SourceSize) or
     ((BufBytes = 0) and (SourceSize <> 0)) then ReadLastPortion;
  Delta.X := 0;
  if (Delta.Y + Size.Y - 1 < VScrollBar^.Max) or
     (Delta.Y > VScrollBar^.Max) then
    Delta.Y := VScrollBar^.Max - Size.Y + 1;
  if Delta.Y < 0 then Delta.Y := 0;
  if Status and sfCursorAtHex <> 0 then
    Cursor.X := HexPos[SourceSize mod $10]
  else Cursor.X := 62 + SourceSize mod $10;
  SetCursor(Cursor.X, VScrollBar^.Max - Delta.Y);
  JustifyX;
  DrawView;
end;

procedure THexViewer.GoCtrlPgUp;
begin
  if BufOrg <> 0 then FillBuffer(0);
  Delta.X := 0;
  Delta.Y := 0;
  if Status and sfCursorAtHex <> 0 then SetCursor(HexPos[0], 0)
  else SetCursor(62, 0);
  JustifyX;
  DrawView;
end;

procedure THexViewer.GoRight;
begin
  if Pattern[Delta.X + Cursor.X] = $F then
  begin
    GoDown;
    GoHome;
    Exit;
  end;
  repeat
    if Cursor.X = Size.X - 1 then Inc(Delta.X)
    else SetCursor(Cursor.X + 1, Cursor.Y);
  until Pattern[Delta.X + Cursor.X] <> $7F;
  if (Delta.X <> HScrollBar^.Value) or
     (EditOptions and eoHilitCurColumn <> 0) then DrawView;
end;

procedure THexViewer.GoLeft;
begin
  if (Delta.Y + Cursor.Y = 0) and
     ((Delta.X + Cursor.X = HexPos[0]) or
      (Delta.X + Cursor.X = 62)) then Exit;
  if (Delta.X + Cursor.X = HexPos[0]) or
     (Delta.X + Cursor.X = 62) then
  begin
    GoUp;
    GoEnd;
    Exit;
  end;
  repeat
    if Cursor.X = 0 then Dec(Delta.X)
    else SetCursor(Cursor.X - 1, Cursor.Y);
  until Pattern[Delta.X + Cursor.X] <> $7F;
  if (Delta.X <> HScrollBar^.Value) or
     (EditOptions and eoHilitCurColumn <> 0) then DrawView;
end;

procedure THexViewer.GoCtrlRight;
var
  B, C: Byte;
  SaveFlag: Boolean;
begin
  if Status and sfCursorAtHex <> 0 then
    if Pattern[Delta.X + Cursor.X] > $F then B := 4
    else B := 3
  else B := 2;
  SaveFlag := DrawFlag;
  DrawFlag := True;
  for C := 1 to B do GoRight;
  DrawFlag := SaveFlag;
  DrawView;
end;

procedure THexViewer.GoCtrlLeft;
var
  B, C: Byte;
  SaveFlag: Boolean;
begin
  if Status and sfCursorAtHex <> 0 then
  begin
    if Pattern[Delta.X + Cursor.X] > $F then B := 4
    else B := 5;
    if Pattern[Delta.X + Cursor.X] and $7F < 2 then Dec(B);
  end
  else B := 2;
  SaveFlag := DrawFlag;
  DrawFlag := True;
  for C := 1 to B do GoLeft;
  DrawFlag := SaveFlag;
  DrawView;
end;

procedure THexViewer.GoEnd;
begin
  Delta.X := 0;
  if Status and sfCursorAtHex = 0 then Cursor.X := 77
  else Cursor.X := HexPos[$F];
  JustifyX;
  SetCursor(Cursor.X, Cursor.Y);
  if (Delta.X <> HScrollBar^.Value) or
     (EditOptions and eoHilitCurColumn <> 0) then DrawView;
end;

procedure THexViewer.GoHome;
begin
  Delta.X := 0;
  if Status and sfCursorAtHex = 0 then Cursor.X := 62
  else Cursor.X := HexPos[0];
  JustifyX;
  SetCursor(Cursor.X, Cursor.Y);
  if (Delta.X <> HScrollBar^.Value) or
     (EditOptions and eoHilitCurColumn <> 0) then DrawView;
end;

procedure THexViewer.GoCtrlEnd;
begin
  Cursor.Y := Size.Y - 1;
  while Delta.Y + Cursor.Y > VScrollBar^.Max do Dec(Cursor.Y);
  SetCursor(Cursor.X, Cursor.Y);
  if EditOptions and eoHilitCurLine <> 0 then DrawView;
end;

procedure THexViewer.GoCtrlHome;
begin
  SetCursor(Cursor.X, 0);
  if EditOptions and eoHilitCurLine <> 0 then DrawView;
end;

procedure THexViewer.GoOpposite;
begin
  Cursor.X := Pattern[Delta.X + Cursor.X] and $7F;
  Delta.X := 0;
  if Status and sfCursorAtHex <> 0 then
    Cursor.X := 62 + Cursor.X
  else Cursor.X := HexPos[Cursor.X];
  JustifyX;
  SetCursor(Cursor.X, Cursor.Y);
  Status := Status xor sfCursorAtHex;
  if (Delta.X <> HScrollBar^.Value) or
     (EditOptions and eoHilitCurColumn <> 0) then DrawView;
end;

procedure THexViewer.GoToPosition(APos: Longint);
var
  L: Longint;
begin
  if APos >= SourceSize then
  begin
    GoCtrlPgDn;
    Exit;
  end;
  if (APos < BufOrg) or (APos >= BufOrg + BufBytes) then
    if APos < BufSize then FillBuffer(0)
    else if APos > SourceSize - BufSize + $10 then ReadLastPortion
    else FillBuffer(APos);
  Delta.X := 0;
  L := APos shr 4;
  if (L < Delta.Y) or (L >= Delta.Y + Size.Y) then
  begin
    Delta.Y := L;
    while (Delta.Y > 0) and
      ((Delta.Y + Size.Y) shl 4 >
	BufOrg + BufBytes - BufBytes mod $11 + $10) do
      Dec(Delta.Y);
  end;
  Cursor.X := APos mod $10;
  if Status and sfCursorAtHex <> 0 then
    Cursor.X := HexPos[Cursor.X]
  else Cursor.X := 62 + Cursor.X;
  Cursor.Y := L - Delta.Y;
  JustifyX;
  SetCursor(Cursor.X, Cursor.Y);
  DrawView;
end;

procedure THexViewer.GoToLineNumber;
const
  GoToLineData: String[10] = '';
var
  D: PDialog;
  Control: PView;
  R: TRect;
  L, Count, Pos: Longint;
  S: String;
begin
  R.Assign(0, 0, 40, 7);
  D := New(PDialog, Init(R, 'Go to address'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcSHGoToLineNumber;
    R.Assign(21, 2, 34, 3);
    Control := New(PCInputLine, Init(R, 10, 0, SourceSize));
    Insert(Control);
    StandardHistory(Control, GoToHexAddrHistoryID);
    R.Assign(2, 2, 21, 3);
    Insert(New(PLabel, Init(R, '~E~nter new address', Control)));

    StandardButtonRow(D, True);
  end;
  if (Application^.ExecuteDialog(D, @GoToLineData, False) <> cmCancel) and
    Str2Long(GoToLineData, L) then
  begin
    GoToPosition(L);
    UpdatePosition;
  end;
end;

procedure THexViewer.SetPlaceMarker(AChar: Char);
begin
  Places[AChar] := CurPos;
end;

procedure THexViewer.GoToPlaceMarker(AChar: Char);
begin
  if Places[AChar] <> -1 then GoToPosition(Places[AChar]);
end;

procedure THexViewer.UpdatePosition;
var
  L: Longint;
  R: Real;

procedure UpdateScrollBars;
begin
  if HScrollBar^.Value <> Delta.X then
  begin
    HScrollBar^.SetValue(Delta.X);
    HScrollBar^.DrawView;
  end;
  if VScrollBar^.Value <> Delta.Y then
  begin
    VScrollBar^.SetValue(Delta.Y);
    VScrollBar^.DrawView;
  end;
end;

procedure UpdateIndicator;
begin
  Indicator^.Position := CurPos;
  if CurPos >= SourceSize - 1 then L := 100
  else
  begin
    R := CurPos;
    R := R * 100 / SourceSize;
    L := Trunc(R);
  end;
  Indicator^.Percent := L;
  Indicator^.Modified := Status and sfModified <> 0;
  Indicator^.DrawView;
end;

begin
  CurPos := (Delta.Y + Cursor.Y) shl 4 +
    (Pattern[Delta.X + Cursor.X] and $7F);
  if Delta.X + Cursor.X > 60 then
    Status := Status and not sfCursorAtHex
  else Status := Status or sfCursorAtHex;
  UpdateScrollBars;
  UpdateIndicator;
end;

procedure THexViewer.SetSelect(ASelOrg, ASelEnd: Longint);
begin
  if ASelOrg > ASelEnd then
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
  if SelOrg <> SelEnd then
  begin
    Status := Status or sfHilit;
    EnableCommands(XViewCommands + MTCopyCommands);
  end
  else
  begin
    Status := Status and not sfHilit;
    DisableCommands(XViewCommands + MTCopyCommands);
  end;
end;

procedure THexViewer.Unselect;
begin
  SelOrg := 0;
  SelEnd := 0;
  SetSelect(SelOrg, SelEnd);
end;

procedure THexViewer.ToggleSelection;
begin
  if SelOrg = SelEnd then Status := Status and not sfHilit
  else Status := Status xor sfHilit;
  if Status and sfHilit <> 0 then
    EnableCommands(XViewCommands + MTCopyCommands)
  else DisableCommands(XViewCommands + MTCopyCommands);
end;

procedure THexViewer.GetSelection(APos: Longint; var Lo, Hi: Integer);
begin
  if (APos shr 4 < SelOrg shr 4) or (APos shr 4 > SelEnd shr 4) then
  begin
    Lo := 0;
    Hi := 0;
    Exit;
  end;
  if APos shr 4 = SelOrg shr 4 then Lo := SelOrg mod $10 + 1
  else Lo := 1;
  if APos shr 4 = SelEnd shr 4 then Hi := SelEnd mod $10
  else Hi := $10;
end;

procedure THexViewer.GetSelectedPart(APos: Longint; var S: String;
  var Lo, Hi: Integer);
begin
  GetSelection(APos, Lo, Hi);
  if (Lo = 0) or (Hi < Lo) then S := ''
  else S := Copy(S, Lo, Hi - Lo + 1);
end;

procedure THexViewer.MarkBlockBegin;
begin
  if CurPos < SelEnd then SetSelect(CurPos, SelEnd)
  else SetSelect(CurPos, CurPos);
end;

procedure THexViewer.MarkBlockEnd;
begin
  if CurPos > SelOrg then SetSelect(SelOrg, CurPos)
  else SetSelect(CurPos, CurPos);
end;

procedure THexViewer.MarkCurLine;
begin
  SelOrg := (CurPos shr 4) shl 4;
  SetSelect(SelOrg, SelOrg + $10);
end;

procedure THexViewer.MarkCurWord;
begin
  SetSelect(CurPos, CurPos + 2);
end;

function THexViewer.Search(const Match: String; AOptions: Word): Boolean;
var
  Hex: Boolean;
  BufPos, BytesToSearch, BytesSearched, SaveStatus: Word;
  SPos, BPos, EPos, Percent, OldPercent,
  SaveBufOrg, SaveOrg, SaveEnd: Longint;
  BT: BTable;
  SS, SSS, PercentStr: String;

procedure _FillBuffer(Pos: Longint);
begin
  GiveTicks;
  if (Pos < BufOrg) or (Pos > BufOrg + BufBytes - Length(SS)) then
    FillBuffer(Pos);
  BufPos := Pos - BufOrg;
  BytesToSearch := BufBytes - BufPos;
  while (BytesToSearch > 0) and
    (BufOrg + BufPos + BytesToSearch > EPos) do
      Dec(BytesToSearch);
end;

begin
  Search := False;
  if Match = '' then Exit;
  if (Byte(IsSearchingAll) <= 1) and (Byte(IsReplacing) <= 1) then
    DrawStatusLine(SearchMsg);
  SS := Match;
  if AOptions and frCaseSensitive = 0 then UpcaseSt(SS);
  if SS[1] = '$' then SS := Hex2Match(SS, Hex);
  if Status and sfHilit = 0 then
    AOptions := AOptions and not frSelectedText;
  if Byte(IsSearchingAll) > 1 then SPos := FindAllPos
  else if AOptions and frSelectedText <> 0 then
  begin
    SPos := SelOrg;
    if AOptions and frFromCursor <> 0 then
      if (CurPos >= SelOrg) and (CurPos < SelEnd) then
	SPos := CurPos + 1
      else if CurPos >= SelEnd then SPos := MaxLongint;
  end
  else if AOptions and frFromCursor <> 0 then SPos := CurPos + 1
  else SPos := 0;
  if (Byte(IsSearchingAll) > 1) or (Byte(IsReplacing) > 1) then
    BPos := FindAllStart
  else
  begin
    BPos := SPos;
    FindAllStart := SPos;
  end;
  if AOptions and frSelectedText <> 0 then EPos := SelEnd
  else EPos := SourceSize;
  BMMakeTable(SS, BT);
  SaveBufOrg := BufOrg;
  BytesSearched := $FFFF;
  OldPercent := 0;
  while SPos < EPos do
  begin
    _FillBuffer(SPos);
    if BytesToSearch < Length(SS) then BytesSearched := $FFFF
    else if (AOptions and frCaseSensitive <> 0) or
      ((Match[1] = '$') and Hex) then BytesSearched :=
	BMSearch(Buffer^[BufPos], BytesToSearch, BT, SS)
    else BytesSearched :=
      BMSearchUC(Buffer^[BufPos], BytesToSearch, BT, SS);
    if BytesSearched <> $FFFF then
    begin
      SPos := BufOrg + BufPos + BytesSearched;
      Break;
    end
    else
    begin
      SPos := BufOrg + BufBytes - (Length(SS) - 1);
      if SPos > EPos - Length(SS) then SPos := EPos;
    end;
    if (KbdStatus = 1) and AbortAction then
    begin
      BytesSearched := $FFFF;
      FindAllPos := -1;
      IsSearchingAll := True;
      Break;
    end;
    if SPos >= EPos then Percent := 100
    else Percent := Trunc(((SPos - BPos) / (EPos - BPos)) * 100);
    if Percent <> OldPercent then
    begin
      OldPercent := Percent;
      FormatStr(PercentStr, ' %d ', Percent);
      PercentStr[Length(PercentStr)] := '%';
      SSS := SearchMsg;
      SSS[Length(SSS)] := ':';
      LogEvent := 0;
      DrawStatusLine(SSS + PercentStr);
    end;
  end;
  if BytesSearched = $FFFF then
  begin
    if BufOrg <> SaveBufOrg then FillBuffer(SaveBufOrg);
    if not IsSearchingAll and not NoSearchMsg then
      SearchStringNotFoundMsgBox
    else IsSearchingAll := False;
  end
  else
  begin
    if IsSearchingAll then
    begin
      FindAllPos := (SPos shr 4 + 1) shl 4;
      FindAllList^.Insert(Pointer(FindAllPos - $10));
      Byte(IsSearchingAll) := 2;
    end
    else
    begin
      SaveStatus := Status;
      Status := Status or sfHilit;
      SaveOrg := SelOrg;
      SaveEnd := SelEnd;
      SelOrg := SPos;
      SelEnd := SPos + Length(SS);
      GoToPosition(SelOrg);
      DrawView;
      UpdatePosition;
      Status := SaveStatus or sfNeedRedraw;
      SelOrg := SaveOrg;
      SelEnd := SaveEnd;
      if IsReplacing then Byte(IsReplacing) := 2;
    end;
    Search := True;
  end;
end;

procedure THexViewer.Find(All: Boolean);
var
  DoShow: Boolean;
  B, E: Integer;
  C: Word;
  SaveBufOrg: Longint;
begin
  if EditOptions and eoFindTextAtCursor <> 0 then
    GetWord(CurPos, SearchData.MatchStr, B, E)
  else SearchData.MatchStr := HistoryStr(FindHistoryID, 0);
  SaveBufOrg := BufOrg;
  C := Application^.ExecuteDialog(
    LoadFindDialog(All, False, frSelectedText * Byte(Status and sfHilit = 0) +
      frWholeWordsOnly + frRegExp + frBackward), @SearchData, False);
  if C = cmOk then Search(SearchData.MatchStr, SearchData.Options)
  else if C = cmYes then
  begin
    FindAllList^.FreeAll;
    FindAllPos := 0;
    FindAllData := SearchData;
    FindAllData.Options := FindAllData.Options and not frSelectedText;
    IsSearchingAll := True;
    repeat until not Search(SearchData.MatchStr, SearchData.Options);
    if BufOrg <> SaveBufOrg then FillBuffer(SaveBufOrg);
    DoShow := FindAllPos <> -1;
    if DoShow then FindAllDlg
    else FindAllList^.FreeAll;
  end;
end;

procedure THexViewer.FindAllDlg;
var
  P: Pointer;
  L: Longint;
begin
  P := @Self;
  if (Application^.ExecuteDialog(
    ViewerFindAllDialog(FindAllList^.Count, True),
      @P, False) <> cmCancel) and (FindAllList^.Count <> 0) then
  begin
    L := Longint(P);
    if L > 0 then Dec(L);
    GoToPosition(L);
    UpdatePosition;
    Search(FindAllData.MatchStr,
      FindAllData.Options or frFromCursor * Byte(L <> 0));
  end;
end;

procedure THexViewer.ReplaceDlg;
var
  NotFound, Changed, Error, Hex: Boolean;
  C, W: Word;
  B, E: Integer;
  D: PDialog;
  R: TRect;
  Spot: TPoint;
begin
  if EditOptions and eoFindTextAtCursor <> 0 then
  begin
    GetWord(CurPos, ReplaceData.MatchStr, B, E);
    ReplaceData.NewString := ReplaceData.MatchStr;
  end
  else
  begin
    ReplaceData.MatchStr := HistoryStr(FindHistoryID, 0);
    ReplaceData.NewString := HistoryStr(ReplaceHistoryID, 0);
  end;
  D := LoadReplaceDialog(frSelectedText * Byte(Status and sfHilit = 0) +
    frWholeWordsOnly + frRegExp + frBackward + frGroupUndo);
  if Application^.ExecuteDialog(D, @ReplaceData, False) <> cmCancel then
  begin
    C := SaveOnExit;
    if C = cmCancel then Exit;
    if C = cmYes then Save
    else DoneSource;
    if (ReplaceData.NewString[1] = '$') then
      ReplaceData.NewString := Hex2Match(ReplaceData.NewString, Hex);
    W := ReplaceData.Options;
    IsReplacing := True;
    NoSearchMsg := True;
    NotFound := True;
    Changed := False;
    Error := False;
    repeat
      if not Search(ReplaceData.MatchStr, W) then Break;
      NotFound := False;
      W := W or frFromCursor;
      if W and frPromptOnReplace <> 0 then
      begin
	MakeGlobal(Cursor, Spot);
	if Spot.Y < ScreenHeight div 2 then
	  R.Assign(19, Spot.Y + 1, 61, Spot.Y + 9)
	else R.Assign(19, Spot.Y - 9, 61, Spot.Y - 1);
	C := ConfirmReplaceMsgBox(R);
	if C = cmOk then W := W and not frPromptOnReplace;
	DrawStatusLine('');
      end
      else C := cmYes;
      if C = cmCancel then Error := True;
      if (C = cmOk) or (C = cmYes) then
      begin
	lAssignFile(Source, SourceName^);
	if SourceAttr and (ReadOnly + Hidden + SysFile) <> 0 then
	begin
	  DrawStatusLine('');
	  lSetFAttr(Source, Archive);
	end;
	lResetFile(Source, 1);
	if IOResult <> 0 then
	begin
	  CouldNotOpenMsgBox(SourceName^);
	  Error := True;
	end
	else
	begin
	  Open := True;
	  Seek(Source.F, CurPos);
	  BlockWrite(Source.F, ReplaceData.NewString[1],
	    Length(ReplaceData.NewString));
	  if IOResult <> 0 then
	  begin
	    CouldNotWriteMsgBox(SourceName^);
	    Error := True;
	  end
	  else Changed := True;
	end;
	DoneSource;
	if SourceAttr <> Archive then lSetFAttr(Source, SourceAttr);
	OpenSource;
	SourceSize := FileSize(Source.F);
	GetFileTime(SourceName^, SourceTime);
	FillBuffer(BufOrg);
      end;
      DrawView;
      PWindow(Owner)^.Frame^.DrawView;
      if (KbdStatus = 1) and AbortAction then Break;
    until Error;
    IsReplacing := False;
    NoSearchMsg := False;
    if NotFound then
    begin
      DrawView;
      SearchStringNotFoundMsgBox;
    end
    else if Changed then UpdateFiles(SourceName^);
  end;
end;

procedure THexViewer.CopyToClipboard;
var
  B: Byte;
  SaveCount, SB, SE, MaxLen: Integer;
  SaveBufOrg: Longint;
  Pos: Longint;
  S, C: String;
begin
  if (DiskClipStream = nil) or (Status and sfHilit = 0) then Exit;
  DrawClipCopyStatus;
  SetExpandClipAreaFlag;
  SaveCount := ClipLines^.Count;
  Pos := SelOrg;
  SaveBufOrg := BufOrg;
  MaxLen := 0;
  while (Pos < SourceSize) and (Pos shr 4 <= SelEnd shr 4) do
  begin
    if (Pos < BufOrg) or (Pos >= BufOrg + BufBytes) then FillBuffer(Pos);
    GetLine(Pos, S);
    GetSelectedPart(Pos, S, SB, SE);
    if Status and sfCursorAtHex <> 0 then
    begin
      C := S;
      S := '';
      for B := 1 to Length(C) do S := S + HexB(Byte(C[B]));
    end;
    if S <> '' then
    begin
      PutClipLine(S);
      if not MarkColumns or (Length(S) > MaxLen) then MaxLen := Length(S);
    end;
    if ClipOverflow or ((KbdStatus = 1) and AbortAction) then Break;
    Inc(Pos, $10);
  end;
  SetOrExpandClipArea(SaveCount, MaxLen + 1);
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
  if BufOrg <> SaveBufOrg then FillBuffer(SaveBufOrg);
end;

procedure THexViewer.WriteBlockToFile(NamePtr: PString; Append: Boolean);
var
  C, W: Word;
  BytesToWrite, BytesWritten: Integer;
  Pos, SaveBufOrg: Longint;
  S: String[7];
  FName: FNameStr;
  F: lFile;

procedure WriteBlock;
begin
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
  Pos := SelOrg;
  SaveBufOrg := BufOrg;
  while (Pos < SourceSize) and (Pos < SelEnd) do
  begin
    if (Pos < BufOrg) or (Pos >= BufOrg + BufBytes) then FillBuffer(Pos);
    W := Pos - BufOrg;
    if Pos + BufBytes - W >= SelEnd then BytesToWrite := SelEnd - Pos
    else BytesToWrite := BufBytes - W;
    BlockWrite(F.F, Buffer^[W], BytesToWrite, BytesWritten);
    if (IOResult <> 0) or (BytesToWrite <> BytesWritten) then
    begin
      CouldNotWriteMsgBox(FName);
      Break;
    end;
    if (KbdStatus = 1) and AbortAction then Break;
    Inc(Pos, BytesWritten);
  end;
  Close(F.F);
  InOutRes := 0;
  if BufOrg <> SaveBufOrg then FillBuffer(SaveBufOrg);
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

function THexViewer.Modify(AChar: Char): Boolean;
var
  BufPos, ModBufPos, W: Word;
  HS: String[2];
begin
  Modify := False;
  BufPos := CurPos - BufOrg;
  if BufPos >= BufBytes then Exit;
  if Status and sfCursorAtHex <> 0 then
  begin
    if not (AChar in ['0'..'9', 'A'..'F', 'a'..'f']) then
    begin
      if not DisableSounds then Write(^G);
      Exit;
    end;
    HS := HexB(Buffer^[BufPos]);
    if Pattern[Delta.X + Cursor.X] > $F then
      Str2Word('$' + AChar + HS[2], W)
    else Str2Word('$' + HS[1] + AChar, W);
    AChar := Char(W);
  end;
  Buffer^[BufPos] := Byte(AChar);
  InitModifiedBuffer;
  ModBufPos := BufPos shr 4;
  ModifiedBuffer^[ModBufPos] :=
    ModifiedBuffer^[ModBufPos] or (1 shl (BufPos mod $10));
  Status := Status or sfModified;
  GoRight;
  DrawView;
  UpdatePosition;
  Modify := True;
end;

procedure THexViewer.Save;
var
  BytesWritten: Word;
label
  InitS;
begin
  DoneSource;
  LogEvent := lcDiskWrite;
  DrawStatusLine('Updating ' + TrimmedName(SourceName^, 59) + '.');
  lAssignFile(Source, SourceName^);
  if SourceAttr and (ReadOnly + Hidden + SysFile) <> 0 then
    if OverwriteReadOnlyMsgBox(SourceName^) = cmCancel then Goto InitS
    else
    begin
      DrawStatusLine('');
      lSetFAttr(Source, Archive);
    end;
  lResetFile(Source, 1);
  if IOResult <> 0 then CouldNotOpenMsgBox(SourceName^)
  else
  begin
    Open := True;
    Seek(Source.F, BufOrg);
    BlockWrite(Source.F, Buffer^, BufBytes, BytesWritten);
    if (IOResult <> 0) or (BufBytes <> BytesWritten) then
      CouldNotWriteMsgBox(SourceName^);
  end;
  DoneSource;
  if SourceAttr <> Archive then lSetFAttr(Source, SourceAttr);
InitS:
  InitSource;
  CloseSource;
  IsValid := True;
  DrawView;
  UpdatePosition;
  UpdateFiles(SourceName^);
end;

function THexViewer.SaveOnExit: Word;
begin
  if (Status and sfModified <> 0) and
     (GetShiftState and kbCtrlShift = 0) then
    SaveOnExit := ModifiedSaveMsgBox(SourceName^)
  else SaveOnExit := cmNo;
end;

constructor THexWindow.Init(Bounds: TRect; const AName: FNameStr);
var
  HControl: PScrollBar;
  VControl: PLongScrollBar;
  IControl: PHexViewIndicator;
  R: TRect;
begin
  Inherited Init(Bounds, AName, WindowNumAvail);
  Options := Options or ofTileable;

  GetExtent(R);
  Inc(R.A.X, 26); Dec(R.B.X, 2); R.A.Y := R.B.Y - 1;
  HControl := New(PScrollBar, Init(R));
  Insert(HControl);

  GetExtent(R);
  R.A.X := R.B.X - 1; Inc(R.A.Y); Dec(R.B.Y);
  VControl := New(PLongScrollBar, Init(R));
  Insert(VControl);

  GetExtent(R);
  Inc(R.A.X, 5); R.A.Y := R.B.Y - 1; R.B.X := R.A.X + 17;
  IControl := New(PHexViewIndicator, Init(R));
  IControl^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(IControl);

  GetExtent(R);
  R.Grow(-1, -1);
  Viewer := New(PHexViewer, Init(
    R, HControl, VControl, AName, IControl));
  Insert(Viewer);
end;

constructor THexWindow.Load(var S: TStream);
begin
  Inherited Load(S);
  GetSubViewPtr(S, Viewer);
  with Viewer^ do if IsValid then
  begin
    SetRanges;
    FillBuffer(BufOrg);
    if Delta.Y + Cursor.Y > SourceSize shr 4 then GoCtrlPgDn;
    UpdatePosition;
  end;
end;

procedure THexWindow.ChangeBounds(var Bounds: TRect);
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

procedure THexWindow.Close;
var
  I: Integer;
  C: Word;
  X: String[15];
  S: String;
begin
  with Viewer^ do if Length(SourceName^) <= 222 then
  begin
    C := SaveOnExit;
    if C = cmCancel then Exit;
    if C = cmYes then Save;
    S := 'XView ' + SourceName^;
    Str(CurPos:10, X);
    S := S + #$FF + X + #$FF#$FF;
    if Self.Size.X = Viewer^.Size.X then
      FillChar(S[Length(S) + 1], 8, OpenWideFiller)
    else Move(Self.Origin, S[Length(S) + 1], 8);
    Inc(S[0], 8);
    if Length(S) < 254 - SizeOf(TLongPlaces) - 8 then
    begin
      S := S + #$FF'PLACES';
      Move(Places, S[Length(S) + 1], SizeOf(TLongPlaces));
      Inc(S[0], SizeOf(TLongPlaces) + 1);
      S[Length(S)] := #0;
    end;
    if Status and sfCursorAtHex = 0 then
    begin
      Inc(S[0]);
      S[Length(S)] := #$FF;
    end;
    HistoryAdd(ReopenHistoryID, S, False);
    if Status and sfHistLocked <> 0 then
    begin
      I := HistoryIndex(ReopenHistoryID, S);
      if I <> -1 then
	Byte(PHistoryRec(HistoryList^.At(I))^.Lock) := HistLock;
    end;
  end;
  Inherited Close;
end;

function THexWindow.GetPalette: PPalette;
const
  P: String[Length(CViewerWindow)] = CViewerWindow;
begin
  GetPalette := @P;
end;

function THexWindow.GetTitle(MaxSize: Integer): TTitleStr;
var
  I: Integer;
  S: String;
begin
  FormatStr(S, ' (%d bytes)', Viewer^.SourceSize);
  if Viewer^.SourceSize = 1 then System.Delete(S, Length(S) - 1, 1);
  I := MaxSize - Length(S) - 8;
  if I < 12 then I := 12;
  GetTitle := Concat('Hex view: ', TrimmedName(Title^, Byte(I)), S);
end;

procedure THexWindow.SizeLimits(var Min, Max: TPoint);
begin
  Inherited SizeLimits(Min, Max);
  Min.X := 31;
end;

procedure THexWindow.Store(var S: TStream);
begin
  Inherited Store(S);
  PutSubViewPtr(S, Viewer);
end;

procedure THexWindow.Zoom;
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