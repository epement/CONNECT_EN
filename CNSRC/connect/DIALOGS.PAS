
{*******************************************************}
{                                                       }
{       Turbo Pascal Version 6.0                        }
{       Turbo Vision Unit                               }
{                                                       }
{       Copyright (c) 1990 Borland International        }
{                                                       }
{*******************************************************}

unit Dialogs;

{$O+,F+,S-,X+}

interface

uses Objects, Drivers, Views;

const

{ Color palettes }

  CDialog        = #32#33#34#35#36#37#38#39#40#41#42#43#44#45#46#47 +
                   #48#49#50#51#52#53#54#55#56#57#58#59#60#61#62#63#31;
                   { Fixed 10.22.96 to add button shortcut default/sel }

  CStaticText    = #6;
  CLabel         = #7#8#9#9;
  CButton        = #10#11#12#13#14#32#33#15;
  CCluster       = #16#17#18#18#31;
  CInputLine     = #19#19#20#21;
  CHistory       = #22#23;
  CHistoryWindow = #19#19#21#24#25#19#20;
  CHistoryViewer = #6#6#7#6#6;

{ TButton flags }

  bfNormal    = $00;
  bfDefault   = $01;
  bfLeftJust  = $02;
  bfBroadcast = $04;

{ TMultiCheckboxes flags }
{ hibyte = number of bits }
{ lobyte = bit mask }

  cfOneBit       = $0101;
  cfTwoBits      = $0203;
  cfThreeBits    = $0307;
  cfFourBits     = $040F;
  cfEightBits    = $08FF;

type

{ TDialog object }

  { Palette layout }
  {  1 = Frame passive }
  {  2 = Frame active }
  {  3 = Frame icon }
  {  4 = ScrollBar page area }
  {  5 = ScrollBar controls }
  {  6 = StaticText }
  {  7 = Label normal }
  {  8 = Label selected }
  {  9 = Label shortcut }
  { 10 = Button normal }
  { 11 = Button default }
  { 12 = Button selected }
  { 13 = Button disabled }
  { 14 = Button shortcut }
  { 15 = Button shadow }
  { 16 = Cluster normal }
  { 17 = Cluster selected }
  { 18 = Cluster shortcut }
  { 19 = InputLine normal text }
  { 20 = InputLine selected text }
  { 21 = InputLine arrows }
  { 22 = History arrow }
  { 23 = History sides }
  { 24 = HistoryWindow scrollbar page area }
  { 25 = HistoryWindow scrollbar controls }
  { 26 = ListViewer normal }
  { 27 = ListViewer focused }
  { 28 = ListViewer selected }
  { 29 = ListViewer divider }
  { 30 = InfoPane }
  { 31 = Cluster disabled }
  { 32 = Reserved }

{ Added 02.05.99 }
  TEventProc = procedure(V: PView; var Event: TEvent);

  PDialog = ^TDialog;
  TDialog = object(TWindow)
    PreProcessEvent: TEventProc; { Added 02.05.99 }
    PostProcessEvent: TEventProc; { Added 02.05.99 }
    constructor Init(var Bounds: TRect; const ATitle: TTitleStr);
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function Valid(Command: Word): Boolean; virtual;
  end;

{ TSItem }

  PSItem = ^TSItem;
  TSItem = record
    Value: PString;
    Next: PSItem;
  end;

{ TInputLine object }

  { Palette layout }
  { 1 = Passive }
  { 2 = Active }
  { 3 = Selected }
  { 4 = Arrows }

  PInputLine = ^TInputLine;
  TInputLine = object(TView)
    Data: PString;
    UndoData: PString; { Added 09.18.97 to support Windows style input Undo }
    MaxLen: Integer;
    CurPos: Integer;
    FirstPos: Integer;
    SelStart: Integer;
    SelEnd: Integer;
    Modified: Boolean; { Added 09.18.97 }
    History: Pointer; { Added 02.03.99 }
{ Added 04.08.08 to support InputLine AutoComplete }
    HistoryId: Word;
    constructor Init(var Bounds: TRect; AMaxLen: Integer);
    constructor Load(var S: TStream);
    destructor Done; virtual;
{ Added 04.08.08 to support InputLine AutoComplete }
    procedure AutoComplete;
    procedure Copy; {virtual;}
    procedure Cut; {virtual;}
    function DataSize: Word; virtual;
    procedure Draw; virtual;
    procedure GetData(var Rec); virtual;
    function GetPalette: PPalette; virtual;
    function GetText: String; {virtual;}
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Paste; {virtual;}
    procedure SelectAll(Enable: Boolean);
    procedure SetData(var Rec); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
  private
    function CanScroll(Delta: Integer): Boolean;
  end;

{ TButton object }

  { Palette layout }
  { 1 = Normal text }
  { 2 = Default text }
  { 3 = Selected text }
  { 4 = Disabled text }
  { 5 = Normal shortcut }
  { 6 = Default shortcut }
  { 7 = Selected shortcut }
  { 8 = Shadow }

  PButton = ^TButton;
  TButton = object(TView)
    Title: PString;
    Command: Word;
    Flags: Byte;
    AmDefault: Boolean;
    constructor Init(var Bounds: TRect; const ATitle: TTitleStr;
      ACommand: Word; AFlags: Word);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure DrawState(Down: Boolean);
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure MakeDefault(Enable: Boolean);
    procedure Press; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
  end;

{ TCluster }

  { Palette layout }
  { 1 = Normal text }
  { 2 = Selected text }
  { 3 = Normal shortcut }
  { 4 = Selected shortcut }
  { 5 = Disabled text }

  PCluster = ^TCluster;
  TCluster = object(TView)
    Value: LongInt;
    Sel: Integer;
    EnableMask: LongInt;
    Strings: TStringCollection;
    PreserveBits: Longint; { Added 02.03.99 }
    constructor Init(var Bounds: TRect; AStrings: PSItem);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function ButtonState(Item: Integer): Boolean;
    function DataSize: Word; virtual;
    procedure DrawBox(const Icon: String; Marker: Char);
    procedure DrawMultiBox(const Icon, Marker: String);
    procedure GetData(var Rec); virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function Mark(Item: Integer): Boolean; virtual;
    function MultiMark(Item: Integer): Byte; virtual;
    procedure Press(Item: Integer); virtual;
    procedure MovedTo(Item: Integer); virtual;
    procedure SetButtonState(AMask: Longint; Enable: Boolean);
    procedure SetData(var Rec); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
  private
    function Column(Item: Integer): Integer;
    function FindSel(P: TPoint): Integer;
    function Row(Item: Integer): Integer;
  end;

{ TRadioButtons }

  { Palette layout }
  { 1 = Normal text }
  { 2 = Selected text }
  { 3 = Normal shortcut }
  { 4 = Selected shortcut }

  PRadioButtons = ^TRadioButtons;
  TRadioButtons = object(TCluster)
    procedure Draw; virtual;
    function Mark(Item: Integer): Boolean; virtual;
    procedure MovedTo(Item: Integer); virtual;
    procedure Press(Item: Integer); virtual;
    procedure SetData(var Rec); virtual;
  end;

{ TCheckBoxes }

  { Palette layout }
  { 1 = Normal text }
  { 2 = Selected text }
  { 3 = Normal shortcut }
  { 4 = Selected shortcut }

  PCheckBoxes = ^TCheckBoxes;
  TCheckBoxes = object(TCluster)
    procedure Draw; virtual;
    function Mark(Item: Integer): Boolean; virtual;
    procedure Press(Item: Integer); virtual;
  end;

{ TMultiCheckBoxes }

  { Palette layout }
  { 1 = Normal text }
  { 2 = Selected text }
  { 3 = Normal shortcut }
  { 4 = Selected shortcut }

  PMultiCheckBoxes = ^TMultiCheckBoxes;
  TMultiCheckBoxes = object(TCluster)
    SelRange: Byte;
    Flags: Word;
    States: PString;
    constructor Init(var Bounds: TRect; AStrings: PSItem;
      ASelRange: Byte; AFlags: Word; const AStates: String);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function DataSize: Word; virtual;
    procedure Draw; virtual;
    procedure GetData(var Rec); virtual;
    function MultiMark(Item: Integer): Byte; virtual;
    procedure Press(Item: Integer); virtual;
    procedure SetData(var Rec); virtual;
    procedure Store(var S: TStream);
  end;

{ TListViewer }

  { Palette layout }
  { 1 = Active }
  { 2 = Inactive }
  { 3 = Focused }
  { 4 = Selected }
  { 5 = Divider }

  PListViewer = ^TListViewer;
  TListViewer = object(TView)
    HScrollBar: PScrollBar;
    VScrollBar: PScrollBar;
    NumCols: Integer;
    TopItem: Integer;
    Focused: Integer;
    Range: Integer;
    constructor Init(var Bounds: TRect; ANumCols: Word;
      AHScrollBar, AVScrollBar: PScrollBar);
    constructor Load(var S: TStream);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure CopyText; { Added 08.03.95 }
    procedure Draw; virtual;
    procedure FocusItem(Item: Integer); virtual;
    function GetPalette: PPalette; virtual;
    function GetCopyText(Item: Integer; MaxLen: Integer): String; virtual; { Added 08.03.95 }
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    function IsSelected(Item: Integer): Boolean; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SelectItem(Item: Integer); virtual;
    procedure SetRange(ARange: Integer);
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
  private
    procedure FocusItemNum(Item: Integer); {virtual;}
  end;

{ TListBox }

  { Palette layout }
  { 1 = Active }
  { 2 = Inactive }
  { 3 = Focused }
  { 4 = Selected }
  { 5 = Divider }

  PListBox = ^TListBox;
  TListBox = object(TListViewer)
    List: PCollection;
    constructor Init(var Bounds: TRect; ANumCols: Word;
      AScrollBar: PScrollBar);
    constructor Load(var S: TStream);
    function DataSize: Word; virtual;
    procedure GetData(var Rec); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure NewList(AList: PCollection); {virtual;}
    procedure SetData(var Rec); virtual;
    procedure Store(var S: TStream);
  end;

{ TStaticText }

  { Palette layout }
  { 1 = Text }

  PStaticText = ^TStaticText;
  TStaticText = object(TView)
    Text: PString;
    constructor Init(var Bounds: TRect; const AText: String);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure GetText(var S: String); virtual;
    procedure Store(var S: TStream);
  end;

{ TParamText }

  { Palette layout }
  { 1 = Text }

  PParamText = ^TParamText;
  TParamText = object(TStaticText)
    ParamCount: Integer;
    ParamList: Pointer;
    constructor Init(var Bounds: TRect; const AText: String;
      AParamCount: Integer);
    constructor Load(var S: TStream);
    function DataSize: Word; virtual;
    procedure GetText(var S: String); virtual;
    procedure SetData(var Rec); virtual;
    procedure Store(var S: TStream);
  end;

{ TLabel }

  { Palette layout }
  { 1 = Normal text }
  { 2 = Selected text }
  { 3 = Normal shortcut }
  { 4 = Selected shortcut }

  PLabel = ^TLabel;
  TLabel = object(TStaticText)
    Link: PView;
    Light: Boolean;
    constructor Init(var Bounds: TRect; const AText: String; ALink: PView);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Store(var S: TStream);
  end;

{ THistoryViewer }

  { Palette layout }
  { 1 = Active }
  { 2 = Inactive }
  { 3 = Focused }
  { 4 = Selected }
  { 5 = Divider }

  PHistoryViewer = ^THistoryViewer;
  THistoryViewer = object(TListViewer)
    HistoryId: Word;
    IncrPos: Integer;
{ Added 2006.01.09 }
    NormalId: Boolean;
    constructor Init(var Bounds: TRect; AHScrollBar, AVScrollBar: PScrollBar;
      AHistoryId: Word);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Draw; virtual;
    procedure FocusItem(Item: Integer); virtual;
    function GetPalette: PPalette; virtual;
    function GetCopyText(Item: Integer; MaxLen: Integer): String; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

{ THistoryWindow }

  { Palette layout }
  { 1 = Frame passive }
  { 2 = Frame active }
  { 3 = Frame icon }
  { 4 = ScrollBar page area }
  { 5 = ScrollBar controls }
  { 6 = HistoryViewer normal text }
  { 7 = HistoryViewer selected text }

  PHistoryWindow = ^THistoryWindow;
  THistoryWindow = object(TWindow)
    Viewer: PListViewer;
    constructor Init(var Bounds: TRect; HistoryId: Word);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    function GetPalette: PPalette; virtual;
    function GetSelection: String; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure InitViewer(HistoryId: Word); virtual;
  end;

{ THistory }

  { Palette layout }
  { 1 = Arrow }
  { 2 = Sides }

  { Added 02.03.99 }
  THistoryFunc = function(Link: PInputLine;
    const S: String): String;

  PHistory = ^THistory;
  THistory = object(TView)
    Link: PInputLine;
    HistoryId: Word;
    HistoryPutFunc: THistoryFunc; { Added 02.03.99 }
    HistoryGetFunc: THistoryFunc; { Added 02.03.99 }
    constructor Init(var Bounds: TRect; ALink: PInputLine; AHistoryId: Word);
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    function InitHistoryWindow(var Bounds: TRect): PHistoryWindow; {virtual;}
    procedure Store(var S: TStream);
    procedure Awaken; virtual; { Added 02.03.99 }
  end;

{ SItem routines }

function NewSItem(const Str: String; ANext: PSItem): PSItem;

const

{ Dialog broadcast commands }

  cmRecordHistory = 60;

{ QWERTY to âñìäÖç convert tables - added 09.17.97 }

  LoChars = 'F<DULT:PBQRKVYJGHCNEA{WXIO}SM">Zf,dult;pbqrkvyjg';
  HiChars = 'hcnea[wxio]sm''.z?/';
  RuChars = 'ù#$%&Ì()*+°-ÓÒ0123456789Ü¶Å=û@îàëÇìÄèêòéãÑúíôáâäõÖÉåñóçüÂ\Í^_`‰®·¢„†Ø‡ËÆ´§Ï‚Èß©™Î•£¨ÊÁ≠Ôï|ö';

{ Added 2005.09.24 }
type
  TConvertAction = (caUpcase, caLocase, caLatin, caRus, caCaps, caHex,
    caVolapyuk, caVolToRus, caUkrVolapyuk, caVolToUkr, caXLAT, caShort,
    caLong, caSpaceToUnderline, caUnderlineToSpace);

{ Standard Dialog buttons }

