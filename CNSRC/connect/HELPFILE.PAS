{$I-,X+,O+,F+}
unit HelpFile;

interface

uses Objects, Drivers, Views, MsgBox, App, Swaps, FindDlg, HelpPrim;

const
  CHelpColor	  = #$38#$3F#$3A#$13#$13#$30#$3E#$1E;
  CHelpBlackWhite = #$07#$0F#$07#$70#$70#$07#$0F#$70;
  CHelpMonochrome = #$07#$0F#$07#$70#$70#$07#$0F#$70;
  CHelpViewer	  = #6#7#8;
  CHelpWindow	  = #64#65#66#67#68#69#70#71;

  HelpSelIndex    = 86;
  ExtraBaseIndex  = 195;
  CHelpExtra      = #195#196#197#198#199#200#201#202#203#204;
  CHelpExtraColor = #$39#$3A#$3B#$3C#$3D#$5F#$7F#$30#$1A#$30;
  CHelpExtraBW    = #$0F#$0F#$0F#$0F#$0F#$0F#$0F#$70#$70#$70;
  CHelpExtraMono  = #$0F#$0F#$0F#$0F#$0F#$0F#$0F#$70#$70#$70;

  hcHelpInUse	  = 2;

type

{ TParagraph }

  PParagraph = ^TParagraph;
  TParagraph = record
    Next: PParagraph;
    Wrap: Boolean;
    Size: Word;
    Text: record end;
  end;

{ THelpTopic }

  TCrossRef = record
    Ref: Integer;
    Offset: Integer;
    Length: Byte;
  end;

  PCrossRefs = ^TCrossRefs;
  TCrossRefs = array[1..10000] of TCrossRef;

  PHelpTopic = ^THelpTopic;
  THelpTopic = object(TObject)
    NumLines: Integer;
    Paragraphs:	PParagraph;
    NumRefs: Integer;
    CrossRefs: PCrossRefs;
    Width: Integer;
    LastOffset:	Integer;
    LastLine: Integer;
    LastParagraph: PParagraph;
    constructor	Load(var S: TStream);
    destructor Done; virtual;
    procedure GetLine(Line: Integer; var S: String);
    function GetNumCrossRefs: Integer;
    procedure CalcNumLines;
    procedure SetWidth(AWidth: Integer);
    procedure GetOffset(Line, APos: Integer;
      var Paragraph: PParagraph; var Offset: Integer);
    procedure GetOffsetLine(var	Line, APos: Integer;
      Paragraph: PParagraph; Offset: Integer);
    procedure WrapText(var Text; Size: Integer; var Offset: Integer;
      Wrap: Boolean; var Line: String);
  end;

{ THelpIndex }

  PIndexArray =	^TIndexArray;
  TIndexArray =	array[0..16380]	of LongInt;

  PHelpIndex = ^THelpIndex;
  THelpIndex = object(TObject)
    Size: Word;
    Index: PIndexArray;
    constructor	Load(var S: TStream);
    destructor Done; virtual;
    function Position(I: Integer): Longint;
  end;

{ THelpFile }

  PHelpFile = ^THelpFile;
  THelpFile = object(TObject)
    Name: PString;
    Stream: PStream;
    Index: PHelpIndex;
    IndexPos: Longint;
    constructor	Init(const AName: FNameStr);
    destructor Done; virtual;
    procedure InitHelpFile(const AName: FNameStr);
    procedure DoneHelpFile;
    function GetTopic(I: Integer): PHelpTopic;
  end;

  PRefItem = ^TRefItem;
  TRefItem = record
    Point: TPoint;
    Length: Byte;
    Index: Integer;
  end;

  PRefList = ^TRefList;
  TRefList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
    function CanInsert: Boolean;
  end;

  PFindAllItem = ^TFindAllItem;
  TFindAllItem = record
    Line: PString;
    Rec: TPrevHelpRec;
  end;

  PFindAllList = ^TFindAllList;
  TFindAllList = object(TRefList)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  TPos = record
    AStart: Integer;
    AnEnd: Integer;
  end;

{ THelpViewer }

  PHelpViewer =	^THelpViewer;
  THelpViewer =	object(TScroller)
    HelpFile: PHelpFile;
    Topic: PHelpTopic;
    RefList: PRefList;
    CurCtx: Word;
    Selected: Integer;
    SearchStr, TopicSearchStr: String[63];
    Area: TArea;
    SelectFromX: Byte;
    SelectFromY: Integer;
    IsSelected:	Boolean;
    DrawFlag: Boolean;
    PrevRec: TPrevHelpRec;
    PrevSel: Integer;
    PrevSelected: Integer;
    FindAllList: PFindAllList;
    FindAllData: TSearchData;
    SearchingAll: Boolean;
    FindAllDlgInUse: Boolean;
    Invalid: Boolean;
    constructor	Init(var Bounds: TRect;	AHScrollBar,
      AVScrollBar: PScrollBar; AHelpFile: PHelpFile;
      const R: TPrevHelpRec);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    function Valid(Command: Word): Boolean; virtual;
    procedure InitViewer(const R: TPrevHelpRec);
    function OtherHelpFileName: FNameStr;
    function SwitchToNewFile(const AName: FNameStr): Boolean;
    procedure SwitchToTopic(KeyRef: Integer; ExecPutPrev: Boolean);
    function SwitchTo(const R: TPrevHelpRec;
      PutPrev, ExecPutPrev: Boolean): Boolean;
    procedure ExecTopic(P: PHelpTopic);
    procedure PutPrevHelp;
    procedure MakeSelectVisible;
    procedure InitRefList;
    procedure DoneRefList;
    procedure FillRefList;
    procedure GetCrossRef(Index: Integer; var KeyPoint: TPoint;
      var KeyLength: Byte; var KeyRef: Integer);
    function GetWordAtCursor: String;
    procedure AddRecordToHistory(const R: TPrevHelpRec;
      KeyPoint: TPoint; KeyLength: Byte);
    procedure WriteTopicToHistory;
    procedure FastScrollTo(Y: Integer);
    procedure GoRight;
    procedure GoLeft;
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
    procedure GoCtrlRight;
    procedure GoCtrlLeft;
    procedure GoCtrlDown;
    procedure GoCtrlUp;
    procedure GoToTopic;
    procedure SelectNext;
    procedure SelectPrev;
    procedure GetPrevState(var R: TPrevHelpRec);
    procedure SetPrevState(const R: TPrevHelpRec; KeepOrgSize: Boolean);
    function Search(AChar: Char): Boolean;
    procedure SearchAndSelect(PutPrev: Boolean);
    procedure ReturnAndSelect;
    function SearchFakeCrossRef(const S: String; Index: Integer): Boolean;
    procedure Highlight(AKB: Integer; APB: Byte; AKK: Integer; APK: Byte);
    procedure Unselect;
    procedure SelectOn(CurY: Integer; CurX: Byte);
    function LineSelected(AnIndex: Integer): Boolean;
    procedure GetPos(AnIndex: Integer; var APos: TPos);
    procedure GetXString(AnIndex: Integer; var S: String);
    function GetSelectedString(AnIndex:	Integer): String;
    procedure Copy;
    procedure Paste;
    procedure Find(const Match: String; AOptions: Word);
    procedure FindDlg(All: Boolean);
    procedure FindAllDlg;
    procedure FindAllTrack(Item: Integer);
    procedure HistoryWindow;
    procedure GetHelpBrowserRec(var R: TPrevHelpRec;
      var FakeRefStr: String; var KeyRef: Integer;
      var SearchFake: Boolean);
    procedure ToggleHelpBrowser;
    procedure ChangeHelpBrowserTopic;
    procedure Popup(AOrigin: TPoint);
  end;

{ THelpWindow }

  PHelpWindow =	^THelpWindow;
  THelpWindow =	object(TWindow)
    constructor	Init(HelpFile: PHelpFile; const R: TPrevHelpRec);
    constructor Load(var S: TStream);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Close; virtual;
    function GetPalette: PPalette; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure SizeLimits(var Min, Max: TPoint);	virtual;
    procedure Zoom; virtual;
  end;

function GetHelpName(const R: TPrevHelpRec): FNameStr;
procedure GetHelp(var R: TPrevHelpRec);
procedure PutHelp(const R: TPrevHelpRec);
procedure PutHelpSearchStr(const S: String);
procedure Help(const R: TPrevHelpRec; ForceBrowser: Boolean);

const
  TheHelpViewer: PHelpViewer = nil;
  TheHelpBrowser: PHelpViewer = nil;

  ModalHelpInUse: Boolean = False;
  OpeningBrowser: Boolean = False;

var
  HelpViewerBounds, HelpBrowserBounds: TRect;

implementation

uses Dos, WinIcons, Menus, Dialogs, HistList, History, DirPrim, EditMsg,
  HelpFind, ClipPrim, RegExp, ExecPrim, OpenHelp, HistWin, CNInputs,
  Popups, WinPos, CNWinPos, HeapUMB, DosTools, LFN, TPString, Consts,
  Commands, Defaults;

const
  HelpSearchStr: PString = nil;

  hcRefFile  = $F700;

  hcColor1   = $F800;
  hcColor2   = $F801;
  hcColor3   = $F802;
  hcColor4   = $F803;
  hcColor5   = $F804;
  hcColorX   = $F805;

  hcColor0   = $F900;
  hcColorFF  = $F9FF;

  SafetyPool = $2800;
  stOutOfMem = $FF;

  sfHelpBrowser = $8000;

  OutOfMemStr: String[35] = 'Not enough memory to load help text';

  GoToTopicCommands = [cmGoToLine];

function ValidWindowBounds(var R: TRect): Boolean;
var
  X, Y: Integer;
begin
  X := R.B.X - R.A.X;
  Y := R.B.Y - R.A.Y;
  ValidWindowBounds :=
    (X >= MinWinSize.X) and (X <= MaxViewWidth) and
    (Y >= MinWinSize.Y) and (Y <= Desktop^.Size.Y);
end;

procedure SetViewerBrowserBounds;
begin
  if ValidWindowBounds(HelpViewerBounds) and
     ValidWindowBounds(HelpBrowserBounds) then Exit;
  Desktop^.GetExtent(HelpViewerBounds);
  HelpBrowserBounds := HelpViewerBounds;
  Dec(HelpViewerBounds.B.Y,
    (HelpViewerBounds.B.Y - HelpViewerBounds.A.Y) div 2);
  HelpBrowserBounds.A.Y := HelpViewerBounds.B.Y;
end;

procedure CloseHelpBrowser;
var
  P: PView;
begin
  if PWindow(TheHelpBrowser^.Owner)^.Icon <> nil then
    P := PWindow(TheHelpBrowser^.Owner)^.Icon
  else P := TheHelpBrowser^.Owner;
  Message(P, evCommand, cmClose, nil);
  if TheHelpViewer <> nil then
    PWindow(TheHelpViewer^.Owner)^.Frame^.DrawView;
end;

procedure HelpErrorMsgBox(Code: Integer; const Name: FNameStr);
var
  S: FNameStr;
