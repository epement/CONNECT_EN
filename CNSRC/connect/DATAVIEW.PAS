{$F+,O+,X+}
unit DataView;

interface

uses Objects, Drivers, Views, Dialogs, DataBase, LongView;

const
  IncSearchLen = 63;

type
  PFieldViewer = ^TFieldViewer;
  TFieldViewer = object(TListViewer)
    DB: PDataBase;
    FieldLine: PByteArray;
    LineSize: Word;
    constructor Init(var Bounds: TRect; AHScrollBar: PScrollBar;
      ADataBase: PDataBase);
    destructor Done; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitFieldLine;
    procedure DoneFieldLine;
  end;

  PDataRec = ^TDataRec;
  TDataRec = record
    Rec: PByteArray;
    Pos: Longint;
  end;

  PDataBuffer = ^TDataBuffer;
  TDataBuffer = object(TCollection)
    RecSize: Word;
    NotInUse: Boolean;
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PDataViewIndicator = ^TDataViewIndicator;
  TDataViewIndicator = object(TView)
    Index: Longint;
    Percent: Byte;
    SelCount: Integer;
    Modified: Boolean;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    function GetMouseShape(var Event: TEvent): Char; virtual;
    function GetMousePos(X: Integer): Byte;
  end;

  PSelList = ^TSelList;
  TSelList = object(TSortedCollection)
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    procedure FreeItem(Item: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
  end;

  PDataViewer = ^TDataViewer;
  TDataViewer = object(TLongListViewer)
    Indicator: PDataViewIndicator;
    DB: PDataBase;
    SelList: PSelList;
    Buffer: PDataBuffer;
    BufOrg: Longint;
    Dividers: PWordArray;
    EditMode: Byte;
    EditItem: PDataRec;
    SelField: Byte;
    SearchingAll: Boolean;
    Replacing: Boolean;
    FoundPos: Word;
    FoundLen: Byte;
    FoundFlag: Boolean;
    DoRedraw: Boolean;
    HistLock: Byte;
    IncSearchStr: String[IncSearchLen];
    IncSearchPos: Longint;
    IncSearchOpt: Word;
    IncSearch: Boolean;
    IsSearchingFrom: Boolean;
{Added 2006.01.10 }
    UpdateTicks: Word;
    constructor Init(var Bounds: TRect; AHScrollBar: PScrollBar;
      AVScrollBar: PLongScrollBar; AIndicator: PDataViewIndicator;
      ADataBase: PDataBase);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure FocusItem(Item: Longint); virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    function GetCopyText(Item: Longint; MaxLen: Integer): String; virtual;
    function GetText(Item: Longint; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function IsSelected(Item: Longint): Boolean; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure InitViewer;
    procedure DoneViewer;
    procedure InitSelList;
    procedure DoneSelList;
    procedure InitBuffer;
    procedure DoneBuffer;
    procedure InitDividers;
    procedure DoneDividers;
    function SetSelect(Item: Longint; On: Boolean): Boolean;
    procedure SelectFocused(Down: Boolean);
    procedure ReRead(const Name: String; CompareName: Boolean);
    procedure Reload;
    procedure Redraw;
    function GetItemPtr(Item: Longint): PDataRec;
    function GetMemoFieldNum: Integer;
    procedure StartEditor(AMode: Byte);
    procedure EndEditor(Ok: Boolean);
    procedure SortData;
    procedure DeleteRecords;
    procedure PackDataBase;
    procedure ZapDataBase;
    procedure UpdateDBChanges(NewFocused: Longint; FreeSel: Boolean);
    function SaveOnExit: Word;
    procedure UpdateSourceTime;
    function CursorAtDiv(APos: Integer): Boolean;
    procedure CursorLeft;
    procedure CursorRight;
    procedure CursorHome;
    procedure CursorEnd;
    procedure CursorCtrlHome;
    procedure CursorCtrlEnd;
    procedure CursorPrev;
    procedure CursorNext;
    procedure CursorOnField(AField: Byte);
    procedure JustifyField;
    procedure Edit(C: Char);
    procedure MarkItems(Mark: Char);
    function Find(const Match: String; AOptions: Word): Boolean;
    procedure PasteText;
    procedure FieldDlg;
    procedure ViewMemo(Hex: Boolean);
    procedure FindDlg;
    procedure ReplaceDlg;
    procedure InitIncSearch;
    procedure DoneIncSearch;
    procedure DoIncSearch(C: Char);
    procedure GoToLineNumber;
    procedure ImportData;
    procedure ExportData;
    procedure ImportFromClipboard;
    procedure ExportToClipboard;
    procedure EditFields(AField: Byte);
    procedure SetXLATTable(const Name: FNameStr; AMode: Byte);
    procedure ClearXLATTable(AMode: Byte);
    procedure ToggleConvertDates;
    procedure ToggleValidate;
    procedure Popup(AOrigin: TPoint);
  end;

  PDataWindow = ^TDataWindow;
  TDataWindow = object(TWindow)
    Fields: PFieldViewer;
    Viewer: PDataViewer;
    Invalid: Boolean;
    constructor Init(Bounds: TRect; ADataBase: PDataBase);
    constructor Load(var S: TStream);
    procedure Close; virtual;
    function GetPalette: PPalette; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
    function Valid(Command: Word): Boolean; virtual;
  end;

const
  BufDelta = 128;

  sfHistLocked  = $1000;
  sfSelList     = $2000;
  sfFieldCursor = $4000;

  ofInXLAT  = $0400;
  ofOutXLAT = $0800;

  emNo = 0;
  emAddEmpty = 1;
  emAddFull = 2;
  emInsertEmpty = 3;
  emInsertFull = 4;
  emOverwrite = 5;

  CFieldViewer       = #6;
  CDataViewIndicator = #1#2#3;
  CDataViewer        = #7#8#9#10;
  CDataWindow        = #185#186#187#188#189#190#191#192#193#194;

  CDataColor         = #$38#$3F#$3A#$13#$13#$31#$30#$5F#$3F#$3E;
  CDataBlackWhite    = #$07#$0F#$07#$70#$70#$0F#$07#$70#$0F#$07;
  CDataMonochrome    = #$07#$0F#$07#$70#$70#$0F#$07#$70#$0F#$07;

  CDBExtraIndex      = 209;
  CDBExtra           = #209#210;
  CDBExtraColor      = #$3E#$5E;
  CDBExtraBW         = #$0F#$7F;
  CDBExtraMono       = #$0F#$01;

function GetDBFInfo(const AName: FNameStr; AList: PCollection): Boolean;
procedure OpenDataViewer(const AName: FNameStr; InfoPtr: Pointer);

implementation

uses Dos, CNCrt, Strings, WinIcons, Menus, App, MsgBox, Gauges, StdDlg,
  DBFields, HistList, FindDlg, FEditor, Clipbrd, EditFile, OpenPrim, ExecPrim,
  EditMsg, TxtView, HexView, RegExp, History, Popups, Keyboard, CNInputs,
  HeapUMB, LFN, Disks, DosTools, TPString, Consts, Commands, Defaults;

const
  DataViewerCommands =
    [cmFind, cmReplace, cmSearchAgain, cmIncSearch, cmGoToLine];

procedure DrawOpenStatus(const AName: FNameStr);
begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Loading dBASE viewer ' + TrimmedName(AName, 46) + '.');
end;

constructor TFieldViewer.Init(var Bounds: TRect; AHScrollBar: PScrollBar;
  ADataBase: PDataBase);
begin
  Inherited Init(Bounds, 1, AHScrollBar, nil);
  Options := Options and not ofSelectable;
  GrowMode := gfGrowHiX;
  DB := ADataBase;
  InitFieldLine;
end;

destructor TFieldViewer.Done;
begin
  DoneFieldLine;
  Inherited Done;
end;

procedure TFieldViewer.ChangeBounds(var Bounds: TRect);
begin
  Inherited ChangeBounds(Bounds);
  HScrollBar^.SetRange(0, LineSize - Size.X);
end;

procedure TFieldViewer.Draw;
var
  C: Word;
  B: TDrawBuffer;
begin
  C := GetColor(1);
  MoveChar(B, ' ', C, Size.X);
  MoveStr(B, GetText(0, Size.X), C);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TFieldViewer.GetPalette: PPalette;
const
  P: String[Length(CFieldViewer)] = CFieldViewer;
begin
  GetPalette := @P;
end;

function TFieldViewer.GetText(Item: Integer; MaxLen: Integer): String;
var
  I, C: Integer;
  S: String;
begin
  I := HScrollBar^.Value;
  if I + MaxLen > LineSize then C := LineSize - I
  else C := MaxLen;
  Move(PByteArray(FieldLine)^[I], S[1], C);
  S[0] := Char(C);
  GetText := S;
end;

procedure TFieldViewer.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evBroadcast) and
     (Event.Command = cmScrollBarChanged) and
     (Event.InfoPtr = HScrollBar) then DrawView;
  Inherited HandleEvent(Event);
end;

procedure TFieldViewer.InitFieldLine;
var
  C: Byte;
  I, J: Integer;
  Len: Word;
  P: PFieldRec;
begin
  LineSize := DB^.Header^.RecordLen + DB^.Fields^.Count - 1;
{  GetMem(FieldLine, LineSize + 1);}
  GetMemUMB(FieldLine, LineSize + 1);
  FillChar(FieldLine^, LineSize, ' ');
  Char(PByteArray(FieldLine)^[0]) := ' ';
  J := 1;
  for I := 0 to DB^.Fields^.Count - 1 do
  begin
    P := DB^.Fields^.At(I);
    Len := DB^.GetFieldLen(P);
    if Len > SizeOf(P^.Name) then C := SizeOf(P^.Name)
    else C := Len;
    Move(P^.Name, PByteArray(FieldLine)^[J], C);
    Inc(J, Len);
    PByteArray(FieldLine)^[J] := Byte('³');
    Inc(J);
  end;
  SetRange(1);

  if LineSize - Size.X <> HScrollBar^.Max then
  begin
    Owner^.EventMask := Owner^.EventMask and not evBroadcast;
    HScrollBar^.SetRange(0, LineSize - Size.X);
    Owner^.EventMask := Owner^.EventMask or evBroadcast;
  end;

{
  if (LineSize > Size.X) and (HScrollBar^.Max < LineSize - Size.X) then
    HScrollBar^.SetRange(0, LineSize - Size.X);
}
end;

procedure TFieldViewer.DoneFieldLine;
begin
  if FieldLine <> nil then
{    FreeMem(FieldLine, LineSize + 1);}
    FreeMemUMB(FieldLine, LineSize + 1);
end;

procedure TDataBuffer.FreeItem(Item: Pointer);
begin
  if Item = nil then Exit;
{
  FreeMem(PDataRec(Item)^.Rec, RecSize);
  FreeMem(Item, SizeOf(TDataRec));
}
  FreeMemUMB(PDataRec(Item)^.Rec, RecSize);
  FreeMemUMB(Item, SizeOf(TDataRec));
end;

procedure TDataViewIndicator.Draw;
var
  C: Char;
  Color: Byte;
  Params: Array[0..1] of Longint;
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
  Params[0] := Index;
  if SelCount = 0 then Params[1] := Percent
  else Params[1] := SelCount;
  FormatStr(S, ' %d (%d) ', Params);
  if SelCount = 0 then System.Insert('%', S, Length(S) - 1);
  MoveStr(B[3], S, Color);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TDataViewIndicator.GetPalette: PPalette;
const
  P: String[Length(CDataViewIndicator)] = CDataViewIndicator;
begin
  GetPalette := @P;
end;

const
  ipNo = 0;
  ipSave = 1;
  ipRecNum = 2;
  ipUnsel = 3;

function TDataViewIndicator.GetMousePos(X: Integer): Byte;
var
  S: String;
begin
  if PDataWindow(Owner)^.Viewer^.EditMode <> emNo then
    GetMousePos := ipSave
  else
  begin
    FormatStr(S, '%d', Index);
    if (SelCount = 0) or (X < 5 + Length(S)) then
      GetMousePos := ipRecNum
    else GetMousePos := ipUnsel;
  end;
end;

procedure TDataViewIndicator.HandleEvent(var Event: TEvent);
var
  B: Byte;
  Mouse: TPoint;
begin
  Inherited HandleEvent(Event);
  if (Event.What = evMouseDown) and MouseInView(Event.Where) then
  begin
    MakeLocal(Event.Where, Mouse);
    B := GetMousePos(Mouse.X);
    if B in [ipSave, ipUnsel] then
    begin
      Pending.What := evKeyDown;
      if B = ipUnsel then Pending.KeyCode := kbGrayMinus
      else if Event.Buttons = mbRightButton then
        Pending.KeyCode := kbEsc
      else Pending.KeyCode := kbEnter;
      Event.What := evNothing;
    end
    else if B = ipRecNum then
    begin
      Message(Application, evCommand, cmGoToLine, nil);
      Event.What := evNothing;
    end;
  end;
end;

procedure TDataViewIndicator.SetState(AState: Word; Enable: Boolean);
begin
  Inherited SetState(AState, Enable);
  DrawView;
end;

function TDataViewIndicator.GetMouseShape(var Event: TEvent): Char;
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
    if B = ipSave then C := ''
    else if B = ipRecNum then C := ''
    else if B = ipUnsel then C := 'û';
  end;
  GetMouseShape := C;
end;

function TSelList.Compare(Key1, Key2: Pointer): Integer;
begin
  if Longint(Key1) = Longint(Key2) then Compare := 0
  else if (LongRec(Key1).Hi < LongRec(Key2).Hi) or
    ((LongRec(Key1).Hi = LongRec(Key2).Hi) and
     (LongRec(Key1).Lo < LongRec(Key2).Lo)) then Compare := 1
  else Compare := -1;
end;

procedure TSelList.FreeItem(Item: Pointer);
begin
end;

function TSelList.GetItem(var S: TStream): Pointer;
var
  L: Longint;
begin
  S.Read(L, SizeOf(Longint));
  GetItem := Pointer(L);
end;

procedure TSelList.PutItem(var S: TStream; Item: Pointer);
begin
  S.Write(Item, SizeOf(Longint));
end;

constructor TDataViewer.Init(var Bounds: TRect; AHScrollBar: PScrollBar;
  AVScrollBar: PLongScrollBar; AIndicator: PDataViewIndicator;
  ADataBase: PDataBase);
begin
  Inherited Init(Bounds, 1, AHScrollBar, AVScrollBar);
  GrowMode := gfGrowHiX + gfGrowHiY;
  Indicator := AIndicator;
  DB := ADataBase;
  InitViewer;
end;

constructor TDataViewer.Load(var S: TStream);
begin
  Inherited Load(S);
  GetPeerViewPtr(S, Indicator);
  if State and sfFieldCursor <> 0 then S.Read(SelField, SizeOf(Byte));
  if State and sfSelList <> 0 then SelList := PSelList(S.Get);
  if State and sfHistLocked <> 0 then S.Read(HistLock, SizeOf(HistLock));
end;

destructor TDataViewer.Done;
begin
  DoneViewer;
  if DB <> nil then Dispose(DB, Done);
  Inherited Done;
end;

procedure TDataViewer.Draw;
var
  NormalColor, CurFieldColor, FocusedColor, EditColor,
  SelectedColor, SelFocusedColor, Color: Byte;
  I: Integer;
  Item: Longint;
  B: TDrawBuffer;

procedure CalcSelField;
begin
  SelField := 0;
  while (SelField < DB^.Fields^.Count - 1) and
    (Dividers^[SelField] < HScrollBar^.Value + Cursor.X) do Inc(SelField);
end;

procedure HilitSelField;
var
  BufPos, Len: Integer;
begin
  if FoundFlag then BufPos := FoundPos + SelField - 1
  else if SelField = 0 then BufPos := 0
  else BufPos := Dividers^[SelField - 1];
  Dec(BufPos, HScrollBar^.Value - 1);
  if FoundFlag then
    Len := FoundLen + DB^.GetFieldNum(FoundPos + FoundLen - 1) - SelField
  else Len := DB^.GetFieldLen(PFieldRec(DB^.Fields^.At(SelField)));
  while (BufPos < 0) and (Len > 0) do
  begin
    Inc(BufPos);
    Dec(Len);
  end;
  while BufPos + Len > Size.X do Dec(Len);
  if Len <= 0 then Exit;
  if EditMode <> emNo then Color := CurFieldColor
  else if IsSelected(Item) then Color := SelFocusedColor
  else Color := FocusedColor;
  MoveChar(B[BufPos], #0, Color, Len);
end;

begin
  NormalColor := GetColor(1);
  FocusedColor := GetColor(2);
  EditColor := GetColor(3);
  CurFieldColor := GetColor(4);
  SelectedColor := Byte(Application^.GetPalette^[CDBExtraIndex]);
  SelFocusedColor := Byte(Application^.GetPalette^[CDBExtraIndex + 1]);
  if EditMode <> emNo then CalcSelField;
  for I := 0 to Size.Y - 1 do
  begin
    MoveChar(B, ' ', NormalColor, Size.X);
    Item := I + TopItem;
    if Item < Range then
    begin
      if Focused = Item then
      begin
        if EditMode <> emNo then Color := EditColor
        else if IsSelected(Item) then
          if State and sfFieldCursor <> 0 then Color := SelectedColor
          else Color := SelFocusedColor
        else if State and sfFieldCursor <> 0 then Color := NormalColor
        else Color := FocusedColor;
        if EditMode = emNo then SetCursor(Dividers^[SelField] -
	  DB^.GetFieldLen(PFieldRec(DB^.Fields^.At(SelField))) -
          HScrollBar^.Value, I);
      end
      else if IsSelected(Item) then Color := SelectedColor
      else Color := NormalColor;
      MoveStr(B, GetText(Item, Size.X), Color);
      if (Focused = Item) and ((EditMode <> emNo) or
         (State and sfFieldCursor <> 0)) then HilitSelField;
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
  if Range = 0 then SetCursor(0, 0);
end;

procedure TDataViewer.FocusItem(Item: Longint);
begin
  if (Item < 0) or (Range = 0) then Item := 0
  else if Item >= Range then Item := Range - 1;
  Inherited FocusItem(Item);
  with Indicator^ do
  begin
    if Range = 0 then
    begin
      Index := 0;
      Percent := 0;
      SelCount := 0;
    end
    else
    begin
      Index := Focused + 1;
      Percent := (Index * 100) div Range;
      SelCount := SelList^.Count;
    end;
    Modified := False;
    DrawView;
  end;
  if not FoundFlag then
  begin
    FoundPos := 0;
    FoundLen := 0;
  end;
end;

function TDataViewer.GetHelpCtx: Word;
var
  B: Boolean;
  L: Longint;
begin
  if State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else if IncSearch then GetHelpCtx := hcEditIncSearch
  else GetHelpCtx := hcDataViewer;

{Added 2006.01.10 }
  if (MemW[$40:$6C] - UpdateTicks >= 50) then
  begin
    UpdateTicks := MemW[$40:$6C];
    if not GetFileTime(DB^.Name^, L) then UpdateSourceTime
    else if L <> DB^.Time then
      if EditMode <> emNo then UpdateSourceTime
      else
      begin
	B := Focused >= Range - 1;
	Reload;
	if B then FocusItem(Range);
      end;
  end;
end;

function TDataViewer.GetPalette: PPalette;
const
  P: String[Length(CDataViewer)] = CDataViewer;
begin
  GetPalette := @P;
end;

function TDataViewer.GetCopyText(Item: Longint; MaxLen: Integer): String;
var
  P: PDataRec;
begin
  if (EditMode <> emNo) or (State and sfFieldCursor <> 0) then
  begin
    P := GetItemPtr(Item);
    if P = nil then GetCopyText := ''
    else GetCopyText := Trim(DB^.GetFieldStr(SelField, P^.Rec^));
  end
  else GetCopyText := Inherited GetCopyText(Item, MaxLen);
end;

function TDataViewer.GetText(Item: Longint; MaxLen: Integer): String;
var
  DivIndex, StrPos: Byte;
  ScrollPos, RecPos: Integer;
  P: PDataRec;
  S: String;
begin
  P := GetItemPtr(Item);
  if P = nil then S := ''
  else
  begin
    DivIndex := 0;
    ScrollPos := HScrollBar^.Value;
    StrPos := 1;
    while Dividers^[DivIndex] < ScrollPos do Inc(DivIndex);
    RecPos := ScrollPos - DivIndex;
    repeat
      if Dividers^[DivIndex] = ScrollPos then
      begin
        if DivIndex < DB^.Fields^.Count - 2 then Inc(DivIndex);
        S[StrPos] := '³';
        Inc(ScrollPos);
        Inc(StrPos);
      end;
      S[StrPos] := Char(P^.Rec^[RecPos]);
      Inc(ScrollPos);
      Inc(RecPos);
      Inc(StrPos);
    until (RecPos >= Buffer^.RecSize) or (StrPos > MaxLen);
    Dec(StrPos);
    S[0] := Char(StrPos);
  end;
  GetText := S;
end;

procedure TDataViewer.HandleEvent(var Event: TEvent);
var
  SameName, MouseDown, Processed: Boolean;
  C: Word;
  L, NewItem: Longint;
  V: PDataViewer;
  Mouse: TPoint;
  S: String;

procedure OpenAnother;
var
  SaveExplode: Boolean;
begin
  SaveExplode := DoExplode;
  DoExplode := False;
  Desktop^.Lock;
  Desktop^.EventMask := Desktop^.EventMask and not evBroadcast;
  Message(Application, evCommand, cmOpenDataViewer, DB^.Name);
  Desktop^.EventMask := Desktop^.EventMask or evBroadcast;
  V := Message(Desktop, evBroadcast, cmOpenDataViewer, DB^.Name);
  if (V <> nil) and (V <> @Self) and
     (V^.Owner^.State and sfActive <> 0) then
  begin
    V^.SelField := SelField;
    if State and sfFieldCursor <> 0 then
    begin
      V^.State := V^.State or sfFieldCursor;
      V^.JustifyField;
    end;
    V^.FocusItem(Focused);
  end;
  Desktop^.Unlock;
  DoExplode := SaveExplode;
end;

procedure MoveAbout;
begin
  case CtrlToArrow(Event.KeyCode) of
    kbLeft: CursorLeft;
    kbRight: CursorRight;
    kbHome: CursorHome;
    kbEnd: CursorEnd;
    kbCtrlHome: CursorCtrlHome;
    kbCtrlEnd: CursorCtrlEnd;
    kbShiftTab, kbCtrlLeft: CursorPrev;
    kbTab, kbCtrlRight: CursorNext;
    else Exit;
  end;
  Event.InfoInt := HScrollBar^.Value;
  HScrollBar^.Value := MaxInt;
  HScrollBar^.SetValue(Event.InfoInt);
  SetCursor(Cursor.X, Cursor.Y);
  Event.What := evNothing;
end;

procedure GoWhileKeyDown(Key: Byte);
begin
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
      72: FocusItem(Focused - 1);
      73: FocusItem(Focused - Size.Y);
      80: FocusItem(Focused + 1);
      81: FocusItem(Focused + Size.Y);
    end;
    if KbdDelay <> 0 then Delay(KbdDelay);
  until False;
end;

procedure GoUp;
begin
  JustifyField;
  if MouseDown or (GetShiftState and (kbLeftShift + kbRightShift) <> 0) then
  begin
    SetSelect(Focused, False);
    FocusItem(Focused - 1);
    if Focused = 0 then DrawView;
  end
  else
  begin
    FocusItem(Focused - 1);
    if (KbdStatus = 72) or (KbdStatus = 224) then GoWhileKeyDown(72);
  end;
end;

procedure GoDown;
begin
  JustifyField;
  if MouseDown or (GetShiftState and (kbLeftShift + kbRightShift) <> 0) then
  begin
    SetSelect(Focused, True);
    FocusItem(Focused + 1);
    if Focused = Range - 1 then DrawView;
  end
  else
  begin
    FocusItem(Focused + 1);
    if (KbdStatus = 80) or (KbdStatus = 224) then GoWhileKeyDown(80);
  end;
end;

procedure GoLeft;
begin
  JustifyField;
  if SelField <> 0 then Dec(SelField);
  if SelField = 0 then Event.InfoInt := 0
  else Event.InfoInt := Dividers^[SelField - 1];
  if Event.InfoInt < HScrollBar^.Value then
    HScrollBar^.SetValue(Event.InfoInt);
  DrawView;
end;

procedure GoRight;
begin
  JustifyField;
  if SelField < DB^.Fields^.Count - 1 then Inc(SelField);
  Event.InfoInt := Dividers^[SelField - 1];
  if Event.InfoInt >= HScrollBar^.Value + Size.X - 1 then
    HScrollBar^.SetValue(Event.InfoInt);
  DrawView;
end;

procedure GoPgUp;
var
  L, N: Longint;
begin
  JustifyField;
  if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
  begin
    N := Focused - Size.Y;
    for L := Focused downto N + 1 do SetSelect(L, False);
    FocusItem(N);
    if Focused = 0 then DrawView;
  end
  else
  begin
    FocusItem(Focused - Size.Y);
    if (KbdStatus = 73) or (KbdStatus = 224) then GoWhileKeyDown(73);
  end;
end;

procedure GoPgDn;
var
  L, N: Longint;
begin
  JustifyField;
  if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
  begin
    N := Focused + Size.Y;
    for L := Focused to N - 1 do
      if not SetSelect(L, True) then Break;
    FocusItem(N);
    if Focused = Range - 1 then DrawView;
  end
  else
  begin
    FocusItem(Focused + Size.Y);
    if (KbdStatus = 81) or (KbdStatus = 224) then GoWhileKeyDown(81);
  end;
end;

function GetScrollField: Byte;
var
  B: Byte;
begin
  B := 0;
  while (B < DB^.Fields^.Count - 1) and
    (Dividers^[B] <= HScrollBar^.Value) do Inc(B);
  GetScrollField := B;
end;

procedure GoNext;
var
  B: Byte;
begin
  B := GetScrollField;
  HScrollBar^.SetValue(Dividers^[B]);
end;

procedure GoPrev;
var
  B: Byte;
begin
  B := GetScrollField;
  if B < 2 then HScrollBar^.SetValue(0)
  else HScrollBar^.SetValue(Dividers^[B - 2]);
end;

procedure HandleOtherKeys;
var
  DoMultiScroll: Boolean;
begin
  DoMultiScroll := (KeyboardOptions and koDisableMultiScroll = 0) and
    (GetShiftState and kbScrollState <> 0) and
    not MultiScrolling and IsScrollKey(Event.KeyCode);
  case CtrlToArrow(Event.KeyCode) of
    kbUp: GoUp;
    kbDown: GoDown;
    kbLeft:
      if State and sfFieldCursor <> 0 then GoLeft
      else if DoMultiScroll then HScrollBar^.HandleEvent(Event)
      else Exit;
    kbRight:
      if State and sfFieldCursor <> 0 then GoRight
      else if DoMultiScroll then HScrollBar^.HandleEvent(Event)
      else Exit;
    kbHome:
      begin
        if State and sfFieldCursor <> 0 then
        begin
          SelField := 0;
          DrawView;
        end;
        if DoMultiScroll then HScrollBar^.HandleEvent(Event)
        else Exit;
      end;
    kbEnd:
      begin
        if State and sfFieldCursor <> 0 then
        begin
          SelField := DB^.Fields^.Count - 1;
          DrawView;
        end;
        if DoMultiScroll then HScrollBar^.HandleEvent(Event)
        else Exit;
      end;
    kbCtrlHome, kbCtrlEnd, kbCtrlPgUp, kbCtrlPgDn:
      if DoMultiScroll then Inherited HandleEvent(Event) else Exit;
    kbCtrlLeft, kbCtrlRight:
      if DoMultiScroll then HScrollBar^.HandleEvent(Event) else Exit;
    kbPgUp: GoPgUp;
    kbPgDn: GoPgDn;
    kbTab: GoNext;
    kbShiftTab: GoPrev;
    kbAltA: OpenAnother;
    kbAltI: ImportData;
    kbAltV: ExportData;
    kbShiftF2: EditFields(SelField);
    else Exit;
  end;
  if DoMultiScroll then MultiScroll(PWindow(Owner), Event.KeyCode);
  Event.What := evNothing;
end;

procedure SelectAll;
var
  L: Longint;
begin
  if DB^.Header^.NumRecords = 0 then Exit;
  DrawStatusLine('Selecting all records in the database.');
  for L := 0 to DB^.Header^.NumRecords - 1 do
    if ((KbdStatus = 1) and AbortAction) or
      not SetSelect(L, True) then Break;
  DrawView;
end;

begin
  if (Event.What = evKeyDown) and (Event.CharCode in WordStarChars) then
    ConvertWSKey(WordStarKeys, Event);
  MouseDown := False;
  if Event.What = evMouseDown then
  begin
    if IncSearch then DoneIncSearch
    else if DoRedraw then Redraw;
    if Event.Buttons = mbRightButton then
    begin
      repeat until not MouseEvent(Event, evMouseDown);
      Popup(Event.Where);
      Event.What := evNothing;
      Exit;
    end;
    if EditMode <> emNo then
    begin
      MakeLocal(Event.Where, Mouse);
      if not MouseInView(Event.Where) or (TopItem + Mouse.Y <> Focused) then
      begin
        Event.What := evNothing;
        Exit;
      end;
      repeat
        MakeLocal(Event.Where, Mouse);
        if MouseInView(Event.Where) then
        begin
          if Mouse.X < DB^.Header^.RecordLen + DB^.Fields^.Count - 1 then
            Cursor.X := Mouse.X;
          if (HScrollBar^.Value + Cursor.X = 0) or
            CursorAtDiv(HScrollBar^.Value + Cursor.X) then
          begin
            Event.What := evKeyDown;
            Event.KeyCode := kbRight;
            MoveAbout;
          end
          else
          begin
            SetCursor(Cursor.X, Cursor.Y);
            DrawView;
          end;
        end
        else
        begin
          Mouse.X := 0;
          MakeGlobal(Mouse, Mouse);
          if Event.Where.X < Mouse.X then Event.KeyCode := kbLeft
          else if Event.Where.X >= Mouse.X + Size.X then
            Event.KeyCode := kbRight
          else Continue;
          Event.What := evKeyDown;
          MoveAbout;
        end;
      until not MouseEvent(Event, evMouseMove + evMouseAuto);
      if Event.Double then EndEditor(True);
      Event.What := evNothing;
    end
    else if not Event.Double then
    repeat
      MakeLocal(Event.Where, Mouse);
      if MouseInView(Event.Where) then
      begin
        if State and sfFieldCursor <> 0 then
        begin
          SelField := 0;
          while (SelField < DB^.Fields^.Count - 1) and
            (Dividers^[SelField] <= HScrollBar^.Value + Mouse.X) do
              Inc(SelField);
        end;
        NewItem := TopItem + Mouse.Y;
        if MouseDown then
          if NewItem > Focused then
            for L := Focused to NewItem - 1 do
              if not SetSelect(L, True) then Break else
          else if NewItem < Focused then
            for L := Focused downto NewItem + 1 do
              SetSelect(L, False);
        if NewItem <> Focused then FocusItem(NewItem)
        else if State and sfFieldCursor <> 0 then DrawView;
        MouseDown := True;
      end
      else
      begin
        MouseDown := True;
        Mouse.X := 0;
        Mouse.Y := 0;
        MakeGlobal(Mouse, Mouse);
        if Event.Where.X < Mouse.X then GoLeft
        else if Event.Where.X >= Mouse.X + Size.X then GoRight;
        if Event.Where.Y < Mouse.Y then GoUp
        else if Event.Where.Y >= Mouse.Y + Size.Y then GoDown;
      end;
    until not MouseEvent(Event, evMouseMove + evMouseAuto);
    MouseDown := False;
  end
  else if Event.What = evKeyDown then
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
         (Event.KeyCode = kbShiftF12) then Exit;
      DoneIncSearch;
    end
    else if DoRedraw then Redraw;
    if Cursor.Y >= Size.Y then
    begin
      Inc(TopItem, Cursor.Y - Size.Y + 1);
      SetCursor(Cursor.X, Size.Y - 1);
      DrawView;
    end;
    if EditMode <> emNo then
    begin
      if Cursor.X >= Size.X then
      begin
        HScrollBar^.SetValue(HScrollBar^.Value + Cursor.X - Size.X + 1);
        SetCursor(Size.X - 1, Cursor.Y);
        DrawView;
      end;
      if Event.KeyCode = kbDel then Event.CharCode := ^G;
      case CtrlToArrow(Event.KeyCode) of
        kbEnter, kbEsc:
          begin
            EndEditor(Event.KeyCode = kbEnter);
            Event.What := evNothing;
          end;
        kbIns:
          begin
            if State and sfCursorIns = 0 then BlockCursor
            else NormalCursor;
            Event.What := evNothing;
          end;
        kbUp, kbDown, kbPgDn, kbPgUp,
        kbCtrlPgDn, kbCtrlPgUp: Event.What := evNothing;
        else if Event.CharCode in [^G, ^H, ^Y, ^Z, #32..#255] then
        begin
          Edit(Event.CharCode);
          Event.What := evNothing;
        end
        else if Event.CharCode in [#0, #9] then MoveAbout;
      end;
    end
    else if (Event.KeyCode = kbEnter) or (Event.KeyCode = kbCtrlEnter) or
      (Event.KeyCode = kbAltJ) then
    begin
      if GetShiftState and kbAltShift <> 0 then
        Event.InfoByte := emOverwrite
      else if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
        if GetShiftState and kbCtrlShift <> 0 then
          Event.InfoByte := emInsertFull
        else Event.InfoByte := emInsertEmpty
      else if GetShiftState and kbCtrlShift <> 0 then
        Event.InfoByte := emAddFull
      else Event.InfoByte := emAddEmpty;
      StartEditor(Event.InfoByte);
      Event.What := evNothing;
    end
    else if (Event.CharCode = #32) and
      (GetShiftState and kbCtrlShift <> 0) then
    begin
      StartEditor(emOverwrite);
      Event.What := evNothing;
    end
    else if (Event.CharCode = #32) or (Event.KeyCode = kbIns) then
    begin
      SelectFocused(True);
      Event.What := evNothing;
    end
    else if Event.KeyCode = kbGrayMinus then
    begin
      DoneSelList;
      InitSelList;
      FocusItem(Focused);
      DrawView;
      Event.What := evNothing;
    end
    else if (Event.KeyCode = kbDel) or (Event.KeyCode = kbCtrlDel) then
    begin
      if Event.KeyCode = kbDel then Event.CharCode := '*'
      else Event.CharCode := ' ';
      MarkItems(Event.CharCode);
      Event.What := evNothing;
    end
    else if Event.KeyCode = kbEsc then
    begin
      Event.What := evCommand;
      Event.Command := cmClose;
      Event.InfoPtr := Owner;
    end
    else if Event.KeyCode = kbCtrl2 then InitIncSearch
    else case Event.CharCode of
      ^L: Find(SearchData.MatchStr,
        SearchData.Options or frFromCursor);
      ^B: Find(SearchData.MatchStr,
        SearchData.Options or (frFromCursor + frBackward));
      ^U: Find(SearchData.MatchStr,
        (SearchData.Options or frFromCursor) and not frBackward);
      '<', '': SetXLATTable('', dcXLATIN);
      '>', 'ž': SetXLATTable('', dcXLATOUT);
      '{', '•': ClearXLATTable(dcXLATIN);
      '}', 'š': ClearXLATTable(dcXLATOUT);
      ^\: Message(Desktop, evBroadcast, cmReopen, DB^.Name);
      else HandleOtherKeys;
    end;
  end;
  if Event.What = evCommand then
  begin
    if IncSearch then
      if (Event.Command <> cmPaste) and
         (Event.Command <> cmPasteFromMT) then DoneIncSearch
      else {}
    else if DoRedraw then Redraw;
    Processed := True;
    case Event.Command of
      cmCopy: if EditMode <> emNo then CopyText else ExportToClipboard;
      cmPaste: if EditMode <> emNo then PasteText
        else if IncSearch then IncSearchFromClipboard(@Self)
        else ImportFromClipboard;
      cmPuzzle: FieldDlg;
      cmRunItem, cmNewItemPos: if EditMode = emNo then
        ViewMemo(Event.Command = cmNewItemPos);
      cmFind: if EditMode = emNo then FindDlg;
      cmReplace: if EditMode = emNo then ReplaceDlg;
      cmSearchAgain: if EditMode = emNo then Find(SearchData.MatchStr,
        SearchData.Options or frFromCursor);
      cmIncSearch: InitIncSearch;
      cmGoToLine: if EditMode = emNo then GoToLineNumber;
      cmInXLAT: if EditMode = emNo then SetXLATTable('', dcXLATIN);
      cmOutXLAT: if EditMode = emNo then SetXLATTable('', dcXLATOUT);
      cmClearInXLAT: if EditMode = emNo then ClearXLATTable(dcXLATIN);
      cmClearOutXLAT: if EditMode = emNo then ClearXLATTable(dcXLATOUT);
      cmDBConvertDates: if EditMode = emNo then ToggleConvertDates;
      cmDBValidate: if EditMode = emNo then ToggleValidate;
      cmImport: if EditMode = emNo then ImportData;
      cmExport: if EditMode = emNo then ExportData;
      cmWriteTo: ImpExpOptDlg;
      cmModifyValue: FieldSeparatorDlg;
      cmDeleteItem: if EditMode = emNo then DeleteRecords;
      cmReset: if EditMode = emNo then SortData;
      cmModifyItem: if EditMode = emNo then PackDataBase;
      cmHide: if EditMode = emNo then ZapDataBase;
      cmNewItem: if EditMode = emNo then
	begin
	  State := State xor sfFieldCursor;
	  DrawView;
	end;
      cmSelectAll: SelectAll;
      cmPopUp:
        begin
          Mouse.X := Size.X div 2;
          Mouse.Y := 0;
          MakeGlobal(Mouse, Mouse);
          Popup(Mouse);
        end;
      else Processed := False;
    end;
    if Processed then Event.What := evNothing;
  end;
  Inherited HandleEvent(Event);
  if Event.What = evBroadcast then
    case Event.Command of
      cmListItemSelected:
        begin
          Event.What := evKeyDown;
          Event.KeyCode := kbEnter;
          HandleEvent(Event);
        end;
      cmOpenDataViewer:
        begin
          SameName :=
            CompUCString(PString(Event.InfoPtr)^, DB^.Name^) = Equal;
          if not SameName and not SameWinFlag then Exit;
          if not SameName then ReRead(PString(Event.InfoPtr)^, True);
          PWindow(Owner)^.Deiconize;
          Owner^.Show;
          Owner^.Select;
          ClearEvent(Event);
        end;
      cmUpdateTime: if (Event.InfoPtr = nil) or
        (CompUCString(PString(Event.InfoPtr)^, DB^.Name^) = Equal) then
          UpdateSourceTime;
      cmGetSource: if Owner^.State and sfVisible <> 0 then
        begin
          Event.What := evNothing;
          Event.InfoPtr := DB^.Name;
        end;
      cmQuit:
        if Event.InfoPtr = nil then
        begin
          C := SaveOnExit;
          if C = cmCancel then ClearEvent(Event)
          else if C = cmYes then EndEditor(True);
        end;
      cmCountry: if EditMode = emNo then
        begin
          Buffer^.FreeAll;
          DrawView;
        end;
      cmlAPIChanged:
        begin
          lGetFileNameForChangedAPI(lAPIType(Event.InfoByte),
            DB^.Name^, S);
{
          DisposeStr(DB^.Name);
          DB^.Name := NewStr(S);
}
          DisposeStrUMB(DB^.Name);
          DB^.Name := NewStrUMB(S);
          DisposeStr(PWindow(Owner)^.Title);
          PWindow(Owner)^.Title := NewStr(S);
          PWindow(Owner)^.Frame^.DrawView;
          if PWindow(Owner)^.Icon <> nil then
            PWinIcon(PWindow(Owner)^.Icon)^.Update;
        end;
    end;
end;

function TDataViewer.IsSelected(Item: Longint): Boolean;
begin
  IsSelected := (SelList^.Count <> 0) and
    (SelList^.IndexOf(Pointer(Item)) <> -1);
end;

procedure TDataViewer.SetState(AState: Word; Enable: Boolean);

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
  if (AState = sfExposed) and Enable then Indicator^.Hide;
  if (AState = sfFocused) and Enable then
  begin
    Indicator^.Show;
    if EditMode <> emNo then
    begin
      EnableCommands(CopyCommands + PasteCommands + MTCommands);
      DisableCommands(DataViewerCommands + DeleteCommands +
        ModifyCommands + HideCommands + RunItemCommands +
        NewItemPosCommands + NewCommands + ImportCommands +
        ExportCommands + ResetCommands + DBInOutCommands);
    end
    else
    begin
      EnableCommands(PasteCommands + ImportCommands +
        DBInOutCommands + MTPasteCommands);
      if Range <> 0 then EnableCommands(
        CopyCommands + DataViewerCommands + DeleteCommands +
        ModifyCommands + HideCommands + NewCommands +
        ExportCommands + ResetCommands + MTCopyCommands)
      else DisableCommands(CopyCommands + MTCopyCommands +
        DataViewerCommands + DeleteCommands + ModifyCommands +
        HideCommands + NewCommands + ExportCommands + ResetCommands);
      if GetMemoFieldNum <> -1 then EnableCommands(
        RunItemCommands + NewItemPosCommands)
      else DisableCommands(RunItemCommands + NewItemPosCommands);
    end;
  end
  else if not Enable and
    (((AState = sfActive) and GetState(sfExposed)) or
     (AState = sfExposed)) then DisableCommands(
       CopyCommands + PasteCommands + MTCommands + DataViewerCommands +
       DeleteCommands + RunItemCommands + NewItemPosCommands +
       NewCommands + ImportCommands + ExportCommands + DBInOutCommands);
end;

procedure TDataViewer.Store(var S: TStream);
begin
  if SelList^.Count <> 0 then State := State or sfSelList
  else State := State and not sfSelList;
  Inherited Store(S);
  PutPeerViewPtr(S, Indicator);
  if State and sfFieldCursor <> 0 then S.Write(SelField, SizeOf(Byte));
  if State and sfSelList <> 0 then S.Put(SelList);
  if State and sfHistLocked <> 0 then S.Write(HistLock, SizeOf(HistLock));
end;

procedure TDataViewer.InitViewer;
var
  P: Byte;
  I: Integer;
  NewFocused: Longint;
  R: PHistoryRec;
  S: String;

function ScanHistory: Boolean;
begin
  ScanHistory := False;
  I := HistoryIndex(ReopenHistoryID, 'dBASE ' + DB^.Name^ + #$FF);
  if I = -1 then Exit;
  R := HistoryList^.At(I);
  S := R^.StrPtr^;
  if R^.Lock then
  begin
    HistLock := Byte(R^.Lock);
    State := State or sfHistLocked;
  end
  else State := State and not sfHistLocked;
  HistoryList^.AtFree(I);
  Dec(S[0], 10);
  S := System.Copy(S, Pos(#$FF, S) + 1, 255);
  P := Pos(#$FF, S);
  if P <> 0 then
  begin
    Val(Copy(S, P + 1, 3), SelField, I);
    if SelField >= DB^.Fields^.Count then SelField := 0;
    S[0] := Char(P - 1);
    State := State or sfFieldCursor;
    JustifyField;
  end;
  Val(S, NewFocused, I);
  ScanHistory := True;
end;

begin
  InitSelList;
  InitBuffer;
  InitDividers;
  SetRange(DB^.Header^.NumRecords);
  HScrollBar^.EventMask := evMouseDown + evKeyDown + evCommand;
  VScrollBar^.EventMask := evMouseDown + evKeyDown + evCommand;
  HideCursor;
  if ScanHistory then FocusItem(NewFocused);
  if Range = 0 then DB^.DoneDBF;
end;

procedure TDataViewer.DoneViewer;
begin
  DoneDividers;
  DoneBuffer;
  DoneSelList;
end;

procedure TDataViewer.InitSelList;
begin
  if SelList = nil then
    SelList := New(PSelList, Init(BufDelta, BufDelta));
end;

procedure TDataViewer.DoneSelList;
begin
  if SelList <> nil then
  begin
    Dispose(SelList, Done);
    SelList := nil;
  end;
end;

procedure TDataViewer.InitBuffer;
begin
  Buffer := New(PDataBuffer, Init(BufDelta, BufDelta));
  Buffer^.RecSize := DB^.Header^.RecordLen;
end;

procedure TDataViewer.DoneBuffer;
begin
  if Buffer <> nil then
  begin
    Buffer^.FreeItem(EditItem);
    Dispose(Buffer, Done);
  end;
end;

procedure TDataViewer.InitDividers;
var
  I, J: Integer;
begin
{  GetMem(Dividers, DB^.Fields^.Count * SizeOf(Word));}
  GetMemUMB(Dividers, DB^.Fields^.Count * SizeOf(Word));
  J := 0;
  for I := 0 to DB^.Fields^.Count - 1 do
  begin
    Inc(J, DB^.GetFieldLen(PFieldRec(DB^.Fields^.At(I))) + 1);
    Dividers^[I] := J;
  end;
end;

procedure TDataViewer.DoneDividers;
begin
  if Dividers <> nil then
{    FreeMem(Dividers, DB^.Fields^.Count * SizeOf(Word));}
    FreeMemUMB(Dividers, DB^.Fields^.Count * SizeOf(Word));
end;

function TDataViewer.SetSelect(Item: Longint; On: Boolean): Boolean;
var
  I: Integer;
begin
  if (Item < 0) or (Item >= Range) then
  else if On then
  begin
    if ((SelList^.Count = MaxCollectionSize) or
        ((SelList^.Count = SelList^.Limit) and
         (MaxAvail <= LongMul(SelList^.Limit +
          SelList^.Delta, 4) + $2000))) and
       (SelList^.IndexOf(Pointer(Item)) = -1) then
    begin
      Application^.OutOfMemory;
      SetSelect := False;
      Exit;
    end;
    SelList^.Insert(Pointer(Item))
  end
  else if SelList^.Search(Pointer(Item), I) then SelList^.AtFree(I);
  SetSelect := True;
end;

procedure TDataViewer.SelectFocused(Down: Boolean);
begin
  if Range = 0 then Exit;
  SetSelect(Focused, SelList^.IndexOf(Pointer(Focused)) = -1);
  if Down then FocusItem(Focused + 1);
  if Focused = Range - 1 then DrawView;
end;

procedure TDataViewer.ReRead(const Name: String; CompareName: Boolean);
var
  D: PDataBase;
begin
  if CompareName and
    (CompUCString(Name, DB^.Name^) = Equal) then Exit;
  D := New(PDataBase, Init(Name));
  if not D^.Valid then
  begin
    Dispose(D, Done);
    CouldNotOpenMsgBox(Name);
  end
  else
  begin
    DoneViewer;
    if DB <> nil then
    begin
      D^.Options := DB^.Options;
      if D^.Options and dbXLATIN <> 0 then
      begin
	D^.InXLATTable := DB^.InXLATTable;
	D^.ConvertFields(dcXLATIN);
      end;
      if D^.Options and dbXLATOUT <> 0 then
	D^.OutXLATTable := DB^.OutXLATTable;
      Dispose(DB, Done);
    end;
    PDataWindow(Owner)^.Fields^.DoneFieldLine;
    PDataWindow(Owner)^.Fields^.DB := D;
    PDataWindow(Owner)^.Fields^.InitFieldLine;
    PDataWindow(Owner)^.Fields^.DrawView;
    DB := D;
    InitViewer;
    DisposeStr(PWindow(Owner)^.Title);
    PWindow(Owner)^.Title := NewStr(Name);
    FocusItem(0);
    Redraw;
    PWindow(Owner)^.Frame^.DrawView;
  end;
end;

procedure TDataViewer.Reload;
var
  L: Longint;
  Name: FNameStr;
begin
  Owner^.Owner^.Lock;
  L := Focused;
  Name := DB^.Name^;
  DrawOpenStatus(Name);
  ReRead(Name, False);
  FocusItem(L);
  Owner^.Owner^.Unlock;
end;

procedure TDataViewer.Redraw;
begin
  DrawView;
  DoRedraw := False;
end;

function TDataViewer.GetItemPtr(Item: Longint): PDataRec;
var
  I: Integer;
  L, Pos, BufEnd: Longint;
  P: PDataRec;
  Rec: PByteArray;
begin
  if Item >= Range then P := nil
  else if (EditItem <> nil) and (Item = Focused) then P := EditItem
  else
  begin
    if (EditItem <> nil) and (EditMode <> emOverwrite) and
       (Item > Focused) then Dec(Item);
    if (Item < BufOrg) or (Item >= BufOrg + Buffer^.Count) then
    begin
      Buffer^.FreeAll;
{      GetMem(Rec, Buffer^.RecSize);}
      GetMemUMB(Rec, Buffer^.RecSize);
      if MaxAvail <= LongMul(Buffer^.RecSize, BufDelta) + $2000 then
      begin
        BufOrg := Item;
        BufEnd := Item + 1;
        Buffer^.NotInUse := True;
      end
      else
      begin
        BufOrg := Item - BufDelta div 2;
        if BufOrg + BufDelta > Range then BufOrg := Range - BufDelta;
        if BufOrg < 0 then BufOrg := 0;
        BufEnd := BufOrg + BufDelta;
        Buffer^.NotInUse := False;
      end;
      L := BufOrg;
      if DB^.DBF = nil then DB^.InitDBF(stOpenRead);
      while (L < BufEnd) and (L < Range) do
      begin
        Pos := DB^.Header^.HeaderLen +
          L * (DB^.Header^.RecordLen - DB^.ExtraRecordLen);
        DB^.ReadRecord(Pos, Rec^);
{
        GetMem(P, SizeOf(TDataRec));
        GetMem(P^.Rec, RecSize);
}
        GetMemUMB(P, SizeOf(TDataRec));
        GetMemUMB(P^.Rec, Buffer^.RecSize);
        Move(Rec^, P^.Rec^, Buffer^.RecSize);
        P^.Pos := Pos;
        Buffer^.Insert(P);
        Inc(L);
      end;
      DB^.DoneDBF;
{      FreeMem(Rec, Buffer^.RecSize);}
      FreeMemUMB(Rec, Buffer^.RecSize);
    end;
    I := Item - BufOrg;
    P := Buffer^.At(I);
  end;
  GetItemPtr := P;
end;

function TDataViewer.GetMemoFieldNum: Integer;
var
  I: Integer;
begin
  if Range <> 0 then for I := 0 to DB^.Fields^.Count - 1 do
    if TPString.Upcase(PFieldRec(DB^.Fields^.At(I))^.Iden) = 'M' then
    begin
      GetMemoFieldNum := I;
      Exit;
    end;
  GetMemoFieldNum := -1;
end;

procedure TDataViewer.StartEditor(AMode: Byte);
var
  P, R: PDataRec;

procedure InsertNew;
begin
{
  GetMem(P, SizeOf(TDataRec));
  GetMem(P^.Rec, Buffer^.RecSize);
}
  GetMemUMB(P, SizeOf(TDataRec));
  GetMemUMB(P^.Rec, Buffer^.RecSize);
  R := GetItemPtr(Focused);
  if (R = nil) or (EditMode in [emAddEmpty, emInsertEmpty]) then
    FillChar(P^.Rec^, Buffer^.RecSize, ' ')
  else Move(R^.Rec^, P^.Rec^, Buffer^.RecSize);
  DB^.InitDBF(stOpenRead);
  if EditMode in [emAddEmpty, emAddFull] then
  begin
    Char(P^.Rec^[0]) := '';
    P^.Pos := DB^.DBF^.GetSize - 1;
  end
  else
  begin
    Char(P^.Rec^[0]) := '';
    if R <> nil then P^.Pos := R^.Pos
    else P^.Pos := DB^.DBF^.GetSize - 1;
  end;
  DB^.DoneDBF;
  if Buffer^.NotInUse then EditItem := P
  else Buffer^.AtInsert(Focused - BufOrg, P);
  SetRange(Range + 1);
end;

begin
  if (Range = 0) and (AMode = emOverwrite) then AMode := emAddEmpty;
  if ((AMode <> emOverwrite) or Buffer^.NotInUse) and
     (MaxAvail <= Buffer^.RecSize + $2000) then
  begin
    Application^.OutOfMemory;
    Exit;
  end;
  JustifyField;
  EditMode := AMode;
  if EditMode <> emOverwrite then InsertNew
  else
  begin
    if Buffer^.NotInUse then
    begin
{
      GetMem(P, SizeOf(TDataRec));
      GetMem(P^.Rec, Buffer^.RecSize);
}
      GetMemUMB(P, SizeOf(TDataRec));
      GetMemUMB(P^.Rec, Buffer^.RecSize);
      R := GetItemPtr(Focused);
      Move(R^.Rec^, P^.Rec^, Buffer^.RecSize);
      P^.Pos := R^.Pos;
      EditItem := P;
    end
    else P := Buffer^.At(Focused - BufOrg);
    if P <> nil then Char(P^.Rec^[0]) := '';
  end;
  HScrollBar^.EventMask := 0;
  VScrollBar^.EventMask := 0;
  if State and sfFieldCursor = 0 then
  begin
    HScrollBar^.SetValue(0);
    SetCursor(1, Cursor.Y);
  end;
  ShowCursor;
  DrawView;
  SetState(sfFocused, True);
end;

procedure TDataViewer.EndEditor(Ok: Boolean);
var
  Add: Boolean;
  Field: Byte;
  Code, I: Integer;
  P: PDataRec;
begin
  if Ok then
  begin
    if EditItem <> nil then P := EditItem
    else P := Buffer^.At(Focused - BufOrg);
    if P <> nil then
    begin
      if (DBImpExpOptions and dbValidate <> 0) and
        not DB^.ValidRecord(Field, Code, False, P^.Rec^) then
      begin
	CursorOnField(Field);
	for I := 1 to Code - 1 do
          Message(@Self, evKeyDown, kbRight, nil);
	DrawView;
	PDataWindow(Owner)^.Fields^.DrawView;
        InvalidDBFieldMsgBox(
          Trim(Copy(DB^.GetFieldStr(Field, P^.Rec^), 1, 32)));
        Exit;
      end;
      Char(P^.Rec^[0]) := ' ';
      LogEvent := lcDiskWrite;
      DrawStatusLine('Updating database file ' +
        TrimmedName(DB^.Name^, 43) + '.');
      DB^.InitDBF(stOpen);
      if EditMode = emOverwrite then
	DB^.WriteRecord(P^.Pos, P^.Rec^)
      else if EditMode in [emAddEmpty, emAddFull] then
        DB^.AddRecord(P^.Rec^)
      else DB^.InsertRecord(P^.Pos, P^.Rec^);
      DB^.DoneDBF;
      UpdateFiles(DB^.Name^);
    end;
  end;
  SetRange(DB^.Header^.NumRecords);
  Buffer^.FreeItem(EditItem);
  EditItem := nil;
  Buffer^.FreeAll;
  Add := Ok and (EditMode in [emAddEmpty, emAddFull]);
  EditMode := emNo;
  HScrollBar^.EventMask := evMouseDown + evKeyDown + evCommand;
  VScrollBar^.EventMask := evMouseDown + evKeyDown + evCommand;
  if State and sfFieldCursor = 0 then HScrollBar^.SetValue(0);
  HideCursor;
  if Add then FocusItem(Range - 1)
  else FocusItem(Focused);
  DrawView;
  PWindow(Owner)^.Frame^.DrawView;
  SetState(sfFocused, True);
end;

procedure TDataViewer.DeleteRecords;
var
  Del: Boolean;
  I, IHi: Integer;
  L, Item, NewFocused: Longint;
  P: PDataRec;
  C, D: String[15];
begin
  if Range = 0 then Exit;
  C := 'the';
  if SelList^.Count <> 0 then Str(SelList^.Count, C);
  D := 'record';
  if SelList^.Count > 1 then D := D + 's';
  if MessageBox(^C'Remove ' + C + ' selected ' + D + #13 +
    ^C'from the database file'#13^C'|' + DB^.Name^ + '| ?',
    nil, mfConfirmation + mfOkCancel) = cmCancel then Exit;
  NewFocused := Focused;
  Del := False;
  with DB^ do
  begin
    C := JustFileName(Name^);
    IHi := SelList^.Count;
    if IHi <> 0 then Dec(IHi);
    for I := 0 to IHi do
    begin
      if (KbdStatus = 1) and AbortAction then Break;
      if I mod 10 = 0 then GiveTicks;
      if SelList^.Count = 0 then
      begin
        P := GetItemPtr(Focused);
        if P = nil then Break;
        L := P^.Pos;
      end
      else
      begin
        Item := Longint(SelList^.At(I));
        L := Header^.HeaderLen +
          Item * (Header^.RecordLen - ExtraRecordLen);
      end;
      if not Del then InitDBF(stOpen);
      LogEvent := lcDiskWrite;
      DrawStatusLine('Deleting database record from ' + C +
        '. File position: $' + HexL(L));
      DeleteRecord(L);
      if Item < NewFocused then Dec(NewFocused);
      Del := True;
    end;
    if Del then
    begin
      DB^.DoneDBF;
      UpdateDBChanges(NewFocused, True);
    end;
  end;
end;

procedure TDataViewer.PackDataBase;
var
  Aborted, Deleted: Boolean;
  C: Char;
  L, Index, NewFocused: Longint;
  NS: String[12];
  S: String;
begin
  if MessageBox(^C'Remove all data marked as deleted'#13 +
    ^C'from the database file'#13^C'|' + DB^.Name^ + '| ?',
    nil, mfConfirmation + mfOkCancel) = cmCancel then Exit;
  NewFocused := Focused;
  Aborted := False;
  Deleted := False;
  with DB^ do
  begin
    NS := JustFileName(Name^);
    InitDBF(stOpen);
    for Index := Header^.NumRecords - 1 downto 0 do
    begin
      if (KbdStatus = 1) and AbortAction then
      begin
        Aborted := True;
        Break;
      end;
      if Index mod 10 = 0 then GiveTicks;
      L := Index + 1;
      FormatStr(S, 'Reading database records, Esc aborts: %d', L);
      LogEvent := 0;
      DrawStatusLine(S);
      L := Header^.HeaderLen +
        Index * (Header^.RecordLen - ExtraRecordLen);
      DBF^.Seek(L);
      DBF^.Read(C, SizeOf(Char));
      if C = '*' then
      begin
        LogEvent := lcDiskWrite;
        DrawStatusLine('Deleting marked record from ' + NS +
          '. File position: $' + HexL(L));
        DeleteRecord(L);
        if Index < NewFocused then Dec(NewFocused);
        Deleted := True;
      end;
    end;
    DoneDBF;
  end;
  if Deleted then UpdateDBChanges(NewFocused, True)
  else if not Aborted then MessageBox(
    ^C'No marked records found.', nil, mfError + mfOkButton);
end;

procedure TDataViewer.ZapDataBase;
begin
  if MessageBox(^C'Zap the database ?'#13^C'All data will be lost !',
    nil, mfConfirmation + mfOkCancel) = cmCancel then Exit;
  LogEvent := lcDiskWrite;
  DrawStatusLine('Zapping database ' + TrimmedName(DB^.Name^, 50) + '.');
  DB^.InitDBF(stOpen);
  DB^.Zap;
  DB^.DoneDBF;
  UpdateDBChanges(0, True);
end;

procedure TDataViewer.UpdateDBChanges(NewFocused: Longint; FreeSel: Boolean);
begin
  UpdateFiles(DB^.Name^);
  SetRange(DB^.Header^.NumRecords);
  if FreeSel then
  begin
    DoneSelList;
    InitSelList;
  end;
  Buffer^.FreeAll;
  FocusItem(NewFocused);
  DrawView;
  PWindow(Owner)^.Frame^.DrawView;
  SetState(sfFocused, True);
end;

function TDataViewer.SaveOnExit: Word;
begin
  if (EditMode <> emNo) and (GetShiftState and kbCtrlShift = 0) then
    SaveOnExit := ModifiedSaveMsgBox(DB^.Name^)
  else SaveOnExit := cmNo;
end;

procedure TDataViewer.UpdateSourceTime;
var
  L: Longint;
begin
  if not GetFileTime(DB^.Name^, L) then
    if DB^.Time <> -1 then
    begin
      DB^.Time := -1;
      InvalidViewerMsgBox('dBASE viewer', DB^.Name^)
    end else
  else if L <> DB^.Time then
    if TimeChangedMsgBox('dBASE viewer', DB^.Name^) = cmOk then
    begin
      if EditMode <> emNo then EndEditor(False);
      Reload;
{
      Buffer^.FreeAll;
      DrawView;
}
    end
    else DB^.Time := L;
end;

function TDataViewer.CursorAtDiv(APos: Integer): Boolean;
var
  I: Integer;
begin
  for I := 0 to DB^.Fields^.Count - 2 do
    if Dividers^[I] = APos then
    begin
      CursorAtDiv := True;
      Exit;
    end;
  CursorAtDiv := False;
end;

procedure TDataViewer.CursorLeft;
var
  B: Byte;
begin
  B := 1 + Byte(CursorAtDiv(HScrollBar^.Value + Cursor.X - 1));
  if Cursor.X >= B then Dec(Cursor.X, B)
  else if HScrollBar^.Value <> 0 then Dec(HScrollBar^.Value, B);
  if HScrollBar^.Value + Cursor.X = 0 then Cursor.X := 1;
end;

procedure TDataViewer.CursorRight;
var
  B: Byte;
begin
  if Cursor.X >= DB^.Header^.RecordLen + DB^.Fields^.Count - 2 then Exit;
  B := 1 + Byte(CursorAtDiv(HScrollBar^.Value + Cursor.X + 1));
  if Cursor.X < Size.X - B then Inc(Cursor.X, B)
  else if HScrollBar^.Value < HScrollBar^.Max then Inc(HScrollBar^.Value, B);
end;

procedure TDataViewer.CursorHome;
var
  I: Integer;
begin
  repeat
    I := HScrollBar^.Value + Cursor.X;
    CursorLeft;
    if I = HScrollBar^.Value + Cursor.X then Exit;
    if I - 2 = HScrollBar^.Value + Cursor.X then
    begin
      CursorRight;
      Exit;
    end;
  until False;
end;

procedure TDataViewer.CursorEnd;
var
  I: Integer;
begin
  repeat
    I := HScrollBar^.Value + Cursor.X;
    CursorRight;
    if I = HScrollBar^.Value + Cursor.X then Exit;
    if I + 2 = HScrollBar^.Value + Cursor.X then
    begin
      CursorLeft;
      Exit;
    end;
  until False;
end;

procedure TDataViewer.CursorCtrlHome;
var
  I: Integer;
begin
  repeat
    I := HScrollBar^.Value + Cursor.X;
    CursorLeft;
    if I = HScrollBar^.Value + Cursor.X then Exit;
  until False;
end;

procedure TDataViewer.CursorCtrlEnd;
var
  I: Integer;
begin
  repeat
    I := HScrollBar^.Value + Cursor.X;
    CursorRight;
    if I = HScrollBar^.Value + Cursor.X then Exit;
  until False;
end;

procedure TDataViewer.CursorPrev;
begin
  CursorHome;
  CursorLeft;
  CursorHome;
end;

procedure TDataViewer.CursorNext;
begin
  CursorEnd;
  CursorRight;
  CursorEnd;
  CursorHome;
end;

procedure TDataViewer.CursorOnField(AField: Byte);
var
  B: Byte;
begin
  CursorCtrlHome;
  if AField = 0 then Exit;
  for B := 0 to AField - 1 do CursorNext;
end;

procedure TDataViewer.JustifyField;
var
  I: Integer;
begin
  if not FoundFlag then
  begin
    FoundPos := 0;
    FoundLen := 0;
  end;
  if (Range = 0) or (EditMode <> emNo) or
     (State and sfFieldCursor = 0) then Exit;
  if SelField = 0 then I := 0
  else I := Dividers^[SelField - 1];
  if FoundFlag then Inc(I, FoundPos - DB^.GetFieldOfs(SelField));
  if (I < HScrollBar^.Value) or
     (I >= HScrollBar^.Value + Size.X - 1) then
    HScrollBar^.SetValue(I);
end;

procedure TDataViewer.Edit(C: Char);
var
  DivIndex: Byte;
  Len, Offset, Key: Word;
  ScrollPos, RecPos: Integer;
  P: PDataRec;
begin
  P := GetItemPtr(Focused);
  if P = nil then Exit;
  DivIndex := 0;
  ScrollPos := HScrollBar^.Value + Cursor.X;
  while (DivIndex < DB^.Fields^.Count - 1) and
    (Dividers^[DivIndex] < ScrollPos) do Inc(DivIndex);
  if DivIndex = 0 then Offset := ScrollPos
  else Offset := ScrollPos - Dividers^[DivIndex - 1];
  Dec(Offset);
  RecPos := ScrollPos - DivIndex;
  Len := DB^.GetFieldLen(PFieldRec(DB^.Fields^.At(DivIndex)));
  case C of
    ^G:
      begin
        Move(P^.Rec^[RecPos + 1], P^.Rec^[RecPos], Len - Offset - 1);
        C := ' ';
        Inc(RecPos, Len - Offset - 1);
        Key := 0;
      end;
    ^H:
      begin
        if Offset = 0 then Exit;
        Move(P^.Rec^[RecPos], P^.Rec^[RecPos - 1], Len - Offset);
        C := ' ';
        Inc(RecPos, Len - Offset - 1);
        Key := kbLeft;
      end;
    ^Y:
      begin
        FillChar(P^.Rec^[RecPos - Offset], Len, ' ');
        C := ' ';
        Key := kbHome;
      end;
    ^Z:
      begin
        FillChar(P^.Rec^, Buffer^.RecSize, ' ');
        C := ' ';
        Key := kbCtrlHome;
      end;
    else
      begin
        if (DBImpExpOptions and dbValidate <> 0) and
          not DB^.ValidChar(C, DB^.GetFieldNum(RecPos)) then
        begin
          if not DisableSounds then Write(^G);
          Exit;
        end;
        if State and sfCursorIns = 0 then
        begin
          if Char(P^.Rec^[RecPos - Offset + Len - 1]) <> ' ' then
            if Char(P^.Rec^[RecPos]) <> ' ' then Exit else
          else Move(P^.Rec^[RecPos], P^.Rec^[RecPos + 1], Len - Offset - 1);
        end;
        Key := kbRight;
      end;
  end;
  P^.Rec^[RecPos] := Byte(C);
  Message(@Self, evKeyDown, Key, nil);
  DrawView;
  Indicator^.Modified := True;
  Indicator^.DrawView;
end;

procedure TDataViewer.MarkItems(Mark: Char);
var
  I, IHi: Integer;
  L, Item: Longint;
  P: PDataRec;
  C: String[15];
begin
  if Range = 0 then Exit;
  with DB^ do
  begin
    InitDBF(stOpen);
    C := JustFileName(Name^);
    IHi := SelList^.Count;
    if IHi <> 0 then Dec(IHi);
    for I := 0 to IHi do
    begin
      if (KbdStatus = 1) and AbortAction then Break;
      if I mod 10 = 0 then GiveTicks;
      if SelList^.Count = 0 then
      begin
        P := GetItemPtr(Focused);
        if P = nil then Break;
        L := P^.Pos;
      end
      else
      begin
        Item := Longint(SelList^.At(I));
        L := Header^.HeaderLen +
          Item * (Header^.RecordLen - ExtraRecordLen);
      end;
      LogEvent := lcDiskWrite;
      DrawStatusLine('Marking database record in ' + C +
        '. File position: $' + HexL(L));
      DBF^.Seek(L);
      DBF^.Write(Mark, SizeOf(Char));
    end;
    DB^.DoneDBF;
    UpdateDBChanges(Focused, False);
  end;
end;

function BMSearchBack(var Buffer; BufLength: Word;
  BT: BTable; MatchString: String; UC: Boolean): Word;
var
  BytesToSearch, BytesSearched, Offset: Word;
begin
  BMSearchBack := $FFFF;
  BytesToSearch := BufLength;
  Offset := 0;
  repeat
    if BytesToSearch < Length(MatchString) then
    begin
      if Offset <> 0 then BMSearchBack := Offset - 1;
      Exit;
    end;
    if UC then BytesSearched := BMSearchUC(
      TByteArray(Buffer)[Offset], BytesToSearch, BT, MatchString)
    else BytesSearched := BMSearch(
      TByteArray(Buffer)[Offset], BytesToSearch, BT, MatchString);
    if BytesSearched <> $FFFF then
    begin
      Inc(Offset, BytesSearched + 1);
      Dec(BytesToSearch, BytesSearched + 1);
    end
    else BytesToSearch := 0;
  until False;
end;

function TDataViewer.Find(const Match: String; AOptions: Word): Boolean;
var
  FieldOnly: Boolean;
  B: Byte;
  W, Offset, SelOfs, SelLen: Word;
  I: Integer;
  L, LE, NewFocused: Longint;
  DP: PDataRec;
  P, SP: PByteArray;
  RE: Pointer;
  Params: Array[0..1] of Longint;
  BT: BTable;
  S, SS: String;

procedure DrawSearchStatus;
begin
  Params[0] := L + 1;
  Params[1] := Range;
  FormatStr(SS, 'Searching through database: %d/%d', Params);
  LogEvent := 0;
  DrawStatusLine(SS);
end;

begin
  Find := False;
  if (Match = '') or (Range = 0) then Exit;
  if not SearchingAll and not Replacing then DrawStatusLine(SearchMsg);
  B := 0;
  S := Match;
  if AOptions and frCaseSensitive = 0 then UpcaseSt(S);
  if AOptions and frRegExp <> 0 then
  begin
    RE := RegCompile(S);
    if RE = nil then Exit;
  end
  else BMMakeTable(S, BT);
{  GetMem(P, DB^.Header^.RecordLen + 1);}
  GetMemUMB(P, DB^.Header^.RecordLen + 1);
  FieldOnly := (State and sfFieldCursor <> 0) and
    (AOptions and frWholeWordsOnly <> 0);
  SelOfs := DB^.GetFieldOfs(SelField);
  SelLen := DB^.GetFieldLen(PFieldRec(DB^.Fields^.At(SelField)));
  L := Focused;
  if AOptions and frBackward <> 0 then
  begin
    if AOptions and frFromCursor = 0 then
    begin
      L := Range - 1;
      FoundLen := 0;
    end
    else if ((FoundLen = 0) and (FieldOnly or
      (State and sfFieldCursor = 0))) or
      ((FoundLen <> 0) and
       ((FieldOnly and (FoundPos <= SelOfs)) or
        (not FieldOnly and (FoundPos = 0)))) then
    begin
      Dec(L);
      FoundLen := 0;
    end;
    if IncSearch then LE := IncSearchPos - 1
    else LE := -1;
  end
  else
  begin
    if AOptions and frFromCursor = 0 then
    begin
      L := 0;
      FoundLen := 0;
    end
    else if FoundLen <> 0 then
      if (FieldOnly and (FoundPos >= SelOfs + SelLen - 1)) or
         (not FieldOnly and (FoundPos >=
           DB^.Header^.RecordLen - 1)) then
      begin
        Inc(L);
        FoundLen := 0;
      end;
    LE := Range;
  end;
  if SelList^.Count = 0 then AOptions := AOptions and not frSelectedText;
  while L <> LE do
  begin
    if (KbdStatus = 1) and AbortAction then
    begin
      B := $FF;
      Break;
    end;
    if (AOptions and frSelectedText = 0) or
       (SelList^.IndexOf(Pointer(L)) <> -1) then
    begin
      DrawSearchStatus;
      DP := GetItemPtr(L);
      if DP = nil then Break;
      W := DB^.Header^.RecordLen;
      Move(DP^.Rec^, P^, W);
      P^[W] := 0;
      Offset := 0;
      if AOptions and frRegExp <> 0 then
      begin
        if FieldOnly then
        begin
          Offset := SelOfs;
          W := SelOfs + SelLen;
        end;
        if (AOptions and frFromCursor <> 0) and (L = Focused) then
          if FoundLen <> 0 then
            if AOptions and frBackward = 0 then
              Offset := FoundPos + 1
            else W := FoundPos
          else if not FieldOnly and (State and sfFieldCursor <> 0) then
            if AOptions and frBackward <> 0 then W := SelOfs
            else Offset := SelOfs;
        P^[W] := 0;
        SP := @P^[Offset];
        if AOptions and frCaseSensitive = 0 then StrUpper(PChar(SP));
        if AOptions and frBackward <> 0 then
          I := RegExBack(RE, PChar(SP))
        else I := RegEx(RE, PChar(SP));
        if I <> 0 then
        begin
          I := PRegExp(RE)^.Endp[0] - PRegExp(RE)^.Startp[0];
          Inc(Offset, PtrRec(RE^).Ofs - PtrRec(SP).Ofs);
          B := 1;
        end;
      end
      else
      begin
        if FieldOnly then
        begin
          Offset := SelOfs;
          W := SelLen;
        end;
        if (AOptions and frFromCursor <> 0) and (L = Focused) then
          if FoundLen <> 0 then
            if AOptions and frBackward = 0 then
            begin
              Offset := FoundPos + Byte(not IsSearchingFrom);
              if FieldOnly then Dec(W, Offset - SelOfs)
              else Dec(W, Offset);
            end
            else if FieldOnly then W := FoundPos - SelOfs
            else W := FoundPos
          else if not FieldOnly and (State and sfFieldCursor <> 0) then
            if AOptions and frBackward <> 0 then W := SelOfs
            else
            begin
              Offset := SelOfs;
              Dec(W, SelOfs);
            end;
        SP := @P^[Offset];
        if AOptions and frBackward <> 0 then
          W := BMSearchBack(SP^, W, BT, S, AOptions and frCaseSensitive = 0)
        else if AOptions and frCaseSensitive <> 0 then
          W := BMSearch(SP^, W, BT, S)
        else W := BMSearchUC(SP^, W, BT, S);
        if W <> $FFFF then
        begin
          I := Length(Match);
          Inc(Offset, W);
          B := 1;
        end;
      end;
      if B = 1 then
      begin
        NewFocused := L;
        Break;
      end;
    end;
    if AOptions and frBackward <> 0 then Dec(L) else Inc(L);
  end;
{  FreeMem(P, DB^.Header^.RecordLen + 1);}
  FreeMemUMB(P, DB^.Header^.RecordLen + 1);
  if AOptions and frRegExp <> 0 then RegFree(RE);
  if B = 1 then
  begin
    SelField := DB^.GetFieldNum(Offset);
    FoundPos := Offset;
    while (I > 0) and (Offset + I > DB^.Header^.RecordLen) do Dec(I);
    FoundLen := I;
    FoundFlag := True;
    if SearchingAll then Find :=
      SetSelect(NewFocused, AOptions and frSelectedText = 0)
    else Find := True;
    if NewFocused = Focused then B := 0;
    W := State;
    if not SearchingAll then State := State or sfFieldCursor;
    FocusItem(NewFocused);
    JustifyField;
    if B = 0 then DrawView;
    State := W;
    DoRedraw := True;
    FoundFlag := False;
  end
  else if not IncSearch then
  begin
    FocusItem(Focused);
    DrawView;
    if (B = 0) and not SearchingAll and not Replacing then
      SearchStringNotFoundMsgBox;
  end;
end;

procedure TDataViewer.PasteText;
var
  B, SaveField: Byte;
  I, SavePos: Integer;
  PS: PString;
  S: String;
begin
  PS := Message(Application, evBroadcast, cmPaste, nil);
  if PS = nil then Exit;
  S := PString(PS)^;
  TrimSt(S);
  SaveField := SelField;
  HideCursor;
  Owner^.Lock;
  for B := 1 to Length(S) do
  begin
    SavePos := HScrollBar^.Value + Cursor.X;
    Edit(S[B]);
    if (SaveField <> SelField) or
       (SavePos = HScrollBar^.Value + Cursor.X) then Break;
  end;
  Owner^.Unlock;
  ShowCursor;
end;

procedure TDataViewer.FieldDlg;
const
  YesCommands = [cmYes];
var
  B: Byte;
  C: Word;
  D: PDialog;
  VBar: PScrollBar;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 54, DB^.Fields^.Count + 8);
  if R.B.Y > ScreenHeight - 4 then R.B.Y := ScreenHeight - 4;
  D := New(PDialog, Init(R, 'Field information'));
  with D^ do
  begin
    Options := Options or ofCentered;
    GrowMode := GrowMode + gfGrowHiY;
    HelpCtx := hcDataFields;
    R.Assign(Size.X - 4, 3, Size.X - 3, Size.Y - 4);
    VBar := New(PScrollBar, Init(R));
    Insert(VBar);
    R.Assign(3, 3, Size.X - 4, Size.Y - 4);
    Control := New(PFieldInfoViewer, Init(R, VBar, DB^.Fields));
    Insert(Control);
    R.Assign(3, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(R, FieldInfoLabelStr, Control)));
    R.Assign(2, Size.Y - 3, 12, Size.Y - 1);
    Control := StandardOkButton(R, D);
    Control^.GrowMode := gfGrowLoY + gfGrowHiY;
    R.Assign(15, Size.Y - 3, 25, Size.Y - 1);
    Control := New(PButton, Init(R, '~E~dit', cmYes, bfNormal));
    Control^.GrowMode := gfGrowLoY + gfGrowHiY;
    Insert(Control);
    R.Assign(28, Size.Y - 3, 38, Size.Y - 1);
    Control := StandardCancelButton(R, D);
    Control^.GrowMode := gfGrowLoY + gfGrowHiY;
    R.Assign(41, Size.Y - 3, 51, Size.Y - 1);
    Control := StandardHelpButton(R, D);
    Control^.GrowMode := gfGrowLoY + gfGrowHiY;
    SelectNext(False);
  end;
  B := SelField;
  if Range = 0 then EnableCommands(YesCommands)
  else DisableCommands(YesCommands);
  C := Application^.ExecuteDialog(D, @B, False);
  EnableCommands(YesCommands);
  if C = cmYes then EditFields(B)
  else if C = cmOk then
    if EditMode <> emNo then
    begin
      CursorOnField(B);
      Message(@Self, evKeyDown, kbHome, nil);
    end
    else
    begin
      SelField := B;
      JustifyField;
      DrawView;
    end;
end;

procedure TDataViewer.ViewMemo(Hex: Boolean);
var
  SaveExplode: Boolean;
  Command: Word;
  I: Integer;
  L: Longint;
  P: PDataRec;
  V: PTextViewer;
  H: PHexViewer;
  C: String[3];
  F: lFile;
  S: String;
begin
  I := GetMemoFieldNum;
  if I = -1 then Exit;
  P := GetItemPtr(Focused);
  if P = nil then Exit;
  S := DB^.GetFieldStr(I, P^.Rec^);
  TrimSt(S);
  Val(S, L, I);
  if L = 0 then Exit;
  if DB^.Header^.Iden in [$03, $83] then C := 'DBT'
  else C := 'FPT';
  S := ForceExtension(DB^.Name^, C);
  if C[1] = 'F' then
  begin
    lAssignFile(F, S);
    lResetFile(F, 1);
    if IOResult = 0 then
    begin
      Seek(F.F, 6);
      BlockRead(F.F, I, SizeOf(Integer));
      Close(F.F);
      InOutRes := 0;
      L := 8 + L * Word(Swap(I));
    end
    else L := 0;
  end
  else L := L * $200;
  SaveExplode := DoExplode;
  DoExplode := False;
  Desktop^.Lock;
  if Hex then Command := cmOpenHexViewer
  else Command := cmOpenTextViewer;
  Message(Application, evCommand, Command, @S);
  if Hex then
  begin
    H := Message(Desktop, evBroadcast, Command, @S);
    if H <> nil then
    begin
      H^.GoToPosition(L);
      H^.UpdatePosition;
    end;
  end
  else
  begin
    V := Message(Desktop, evBroadcast, Command, @S);
    if V <> nil then
    begin
      V^.GoToPosition(L, 1);
      V^.UpdatePosition;
    end;
  end;
  Desktop^.Unlock;
  DoExplode := SaveExplode;
end;

procedure TDataViewer.FindDlg;
var
  W: Word;
  D: PDialog;
begin
  if (EditOptions and eoFindTextAtCursor <> 0) and
     (State and sfFieldCursor <> 0) then
    SearchData.MatchStr := GetCopyText(Focused, 0)
  else SearchData.MatchStr := HistoryStr(FindHistoryID, 0);
  if SelList^.Count <> 0 then W := 0
  else W := frSelectedText;
  if State and sfFieldCursor = 0 then W := W + frWholeWordsOnly;
  D := LoadFindDialog(False, False, W);
  ReplaceFindClusterText(D, 2, 'C~u~rrent field');
  W := Application^.ExecuteDialog(D, @SearchData, False);
  if W = cmOk then Find(SearchData.MatchStr, SearchData.Options)
  else if W = cmYes then
  begin
    DrawStatusLine(SearchMsg);
    W := SearchData.Options;
    if SelList^.Count = 0 then W := W and not frSelectedText;
    SearchingAll := True;
    repeat
      if not Find(SearchData.MatchStr, W) or
        ((W and frSelectedText <> 0) and (SelList^.Count = 0)) then Break;
      W := W or frFromCursor;
    until False;
    SearchingAll := False;
  end;
end;

procedure TDataViewer.ReplaceDlg;
var
  NotFound, Changed: Boolean;
  W, C, Offset, Len: Word;
  LenDif: Integer;
  P: PDataRec;
  D: PDialog;
  R: TRect;
  Spot: TPoint;
  S, FS: String;
begin
  if (EditOptions and eoFindTextAtCursor <> 0) and
     (State and sfFieldCursor <> 0) then
  begin
    ReplaceData.MatchStr := GetCopyText(Focused, 0);
    ReplaceData.NewString := ReplaceData.MatchStr;
  end
  else
  begin
    ReplaceData.MatchStr := HistoryStr(FindHistoryID, 0);
    ReplaceData.NewString := HistoryStr(ReplaceHistoryID, 0);
  end;
  W := frGroupUndo;
  if SelList^.Count = 0 then W := W + frSelectedText;
  if State and sfFieldCursor = 0 then W := W + frWholeWordsOnly;
  D := LoadReplaceDialog(W);
  ReplaceFindClusterText(D, 2, 'C~u~rrent field only');
  if Application^.ExecuteDialog(D, @ReplaceData, False) <> cmCancel then
  begin
    DrawStatusLine(SearchMsg);
    W := ReplaceData.Options;
    Replacing := True;
    NotFound := True;
    Changed := False;
    repeat
      if not Find(ReplaceData.MatchStr, W) then Break;
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
      end
      else C := cmYes;
      if C = cmCancel then Break;
      if (C = cmOk) or (C = cmYes) then
      begin
        P := GetItemPtr(Focused);
        if P = nil then Break;
        S := ReplaceData.NewString;
        if (State and sfFieldCursor <> 0) and
           (W and frWholeWordsOnly <> 0) then
        begin
          Offset := FoundPos - DB^.GetFieldOfs(SelField);
          Len := DB^.GetFieldLen(PFieldRec(DB^.Fields^.At(SelField)));
          LenDif := Length(S) - FoundLen;
          while (LenDif > 0) and (S <> '') and (Offset + Length(S) > Len) do
          begin
            Dec(S[0]);
            Dec(LenDif);
          end;
          if LenDif > 0 then
            Move(P^.Rec^[FoundPos], P^.Rec^[FoundPos + LenDif],
              Len - Offset - LenDif)
          else if LenDif < 0 then
          begin
            Move(P^.Rec^[FoundPos - LenDif], P^.Rec^[FoundPos],
              Len - Offset + LenDif);
            FillChar(P^.Rec^[FoundPos - Offset + Len + LenDif],
              -LenDif, #32);
          end;
        end
        else while (S <> '') and
          (FoundPos + Length(S) > DB^.Header^.RecordLen) do Dec(S[0]);
        Move(S[1], P^.Rec^[FoundPos], Length(S));
        DB^.InitDBF(stOpen);
	DB^.WriteRecord(P^.Pos, P^.Rec^);
        DB^.DoneDBF;
        DrawView;
        Changed := True;
      end;
    until False;
    Replacing := False;
    if NotFound then SearchStringNotFoundMsgBox
    else if Changed then UpdateFiles(DB^.Name^);
  end;
end;

procedure TDataViewer.InitIncSearch;
begin
  IncSearchStr := '';
  IncSearchPos := Focused;
  IncSearchOpt := (SearchData.Options or frFromCursor) and not frRegExp;
  if SelList^.Count = 0 then
    IncSearchOpt := IncSearchOpt and not frSelectedText;
  if State and sfFieldCursor = 0 then
    IncSearchOpt := IncSearchOpt and not frWholeWordsOnly;
  IncSearch := True;
end;

procedure TDataViewer.DoneIncSearch;
begin
  if IncSearchStr <> '' then
    SearchData.MatchStr := IncSearchStr;
  Redraw;
  IncSearch := False;
end;

procedure TDataViewer.DoIncSearch(C: Char);
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
    end;
  end;
  if not Find(IncSearchStr, IncSearchOpt) then
    if C = #8 then
    begin
      Inc(FoundPos, Length(IncSearchStr));
      if not Find(IncSearchStr, IncSearchOpt) then
        Dec(FoundPos, Length(IncSearchStr));
    end
    else if not (C in [^B, ^L]) then Dec(IncSearchStr[0]);
  IsSearchingFrom := False;
end;

procedure TDataViewer.GoToLineNumber;
const
  GoToLineData: String[10] = '';
var
  D: PDialog;
  Control: PView;
  R: TRect;
  L: Longint;
  S: String;
begin
  if Range <= 1 then Exit;
  R.Assign(0, 0, 46, 7);
  D := New(PDialog, Init(R, 'Go to record'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcSHGoToLineNumber;
    R.Assign(27, 2, 40, 3);
    Control := New(PCInputLine, Init(R, 10, 1, Range));
    Insert(Control);
    StandardHistory(Control, GoToLineNumHistoryID);
    R.Assign(2, 2, 27, 3);
    Insert(New(PLabel, Init(R, '~E~nter new record number', Control)));

    StandardButtonRow(D, True);
  end;
  if (Application^.ExecuteDialog(D, @GoToLineData, False) <> cmCancel) and
    Str2Long(GoToLineData, L) then FocusItem(L - 1);
end;

procedure TDataViewer.ImportData;
var
  C: Word;
  L: Longint;
  S: FNameStr;
begin
  S := '';
  C := Application^.ExecuteDialog(New(PFileDialog, Init('*.TXT',
    'Read records from text file', '~N~ame',
    fdOkButton + fdSelButton + fdHelpButton, HistoryID)), @S, True);
  if C <> cmCancel then
  begin
    if C = cmSelectedFiles then S := '';
    if DBImpExpOptions and imInsert <> 0 then L := Focused
    else L := DB^.Header^.NumRecords;
    if ImportFromTxt(S, DB, SelList, Focused) then
      UpdateDBChanges(L, False);
  end;
end;

procedure TDataViewer.ExportData;
var
  S: FNameStr;
begin
  S := '';
  if (Application^.ExecuteDialog(New(PFileDialog, Init('*.TXT',
    'Write records to text file', '~N~ame', fdOkButton + fdHelpButton,
    HistoryID)), @S, True) <> cmCancel) and ExportToTxt(S, DB, SelList) then
      UpdateFiles(S);
end;

procedure TDataViewer.ImportFromClipboard;
var
  L: Longint;
begin
  if DBImpExpOptions and imInsert <> 0 then L := Focused
  else L := DB^.Header^.NumRecords;
  if ImportFromTxt('', DB, SelList, Focused) then
    UpdateDBChanges(L, False);
end;

procedure TDataViewer.ExportToClipboard;
var
  SelCount: Integer;
begin
  SelCount := SelList^.Count;
  if SelCount = 0 then SelList^.Insert(Pointer(Focused));
  if ExportToTxt('', DB, SelList) then
    Message(Desktop, evBroadcast, cmUpdateViews, nil);
  if SelCount = 0 then SelList^.AtFree(0);
end;

procedure TDataViewer.SortData;
begin
  if SortDatabase(DB, SelField) then UpdateDBChanges(0, True);
end;

procedure TDataViewer.EditFields(AField: Byte);
var
  C: Word;
begin
  if Range <> 0 then Exit;
  EventMask := EventMask and not evBroadcast;
  C := NewDBDlg(DB^.Name^, DB^.Fields, AField,
    DB^.OutXLATTable, DB^.Options and dbXLATOUT <> 0);
  EventMask := EventMask or evBroadcast;
  if C = cmOk then Reload;
end;

procedure TDataViewer.SetXLATTable(const Name: FNameStr; AMode: Byte);
var
  B, C: Boolean;
begin
  if AMode = dcXLATIN then
  begin
    if Name <> '' then B := ReadConvertTable(DB^.InXLATTable, Name, C)
    else B := GetConvertTable(DB^.InXLATTable, True, C);
    if B then DB^.Options := DB^.Options or dbXLATIN
    else if C then DB^.Options := DB^.Options and not dbXLATIN;
    Reload;
  end
  else
  begin
    if Name <> '' then B := ReadConvertTable(DB^.OutXLATTable, Name, C)
    else B := GetConvertTable(DB^.OutXLATTable, True, C);
    if B then DB^.Options := DB^.Options or dbXLATOUT
    else if C then DB^.Options := DB^.Options and not dbXLATOUT;
    PWindow(Owner)^.Frame^.DrawView;
  end;
end;

procedure TDataViewer.ClearXLATTable(AMode: Byte);
begin
  if (AMode = dcXLATIN) and (DB^.Options and dbXLATIN <> 0) then
  begin
    DB^.Options := DB^.Options and not dbXLATIN;
    Reload;
  end
  else if (AMode = dcXLATOUT) and (DB^.Options and dbXLATOUT <> 0) then
  begin
    DB^.Options := DB^.Options and not dbXLATOUT;
    PWindow(Owner)^.Frame^.DrawView;
  end;
end;

procedure TDataViewer.ToggleConvertDates;
begin
  DBImpExpOptions := DBImpExpOptions xor dbConvertDates;
  Reload;
end;

procedure TDataViewer.ToggleValidate;
begin
  DBImpExpOptions := DBImpExpOptions xor dbValidate;
end;

procedure TDataViewer.Popup(AOrigin: TPoint);
var
  YesOrNo: Array[False..True] of String[3];
begin
  YesOrNo[False] := ' No';
  YesOrNo[True] := 'Yes';
  ShowPopup(AOrigin, NewMenu(
    NewItem('~C~opy', 'Ctrl+Ins', kbCtrlIns, cmCopy, hcECopy,
    NewItem('~P~aste', 'Shift+Ins', kbShiftIns, cmPaste, hcEPaste,
    NewLine(
    NewItem('Fie~l~ds...', 'F2', kbF2, cmPuzzle, hcDataFields,
    NewItem('~V~iew memo', 'F4', kbF4, cmRunItem, hcViewMemo,
    NewItem('View memo as ~H~ex', 'Ctrl+F4', kbCtrlF4, cmNewItemPos, hcViewMemo,
    NewLine(
    NewItem('~F~ind...', 'F7', kbF7, cmFind, hcSHFind,
    NewItem('~R~eplace...', '', kbNoKey, cmReplace, hcSHReplace,
    NewItem('~S~earch again', 'Shift+F7', kbShiftF7, cmSearchAgain, hcSHSearchAgain,
    NewItem('~I~ncremental search', 'Ctrl+@', kbNoKey, cmIncSearch, hcSHIncSearch,
    NewItem('~G~o to record...', 'Alt+G', kbAltG, cmGoToLine, hcSHGoToLineNumber,
    NewLine(
    NewSubMenu('Inp~u~t/Output commands', hcInOutCommands, NewMenu(
    NewItem('In XLAT file...            ~<~', '', kbNoKey, cmInXLAT, hcDBXLATFile,
    NewItem('Out XLAT file...           ~>~', '', kbNoKey, cmOutXLAT, hcDBXLATFile,
    NewItem('Clear In XLAT table        ~{~', '', kbNoKey, cmClearInXLAT, hcDBClearXLAT,
    NewItem('Clear Out XLAT table       ~}~', '', kbNoKey, cmClearOutXLAT, hcDBClearXLAT,
    NewLine(
    NewItem('~C~onvert date fields',
      YesOrNo[DBImpExpOptions and dbConvertDates <> 0],
      kbNoKey, cmDBConvertDates, hcDBConvertDates,
    NewItem('~V~alidate numeric fields',
      YesOrNo[DBImpExpOptions and dbValidate <> 0],
      kbNoKey, cmDBValidate, hcDBValidate,
    NewLine(
    NewItem('~I~mport from text...', 'Alt+I', kbAltI, cmImport, hcImportData,
    NewItem('E~x~port to text...', 'Alt+V', kbAltV, cmExport, hcExportData,
    NewLine(
    NewItem('Import/Export ~o~ptions...', '', kbNoKey, cmWriteTo, hcImpExpOptions,
    NewItem('Fi~e~ld separator...', FieldSeparator, kbNoKey, cmModifyValue, hcFieldSeparator,
      nil)))))))))))))),
    NewLine(
    NewItem('Sor~t~ database...', '', kbNoKey, cmReset, hcSortDataBase,
    NewItem('~D~elete records...', 'F8', kbF8, cmDeleteItem, hcDeleteRecord,
    NewItem('P~a~ck database...', 'Shift+F8', kbShiftF8, cmModifyItem, hcPackDataBase,
    NewItem('~Z~ap database...', '', kbNoKey, cmHide, hcZapDataBase,
    NewLine(
    NewItem('Field cursor ~o~n/off', 'Alt+F2', kbAltF2, cmNewItem, hcFieldCursor,
      nil)))))))))))))))))))))));
end;

constructor TDataWindow.Init(Bounds: TRect; ADataBase: PDataBase);
var
  HControl: PScrollBar;
  VControl: PLongScrollBar;
  IControl: PDataViewIndicator;
  R: TRect;
begin
  Inherited Init(Bounds, ADataBase^.Name^, WindowNumAvail);
  Options := Options or ofTileable;

  GetExtent(R);
  Inc(R.A.X, 28); Dec(R.B.X, 2); R.A.Y := R.B.Y - 1;
  HControl := New(PScrollBar, Init(R));
  HControl^.Options := HControl^.Options or ofPostProcess;
  Insert(HControl);

  GetExtent(R);
  R.A.X := R.B.X - 1; Inc(R.A.Y); Dec(R.B.Y);
  VControl := New(PLongScrollBar, Init(R));
  Insert(VControl);

  GetExtent(R);
  Inc(R.A.X, 3); R.A.Y := R.B.Y - 1; R.B.X := R.A.X + 24;
  IControl := New(PDataViewIndicator, Init(R));
  IControl^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(IControl);

  GetExtent(R);
  R.Grow(-1, -1);
  R.B.Y := R.A.Y + 1;
  Fields := New(PFieldViewer, Init(R, HControl, ADataBase));
  Insert(Fields);

  GetExtent(R);
  R.Grow(-1, -1);
  Inc(R.A.Y);
  Viewer := New(PDataViewer, Init(
    R, HControl, VControl, IControl, ADataBase));
  Insert(Viewer);
end;

constructor TDataWindow.Load(var S: TStream);
var
  D: PDataBase;
begin
  Inherited Load(S);
  GetSubViewPtr(S, Fields);
  GetSubViewPtr(S, Viewer);
  DrawOpenStatus(Title^);
  D := New(PDataBase, Init(Title^));
  if Viewer^.Options and ofInXLAT <> 0 then
  begin
    S.Read(D^.INXLATTable, SizeOf(ConvertTable));
    D^.Options := D^.Options or dbXLATIN;
  end;
  if Viewer^.Options and ofOutXLAT <> 0 then
  begin
    S.Read(D^.OUTXLATTable, SizeOf(ConvertTable));
    D^.Options := D^.Options or dbXLATOUT;
  end;
  if not D^.Valid then
  begin
    Dispose(D, Done);
    CouldNotOpenMsgBox(Title^);
    Invalid := True;
    Exit;
  end;
  with Fields^ do
  begin
    DB := D;
    InitFieldLine;
  end;
  with Viewer^ do
  begin
    DB := D;
    InitViewer;
  end;
end;

procedure TDataWindow.Close;
var
  C: Word;
  I: Integer;
  Y: String[15];
  S: String;
begin
  with Viewer^ do
  begin
    C := SaveOnExit;
    if C = cmCancel then Exit;
    if C = cmYes then EndEditor(True);
    if Length(DB^.Name^) <= 222 then
    begin
      S := 'dBASE ' + DB^.Name^;
      if HistoryIndex(ReopenHistoryID, S) = -1 then
      begin
        Str(Focused, Y);
        S := S + #$FF + Y;
        if State and sfFieldCursor <> 0 then
        begin
          Str(SelField, Y);
          S := S + #$FF + Y;
        end;
        S := S + #$FF#$FF;
        Move(Self.Origin, S[Length(S) + 1], 8);
        Inc(S[0], 8);
        HistoryAdd(ReopenHistoryID, S, False);
        if State and sfHistLocked <> 0 then
        begin
          I := HistoryIndex(ReopenHistoryID, S);
          if I <> -1 then
            Byte(PHistoryRec(HistoryList^.At(I))^.Lock) := HistLock;
        end;
      end;
    end;
  end;
  Inherited Close;
end;

function TDataWindow.GetPalette: PPalette;
const
  P: String[Length(CDataWindow)] = CDataWindow;
begin
  GetPalette := @P;
end;

function TDataWindow.GetTitle(MaxSize: Integer): TTitleStr;
var
  I: Integer;
  S: String;
begin
  FormatStr(S, ' (%d records)', Viewer^.DB^.Header^.NumRecords);
  if Viewer^.DB^.Header^.NumRecords = 1 then
    System.Delete(S, Length(S) - 1, 1);
  if Viewer^.DB^.Options and dbXLATIN <> 0 then S := S + ' <';
  if Viewer^.DB^.Options and dbXLATOUT <> 0 then S := S + ' >';
  I := MaxSize - Length(S) - 10;
  if I < 12 then I := 12;
  GetTitle := Concat('dBASE view: ', TrimmedName(Title^, Byte(I)), S);
end;

procedure TDataWindow.SizeLimits(var Min, Max: TPoint);
begin
  Inherited SizeLimits(Min, Max);
  Min.X := 33;
  Min.Y := 4;
end;

procedure TDataWindow.Store(var S: TStream);
begin
  if Viewer^.DB^.Options and dbXLATIN <> 0 then
    Viewer^.Options := Viewer^.Options or ofInXLAT
  else Viewer^.Options := Viewer^.Options and not ofInXLAT;
  if Viewer^.DB^.Options and dbXLATOUT <> 0 then
    Viewer^.Options := Viewer^.Options or ofOutXLAT
  else Viewer^.Options := Viewer^.Options and not ofOutXLAT;
  Inherited Store(S);
  PutSubViewPtr(S, Fields);
  PutSubViewPtr(S, Viewer);
  if Viewer^.Options and ofInXLAT <> 0 then
    S.Write(Viewer^.DB^.INXLATTable, SizeOf(ConvertTable));
  if Viewer^.Options and ofOutXLAT <> 0 then
    S.Write(Viewer^.DB^.OUTXLATTable, SizeOf(ConvertTable));
end;

function TDataWindow.Valid(Command: Word): Boolean;
begin
  Valid := (not Invalid) and Inherited Valid(Command);
end;

function GetDBFInfo(const AName: FNameStr; AList: PCollection): Boolean;
var
  B: Boolean;
  DB: PDataBase;
  C: String;

procedure NewLine(const S: String);
begin
{  AList^.Insert(NewStr(S + '|'));}
  AList^.Insert(NewStrUMB(S + '|'));
end;

begin
  DB := New(PDataBase, Init(AName));
  B := DB^.Valid;
  if B then
  begin
    Str(DB^.Header^.Iden, C);
    NewLine('Database type     |' + C);
    with DB^.Header^ do C := FormatDateStr(Year, Month, Day);
    NewLine('Last updated      |' + C);
    Str(DB^.Header^.HeaderLen, C);
    NewLine('Header size       |' + C + ' bytes');
    Str(DB^.Header^.RecordLen - DB^.ExtraRecordLen, C);
    NewLine('Record size       |' + C + ' bytes');
    Str(DB^.Fields^.Count, C);
    NewLine('Number of fields  |' + C);
    Str(DB^.Header^.NumRecords, C);
    NewLine('Number of records |' + C);
  end;
  Dispose(DB, Done);
  GetDBFInfo := B;
end;

procedure OpenDataViewer(const AName: FNameStr; InfoPtr: Pointer);
var
  Exists, Dev, C: Boolean;
  I: Integer;
  P: PView;
  DB: PDataBase;
  R: TRect;
  InName, OutName: FNameStr;
  XLATTable: ConvertTable;
  F: lFile;
begin
  SameWinFlag := (InfoPtr = @ExecRec) and
    (ExecRec.Options and opInfoBit <> 0);
  P := Message(Desktop, evBroadcast, cmOpenDataViewer, @AName);
  SameWinFlag := False;
  if P <> nil then Exit;
  InName := '';
  OutName := '';
  if (InfoPtr = @ExecRec) and (ExecRec.Params <> '') then
  begin
    I := Pos(';', ExecRec.Params);
    if I = 0 then I := 255;
    if I <> 1 then
      InName := lFExpand(Trim(Copy(ExecRec.Params, 1, I - 1)));
    if I < Length(ExecRec.Params) then
      OutName := lFExpand(Trim(Copy(ExecRec.Params, I + 1, 255)));
  end;
  DrawOpenStatus(AName);
  lAssignFile(F, AName);
  lResetReadOnly(F, 1);
  Exists := IOResult = 0;
  Dev := Exists and IsDevice(FileRec(F.F).Handle);
  Close(F.F);
  InOutRes := 0;
  if Dev then
  begin
    FileIsDeviceMsgBox(AName);
    Exit;
  end;
  if not Exists then
  begin
    if CreateNewFileMsgBox(AName) <> cmOk then Exit;
    if (OutName <> '') and
      not ReadConvertTable(XLATTable, OutName, C) then OutName := '';
    if NewDBDlg(AName, nil, 0, XLATTable, OutName <> '') <> cmOk then Exit;
  end;
  DB := New(PDataBase, Init(AName));
  if not DB^.Valid then
  begin
    Dispose(DB, Done);
    CouldNotOpenMsgBox(AName);
  end
  else
  begin
    if InName <> '' then DB^.SetXLATTable(InName, dcXLATIN);
    if OutName <> '' then DB^.SetXLATTable(OutName, dcXLATOUT);
    if DB^.Options and dbXLATIN <> 0 then DB^.ConvertFields(dcXLATIN);
    GetBoundsForNewWindow(R);
    Application^.InsertWindow(New(PDataWindow, Init(R, DB)));
  end;
end;

end.