function StandardOkButton(var R: TRect; D: PDialog): PButton;
function StandardCancelButton(var R: TRect; D: PDialog): PButton;
function StandardHelpButton(var R: TRect; D: PDialog): PButton;
procedure StandardButtonRow(D: PDialog; SelNext: Boolean);
function StandardHistory(ALink: PView; AHistoryId: Word): PHistory;

procedure ConvertWSKey(KeyMask: Word; var Event: TEvent); { Added 02.05.99 }

{Added 12.17.99}
function MoveListItem(Viewer: PListViewer;
  List: PCollection; Up: Boolean): Boolean;

{ Added 2005.09.24 }
function StrToVolapyukStr(C, PC, NC, NNC: Char;
  var DelChars: Byte; AltUkr: Boolean): String;
function VolapyukStrToStr(C, PC, NC, NNC: Char;
  var DelChars: Byte; AltUkr: Boolean): String;
procedure ConvertString(var S: String; Action: TConvertAction;
  C: Char; W: Word);

implementation

uses App, MsgBox, HistList, LFN, FileMngr, PanelRec, Swaps, Menus, Popups,
  EditFile, DirPrim, Decoders, ProgPath, TPString, Consts, Commands, Defaults;

const

{ TButton messages }

  cmGrabDefault    = 61;
  cmReleaseDefault = 62;

{ Utility functions }