begin
  if Code = stOutOfMem then S := OutOfMemStr + ' from'
  else S := 'Could not open help file';
  MessageBox(^C + S + #13^C'|' + Name + '|.', nil, mfError + mfOkButton);
end;

function ExecutableTopic(P: PHelpTopic; var PutPrev: Boolean): Boolean;
var
  B: Boolean;
  S: String;
begin
  P^.GetLine(1, S);
  TrimSt(S);
  UpcaseSt(S);
  B := Pos('$EXECUTE', S) = 1;
  if B and PutPrev and (Length(S) > 8) and (S[9] = '-') then
    PutPrev := False;
  ExecutableTopic := B;
end;

{
procedure WhitesToSpaces(var S: String);
var
  B: Byte;
begin
  for B	:= 1 to	Length(S) do
    if S[B] in [#0, #$FF] then S[B] := #32;
end;
}

{ THelpTopic }

constructor THelpTopic.Load(var	S: TStream);

procedure ReadParagraphs;
var
  I, Size: Integer;
  PP: ^PParagraph;
begin
  S.Read(I, SizeOf(I));
  PP :=	Addr(Paragraphs);
  while	I > 0 do
  begin
    S.Read(Size, SizeOf(Size));
    if (Size < 0) or (MaxAvail <= Longint(Size) + SafetyPool) then
    begin
      S.Status := stOutOfMem;
      Break;
    end;
{    GetMem(PP^, SizeOf(PP^^) + Size);}
    GetMemUMB(PP^, SizeOf(PP^^) + Size);
    PP^^.Size := Size;
    S.Read(PP^^.Wrap, SizeOf(Boolean));
    S.Read(PP^^.Text, Size);
    PP := Addr(PP^^.Next);
    Dec(I);
  end;
  PP^ := nil;
end;

procedure ReadCrossRefs;
var
  W: Word;
begin
  S.Read(NumRefs, SizeOf(Integer));
  W := SizeOf(TCrossRef) * NumRefs;
  if (S.Status <> stOk) or (MaxAvail <= Longint(W) + SafetyPool) then
  begin
    S.Status := stOutOfMem;
    NumRefs := 0;
  end
  else
  begin
{    GetMem(CrossRefs, W);}
    GetMemUMB(CrossRefs, W);
    S.Read(CrossRefs^, W);
  end;
end;

begin
  TObject.Init;
  ReadParagraphs;
  ReadCrossRefs;
  LastLine := MaxInt;
end;

destructor THelpTopic.Done;
var
  PP: PParagraph;
begin
{  FreeMem(CrossRefs, SizeOf(TCrossRef) * NumRefs);}
  FreeMemUMB(CrossRefs, SizeOf(TCrossRef) * NumRefs);
  while	Paragraphs <> nil do
  begin
    PP := Paragraphs;
    Paragraphs := PP^.Next;
{    FreeMem(PP, SizeOf(PP^) + PP^.Size);}
    FreeMemUMB(PP, SizeOf(PP^) + PP^.Size);
  end;
  TObject.Done;
end;

procedure THelpTopic.GetLine(Line: Integer; var S: String);
var
  Offset, I: Integer;
  P: PParagraph;
begin
  if Line <= NumLines then
  begin
    if LastLine < Line then
    begin
      I := Line;
      Dec(Line, LastLine);
      LastLine := I;
      Offset := LastOffset;
      P := LastParagraph;
    end
    else
    begin
      P := Paragraphs;
      Offset := 0;
      LastLine := Line;
    end;
    while P <> nil do
    begin
      while Offset < P^.Size do
      begin
	Dec(Line);
	WrapText(P^.Text, P^.Size, Offset, P^.Wrap, S);
	if Line = 0 then
	begin
	  LastOffset := Offset;
	  LastParagraph := P;
	  Exit;
	end;
      end;
      P := P^.Next;
      Offset := 0;
    end;
  end;
  S := '';
end;

function THelpTopic.GetNumCrossRefs: Integer;
begin
  GetNumCrossRefs := NumRefs;
end;

procedure THelpTopic.GetOffset(Line, APos: Integer;
  var Paragraph: PParagraph; var Offset: Integer);
var
  I: Integer;
  P: PParagraph;
  S: String;
begin
  Paragraph := nil;
  if LastLine <	Line then
  begin
    I := Line;
    Dec(Line, LastLine);
    LastLine :=	I;
    Offset := LastOffset;
    P := LastParagraph;
  end
  else
  begin
    Offset := 0;
    P := Paragraphs;
    LastLine :=	Line;
  end;
  while	P <> nil do
  begin
    while Offset < P^.Size do
    begin
      Dec(Line);
      WrapText(P^.Text, P^.Size, Offset, P^.Wrap, S);
      if Line =	0 then
      begin
	LastOffset := Offset;
	LastParagraph := P;
	Paragraph := P;
{	TrailTrim(S);}
	if APos	<= Length(S) then Dec(Offset, Length(S)	- APos + 1);
	Exit;
      end;
    end;
    P := P^.Next;
    Offset := 0;
  end;
end;

procedure THelpTopic.GetOffsetLine(var Line, APos: Integer;
  Paragraph: PParagraph; Offset: Integer);
var
  I, L:	Integer;
  P: PParagraph;
  S: String;
begin
  Line := 0;
  I := 0;
  L := 0;
  P := Paragraphs;
  while	(P <> nil) and (P <> Paragraph)	do
  begin
    while I < P^.Size do
    begin
      Inc(L);
      WrapText(P^.Text,	P^.Size, I, P^.Wrap, S);
    end;
    P := P^.Next;
    I := 0;
  end;
  if P <> Paragraph then Exit;
  while	(I <= Offset) and (I < P^.Size)	do
  begin
    Inc(L);
    WrapText(P^.Text, P^.Size, I, P^.Wrap, S);
  end;
  Line := L - 1;
{  TrailTrim(S);}
  APos := Length(S) - (I - Offset);
  if APos < 0 then APos	:= 0;
end;

procedure THelpTopic.CalcNumLines;
var
  Offset: Integer;
  P: PParagraph;
  S: String;
begin
  NumLines := 0;
  LastLine := MaxInt;
  P := Paragraphs;
  while	P <> nil do
  begin
    Offset := 0;
    while Offset < P^.Size do
    begin
      Inc(NumLines);
      WrapText(P^.Text,	P^.Size, Offset, P^.Wrap, S);
    end;
    P := P^.Next;
  end;
end;

procedure THelpTopic.SetWidth(AWidth: Integer);
begin
  Width	:= AWidth - 1;
end;

procedure THelpTopic.WrapText(var Text; Size: Integer; var Offset: Integer;
  Wrap: Boolean; var Line: String);
var
  I: Integer;

function Scan(var P; Offset, Size: Integer; C: Char): Integer; assembler;
asm
	CLD
	LES	DI,P
	ADD	DI,&Offset
	MOV	DX,Size
	SUB	DX,&Offset
	OR	DH,DH
	JZ	@@1
	MOV	DX,256
@@1:	MOV	CX,DX
	MOV	AL,C
	REPNE	SCASB
	SUB	CX,DX
	NEG	CX
	XCHG	AX,CX
end;

procedure TextToLine(var Text; Offset, Length: Integer;	var Line: String);
  assembler;
asm
	CLD
	PUSH	DS
	LDS	SI,Text
	ADD	SI,&Offset
	LES	DI,Line
	MOV	AX,Length
	XOR	AH,AH
	STOSB
	XCHG	AX,CX
@@1:    lodsb
	cmp	al,0
	je	@@2
	cmp	al,255
	jne	@@3
@@2:	mov 	al,32
@@3:    stosb
	loop 	@@1
	POP	DS
end;

begin
  I := Scan(Text, Offset, Size,	#13);
  if (I	>= Width) and Wrap then
  begin
    I := Offset	+ Width;
    if I >= Size then I := Size
    else
    begin
      while (I > Offset) and
	not (PByteArray(@Text)^[I] in [10, 13, 32]) do Dec(I);
      if I <> Offset then Inc(I);
    end;
    if I = Offset then
    begin
      while (I < Size) and
	not (PByteArray(@Text)^[I] in [10, 13, 32]) do Inc(I);
      if I < Size then Inc(I);
    end;
    Dec(I, Offset);
  end;
  TextToLine(Text, Offset, I, Line);
  if Line[Length(Line)]	= #13 then Dec(Line[0]);
  Inc(Offset, I);
end;

{ THelpIndex }

constructor THelpIndex.Load(var	S: TStream);
begin
  S.Read(Size, SizeOf(Size));
  if MaxAvail <= LongMul(SizeOf(Longint), Size) + SafetyPool then
  begin
    S.Status := stOutOfMem;
    Size := 0;
  end;
  if Size = 0 then Index := nil
  else
  begin
{    GetMem(Index, SizeOf(Longint) * Size);}
    GetMemUMB(Index, SizeOf(Longint) * Size);
    S.Read(Index^, SizeOf(Longint) * Size);
  end;
end;

destructor THelpIndex.Done;
begin
{  FreeMem(Index, SizeOf(LongInt) * Size);}
  FreeMemUMB(Index, SizeOf(LongInt) * Size);
  TObject.Done;
end;

function THelpIndex.Position(I:	Integer): Longint;
begin
  if I < Size then Position := Index^[I]
  else Position	:= -1;
end;

{ THelpFile }

constructor THelpFile.Init(const AName: FNameStr);
begin
  TObject.Init;
  InitHelpFile(AName);
end;

destructor THelpFile.Done;
begin
  DoneHelpFile;
  TObject.Done;
end;

procedure THelpFile.InitHelpFile(const AName: FNameStr);
const
  MagicHeader =	$46484246; {'FBHF'}
var
  Magic: Longint;
begin
{  Name := NewStr(AName);}
  Name := NewStrUMB(AName);
  LogEvent := lcDiskRead;
  DrawStatusLine('Reading Help file ' + TrimmedName(Name^, 49) + '.');
  Stream := New(PDosStream, Init(Name^, stOpenRead));
  Stream^.Read(Magic, SizeOf(Longint));
  if Magic <> MagicHeader then Stream^.Status := stReadError
  else with Stream^ do
  begin
    Seek(8);
    Read(IndexPos, SizeOf(IndexPos));
    Seek(IndexPos);
    Index := PHelpIndex(Get);
  end;
end;

procedure THelpFile.DoneHelpFile;
begin
  if Index <> nil then
  begin
    Dispose(Index, Done);
    Index := nil;
  end;
  Dispose(Stream, Done);
{  DisposeStr(Name);}
  DisposeStrUMB(Name);
end;

function InvalidTopic(const AName: FNameStr;
  Index, Code: Integer): PHelpTopic;
var
  Topic: PHelpTopic;
  Para: PParagraph;
  S: String;
begin
  if Code = stOutOfMem then S := OutOfMemStr
  else S := 'No help available in this context';
  S := Concat(' ', S, '.'#13#13' Help file:   ', AName,
    #13' Topic index: ', Long2Str(Index));
  Topic := New(PHelpTopic, Init);
{  GetMem(Para, SizeOf(Para^) + Length(S));}
  GetMemUMB(Para, SizeOf(Para^) + Length(S));
  Para^.Size := Length(S);
  Para^.Wrap := False;
  Para^.Next := nil;
  Move(S[1], Para^.Text, Length(S));
  Topic^.Paragraphs := Para;
  Topic^.LastLine := MaxInt;
  InvalidTopic := Topic;
end;

function THelpFile.GetTopic(I: Integer): PHelpTopic;
var
  Code: Integer;
  Pos: Longint;
  P: PHelpTopic;
begin
  LogEvent := 0;
  DrawStatusLine('Searching for Help topic.');
  Pos := Index^.Position(I);
  if Pos <= 0 then P := nil
  else
  begin
    Stream^.Seek(Pos);
    P := PHelpTopic(Stream^.Get);
    Code := Stream^.Status;
    Stream^.Reset;
  end;
  if (P = nil) or (Code <> stOk) then
  begin
    if P <> nil then Dispose(P, Done);
    P := InvalidTopic(Name^, I, Code);
  end;
  GetTopic := P;
end;

procedure TRefList.FreeItem(Item: Pointer);
begin
{  if Item <> nil then FreeMem(Item, SizeOf(TRefItem));}
  if Item <> nil then FreeMemUMB(Item, SizeOf(TRefItem));
end;

function TRefList.CanInsert: Boolean;
begin
  if Count < Limit then CanInsert := MaxAvail > SafetyPool
  else CanInsert := MaxAvail > LongMul(Limit + Delta, 4) + SafetyPool;
end;

procedure TFindAllList.FreeItem(Item: Pointer);
begin
  if Item <> nil then with PFindAllItem(Item)^ do
  begin
{
    DisposeStr(Line);
    DisposeStr(Rec.PrevName);
    FreeMem(Item, SizeOf(TFindAllItem));
}
    DisposeStrUMB(Line);
    DisposeStrUMB(Rec.PrevName);
    FreeMemUMB(Item, SizeOf(TFindAllItem));
  end;
end;

{ THelpViewer }

constructor THelpViewer.Init(var Bounds: TRect;	AHScrollBar,
  AVScrollBar: PScrollBar; AHelpFile: PHelpFile;
  const R: TPrevHelpRec);
begin
  TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
  Options := Options or	ofSelectable;
  State	:= State or sfCursorVis;
  GrowMode := gfGrowHiX	+ gfGrowHiY;
  HelpFile := AHelpFile;
  InitViewer(R);
end;

constructor THelpViewer.Load(var S: TStream);
var
  R: TPrevHelpRec;
  Name: FNameStr;
begin
  TScroller.Load(S);
  R.PrevName := S.ReadStr;
  S.Read(R.PrevIndex, SizeOf(Word) + SizeOf(TPoint) * 3);
  S.Read(Area, SizeOf(TArea) +
    SizeOf(Byte) + SizeOf(Integer) + SizeOf(Boolean));
  Name := GetHelpName(R);
  DisposeStr(R.PrevName);
  HelpFile := New(PHelpFile, Init(Name));
  InitViewer(R);
end;

destructor THelpViewer.Done;
begin
  if not Invalid then PutPrevHelp;
  Dispose(HelpFile, Done);
  if FindAllList <> nil then Dispose(FindAllList, Done);
  DoneRefList;
  if Topic <> nil then Dispose(Topic, Done);
  if not ModalHelpInUse then
    if State and sfHelpBrowser <> 0 then TheHelpBrowser := nil
    else TheHelpViewer := nil;
  TScroller.Done;
end;

procedure THelpViewer.InitViewer(const R: TPrevHelpRec);
var
  B: Boolean;
begin
  if HelpFile^.Stream^.Status <> stOk then
  begin
    HelpErrorMsgBox(HelpFile^.Stream^.Status, HelpFile^.Name^);
    Invalid := True;
  end
  else
  begin
    if not ModalHelpInUse then
    begin
      if OpeningBrowser then State := State or sfHelpBrowser;
      if State and sfHelpBrowser <> 0 then TheHelpBrowser := @Self
      else TheHelpViewer := @Self;
    end;
    Topic := HelpFile^.GetTopic(R.PrevIndex);
    Topic^.SetWidth(Size.X);
    Topic^.CalcNumLines;
    InitRefList;
    FindAllList := New(PFindAllList, Init(8, 8));
    SetLimit(255, Topic^.NumLines + Size.Y);
    CurCtx := R.PrevIndex;
    SetPrevState(R, False);
    if ExecutableTopic(Topic, B) then
    begin
      ExecTopic(Topic);
      Topic := nil;
      Invalid := True;
    end;
  end;
end;

procedure THelpViewer.Store(var S: TStream);
var
  R: TPrevHelpRec;
begin
  TScroller.Store(S);
  GetPrevState(R);
  S.WriteStr(R.PrevName);
  S.Write(R.PrevIndex, SizeOf(Word) + SizeOf(TPoint) * 3);
  S.Write(Area, SizeOf(TArea) +
    SizeOf(Byte) + SizeOf(Integer) + SizeOf(Boolean));
end;

function THelpViewer.Valid(Command: Word): Boolean;
begin
  Valid := not Invalid and TScroller.Valid(Command);
end;

procedure THelpViewer.ChangeBounds(var Bounds: TRect);
var
  L, O,	X, KBL,	KBO, KBX, KKL, KKO, KKX: Integer;
  P, KBP, KKP: PParagraph;
begin
  DrawFlag := True;
  Topic^.GetOffset(Delta.Y + Cursor.Y +	1, Delta.X + Cursor.X +	1, P, O);
  if IsSelected	then
  begin
    Topic^.GetOffset(Area.KB + 1, Area.PB + 1, KBP, KBO);
    Topic^.GetOffset(Area.KK + 1, Area.PK + 1, KKP, KKO);
  end;
  TScroller.ChangeBounds(Bounds);
  Topic^.SetWidth(Size.X);
  Topic^.CalcNumLines;
  InitRefList;
  SetLimit(255, Topic^.NumLines + Size.Y);
  if P <> nil then Topic^.GetOffsetLine(L, X, P, O)
  else
  begin
    X := 0;
    L := Limit.Y - Size.Y;
  end;
  if IsSelected	then
  begin
    if KBP <> nil then Topic^.GetOffsetLine(KBL, KBX, KBP, KBO)
    else
    begin
      KBX := 0;
      KBL := 0;
    end;
    if KKP <> nil then Topic^.GetOffsetLine(KKL, KKX, KKP, KKO)
    else
    begin
      KKX := 0;
      KKL := 0;
    end;
    Highlight(KBL, KBX,	KKL, KKX);
  end;
  HideCursor;
  SetCursor(X -	Delta.X, L - Delta.Y);
  DrawFlag := False;
  DrawView;
end;

procedure THelpViewer.Draw;
var
  ChangeBrowser: Boolean;
  FC: Char;
  I, J,	L: Integer;
  KeyCount: Integer;
  Normal, Sel, Keyword,	SelKeyword, C: Byte;
  Pos: TPos;
  BP, Count: Integer;
  KeyPoint: TPoint;
  KeyLength: Byte;
  KeyRef: Integer;
  RefItem: PRefItem;
  B: TDrawBuffer;
  Line:	String;
begin
  if DrawFlag then Exit;
  Normal := GetColor(1);
  Sel := Byte(Application^.GetPalette^[HelpSelIndex]);
  Keyword := GetColor(2);
  SelKeyword :=	GetColor(3);
  Selected := 0;
  KeyCount := 0;
  KeyPoint.X :=	0;
  KeyPoint.Y :=	0;
  ChangeBrowser := False;
  if Topic^.GetNumCrossRefs > 0	then
  begin
    KeyCount :=	1;
    repeat
      RefItem := RefList^.At(KeyCount -	1);
      if RefItem^.Point.Y > Delta.Y then
      begin
	KeyPoint := RefItem^.Point;
	KeyLength := RefItem^.Length;
	KeyRef := RefItem^.Index;
	Break;
      end;
      Inc(KeyCount);
    until KeyCount > Topic^.GetNumCrossRefs;
  end;
  for I	:= 1 to	Size.Y do
  begin
    MoveChar(B,	' ', Normal, Size.X);
    Topic^.GetLine(I + Delta.Y, Line);
    MoveStr(B, System.Copy(Line, Delta.X+1, Size.X), Normal);
    while I + Delta.Y =	KeyPoint.Y do
    begin
      L	:= KeyLength;
      J	:= Delta.X - KeyPoint.X;
      if J > 0 then
      begin
	Dec(L, J);
	KeyPoint.X := Delta.X;
      end;
      FC := #0;
      if (Word(KeyRef) >= hcColor0) and (Word(KeyRef) <= hcColorFF) then
	C := Word(KeyRef) - hcColor0
      else if Word(KeyRef) = hcColorX then
      begin
	C := Normal;
	FC := ' ';
      end
      else if (Word(KeyRef) >= hcColor1) and (Word(KeyRef) <= hcColor5) then
	C := Byte(Application^.GetPalette^[ExtraBaseIndex +
	  Word(KeyRef) - hcColor1])
      else if (Delta.X + Cursor.X >= KeyPoint.X) and
	(Delta.X + Cursor.X < KeyPoint.X + L) and
	(Delta.Y + Cursor.Y = KeyPoint.Y - 1) then
      begin
	C := SelKeyword;
	Selected := KeyCount;
	if (TheHelpBrowser <> nil) and (State and sfHelpBrowser = 0) and
	   (PrevSelected <> Selected) then ChangeBrowser := True;
      end
      else C :=	Keyword;
      if L > 0 then MoveChar(B[KeyPoint.X - Delta.X], FC, C, L);
      Inc(KeyCount);
      if KeyCount <= Topic^.GetNumCrossRefs then
	GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef)
      else KeyPoint.Y := 0;
    end;
    if IsSelected and LineSelected(I + Delta.Y - 1) then
    begin
      GetPos(I + Delta.Y - 1, Pos);
      BP := Pos.AStart - Delta.X - 1;
      if BP < Size.X then
      begin
	if BP <	0 then BP := 0;
	Count := Pos.AnEnd - Delta.X - 1 - BP;
	if Count > Size.X - BP then Count := Size.X - BP;
	if Count > 0 then MoveChar(B[BP], #0, Sel, Count);
      end;
    end;
    WriteLine(0, I - 1, Size.X, 1, B);
  end;
  PrevSelected := Selected;
  if State and sfCursorVis = 0 then ShowCursor;
  if ChangeBrowser then ChangeHelpBrowserTopic;
end;

function THelpViewer.GetPalette: PPalette;
const
  P: String[Length(CHelpViewer)] = CHelpViewer;
begin
  GetPalette :=	@P;
end;

procedure THelpViewer.MakeSelectVisible;
var
  D: TPoint;
  KeyPoint: TPoint;
  KeyLength: Byte;
  KeyRef: Integer;
begin
  DrawFlag := True;
  GetCrossRef(Selected, KeyPoint, KeyLength, KeyRef);
  D := Delta;
  if KeyPoint.X	< D.X then D.X := KeyPoint.X;
  if KeyPoint.X	> D.X +	Size.X - KeyLength then
    if KeyLength >= Size.X then D.X := KeyPoint.X
    else D.X := KeyPoint.X - Size.X + KeyLength;
  if KeyPoint.Y	<= D.Y then D.Y	:= KeyPoint.Y -	1;
  if KeyPoint.Y	> D.Y +	Size.Y then D.Y	:= KeyPoint.Y -	Size.Y;
  if D.X <> Delta.X then ScrollTo(D.X, Delta.Y);
  if D.Y <> Delta.Y then FastScrollTo(D.Y);
  SetCursor(KeyPoint.X - Delta.X, KeyPoint.Y - Delta.Y - 1);
  DrawFlag := False;
end;

function THelpViewer.OtherHelpFileName: FNameStr;
begin
  OtherHelpFileName := ForceExtension(AddedSlash(
    JustPathName(HelpFile^.Name^)) +
    Trim(StUpcase(GetWordAtCursor)), 'HLP');
end;

function THelpViewer.SwitchToNewFile(const AName: FNameStr): Boolean;
var
  S: FNameStr;
begin
  with HelpFile^ do
  begin
    S := Name^;
    DoneHelpFile;
    InitHelpFile(AName);
    if Stream^.Status <> stOk then
    begin
      HelpErrorMsgBox(Stream^.Status, AName);
      DoneHelpFile;
      InitHelpFile(S);
      SwitchToNewFile := False;
    end
    else
    begin
      CurCtx := 0;
      SwitchToNewFile := True;
    end;
  end;
end;

procedure THelpViewer.SwitchToTopic(KeyRef: Integer; ExecPutPrev: Boolean);
var
  P: PHelpTopic;
  R: TPrevHelpRec;
begin
  P := HelpFile^.GetTopic(KeyRef);
  P^.SetWidth(Size.X);
  P^.CalcNumLines;
  if ExecutableTopic(P, ExecPutPrev) then
  begin
    if ExecPutPrev then
    begin
      GetPrevState(R);
      R.PrevIndex := KeyRef;
      PutHelp(R);
    end;
    ExecTopic(P);
    Exit;
  end;
  Unselect;
  DrawFlag := True;
  if Topic <> nil then Dispose(Topic, Done);
  Topic	:= P;
  InitRefList;
  CurCtx := KeyRef;
  SetLimit(Limit.X, Topic^.NumLines + Size.Y);
  HideCursor;
  GoCtrlPgUp;
  Selected := 0;
  PrevSel := 0;
  PrevSelected := 0;
  SearchStr := '';
  DrawFlag := False;
  PWindow(Owner)^.Frame^.DrawView;
end;

procedure THelpViewer.ExecTopic(P: PHelpTopic);
var
  S: String;
begin
  with ExecRec do
  begin
    P^.GetLine(2, S);
    Path := Trim(S);
    P^.GetLine(3, S);
    Params := Trim(S);
    FileMask :=	'';
    LineMask :=	'';
    Main := mnSwap;
    Setup := suLoadSnipper;
    Options := opLoadCOMMANDCOM;
    if OpeningBrowser then Options := Options or opInfoBit;
  end;
  Dispose(P, Done);
  PrepareExecEvent;
end;

function THelpViewer.SwitchTo(const R: TPrevHelpRec;
  PutPrev, ExecPutPrev: Boolean): Boolean;
var
  PR: TPrevHelpRec;
  Name, S: FNameStr;
begin
  if PutPrev then GetPrevState(PR);
  S := GetHelpName(R);
  if S <> HelpFile^.Name^ then
  begin
    Name := HelpFile^.Name^;
    if not SwitchToNewFile(S) then
    begin
      SwitchTo := False;
      Exit;
    end;
    if PutPrev then PR.PrevName := @Name;
  end;
  if PutPrev then PutHelp(PR);
  SwitchToTopic(R.PrevIndex, ExecPutPrev);
  SwitchTo := True;
end;

procedure THelpViewer.PutPrevHelp;
var
  R: TPrevHelpRec;
begin
  GetPrevState(R);
  PutHelp(R);
end;

procedure THelpViewer.HandleEvent(var Event: TEvent);

function OtherHelpFile: Boolean;
var
  R: TPrevHelpRec;
begin
  R.PrevName := nil;
  OtherHelpFile := GetHelpName(R) <> HelpFile^.Name^;
end;

function ShiftDown: Boolean;
begin
  ShiftDown :=
    (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
    (Event.KeyCode <> kbShiftTab) and (Event.KeyCode <> kbShiftIns) and
    (Event.KeyCode <> kbShiftF7);
end;

procedure SetPending(ACommand: Word);
begin
  Pending.What := evCommand;
  Pending.Command := ACommand;
  Pending.InfoPtr := Owner;
  Event.What := evNothing;
end;

procedure SelectAll;
begin
  if Topic^.NumLines = 0 then Exit;
  if MarkColumns then Message(
    Application, evCommand, cmToggleMarkMode, nil);
  Highlight(0, 1, Topic^.NumLines, 1);
  DrawView;
end;

var
  DoSearchFake: Boolean;
  Mouse: TPoint;
  R: TPrevHelpRec;
  KeyPoint: TPoint;
  KeyLength: Byte;
  KeyRef: Integer;
  SaveCtx: Word;
  S: String;
begin
  if Event.What = evKeyDown then
    if (Event.KeyCode = kbCtrlHome) or (Event.KeyCode = kbCtrlEnd) or
       (Event.KeyCode = kbCtrlPgUp) or (Event.KeyCode = kbCtrlPgDn) or
       (Event.CharCode in WordStarChars) then
      ConvertWSKey(WordStarKeys, Event);
  TScroller.HandleEvent(Event);
  case Event.What of
    evMouseDown: if MouseInView(Event.Where) then
      begin
	if Event.Buttons = mbRightButton then
	begin
	  repeat until not MouseEvent(Event, evMouseDown);
	  Popup(Event.Where);
	  Event.What := evNothing;
	  Exit;
	end;
	if GetShiftState and (kbLeftShift + kbRightShift) = 0 then Unselect;
	repeat
	  if MouseInView(Event.Where) then
	  begin
	    MakeLocal(Event.Where, Mouse);
	    while Delta.Y + Mouse.Y > Topic^.NumLines do Dec(Mouse.Y);
	    SetCursor(Mouse.X, Mouse.Y);
	    if GetShiftState and (kbLeftShift +	kbRightShift) <> 0 then
	      SelectOn(Delta.Y + Cursor.Y, Succ(Delta.X	+ Cursor.X))
	    else if not	IsSelected then
	      Highlight(Delta.Y	+ Cursor.Y, Succ(Delta.X + Cursor.X),
		Delta.Y	+ Cursor.Y, Succ(Delta.X + Cursor.X))
	    else if Event.What and evMouseMove <> 0 then
	      SelectOn(Delta.Y + Cursor.Y, Succ(Delta.X	+ Cursor.X));
	    DrawView;
	  end
	  else
	  begin
	    Mouse.X := 0;
	    Mouse.Y := 0;
	    MakeGlobal(Mouse, Mouse);
	    if Event.Where.X < Mouse.X then GoLeft;
	    if Event.Where.X > Mouse.X + Size.X	- 1 then GoRight;
	    if Event.Where.Y < Mouse.Y then GoUp;
	    if Event.Where.Y > Mouse.Y + Size.Y	- 1 then GoDown;
	    SelectOn(Delta.Y + Cursor.Y, Succ(Delta.X +	Cursor.X));
	    DrawView;
	  end;
	until not MouseEvent(Event, evMouseMove	+ evMouseAuto);
	if Event.Double	then
	begin
	  Event.What :=	evKeyDown;
	  Event.KeyCode	:= kbEnter;
	  HandleEvent(Event);
	end;
	if IsSelected and
	  (Area.KB = Area.KK) and (Area.PB = Area.PK) then Unselect;
	SearchStr := '';
	Event.What := evNothing;
      end;
    evKeyDown:
      begin
	if Cursor.X < 0	then ScrollTo(0, Delta.Y);
	if Cursor.X >= Size.X then
	  ScrollTo(Delta.X + Cursor.X - Size.X + 1, Delta.Y);
	if Cursor.Y < 0	then ScrollTo(Delta.X, Delta.Y + Cursor.Y);
	if Cursor.Y >= Size.Y then
	  ScrollTo(Delta.X, Delta.Y + Cursor.Y - Size.Y	+ 1);
	if (Event.CharCode in [#8, ^L, #32..#255]) and
	   (Event.KeyCode <> kbGrayPlus) and Search(Event.CharCode) then
	begin
	  DrawView;
	  Event.What := evNothing;
	  Exit;
	end;
	if ShiftDown then
	  if IsSelected	and
	    (((Delta.Y + Cursor.Y = Area.KB) and
	    (Delta.X + Cursor.X	+ 1 = Area.PB))	or
	    ((Delta.Y +	Cursor.Y = Area.KK) and
	    (Delta.X + Cursor.X	+ 1 = Area.PK))) then {}
	  else
	  begin
	    IsSelected := False;
	    Highlight(Delta.Y +	Cursor.Y, Succ(Delta.X + Cursor.X),
	      Delta.Y +	Cursor.Y, Succ(Delta.X + Cursor.X));
	  end;
	case CtrlToArrow(Event.KeyCode) of
	  kbDown:      GoDown;
	  kbUp:	       GoUp;
	  kbRight:     GoRight;
	  kbLeft:      GoLeft;
	  kbPgDn:      GoPgDn;
	  kbPgUp:      GoPgUp;
	  kbCtrlPgDn:  GoCtrlPgDn;
	  kbCtrlPgUp:  GoCtrlPgUp;
	  kbHome:      GoHome;
	  kbEnd:       GoEnd;
	  kbCtrlHome:  GoCtrlHome;
	  kbCtrlEnd:   GoCtrlEnd;
	  kbCtrlRight: GoCtrlRight;
	  kbCtrlLeft:  GoCtrlLeft;
	  kbCtrlDn:    GoCtrlDown;
	  kbCtrlUp:    GoCtrlUp;
	  kbTab:       SelectNext;
	  kbShiftTab:  SelectPrev;
	  kbGrayPlus:  ReturnAndSelect;
	  kbEnter:
	    if (Selected > 0) and (Selected <= Topic^.GetNumCrossRefs) then
	    begin
	      DoSearchFake := False;
	      GetCrossRef(Selected, KeyPoint, KeyLength, KeyRef);
	      if Word(KeyRef) = hcRefFile then
	      begin
		S := OtherHelpFileName;
		R.PrevName := @S;
		R.PrevIndex := Byte(GetShiftState and
		  (kbLeftShift + kbRightShift) <> 0);
	      end
	      else
	      begin
		if (KeyRef <> -1) and (Word(KeyRef) and $8000 <> 0) then
		begin
		  Word(KeyRef) := Word(KeyRef) and not $8000;
		  Topic^.GetLine(KeyPoint.Y, S);
		  S := System.Copy(S, KeyPoint.X + 1, KeyLength);
		  DoSearchFake := True;
		end;
		GetPrevState(R);
		R.PrevIndex := KeyRef;
	      end;
	      AddRecordToHistory(R, KeyPoint, KeyLength);
	      SwitchTo(R, True, True);
	      if DoSearchFake then SearchFakeCrossRef(S, KeyRef);
	    end;
	  kbEsc:
	    begin
	      SetPending(cmClose);
	      Exit;
	    end;
	  kbCtrlIns:
	    begin
	      SetPending(cmCopy);
	      Exit;
	    end;
	  kbCtrlF12:
	    begin
	      SetPending(cmCopyToMT);
	      Exit;
	    end;
	  kbShiftIns:
	    begin
	      SetPending(cmPaste);
	      Exit;
	    end;
	  kbF7:
	    begin
	      SetPending(cmFind);
	      Exit;
	    end;
	  kbShiftF7, $260C {^L}:
	    begin
	      SetPending(cmSearchAgain);
	      Exit;
	    end;
	  $1117 {^W}:
	    begin
	      SetPending(cmHelpHistory);
	      Exit;
	    end;
	  kbAltH: WriteTopicToHistory;
	  kbCtrl2: ToggleHelpBrowser;
	  else Exit;
	end;
	SearchStr := '';
	if ShiftDown then
	  SelectOn(Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
	if IsSelected and
	   (Area.KB = Area.KK) and (Area.PB = Area.PK) then Unselect;
	DrawView;
	Event.What := evNothing;
      end;
    evCommand:
      begin
	case Event.Command of
	  cmHelp:
	    if CurCtx <> hcNoContext then
	    begin
	      PutPrevHelp;
	      SwitchToTopic(hcNoContext, True);
	      DrawView;
	    end;
	  cmContents:
	    if (OtherHelpFile and (CurCtx <> 1)) or
	       (not OtherHelpFile and (CurCtx <> hcContents)) then
	    begin
	      PutPrevHelp;
	      if OtherHelpFile then SwitchToTopic(1, True)
	      else SwitchToTopic(hcContents, True);
	      DrawView;
	    end;
	  cmTopicSearch:
	    if (OtherHelpFile and (CurCtx <> 1)) or
	       (not OtherHelpFile and (CurCtx <> hcTopicSearch)) then
	    begin
	      PutPrevHelp;
	      S := GetWordAtCursor;
	      if OtherHelpFile then SwitchToTopic(1, True)
	      else SwitchToTopic(hcTopicSearch, True);
	      if S <> '' then
	      begin
		PutHelpSearchStr(S);
		SearchAndSelect(False);
	      end;
	      DrawView;
	    end;
	  cmPreviousTopic:
	    begin
	      GetHelp(R);
	      if SwitchTo(R, False, False) then SetPrevState(R, True);
	      DrawView;
	    end;
	  cmCopy: Copy;
	  cmPaste: Paste;
	  cmFind, cmTraceInto: FindDlg(False);
	  cmFindAll: FindDlg(True);
	  cmShowAllFound: FindAllDlg;
	  cmSearchAgain: Find(SearchData.MatchStr,
	    SearchData.Options or frFromCursor);
	  cmGoToLine: GoToTopic;
	  cmAltHelpName: SetAltHelpName;
	  cmSaveFocusedName: WriteTopicToHistory;
	  cmHelpHistory: HistoryWindow;
	  cmHelpBrowser: ToggleHelpBrowser;
	  cmSelectAll: SelectAll;
	  cmPopUp:
	    begin
	      Mouse.X := Size.X div 2;
	      Mouse.Y := 0;
	      MakeGlobal(Mouse, Mouse);
	      Popup(Mouse);
	    end;
	  else if (Event.Command = cmClose) and
	    (Owner^.State and sfModal <> 0) then
	  begin
	    Event.What := evNothing;
	    EndModal(cmClose);
	    Exit;
	  end
	  else Exit;
	end;
	Event.What := evNothing;
      end;
    evBroadcast:
      case Event.Command of
	cmToggleMarkMode: DrawView;
	cmGetWord:
	  begin
	    Event.What := evNothing;
	    Event.InfoPtr := @TopicSearchStr;
	  end;
	cmGetLine:
	  begin
	    Event.What := evNothing;
	    Topic^.GetLine(Delta.Y + Cursor.Y + 1, S);
	    if S = '' then Event.InfoPtr := nil
	    else Event.InfoPtr := @S;
	  end;
	cmTrackSource:
	  begin
	    FindAllTrack(Event.InfoInt);
	    Event.What := evNothing;
	  end;
	cmQuit: if (Event.InfoPtr <> nil) and
	  (TheHelpBrowser <> nil) and
	  (State and sfHelpBrowser = 0) then CloseHelpBrowser;
	cmlAPIChanged:
	  begin
	    lGetFileNameForChangedAPI(lAPIType(Event.InfoByte),
	      HelpFile^.Name^, S);
	    SaveCtx := CurCtx;
	    SwitchToNewFile(S);
	    CurCtx := SaveCtx;
	    PWindow(Owner)^.Frame^.DrawView;
	    if PWindow(Owner)^.Icon <> nil then
	      PWinIcon(PWindow(Owner)^.Icon)^.Update;
	  end;
      end;
  end;
end;

procedure THelpViewer.SetState(AState: Word; Enable: Boolean);
const
  FindAllCommands = [cmFindAll, cmShowAllFound];
begin
  TScroller.SetState(AState, Enable);
  if Enable and (AState = sfFocused) then
  begin
    EnableCommands(PasteCommands + MTPasteCommands +
      FindCommands + FindAllCommands + GoToTopicCommands);
    if IsSelected then EnableCommands(CopyCommands + MTCopyCommands)
    else DisableCommands(CopyCommands + MTCopyCommands);
  end
  else if not Enable and
    (((AState = sfActive) and GetState(sfExposed)) or
     (AState = sfExposed)) then DisableCommands(
      CopyCommands + PasteCommands + MTCommands +
      FindCommands + FindAllCommands + GoToTopicCommands);
end;

procedure THelpViewer.InitRefList;
var
  I: Integer;
begin
  DoneRefList;
  I := Topic^.GetNumCrossRefs;
  if I <> 0 then
  begin
    if MaxAvail <= LongMul(I, 4) + SafetyPool then I := 64;
    RefList := New(PRefList, Init(I, 64));
    FillRefList;
  end;
end;

procedure THelpViewer.DoneRefList;
begin
  if RefList <> nil then
  begin
    Dispose(RefList, Done);
    RefList := nil;
  end;
end;

procedure THelpViewer.FillRefList;
var
  OldOffset, CurOffset, Offset, ParaOffset, Line, NumRef, I: Integer;
  P: PParagraph;
  RefItem: PRefItem;
  S: String;
begin
  with Topic^ do
  begin
    P := Paragraphs;
    CurOffset := 0;
    ParaOffset := 0;
    Line := 0;
    I := 1;
    Offset := CrossRefs^[I].Offset;
    NumRef := GetNumCrossRefs;
    repeat
      OldOffset := ParaOffset + CurOffset;
      WrapText(P^.Text, P^.Size, CurOffset, P^.Wrap, S);
      Inc(Line);
      while ParaOffset + CurOffset >= Offset do
      begin
{	GetMem(RefItem, SizeOf(TRefItem));}
	GetMemUMB(RefItem, SizeOf(TRefItem));
	RefItem^.Point.X := Offset - OldOffset - 1;
	RefItem^.Point.Y := Line;
	RefItem^.Length := CrossRefs^[I].Length;
	RefItem^.Index := CrossRefs^[I].Ref;
	if not RefList^.CanInsert then
	begin
{	  FreeMem(RefItem, SizeOf(TRefItem));}
	  FreeMemUMB(RefItem, SizeOf(TRefItem));
	  Application^.OutOfMemory;
	  Exit;
	end;
	RefList^.Insert(RefItem);
	Inc(I);
	if I > NumRef then Break;
	Offset := CrossRefs^[I].Offset;
      end;
      if CurOffset >= P^.Size then
      begin
	Inc(ParaOffset, P^.Size);
	P := P^.Next;
	CurOffset := 0;
      end;
    until (P = nil) or (I > NumRef);
  end;
end;

procedure THelpViewer.GetCrossRef(Index: Integer; var KeyPoint: TPoint;
  var KeyLength: Byte; var KeyRef: Integer);
var
  RefItem: PRefItem;
begin
  RefItem := RefList^.At(Index - 1);
  KeyPoint := RefItem^.Point;
  KeyLength := RefItem^.Length;
  KeyRef := RefItem^.Index;
end;

function THelpViewer.GetWordAtCursor: String;
var
  X, Y, BPos, EPos: Integer;
  S: String;
begin
  X := Delta.X + Cursor.X + 1;
  Y := Delta.Y + Cursor.Y + 1;
  Topic^.GetLine(Y, S);
  if X <= Length(S) then
  begin
    EPos := X;
    while (EPos > 1) and (S[EPos] in WordDelims) do Dec(EPos);
    if not (S[EPos] in WordDelims) then
    begin
      BPos := EPos;
      while (BPos > 0) and not (S[BPos] in WordDelims) do Dec(BPos);
      while (EPos <= Length(S)) and not (S[EPos] in WordDelims) do Inc(EPos);
      S := System.Copy(S, BPos + 1, EPos - BPos - 1);
    end;
  end;
  GetWordAtCursor := S;
end;

procedure WriteRecToHistory(const R: TPrevHelpRec; const ATitle: String);
var
  B: Byte;
  Name: FNameStr;
  S: String;
begin
  if (R.PrevName = nil) and (ATitle <> '') then Name := ''
  else Name := GetHelpName(R);
  S := ATitle + #$FF + Name + #$FF;
  if Length(S) <= 222 then
  begin
    B := SizeOf(TPrevHelpRec) - SizeOf(PString);
    Move(R.PrevIndex, S[Length(S) + 1], B);
    FillChar(S[Length(S) + 3], 8, 0);
    Inc(S[0], B);
    HistoryAdd(HelpHistoryId, S, False);
  end;
end;

procedure THelpViewer.AddRecordToHistory(const R: TPrevHelpRec;
  KeyPoint: TPoint; KeyLength: Byte);
var
  S: String;
begin
  if State and sfHelpBrowser <> 0 then Exit;
  Topic^.GetLine(KeyPoint.Y, S);
  WriteRecToHistory(R, Trim(System.Copy(S, KeyPoint.X + 1, KeyLength)));
end;

procedure THelpViewer.WriteTopicToHistory;
var
  R: TPrevHelpRec;
  S: String;
begin
  GetPrevState(R);
  S := Trim(GetWordAtCursor);
  WriteRecToHistory(R, S);
end;

procedure THelpViewer.FastScrollTo(Y: Integer);
var
  OldValue: Integer;
begin
  with VScrollBar^ do
  begin
    OldValue :=	Value;
    if Y < Min then Value := Min
    else if Y >	Max then Value := Max
    else Value := Y;
    if Value <>	OldValue then DrawView;
    Delta.Y := Value;
  end;
end;

procedure THelpViewer.GoRight;
begin
  if Delta.X + Cursor.X	= Limit.X - 1 then Exit;
  SetCursor(Cursor.X + 1, Cursor.Y);
  DrawFlag := True;
  if Cursor.X =	Size.X then ScrollTo(Delta.X + 1, Delta.Y);
  DrawFlag := False;
end;

procedure THelpViewer.GoLeft;
begin
  if Delta.X + Cursor.X	= 0 then Exit;
  SetCursor(Cursor.X - 1, Cursor.Y);
  DrawFlag := True;
  if Cursor.X <	0 then ScrollTo(Delta.X	- 1, Delta.Y);
  DrawFlag := False;
end;

procedure THelpViewer.GoDown;
begin
  if Delta.Y + Cursor.Y	>= Topic^.NumLines then	Exit;
  if Cursor.Y =	Size.Y - 1 then	FastScrollTo(Delta.Y + 1)
  else SetCursor(Cursor.X, Cursor.Y + 1);
end;

procedure THelpViewer.GoUp;
begin
  if Delta.Y + Cursor.Y	= 0 then Exit;
  if Cursor.Y =	0 then FastScrollTo(Delta.Y - 1)
  else SetCursor(Cursor.X, Cursor.Y - 1);
end;

procedure THelpViewer.GoPgDn;
begin
  if Delta.Y + Cursor.Y	+ Size.Y >= Topic^.NumLines then GoCtrlPgDn
  else FastScrollTo(Delta.Y + Size.Y - 1);
end;

procedure THelpViewer.GoPgUp;
begin
  if Delta.Y = 0 then
  begin
    ScrollTo(0,	0);
    SetCursor(0, 0);
  end
  else FastScrollTo(Delta.Y - Size.Y + 1);
end;

procedure THelpViewer.GoCtrlPgDn;
begin
  DrawFlag := True;
  if Delta.Y < Topic^.NumLines - Size.Y	+ 1 then
    ScrollTo(0,	Topic^.NumLines	- Size.Y + 1);
  DrawFlag := False;
  SetCursor(0, Topic^.NumLines - Delta.Y);
end;

procedure THelpViewer.GoCtrlPgUp;
begin
  DrawFlag := True;
  ScrollTo(0, 0);
  DrawFlag := False;
  SetCursor(0, 0);
end;

procedure THelpViewer.GoHome;
begin
  DrawFlag := True;
  ScrollTo(0, Delta.Y);
  DrawFlag := False;
  SetCursor(0, Cursor.Y);
end;

procedure THelpViewer.GoEnd;
var
  I: Integer;
  S: String;
begin
  GetXString(Delta.Y + Cursor.Y + 1, S);
  TrailTrim(S);
  I := Length(S);
  if (I	>= Delta.X) and	(I <= Delta.X +	Size.X - 1) then
    SetCursor(I	- Delta.X, Cursor.Y)
  else
  begin
    DrawFlag :=	True;
    ScrollTo(0,	Delta.Y);
    SetCursor(I, Cursor.Y);
    if Cursor.X	>= Size.X then
      ScrollTo(Cursor.X - Size.X + 1, Delta.Y);
    DrawFlag :=	False;
  end;
end;

procedure THelpViewer.GoCtrlEnd;
begin
  Cursor.Y := Size.Y - 1;
  while	Delta.Y	+ Cursor.Y > Topic^.NumLines do	Dec(Cursor.Y);
end;

procedure THelpViewer.GoCtrlHome;
begin
  SetCursor(Cursor.X, 0);
end;

procedure THelpViewer.GoCtrlRight;
var
  S: String;
begin
  GetXString(Delta.Y + Cursor.Y + 1, S);
  TrailTrim(S);
  if Delta.X + Cursor.X	>= Byte(S[0]) then
  begin
    GoDown;
    GoHome;
  end
  else if GetShiftState and (kbAltShift + kbCtrlShift) =
    kbAltShift + kbCtrlShift then
  begin
    while (Delta.X + Cursor.X <	Byte(S[0])) and
      (S[Delta.X + Cursor.X + 1] in WordDelims) do GoRight;
    while (Delta.X + Cursor.X <	Byte(S[0])) and
      not (S[Delta.X + Cursor.X + 1] in WordDelims) do GoRight;
  end
  else
  begin
    while (Delta.X + Cursor.X <	Byte(S[0])) and
      not (S[Delta.X + Cursor.X + 1] in WordDelims) do GoRight;
    while (Delta.X + Cursor.X <	Byte(S[0])) and
      (S[Delta.X + Cursor.X + 1] in WordDelims) do GoRight;
  end;
end;

procedure THelpViewer.GoCtrlLeft;
var
  S: String;
begin
  GetXString(Delta.Y + Cursor.Y + 1, S);
  TrailTrim(S);
  if Delta.X + Cursor.X	= 0 then
  begin
    GoUp;
    GoEnd;
  end
  else if GetShiftState and (kbAltShift + kbCtrlShift) =
    kbAltShift + kbCtrlShift then
  begin
    if Delta.X + Cursor.X > Byte(S[0]) then GoEnd
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
    if Delta.X + Cursor.X > Byte(S[0]) then GoEnd;
    while (Delta.X + Cursor.X >	0) and
      (S[Delta.X + Cursor.X] in WordDelims) do GoLeft;
    while (Delta.X + Cursor.X >	0) and
      not (S[Delta.X + Cursor.X] in WordDelims) do GoLeft;
  end;
end;

procedure THelpViewer.GoCtrlDown;
var
  I: Integer;
begin
  I := CurCtx;
  with HelpFile^.Index^ do
  begin
    while (I < Size) and ((Position(I) = -1) or
      (Position(I) = Position(CurCtx))) do Inc(I);
    if I < Size then SwitchToTopic(I, False);
  end;
end;

procedure THelpViewer.GoCtrlUp;
var
  I: Integer;
begin
  I := CurCtx;
  with HelpFile^.Index^ do
  begin
    while (I >= 0) and ((Position(I) = -1) or
      (Position(I) = Position(CurCtx))) do Dec(I);
    if I >= 0 then SwitchToTopic(I, False);
  end;
end;

procedure THelpViewer.GoToTopic;
const
  GoToTopicData: String[5] = '';
var
  W: Word;
  D: PDialog;
  Control: PView;
  R: TRect;
  S: String;
begin
  R.Assign(0, 0, 38, 7);
  D := New(PDialog, Init(R, 'Go to topic'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcGoToTopic;
    R.Assign(25, 2, 32, 3);
    Control := New(PCInputLine, Init(R, 5, 0, $FFFF));
    Insert(Control);
    StandardHistory(Control, GoToLineNumHistoryID);
    R.Assign(2, 2, 25, 3);
    Insert(New(PLabel, Init(R, '~E~nter new topic index', Control)));

    StandardButtonRow(D, True);
  end;
  if (Application^.ExecuteDialog(D, @GoToTopicData, False) <> cmCancel) and
    Str2Word(GoToTopicData, W) then
  begin
    PutPrevHelp;
    SwitchToTopic(W, False);
    DrawView;
  end;
end;

procedure THelpViewer.SelectNext;
var
  NumRef, KeyCount, Count: Integer;
  KeyPoint: TPoint;
  KeyLength: Byte;
  KeyRef: Integer;
begin
  NumRef := Topic^.GetNumCrossRefs;
  if NumRef = 0	then Exit;
  if Selected <> 0 then
    if Selected	= NumRef then KeyCount := 1
    else KeyCount := Selected +	1
  else
  begin
    KeyCount :=	0;
    repeat
      Inc(KeyCount);
      GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
      if Word(KeyRef) >= hcColor1 then KeyPoint.Y := -MaxInt;
    until (KeyCount > NumRef) or
      ((KeyPoint.Y = Delta.Y + Cursor.Y + 1) and
       (KeyPoint.X > Delta.X + Cursor.X)) or
      ((KeyPoint.Y > Delta.Y + Cursor.Y	+ 1));
    if KeyCount	> NumRef then KeyCount := 1;
  end;
  Count := 0;
  repeat
    GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
    if Word(KeyRef) < hcColor1 then
    begin
      Selected := KeyCount;
      MakeSelectVisible;
      Exit;
    end;
    Inc(Count);
    Inc(KeyCount);
    if KeyCount	> NumRef then KeyCount := 1;
  until Count >= NumRef;
end;

procedure THelpViewer.SelectPrev;
var
  NumRef, KeyCount, Count: Integer;
  KeyPoint: TPoint;
  KeyLength: Byte;
  KeyRef: Integer;
begin
  NumRef := Topic^.GetNumCrossRefs;
  if NumRef = 0	then Exit;
  if Selected <> 0 then
    if Selected	= 1 then KeyCount := NumRef
    else KeyCount := Selected -	1
  else
  begin
    KeyCount :=	0;
    repeat
      Inc(KeyCount);
      GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
      if Word(KeyRef) >= hcColor1 then KeyPoint.Y := -MaxInt;
    until (KeyCount > NumRef) or
      ((KeyPoint.Y = Delta.Y + Cursor.Y + 1) and
       (KeyPoint.X > Delta.X + Cursor.X)) or
      ((KeyPoint.Y > Delta.Y + Cursor.Y	+ 1));
    if KeyCount	> NumRef then KeyCount := 1;
    if KeyCount	= 1 then KeyCount := NumRef
    else Dec(KeyCount);
  end;
  Count := 0;
  repeat
    GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
    if Word(KeyRef) < hcColor1 then
    begin
      Selected := KeyCount;
      MakeSelectVisible;
      Exit;
    end;
    Inc(Count);
    if KeyCount	= 1 then KeyCount := NumRef
    else Dec(KeyCount);
  until Count >= NumRef;
end;

procedure THelpViewer.GetPrevState(var R: TPrevHelpRec);
begin
  with R do
  begin
    PrevName := nil;
    if GetHelpName(R) <> HelpFile^.Name^ then
      PrevName := HelpFile^.Name;
    PrevIndex := CurCtx;
    PrevDelta := Delta;
    PrevCursor := Cursor;
    PrevSize :=	Owner^.Size;
    PrevOrg := Owner^.Origin;
  end;
end;

procedure THelpViewer.SetPrevState(const R: TPrevHelpRec;
  KeepOrgSize: Boolean);
var
  ResizeBack: Boolean;
  B, O: TRect;
begin
  DrawFlag := True;
  ResizeBack := False;
  with R do
  begin
    if (Owner <> nil) and (Longint(PrevSize) <> 0) then
    begin
      if KeepOrgSize then
      begin
	Owner^.GetBounds(O);
	Owner^.Owner^.Lock;
	ResizeBack := True;
      end;
      B.Assign(PrevOrg.X, PrevOrg.Y,
	PrevOrg.X + PrevSize.X, PrevOrg.Y + PrevSize.Y);
      Owner^.Locate(B);
    end;
    Delta.X := PrevDelta.X;
    Delta.Y := PrevDelta.Y;
    ScrollTo(PrevDelta.X, PrevDelta.Y);
    SetCursor(PrevCursor.X, PrevCursor.Y);
  end;
  if HelpSearchStr <> nil then SearchAndSelect(False);
  if ResizeBack then
  begin
    Owner^.Locate(O);
    Message(@Self, evKeyDown, 0, nil);
    Owner^.Owner^.Unlock;
  end;
  DrawFlag := False;
end;

function THelpViewer.Search(AChar: Char): Boolean;
var
  KeyCount: Integer;
  KeyPoint: TPoint;
  KeyLength: Byte;
  KeyRef: Integer;
  P, AP: Byte;
  S, KS: String;
begin
  Search := False;
  if (AChar = #8) and (SearchStr = '') then
  begin
    Pending.What := evKeyDown;
    Pending.KeyCode := kbAltF1;
    Exit;
  end;
  if Topic^.GetNumCrossRefs > 0	then
  begin
    S := '';
    if AChar = #8 then
    begin
      Dec(SearchStr[0]);
      if SearchStr = '' then
      begin
	GoLeft;
	Exit;
      end;
      KeyCount := 0;
    end
    else if AChar = ^L then
      if SearchStr = '' then Exit else KeyCount := Selected
    else
    begin
      S := TPString.Upcase(AChar);
      if SearchStr = '' then KeyCount := 0 else KeyCount := Selected - 1
    end;
    S := SearchStr + S;
    P := 0;
    repeat
      Inc(KeyCount);
      if KeyCount > Topic^.GetNumCrossRefs then Break;
      GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
      if Word(KeyRef) >= hcColor1 then Continue;
      Topic^.GetLine(KeyPoint.Y, KS);
      KS := StUpcase(System.Copy(KS, KeyPoint.X + 1, KeyLength));
      P := Pos(S, KS);
      if (P > 1) then
      begin
	AP := P - 1;
	P := Pos(S, TrimLead(KS));
      end
      else AP := 0;
    until P = 1;
    if P = 1 then
    begin
      SearchStr	:= S;
      DrawFlag := True;
      HideCursor;
      if Selected <> KeyCount then
      begin
	Selected := KeyCount;
	MakeSelectVisible;
      end
      else while Delta.X + Cursor.X > KeyPoint.X do GoLeft;
      while (Delta.X + Cursor.X	< KeyPoint.X + KeyLength - 1) and
	(Delta.X + Cursor.X < KeyPoint.X + Length(S) + AP) do GoRight;
      DrawFlag := False;
      Search := True;
    end;
  end;
end;

procedure THelpViewer.SearchAndSelect(PutPrev: Boolean);
var
  DoSearchFake: Boolean;
  B: Byte;
  I, SaveSel: Integer;
  P: TPoint;
  R: TPrevHelpRec;
  S: String;
begin
  TopicSearchStr := HelpSearchStr^;
  PutHelpSearchStr('');
  for B := 1 to Length(TopicSearchStr) do
    if not Search(TopicSearchStr[B]) then Exit;
  if (Selected > 0) and (Selected <= Topic^.GetNumCrossRefs) then
  begin
    DoSearchFake := False;
    GetCrossRef(Selected, P, B, I);
    if (B = Length(TopicSearchStr)) or (TopicSearchStr = ^L) then
    begin
      if Word(I) = hcRefFile then
      begin
	if not SwitchToNewFile(OtherHelpFileName) then Exit;
	I := 0;
      end
      else if (I <> -1) and (Word(I) and $8000 <> 0) then
      begin
	Word(I) := Word(I) and not $8000;
	Topic^.GetLine(P.Y, S);
	S := System.Copy(S, P.X + 1, B);
	DoSearchFake := True;
      end;
      SaveSel := Selected;
      GetPrevState(PrevRec);
      if PutPrev then PutHelp(PrevRec);
      R := PrevRec;
      R.PrevIndex := I;
      AddRecordToHistory(R, P, B);
      Delta.X := 0;
      Delta.Y := 0;
      SwitchToTopic(I, True);
      PrevSel := SaveSel;
      if DoSearchFake then SearchFakeCrossRef(S, I);
    end;
  end;
end;

function THelpViewer.SearchFakeCrossRef(const S: String;
  Index: Integer): Boolean;
var
  KeyCount: Integer;
  KeyPoint: TPoint;
  KeyLength: Byte;
  KeyRef: Integer;
  KS: String;
begin
  SearchFakeCrossRef := False;
  if Topic^.GetNumCrossRefs > 0	then
  begin
    KeyCount := 0;
    repeat
      Inc(KeyCount);
      if KeyCount > Topic^.GetNumCrossRefs then Exit;
      GetCrossRef(KeyCount, KeyPoint, KeyLength, KeyRef);
      if Word(Index) <> Word(KeyRef) and not $8000 then
      begin
	Topic^.GetLine(KeyPoint.Y, KS);
	if System.Copy(KS, KeyPoint.X + 1, KeyLength) = S then Break;
      end;
    until False;
    if Word(KeyRef) = hcColorX then KeyPoint.X := 0
    else if KeyPoint.Y <> 0 then Dec(KeyPoint.Y);
    DrawFlag := True;
    HideCursor;
    if (KeyPoint.Y < Delta.Y) or (KeyPoint.Y >= Delta.Y + Size.Y) then
      FastScrollTo(KeyPoint.Y - Size.Y div 2);
    SetCursor(0, KeyPoint.Y - Delta.Y);
    while Delta.X + Cursor.X < KeyPoint.X do GoRight;
    DrawFlag := False;
    SearchFakeCrossRef := True;
  end;
end;

procedure THelpViewer.ReturnAndSelect;
var
  SaveSel: Integer;
begin
  if PrevSel <> 0 then
  begin
    SaveSel := PrevSel;
    PutPrevHelp;
    SwitchToTopic(PrevRec.PrevIndex, True);
    SetPrevState(PrevRec, False);
    SearchStr := GetWordAtCursor;
    UpcaseSt(SearchStr);
    PutHelpSearchStr(^L);
    Selected := SaveSel;
    SearchAndSelect(False);
    DrawView;
  end;
end;

procedure THelpViewer.Highlight(AKB: Integer; APB: Byte;
  AKK: Integer;	APK: Byte);
begin
  if not IsSelected then
  begin
    SelectFromX	:= APB;
    SelectFromY	:= AKB;
  end;
  with Area do
  begin
    KB := AKB; PB := APB; KK :=	AKK; PK	:= APK;
  end;
  IsSelected :=	(AKB < AKK) or ((AKB = AKK) and	(APB <=	APK));
  if IsSelected	then EnableCommands(CopyCommands + MTCopyCommands)
  else DisableCommands(CopyCommands + MTCopyCommands);
end;

procedure THelpViewer.Unselect;
begin
  Highlight(0, 0, 0, 0);
  SelectFromX := 0; SelectFromY	:= 0;
  IsSelected :=	False;
  DisableCommands(CopyCommands + MTCopyCommands);
end;

procedure THelpViewer.SelectOn(CurY: Integer; CurX: Byte);
begin
  if (CurY = SelectFromY) and (CurX = SelectFromX) then
    Highlight(CurY, CurX, CurY,	CurX)
  else
  if (CurY < SelectFromY) or
     ((CurY = SelectFromY) and (CurX < SelectFromX)) then
    Highlight(CurY, CurX, SelectFromY, SelectFromX)
  else Highlight(SelectFromY, SelectFromX, CurY, CurX);
end;

function THelpViewer.LineSelected(AnIndex: Integer): Boolean;
begin
  LineSelected := IsSelected and
    ((AnIndex >= Area.KB) and (AnIndex <= Area.KK));
end;

procedure THelpViewer.GetPos(AnIndex: Integer; var APos: TPos);
begin
  if MarkColumns then
  begin
    if Area.PB > Area.PK then
    begin
      APos.AStart := Area.PK;
      APos.AnEnd := Area.PB;
    end
    else
    begin
      APos.AStart := Area.PB;
      APos.AnEnd := Area.PK;
    end;
  end
  else
  begin
    if AnIndex = Area.KB then APos.AStart := Area.PB
    else APos.AStart :=	1;
    if AnIndex = Area.KK then APos.AnEnd := Area.PK
    else APos.AnEnd := SizeOf(String);
  end;
end;

procedure THelpViewer.GetXString(AnIndex: Integer; var S: String);
var
  KeyCount: Integer;
  RefItem: PRefItem;
begin
  Topic^.GetLine(AnIndex, S);
  if Topic^.GetNumCrossRefs > 0	then
  begin
    KeyCount :=	1;
    repeat
      RefItem := RefList^.At(KeyCount -	1);
      if (RefItem^.Point.Y = AnIndex) and
	 (Word(RefItem^.Index) = hcColorX) then
	FillChar(S[RefItem^.Point.X + 1], RefItem^.Length, ' ');
      Inc(KeyCount);
    until (KeyCount > Topic^.GetNumCrossRefs) or
      (RefItem^.Point.Y > AnIndex);
  end;
end;

function THelpViewer.GetSelectedString(AnIndex:	Integer): String;
var
  Pos: TPos;
  S: String;
begin
  GetXString(AnIndex + 1, S);
  TrailTrim(S);
  GetPos(AnIndex, Pos);
  GetSelectedString := System.Copy(S, Pos.AStart, Pos.AnEnd - Pos.AStart);
end;

procedure THelpViewer.Copy;
var
  I, SaveCount:	Integer;
  SaveArea: TArea;
  S: String;
begin
  if DiskClipStream = nil then Exit;
  DrawClipCopyStatus;
  SetExpandClipAreaFlag;
  SaveCount := ClipLines^.Count;
  SaveArea := Area;
  if not IsSelected then
  begin
    I := Delta.Y + Cursor.Y;
    GetXString(I + 1, S);
    Area.KB := I;
    Area.KK := I;
    Area.PB := 1;
    I := Length(S);
    if I < 255 then Inc(I);
    Area.PK := I;
  end;
  I := Area.KB;
  while	I <= Area.KK do
  begin
    S := GetSelectedString(I);
    PutClipLine(S);
    Inc(I);
  end;
  SetOrExpandClipArea(SaveCount, Length(S) + 1);
  if MarkColumns then SetArea(ClipArea, ClipArea^.KB, ClipArea^.PB,
    ClipArea^.KK, Area.PK - Area.PB + 1);
  Area := SaveArea;
  Message(Application, evBroadcast, cmUpdateViews, nil);
end;

procedure THelpViewer.Paste;
var
  S: String;
begin
  Message(Application, evBroadcast, cmUpdateViews, nil);
  GetClipLine(ClipArea^.KB, S);
  TrimSt(S);
  if S <> '' then
  begin
    PutHelpSearchStr(S);
    SearchAndSelect(True);
    DrawView;
  end;
end;

procedure THelpViewer.Find(const Match: String; AOptions: Word);
var
  B, Aborted, WasSearchingAll: Boolean;
  FoundPos, CutLen: Byte;
  I, ILo, NumTopics, FoundTopic, FoundLine: Integer;
  L, PL: Longint;
  RegExpr: Pointer;
  P: PHelpTopic;
  PR: PFindAllItem;
  Params: Array[0..1] of Longint;
  SaveArea: TArea;
  SS, SubS, Str, RGS: String;

procedure FindPos;
begin
  if AOptions and frCaseSensitive = 0 then UpcaseSt(Str);
  if (AOptions and frRegExp <> 0) and (RegExpr <> nil) then
  begin
    RGS := RegSearch(RegExpr, Str);
    if RGS <> '' then SubS := RGS;
  end;
  if AOptions and frWholeWordsOnly <> 0 then
    FoundPos := WordPos(SubS, Str, WordDelims, False)
  else FoundPos := Pos(SubS, Str);
  if FoundPos <> 0 then Inc(FoundPos, CutLen - 1);
end;

procedure SearchThroughTopic;
var
  II: Integer;
begin
  if (AOptions and frFromCursor <> 0) and (I = CurCtx) then
    ILo := Delta.Y + Cursor.Y + 1
  else ILo := 1;
  for II := ILo to P^.NumLines do
  begin
    P^.GetLine(II, Str);
    TrimTrail(Str);
    if (AOptions and frFromCursor <> 0) and
       (I = CurCtx) and (II = ILo) then
    begin
      Delete(Str, 1, Delta.X + Cursor.X + 1);
      CutLen := Delta.X + Cursor.X + 2;
    end
    else CutLen := 1;
    if Str <> '' then
    begin
      FindPos;
      if FoundPos <> 0 then
      begin
	if SearchingAll and FindAllList^.CanInsert then
	begin
	  P^.GetLine(II, Str);
	  TrimSt(Str);
{	  GetMem(PR, SizeOf(TFindAllItem));}
	  GetMemUMB(PR, SizeOf(TFindAllItem));
	  FillChar(PR^, SizeOf(TFindAllItem), 0);
{
	  PR^.Line := NewStr(Str);
	  PR^.Rec.PrevName := NewStr(HelpFile^.Name^);
}
	  PR^.Line := NewStrUMB(Str);
	  PR^.Rec.PrevName := NewStrUMB(HelpFile^.Name^);
	  PR^.Rec.PrevIndex := I;
	  FindAllList^.Insert(PR);
	end
	else FoundLine := II - 1;
	Break;
      end;
    end;
  end;
end;

begin
  if Match = '' then Exit;
  DrawStatusLine(SearchMsg);
  SubS := Match;
  if AOptions and frCaseSensitive = 0 then UpcaseSt(SubS);
  if AOptions and frRegExp <> 0 then RegExpr := RegCompile(SubS)
  else RegExpr := nil;
  if AOptions and frFromCursor <> 0 then ILo := CurCtx
  else ILo:= 0;
  NumTopics := HelpFile^.Index^.Size;
  while (NumTopics >= 0) and
    (HelpFile^.Index^.Position(NumTopics) = -1) do Dec(NumTopics);
  Params[1] := NumTopics;
  FoundPos := 0;
  FoundTopic := CurCtx;
  Aborted := False;
  B := False;
  PL := -1;
  for I := ILo to NumTopics do
  begin
    if EscPressed then
    begin
      Aborted := True;
      Break;
    end;
    if (AOptions and frSelectedText <> 0) or (I = CurCtx) then
    begin
      L := HelpFile^.Index^.Position(CurCtx);
      if (L = -1) or (L = PL) then Continue;
      PL := L;
      P := Topic;
    end
    else
    begin
      Params[0] := I;
      SS := SearchMsg;
      SS[Length(SS)] := ':';
      FormatStr(Str, SS + ' %d/%d', Params);
      LogEvent := 0;
      DrawStatusLine(Str);
      L := HelpFile^.Index^.Position(I);
      if (L = -1) or (L = PL) then Continue;
      PL := L;
      HelpFile^.Stream^.Seek(L);
      P := PHelpTopic(HelpFile^.Stream^.Get);
      if (HelpFile^.Stream^.Status <> stOk) or (P = nil) then
      begin
	if P <> nil then Dispose(P, Done);
	HelpFile^.Stream^.Reset;
	Aborted := True;
	MessageBox(^C'Error reading help file'#13^C'|' +
	  HelpFile^.Name^ + '|.', nil, mfError + mfOkButton);
	Break;
      end;
      P^.SetWidth(Size.X);
      P^.CalcNumLines;
    end;
    if not ExecutableTopic(P, B) then SearchThroughTopic;
    if AOptions and frSelectedText <> 0 then Break;
    if I <> CurCtx then Dispose(P, Done);
    if FoundPos <> 0 then
      if SearchingAll then FoundPos := 0
      else
      begin
	FoundTopic := I;
	Break;
      end;
  end;
  RegFree(RegExpr);
  WasSearchingAll := SearchingAll;
  SearchingAll := False;
  if Aborted then
    if WasSearchingAll then FindAllList^.FreeAll else
  else if WasSearchingAll and (FindAllList^.Count <> 0) then
  begin
    FindAllData := SearchData;
    FindAllDlg;
  end
  else if FoundPos = 0 then SearchStringNotFoundMsgBox
  else
  begin
    if FoundTopic <> CurCtx then
    begin
      PutPrevHelp;
      SwitchToTopic(FoundTopic, True);
    end;
    DrawFlag := True;
    HideCursor;
    if FindAllDlgInUse and (Size.Y > 3) then FastScrollTo(FoundLine - 2)
    else if (FoundLine < Delta.Y) or (FoundLine >= Delta.Y + Size.Y) then
      FastScrollTo(FoundLine);
    SetCursor(Cursor.X, FoundLine - Delta.Y);
    GoHome;
    for I := 1 to FoundPos + Length(SubS) - 1 do GoRight;
    for I := 1 to Length(SubS) do GoLeft;
    SaveArea := Area;
    HighLight(Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1,
      Delta.Y + Cursor.Y, Delta.X + Cursor.X + Length(SubS) + 1);
    DrawFlag := False;
    DrawView;
    HighLight(SaveArea.KB, SaveArea.PB, SaveArea.KK, SaveArea.PK);
  end;
end;

procedure THelpViewer.FindDlg(All: Boolean);
var
  C: Word;
  D: PDialog;
begin
  if EditOptions and eoFindTextAtCursor <> 0 then
    SearchData.MatchStr := GetWordAtCursor
  else SearchData.MatchStr := HistoryStr(FindHistoryID, 0);
  D := LoadFindDialog(All, False, frBackward);
  ReplaceFindClusterText(D, 4, 'C~u~rrent topic only');
  C := Application^.ExecuteDialog(D, @SearchData, False);
  if C = cmYes then
  begin
    FindAllList^.FreeAll;
    SearchingAll := True;
  end;
  if C <> cmCancel then Find(SearchData.MatchStr, SearchData.Options);
end;

procedure THelpViewer.FindAllDlg;
var
  C: Word;
  P: Pointer;
begin
  P := @Self;
  FindAllDlgInUse := True;
  C := Application^.ExecuteDialog(
    HelpFindAllDialog(FindAllList^.Count), @P, False);
  FindAllDlgInUse := False;
  if (C <> cmCancel) and
     (FindAllList^.Count <> 0) then FindAllTrack(Integer(P));
end;

procedure THelpViewer.FindAllTrack(Item: Integer);
var
  P: PFindAllItem;
begin
  P := FindAllList^.At(Item);
  if SwitchTo(P^.Rec, True, True) then
    Find(FindAllData.MatchStr, FindAllData.Options or frSelectedText);
end;

type
  PHelpHistoryViewer = ^THelpHistoryViewer;
  THelpHistoryViewer = object(THistoryViewer)
    function GetCopyText(Item: Integer; MaxLen: Integer): String; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
  end;

  PHelpHistoryWindow = ^THelpHistoryWindow;
  THelpHistoryWindow = object(TSpecialHistWindow)
    procedure InitViewer(HistoryId: Word); virtual;
  end;

function THelpHistoryViewer.GetCopyText(Item: Integer;
  MaxLen: Integer): String;
var
  S: String;
begin
  S := Inherited GetCopyText(Item, MaxLen);
  Dec(S[0], 20 - Byte(S[1] = #$FF));
  TrimSt(S);
  GetCopyText := S;
end;

function THelpHistoryViewer.GetText(Item: Integer; MaxLen: Integer): String;
var
  I: Integer;
  S, C: String;
begin
  S := Inherited GetText(Item, MaxLen);
  I := Pos(#$FF, S);
  if I = 0 then GetText := ''
  else
  begin
    C := Copy(S, 1, I - 1);
    Delete(S, 1, I);
    I := Pos(#$FF, S);
    S[0] := Char(I - 1);
    if S <> '' then
    begin
      if Length(C) <= 2 then I := 3 else I := 6;
      Dec(MaxLen, Length(C) + I);
      if MaxLen < 12 then MaxLen := 12;
      S := TrimmedName(S, MaxLen);
      if Length(C) > 2 then S := ' (' + S + ')';
    end;
    GetText := C + S;
  end;
end;

procedure THelpHistoryWindow.InitViewer(HistoryId: Word);
var
  R: TRect;
begin
  GetExtent(R);
  R.Grow(-1,-1);
  Viewer := New(PHelpHistoryViewer, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    HistoryId));
  Insert(Viewer);
  Viewer^.FocusItem(0);
end;

procedure THelpViewer.HistoryWindow;
var
  W: PHelpHistoryWindow;
  R: TRect;
  S: String[15];
begin
  S := 'Help history';
  GetHistWinBounds(HelpHistoryID, S, R);
  if R.B.X - R.A.X >= 44 then Dec(R.B.X, 20);
  W := New(PHelpHistoryWindow, Init(R, HelpHistoryID));
  DisposeStr(W^.Title);
  W^.Title := NewStr(S);
  W^.Options := W^.Options or ofCentered;
  W^.HelpCtx := hcReopenHelp;
  if Application^.ValidView(W) <> nil then
  begin
    if Owner^.Owner^.ExecView(W) = cmOk then
    begin
      PutPrevHelp;
      Message(Application, evCommand,
	cmReopenHelp + W^.Viewer^.Focused, nil);
    end;
    Dispose(W, Done);
  end;
end;

procedure THelpViewer.GetHelpBrowserRec(var R: TPrevHelpRec;
  var FakeRefStr: String; var KeyRef: Integer; var SearchFake: Boolean);
var
  KeyPoint: TPoint;
  KeyLength: Byte;
  S: String;
begin
  FillChar(R, SizeOf(TPrevHelpRec), 0);
  SearchFake := False;
  if (Selected <= 0) or (Selected > Topic^.GetNumCrossRefs) then
  begin
    if GetHelpName(R) <> HelpFile^.Name^ then
      R.PrevName := HelpFile^.Name;
    R.PrevIndex := CurCtx;
  end
  else
  begin
    GetCrossRef(Selected, KeyPoint, KeyLength, KeyRef);
    if Word(KeyRef) = hcRefFile then
    begin
      S := OtherHelpFileName;
      R.PrevName := @S;
      R.PrevIndex := 0;
    end
    else
    begin
      if (KeyRef <> -1) and (Word(KeyRef) and $8000 <> 0) then
      begin
	Word(KeyRef) := Word(KeyRef) and not $8000;
	Topic^.GetLine(KeyPoint.Y, S);
	FakeRefStr := System.Copy(S, KeyPoint.X + 1, KeyLength);
	SearchFake := True;
      end;
      if GetHelpName(R) <> HelpFile^.Name^ then
	R.PrevName := HelpFile^.Name;
      R.PrevIndex := KeyRef;
    end;
  end;
  R.PrevSize.X := HelpBrowserBounds.B.X - HelpBrowserBounds.A.X;
  R.PrevSize.Y := HelpBrowserBounds.B.Y - HelpBrowserBounds.A.Y;
  R.PrevOrg := HelpBrowserBounds.A;
end;

procedure THelpViewer.ToggleHelpBrowser;
var
  SaveExplode, DoSearchFake: Boolean;
  KeyRef: Integer;
  R: TPrevHelpRec;
  S: String;
begin
  if ModalHelpInUse or (Owner^.State and sfModal <> 0) or
    (State and sfHelpBrowser <> 0) then Exit;
  if TheHelpBrowser <> nil then CloseHelpBrowser
  else
  begin
    SetViewerBrowserBounds;
    GetHelpBrowserRec(R, S, KeyRef, DoSearchFake);
    OpeningBrowser := True;
    SaveExplode := DoExplode;
    DoExplode := False;
    Desktop^.Lock;
    Owner^.Locate(HelpViewerBounds);
    TheHelpViewer := nil;
    Help(R, False);
    TheHelpViewer := @Self;
    Owner^.Select;
    OpeningBrowser := False;
    if DoSearchFake and (TheHelpBrowser <> nil) then
    begin
      TheHelpBrowser^.SearchFakeCrossRef(S, KeyRef);
      TheHelpBrowser^.DrawView;
    end;
    if TheHelpViewer <> nil then
      PWindow(TheHelpViewer^.Owner)^.Frame^.DrawView;
    Desktop^.Unlock;
    DoExplode := SaveExplode;
  end;
end;

procedure THelpViewer.ChangeHelpBrowserTopic;
var
  DoSearchFake: Boolean;
  KeyRef: Integer;
  R: TPrevHelpRec;
  S: String;
begin
  if (Selected <= 0) or (Selected > Topic^.GetNumCrossRefs) then Exit;
  GetHelpBrowserRec(R, S, KeyRef, DoSearchFake);
  OpeningBrowser := True;
  TheHelpBrowser^.SwitchTo(R, False, False);
  OpeningBrowser := False;
  if DoSearchFake and (TheHelpBrowser <> nil) then
    TheHelpBrowser^.SearchFakeCrossRef(S, KeyRef);
  if TheHelpBrowser <> nil then TheHelpBrowser^.DrawView;
end;

procedure THelpViewer.Popup(AOrigin: TPoint);
var
  C, W1, W2: Word;
  Item: PMenuItem;
  S: String[7];
  SS: String[15];
begin
  if not ModalHelpInUse and (Owner^.State and sfModal = 0) and
    (State and sfHelpBrowser = 0) then
  begin
    if TheHelpBrowser <> nil then
    begin
      S := 'Close';
      C := hcCloseHelpBrowser;
    end
    else
    begin
      S := 'Open';
      C := hcOpenHelpBrowser;
    end;
    Item := NewLine(
      NewItem(S + ' Help ~B~rowser', 'Ctrl+@', kbCtrl2, cmHelpBrowser, C,
	nil));
  end
  else Item := nil;
  if MultitaskerDetected then
  begin
    SS := 'MS Windows';
    W1 := hcECopyToWinClip;
    W2 := hcEPasteFromWinClip;
  end
  else
  begin
    SS := 'additional';
    W1 := hcECopyToAddClip;
    W2 := hcEPasteFromAddClip;
  end;
  ShowPopup(AOrigin, NewMenu(
    NewItem('~C~opy', 'Ctrl+Ins', kbCtrlIns, cmCopy, hcECopy,
    NewItem('~P~aste', 'Shift+Ins', kbShiftIns, cmPaste, hcEPaste,
    NewItem('Cop~y~ to ' + SS + ' Clipboard', 'Ctrl+F12', kbCtrlF12, cmCopyToMT, W1,
    NewItem('Paste fr~o~m ' + SS + ' Clipboard', 'Shift+F12', kbShiftF12, cmPasteFromMT, W2,
    NewLine(
    NewItem('~F~ind...', 'F7', kbF7, cmFind, hcSHFind,
    NewItem('Find ~a~ll...', '', kbNoKey, cmFindAll, hcSHFindAll,
    NewItem('S~h~ow all found...', '', kbNoKey, cmShowAllFound, hcSHShowAllFound,
    NewItem('~S~earch again', 'Shift+F7', kbShiftF7, cmSearchAgain, hcSHSearchAgain,
    NewItem('~G~o to topic...', 'Alt+G', kbAltG, cmGoToLine, hcGoToTopic,
    NewLine(
    NewItem('Help co~n~tents', 'Shift+F1', kbShiftF1, cmContents, hcHContents,
    NewItem('~T~opic search', 'Ctrl+F1', kbCtrlF1, cmTopicSearch, hcHTopicSearch,
    NewItem('P~r~evious topic', 'Alt+F1', kbAltF1, cmPreviousTopic, hcHPreviousTopic,
    NewLine(
    NewItem('He~l~p file...', '', kbNoKey, cmAltHelpName, hcAltHelpName,
    NewLine(
    NewItem('~W~rite topic to history', 'Alt+H', kbNoKey, cmSaveFocusedName, hcSaveTopic,
    NewItem('Help h~i~story...', 'Ctrl+W', kbNoKey, cmHelpHistory, hcReopenHelp,
      Item)))))))))))))))))))));
end;

{ THelpWindow }

constructor THelpWindow.Init(HelpFile: PHelpFile; const R: TPrevHelpRec);
var
  Wide: Boolean;
  B: TRect;
  O: PGroup;
begin
  Wide := HelpWinPos.AX = -1;
  with R do if Longint(PrevSize) = 0 then
  begin
    if Desktop = Pointer(Application^.Current) then O := Desktop
    else O := Application;
    if not Wide and (WinPosMask and wpHelp <> 0) and
      ValidWinPos(HelpWinPos) then SetWinPos(O, HelpWinPos, B)
    else if Pointer(O) = Desktop then Desktop^.GetExtent(B)
    else Desktop^.GetBounds(B);
  end
  else B.Assign(PrevOrg.X, PrevOrg.Y,
    PrevOrg.X + PrevSize.X, PrevOrg.Y + PrevSize.Y);
  TWindow.Init(B, '', WindowNumAvail);
  GetExtent(B);
  if not Wide then B.Grow(-1, -1);
  Insert(New(PHelpViewer, Init(B,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard), HelpFile,	R)));
  HelpCtx := hcHelpInUse;
  WinPos := @HelpWinPos;
end;

constructor THelpWindow.Load(var S: TStream);
begin
  TWindow.Load(S);
  WinPos := @HelpWinPos;
end;

procedure THelpWindow.ChangeBounds(var Bounds: TRect);
var
  SaveWinPos: Pointer;
  R: TRect;
begin
  SaveWinPos := WinPos;
  if OpeningBrowser or (TheHelpBrowser <> nil) then WinPos := nil;
  TWindow.ChangeBounds(Bounds);
  WinPos := SaveWinPos;
  if ((Size.X = Current^.Size.X) and (Size.X < Desktop^.Size.X)) or
     ((Size.Y = Current^.Size.Y) and (Size.Y < Desktop^.Size.Y)) then
  begin
    GetExtent(R);
    R.Grow(-1, -1);
    Current^.Locate(R);
  end;
  if (WinPos <> nil) and
     (Size.X = Current^.Size.X) and (Size.Y = Current^.Size.Y) then
    PWinPosRec(WinPos)^.AX := -1;
  if Current^.State and sfHelpBrowser <> 0 then
    HelpBrowserBounds := Bounds
  else if TheHelpBrowser <> nil then HelpViewerBounds := Bounds;
end;

procedure THelpWindow.Close;
begin
  if (TheHelpBrowser <> nil) and
     (Current^.State and sfHelpBrowser = 0) then CloseHelpBrowser;
  Inherited Close;
end;

function THelpWindow.GetPalette: PPalette;
const
  P: String[Length(CHelpWindow)] = CHelpWindow;
begin
  GetPalette :=	@P;
end;

function THelpWindow.GetTitle(MaxSize: Integer): TTitleStr;
var
  I: Integer;
  Params: Array[0..1] of Longint;
  Ch: String[3];
  C: String[15];
  S: String;
begin
  with PHelpViewer(Current)^ do
  begin
    Params[0] := CurCtx;
    if HelpFile^.Index = nil then Params[1] := 0
    else if HelpFile^.Index^.Size = 0 then Params[1] := 0
    else
    begin
      I := HelpFile^.Index^.Size - 1;
      while (I > 0) and	(HelpFile^.Index^.Position(I) = -1) do Dec(I);
      Params[1] := I;
    end;
    FormatStr(S, ' (%d/%d)', Params);
    I := MaxSize - Length(S) - 1;
    if I < 12 then I := 12;
    if State and sfHelpBrowser <> 0 then C := ' Browser' else C := '';
    if (Owner^.State and sfModal = 0) and (TheHelpBrowser <> nil) then
      if State and sfHelpBrowser <> 0 then Ch := '  ' else Ch := '  '
    else Ch := '';
    GetTitle := Concat(
      'Help', C, '³', Ch, TrimmedName(HelpFile^.Name^, Byte(I)), S);
  end;
end;

procedure THelpWindow.Zoom;
var
  CtrlDown, Full, Wide: Boolean;
  R: TRect;
begin
  CtrlDown := GetShiftState and
    (kbCtrlShift + kbLeftShift + kbRightShift) <> 0;
  Full := Longint(Size) = Longint(Desktop^.Size);
  Wide := Longint(Size) = Longint(Current^.Size);
  if not CtrlDown or not Full then
    if not Full then
    begin
      GetBounds(ZoomRect);
      if Owner = Pointer(Desktop) then Desktop^.GetExtent(R)
      else Desktop^.GetBounds(R);
      Locate(R);
    end
    else Locate(ZoomRect);
  if CtrlDown or Wide then
  begin
    GetExtent(R);
    if Wide then R.Grow(-1, -1);
    if (WinPos <> nil) and (TheHelpBrowser = nil) then
      if Wide then PWinPosRec(WinPos)^.AX := 0
      else PWinPosRec(WinPos)^.AX := -1;
    Current^.Locate(R);
  end;
end;

procedure THelpWindow.SizeLimits(var Min, Max: TPoint);
begin
  TWindow.SizeLimits(Min, Max);
  Max.Y	:= Desktop^.Size.Y;
end;

function GetHelpName(const R: TPrevHelpRec): FNameStr;
begin
  if R.PrevName <> nil then GetHelpName := CNFileName(R.PrevName^)
  else GetHelpName := ForceExtension(FExpand(ParamStr(0)), 'HLP');
end;

procedure GetHelp(var R: TPrevHelpRec);
begin
  R := PrevHelps[PrevHelpIndex];
  Inc(PrevHelpIndex);
  if PrevHelpIndex = MaxHelps then PrevHelpIndex := 0;
end;

procedure PutHelp(const R: TPrevHelpRec);
begin
  if (GetHelpName(PrevHelps[PrevHelpIndex]) <> GetHelpName(R)) or
     (PrevHelps[PrevHelpIndex].PrevIndex <> R.PrevIndex) then
    if PrevHelpIndex = 0 then PrevHelpIndex := MaxHelps - 1
    else Dec(PrevHelpIndex);
{  DisposeStr(PrevHelps[PrevHelpIndex].PrevName);}
  DisposeStrUMB(PrevHelps[PrevHelpIndex].PrevName);
  PrevHelps[PrevHelpIndex] := R;
  if R.PrevName <> nil then
{    PrevHelps[PrevHelpIndex].PrevName := NewStr(R.PrevName^);}
    PrevHelps[PrevHelpIndex].PrevName := NewStrUMB(R.PrevName^);
  PrevHelpUsed := True;
end;

procedure PutHelpSearchStr(const S: String);
begin
  DisposeStr(HelpSearchStr);
  HelpSearchStr := NewStr(S);
end;

procedure Help(const R: TPrevHelpRec; ForceBrowser: Boolean);
var
  P: PHelpFile;
  V: PHelpViewer;
  W: PHelpWindow;
  Name: FNameStr;
begin
  if ForceBrowser then
  begin
    if TheHelpBrowser <> nil then with TheHelpBrowser^ do
    begin
      SwitchTo(R, False, False);
      if HelpSearchStr <> nil then SearchAndSelect(True);
      DrawView;
    end;
    Exit;
  end;
  ModalHelpInUse := not NoModalWindows or
    ((R.PrevIndex = hcDragging) and (R.PrevName = nil) and
     (Application^.GetHelpCtx = hcDragging));
  if not ModalHelpInUse and (TheHelpViewer <> nil) then
  begin
    if (TheHelpBrowser <> nil) and
       (TheHelpBrowser^.Owner = Pointer(Desktop^.Current)) then
	 V := TheHelpBrowser
    else V := TheHelpViewer;
    with V^ do
    begin
      SwitchTo(R, True, True);
      if HelpSearchStr <> nil then SearchAndSelect(True);
      DrawView;
      PWindow(Owner)^.Deiconize;
      Owner^.Show;
      Owner^.Select;
    end;
  end
  else
  begin
    Name := GetHelpName(R);
    P := New(PHelpFile, Init(Name));
    W := New(PHelpWindow, Init(P, R));
    if ModalHelpInUse then
      Application^.ExecuteDialog(PDialog(W), nil, False)
    else Application^.InsertWindow(W);
  end;
  ModalHelpInUse := False;
end;

end.
