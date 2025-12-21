unit ColorSel;
{$X+,O+,F+}

interface

uses Objects, Drivers, Views, Dialogs;

const
  cmColorForegroundChanged = 71;
  cmColorBackgroundChanged = 72;
  cmColorSet               = 73;
  cmNewColorItem           = 74;
  cmNewColorIndex          = 75;

  ViewPalLen = 63;

type

  { TColorDialogData }

  PColorDialogData = ^TColorDialogData;
  TColorDialogData = record
    AppPal: String;
    CurPal: String[ViewPalLen];
  end;

  { TColorItem }

  PColorItem = ^TColorItem;
  TColorItem = record
    Name: PString;
    Index: Byte;
    Next: PColorItem;
  end;

  { TColorGroup }

  PColorGroup = ^TColorGroup;
  TColorGroup = record
    Name:  PString;
    Items: PColorItem;
    Next:  PColorGroup;
  end;

  { TColorSelector }

  TColorSel = (csForeground, csBackground);

  PColorSelector = ^TColorSelector;
  TColorSelector = object(TView)
    Color: Byte;
    SelType: TColorSel;
    constructor Init(var Bounds: TRect; ASelType: TColorSel);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
  end;

  { TMonoSelector }

  PMonoSelector = ^TMonoSelector;
  TMonoSelector = object(TRadioButtons)
    Color: Byte;
    SelType: TColorSel;
    constructor Init(var Bounds: TRect; ASelType: TColorSel);
    constructor Load(var S: TStream);
{    procedure Draw; virtual;}
    function GetHelpCtx: Word; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
{    function Mark(Item: Integer): Boolean; virtual;}
    procedure NewColor;
    procedure Press(Item: Integer); virtual;
    procedure MovedTo(Item: Integer); virtual;
    procedure Store(var S: TStream);
  end;

  { TColorDisplay }

  PColorDisplay = ^TColorDisplay;
  TColorDisplay = object(TView)
    Color: ^Byte;
    Text: PString;
    constructor Init(var Bounds: TRect; AText: PString);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetColor(var AColor: Byte); virtual;
    procedure Store(var S: TStream);
  end;

  { TColorGroupList }

  PColorGroupList = ^TColorGroupList;
  TColorGroupList = object(TListViewer)
    Groups: PColorGroup;
    constructor Init(var Bounds: TRect; AScrollBar: PScrollBar;
      AGroups: PColorGroup);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure Store(var S: TStream);
  end;

  { TColorItemList }

  PColorItemList = ^TColorItemList;
  TColorItemList = object(TListViewer)
    Items: PColorItem;
    constructor Init(var Bounds: TRect; AScrollBar: PScrollBar;
      AItems: PColorItem);
    procedure FocusItem(Item: Integer); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  { TColorDialog }

  PColorDialog = ^TColorDialog;
  TColorDialog = object(TDialog)
    Display: PColorDisplay;
    Groups: PColorGroupList;
    ForLabel: PLabel;
    ForSel: PColorSelector;
    BakLabel: PLabel;
    BakSel: PColorSelector;
    MonoForeLabel: PLabel;
    MonoForeSel: PMonoSelector;
    MonoBackLabel: PLabel;
    MonoBackSel: PMonoSelector;
    Pal: TPalette;
    constructor Init(APalette: TPalette; AGroups: PColorGroup);
    constructor Load(var S: TStream);
    function DataSize: Word; virtual;
    procedure GetData(var Rec); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure Store(var S: TStream);
  end;

{ Color list building routines }

function ColorItem(Name: String; Index: Byte; Next: PColorItem): PColorItem;
function ColorGroup(Name: String; Items: PColorItem; Next: PColorGroup):
  PColorGroup;

implementation

uses Dos, Memory, App, StdDlg, HistList, History, RGBDlg, EditFile, EditMsg,
  HeapUMB, LFN, DosTools, TPString, Consts, Commands, Defaults;

{ TColorSelector }

constructor TColorSelector.Init(var Bounds: TRect; ASelType: TColorSel);
begin
  TView.Init(Bounds);
  Options := Options or (ofSelectable + ofFirstClick + ofFramed);
  EventMask := EventMask or evBroadcast;
  SelType := ASelType;
end;

constructor TColorSelector.Load(var S: TStream);
begin
  TView.Load(S);
  S.Read(Color, SizeOf(Byte) + SizeOf(TColorSel));