function IsBlank(Ch: Char): Boolean;
begin
  IsBlank := (Ch = ' ') or (Ch = #13) or (Ch = #10);
end;

{ TDialog }

constructor TDialog.Init(var Bounds: TRect; const ATitle: TTitleStr);
begin
  TWindow.Init(Bounds, ATitle, wnNoNumber);
  GrowMode := gfExplode;
  Flags := wfMove + wfClose;
end;

function TDialog.GetPalette: PPalette;
const
  P: string[Length(CDialog)] = CDialog;
begin
  GetPalette := @P;
end;

procedure TDialog.HandleEvent(var Event: TEvent);
begin
  if Assigned(PreProcessEvent) then PreProcessEvent(@Self, Event);
  TWindow.HandleEvent(Event);
  case Event.What of
    evKeyDown:
      case Event.KeyCode of
        kbEsc:
          begin
            Event.What := evCommand;
            Event.Command := cmCancel;
            Event.InfoPtr := nil;
            PutEvent(Event);
            Event.What := evNothing;
          end;
        kbEnter:
          begin
            Event.What := evBroadcast;
            Event.Command := cmDefault;
            Event.InfoPtr := nil;
            PutEvent(Event);
            Event.What := evNothing;
          end;
      end;
    evMouseDown: { Added 05.22.97 }
      if Event.Buttons = mbRightButton then
      begin
        Event.What := evBroadcast;
        Event.Command := cmDefault;
        Event.InfoPtr := nil;
        PutEvent(Event);
        Event.What := evNothing;
      end;
    evCommand:
      case Event.Command of
        cmOk, cmCancel, cmYes, cmNo:
          if State and sfModal <> 0 then
          begin
            EndModal(Event.Command);
            Event.What := evNothing;
          end;
      end;
  end;
  if Assigned(PostProcessEvent) then PostProcessEvent(@Self, Event);
end;

function TDialog.Valid(Command: Word): Boolean;
begin
  if Command = cmCancel then Valid := True
  else Valid := TGroup.Valid(Command);
end;

function NewSItem(const Str: String; ANext: PSItem): PSItem;
var
  Item: PSItem;
begin
  New(Item);
  Item^.Value := NewStr(Str);
  Item^.Next := ANext;
  NewSItem := Item;
end;

function Max(A, B: Integer): Integer;
inline(
   $58/     {pop   ax   }
   $5B/     {pop   bx   }
   $3B/$C3/ {cmp   ax,bx}
   $7F/$01/ {jg    @@1  }
   $93);    {xchg  ax,bx}
       {@@1:            }

function HotKey(var S: String): Char;
var
  P: Word;
begin
  P := Pos('~',S);
  if P <> 0 then HotKey := UpCase(S[P+1])
  else HotKey := #0;
end;

{ TInputLine }

constructor TInputLine.Init(var Bounds: TRect; AMaxLen: Integer);
begin
  TView.Init(Bounds);
  State := State or sfCursorVis;
  Options := Options or (ofSelectable + ofFirstClick);
  GetMem(Data, AMaxLen + 1);
  Data^ := '';
  GetMem(UndoData, AMaxLen + 1);
  UndoData^ := '';
  MaxLen := AMaxLen;
end;

constructor TInputLine.Load(var S: TStream);
begin
  TView.Load(S);
  S.Read(MaxLen, SizeOf(Integer) * 5);
  GetMem(Data, MaxLen + 1);
  S.Read(Data^[0], 1);
  S.Read(Data^[1], Length(Data^));
  GetMem(UndoData, MaxLen + 1); { Added 09.18.97 }
  UndoData^ := '';
end;

destructor TInputLine.Done;
begin
  FreeMem(UndoData, MaxLen + 1); { Added 09.18.97 }
  FreeMem(Data, MaxLen + 1);
  TView.Done;
end;

{ Added 04.08.08 to support InputLine AutoComplete }
procedure TInputLine.AutoComplete;
var
  H: Word;
  I, J: Integer;
  P: PHistoryRec;
  S: String;
begin
  if AutoDecode and adAutoComplete = 0 then Exit;
  if HistoryId <> 0 then H := HistoryId
  else if History <> nil then H := PHistory(History)^.HistoryId
  else Exit;
  J := HistoryCount(H) - 1;
  for I := 0 to J do
  begin
    P := HistoryRec(H, I);
    if (P <> nil) and (P^.StrPtr^ = '-') and
       (Byte(P^.Lock) = Byte('0')) then Exit;
  end;
  for I := 0 to J do
  begin
    S := HistoryStr(H, I);
    if Pos(Data^, S) = 1 then
    begin
      I := Length(S);
      while (I > 0) and (S[I] <> #$FF) do Dec(I);
      if I > 0 then Byte(S[0]) := I - 1;
      if Length(S) > MaxLen then Byte(S[0]) := MaxLen;
      I := Length(Data^);
      Data^ := S;
      SelStart := I;
      SelEnd := Length(S);
      Exit;
    end;
  end;
end;

function TInputLine.CanScroll(Delta: Integer): Boolean;
begin
  if Delta < 0 then
    CanScroll := FirstPos > 0 else
  if Delta > 0 then
    CanScroll := Length(Data^) - FirstPos + 2 > Size.X else
    CanScroll := False;
end;

procedure TInputLine.Copy;
var
  S: String;
begin
  S := GetText;
  if S <> '' then Message(Application, evBroadcast, cmCopy, @S);
end;

procedure TInputLine.Cut;
var
  I: Integer;
begin
  Copy;
  if SelStart <> SelEnd then
  begin
    Delete(Data^, SelStart + 1, SelEnd - SelStart);
    CurPos := SelStart;
    SelStart := 0;
    SelEnd := 0;
    DrawView;
  end;
end;

function TInputLine.DataSize: Word;
begin
  DataSize := MaxLen + 1;
end;

procedure TInputLine.Draw;
var
  Color: Byte;
  L, R: Integer;
  B: TDrawBuffer;
begin
  if FirstPos > CurPos then FirstPos := CurPos;
  L := CurPos - Size.X + 2;
  if FirstPos < L then FirstPos := L;
  if FirstPos < 0 then FirstPos := 0;
  if State and sfFocused = 0 then Color := GetColor(1)
  else Color := GetColor(2);
  MoveChar(B, ' ', Color, Size.X);
  MoveStr(B[1], System.Copy(Data^, FirstPos + 1, Size.X - 2), Color);
  if CanScroll(1) then MoveChar(B[Size.X - 1], #16, GetColor(4), 1);
  if CanScroll(-1) then MoveChar(B[0], #17, GetColor(4), 1);
  if State and sfSelected <> 0 then
  begin
    L := SelStart - FirstPos;
    R := SelEnd - FirstPos;
    if L < 0 then L := 0;
    if R > Size.X - 2 then R := Size.X - 2;
    if L < R then MoveChar(B[L + 1], #0, GetColor(3), R - L);
  end;
  WriteLine(0, 0, Size.X, Size.Y, B);
  SetCursor(CurPos - FirstPos + 1, 0);
end;

procedure TInputLine.GetData(var Rec);
begin
  FillChar(Rec, DataSize, #0);
  Move(Data^, Rec, Length(Data^) + 1);
end;

function TInputLine.GetPalette: PPalette;
const
  P: String[Length(CInputLine)] = CInputLine;
begin
  GetPalette := @P;
end;

function TInputLine.GetText: String;
begin
  if SelStart <> SelEnd then GetText :=
    System.Copy(Data^, SelStart + 1, SelEnd - SelStart)
  else GetText := Data^;
end;

procedure TInputLine.HandleEvent(var Event: TEvent);
var
  Delta, Anchor, I: Integer;

procedure GoLeft;
begin
  if CurPos > 0 then
  begin
    if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
    begin
      if (CurPos = SelEnd) and (SelStart < SelEnd) then
        Dec(SelEnd)
      else
      begin
        if SelStart = SelEnd then SelEnd := CurPos;
        SelStart := CurPos - 1;
      end;
    end;
    Dec(CurPos);
  end;
end;

procedure GoRight;
begin
  if CurPos < Length(Data^) then
  begin
    if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
    begin
      if (CurPos = SelStart) and (SelStart < SelEnd) then
        Inc(SelStart)
      else
      begin
        if SelStart = SelEnd then SelStart := CurPos;
        SelEnd := CurPos + 1;
      end;
    end;
    Inc(CurPos);
  end;
end;

function MouseDelta: Integer;
var
  Mouse: TPoint;
begin
  MakeLocal(Event.Where, Mouse);
  if Mouse.X <= 0 then MouseDelta := -1 else
  if Mouse.X >= Size.X - 1 then MouseDelta := 1 else
  MouseDelta := 0;
end;

function MousePos: Integer;
var
  Pos: Integer;
  Mouse: TPoint;
begin
  MakeLocal(Event.Where, Mouse);
  if Mouse.X < 1 then Mouse.X := 1;
  Pos := Mouse.X + FirstPos - 1;
  if Pos < 0 then Pos := 0;
  if Pos > Length(Data^) then Pos := Length(Data^);
  MousePos := Pos;
end;

procedure DeleteSelect;
begin
  if SelStart <> SelEnd then
  begin
    Delete(Data^, SelStart + 1, SelEnd - SelStart);
    CurPos := SelStart;
  end;
end;

procedure OnModify;
begin
  if not Modified then
  begin
    UndoData^ := Data^;
    Modified := True;
  end;
end;

procedure CharPressed;
begin
  OnModify;
  if State and sfCursorIns <> 0 then
    Delete(Data^, CurPos + 1, 1) else DeleteSelect;
  if Length(Data^) < MaxLen then
  begin
    if FirstPos > CurPos then FirstPos := CurPos;
    Inc(CurPos);
    Insert(Event.CharCode, Data^, CurPos);
  end;
end;

procedure InsertCurDir(Long: Boolean);
var
  S: FNameStr;
begin
  if Long then lGetDir(0, S) else GetDir(0, S);
  if S[Length(S)] <> '\' then S := S + '\';
  DeleteSelect;
  if Length(Data^) + Length(S) > MaxLen then
    S[0] := Char(MaxLen - Length(Data^));
  System.Insert(S, Data^, CurPos + 1);
  SelStart := CurPos;
  SelEnd := SelStart + Length(S);
  DrawView;
end;

{ added 05-14-03 to support Ctrl+Enter, Ctrl+J, Alt+Paren, Ctrl+[, Ctrl+] keystrokes }
function FMFocusedStr(Key: Word): FNameStr;

function IsFileManager(P: PView): Boolean; far;
begin
  IsFileManager := (P^.State and sfVisible <> 0) and
    (TypeOf(P^) = TypeOf(TPanelWindow));
end;

var
  W: PPanelWindow;
  P: PPanel;
  SR: PPanelRec;
  S: FNameStr;
begin
  FMFocusedStr := '';
  W := PPanelWindow(Desktop^.FirstThat(@IsFileManager));
  if W = nil then Exit;
  if (Key = $1A1B) or (Key = $1B1D) then
  begin
    if Key = $1A1B then W^.LeftPanel^.GetListDir(S)
    else W^.RightPanel^.GetListDir(S);
    if S[Length(S)] <> '\' then S := S + '\';
    if GetShiftState and (kbLeftShift + kbRightShift) = 0 then
      lGetShortFileName(S, S);
  end
  else
  begin
    P := W^.CurrentPanel;
    if P = nil then Exit;
    with P^ do
    begin
      if (Status >= stInfo) or (List^.Count = 0) then Exit;
      SR := List^.At(Focused);
      if (Status = stTree) and (Focused = 0) then
        S := TheTree^.GetBaseName
      else if (Key = kbAltParen) or (Options and ofValidate <> 0) or
        (SR^.Name[1] in [':', '.']) then GetRecStr(SR, S)
      else AddNameExt('', SR, S);
      if Key = kbAltParen then
        if GetShiftState and (kbLeftShift + kbRightShift) = 0 then
          lGetShortFileName(S, S) else
      else if (Key <> $240A) and not (SR^.Name[1] in [':', '.']) then
      begin
        lGetShortFileName(S, S);
        if Length(S) > 3 then S := JustFileName(S);
      end;
    end;
  end;
  FMFocusedStr := S;
end;

procedure InsertFMFocusedStr(Key: Word);
var
  S: FNameStr;
begin
  S := FMFocusedStr(Key);
  if S = '' then Exit;
  DeleteSelect;
  if Length(Data^) + Length(S) > MaxLen then
    S[0] := Char(MaxLen - Length(Data^));
  System.Insert(S, Data^, CurPos + 1);
  SelStart := CurPos;
  SelEnd := SelStart + Length(S);
  DrawView;
end;

procedure ConvertChars(Action: TConvertAction);
var
  C: Char;
  I: Integer;
  S: String;
begin
  OnModify;
  S := GetText;
  if (SelStart = SelEnd) or (SelStart = 0) then C := #0
  else C := Data^[SelStart - 1];
  ConvertString(S, Action, C, Event.KeyCode);
  if Action in [caHex, caVolapyuk, caVolToRus, caUkrVolapyuk, caVolToUkr, caShort, caLong] then
    if SelStart <> SelEnd then CurPos := SelStart else CurPos := 0;
  I := MaxLen;
  if SelStart <> SelEnd then Dec(I, Length(Data^) - (SelEnd - SelStart));
  if Length(S) > I then S[0] := Char(I);
  if SelStart <> SelEnd then
  begin
    Delete(Data^, SelStart + 1, SelEnd - SelStart);
    System.Insert(S, Data^, SelStart + 1);
  end
  else Data^ := S;
end;

procedure SwapData;
var
  S: String;
begin
  S := UndoData^;
  UndoData^ := Data^;
  SetData(S);
  Modified := True;
end;

procedure InputLinePopup(AnOrigin: TPoint);
const
  CutCommands = [cmCut];
  ClearCommands = [cmClear];
  ExportCommands = [cmExport];
  SelectAllCommands = [cmCtrlKA];
var
  W1, W2: Word;
  SaveCommands: TCommandSet;
  S: String[15];
begin
  GetCommands(SaveCommands);
  if Modified then EnableCommands(UndoCommands)
  else DisableCommands(UndoCommands);
  if SelStart <> SelEnd then EnableCommands(CutCommands)
  else DisableCommands(CutCommands);
  if Data^ <> '' then EnableCommands(
    DeleteSelCommands + CopyCommands + ClearCommands + ExportCommands)
  else DisableCommands(DeleteSelCommands + CopyCommands + ClearCommands + ExportCommands);
  if ClipAreaSelected then EnableCommands(PasteCommands)
  else DisableCommands(PasteCommands);
  if (Data^ <> '') and ((SelStart <> 0) or (SelEnd <> Length(Data^))) then
    EnableCommands(SelectAllCommands)
  else DisableCommands(SelectAllCommands);
  if MultitaskerDetected then
  begin
    S := 'MS Windows';
    W1 := hcECopyToWinClip;
    W2 := hcEPasteFromWinClip;
  end
  else
  begin
    S := 'additional';
    W1 := hcECopyToAddClip;
    W2 := hcEPasteFromAddClip;
  end;
  ShowPopup(AnOrigin, NewMenu(
    NewItem('~U~ndo', 'Alt+Back', kbAltBack, cmUndo, hcEUndo,
    NewLine(
    NewItem('~D~elete', 'Del', kbDel, cmDeleteSel, hcEClear,
    NewItem('Cu~t~', 'Shift+Del', kbShiftDel, cmCut, hcECut,
    NewItem('~C~opy', 'Ctrl+Ins', kbCtrlIns, cmCopy, hcECopy,
    NewItem('~P~aste', 'Shift+Ins', kbShiftIns, cmPaste, hcEPaste,
    NewItem('C~l~ear', 'Ctrl+Del', kbCtrlDel, cmClear, hcEClear,
    NewLine(
    NewItem('Cop~y~ to ' + S + ' Clipboard', 'Ctrl+F12', kbCtrlF12, cmExport, W1,
    NewItem('Paste fr~o~m ' + S + ' Clipboard', 'Shift+F12', kbShiftF12, cmImport, W2,
    NewLine(
    NewItem('Select ~a~ll', 'Ctrl+A', kbNoKey, cmCtrlKA, hcESelectAll,
      nil))))))))))))));
  SetCommands(SaveCommands);
end;

begin
  if (Event.What = evKeyDown) and (Owner^.State and sfModal <> 0) and
     (Event.CharCode in WordStarChars) then
       ConvertWSKey(WordStarKeys and not
         (wsD + wsE + wsF + wsR + wsS + wsW), Event);
  TView.HandleEvent(Event);
  if State and sfSelected <> 0 then
    case Event.What of
      evMouseDown:
        if Event.Buttons = mbRightButton then
        begin
          Select;
          repeat until not MouseEvent(Event, evMouseDown);
          InputLinePopup(Event.Where);
          Event.What := evNothing;
        end
        else
        begin
          Delta := MouseDelta;
          if CanScroll(Delta) then
          begin
            repeat
              if CanScroll(Delta) then
              begin
                Inc(FirstPos, Delta);
                DrawView;
              end;
            until not MouseEvent(Event, evMouseAuto);
          end
          else if Event.Double then SelectAll(True)
          else
          begin
            Anchor := MousePos;
            repeat
              if Event.What = evMouseAuto then
              begin
                Delta := MouseDelta;
                if CanScroll(Delta) then Inc(FirstPos, Delta);
              end;
              CurPos := MousePos;
              if CurPos < Anchor then
              begin
                SelStart := CurPos;
                SelEnd := Anchor;
              end else
              begin
                SelStart := Anchor;
                SelEnd := CurPos;
              end;
              DrawView;
            until not MouseEvent(Event, evMouseMove + evMouseAuto);
          end;
          Event.What := evNothing;
        end;
      evKeyDown:
        begin
          case Event.KeyCode of
            kbLeft: GoLeft;
            kbRight: GoRight;
            kbHome:
              begin
                if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
                begin
                  if SelStart = SelEnd then SelEnd := CurPos
                  else if SelEnd = CurPos then SelEnd := SelStart;
                  SelStart := 0;
                end;
                CurPos := 0;
              end;
            kbEnd:
              begin
                if GetShiftState and (kbLeftShift + kbRightShift) <> 0 then
                begin
                  if SelStart = SelEnd then SelStart := CurPos
                  else if SelStart = CurPos then SelStart := SelEnd;
                  SelEnd := Length(Data^);
                end;
                CurPos := Length(Data^);
              end;
            kbCtrlLeft:
              if GetShiftState and (kbAltShift + kbCtrlShift) =
                kbAltShift + kbCtrlShift then
              begin
                while (CurPos > 0) and
                  not (Data^[CurPos] in WordDelims) do GoLeft;
                while (CurPos > 0) and
                  (Data^[CurPos] in WordDelims) do GoLeft;
              end
              else
              begin
                while (CurPos > 0) and
                  (Data^[CurPos] in WordDelims) do GoLeft;
                while (CurPos > 0) and
                  not (Data^[CurPos] in WordDelims) do GoLeft;
              end;
            kbCtrlRight:
              if GetShiftState and (kbAltShift + kbCtrlShift) =
                kbAltShift + kbCtrlShift then
              begin
                while (CurPos < Length(Data^)) and
                  (Data^[CurPos + 1] in WordDelims) do GoRight;
                while (CurPos < Length(Data^)) and
                  not (Data^[CurPos + 1] in WordDelims) do GoRight;
              end
              else
              begin
                while (CurPos < Length(Data^)) and
                  not (Data^[CurPos + 1] in WordDelims) do GoRight;
                while (CurPos < Length(Data^)) and
                  (Data^[CurPos + 1] in WordDelims) do GoRight;
              end;
            kbBack:
              if CurPos > 0 then
              begin
                OnModify;
                Delete(Data^, CurPos, 1);
                Dec(CurPos);
                if CurPos <= FirstPos then Dec(FirstPos, Size.X div 4 + 1);
              end;
            kbCtrlBack:
              begin
                I := CurPos;
                Event.KeyCode := kbCtrlLeft;
                HandleEvent(Event);
                if CurPos <> I then
                begin
                  OnModify;
                  Delete(Data^, CurPos + 1, I - CurPos);
                end;
              end;
            kbAltBack:
              begin
                SwapData;
                Exit;
              end;
            kbIns:
              SetState(sfCursorIns, State and sfCursorIns = 0);
            kbCtrlIns: if GetShiftState and kbAltShift = 0 then
              begin
                Copy;
                Event.What := evNothing;
                Exit;
              end;
            kbShiftIns:
              begin
                OnModify;
                Paste;
                Event.What := evNothing;
                Exit;
              end;
            kbDel:
              begin
                OnModify;
                if SelStart = SelEnd then
                  if CurPos < Length(Data^) then
                  begin
                    SelStart := CurPos;
                    SelEnd := CurPos + 1;
                  end;
                DeleteSelect;
              end;
            kbShiftDel:
              begin
                OnModify;
                Cut;
                Event.What := evNothing;
                Exit;
              end;
            kbCtrlDel:
              begin
                OnModify;
                Data^ := '';
                CurPos := 0;
              end;
            kbAltIns, kbAltColon: if Owner^.State and sfModal <> 0 then
              begin
                OnModify;
                InsertCurDir(Event.KeyCode <> kbAltColon);
                Event.What := evNothing;
                Exit;
              end;
{ added 05-14-03 to support Ctrl+Enter, Ctrl+J, Alt+Paren, Ctrl+[, Ctrl+] keystrokes }
            kbAltParen, kbCtrlEnter, $240A {^J }, $1A1B, $1B1D {Ctrl+[, Ctrl+]}:
              if Owner^.State and sfModal <> 0 then
              begin
                OnModify;
                InsertFMFocusedStr(Event.KeyCode);
                Event.What := evNothing;
                Exit;
              end;
            kbAltF10:
              begin
                MakeGlobal(Origin, Event.Where);
                InputLinePopup(Event.Where);
              end;
{ Added 2005.09.24 }
            kbAlt1..kbAlt0: ConvertChars(caXLAT);
          else if (State and sfFocused = 0) and
            (Event.CharCode <> #0) then CharPressed
          else
            case Event.CharCode of
              ^U: ConvertChars(caUpcase);
              ^L: ConvertChars(caLocase);
              ^E: ConvertChars(caLatin);
              ^R: ConvertChars(caRus);
              ^I: if Event.KeyCode <> kbTab then ConvertChars(caCaps)
                  else Exit;
              ^H: ConvertChars(caHex);
{ Added 2005.09.24 }
	      ^T: ConvertChars(caVolapyuk);
	      ^W: ConvertChars(caVolToRus);
	      ^B: ConvertChars(caUkrVolapyuk);
	      ^G: ConvertChars(caVolToUkr);
              ^S: ConvertChars(caShort);
	      ^N: ConvertChars(caLong);
	     '': ConvertChars(caSpaceToUnderline);
	     '': ConvertChars(caUnderlineToSpace);
              ^Y:
                begin
                  OnModify;
                  Data^ := '';
                  CurPos := 0;
                end;
              #1..#7, #10..#12, #14..#26, #28..#255: CharPressed;
              else Exit;
            end
          end;
          if (GetShiftState and (kbLeftShift + kbRightShift) = 0) or
             (Event.CharCode <> #0) then
          begin
            SelStart := 0;
            SelEnd := 0;
          end;
{ Added 04.08.08 to support InputLine AutoComplete }
          if Event.CharCode in [#32..#255] then AutoComplete;
          DrawView;
          Event.What := evNothing;
        end;
      evCommand:
        begin
          case Event.Command of
            cmDeleteSel:
              begin
                Pending.What := evKeyDown;
                Pending.KeyCode := kbDel;
              end;
            cmCopy:
              begin
                OnModify;
                Copy;
              end;
            cmPaste:
              begin
                OnModify;
                Paste;
              end;
            cmCut:
              begin
                OnModify;
                Cut;
              end;
            cmClear:
              begin
                OnModify;
                Data^ := '';
                FillChar(CurPos, SizeOf(Integer) * 4, 0);
                DrawView;
              end;
            cmUndo: SwapData;
            cmSelectAll, cmCtrlKA: SelectAll(True);
            cmExport:
              begin
                Pending.What := evKeyDown;
                Pending.KeyCode := kbCtrlF12;
              end;
            cmImport:
              begin
                Pending.What := evKeyDown;
                Pending.KeyCode := kbShiftF12;
              end;
            else Exit;
          end;
          Event.What := evNothing;
        end;
    end;
end;

procedure TInputLine.Paste;
var
  P: PView;
  PS: PString;
  S: String;
begin
  if Owner = nil then Exit;
  P := Owner;
  while P^.Owner <> nil do P := P^.Owner;
  PS := Message(P, evBroadcast, cmPaste, nil);
  if (PS = nil) or (PS^ = '') then Exit;
  if SelStart <> SelEnd then
  begin
    System.Delete(Data^, SelStart + 1, SelEnd - SelStart);
    CurPos := SelStart;
  end;
  S := PString(PS)^;
  if Length(Data^) + Length(S) > MaxLen then
    S[0] := Char(MaxLen - Length(Data^));
  System.Insert(S, Data^, CurPos + 1);
  if NewEditOptions and neoPasteGoesToEnd <> 0 then
  begin
    Inc(CurPos, Length(S));
    SelStart := 0;
    SelEnd := 0;
  end
  else
  begin
    SelStart := CurPos;
    SelEnd := SelStart + Length(S);
  end;
  DrawView;
end;

procedure TInputLine.SelectAll(Enable: Boolean);
begin
  if Enable then
  begin
    if MaxLen = 1 then CurPos := 0
    else CurPos := Length(Data^);
    FirstPos := 0;
  end;
  SelStart := 0;
  if Enable then SelEnd := Length(Data^)
  else SelEnd := 0;
  DrawView;
end;

procedure TInputLine.SetData(var Rec);
begin
  if History = nil then Move(Rec, Data^[0], DataSize) { Added 02.03.99 }
  else Data^ := PHistory(History)^.HistoryGetFunc(@Self, PString(@Rec)^);
  if Byte(Data^[0]) > MaxLen then Byte(Data^[0]) := MaxLen;
  SelectAll(True);
end;

procedure TInputLine.SetState(AState: Word; Enable: Boolean);
begin
  TView.SetState(AState, Enable);
  if (AState = sfSelected) or ((AState = sfActive) and
    (State and sfSelected <> 0)) then SelectAll(Enable);
end;

procedure TInputLine.Store(var S: TStream);
begin
  TView.Store(S);
  S.Write(MaxLen, SizeOf(Integer) * 5);
  S.WriteStr(Data);
end;

{ TButton }

constructor TButton.Init(var Bounds: TRect; const ATitle: TTitleStr;
  ACommand: Word; AFlags: Word);
begin
  TView.Init(Bounds);
  Options := Options or (ofSelectable + ofFirstClick +
    ofPreProcess + ofPostProcess);
  EventMask := EventMask or evBroadcast;
  if not CommandEnabled(ACommand) then State := State or sfDisabled;
  Flags := AFlags;
  if AFlags and bfDefault <> 0 then AmDefault := True
  else AmDefault := False;
  Title := NewStr(ATitle);
  Command := ACommand;
end;

constructor TButton.Load(var S: TStream);
begin
  TView.Load(S);
  Title := S.ReadStr;
  S.Read(Command, SizeOf(Word) + SizeOf(Byte) + SizeOf(Boolean));
  if not CommandEnabled(Command) then State := State or sfDisabled
  else State := State and not sfDisabled;
end;

destructor TButton.Done;
begin
  DisposeStr(Title);
  TView.Done;
end;

procedure TButton.Draw;
begin
  DrawState(False);
end;

procedure TButton.DrawState(Down: Boolean);
var
  Ch: Char;
  CButton, CShadow: Word;
  I, S, Y, T: Integer;
  B: TDrawBuffer;

procedure DrawTitle;
var
  L, SCOff: Integer;
begin
  if Flags and bfLeftJust <> 0 then L := 1 else
  begin
    L := (S - CStrLen(Title^) - 1) div 2;
    if L < 1 then L := 1;
  end;
  MoveCStr(B[I + L], Title^, CButton);
{ Removed 03.30.98 }
{
  if ShowMarkers and not Down then
  begin
    if State and sfSelected <> 0 then SCOff := 0 else
      if AmDefault then SCOff := 2 else SCOff := 4;
    Char(B[0]) := SpecialChars[SCOff];
    Char(B[S]) := SpecialChars[SCOff + 1];
  end;
}
end;

begin
  if State and sfDisabled <> 0 then CButton := GetColor($0404) else
  begin
    CButton := GetColor($0501);
    if State and sfActive <> 0 then
      if State and sfSelected <> 0 then
        if CStrLen(Title^) = 1 then CButton := GetColor($0303)
        else CButton := GetColor($0703)
      else if AmDefault then CButton := GetColor($0602);
  end;
  CShadow := GetColor(8);
  S := Size.X - 1;
  T := Size.Y div 2 - 1;
  for Y := 0 to Size.Y - 2 do
  begin
    MoveChar(B, ' ', Byte(CButton), Size.X);
    WordRec(B[0]).Hi := CShadow;
    if Down then
    begin
      WordRec(B[1]).Hi := CShadow;
      Ch := ' ';
      I := 2;
    end else
    begin
      WordRec(B[S]).Hi := Byte(CShadow);
      if ShowMarkers then Ch := ' ' else
      begin
        if Y = 0 then
          Char(B[S]) := '‹' else
          Char(B[S]) := '€';
        Ch := 'ﬂ';
      end;
      I := 1;
    end;
    if (Y = T) and (Title <> nil) then DrawTitle;
    if ShowMarkers and not Down then
    begin
      Char(B[1]) := '[';
      Char(B[S - 1]) := ']';
    end;
    { Added 03.30.98 to indicate current or default button }
    if (State and sfDisabled = 0) and (State and sfActive <> 0) and
       (CStrLen(Title^) > 1) then
      if (State and sfSelected <> 0) or AmDefault then
      begin
        Char(B[1 + Byte(Down)]) := '';
        Char(B[S - 1 + Byte(Down)]) := '';
      end;
    WriteLine(0, Y, Size.X, 1, B);
  end;
  MoveChar(B[0], ' ', Byte(CShadow), 2);
  MoveChar(B[2], Ch, Byte(CShadow), S - 1);
  WriteLine(0, Size.Y - 1, Size.X, 1, B);
end;

function TButton.GetPalette: PPalette;
const
  P: String[Length(CButton)] = CButton;
begin
  GetPalette := @P;
end;

procedure TButton.HandleEvent(var Event: TEvent);
var
  Down: Boolean;
  C: Char;
  Mouse: TPoint;
  ClickRect: TRect;
begin
  GetExtent(ClickRect);
  Inc(ClickRect.A.X);
  Dec(ClickRect.B.X);
  Dec(ClickRect.B.Y);
  if Event.What = evMouseDown then
  begin
    MakeLocal(Event.Where, Mouse);
    if not ClickRect.Contains(Mouse) then Event.What := evNothing;
  end;
{  TView.HandleEvent(Event);}
  case Event.What of
    evMouseDown:
      begin
        Inc(ClickRect.B.X);
        Down := False;
        repeat
          MakeLocal(Event.Where, Mouse);
          if Down <> ClickRect.Contains(Mouse) then
          begin
            Down := not Down;
            DrawState(Down);
          end;
        until not MouseEvent(Event, evMouseMove);
        if Down then
        begin
          Press;
          DrawState(False);
        end;
        Event.What := evNothing;
      end;
    evKeyDown:
      begin
        C := HotKey(Title^);
        if ((State and sfFocused <> 0) and (Event.CharCode = ' ')) or
           ((C <> #0) and
            ((Event.KeyCode = GetAltCode(C)) or
             ((Owner^.Phase = phPostProcess) and
              ((LatinChar(Event.CharCode) = C) or
               (InterChar(Event.CharCode) = C))))) then
        begin
          Press;
          Event.What := evNothing;
        end;
      end;
    evBroadcast:
      case Event.Command of
        cmDefault:
          if AmDefault and (State and sfDisabled = 0) then
          begin
            Press;
            Event.What := evNothing;
          end;
        cmGrabDefault, cmReleaseDefault:
          if Flags and bfDefault <> 0 then
          begin
            AmDefault := Event.Command = cmReleaseDefault;
            DrawView;
          end;
        cmCommandSetChanged:
          begin
            SetState(sfDisabled, not CommandEnabled(Command));
            DrawView;
          end;
      end;
  end;
end;

procedure TButton.MakeDefault(Enable: Boolean);
var
  C: Word;
begin
  if Flags and bfDefault = 0 then
  begin
    if Enable then C := cmGrabDefault else C := cmReleaseDefault;
    Message(Owner, evBroadcast, C, @Self);
    AmDefault := Enable;
    DrawView;
  end;
end;

procedure TButton.Press;
var
  E: TEvent;
begin
  Message(Owner, evBroadcast, cmRecordHistory, nil);
  if Flags and bfBroadcast <> 0 then
    Message(Owner, evBroadcast, Command, @Self) else
  begin
    E.What := evCommand;
    E.Command := Command;
    E.InfoPtr := @Self;
    PutEvent(E);
  end;
end;

procedure TButton.SetState(AState: Word; Enable: Boolean);
begin
  TView.SetState(AState, Enable);
  if AState and (sfSelected + sfActive) <> 0 then DrawView;
  if AState and sfFocused <> 0 then MakeDefault(Enable);
end;

procedure TButton.Store(var S: TStream);
begin
  TView.Store(S);
  S.WriteStr(Title);
  S.Write(Command, SizeOf(Word) + SizeOf(Byte) + SizeOf(Boolean));
end;

{ TCluster }

constructor TCluster.Init(var Bounds: TRect; AStrings: PSItem);
var
  I: Integer;
  P: PSItem;
begin
  TView.Init(Bounds);
  Options := Options or (ofSelectable + ofFirstClick + ofPreProcess +
    ofPostProcess);
  State := State or sfCursorVis;
  EnableMask := $FFFFFFFF;
  I := 0;
  P := AStrings;
  while P <> nil do
  begin
    Inc(I);
    P := P^.Next;
  end;
  Strings.Init(I,0);
  while AStrings <> nil do
  begin
    P := AStrings;
    Strings.AtInsert(Strings.Count, AStrings^.Value);
    AStrings := AStrings^.Next;
    Dispose(P);
  end;
  SetCursor(2,0);
end;

constructor TCluster.Load(var S: TStream);
begin
  TView.Load(S);
  S.Read(Value, SizeOf(Longint) * 2 + SizeOf(Integer));
  Strings.Load(S);
  SetButtonState(0, True);
end;

destructor TCluster.Done;
begin
  Strings.Done;
  TView.Done;
end;

function TCluster.ButtonState(Item: Integer): Boolean; assembler;
asm
        XOR     AL,AL
        MOV     CX,Item
        CMP     CX,31
        JA      @@3
        MOV     AX,1
        XOR     DX,DX
        JCXZ    @@2
@@1:    SHL     AX,1
        RCL     DX,1
        LOOP    @@1
@@2:    LES     DI,Self
        AND     AX,ES:[DI].TCluster.EnableMask.Word[0]
        AND     DX,ES:[DI].TCluster.EnableMask.Word[2]
        OR      AX,DX
        JZ      @@3
        MOV     AL,1
@@3:
end;

function TCluster.DataSize: Word;
begin
  DataSize := SizeOf(Word);
end;

procedure TCluster.DrawBox(const Icon: String; Marker: Char);
begin
  DrawMultiBox(Icon, ' ' + Marker);
end;

procedure TCluster.DrawMultiBox(const Icon, Marker: String);
var
  SCOff: Byte;
  I,J,Cur,Col: Integer;
  CNorm, CSel, CDis, Color: Word;
  B: TDrawBuffer;
begin
  CNorm := GetColor($0301);
  CSel := GetColor($0402);
  CDis := GetColor($0505);
  for I := 0 to Size.Y do
  begin
    MoveChar(B, ' ', Byte(CNorm), Size.X);
    for J := 0 to (Strings.Count - 1) div Size.Y + 1 do
    begin
      Cur := J * Size.Y + I;
      if Cur < Strings.Count then
      begin
        Col := Column(Cur);
        if (Col + CStrLen(PString(Strings.At(Cur))^) + 5 <
          Sizeof(TDrawBuffer) div SizeOf(Word)) and (Col < Size.X) then
        begin
          if not ButtonState(Cur) then
            Color := CDis
          else if (Cur = Sel) and (State and sfFocused <> 0) then
            Color := CSel
          else
            Color := CNorm;
          MoveChar(B[Col], ' ', Byte(Color), Size.X - Col);
          MoveStr(B[Col], Icon, Byte(Color));
          if ButtonState(Cur) then { Fixed 06.22.95 to draw disabled empty }
            Byte(B[Col+2]) := Byte(Marker[MultiMark(Cur) + 1]);
          MoveCStr(B[Col+5], PString(Strings.At(Cur))^, Color);
          if ShowMarkers and (State and sfFocused <> 0) and (Cur = Sel) then
          begin
            Char(B[Col]) := SpecialChars[0];
            Char(B[Column(Cur+Size.Y)-1]) := SpecialChars[1];
          end;
        end;
      end;
    end;
    WriteBuf(0, I, Size.X, 1, B);
  end;
  SetCursor(Column(Sel)+2,Row(Sel));
end;

procedure TCluster.GetData(var Rec);
begin
  Word(Rec) := Value;
end;

function TCluster.GetHelpCtx: Word;
begin
  if Owner^.State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else GetHelpCtx := HelpCtx;
{
  if HelpCtx = hcNoContext then GetHelpCtx := hcNoContext
  else GetHelpCtx := HelpCtx + Sel;
}
end;

function TCluster.GetPalette: PPalette;
const
  P: String[Length(CCluster)] = CCluster;
begin
  GetPalette := @P;
end;

procedure TCluster.HandleEvent(var Event: TEvent);
var
  C: Char;
  I, S: Integer;
  Mouse: TPoint;

procedure MoveSel;
begin
  if I <= Strings.Count then
  begin
    Sel := S;
    MovedTo(Sel);
    DrawView;
  end;
end;

begin
  TView.HandleEvent(Event);
  if Options and ofSelectable = 0 then Exit;
  if Event.What = evMouseDown then
  begin
    MakeLocal(Event.Where, Mouse);
    I := FindSel(Mouse);
    if I <> -1 then if ButtonState(I) then Sel := I;
    DrawView;
    repeat
      MakeLocal(Event.Where, Mouse);
      if FindSel(Mouse) = Sel then
        ShowCursor else
        HideCursor;
    until not MouseEvent(Event, evMouseMove); {Wait for mouse up}
    ShowCursor;
    MakeLocal(Event.Where, Mouse);
    if (FindSel(Mouse) = Sel) and ButtonState(Sel) then
    begin
      Press(Sel);
      DrawView;
    end;
    Event.What := evNothing;
  end else if Event.What = evKeyDown then
  begin
    S := Sel;
    case CtrlToArrow(Event.KeyCode) of
      kbUp:
        if State and sfFocused <> 0 then
        begin
          I := 0;
          repeat
            Inc(I);
            Dec(S);
            if S < 0 then S := Strings.Count - 1;
          until ButtonState(S) or (I > Strings.Count);
          MoveSel;
          Event.What := evNothing;
        end;
      kbDown:
        if State and sfFocused <> 0 then
        begin
          I := 0;
          repeat
            Inc(I);
            Inc(S);
            if S >= Strings.Count then S := 0;
          until ButtonState(S) or (I > Strings.Count);
          MoveSel;
          Event.What := evNothing;
        end;
      kbRight:
        if State and sfFocused <> 0 then
        begin
          I := 0;
          repeat
            Inc(I);
            Inc(S,Size.Y);
            if S >= Strings.Count then
            begin
              S := (S+1) mod Size.Y;
              if S >= Strings.Count then S := 0;
            end;
          until ButtonState(S) or (I > Strings.Count);
          MoveSel;
	  Event.What := evNothing;
	end;
      kbLeft:
	if State and sfFocused <> 0 then
	begin
	  I := 0;
	  repeat
	    Inc(I);
	    if S > 0 then
	    begin
	      Dec(S, Size.Y);
	      if S < 0 then
	      begin
		S := ((Strings.Count + Size.Y - 1) div Size.Y) *
		  Size.Y + S - 1;
		if S >= Strings.Count then S := Strings.Count - 1;
	      end;
	    end else S := Strings.Count - 1;
	  until ButtonState(S) or (I > Strings.Count);
	  MoveSel;
	  Event.What := evNothing;
	end;
{ Added 2006.03.13 }
      kbCtrlUp, kbCtrlDn:
	if (State and sfFocused <> 0) and
	   (Mark(Sel) = (Event.KeyCode = kbCtrlDn)) then
	begin
	  Press(Sel);
	  DrawView;
	  Event.What := evNothing;
	end;
    else
      begin
	for I := 0 to Strings.Count - 1 do
	begin
          C := HotKey(PString(Strings.At(I))^);
          if (C <> #0) and
             ((Event.KeyCode = GetAltCode(C)) or
              ((Owner^.Phase = phPostProcess) or
               (State and sfFocused <> 0)) and
              ((LatinChar(Event.CharCode) = C) or
               (InterChar(Event.CharCode) = C))) then
          begin
            if ButtonState(I) then
            begin
              if Focus then
              begin
                Sel := I;
                MovedTo(Sel);
                Press(Sel);
                DrawView;
              end;
              Event.What := evNothing;
            end;
            Exit;
          end;
        end;
        if (Event.CharCode = ' ') and (State and sfFocused <> 0)
	  and ButtonState(Sel) then
        begin
          Press(Sel);
          DrawView;
          Event.What := evNothing;
        end;
      end;
    end;
  end;
end;

procedure TCluster.SetButtonState(AMask: Longint; Enable: Boolean); assembler;
asm
        LES     DI,Self
        MOV     AX,AMask.Word[0]
        MOV     DX,AMask.Word[2]
        TEST    Enable,0FFH
        JNZ     @@1
        NOT     AX
        NOT     DX
        AND     ES:[DI].TCluster.EnableMask.Word[0],AX
        AND     ES:[DI].TCluster.EnableMask.Word[2],DX
        JMP     @@2
@@1:    OR      ES:[DI].TCluster.EnableMask.Word[0],AX
        OR      ES:[DI].TCluster.EnableMask.Word[2],DX
@@2:    MOV     CX,ES:[DI].Strings.TCollection.Count
        CMP     CX,32
        JA      @@6
        MOV     BX,ES:[DI].TCluster.Options
        AND     BX,not ofSelectable
        MOV     AX,ES:[DI].TCluster.EnableMask.Word[0]
        MOV     DX,ES:[DI].TCluster.EnableMask.Word[2]
@@3:    SHR     DX,1
        RCR     AX,1
        JC      @@4
        LOOP    @@3
        JMP     @@5
@@4:    OR      BX,ofSelectable
@@5:    MOV     ES:[DI].TCluster.Options,BX
@@6:
end;

procedure TCluster.SetData(var Rec);
begin
{ Added 02.03.99 }
  if PreserveBits <> 0 then Value :=
    (Value and PreserveBits) or (Word(Rec) and not PreserveBits)
  else Value := Word(Rec);
  DrawView;
end;

procedure TCluster.SetState(AState: Word; Enable: Boolean);
begin
  TView.SetState(AState, Enable);
  if AState = sfFocused then DrawView;
end;

function TCluster.Mark(Item: Integer): Boolean;
begin
  Mark := False;
end;

function TCluster.MultiMark(Item: Integer): Byte;
begin
  MultiMark := Byte(Mark(Item) = True);
end;

procedure TCluster.MovedTo(Item: Integer);
begin
end;

procedure TCluster.Press(Item: Integer);
begin
end;

procedure TCluster.Store(var S: TStream);
begin
  TView.Store(S);
  S.Write(Value, SizeOf(Longint) * 2 + SizeOf(Integer));
  Strings.Store(S);
end;

function TCluster.Column(Item: Integer): Integer;
var
  I, Col, Width, L: Integer;
begin
  if Item < Size.Y then Column := 0
  else
  begin
    Width := 0;
    Col := -6;
    for I := 0 to Item do
    begin
      if I mod Size.Y = 0 then
      begin
        Inc(Col, Width + 6);
        Width := 0;
      end;
      if I < Strings.Count then
        L := CStrLen(PString(Strings.At(I))^);
      if L > Width then Width := L;
    end;
    Column := Col;
  end;
end;

function TCluster.FindSel(P: TPoint): Integer;
var
  I, S: Integer;
  R: TRect;
begin
  GetExtent(R);
  if not R.Contains(P) then FindSel := -1
  else
  begin
    I := 0;
    while P.X >= Column(I+Size.Y) do
      Inc(I, Size.Y);
    S := I + P.Y;
    if S >= Strings.Count then
      FindSel := -1 else
      FindSel := S;
  end;
end;

function TCluster.Row(Item: Integer): Integer;
begin
  Row := Item mod Size.Y;
end;

{ TRadioButtons }

procedure TRadioButtons.Draw;
const
  Button = ' ( ) ';
begin
  DrawMultiBox(Button, #32#7);
end;

function TRadioButtons.Mark(Item: Integer): Boolean;
begin
  Mark := Item = Value;
end;

procedure TRadioButtons.Press(Item: Integer);
begin
  Value := Item;
end;

procedure TRadioButtons.MovedTo(Item: Integer);
begin
  Value := Item;
end;

procedure TRadioButtons.SetData(var Rec);
begin
  TCluster.SetData(Rec);
  Sel := Integer(Value);
end;

{ TCheckBoxes }

procedure TCheckBoxes.Draw;
const
  Button = ' [ ] ';
begin
  DrawMultiBox(Button, ' X');
end;

function TCheckBoxes.Mark(Item: Integer): Boolean;
begin
  Mark := Value and (Longint(1) shl Item) <> 0;
end;

procedure TCheckBoxes.Press(Item: Integer);
begin
  Value := Value xor (Longint(1) shl Item);
end;

{ TMultiCheckBoxes }

constructor TMultiCheckBoxes.Init(var Bounds: TRect; AStrings: PSItem;
  ASelRange: Byte; AFlags: Word; const AStates: String);
begin
  Inherited Init(Bounds, AStrings);
  SelRange := ASelRange;
  Flags := AFlags;
  States := NewStr(AStates);
end;

constructor TMultiCheckBoxes.Load(var S: TStream);
begin
  TCluster.Load(S);
  S.Read(SelRange, SizeOf(Byte));
  S.Read(Flags, SizeOf(Word));
  States := S.ReadStr;
end;

destructor TMultiCheckBoxes.Done;
begin
  DisposeStr(States);
  TCluster.Done;
end;

procedure TMultiCheckBoxes.Draw;
const
  Button = ' [ ] ';
begin
  DrawMultiBox(Button, States^);
end;

function TMultiCheckBoxes.DataSize: Word;
begin
  DataSize := SizeOf(Longint);
end;

function TMultiCheckBoxes.MultiMark(Item: Integer): Byte;
begin
  MultiMark := (Value shr (Word(Item) * WordRec(Flags).Hi))
    and WordRec(Flags).Lo;
end;

procedure TMultiCheckBoxes.GetData(var Rec);
begin
  Longint(Rec) := Value;
end;

procedure TMultiCheckBoxes.Press(Item: Integer);
var
  CurState: ShortInt;
begin
  CurState := (Value shr (Word(Item) * WordRec(Flags).Hi))
    and WordRec(Flags).Lo;
  Dec(CurState);
  if (CurState >= SelRange) or (CurState < 0) then
    CurState := SelRange - 1;
  Value := (Value and not (LongInt(WordRec(Flags).Lo)
    shl (Word(Item) * WordRec(Flags).Hi))) or
    (LongInt(CurState) shl (Word(Item) * WordRec(Flags).Hi));
end;

procedure TMultiCheckBoxes.SetData(var Rec);
begin
{ Added 02.03.99 }
  if PreserveBits <> 0 then Value :=
    (Value and PreserveBits) or (Longint(Rec) and not PreserveBits)
  else Value := Longint(Rec);
  DrawView;
end;

procedure TMultiCheckBoxes.Store(var S: TStream);
begin
  TCluster.Store(S);
  S.Write(SelRange, SizeOf(Byte));
  S.Write(Flags, SizeOf(Word));
  S.WriteStr(States);
end;

{ TListViewer }

constructor TListViewer.Init(var Bounds: TRect; ANumCols: Word;
  AHScrollBar, AVScrollBar: PScrollBar);
var
  ArStep, PgStep: Integer;
begin
  TView.Init(Bounds);
  Options := Options or (ofFirstClick + ofSelectable);
  EventMask := EventMask or evBroadcast;
  NumCols := ANumCols;
  if AVScrollBar <> nil then
  begin
    if NumCols = 1 then
    begin
      PgStep := Size.Y -1;
      ArStep := 1;
    end else
    begin
      PgStep := Size.Y * NumCols;
      ArStep := Size.Y;
    end;
    AVScrollBar^.SetStep(PgStep, ArStep);
  end;
  if AHScrollBar <> nil then AHScrollBar^.SetStep(Size.X div NumCols, 1);
  HScrollBar := AHScrollBar;
  VScrollBar := AVScrollBar;
end;

constructor TListViewer.Load(var S: TStream);
begin
  TView.Load(S);
  GetPeerViewPtr(S, HScrollBar);
  GetPeerViewPtr(S, VScrollBar);
  S.Read(NumCols, SizeOf(Word) * 4);
end;

procedure TListViewer.ChangeBounds(var Bounds: TRect);
begin
  TView.ChangeBounds(Bounds);
  if HScrollBar <> nil then
    HScrollBar^.SetStep(Size.X div NumCols, HScrollBar^.ArStep);
  if VScrollBar <> nil then
    VScrollBar^.SetStep(Size.Y, VScrollBar^.ArStep);
end;

procedure TListViewer.CopyText;
var
  S: String;
begin
  S := GetCopyText(Focused, Size.X);
  if S <> '' then Message(Application, evBroadcast, cmCopy, @S);
end;

procedure TListViewer.Draw;
var
  I, J, Item: Integer;
  NormalColor, SelectedColor, FocusedColor, Color: Word;
  ColWidth, CurCol, Indent: Integer;
  B: TDrawBuffer;
  SCOff: Byte;
begin
  if State and (sfSelected + sfActive) = (sfSelected + sfActive) then
  begin
    NormalColor := GetColor(1);
    FocusedColor := GetColor(3);
    SelectedColor := GetColor(4);
  end else
  begin
    NormalColor := GetColor(2);
    SelectedColor := GetColor(4);
  end;
  if HScrollBar <> nil then Indent := HScrollBar^.Value + 1
  else Indent := 0;
  ColWidth := Size.X div NumCols + 1;
  for I := 0 to Size.Y - 1 do
  begin
    for J := 0 to NumCols-1 do
    begin
      Item := J*Size.Y + I + TopItem;
      CurCol := J*ColWidth;
      if (State and (sfSelected + sfActive) = (sfSelected + sfActive)) and
        (Focused = Item) and (Range > 0) then
      begin
        Color := FocusedColor;
        SetCursor(CurCol+1,I);
        SCOff := 0;
      end
      else if (Item < Range) and IsSelected(Item) then
      begin
        Color := SelectedColor;
        SCOff := 2;
      end
      else
      begin
        Color := NormalColor;
        SCOff := 4;
      end;
      MoveChar(B[CurCol], ' ', Color, ColWidth);
      if Item < Range then
      begin
        MoveStr(B[CurCol+1],
          Copy(GetText(Item, ColWidth + Indent), Indent, ColWidth), Color);
        if ShowMarkers then
        begin
          Char(B[CurCol]) := SpecialChars[SCOff];
          Char(B[CurCol+ColWidth-2]) := SpecialChars[SCOff+1];
        end;
      end;
      MoveChar(B[CurCol+ColWidth-1], #179, GetColor(5), 1);
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure TListViewer.FocusItem(Item: Integer);
begin
  Focused := Item;
  if VScrollBar <> nil then VScrollBar^.SetValue(Item);
  if Item < TopItem then
    if NumCols = 1 then TopItem := Item
    else TopItem := Item - Item mod Size.Y
  else if Item >= TopItem + (Size.Y * NumCols) then
    if NumCols = 1 then TopItem := Item - Size.Y + 1
    else TopItem := Item - Item mod Size.Y - (Size.Y * (NumCols - 1));
end;

procedure TListViewer.FocusItemNum(Item: Integer);
var
  SaveMask: Word;
begin
  if Item < 0 then Item := 0
  else if (Item >= Range) and (Range > 0) then Item := Range - 1;
  if Range <> 0 then
  begin { Fixed 11.10.93 }
    SaveMask := EventMask;
    EventMask := EventMask and not evBroadcast;
    FocusItem(Item);
    EventMask := SaveMask;
  end;
  DrawView;
end;

function TListViewer.GetPalette: PPalette;
const
  P: String[Length(CListViewer)] = CListViewer;
begin
  GetPalette := @P;
end;

function TListViewer.GetCopyText(Item: Integer; MaxLen: Integer): String;
begin
  GetCopyText := GetText(Item, MaxLen);
end;

function TListViewer.GetText(Item: Integer; MaxLen: Integer): String;
begin
  Abstract;
end;

function TListViewer.IsSelected(Item: Integer): Boolean;
begin
  IsSelected := Item = Focused;
end;

procedure TListViewer.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  ColWidth: Word;
  OldItem, NewItem: Integer;
  S: String;
begin
  if Event.What = evKeyDown then
    if (Event.KeyCode = kbCtrlHome) or (Event.KeyCode = kbCtrlEnd) or
       (Event.KeyCode = kbCtrlPgUp) or (Event.KeyCode = kbCtrlPgDn) or
       (Event.CharCode in WordStarChars) then
      ConvertWSKey(WordStarKeys, Event);
  TView.HandleEvent(Event);
  if Event.What = evMouseDown then
  begin
    ColWidth := Size.X div NumCols + 1;
    OldItem := Focused;
    MakeLocal(Event.Where, Mouse);
    if MouseInView(Event.Where) then
      NewItem := Mouse.Y + (Size.Y * (Mouse.X div ColWidth)) + TopItem
    else NewItem := OldItem;
    repeat
      if NewItem <> OldItem then FocusItemNum(NewItem);
      OldItem := NewItem;
      MakeLocal(Event.Where, Mouse);
      if MouseInView(Event.Where) then
        NewItem := Mouse.Y + (Size.Y * (Mouse.X div ColWidth)) + TopItem
      else
      begin
        if NumCols = 1 then
        begin
          if Event.What = evMouseAuto then
          begin
            if Mouse.Y < 0 then NewItem := Focused-1
            else if Mouse.Y >= Size.Y then NewItem := Focused+1;
          end;
        end
        else
        begin
          if Event.What = evMouseAuto then
          begin
            if Mouse.X < 0 then NewItem := Focused-Size.Y
            else if Mouse.X >= Size.X then NewItem := Focused+Size.Y
            else if Mouse.Y < 0 then
              NewItem := Focused - Focused mod Size.Y
            else if Mouse.Y > Size.Y then
              NewItem := Focused - Focused mod Size.Y + Size.Y - 1;
          end
        end;
      end;
    until not MouseEvent(Event, evMouseMove + evMouseAuto);
    FocusItemNum(NewItem);
    if Event.Double and (Range > Focused) then SelectItem(Focused);
    Event.What := evNothing;
  end
  else if Event.What = evKeyDown then
  begin
    if (Event.CharCode = ' ') and (Focused < Range) then
    begin
      SelectItem(Focused);
      NewItem := Focused;
    end
    else case CtrlToArrow(Event.KeyCode) of
      kbUp: NewItem := Focused - 1;
      kbDown: NewItem := Focused + 1;
      kbRight: if NumCols > 1 then NewItem := Focused + Size.Y else Exit;
      kbLeft: if NumCols > 1 then NewItem := Focused - Size.Y else Exit;
      kbPgDn: NewItem := Focused + Size.Y * NumCols;
      kbPgUp: NewItem := Focused - Size.Y * NumCols;
      kbCtrlHome: NewItem := TopItem;
      kbCtrlEnd: NewItem := TopItem + (Size.Y * NumCols) - 1;
      kbCtrlPgDn: NewItem := Range - 1;
      kbCtrlPgUp: NewItem := 0;
      kbCtrlIns: { Added 08.03.95 }
        begin
          CopyText;
          Event.What := evNothing;
          Exit;
        end;
      kbHome: { Added 07.15.97 }
        if HScrollBar = nil then NewItem := 0 else Exit;
      kbEnd: { Added 07.15.97 }
        if HScrollBar = nil then NewItem := Range - 1
        else
        begin
          S := GetText(Focused, 255);
          while S[Length(S)] = ' ' do Dec(S[0]);
          if (Length(S) > Size.X - 2) or
             (Length(S) <= HScrollBar^.Value) then
            HScrollBar^.SetValue(Length(S) - (Size.X - 2));
          Event.What := evNothing;
          Exit;
        end;
    else
      Exit;
    end;
    FocusItemNum(NewItem);
    Event.What := evNothing;
  end else if (Event.What = evCommand) and (Event.Command = cmCopy) then
  begin  { Added 08.29.96 }
    CopyText;
    Event.What := evNothing;
  end else if Event.What = evBroadcast then
    if Options and ofSelectable <> 0 then
      if (Event.Command = cmScrollBarClicked) and
         ((Event.InfoPtr = HScrollBar) or
          (Event.InfoPtr = VScrollBar)) then Select
      else if (Event.Command = cmScrollBarChanged) then
      begin
        if (VScrollBar = Event.InfoPtr) then
          FocusItemNum(VScrollBar^.Value)
        else if (HScrollBar = Event.InfoPtr) then DrawView;
      end;
end;

procedure TListViewer.SelectItem(Item: Integer);
begin
  Message(Owner, evBroadcast, cmListItemSelected, @Self);
end;

procedure TListViewer.SetRange(ARange: Integer);
begin
  Range := ARange;
  if VScrollBar <> nil then
  begin
    if Focused > ARange then Focused := {0} ARange; { Fixed 12.08.94 }
    VScrollbar^.SetParams(Focused, 0, ARange-1, VScrollBar^.PgStep,
      VScrollBar^.ArStep);
  end;
end;

procedure TListViewer.SetState(AState: Word; Enable: Boolean);

procedure ShowSBar(SBar: PScrollBar);
begin
  if (SBar <> nil) then
    if GetState(sfActive) and GetState(sfVisible) then SBar^.Show
    else SBar^.Hide;
end;

begin
  TView.SetState(AState, Enable);
  if (State and sfExposed <> 0) and
     (AState and (sfSelected + sfActive + sfVisible) <> 0) then
  begin
    ShowSBar(HScrollBar);
    ShowSBar(VScrollBar);
    if Enable and (State and sfExposed <> 0) then
      FocusItemNum(Focused)
    else DrawView;
  end;
end;

procedure TListViewer.Store(var S: TStream);
begin
  TView.Store(S);
  PutPeerViewPtr(S, HScrollBar);
  PutPeerViewPtr(S, VScrollBar);
  S.Write(NumCols, SizeOf(Word) * 4);
end;

{ TListBox }

type
  TListBoxRec = record
    List: PCollection;
    Selection: Word;
  end;

constructor TListBox.Init(var Bounds: TRect; ANumCols: Word;
  AScrollBar: PScrollBar);
begin
  TListViewer.Init(Bounds, ANumCols, nil, AScrollBar);
  List := nil;
  SetRange(0);
end;

constructor TListBox.Load(var S: TStream);
begin
  TListViewer.Load(S);
  List := PCollection(S.Get);
end;

function TListBox.DataSize: Word;
begin
  DataSize := SizeOf(TListBoxRec);
end;

procedure TListBox.GetData(var Rec);
begin
  TListBoxRec(Rec).List := List;
  TListBoxRec(Rec).Selection := Focused;
end;

function TListBox.GetText(Item: Integer; MaxLen: Integer): String;
begin
  if List <> nil then GetText := PString(List^.At(Item))^
  else GetText := '';
end;

procedure TListBox.NewList(AList: PCollection);
begin
  if List <> nil then Dispose(List, Done);
  List := AList;
  if AList <> nil then SetRange(AList^.Count)
  else SetRange(0);
  FocusItem(0);
  DrawView;
end;

procedure TListBox.SetData(var Rec);
begin
  NewList(TListBoxRec(Rec).List);
  FocusItem(TListBoxRec(Rec).Selection);
  DrawView;
end;

procedure TListBox.Store(var S: TStream);
begin
  TListViewer.Store(S);
  S.Put(List);
end;

{ TStaticText }

constructor TStaticText.Init(var Bounds: TRect; const AText: String);
begin
  TView.Init(Bounds);
  Text := NewStr(AText);
end;

constructor TStaticText.Load(var S: TStream);
begin
  TView.Load(S);
  Text := S.ReadStr;
end;

destructor TStaticText.Done;
begin
  DisposeStr(Text);
  TView.Done;
end;

procedure TStaticText.Draw;
var
  Color: Byte;
  Center: Boolean;
  I, J, L, P, Y: Integer;
  B: TDrawBuffer;
  S: String;
begin
  Color := GetColor(1);
  GetText(S);
  L := Length(S);
  P := 1;
  Y := 0;
  Center := False;
  while Y < Size.Y do
  begin
    MoveChar(B, ' ', Color, Size.X);
    if P <= L then
    begin
      if S[P] = #3 then
      begin
        Center := True;
        Inc(P);
      end;
      I := P;
      repeat
        J := P;
        while (P <= L) and (S[P] = ' ') do Inc(P);
        while (P <= L) and (S[P] <> ' ') and (S[P] <> #13) do Inc(P);
      until (P > L) or (P >= I + Size.X) or (S[P] = #13);
      if P > I + Size.X then
        if J > I then P := J else P := I + Size.X;
      if Center then J := (Size.X - P + I) div 2 else J := 0;
      MoveBuf(B[J], S[I], Color, P - I);
      while (P <= L) and (S[P] = ' ') do Inc(P);
      if (P <= L) and (S[P] = #13) then
      begin
        Center := False;
        Inc(P);
        if (P <= L) and (S[P] = #10) then Inc(P);
      end;
    end;
    WriteLine(0, Y, Size.X, 1, B);
    Inc(Y);
  end;
end;

function TStaticText.GetPalette: PPalette;
const
  P: String[Length(CStaticText)] = CStaticText;
begin
  GetPalette := @P;
end;

procedure TStaticText.GetText(var S: String);
begin
  if Text <> nil then S := Text^
  else S := '';
end;

procedure TStaticText.Store(var S: TStream);
begin
  TView.Store(S);
  S.WriteStr(Text);
end;

{ TParamText }

constructor TParamText.Init(var Bounds: TRect; const AText: String;
  AParamCount: Integer);
begin
  TStaticText.Init(Bounds, AText);
  ParamCount := AParamCount;
end;

constructor TParamText.Load(var S: TStream);
begin
  TStaticText.Load(S);
  S.Read(ParamCount, SizeOf(Integer));
end;

function TParamText.DataSize: Word;
begin
  DataSize := ParamCount * SizeOf(Longint);
end;

procedure TParamText.GetText(var S: String);
begin
  if Text <> nil then FormatStr(S, Text^, ParamList^)
  else S := '';
end;

procedure TParamText.SetData(var Rec);
begin
  ParamList := @Rec;
end;

procedure TParamText.Store(var S: TStream);
begin
  TStaticText.Store(S);
  S.Write(ParamCount, SizeOf(Integer));
end;

{ TLabel }

constructor TLabel.Init(var Bounds: TRect; const AText: String; ALink: PView);
begin
  TStaticText.Init(Bounds, AText);
  Link := ALink;
  Options := Options or (ofPreProcess + ofPostProcess);
  EventMask := EventMask or evBroadcast;
end;

constructor TLabel.Load(var S: TStream);
begin
  TStaticText.Load(S);
  GetPeerViewPtr(S, Link);
end;

procedure TLabel.Draw;
var
  SCOff: Byte;
  Color: Word;
  B: TDrawBuffer;
begin
  if Light then
  begin
    Color := GetColor($0402);
    SCOff := 0;
  end
  else
  begin
    Color := GetColor($0301);
    SCOff := 4;
  end;
  MoveChar(B[0], ' ', Byte(Color), Size.X);
  if Text <> nil then MoveCStr(B[1], Text^, Color);
  if ShowMarkers then Char(B[0]) := SpecialChars[SCOff];
  WriteLine(0, 0, Size.X, 1, B);
end;

function TLabel.GetPalette: PPalette;
const
  P: String[Length(CLabel)] = CLabel;
begin
  GetPalette := @P;
end;

procedure TLabel.HandleEvent(var Event: TEvent);
var
  C: Char;
begin
  TStaticText.HandleEvent(Event);
  if Event.What = evMouseDown then
  begin
    if Link <> nil then Link^.Select;
    Event.What := evNothing;
  end
  else if Event.What = evKeyDown then
  begin
    C := HotKey(Text^);
    if (C <> #0) and
       ((Event.KeyCode = GetAltCode(C)) or
        ((Owner^.Phase = phPostProcess) and
         ((LatinChar(Event.CharCode) = C) or
          (InterChar(Event.CharCode) = C)))) then
    begin
      if Link <> nil then Link^.Select;
      Event.What := evNothing;
    end;
  end
  else if Event.What = evBroadcast then
    if (Event.Command = cmReceivedFocus) or
       (Event.Command = cmReleasedFocus) then
    begin
      Light := Link^.State and sfFocused <> 0;
      DrawView;
    end;
end;

procedure TLabel.Store(var S: TStream);
begin
  TStaticText.Store(S);
  PutPeerViewPtr(S, Link);
end;

{ THistoryViewer }

constructor THistoryViewer.Init(var Bounds: TRect; AHScrollBar,
  AVScrollBar: PScrollBar; AHistoryId: Word);
begin
  TListViewer.Init(Bounds, 1, AHScrollBar, AVScrollBar);
  GrowMode := gfGrowHiX + gfGrowHiY;
  HistoryId := AHistoryId;
  IncrPos := 1;
{ Added 2006.01.09 }
  NormalId := HistoryId < 200;
  SetRange(HistoryCount(AHistoryId));
  if (Range > 1) and not LastWasEmpty then FocusItem(1);
  HScrollBar^.SetRange(0, HistoryWidth(HistoryId) - Size.X +
    3 * Byte(NormalId));
end;

procedure THistoryViewer.ChangeBounds(var Bounds: TRect);
begin
  TListViewer.ChangeBounds(Bounds);
  SetRange(Range);
  HScrollBar^.SetRange(0, HistoryWidth(HistoryId) - Size.X +
    3 * Byte(NormalId));
end;

procedure THistoryViewer.Draw;
begin
  TListViewer.Draw;
  SetCursor(IncrPos + 2 * Byte(NormalId) - HScrollBar^.Value, Cursor.Y);
end;

procedure THistoryViewer.FocusItem(Item: Integer);
begin
  HideCursor;
  IncrPos := 1;
  TListViewer.FocusItem(Item);
end;

function THistoryViewer.GetPalette: PPalette;
const
  P: String[Length(CHistoryViewer)] = CHistoryViewer;
begin
  GetPalette := @P;
end;

function THistoryViewer.GetCopyText(Item: Integer; MaxLen: Integer): String;
var
  P: PHistoryRec;
begin
  P := HistoryRec(HistoryId, Item);
  if P = nil then GetCopyText := ''
  else GetCopyText := P^.StrPtr^;
end;

function THistoryViewer.GetText(Item: Integer; MaxLen: Integer): String;
var
  C: Char;
  P: PHistoryRec;
  S: String;
begin
  P := HistoryRec(HistoryId, Item);
  if P = nil then GetText := ''
  else
  begin
    if P^.StrPtr = nil then S := ''
    else S := P^.StrPtr^;
    if not NormalId then GetText := S
    else
    begin
      case Byte(P^.Lock) of
	0: C := ' ';
	1: C := '˚';
	else C := Char(P^.Lock);
      end;
      GetText := Concat(C, ' ', S);
    end;
  end;
end;

procedure THistoryViewer.HandleEvent(var Event: TEvent);

procedure FindMatch;
var
  C: Char;
  Offset, CurOfs: Byte;
  Index: Integer;
  SearchStr, S: String;
begin
  C := Upcase(Event.CharCode);
  HistoryStrProc(HistoryId, Focused, SearchStr, Offset);
  if IncrPos < Offset then CurOfs := 0
  else CurOfs := IncrPos - Offset;
  SearchStr[0] := Char(CurOfs);
  Index := 0;
  if C = ^L then Index := Focused + 1
  else if C = #8 then
  begin
    if IncrPos <= Offset + 1 then
    begin
      FocusItem(Focused);
      if HScrollBar <> nil then HScrollBar^.SetValue(0);
      Exit;
    end;
    Dec(SearchStr[0]);
  end
  else
  begin
    Inc(SearchStr[0]);
    SearchStr[Length(SearchStr)] := C;
  end;
  if SearchStr = '' then Exit;
  while Index < Range do
  begin
    HistoryStrProc(HistoryId, Index, S, Offset);
    if Pos(SearchStr, S) = 1 then
    begin
      Inc(Offset, CurOfs);
      if C = #8 then Dec(Offset)
      else if C <> ^L then Inc(Offset);
      FocusItem(Index);
      IncrPos := Offset;
      DrawView;
      ShowCursor;
      if HScrollBar <> nil then
        if Cursor.X < 1 then
          HScrollBar^.SetValue(HScrollBar^.Value + Cursor.X - 1)
        else if Cursor.X >= Size.X then
          HScrollBar^.SetValue(HScrollBar^.Value + Cursor.X - Size.X + 1);
      Break;
    end;
    Inc(Index);
  end;
end;

function FocusLockChar: Boolean;
var
  Index: Integer;
begin
  Index := HistoryLockIndex(HistoryId, Byte(Event.CharCode));
  if Index <> -1 then
  begin
    FocusItem(Index);
    FocusLockChar := True;
  end
  else FocusLockChar := False;
end;

procedure FocusMarked(Prev: Boolean);
var
  Index: Integer;
  P: PHistoryRec;
begin
  Index := Focused;
  repeat
    if Prev then Dec(Index) else Inc(Index);
    P := HistoryRec(HistoryId, Index);
    if P = nil then Exit;
    if P^.Lock then
    begin
      FocusItem(Index);
      DrawView;
      Exit;
    end;
  until False;
end;

var
  B: Byte;
  I: Integer;
  R: PHistoryRec;
begin
  if (Range <> 0) and (Event.What = evKeyDown) and
     (Event.CharCode in ['0'..'9']) and FocusLockChar then
  begin { Added 10.23.95 to support selection by number }
    Event.KeyCode := kbEnter;
    HandleEvent(Event);
  end else if (Range <> 0) and (Event.What = evKeyDown) and
     (Event.CharCode in [^L, #8, #32..#255]) then
  begin  { Added 08.16.95 to support incremental search }
    FindMatch;
    Event.What := evNothing;
  end;
  if ((Event.What = evMouseDown) and (Event.Double)) or
     ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) then
  begin
    EndModal(cmOk);
    Event.What := evNothing;
  end else if ((Event.What = evKeyDown) and (Event.KeyCode = kbEsc)) or
    ((Event.What = evCommand) and (Event.Command = cmCancel)) then
  begin
    EndModal(cmCancel);
    Event.What := evNothing;
  end else if (Event.What = evKeyDown) and (Event.KeyCode = kbDel) then
  begin
    Event.What := evNothing;
    R := HistoryRec(HistoryID, Focused);
    if (R = nil) or
       (R^.Lock and (ConfirmOptions and coDeleteItem <> 0) and (MessageBox(
         ^C'This history item has been marked as ''locked''. Delete still ?',
         nil, mfConfirmation + mfOkCancel) <> cmOk)) then Exit;
    HistoryDelete(HistoryID, Focused);
    SetRange(HistoryCount(HistoryId));
    HScrollBar^.SetRange(0, HistoryWidth(HistoryId) - Size.X +
      3 * Byte(NormalId));
    FocusItem(Focused);
    DrawView;
  end else if (Event.What = evKeyDown) and
    ((Event.KeyCode = kbCtrlUp) or (Event.KeyCode = kbCtrlDn)) then
  begin
    FocusMarked(Event.KeyCode = kbCtrlUp);
    Event.What := evNothing;
  end else if (Event.What = evKeyDown) and
    ((Event.KeyCode = $1A1B) or (Event.KeyCode = $1B1D)) then
  begin {Added 10.20.97 to re-sort history list (Ctrl+[, Ctrl+])}
    R := HistoryRec(HistoryID, Focused);
    if Event.KeyCode = $1A1B then B := hsLockedFirst
    else B := hsLockedLast;
    HistorySort(HistoryID, B);
    HistoryList^.IndexMode := hlExact + hlRelat;
    I := HistoryIndex(HistoryID, R^.StrPtr^);
    HistoryList^.IndexMode := 0;
    FocusItem(I);
    DrawView;
    Event.What := evNothing;
  end
  else if ((Event.What = evMouseDown) and
    (Event.Buttons = mbRightButton)) or
    ((Event.What = evKeyDown) and (Event.KeyCode = kbIns)) then
  begin
    if Event.What = evMouseDown then TListViewer.HandleEvent(Event);
    HistoryToggleLock(HistoryID, Focused);
    if Focused < Range - 1 then FocusItem(Focused + 1);
    DrawView;
    Event.What := evNothing;
  end else if (Range <> 0) and (Event.What = evKeyDown) and
    (GetAltChar(Event.KeyCode) in ['0'..'9']) then
  begin { Added 10.23.95 to support selection by number }
    HistorySetLock(HistoryID, Focused, Byte(GetAltChar(Event.KeyCode)));
    if Focused < Range - 1 then FocusItem(Focused + 1);
    DrawView;
    Event.What := evNothing;
  end
  else TListViewer.HandleEvent(Event);
end;

{ THistoryWindow }

constructor THistoryWindow.Init(var Bounds: TRect; HistoryId: Word);
begin
  TWindow.Init(Bounds, 'History', wnNoNumber);
  InitViewer(HistoryId);
end;

procedure THistoryWindow.ChangeBounds(var Bounds: TRect);
var
  Growing: Boolean;
  R: TRect;
begin
  Owner^.GetExtent(R);
  Growing :=
    (Bounds.B.X - Bounds.A.X <> Size.X) or
    (Bounds.B.Y - Bounds.A.Y <> Size.Y);
  if Bounds.A.X < R.A.X then
  begin
    Bounds.A.X := R.A.X;
    Bounds.B.X := R.A.X + Size.X;
  end;
  if Bounds.A.Y < R.A.Y then
  begin
    Bounds.A.Y := R.A.Y;
    Bounds.B.Y := R.A.Y + Size.Y;
  end;
  if Bounds.B.X > R.B.X then
  begin
    Bounds.B.X := R.B.X;
    if not Growing then Bounds.A.X := R.B.X - Size.X;
  end;
  if Bounds.B.Y > R.B.Y then
  begin
    Bounds.B.Y := R.B.Y;
    if not Growing then Bounds.A.Y := R.B.Y - Size.Y;
  end;
  TWindow.ChangeBounds(Bounds);
end;

function THistoryWindow.GetPalette: PPalette;
const
  P: String[Length(CHistoryWindow)] = CHistoryWindow;
begin
  GetPalette := @P;
end;

function THistoryWindow.GetSelection: String;
begin
  GetSelection := HistoryStr(
    PHistoryViewer(Viewer)^.HistoryId, Viewer^.Focused);
end;

function THistoryWindow.GetTitle(MaxSize: Integer): TTitleStr;
begin
  if Length(Title^) > MaxSize + 6 then GetTitle := ''
  else GetTitle := TWindow.GetTitle(MaxSize);
end;

procedure THistoryWindow.InitViewer(HistoryId: Word);
var
  R: TRect;
begin
  GetExtent(R);
  R.Grow(-1,-1);
  Viewer := New(PHistoryViewer, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    HistoryId));
  Insert(Viewer);
end;

{ THistory }

function DefHistoryFunc(Link: PInputLine;
  const S: String): String;
begin
  DefHistoryFunc := S;
end;

constructor THistory.Init(var Bounds: TRect; ALink: PInputLine;
  AHistoryId: Word);
begin
  TView.Init(Bounds);
  Options := Options or ofPostProcess;
  EventMask := EventMask or evBroadcast;
  Link := ALink;
  if Link <> nil then Link^.History := @Self;
  HistoryId := AHistoryId;
  HistoryPutFunc := DefHistoryFunc;
  HistoryGetFunc := DefHistoryFunc;
end;

constructor THistory.Load(var S: TStream);
begin
  TView.Load(S);
  GetPeerViewPtr(S, Link);
  S.Read(HistoryId, SizeOf(Word));
  HistoryPutFunc := DefHistoryFunc;
  HistoryGetFunc := DefHistoryFunc;
end;

procedure THistory.Draw;
var
  B: TDrawBuffer;
begin
  MoveCStr(B, #222'~'#25'~'#221, GetColor($0102));
  WriteLine(0, 0, Size.X, Size.Y, B);
end;

function THistory.GetPalette: PPalette;
const
  P: String[Length(CHistory)] = CHistory;
begin
  GetPalette := @P;
end;

procedure THistory.HandleEvent(var Event: TEvent);
var
  I: Integer;
  C: Word;
  R, P: TRect;
  HistoryWindow: PHistoryWindow;
  Rslt: String;
begin
  TView.HandleEvent(Event);
  if (Event.What = evMouseDown) or
     ((Event.What = evKeyDown) and
      (CtrlToArrow(Event.KeyCode) = kbDown) and
      (Link^.State and sfFocused <> 0)) then
  begin
    HistoryAdd(HistoryId, HistoryPutFunc(Link, Link^.Data^),
      Link^.Options and ofValidate = 0);
    Link^.Select;
    Link^.GetBounds(R);
    Dec(R.A.X); Inc(R.B.X); Inc(R.B.Y, 8); Dec(R.A.Y);
    Owner^.GetExtent(P);
    R.Intersect(P);
    I := HistoryWidth(HistoryID) + 4;
    if I < 10 then I := 10;
    if R.B.X - R.A.X < I then R.B.X := R.A.X + I;
    if R.B.X > Owner^.Size.X then R.B.X := Owner^.Size.X;
    if R.B.Y = Owner^.Size.Y then
    begin
      Dec(R.B.Y);
      while (R.B.Y - R.A.Y < 10) and (R.A.Y > 1) do Dec(R.A.Y);
    end;
    HistoryWindow := InitHistoryWindow(R);
    if HistoryWindow <> nil then
    begin
      HistoryWindow^.HelpCtx := Owner^.HelpCtx;
      C := Owner^.ExecView(HistoryWindow);
      if C = cmOk then
      begin
        Rslt := HistoryWindow^.GetSelection;
        Link^.SetData(Rslt);
      end;
      Dispose(HistoryWindow, Done);
    end;
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and
    ((Event.KeyCode = kbCtrlDn) or (Event.KeyCode = kbCtrlUp)) and
    (Link^.State and sfFocused <> 0) then
  begin
    C := HistoryCount(HistoryID);
    if C <> 0 then
    begin
      if Link^.Data^ = '' then I := -1
      else
      begin
        HistoryList^.IndexMode := hlExact + hlRelat;
        I := HistoryIndex(HistoryId, Link^.Data^);
        HistoryList^.IndexMode := 0;
        if Event.KeyCode = kbCtrlDn then Inc(I)
        else Dec(I);
      end;
      if I < 0 then I := 0
      else if I >= C then I := C - 1;
      Rslt := HistoryStr(HistoryId, I);
      Link^.SetData(Rslt);
    end;
    Event.What := evNothing;
  end
  else if Event.What = evBroadcast then
    if ((Event.Command = cmReleasedFocus) and (Event.InfoPtr = Link)) or
       (Event.Command = cmRecordHistory) then
      HistoryAdd(HistoryId, HistoryPutFunc(Link, Link^.Data^),
        Link^.Options and ofValidate = 0);
end;

function THistory.InitHistoryWindow(var Bounds: TRect): PHistoryWindow;
var
  P: PHistoryWindow;
begin
  P := New(PHistoryWindow, Init(Bounds, HistoryId));
  P^.HelpCtx := Link^.HelpCtx;
  InitHistoryWindow := P;
end;

procedure THistory.Store(var S: TStream);
begin
  TView.Store(S);
  PutPeerViewPtr(S, Link);
  S.Write(HistoryId, SizeOf(Word));
end;

procedure THistory.Awaken;
begin
  TView.Awaken;
  if Link <> nil then Link^.History := @Self;
end;

function StandardOkButton(var R: TRect; D: PDialog): PButton;
var
  Control: PButton;
begin
  Control := New(PButton, Init(R, 'O~K~', cmOK, bfDefault));
  D^.Insert(Control);
  StandardOkButton := Control;
end;

function StandardCancelButton(var R: TRect; D: PDialog): PButton;
var
  Control: PButton;
begin
  Control := New(PButton, Init(R, 'Cancel', cmCancel, bfNormal));
  D^.Insert(Control);
  StandardCancelButton := Control;
end;

function StandardHelpButton(var R: TRect; D: PDialog): PButton;
var
  Control: PButton;
begin
  Control := New(PButton, Init(R, 'Help', cmHelp, bfNormal));
  D^.Insert(Control);
  StandardHelpButton := Control;
end;

procedure StandardButtonRow(D: PDialog; SelNext: Boolean);
var
  R: TRect;
begin
  with D^ do
  begin
    R.Assign(3, Size.Y - 3, 13, Size.Y - 1);
    StandardOkButton(R, D);
    if Size.X > 37 then R.Assign(
      Size.X div 2 - 5, Size.Y - 3, Size.X div 2 + 5, Size.Y - 1)
    else R.Assign(
      Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
    StandardCancelButton(R, D);
    if Size.X > 37 then
    begin
      R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
      StandardHelpButton(R, D);
    end;
    if SelNext then SelectNext(False);
  end;
end;

function StandardHistory(ALink: PView; AHistoryId: Word): PHistory;
var
  Control: PHistory;
  R: TRect;
begin
  ALink^.GetBounds(R);
  R.A.X := R.B.X;
  Inc(R.B.X, 3);
  Control := New(PHistory, Init(R, PInputLine(ALink), AHistoryId));
  ALink^.Owner^.Insert(Control);
  StandardHistory := Control;
end;

procedure ConvertWSKey(KeyMask: Word; var Event: TEvent); { Added 02.05.99 }

procedure KeyToCommand(Command: Word);
begin
  Event.What := evCommand;
  Event.Command := Command;
  Event.InfoPtr := nil;
end;

begin
  case Event.KeyCode of
    kbCtrlHome: if KeyMask and ws1 <> 0 then Event.KeyCode := kbCtrlPgUp;
    kbCtrlEnd: if KeyMask and ws1 <> 0 then Event.KeyCode := kbCtrlPgDn;
    kbCtrlPgUp: if KeyMask and ws1 <> 0 then Event.KeyCode := kbCtrlHome;
    kbCtrlPgDn: if KeyMask and ws1 <> 0 then Event.KeyCode := kbCtrlEnd;
    else if Event.CharCode in WordStarChars then
      case Event.CharCode of
        ^A: if KeyMask and wsA <> 0 then KeyToCommand(cmSelectAll);
        ^C: if KeyMask and wsC <> 0 then KeyToCommand(cmCopy);
        ^D: if KeyMask and wsD <> 0 then KeyToCommand(cmValid);
        ^E: if KeyMask and wsE <> 0 then KeyToCommand(cmIncSearch);
        ^F: if KeyMask and wsF <> 0 then KeyToCommand(cmFind);
        ^R: if KeyMask and wsR <> 0 then KeyToCommand(cmReplace);
        ^S: if KeyMask and wsS <> 0 then KeyToCommand(cmSave);
        ^V: if KeyMask and wsV <> 0 then KeyToCommand(cmPaste);
        ^W: if KeyMask and wsW <> 0 then KeyToCommand(cmValid);
        ^X: if KeyMask and wsX <> 0 then KeyToCommand(cmCut);
        ^Z: if KeyMask and wsZ <> 0 then KeyToCommand(cmUndo);
      end;
  end;
end;

{Added 12.17.99}
function MoveListItem(Viewer: PListViewer;
  List: PCollection; Up: Boolean): Boolean;
var
  P: Pointer;
begin
  MoveListItem := False;
  with Viewer^, List^ do
  begin
    P := At(Focused);
    if P = nil then Exit;
    if Up and (Focused <> 0) then
    begin
      Items^[Focused] := Items^[Focused - 1];
      Items^[Focused - 1] := P;
      FocusItem(Focused - 1);
    end
    else if not Up and (Focused < Range - 1) then
    begin
      if At(Focused + 1) = nil then Exit;
      Items^[Focused] := Items^[Focused + 1];
      Items^[Focused + 1] := P;
      FocusItem(Focused + 1);
    end
    else Exit;
  end;
  MoveListItem := True;
end;

{ Added 2005.09.24 }
(*
Ééëí 16876-71

† - a              ™ - k             Â - kh
° - b              ´ - l             Ê - c
¢ - v              ¨ - m             Á - ch
£ - g              ≠ - n             Ë - sh
§ - d              Æ - o             È - shh
• - e              Ø - p             Í - "
Ò - jo             ‡ - r             Î - y
¶ - zh             · - s             Ï - '
ß - z              ‚ - t             Ì - eh
® - i              „ - u             Ó - ju
© - jj             ‰ - f             Ô - ja
*)

function StrToVolapyukStr(C, PC, NC, NNC: Char;
  var DelChars: Byte; AltUkr: Boolean): String;
var
  S: String[3];
begin
  S := C;
  DelChars := 3;
  if (C = 'ä') and (NC = 'ë') and (NNC = #250) then S := 'X'
  else if (C in ['ä', '™']) and (NC in ['ë', '·']) and (NNC = #250) then S := 'x'
  else
  begin
    DelChars := 2;
    if (C = 'Ç') and (NC = #250) then S := 'W'
    else if (C = '¢') and (NC = #250) then S := 'w'
    else if (C = 'â') and (NC = #250) then S := 'J'
    else if (C = '©') and (NC = #250) then S := 'j'
    else if (C = 'ä') and (NC = #250) then S := 'Q'
    else if (C = '™') and (NC = #250) then S := 'q'
    else if (C = 'ï') and (NC = #250) then S := 'H'
    else if (C = 'Â') and (NC = #250) then S := 'h'
    else
    begin
      DelChars := 1;
      case C of
        'Ä' : S := 'A';
        'Å' : S := 'B';
        'Ç' : S := 'V';
        'É' : S := 'G';
        'Ñ' : S := 'D';
        'Ö' : S := 'E';
        'Ü' : if TPString.Upcase(NC) = NC then S := 'ZH' else S := 'Zh';
        'á' : S := 'Z';
        'à' : S := 'I';
        'â' : if TPString.Upcase(NC) = NC then S := 'JJ' else S := 'Jj';
        'ä' : S := 'K';
        'ã' : S := 'L';
        'å' : S := 'M';
        'ç' : S := 'N';
        'é' : S := 'O';
        'è' : S := 'P';
        'ê' : S := 'R';
        'ë' : S := 'S';
        'í' : S := 'T';
        'ì' : S := 'U';
        'î' : S := 'F';
        'ï' : if TPString.Upcase(NC) = NC then S := 'KH' else S := 'Kh';
        'ñ' : S := 'C';
        'ó' : if TPString.Upcase(NC) = NC then S := 'CH' else S := 'Ch';
        'ò' : if TPString.Upcase(NC) = NC then S := 'SH' else S := 'Sh';
        'ô' : if TPString.Upcase(NC) = NC then S := 'SHH' else S := 'Shh';
        'ö' : S := '''''';
        'õ' : S := 'Y';
        'ú' : S := '''';
        'ù' : if TPString.Upcase(NC) = NC then S := 'EH' else S := 'Eh';
        'û' : if TPString.Upcase(NC) = NC then S := 'JU' else S := 'Ju';
        'ü' : if TPString.Upcase(NC) = NC then S := 'JA' else S := 'Ja';
        #240: if TPString.Upcase(NC) = NC then S := 'JO' else S := 'Jo';
{ukr}
        #242:
          if AltUkr then
            if TPString.Upcase(NC) = NC then S := 'JE' else S := 'Je'
          else S := 'G'#250;
        #243: if AltUkr then S := 'je' else S := 'g'#250;
        #244:
          if AltUkr then
            if TPString.Upcase(NC) = NC then S := 'JI' else S := 'Ji'
          else if TPString.Upcase(NC) = NC then S := 'JE' else S := 'Je';
        #245: if AltUkr then S := 'ji' else S := 'je';
        #246: S := 'I'#250;
        #247: S := 'i'#250;
        #248: if TPString.Upcase(NC) = NC then S := 'JI' else S := 'Ji';
        #249: S := 'ji';
{end ukr}
        '†' : S := 'a';
        '°' : S := 'b';
        '¢' : S := 'v';
        '£' : S := 'g';
        '§' : S := 'd';
        '•' : S := 'e';
        '¶' : S := 'zh';
        'ß' : S := 'z';
        '®' : S := 'i';
        '©' : S := 'jj';
        '™' : S := 'k';
        '´' : S := 'l';
        '¨' : S := 'm';
        '≠' : S := 'n';
        'Æ' : S := 'o';
        'Ø' : S := 'p';
        '‡' : S := 'r';
        '·' : S := 's';
        '‚' : S := 't';
        '„' : S := 'u';
        '‰' : S := 'f';
        'Â' : S := 'kh';
        'Ê' : S := 'c';
        'Á' : S := 'ch';
        'Ë' : S := 'sh';
        'È' : S := 'shh';
        'Í' : S := '''''';
        'Î' : S := 'y';
        'Ï' : S := '''';
        'Ì' : S := 'eh';
        'Ó' : S := 'ju';
        'Ô' : S := 'ja';
        #241: S := 'jo';
      end;
    end;
  end;
  StrToVolapyukStr := S;
end;

function VolapyukStrToStr(C, PC, NC, NNC: Char;
  var DelChars: Byte; AltUkr: Boolean): String;
var
  S: String[3];
begin
  S := C;
  DelChars := 3;
  if ((C = 'S') and (NC = 'H') and (NNC = 'H')) or
     ((C = 'S') and (NC = 'h') and (NNC = 'h')) then S := 'ô'
  else if (C = 's') and (NC = 'h') and (NNC = 'h') then S := 'È'
  else
  begin
    DelChars := 2;
    if (C = 'Z') and (NC in ['H', 'h']) then S := 'Ü'
    else if (C = 'z') and (NC = 'h') then S := '¶'
    else if (C = 'J') and (NC in ['J', 'j']) then S := 'â'
    else if (C = 'j') and (NC = 'j') then S := '©'
    else if (C = 'K') and (NC in ['H', 'h']) then S := 'ï'
    else if (C = 'k') and (NC = 'h') then S := 'Â'
    else if (C = 'C') and (NC in ['H', 'h']) then S := 'ó'
    else if (C = 'c') and (NC = 'h') then S := 'Á'
    else if (C = 'S') and (NC in ['H', 'h']) then S := 'ò'
    else if (C = 's') and (NC = 'h') then S := 'Ë'
    else if (C = 'E') and (NC in ['H', 'h']) then S := 'ù'
    else if (C = 'e') and (NC = 'h') then S := 'Ì'
    else if (C = 'J') and (NC in ['U', 'u']) then S := 'û'
    else if (C = 'j') and (NC = 'u') then S := 'Ó'
    else if (C = 'J') and (NC in ['A', 'a']) then S := 'ü'
    else if (C = 'j') and (NC = 'a') then S := 'Ô'
    else if (C = 'J') and (NC in ['O', 'o']) then S := #240
    else if (C = 'j') and (NC = 'o') then S := #241
    else if (C = '''') and (NC = '''') then
    begin
      if NNC in ['A'..'Z', 'a'..'z'] then
        if PC in ['Å', 'Ç', 'Ñ', 'Ü', 'á', 'ç', 'ê', 'ë', 'í', 'ï'] then S := 'ö'
        else if PC in ['°', '¢', '§', '¶', 'ß', '≠', '‡', '·', '‚', 'Â'] then S := 'Í';
    end
{ukr}
    else if (C = 'J') and (NC in ['E', 'e']) then
      if AltUkr then S := #242 else S := #244
    else if (C = 'j') and (NC = 'e') then
      if AltUkr then S := #243 else S := #245
    else if (C = 'J') and (NC in ['I', 'i']) then
      if AltUkr then S := #244 else S := #248
    else if (C = 'j') and (NC = 'i') then
      if AltUkr then S := #245 else S := #249
    else if (C = 'G') and (NC = #250) then S := #242
    else if (C = 'g') and (NC = #250) then S := #243
    else if (C = 'I') and (NC = #250) then S := #246
    else if (C = 'i') and (NC = #250) then S := #247
{end ukr}
    else
    begin
      DelChars := 1;
      case C of
        'A': S := 'Ä';
        'B': S := 'Å';
        'V': S := 'Ç';
        'G': S := 'É';
        'D': S := 'Ñ';
        'E': S := 'Ö';
        'Z': S := 'á';
        'I': S := 'à';
        'K': S := 'ä';
        'L': S := 'ã';
        'M': S := 'å';
        'N': S := 'ç';
        'O': S := 'é';
        'P': S := 'è';
        'R': S := 'ê';
        'S': S := 'ë';
        'T': S := 'í';
        'U': S := 'ì';
        'F': S := 'î';
        'C': S := 'ñ';
        'Y': S := 'õ';
        'J': S := 'â'#250;
        'H': S := 'ï'#250;
        'Q': S := 'ä'#250;
        'W': S := 'Ç'#250;
        'X': S := 'äë'#250;
       '''':
          begin
            if NC in [#32..#127] then
              if PC in ['Å', 'Ç', 'É', 'Ñ', 'Ö', 'Ü', 'á', 'ä', 'ã', 'å',
                'ç', 'è', 'ê', 'ë', 'í', 'î', 'ï', 'ó', 'ò', 'ô'] then S := 'ú'
              else if PC in ['°', '¢', '£', '§', '•', '¶', 'ß', '™', '´', '¨',
                '≠', 'Ø', '‡', '·', '‚', '‰', 'Â', 'Á', 'Ë', 'È'] then S := 'Ï'
              else S := '''';
          end;
        'a': S := '†';
        'b': S := '°';
        'v': S := '¢';
        'g': S := '£';
        'd': S := '§';
        'e': S := '•';
        'z': S := 'ß';
        'i': S := '®';
        'k': S := '™';
        'l': S := '´';
        'm': S := '¨';
        'n': S := '≠';
        'o': S := 'Æ';
        'p': S := 'Ø';
        'r': S := '‡';
        's': S := '·';
        't': S := '‚';
        'u': S := '„';
        'f': S := '‰';
        'c': S := 'Ê';
        'y': S := 'Î';
        'j': S := '©'#250;
        'h': S := 'Â'#250;
        'q': S := '™'#250;
        'w': S := '¢'#250;
        'x': S := '™·'#250;
      end;
    end;
  end;
  VolapyukStrToStr := S;
end;

procedure ConvertString(var S: String; Action: TConvertAction;
  C: Char; W: Word);
var
  X, Y: Boolean;
  B, XB: Byte;
  PC, NC, NNC: Char;
  I: Integer;
  L: PDecoderList;
  BS: String[3];
  XS: String;
  T: ConvertTable;
begin
  case Action of
    caUpcase: UpcaseSt(S);
    caLocase: LocaseSt(S);
    caLatin, caRus:
      begin
	for C := #0 to #255 do T[C] := C;
	if Action = caLatin then
	begin
	  Move(TByteArray(GetStrAddr(LoChars)^)[1],
	    T[#128], Length(LoChars));
	  Move(TByteArray(GetStrAddr(HiChars)^)[1],
            T[#224], Length(HiChars));
        end
        else Move(TByteArray(GetStrAddr(RuChars)^)[1],
          T[#34], Length(RuChars));
        for B := 1 to Length(S) do S[B] := T[S[B]];
      end;
    caCaps: for B := 1 to Length(S) do
      begin
        if B <> 1 then C := S[B - 1];
	if (C = #0) or (C in WordDelims) then
          S[B] := TPString.Upcase(S[B]);
      end;
    caHex:
      begin
        X := Trim(S) <> '';
        if X then for B := 1 to Length(S) do
          if not (S[B] in [' ', '$', '0'..'9', 'A'..'F', 'a'..'f']) then
          begin
            X := False;
	    Break;
          end;
        BS := '';
        XS := '';
        for B := 1 to Length(S) do
          if X then
          begin
            if S[B] in [' ', '$'] then Continue;
            BS := BS + S[B];
            if Length(BS) = 2 then
	    begin
              Val('$' + BS, XB, I);
              XS := XS + Char(XB);
              BS := '';
            end;
          end
          else
          begin
            Y := GetShiftState and (kbLeftShift + kbRightShift) <> 0;
            BS := HexB(Byte(S[B]));
	    if not Y and (XS <> '') then BS := ' ' + BS;
            XS := XS + BS;
	  end;
        S := XS;
      end;
    caVolapyuk, caVolToRus, caUkrVolapyuk, caVolToUkr:
      begin
{	X := GetShiftState and (kbLeftShift + kbRightShift) <> 0;}
	X := Action >= caUkrVolapyuk;
	B := 1;
	while B <= Length(S) do
	begin
	  C := S[B];
	  if B > 1 then PC := S[B - 1] else PC := ' ';
	  if B < Length(S) then NC := S[B + 1] else NC := ' ';
	  if B < Length(S) - 1 then NNC := S[B + 2] else NNC := ' ';
	  if Action in [caVolToRus, caVolToUkr] then
	    BS := VolapyukStrToStr(C, PC, NC, NNC, XB, X)
	  else BS := StrToVolapyukStr(C, PC, NC, NNC, XB, X);
	  Delete(S, B, XB);
	  Insert(BS, S, B);
	  Inc(B, Length(BS));
	end;
      end;
    caXLAT:
      begin
        if W = kbAlt0 then I := 0 else I := 1 + Hi(W) - Hi(kbAlt1);
        X := False;
        XS := ProgramPath + 'CONNECT.UDD';
        if ThisFileExists(XS) then
        begin
	  L := New(PDecoderList, Init(8, 8));
          L^.LoadFromFile(XS);
          if L^.Count > I shr 1 then
            if Odd(I) then X := ReadConvertTable(T, L^.OutNames(I shr 1), Y)
            else X := ReadConvertTable(T, L^.InNames(I shr 1), Y);
          Dispose(L, Done);
	  if X then for B := 1 to Length(S) do S[B] := T[S[B]];
	end;
      end;
    caShort: lGetShortFileName(S, S);
    caLong:  lGetLongFileName(S, S);
    caSpaceToUnderline: for B := 1 to Length(S) do if S[B] = ' ' then S[B] := '_';
    caUnderlineToSpace: for B := 1 to Length(S) do if S[B] = '_' then S[B] := ' ';
  end;
end;

end.