end;

procedure TColorSelector.Draw;
var
  C, I, J: Integer;
  B: TDrawBuffer;
begin
  MoveChar(B, ' ', $70, Size.X);
  for I := 0 to Size.Y do
  begin
    if I < 4 then
      for J := 0 to 3 do
      begin
	C := I * 4 + J;
	MoveChar(B[ J*3 ], #219, C, 3);
	if C = Byte(Color) then
	begin
	  WordRec(B[ J*3+1 ]).Lo := 8;
	  if C = 0 then WordRec(B[ J*3+1 ]).Hi := $70;
	end;
      end;
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure TColorSelector.HandleEvent(var Event: TEvent);
const
  Width = 4;
var
  MaxCol: Byte;
  Mouse: TPoint;
  OldColor: Byte;

procedure ColorChanged;
var
  Msg: Integer;
begin
  if SelType = csForeground then
    Msg := cmColorForegroundChanged else
    Msg := cmColorBackgroundChanged;
  Message(Owner, evBroadcast, Msg, Pointer(Color));
end;

begin
  TView.HandleEvent(Event);
  case Event.What of
    evMouseDown:
      begin
	OldColor := Color;
	repeat
	  if MouseInView(Event.Where) then
	  begin
	    MakeLocal(Event.Where, Mouse);
	    Color := Mouse.Y * 4 + Mouse.X div 3;
	  end
	  else Color := OldColor;
	  ColorChanged;
	  DrawView;
	until not MouseEvent(Event, evMouseMove);
      end;
    evKeyDown:
      begin
{	if SelType = csBackground then
	  MaxCol := 7 else} MaxCol := 15;
	case CtrlToArrow(Event.KeyCode) of
	  kbLeft:
	    if Color > 0 then
	      Dec(Color) else
	      Color := MaxCol;
	  kbRight:
	    if Color < MaxCol then
	      Inc(Color) else
	      Color := 0;
	  kbUp:
	    if Color > Width - 1 then
	      Dec(Color, Width) else
	      if Color = 0 then
		Color := MaxCol else
		Inc(Color, MaxCol - Width);
	  kbDown:
	    if Color < MaxCol - (Width - 1) then
	      Inc(Color, Width) else
	      if Color = MaxCol then
		Color := 0 else
		Dec(Color, MaxCol - Width);
	else
	  Exit;
	end;
      end;
    evBroadcast:
      if Event.Command = cmColorSet then
      begin
	if SelType = csBackground then
	  Color := Event.InfoByte shr 4 else
	  Color := Event.InfoByte and $0F;
	DrawView;
	Exit;
      end else Exit;
    else Exit;
  end;
  DrawView;
  ColorChanged;
  Event.What := evNothing;
end;

procedure TColorSelector.Store(var S: TStream);
begin
  TView.Store(S);
  S.Write(Color, SizeOf(Byte) + SizeOf(TColorSel));
end;

{ TMonoSelector }

const
{  MonoColors: array[0..4] of Byte = ($07, $0F, $01, $70, $09);}
  MonoFore: Array[0..4] of Byte = (0, 1, 7, 9, 15);
  MonoBack: Array[0..2] of Byte = (0, 7, 15);

constructor TMonoSelector.Init(var Bounds: TRect; ASelType: TColorSel);
var
  SItem: PSItem;
begin
  if ASelType = csForeground then SItem :=
    NewSItem('Black',
    NewSItem('Gray _',
    NewSItem('Gray',
    NewSItem('White _',
    NewSItem('White', nil)))))
  else SItem :=
    NewSItem('Black',
    NewSItem('Gray',
    NewSItem('Blink', nil)));
  Inherited Init(Bounds, SItem);
  EventMask := EventMask or evBroadcast;
  SelType := ASelType;
end;

constructor TMonoSelector.Load(var S: TStream);
begin
  Inherited Load(S);
  S.Read(Color, SizeOf(Byte) + SizeOf(TColorSel));
end;

function TMonoSelector.GetHelpCtx: Word;
begin
  if Owner^.State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else GetHelpCtx := HelpCtx;
end;

procedure TMonoSelector.HandleEvent(var Event: TEvent);
begin
  TCluster.HandleEvent(Event);
  if (Event.What = evBroadcast) and (Event.Command = cmColorSet) then
  begin
    if SelType = csForeground then
    begin
      Color := Event.InfoByte and $0F;
      case Color of
	0: Value := 0;
	1: Value := 1;
	7: Value := 2;
	9: Value := 3;
	15: Value := 4;
	else Value := 5;
      end;
    end
    else
    begin
      Color := Event.InfoByte shr 4;
      case Color of
	0: Value := 0;
	7: Value := 1;
	15: Value := 2;
	else Value := 3;
      end;
    end;
    DrawView;
  end;
end;

procedure TMonoSelector.NewColor;
var
  Msg: Integer;
begin
  if SelType = csForeground then Msg := cmColorForegroundChanged
  else Msg := cmColorBackgroundChanged;
  Message(Owner, evBroadcast, Msg, Pointer(Color));
end;

procedure TMonoSelector.Press(Item: Integer);
begin
  Value := Item;
  if SelType = csForeground then Color := MonoFore[Item]
  else Color := MonoBack[Item];
  NewColor;
end;

procedure TMonoSelector.MovedTo(Item: Integer);
begin
  Press(Item);
end;

procedure TMonoSelector.Store(var S: TStream);
begin
  Inherited Store(S);
  S.Write(Color, SizeOf(Byte) + SizeOf(TColorSel));
end;

{ TColorDisplay }

constructor TColorDisplay.Init(var Bounds: TRect; AText: PString);
begin
  TView.Init(Bounds);
  EventMask := EventMask or evBroadcast;
  Text := AText;
  Color := nil;
end;

constructor TColorDisplay.Load(var S: TStream);
begin
  TView.Load(S);
{  Text := S.ReadStr;}
  Text := ReadStrUMB(@S);
end;

destructor TColorDisplay.Done;
begin
{  DisposeStr(Text);}
  DisposeStrUMB(Text);
  TView.Done;
end;

procedure TColorDisplay.Draw;
var
  I: Integer;
  C: Byte;
  B: TDrawBuffer;
begin
  C := Color^;
  if C = 0 then C := ErrorAttr;
  for I := 0 to Size.X div Length(Text^) do
    MoveStr(B[I*Length(Text^)], Text^, C);
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

procedure TColorDisplay.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  case Event.What of
    evBroadcast:
      case Event.Command of
	cmColorBackgroundChanged:
	  begin
	    Color^ := (Color^ and $0F) or (Event.InfoByte shl 4 and $F0);
	    DrawView;
	  end;
	cmColorForegroundChanged:
	  begin
	    Color^ := (Color^ and $F0) or (Event.InfoByte and $0F);
	    DrawView;
	  end;
      end;
  end;
end;

procedure TColorDisplay.SetColor(var AColor: Byte);
begin
  Color := @AColor;
  Message(Owner, evBroadcast, cmColorSet, Pointer(Color^));
  DrawView;
end;

procedure TColorDisplay.Store(var S: TStream);
begin
  TView.Store(S);
  S.WriteStr(Text);
end;

{ TColorGroupList }

constructor TColorGroupList.Init(var Bounds: TRect; AScrollBar: PScrollBar;
  AGroups: PColorGroup);
var
  I: Integer;
begin
  TListViewer.Init(Bounds, 1, nil, AScrollBar);
  Groups := AGroups;
  I := 0;
  while AGroups <> nil do
  begin
    AGroups := AGroups^.Next;
    Inc(I);
  end;
  SetRange(I);
end;

constructor TColorGroupList.Load(var S: TStream);

function ReadItems: PColorItem;
var
  Count, I: Integer;
  Itms:  PColorItem;
  CurItm: ^PColorItem;
begin
  S.Read(Count, SizeOf(Integer));
  Itms := nil;
  CurItm := @Itms;
  for I := 1 to Count do
  begin
    New(CurItm^);
    with CurItm^^ do
    begin
{      Name := S.ReadStr;}
      Name := ReadStrUMB(@S);
      S.Read(Index, SizeOf(Byte));
    end;
    CurItm := @CurItm^^.Next;
  end;
  CurItm^ := nil;
  ReadItems := Itms;
end;

function ReadGroups: PColorGroup;
var
  Count, I: Integer;
  Grps:  PColorGroup;
  CurGrp: ^PColorGroup;
begin
  S.Read(Count, SizeOf(Integer));
  Grps := nil;
  CurGrp := @Grps;
  for I := 1 to Count do
  begin
    New(CurGrp^);
    with CurGrp^^ do
    begin
{      Name := S.ReadStr;}
      Name := ReadStrUMB(@S);
      Items := ReadItems;
    end;
    CurGrp := @CurGrp^^.Next;
  end;
  CurGrp^ := nil;
  ReadGroups := Grps;
end;

begin
  TListViewer.Load(S);
  Groups := ReadGroups;
end;

destructor TColorGroupList.Done;

procedure FreeItems(CurITem: PColorItem);
var
  P: PColorItem;
begin
  while CurItem <> nil do
  begin
    P := CurItem;
{    DisposeStr(CurItem^.Name);}
    DisposeStrUMB(CurItem^.Name);
    CurItem := CurItem^.Next;
    Dispose(P);
  end;
end;

procedure FreeGroups(CurGroup: PColorGroup);
var
  P: PColorGroup;
begin
  while CurGroup <> nil do
  begin
    P := CurGroup;
    FreeItems(CurGroup^.Items);
{    DisposeStr(CurGroup^.Name);}
    DisposeStrUMB(CurGroup^.Name);
    CurGroup := CurGroup^.Next;
    Dispose(P);
  end
end;

begin
  TListViewer.Done;
  FreeGroups(Groups);
end;

procedure TColorGroupList.FocusItem(Item: Integer);
var
  CurGroup: PColorGroup;
begin
  TListViewer.FocusItem(Item);
  CurGroup := Groups;
  while Item > 0 do
  begin
    CurGroup := CurGroup^.Next;
    Dec(Item);
  end;
  Message(Owner, evBroadcast, cmNewColorItem, CurGroup^.Items);
end;

function TColorGroupList.GetText(Item: Integer; MaxLen: Integer): String;
var
  I: Integer;
  CurGroup: PColorGroup;
begin
  CurGroup := Groups;
  while Item > 0 do
  begin
    CurGroup := CurGroup^.Next;
    Dec(Item);
  end;
  GetText := CurGroup^.Name^;
end;

procedure TColorGroupList.Store(var S: TStream);

procedure WriteItems(Items: PColorItem);
var
  Count: Integer;
  CurItm: PColorItem;
begin
  Count := 0;
  CurItm := Items;
  while CurItm <> nil do
  begin
    CurItm := CurItm^.Next;
    Inc(Count);
  end;
  S.Write(Count, SizeOf(Integer));
  CurItm := Items;
  while CurItm <> nil do
  begin
    with CurItm^ do
    begin
      S.WriteStr(Name);
      S.Write(Index, SizeOf(Byte));
    end;
    CurItm := CurItm^.Next;
  end;
end;

procedure WriteGroups(Groups: PColorGroup);
var
  Count: Integer;
  CurGrp: PColorGroup;
begin
  Count := 0;
  CurGrp := Groups;
  while CurGrp <> nil do
  begin
    CurGrp := CurGrp^.Next;
    Inc(Count);
  end;
  S.Write(Count, SizeOf(Integer));
  CurGrp := Groups;
  while CurGrp <> nil do
  begin
    with CurGrp^ do
    begin
      S.WriteStr(Name);
      WriteItems(Items);
    end;
    CurGrp := CurGrp^.Next;
  end;
end;

begin
  TListViewer.Store(S);
  WriteGroups(Groups);
end;

{ TColorItemList }

constructor TColorItemList.Init(var Bounds: TRect; AScrollBar: PScrollBar;
  AItems: PColorItem);
var
  I: Integer;
begin
  TListViewer.Init(Bounds, 1, nil, AScrollBar);
  EventMask := EventMask or evBroadcast;
  Items := AItems;
  I := 0;
  while AItems <> nil do
  begin
    AItems := AItems^.Next;
    Inc(I);
  end;
  SetRange(I);
end;

procedure TColorItemList.FocusItem(Item: Integer);
var
  CurItem: PColorItem;
begin
  TListViewer.FocusItem(Item);
  CurItem := Items;
  while Item > 0 do
  begin
    CurItem := CurItem^.Next;
    Dec(Item);
  end;
  Message(Owner, evBroadcast, cmNewColorIndex, Pointer(CurItem^.Index));
end;

function TColorItemList.GetText(Item: Integer; MaxLen: Integer): String;
var
  CurItem: PColorItem;
begin
  CurItem := Items;
  while Item > 0 do
  begin
    CurItem := CurItem^.Next;
    Dec(Item);
  end;
  GetText := CurItem^.Name^;
end;

procedure TColorItemList.HandleEvent(var Event: TEvent);
var
  I: Integer;
  CurItem: PColorItem;
begin
  TListViewer.HandleEvent(Event);
  case Event.What of
    evBroadcast:
      if Event.Command = cmNewColorItem then
      begin
	Items := Event.InfoPtr;
	CurItem := Items;
	I := 0;
	while CurItem <> nil do
	begin
	  CurItem := CurItem^.Next;
	  Inc(I);
	end;
	SetRange(I);
	FocusItem(0);
	DrawView;
      end
      else if Event.Command = cmColors then FocusItem(Focused);
  end;
end;

{ TColorDialog }

constructor TColorDialog.Init(APalette: TPalette; AGroups: PColorGroup);
var
  P: PView;
  R: TRect;
begin
  R.Assign(0, 0, 65, ScreenHeight - 5);
  TDialog.Init(R, 'Colors');
  Options := Options or ofCentered;
  Pal := APalette;

  R.Assign(18, 3, 19, Size.Y - 4);
  P := New(PScrollBar, Init(R));
  Insert(P);
  R.Assign(3, 3, 18, Size.Y - 4);
  Groups := New(PColorGroupList, Init(R, PScrollBar(P), AGroups));
  Insert(Groups);
  R.Assign(2, 2, 19, 3);
  Insert(New(PLabel, Init(R, '~G~roup', Groups)));

  R.Assign(45, 3, 46, Size.Y - 4);
  P := New(PScrollBar, Init(R));
  Insert(P);
  R.Assign(21, 3, 45, Size.Y - 4);
  P := New(PColorItemList, Init(R, PScrollBar(P), AGroups^.Items));
  Insert(P);
  R.Assign(20, 2, 46, 3);
  Insert(New(PLabel, Init(R, '~I~tem', P)));

  R.Assign(49, 3, 61, 7);
  ForSel := New(PColorSelector, Init(R, csForeground));
  Insert(ForSel);
  Dec(R.A.Y); R.B.Y := R.A.Y + 1;
  ForLabel := New(PLabel, Init(R, '~F~oreground', ForSel));
  Insert(ForLabel);

  Inc(R.A.Y, 7); Inc(R.B.Y, 10);
  BakSel := New(PColorSelector, Init(R, csBackground));
  Insert(BakSel);
  Dec(R.A.Y); R.B.Y := R.A.Y + 1;
  BakLabel := New(PLabel, Init(R, '~B~ackground', BakSel));
  Insert(BakLabel);

  Dec(R.A.X); Inc(R.B.X); Inc(R.A.Y, 6); Inc(R.B.Y, 7);
{  Display := New(PColorDisplay, Init(R, NewStr('Text ')));}
  Display := New(PColorDisplay, Init(R, NewStrUMB('Text ')));
  Insert(Display);

  R.Assign(48, 3, 61, 8);
  MonoForeSel := New(PMonoSelector, Init(R, csForeground));
{  MonoForeSel^.Hide;}
  Insert(MonoForeSel);
  R.Assign(47, 2, 61, 3);
  MonoForeLabel := New(PLabel, Init(R, '~F~oreground', MonoForeSel));
{  MonoForeLabel^.Hide;}
  Insert(MonoForeLabel);

  R.Assign(48, 10, 61, 13);
  MonoBackSel := New(PMonoSelector, Init(R, csBackground));
{  MonoBackSel^.Hide;}
  Insert(MonoBackSel);
  R.Assign(47, 9, 61, 10);
  MonoBackLabel := New(PLabel, Init(R, '~B~ackground', MonoBackSel));
{  MonoBackLabel^.Hide;}
  Insert(MonoBackLabel);

  if (AGroups <> nil) and (AGroups^.Items <> nil) then
    Display^.SetColor(Byte(Pal[AGroups^.Items^.Index]));

  R.Assign(2, Size.Y - 3, 8, Size.Y - 1);
  StandardOkButton(R, @Self);
  R.Assign(9, Size.Y - 3, 20, Size.Y - 1);
  Insert(New(PButton, Init(R, '~D~efault', cmColors, bfNormal)));
  R.Assign(21, Size.Y - 3, 28, Size.Y - 1);
  Insert(New(PButton, Init(R, 'B&~W~', cmNewColorIndex, bfNormal)));
  R.Assign(29, Size.Y - 3, 43, Size.Y - 1);
  Insert(New(PButton, Init(R, '~V~GA colors', cmColorSet, bfNormal)));
  R.Assign(44, Size.Y - 3, 52, Size.Y - 1);
  Insert(New(PButton, Init(R, '~L~oad', cmRetrieveOptions, bfNormal)));
  R.Assign(53, Size.Y - 3, 62, Size.Y - 1);
  Insert(New(PButton, Init(R, '~S~tore', cmSaveOptions, bfNormal)));
  HelpCtx := hcColors;
end;

constructor TColorDialog.Load(var S: TStream);
var
  Len: Byte;
begin
  TDialog.Load(S);
  GetSubViewPtr(S, Display);
  GetSubViewPtr(S, Groups);
  GetSubViewPtr(S, ForLabel);
  GetSubViewPtr(S, ForSel);
  GetSubViewPtr(S, BakLabel);
  GetSubViewPtr(S, BakSel);
  GetSubViewPtr(S, MonoForeLabel);
  GetSubViewPtr(S, MonoForeSel);
  GetSubViewPtr(S, MonoBackLabel);
  GetSubViewPtr(S, MonoBackSel);
  S.Read(Len, SizeOf(Byte));
  S.Read(Pal[1], Len);
  Pal[0] := Char(Len);
end;

procedure TColorDialog.HandleEvent(var Event: TEvent);
var
  PalPos: Integer;
  PalPtr: Pointer;
  PName: FNameStr;

procedure DefaultPalForGroup;
var
  I: Integer;
  P: PColorGroup;
  IP: PColorItem;
begin
  P := Groups^.Groups;
  I := Groups^.Focused;
  while I > 0 do
  begin
    P := P^.Next;
    Dec(I);
  end;
  IP := P^.Items;
  while IP <> nil do
  begin
    Pal[IP^.Index] := DefaultPalette[IP^.Index];
    IP := IP^.Next;
  end;
end;

procedure BlackWhitePal;
var
  SavePal: Integer;
begin
  SavePal := AppPalette;
  AppPalette := apBlackWhite;
  Pal := Application^.GetPalette^;
  Pal[255] := #$07;
  AppPalette := SavePal;
end;

function PalName(const AHeader: String): FNameStr;
var
  S: FNameStr;
begin
  S := HistoryStr(PaletteHistoryID, 0);
  if Application^.ExecuteDialog(
    New(PFileDialog, Init('*.PAL', AHeader + ' palette',
    '~P~alette file name', fdOkButton + fdHelpButton, PaletteHistoryID)),
    @S, False) = cmCancel then S := '';
  PalName := S;
end;

procedure LoadPal(const Name: FNameStr);
var
  F: lFile;
begin
  lAssignFile(F, Name);
  lResetReadOnly(F, 1);
  if IOResult <> 0 then
  begin
    CouldNotOpenMsgBox(Name);
    Exit;
  end;
  if IsDevice(FileRec(F.F).Handle) then
  begin
    System.Close(F.F);
    InOutRes := 0;
    FileIsDeviceMsgBox(Name);
    Exit;
  end;
  BlockRead(F.F, Pal, SizeOf(TPalette));
  System.Close(F.F);
  InOutRes := 0;
end;

procedure StorePal(const Name: FNameStr);
var
  F: lFile;
begin
  lAssignFile(F, Name);
  lRewriteFile(F, 1);
  if IOResult <> 0 then
  begin
    CouldNotCreateMsgBox(Name);
    Exit;
  end;
  if NotAccessible(FileRec(F.F).Handle) then
  begin
    System.Close(F.F);
    InOutRes := 0;
    FileIsDeviceMsgBox(Name);
    Exit;
  end;
  BlockWrite(F.F, Pal, SizeOf(TPalette));
  System.Close(F.F);
  InOutRes := 0;
  UpdateFiles(Name);
end;

begin
  TDialog.HandleEvent(Event);
  if Event.What = evBroadcast then
    case Event.Command of
      cmNewColorIndex: Display^.SetColor(Byte(Pal[Event.InfoByte]));
      cmColorForegroundChanged, cmColorBackgroundChanged, cmColors:
	begin
	  Application^.GetPalette^ := Pal;
	  ShadowAttr := Byte(Pal[255]);
	  DoneMemory;
	  Application^.Redraw;
	end;
    end
  else if Event.What = evCommand then
    case Event.Command of
      cmColors:
	begin
	  if GetShiftState and kbCtrlShift <> 0 then
	    if Groups^.State and sfSelected <> 0 then DefaultPalForGroup
	    else
	    begin
	      PalPtr := @Pal;
	      PalPos := PtrRec(Display^.Color).Ofs - PtrRec(PalPtr).Ofs;
	      if (PalPos > 0) and (PalPos <= 255) then
		Pal[PalPos] := DefaultPalette[PalPos];
	    end
	  else Move(DefaultPalette, Pal, SizeOf(TPalette));
	  Event.What := evBroadcast;
	  HandleEvent(Event);
	end;
      cmNewColorIndex:
	begin
	  BlackWhitePal;
	  Event.What := evBroadcast;
	  Event.Command := cmColors;
	  HandleEvent(Event);
	end;
      cmColorSet:
	begin
	  RGBDialog;
	  Event.What := evNothing;
	end;
      cmSaveOptions:
	begin
	  PName := PalName('Store');
	  if PName <> '' then StorePal(PName);
	  Event.What := evNothing;
	end;
      cmRetrieveOptions:
	begin
	  PName := PalName('Load');
	  if PName <> '' then LoadPal(PName);
	  Event.What := evBroadcast;
	  Event.Command := cmColors;
	  HandleEvent(Event);
	end;
    end;
end;

procedure TColorDialog.Store(var S: TStream);
begin
  TDialog.Store(S);
  PutSubViewPtr(S, Display);
  PutSubViewPtr(S, Groups);
  PutSubViewPtr(S, ForLabel);
  PutSubViewPtr(S, ForSel);
  PutSubViewPtr(S, BakLabel);
  PutSubViewPtr(S, BakSel);
  PutSubViewPtr(S, MonoForeLabel);
  PutSubViewPtr(S, MonoForeSel);
  PutSubViewPtr(S, MonoBackLabel);
  PutSubViewPtr(S, MonoBackSel);
  S.Write(Pal, Length(Pal)+1);
end;

function TColorDialog.DataSize: Word;
begin
  DataSize := SizeOf(TPalette);
end;

procedure TColorDialog.GetData(var Rec);
begin
end;

procedure TColorDialog.SetData(var Rec);

function GetCurViewIndex: Integer;
var
  B: Byte;
  I: Integer;
  P: PColorGroup;
  S: String[ViewPalLen];
begin
  S := TColorDialogData(Rec).CurPal;
  I := 0;
  P := Groups^.Groups;
  while P <> nil do
  begin
    for B := 1 to Length(S) do
      if P^.Items^.Index = Byte(S[B]) then
      begin
	GetCurViewIndex := I;
	Exit;
      end;
    Inc(I);
    P := P^.Next;
  end;
  GetCurViewIndex := 0;
end;

begin
  Pal := TColorDialogData(Rec).AppPal;
  Groups^.FocusItem(GetCurViewIndex);
  if ShowMarkers then
  begin
    ForLabel^.Free;
    ForSel^.Free;
    BakLabel^.Free;
    BakSel^.Free;
  end
  else
  begin
    MonoForeLabel^.Free;
    MonoForeSel^.Free;
    MonoBackLabel^.Free;
    MonoBackSel^.Free;
  end;
  Groups^.Select;
end;

{ -- Color list building routines -- }

function ColorItem(Name: String; Index: Byte; Next: PColorItem): PColorItem;
var
  Item: PColorItem;
begin
  New(Item);
{  Item^.Name := NewStr(Name);}
  Item^.Name := NewStrUMB(Name);
  Item^.Index := Index;
  Item^.Next := Next;
  ColorItem := Item;
end;

function ColorGroup(Name: String; Items: PColorItem; Next: PColorGroup):
  PColorGroup;
var
  Group: PColorGroup;
begin
  New(Group);
{  Group^.Name := NewStr(Name);}
  Group^.Name := NewStrUMB(Name);
  Group^.Items := Items;
  Group^.Next := Next;
  ColorGroup := Group;
end;

end.