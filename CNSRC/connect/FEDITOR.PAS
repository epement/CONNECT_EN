{$I-,F-,O-,X+}
unit FEditor;

interface

uses Dos, Objects, Views, Drivers, Swaps, CmntList, FindDlg, StrCol;

const
  MaxBreakPoints = 20;

  ofASCII = $1000;
  ofHex = $2000;
  ofNewSize = $8000;
  ofSaveLocal = $80;

  IncSearchLen = 63;

type

  { TPlaces }

  TPlaces = Array['0'..'9'] of TPoint;

  { TBreakPoints }

  TBreakPoints = Array[0..MaxBreakPoints - 1] of Integer;

  { TPos }

  TPos = record
    AStart: Integer;
    AnEnd: Integer;
  end;

  { TLastLine }

  TLastLine = record
    Line: String;
    Index: Integer;
    Pos: TPoint;
    SelArea: TArea;
    Sel: Boolean;
  end;

  { TUndoRec }

  PUndoRec = ^TUndoRec;
  TUndoRec = record
    Address: Longint;
    Index: Integer;
    Action: Byte;
  end;

  { TUndoChain }

  PUndoChain = ^TUndoChain;
  TUndoChain = object(TCollection)
    SavePos: TPoint;
    SaveArea: TArea;
    SaveSel: Boolean;
    NestedCount: Integer;
    constructor Load(var S: TStream);
    procedure FreeItem(Item: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
    procedure SetLimit(ALimit: Integer); virtual;
    procedure Store(var S: TStream);
  end;

  { TIndicator }

  PIndicator = ^TIndicator;
  TIndicator = object(TView)
    procedure Draw; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    function GetMouseShape(var Event: TEvent): Char; virtual;
  end;

  PSyntaxList = ^TSyntaxList;
  TSyntaxList = object(TStringsCollection)
    FileName: PString;
    Symbols: set of Char;
    Quotes: set of Char;
    QuoteColors: Array[#0..#255] of Byte;
    NumberColor: Byte;
  end;

  { TFileEditor }

  PFileEditor = ^TFileEditor;
  TFileEditor = object(TScroller)
    SelectFromX: Byte;
    SelectFromY: Integer;
    FileName: PString;
    Indicator: PIndicator;
    FileLines, NewLines, UndoList, RedoList, FindAllList: PCollection;
    SwapStream: PStream;
    RegExpr: Pointer;
    KeepRegExpr: Boolean;
    IsValid, IsInsert, IsModified, DebugModified, IsSelected,
    IsCtrlKPressed, IsCtrlQPressed, IsCtrlPPressed, IsCtrlOPressed,
    IsDebug, IsClip, DoRedraw, DrawFlag, Drawing, FastGetLine,
    IsSearchingAll, IsSearchingFrom, IsReplacing, IsReloading,
    DisposeXLATNames: Boolean;
    DrawFromTop: Boolean;
    UnixMode: Boolean;
    Area: PArea;
    Places: TPlaces;
    BreakPoints: TBreakPoints;
    LastLine: TLastLine;
    SourceLine: Integer;
    LastTime: Longint;
    TopLine: Integer;
    SwapSize: Longint;
    UndoCount: Integer;
    FindAllIndex: Integer;
    FindAllData: TSearchData;
    SyntaxWord: Byte;
    Comment: CommentStr;
    CommentRegExp: Pointer;
    LocalEditOptions: Longint;
    LocalTabSize: Byte;
    LocalMaxLineWidth: Byte;
    LocalWordDelims: TCharSet;
    NewLocalOptions: Word;
    HelpName: PString;
    INXLATName: PString;
    OUTXLATName: PString;
    MacroName: PString;
    MacroList: PCollection;
    SyntaxName: PString;
    SyntaxList: PSyntaxList;
    PrnRec: PPrnRec;
    LinesPerPage: Byte;
    ErrorCode: Byte;
    FileAttr: Word;
    HistLock: Byte;
    IncSearchStr: String[IncSearchLen];
    IncSearchPos: Integer;
    IncSearchOpt: Word;
    IncSearch: Boolean;
    SavedCursor: TPoint;
    SavedInsert: Boolean;
    SavedBlock: TArea;
    SavedColumns: Boolean;
    SavedIsSel: Boolean;
{ Added 20.09.2002 to support command line positioning }
    ParamStrCol: Integer;
    ParamStrRow: Integer;
    ParamStrExitOnClose: Boolean;
{Added 2006.01.10 }
    UpdateTicks: Word;
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar; AnIndicator: PIndicator);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Draw; virtual;
    procedure DrawError(const ALine: String; ACode: Byte);
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    function Valid(Command: Word): Boolean; virtual;
    procedure ReadFile(var FName: String); virtual;
    procedure FastScrollTo(Y: Integer);
    function GetLinePos: Integer; virtual;
    procedure GetValidLine(AnIndex: Integer; var ALine: String); virtual;
    procedure NewLine(AnIndex: Integer; ALine: String);
    procedure ReplaceLine(AnIndex: Integer; ALine: String);
    procedure ClearLine(AnIndex: Integer);
    procedure DeleteChar(AnIndex: Integer; APos: Byte;
      Backward: Boolean); virtual;
    procedure Scroll(var Event: TEvent);
    procedure GoRight; virtual;
    procedure GoLeft; virtual;
    procedure GoWhileKeyDown(Key: Byte); virtual;
    procedure GoDown; virtual;
    procedure GoUp; virtual;
    procedure GoPgDn; virtual;
    procedure GoPgUp; virtual;
    procedure GoCtrlPgDn; virtual;
    procedure GoCtrlPgUp; virtual;
    procedure GoCtrlRight; virtual;
    procedure GoCtrlLeft; virtual;
    procedure GoCtrlUp; virtual;
    procedure GoCtrlDown; virtual;
    procedure GoEnd; virtual;
    procedure GoHome; virtual;
    procedure GoCtrlEnd; virtual;
    procedure GoCtrlHome; virtual;
    procedure GoToPos(APos: Byte; AnIndex: Integer); virtual;
    procedure GoToLineNum(AnIndex: LongInt); virtual;
    procedure ToggleInsert;
    function Save(const AName: FNameStr; Append: Boolean): Boolean; virtual;
    function SaveOrCancel: Word;
    procedure UpdateLines(const Name: FNameStr);
    procedure UpdateTime;
    procedure Highlight(AKB: Integer; APB: Byte; AKK: Integer; APK: Byte);
    procedure Unselect;
    procedure SelectOn(CurY: Integer; CurX: Byte);
    function Selected(AnIndex: Integer): Boolean;
    procedure GetPos(AnArea: PArea; AnIndex: Integer;
      var APos: TPos); virtual;
    procedure GetSelectedString(AnIndex: Integer; var ALine: String); virtual;
    procedure Copy; virtual;
    procedure Clear(DoMove, DoDraw: Boolean); virtual;
    procedure Cut; virtual;
    procedure Paste; virtual;
    procedure Find;
    procedure Replace(Prompt: Boolean);
    procedure ReplaceWith(const AString: String; ALength: Byte); virtual;
    procedure InsertBlock(AnIndex: Integer; APos: Byte); virtual;
    procedure CutBlock(AnArea: PArea); virtual;
    procedure DeleteBlock(AnArea: PArea);
    procedure MoveBlock(AnIndex: Integer; APos: Byte); virtual;
    procedure TransferBlock(AnIndex: Integer; APos: Byte; JustCopy: Boolean);
    procedure ExtCompile;
    function GetPrintLine(AnIndex: Integer; Sel: Boolean;
      var ALine: String): Boolean; virtual;
    function WriteBlock(const FName: FNameStr;
      Append: Boolean): Boolean; virtual;
    function ReadBlock(const FName: FNameStr;
      ConcatLast: Boolean): Boolean; virtual;
    function WriteBlockToFile(const AName: FNameStr;
      Prompt: Boolean; Append: Boolean): Boolean;
    function ReadBlockFromFile(const AName: FNameStr;
      Prompt: Boolean): Boolean;
    procedure ClearPlaces;
    procedure UpdatePlaces(AnIndex: Integer; Action: Byte);
    procedure UpdateLastLine(AnIndex: Integer);
    procedure SetLastLine(const ALine: String; AnIndex: Integer);
    procedure SaveLastLine;
    procedure Undo;
    procedure Redo;
    procedure UndoError;
    function GetUndoChain: PUndoChain;
    function GetRedoChain: PUndoChain;
    procedure NewUndoChain(ARange: Integer);
    procedure AddUndoChain;
    procedure AddRedoChain;
    function Search(const Match: String; AOptions: Word): Boolean; virtual;
    function WordChar(Ch: Char): Boolean;
    function GetWord(var B, E: Byte): String; virtual;
    function GetLine: String; virtual;
    procedure FreeLocalPointers;
    procedure InitLocalFields(SkipOptions: Boolean);
    procedure GetLocalFields;
    function IsBreakPoint(AnIndex: Integer): Integer;
    procedure ClearBreakPoints;
    procedure Debug;
    procedure ProgramReset;
    procedure SwapTruncate; virtual;
    procedure UpdateHistory;
    procedure NewTitle(const Name: FNameStr); virtual;
{ Added 20.09.2002 to support command line positioning }
    procedure PreprocessFileName(var Name: FNameStr);
  end;

  { TEditorWindow }

  PEditorWindow = ^TEditorWindow;
  TEditorWindow = object(TWindow)
    Editor: PScroller;
    constructor Init(Bounds: TRect; var FileName: String);
    constructor Load(var S: TStream);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure Close; virtual;
    function GetPalette: PPalette; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
    procedure Zoom; virtual;
  end;

procedure SwapWrite(var S: PStream; APos: Longint; var Buf; Count: Word);

const
  CEditorColor      = #$17#$1F#$1A#$31#$31#$1E#$71#$4F#$30;
  CEditorBlackWhite = #$07#$0F#$07#$70#$70#$07#$70#$0F#$70;
  CEditorMonochrome = #$07#$0F#$07#$70#$70#$07#$70#$0F#$70;
  CEditor           = #6#7#8#9;
  CEditorWindow     = #96#97#98#99#100#101#102#103#104;

  CSyntaxColor      = #$17#$1F#$1A#$1A#$1A#$1C#$1B#$17#$1F#$5F;
  CSyntaxBlackWhite = #$07#$0F#$0F#$0F#$0F#$07#$07#$07#$0F#$70;
  CSyntaxMonochrome = #$07#$0F#$0F#$0F#$0F#$07#$07#$07#$0F#$01;
  cASM              = 165;
  cCBSFunctions     = 166;
  cCBSOperators     = 167;
  cCBSStatements    = 168;
  cCBSSymbols       = 169;
  cCBSLabels        = 170;
  cCBSStrings       = 171;
  cCBSRemarks       = 172;
  cCurLine          = 173;
  cPageBreak        = 174;
  cCurCol           = 200;
  cBoundaries       = 202;
  swNothing         = 0;
  swASM             = 1;
  swCPP             = 2;
  swBAS             = 3;
  swAny             = 4;
  swCBS             = 5;

const
  sfDrawSingle = $1000;
  sfDrawDouble = $2000;
  sfDrawing = $3000;

  sfSemicolon = $4000;
  sfNoname = $8000;

  unDel = 0;
  unIns = 1;
  unRep = 2;

  UndoChain: PUndoChain = nil;

  NumLines = 128;

  EditorTypes: Array[False..True] of String[6] = ('ASCII ', 'Hex   ');

{ Added 20.09.2002 to support command line positioning }
  ColRowChar: Char = '[';
  ExitOnCloseChar: Char = ']';

var
  ReplaceLen: Byte;

implementation

uses Memory, App, WinIcons, HistList, History, Compiler, DirPrim, ExecPrim,
  EditBlk, EditClip, EditCmnd, EditDraw, EditFile, EditFind, EditGo, EditMsg,
  EditPrim, EditTabl, EditUndo, EditUpdt, CNMacros, RegExp, RevPos, Spooler,
  HeapUMB, Disks, DosTools, LFN, Keyboard, TPString, Consts, Commands, Defaults;

procedure SwapWrite(var S: PStream; APos: Longint; var Buf; Count: Word);
var
  SaveStatus: Integer;
  Size: Longint;
  SaveMsg: FNameStr;
begin
  S^.Write(Buf, Count);
  if (S^.Status <> stOk) and (S = DiskSwapStream) and
     (TypeOf(S^) <> TypeOf(TDosStream)) then
    SwapWritePrim(S, APos, Buf, Count);
end;

{ TUndoChain }
constructor TUndoChain.Load(var S: TStream);
var
  C, I: Integer;
begin
  TObject.Init;
  S.Read(Count, SizeOf(Integer) * 3);
  Items := nil;
  C := Count;
  I := Limit;
  Count := 0;
  Limit := 0;
  SetLimit(I);
  if Limit <> I then Fail;
  Count := C;
  for I := 0 to C - 1 do AtPut(I, GetItem(S));
  S.Read(SavePos, SizeOf(TPoint) + SizeOf(TArea) + SizeOf(Boolean));
end;

procedure TUndoChain.FreeItem(Item: Pointer);
begin
  if Item <> nil then FreeMem(Item, SizeOf(TUndoRec));
end;

function TUndoChain.GetItem(var S: TStream): Pointer;
var
  Item: PUndoRec;
  BRec: TUndoRec;
begin
  Item := MemAlloc(SizeOf(TUndoRec));
  if Item <> nil then S.Read(Item^, SizeOf(TUndoRec))
  else S.Read(BRec, SizeOf(TUndoRec));
  GetItem := Item;
end;

procedure TUndoChain.PutItem(var S: TStream; Item: Pointer);
begin
  S.Write(Item^, SizeOf(TUndoRec));
end;

procedure TUndoChain.SetLimit(ALimit: Integer);
begin
  if MaxAvail > LongMul(ALimit, SizeOf(Pointer)) + $2000 then
    TCollection.SetLimit(ALimit);
end;

procedure TUndoChain.Store(var S: TStream);
begin
  TCollection.Store(S);
  S.Write(SavePos, SizeOf(TPoint) + SizeOf(TArea) + SizeOf(Boolean));
end;

{ TIndicator }
procedure TIndicator.Draw;
var
  Ch: Char;
  C: Word;
  X, Y: Integer;
  CS: String[3];
  Params: Array[0..2] of Longint;
  B: TDrawBuffer;
  S, L: String;
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
    Ch := #205;
    C := GetColor(2);
  end;
  MoveChar(B, Ch, C, Size.X);
  with PFileEditor(PEditorWindow(Owner)^.Editor)^ do
  begin
    X := Delta.X + Cursor.X + 1;
    Y := Delta.Y + Cursor.Y;
    if Y >= FileLines^.Count then CS := 'EOF'
    else
    begin
      GetValidLine(Y, L);
      if X > Length(L) then CS := 'EOL'
      else Str(Byte(L[X]), CS);
    end;
    Params[0] := Y + 1;
    Params[1] := X;
    Params[2] := Longint(@CS);
    FormatStr(S, ' %d:%d Char %-s ', Params);
    if IsModified then MoveChar(B, '', C, 1);
    if State and sfDrawing <> 0 then
    begin
      MoveChar(B[Self.Size.X - 3], '<', C, 1);
      if State and sfDrawSingle <> 0 then
        MoveChar(B[Self.Size.X - 2], 'Å', C, 1)
      else MoveChar(B[Self.Size.X - 2], 'Î', C, 1);
      MoveChar(B[Self.Size.X - 1], '>', C, 1);
    end
    else
    begin
      MoveChar(B[Self.Size.X - 3], '[', C, 1);
      if MarkColumns then MoveChar(B[Self.Size.X - 2], '', C, 1)
      else MoveChar(B[Self.Size.X - 2], '', C, 1);
      MoveChar(B[Self.Size.X - 1], ']', C, 1);
    end;
  end;
  MoveStr(B[3], S, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TIndicator.GetPalette: PPalette;
const
  P: String[3] = #1#2#3;
begin
  GetPalette := @P;
end;

procedure TIndicator.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  if (Event.What = evMouseDown) and MouseInView(Event.Where) then
    HandleIndicatorMouse(PFileEditor(PEditorWindow(Owner)^.Editor), Event);
end;

procedure TIndicator.SetState(AState: Word; Enable: Boolean);
begin
  TView.SetState(AState, Enable);
  DrawView;
end;

function TIndicator.GetMouseShape(var Event: TEvent): Char;
begin
  GetMouseShape := IndicatorGetMouseShape(
    PFileEditor(PEditorWindow(Owner)^.Editor), Event);
end;

{ TFileEditor }
constructor TFileEditor.Init(var Bounds: TRect; AHScrollBar,
  AVScrollBar: PScrollBar; AnIndicator: PIndicator);
begin
  TScroller.Init(Bounds, AHScrollbar, AVScrollBar);
  GrowMode := gfGrowHiX + gfGrowHiY;
  Indicator := AnIndicator;
{  GetMem(Area, SizeOf(TArea));}
  GetMemUMB(Area, SizeOf(TArea));
  Unselect;
  ClearPlaces;
  ClearBreakPoints;
  ParamStrCol := -1;
  ParamStrRow := -1;
end;

constructor TFileEditor.Load(var S: TStream);
begin
  TScroller.Load(S);
  GetPeerViewPtr(S, Indicator);
{  FileName := S.ReadStr;}
  FileName := ReadStrUMB(@S);
{  GetMem(Area, SizeOf(TArea));}
  GetMemUMB(Area, SizeOf(TArea));
  S.Read(Area^, SizeOf(Area^));
  S.Read(Places, SizeOf(Places));
  S.Read(BreakPoints, SizeOf(BreakPoints));
  S.Read(IsSelected, SizeOf(IsSelected));
  S.Read(HistLock, SizeOf(HistLock));
  if Byte(IsSelected) and ofSaveLocal <> 0 then
  begin
    S.Read(LocalEditOptions, SizeOf(LocalEditOptions));
    S.Read(LocalTabSize, SizeOf(LocalTabSize));
    S.Read(LocalMaxLineWidth, SizeOf(LocalMaxLineWidth));
    S.Read(LocalWordDelims, SizeOf(LocalWordDelims));
    S.Read(NewLocalOptions, SizeOf(NewLocalOptions));
  end;
  ParamStrCol := -1;
  ParamStrRow := -1;
end;

destructor TFileEditor.Done;
begin
  SwapTruncate;
  FreeLocalPointers;
{  FreeMem(Area, SizeOf(TArea));}
  FreeMemUMB(Area, SizeOf(TArea));
  if FindAllList <> nil then Dispose(FindAllList, Done);
  if RedoList <> nil then Dispose(RedoList, Done);
  if UndoList <> nil then Dispose(UndoList, Done);
  if NewLines <> nil then Dispose(NewLines, Done);
  if FileLines <> nil then Dispose(FileLines, Done);
{  DisposeStr(FileName);}
  DisposeStrUMB(FileName);
  TScroller.Done;
end;

procedure TFileEditor.ChangeBounds(var Bounds: TRect);
begin
  TScroller.ChangeBounds(Bounds);
  DrawFlag := True;
  SetLimit(Limit.X, FileLines^.Count + Size.Y);
  DrawFlag := False;
end;

procedure TFileEditor.Draw;
begin
  DrawEditorPrim(@Self);
end;

procedure TFileEditor.DrawError(const ALine: String; ACode: Byte);
begin
  DrawEditorErrorPrim(@Self, ALine, ACode);
end;

function TFileEditor.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else if ErrorCode <> 0 then GetHelpCtx := hcCompilerError + ErrorCode - 1
  else if IncSearch then GetHelpCtx := hcEditIncSearch
  else if GetShiftState and kbAltShift <> 0 then GetHelpCtx := hcAltASCIIEditor
  else if IsCtrlKPressed then GetHelpCtx := hcCtrlKPressed
  else if IsCtrlQPressed then GetHelpCtx := hcCtrlQPressed
  else if IsCtrlPPressed then GetHelpCtx := hcCtrlPPressed
  else if IsCtrlOPressed then GetHelpCtx := hcCtrlOPressed
  else if State and sfDrawSingle <> 0 then GetHelpCtx := hcDrawSingle
  else if State and sfDrawDouble <> 0 then GetHelpCtx := hcDrawDouble
  else GetHelpCtx := hcASCIIEditor;

{Added 2006.01.10 }
  if (MemW[$40:$6C] - UpdateTicks >= 50) then
  begin
    UpdateTicks := MemW[$40:$6C];
    UpdateTime;
  end;
end;

function TFileEditor.GetPalette: PPalette;
const
  P: String[Length(CEditor)] = CEditor;
begin
  GetPalette := @P;
end;

procedure TFileEditor.FastScrollTo(Y: Integer);
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

procedure TFileEditor.Debug;
begin
  IsDebug := True;
  InitSource(@Self);
end;

procedure TFileEditor.ProgramReset;
begin
  if Debugging and IsDebug then
  begin
    if CPUInUse then CloseCPUWindow;
    IsDebug := False;
    SourceLine := -1;
    DrawView;
  end;
end;

procedure TFileEditor.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evKeyDown) and (MacroList <> nil) and
    PreprocessEnabledPrim(@Self, Event) then
      PreprocessKeyEvent(MacroList, Event);
  TScroller.HandleEvent(Event);
  if Event.What = evKeyDown then HandleEditKey(@Self, Event)
  else if (Event.What = evMouseDown) and MouseInView(Event.Where) then
    HandleEditMouse(@Self, Event)
  else if Event.What = evCommand then HandleEditCommand(@Self, Event)
  else if Event.What = evBroadcast then HandleEditBroadcast(@Self, Event);
end;

function TFileEditor.GetLinePos: Integer;
begin
  GetLinePos := Delta.X + Cursor.X;
end;

procedure TFileEditor.GetValidLine(AnIndex: Integer; var ALine: String);
var
  I, C: Integer;
  P: PString;
  L: Longint;
  S: String;
label
  Quit;
begin
  if AnIndex = LastLine.Index then
    if NewLocalOptions and neoTrailingBlanks = 0 then
      ALine := TrimTrail(LastLine.Line)
    else ALine := LastLine.Line
  else if AnIndex >= FileLines^.Count then ALine := ''
  else
  begin
    if (AnIndex < TopLine) or
       (AnIndex >= TopLine + NewLines^.Count) then
    begin
      GiveTicks;
      NewLines^.FreeAll;
      if FastGetLine then TopLine := AnIndex
      else TopLine := AnIndex - NumLines div 2;
      if TopLine + NumLines > FileLines^.Count then
        TopLine := FileLines^.Count - NumLines;
      if TopLine < 0 then TopLine := 0;
      I := TopLine;
      while (I < TopLine + NumLines) and (I < FileLines^.Count) do
      begin
        L := Longint(PSwapLinesCollection(FileLines)^.ExtraAt(I));
        if L = 0 then NewLines^.Insert(nil)
        else with SwapStream^ do
        begin
          Seek(L);
          Read(S[0], 1);
          Read(S[1], Byte(S[0]));
          if Status <> stOk then
          begin
            Reset;
            I := TopLine;
            SwapReadErrorMsgBox;
            TopLine := I;
            for I := NewLines^.Count to NumLines - 1 do
              NewLines^.Insert(nil);
            Break;
          end;
          C := NewLines^.Count;
{          NewLines^.Insert(NewStr(S));}
          NewLines^.Insert(NewStrUMB(S));
          if C = NewLines^.Count then
          begin
            L := Longint(PSwapLinesCollection(FileLines)^.ExtraAt(AnIndex));
            if L = 0 then ALine := ''
            else with SwapStream^ do
            begin
              Seek(L);
              Read(ALine[0], 1);
              Read(ALine[1], Byte(ALine[0]));
              if Status <> stOk then Reset;
            end;
            P := @ALine;
            Goto Quit;
          end;
        end;
        Inc(I);
      end;
    end;
    I := AnIndex - TopLine;
    P := NewLines^.At(I);
    if P = nil then ALine := ''
    else
    begin
Quit:
      ALine := Detab(P^, LocalTabSize);
      if NewLocalOptions and neoTrailingBlanks = 0 then
	TrailTrim(ALine);
    end;
  end;
end;

procedure TFileEditor.NewLine(AnIndex: Integer; ALine: String);
var
  SaveCount: Integer;
  L: Longint;
  R: PUndoRec;
begin
  if AnIndex > FileLines^.Count then Exit;
  if ALine = '' then L := 0
  else
  begin
    L := SwapStream^.GetSize;
    SwapStream^.Seek(L);
    SwapWrite(SwapStream, L, ALine, Byte(ALine[0]) + 1);
    if SwapStream^.Status <> stOk then
    begin
      SwapStream^.Reset;
      PSwapLinesCollection(FileLines)^.Status := coOverflow;
      SwapWriteErrorMsgBox;
      Exit;
    end;
  end;
  PSwapLinesCollection(FileLines)^.ExtraAtInsert(AnIndex, Pointer(L));
  if PSwapLinesCollection(FileLines)^.Status = coOverflow then
  begin
    Application^.OutOfMemory;
    Exit;
  end;
  if (AnIndex >= TopLine) and
     (AnIndex <= TopLine + NewLines^.Count) then with NewLines^ do
  begin
    if Count = NumLines then
      if AnIndex = TopLine + NewLines^.Count then
      begin
        AtFree(0);
        Inc(TopLine);
      end
      else AtFree(Count - 1);
{    AtInsert(AnIndex - TopLine, NewStr(ALine));}
    AtInsert(AnIndex - TopLine, NewStrUMB(ALine));
  end;
  if UndoChain <> nil then
  begin
    R := MemAlloc(SizeOf(TUndoRec));
    if R <> nil then
    begin
      R^.Address := L;
      R^.Index := AnIndex;
      R^.Action := unDel;
      SaveCount := UndoChain^.Count;
      UndoChain^.Insert(R);
      if SaveCount = UndoChain^.Count then
      begin
        FreeMem(R, SizeOf(TUndoRec));
        UndoError;
      end
    end
    else UndoError;
  end;
  UpdatePlaces(AnIndex, unIns);
end;

procedure TFileEditor.ReplaceLine(AnIndex: Integer; ALine: String);
var
  SaveCount: Integer;
  L: Longint;
  R: PUndoRec;
begin
  if AnIndex > FileLines^.Count then Exit;
  if ALine = '' then L := 0
  else
  begin
    L := SwapStream^.GetSize;
    SwapStream^.Seek(L);
    SwapWrite(SwapStream, L, ALine, Byte(ALine[0]) + 1);
    if SwapStream^.Status <> stOk then
    begin
      SwapStream^.Reset;
      PSwapLinesCollection(FileLines)^.Status := coOverflow;
      SwapWriteErrorMsgBox;
      Exit;
    end;
  end;
  if UndoChain <> nil then
  begin
    R := MemAlloc(SizeOf(TUndoRec));
    if R <> nil then
    begin
      R^.Address := Longint(PSwapLinesCollection(FileLines)^.ExtraAt(AnIndex));
      R^.Index := AnIndex;
      if AnIndex = FileLines^.Count then R^.Action := unDel
      else R^.Action := unRep;
      SaveCount := UndoChain^.Count;
      UndoChain^.Insert(R);
      if SaveCount = UndoChain^.Count then
      begin
        FreeMem(R, SizeOf(TUndoRec));
        UndoError;
      end
    end
    else UndoError;
  end;
  PSwapLinesCollection(FileLines)^.ExtraAtFree(AnIndex);
  PSwapLinesCollection(FileLines)^.ExtraAtInsert(AnIndex, Pointer(L));
  if (AnIndex >= TopLine) and
     (AnIndex < TopLine + NewLines^.Count) then with NewLines^ do
  begin
    AtFree(AnIndex - TopLine);
{    AtInsert(AnIndex - TopLine, NewStr(ALine));}
    AtInsert(AnIndex - TopLine, NewStrUMB(ALine));
  end;
end;

procedure TFileEditor.ClearLine(AnIndex: Integer);
var
  SaveCount: Integer;
  R: PUndoRec;
begin
  if AnIndex >= FileLines^.Count then Exit;
  if UndoChain <> nil then
  begin
    R := MemAlloc(SizeOf(TUndoRec));
    if R <> nil then
    begin
      R^.Address := Longint(PSwapLinesCollection(FileLines)^.ExtraAt(AnIndex));
      R^.Index := AnIndex;
      R^.Action := unIns;
      SaveCount := UndoChain^.Count;
      UndoChain^.Insert(R);
      if SaveCount = UndoChain^.Count then
      begin
        FreeMem(R, SizeOf(TUndoRec));
        UndoError;
      end
    end
    else UndoError;
  end;
  PSwapLinesCollection(FileLines)^.ExtraAtFree(AnIndex);
  if (AnIndex >= TopLine) and
     (AnIndex <= TopLine + NumLines) then
    NewLines^.AtFree(AnIndex - TopLine);
  UpdatePlaces(AnIndex, unDel);
end;

procedure TFileEditor.DeleteChar(AnIndex: Integer; APos: Byte;
  Backward: Boolean);
begin
  DeleteCharPrim(@Self, AnIndex, APos, Backward);
end;

procedure TFileEditor.ReplaceWith(const AString: String; ALength: Byte);
begin
  ReplaceWithPrim(@Self, AString, ALength);
end;

procedure TFileEditor.CutBlock(AnArea: PArea);
begin
  CutBlockPrim(@Self, AnArea);
end;

procedure TFileEditor.InsertBlock(AnIndex: Integer; APos: Byte);
begin
  InsertBlockPrim(@Self, AnIndex, APos);
end;

procedure TFileEditor.DeleteBlock(AnArea: PArea);
begin
  DeleteBlockPrim(@Self, AnArea);
end;

procedure TFileEditor.MoveBlock(AnIndex: Integer; APos: Byte);
begin
  MoveBlockPrim(@Self, AnIndex, APos);
end;

procedure TFileEditor.TransferBlock(AnIndex: Integer; APos: Byte;
  JustCopy: Boolean);
begin
  TransferBlockPrim(@Self, AnIndex, APos, JustCopy);
end;

function TFileEditor.ReadBlock(const FName: FNameStr;
  ConcatLast: Boolean): Boolean;
begin
  ReadBlock := ReadBlockPrim(@Self, FName, ConcatLast);
end;

function TFileEditor.WriteBlock(const FName: FNameStr;
  Append: Boolean): Boolean;
begin
  WriteBlock := WriteBlockPrim(@Self, FName, Append);
end;

function TFileEditor.WriteBlockToFile(const AName: FNameStr;
  Prompt: Boolean; Append: Boolean): Boolean;
begin
  WriteBlockToFile := WriteBlockToFilePrim(@Self, AName, Prompt, Append);
end;

function TFileEditor.ReadBlockFromFile(const AName: FNameStr;
  Prompt: Boolean): Boolean;
begin
  ReadBlockFromFile := ReadBlockFromFilePrim(@Self, AName, Prompt);
end;

procedure TFileEditor.Copy;
begin
  CopyPrim(@Self);
end;

procedure TFileEditor.Clear(DoMove, DoDraw: Boolean);
begin
  ClearPrim(@Self, DoMove, DoDraw);
end;

procedure TFileEditor.Cut;
begin
  Copy;
  Clear(True, True);
end;

procedure TFileEditor.Paste;
begin
  PastePrim(@Self);
end;

procedure TFileEditor.Find;
begin
  FindPrim(@Self, False);
end;

procedure TFileEditor.Replace(Prompt: Boolean);
begin
  ReplacePrim(@Self, Prompt);
end;

procedure TFileEditor.ExtCompile;
begin
  if ExtractExecRec(ExecRec, JustFileName(FileName^), 0, False) then
  begin
    HistoryOpened := True;
    PrepareExecEvent;
  end;
end;

function TFileEditor.GetPrintLine(AnIndex: Integer; Sel: Boolean;
  var ALine: String): Boolean;
begin
  GetPrintLine := GetPrintLinePrim(@Self, AnIndex, Sel, ALine);
end;

procedure TFileEditor.Scroll(var Event: TEvent);
begin
  ScrollPrim(@Self, Event);
end;

procedure TFileEditor.GoRight;
begin
  GoRightPrim(@Self);
end;

procedure TFileEditor.GoLeft;
begin
  GoLeftPrim(@Self);
end;

procedure TFileEditor.GoWhileKeyDown(Key: Byte);
begin
  GoWhileKeyDownPrim(@Self, Key);
end;

procedure TFileEditor.GoDown;
begin
  GoDownPrim(@Self);
end;

procedure TFileEditor.GoUp;
begin
  GoUpPrim(@Self);
end;

procedure TFileEditor.GoPgDn;
begin
  GoPgDnPrim(@Self);
end;

procedure TFileEditor.GoPgUp;
begin
  GoPgUpPrim(@Self);
end;

procedure TFileEditor.GoCtrlPgDn;
begin
  GoCtrlPgDnPrim(@Self);
end;

procedure TFileEditor.GoCtrlPgUp;
begin
  GoCtrlPgUpPrim(@Self);
end;

procedure TFileEditor.GoCtrlRight;
begin
  GoCtrlRightPrim(@Self);
end;

procedure TFileEditor.GoCtrlLeft;
begin
  GoCtrlLeftPrim(@Self);
end;

procedure TFileEditor.GoCtrlUp;
begin
  GoCtrlUpPrim(@Self);
end;

procedure TFileEditor.GoCtrlDown;
begin
  GoCtrlDownPrim(@Self);
end;

procedure TFileEditor.GoHome;
begin
  GoHomePrim(@Self);
end;

procedure TFileEditor.GoEnd;
begin
  GoEndPrim(@Self);
end;

procedure TFileEditor.GoCtrlHome;
begin
  GoCtrlHomePrim(@Self);
end;

procedure TFileEditor.GoCtrlEnd;
begin
  GoCtrlEndPrim(@Self);
end;

procedure TFileEditor.GoToPos(APos: Byte; AnIndex: Integer);
var
  Within: Boolean;
  X, SX, Y, SY: Integer;
begin
  if AnIndex > FileLines^.Count then AnIndex := FileLines^.Count;
  Within := (AnIndex < Delta.Y + Size.Y) and (AnIndex >= Delta.Y);
  if Within and (APos < Delta.X + Size.X) and (APos >= Delta.X) then
    SetCursor(APos - Delta.X, AnIndex - Delta.Y)
  else
  begin
    X := APos;
    if X > Pred(Size.X) then X := Pred(Size.X);
    SX := 0;
    if SX + Pred(Size.X) < APos then SX := APos - Pred(Size.X);
    if AnIndex = FileLines^.Count then SY := AnIndex - Pred(Size.Y)
    else if Within then SY := Delta.Y else SY := AnIndex - Size.Y div 2;
    if SY < 0 then SY := 0;
    if AnIndex = FileLines^.Count then Y := Pred(Size.Y)
    else if Within then Y := AnIndex - Delta.Y else Y := Size.Y div 2;
    if SY = 0 then Y := AnIndex;
    ScrollTo(SX, SY);
    SetCursor(X, Y);
  end;
  if LocalEditOptions and (eoHilitCurLine + eoHilitCurColumn) <> 0 then
    DrawView;
  Indicator^.DrawView;
end;

procedure TFileEditor.GoToLineNum(AnIndex: LongInt);
begin
  if (AnIndex <= FileLines^.Count + 1) and (AnIndex > 0) then
    GoToPos(0, AnIndex - 1);
end;

procedure TFileEditor.ToggleInsert;
begin
  IsInsert := not IsInsert;
  if IsInsert then NormalCursor else BlockCursor;
end;

function TFileEditor.SaveOrCancel: Word;
begin
  if IsModified and (GetShiftState and kbCtrlShift = 0) then
    SaveOrCancel := ModifiedSaveMsgBox(FileName^)
  else SaveOrCancel := cmNo;
end;

function TFileEditor.Save(const AName: FNameStr; Append: Boolean): Boolean;
begin
  Save := SavePrim(@Self, AName, Append);
end;

procedure TFileEditor.UpdateLines(const Name: FNameStr);
begin
  UpdateLinesPrim(@Self, Name);
end;

procedure TFileEditor.UpdateTime;
begin
  UpdateTimePrim(@Self);
end;

{ Added 20.09.2002 to support command line positioning }
procedure TFileEditor.PreprocessFileName(var Name: FNameStr);
var
  B, I, X: Integer;
  S: String[31];
begin
  if Name = '' then Exit;
  if (Name[Length(Name)] = ExitOnCloseChar) and not ThisFileExists(Name) then
  begin
    ParamStrExitOnClose := True;
    Dec(Name[0]);
  end;
  B := Pos(ColRowChar, Name);
  if (B <> 0) and not ThisFileExists(Name) then
  begin
    S := System.Copy(Name, B + 1, 31);
    Name[0] := Char(B - 1);
    B := 1;
    while (B <= Length(S)) and (S[B] in ['0'..'9']) do Inc(B);
    Val(System.Copy(S, 1, B - 1), X, I);
    if X > 0 then ParamStrCol := X - 1;
    Delete(S, 1, B);
    B := 1;
    while (B <= Length(S)) and (S[B] in ['0'..'9']) do Inc(B);
    Val(System.Copy(S, 1, B - 1), X, I);
    if X > 0 then ParamStrRow := X - 1;
  end;
end;

procedure TFileEditor.ReadFile(var FName: String);
type
  PMyBuffer = ^TMyBuffer;
  TMyBuffer = Array[0..8191] of Char;
var
  XLAT, C: Boolean;
  Len: Integer;
  L, SavePos, Result: Longint;
  Buffer: PMyBuffer;
  F: lText;
  Line: String;
  T: ConvertTable;
begin
  SwapStream := DiskSwapStream;
  if SwapStream = nil then
  begin
    SwapAccessErrorMsgBox;
    IsValid := False;
    Exit;
  end;
{ Added 20.09.2002 to support command line positioning }
  PreprocessFileName(FName);
  if FName = '' then State := State or sfNoname
  else State := State and not sfNoname;
  if State and sfNoname <> 0 then FName := 'NONAME';
  NewTitle(FName);
  IsValid := True;
  IsModified := False;
  DebugModified := False;
  UnixMode := False;
  FileAttr := Archive;
  Options := Options or ofASCII;
  IsCtrlKPressed := False;
  IsCtrlQPressed := False;
  IsCtrlPPressed := False;
  IsCtrlOPressed := False;
  IsInsert := State and sfCursorIns = 0;
  IsDebug := False;
  IsClip := False;
  TopLine := MaxInt;
  SourceLine := -1;
  SetLastLine('', -1);
  UndoCount := 0;
  if not IsReloading then GetLocalFields;
  Byte(IsSelected) := Byte(IsSelected) and not ofSaveLocal;
  FileLines := New(PSwapLinesCollection, Init(16, 128));
  NewLines := New(PStringsCollection, Init(NumLines, 1));
  UndoList := New(PSwapLinesCollection, Init(8, 8));
  RedoList := New(PSwapLinesCollection, Init(8, 8));
  FindAllList := New(PSwapLinesCollection, Init(8, 8));
  if State and sfNoname = 0 then
  begin
    LogEvent := lcDiskRead;
    DrawStatusLine('Loading ' + TrimmedName(FName, 61) + '.');
    lAssignText(F, FName);
    lGetTAttr(F, FileAttr);
    if DosError <> 0 then FileAttr := Archive;
    Buffer := MemAlloc(SizeOf(Buffer^));
    if Buffer <> nil then SetTextBuf(F.T, Buffer^);
    Reset(F.T);
    Result := IOResult;
    if Result = 0 then
    begin
      if IsDevice(TextRec(F.T).Handle) then
      begin
	FileIsDeviceMsgBox(FName);
	IsValid := False;
      end
      else
      begin
	if INXLATName <> nil then
        begin
	  XLAT := ReadConvertTable(T, INXLATName^, C);
	  if not XLAT and (State and sfNoname = 0) then DrawStatusLine('');
	end
	else XLAT := False;
        if (LocalEditOptions and eoWrapLinesOnLoad = 0) and
           (TextReadMode = trAuto) and not Eof(F.T) then
        begin
          SetUNIXTextMode;
          Readln(F.T, Line);
          if Line[Length(Line)] = #13 then SetDOSTextMode
          else UnixMode := True;
          TextSeek(F.T, 0);
        end
        else if TextReadMode = trUNIX then
        begin
	  SetUNIXTextMode;
          UnixMode := True;
        end;
        L := SwapStream^.GetSize;
        SwapStream^.Seek(L);
        SavePos := 0;
        while not Eof(F.T) do
	begin
	  Readln(F.T, Line);
          if Line = '' then FileLines^.Insert(nil)
          else
          begin
            if LocalEditOptions and eoWrapLinesOnLoad <> 0 then
            begin
              if Length(Line) > LocalMaxLineWidth then
              begin
                Len := LocalMaxLineWidth;
                while (Len > 16) and (Line[Len] <> ' ') do Dec(Len);
                if Line[Len] = ' ' then
                begin
		  Line[0] := Char(Len);
                  TextSeek(F.T, SavePos + Length(Line));
                end;
              end;
              SavePos := TextPos(F.T);
            end;
	    if XLAT then for Len := 1 to Length(Line) do
	      Line[Len] := T[Line[Len]];
	    if NewLocalOptions and neoTrailingBlanks = 0 then
	      TrailTrim(Line);
            SwapWrite(SwapStream, -1, Line, Length(Line) + 1);
            if SwapStream^.Status = stOk then
            begin
              FileLines^.Insert(Pointer(L));
              Inc(L, Length(Line) + 1);
            end
            else Break;
          end;
          if PSwapLinesCollection(FileLines)^.Status = coOverflow then Break;
          if (KbdStatus = 1) and AbortAction then
	  begin
            IsValid := False;
            IsModified := True;
            Break;
          end;
        end;
        SetDOSTextMode;
	SwapSize := L;
	if SwapStream^.Status <> stOk then
	begin
	  if TruncateNoSwapMsgBox(FName) = cmCancel then IsValid := False;
	  IsModified := True;
	end
	else if PSwapLinesCollection(FileLines)^.Status = coOverflow then
	begin
	  if TruncateLinesMsgBox(FName) = cmCancel then IsValid := False;
	  IsModified := True;
	end;
	SwapStream^.Reset;
	PSwapLinesCollection(FileLines)^.Status := 0;
	GetFileTime(FName, LastTime);
      end;
      Close(F.T);
      InOutRes := 0;
    end
    else if Result = 2 then
      if (LocalEditOptions and eoPromptOnNew <> 0) and
         (CreateNewFileMsgBox(FName) = cmCancel) then
        IsValid := False else
    else
    begin
      CouldNotOpenCodeMsgBox(FName, Result);
      IsValid := False;
    end;
    if Buffer <> nil then FreeMem(Buffer, SizeOf(Buffer^));
  end;
  Limit.X := 255;
  Limit.Y := FileLines^.Count;
  if Limit.Y > 0 then Inc(Limit.Y, Size.Y);
  SetLimit(Limit.X, Limit.Y);
  ShowCursor;
  if IsValid and (State and sfNoname = 0) then
  begin
    UpdateHistory;
    if LocalEditOptions and eoChangeDirOnOpen <> 0 then
    begin
      FailSysErrors := True;
      lChDir(JustPathName(FName));
      FailSysErrors := False;
      InOutRes := 0;
    end;
  end;
  if Delta.Y + Cursor.Y > FileLines^.Count then GoCtrlPgDn;
end;

procedure TFileEditor.SetState(AState: Word; Enable: Boolean);

function ASCII(P: PView): Boolean; far;
begin
  ASCII := (P <> PView(Owner)) and (P^.Options and ofASCII <> 0);
end;

begin
  TScroller.SetState(AState, Enable);
  if Enable and (AState = sfExposed) and
     (Owner <> nil) and (Owner^.State and sfModal = 0) then Indicator^.Hide;
  if Enable and (AState = sfFocused) then
  begin
    Indicator^.Show;
    EnableCommands(ASCIICommands);
    if not IsClip then EnableCommands(DebugCommands + SaveAllCommands);
    if (LocalEditOptions and eoEnableUndo <> 0) and
       (((UndoList <> nil) and (UndoList^.Count <> 0)) or
       (LastLine.Index <> -1)) then EnableCommands(UndoCommands)
    else DisableCommands(UndoCommands);
    if (LocalEditOptions and eoEnableUndo <> 0) and
       (RedoList <> nil) and (RedoList^.Count <> 0) then
      EnableCommands(RedoCommands)
    else DisableCommands(RedoCommands);
    if ClipAreaSelected then EnableCommands(PasteCommands)
    else DisableCommands(PasteCommands);
    EnableCommands(MTPasteCommands);
    if IsSelected then EnableCommands(BlockCommands + MTCopyCommands)
    else DisableCommands(BlockCommands + MTCopyCommands);
  end
  else if not Enable and
    (((AState = sfActive) and GetState(sfExposed)) or
    (AState = sfExposed)) then DisableCommands(
      ASCIICommands + UndoCommands + RedoCommands +
      PasteCommands + BlockCommands + MTCommands);
  if Enable and not IsClip and (AState = sfExposed) then
    EnableCommands(DebugCommands + SaveAllCommands)
  else if not Enable and not IsClip and (AState = sfExposed) and
    (Desktop^.FirstThat(@ASCII) = nil) then DisableCommands(DebugCommands);
  if not Enable and (AState = sfFocused) then
  begin
    NewLines^.FreeAll;
    TopLine := MaxInt;
  end;
end;

procedure TFileEditor.Store(var S: TStream);
begin
  TScroller.Store(S);
  PutPeerViewPtr(S, Indicator);
  S.WriteStr(FileName);
  S.Write(Area^, SizeOf(Area^));
  S.Write(Places, SizeOf(Places));
  S.Write(BreakPoints, SizeOf(BreakPoints));
  if not CreatingResource then
    Byte(IsSelected) := Byte(IsSelected) or ofSaveLocal;
  S.Write(IsSelected, SizeOf(IsSelected));
  Byte(IsSelected) := Byte(IsSelected) and not ofSaveLocal;
  S.Write(HistLock, SizeOf(HistLock));
  if not CreatingResource then
  begin
    S.Write(LocalEditOptions, SizeOf(LocalEditOptions));
    S.Write(LocalTabSize, SizeOf(LocalTabSize));
    S.Write(LocalMaxLineWidth, SizeOf(LocalMaxLineWidth));
    S.Write(LocalWordDelims, SizeOf(LocalWordDelims));
    S.Write(NewLocalOptions, SizeOf(NewLocalOptions));
  end;
end;

function TFileEditor.Valid(Command: Word): Boolean;
begin
  Valid := TScroller.Valid(Command) and
    (IsValid or (State and sfExposed <> 0));
end;

procedure TFileEditor.Highlight(AKB: Integer; APB: Byte; AKK: Integer; APK: Byte);
begin
  if Options and ofHex = 0 then
  begin
    if AKB > FileLines^.Count then AKB := FileLines^.Count;
    if AKK > FileLines^.Count then AKK := FileLines^.Count;
  end;
  if not IsSelected then
  begin
    SelectFromX := APB;
    SelectFromY := AKB;
  end;
  SetArea(Area, AKB, APB, AKK, APK);
  IsSelected := (AKB < AKK) or ((AKB = AKK) and (APB <= APK));
  if IsSelected then EnableCommands(BlockCommands + MTCopyCommands)
  else DisableCommands(BlockCommands + MTCopyCommands);
  if IsClip then
  begin
    if IsSelected then EnableCommands(PasteCommands)
    else DisableCommands(PasteCommands);
    ClipAreaSelected := IsSelected;
  end;
end;

procedure TFileEditor.Unselect;
begin
  Highlight(0, 1, 0, 1);
  SelectFromX := 1; SelectFromY := 0;
  IsSelected := False;
  DisableCommands(BlockCommands + MTCopyCommands);
  if IsClip then
  begin
    DisableCommands(PasteCommands);
    ClipAreaSelected := False;
  end;
end;

procedure TFileEditor.SelectOn(CurY: Integer; CurX: Byte);
begin
  if (CurY = SelectFromY) and (CurX = SelectFromX) then
    Highlight(CurY, CurX, CurY, CurX)
  else
  if (CurY < SelectFromY) or
     ((CurY = SelectFromY) and (CurX < SelectFromX)) then
    Highlight(CurY, CurX, SelectFromY, SelectFromX)
  else Highlight(SelectFromY, SelectFromX, CurY, CurX);
end;

function TFileEditor.Selected(AnIndex: Integer): Boolean;
begin
  Selected := IsSelected and
    ((AnIndex >= Area^.KB) and (AnIndex <= Area^.KK));
end;

procedure TFileEditor.GetPos(AnArea: PArea; AnIndex: Integer; var APos: TPos);
begin
  GetPosPrim(@Self, AnArea, AnIndex, APos);
end;

procedure TFileEditor.GetSelectedString(AnIndex: Integer; var ALine: String);
begin
  GetSelectedStringPrim(@Self, AnIndex, ALine);
end;

procedure TFileEditor.ClearPlaces;
begin
  FillChar(Places, SizeOf(Places), $FF);
end;

procedure TFileEditor.UpdatePlaces(AnIndex: Integer; Action: Byte);
var
  Ch: Char;
  I: Integer;
begin
  for Ch := '0' to '9' do
    if Places[Ch].Y >= AnIndex then
      if Action = unIns then Inc(Places[Ch].Y)
      else if Places[Ch].Y = AnIndex then Places[Ch].Y := -1
      else Dec(Places[Ch].Y);
  if BreakPoints[0] <> -1 then
    for I := 0 to MaxBreakPoints - 1 do
      if BreakPoints[I] >= AnIndex then
        if Action = unIns then Inc(BreakPoints[I])
        else if BreakPoints[I] = AnIndex then BreakPoints[I] := -1
        else Dec(BreakPoints[I]);
end;

procedure TFileEditor.FreeLocalPointers;
begin
  if SyntaxList <> nil then DoneSyntaxListPrim(@Self);
  if MacroList <> nil then DoneMacroListPrim(@Self);
  if CommentRegExp <> nil then
  begin
    RegFree(CommentRegExp);
    CommentRegExp := nil;
  end;
  if DisposeXLATNames then
  begin
    DisposeXLATNames := False;
{
    DisposeStr(INXLATName);
    DisposeStr(OUTXLATName);
}
    DisposeStrUMB(INXLATName);
    DisposeStrUMB(OUTXLATName);
  end;
end;

procedure TFileEditor.InitLocalFields(SkipOptions: Boolean);
begin
  FreeLocalPointers;
  if not SkipOptions then
  begin
    LocalEditOptions := EditOptions;
    LocalTabSize := TabSize;
    LocalMaxLineWidth := MaxLineWidth;
    LocalWordDelims := WordDelims;
    NewLocalOptions := NewEditOptions;
  end;
  HelpName := nil;
  INXLATName := nil;
  OUTXLATName := nil;
  MacroName := nil;
  SyntaxName := nil;
  PrnRec := nil;
end;

procedure TFileEditor.GetLocalFields;
var
  SkipOptions: Boolean;
  L, T, B, I: Byte;
  C: Word;
  S: FNameStr;
begin
  SkipOptions := Byte(IsSelected) and ofSaveLocal <> 0;
  InitLocalFields(SkipOptions);
  if @Self = TheBack then S := 'Back' else S := FileName^;
  GetComment(S, Comment, LocalEditOptions, LocalTabSize,
    LocalMaxLineWidth, LocalWordDelims, NewLocalOptions,
    HelpName, INXLATName, OUTXLATName, MacroName, SyntaxName,
    PrnRec, SkipOptions);
  if MacroName <> nil then InitMacroListPrim(@Self);
  if SyntaxName <> nil then InitSyntaxListPrim(@Self);
  if State and sfSemicolon <> 0 then
  begin
    SyntaxWord := swASM;
    Comment := ';';
  end
  else if Comment = '' then
    if CompUCString(JustExtension(FileName^), 'CBS') = Equal then
      SyntaxWord := swCBS
    else SyntaxWord := swNothing
  else if Length(Comment) = 1 then
    if Comment[1] = ';' then SyntaxWord := swASM
    else SyntaxWord := swBAS
  else if Comment = '//' then SyntaxWord := swCPP
  else
  begin
    if LocalEditOptions and eoRegExpComment <> 0 then
      CommentRegExp := RegCompile(Comment);
    SyntaxWord := swAny;
  end;
  if (LocalEditOptions and eoInsertMode <> 0) <> IsInsert then
    ToggleInsert;
  if LocalEditOptions and eoHilitPageBreak = 0 then LinesPerPage := 0
  else GetPrnValues(PrnRec, L, T, B, LinesPerPage, I, C);
  if State and sfFocused <> 0 then SetState(sfFocused, True);
end;

function TFileEditor.IsBreakPoint(AnIndex: Integer): Integer;
begin
  IsBreakPoint := FindWord(BreakPoints, SizeOf(BreakPoints), AnIndex);
end;

procedure TFileEditor.ClearBreakPoints;
begin
  FillChar(BreakPoints, SizeOf(BreakPoints), $FF);
  DrawView;
end;

procedure TFileEditor.UpdateLastLine(AnIndex: Integer);
begin
  with LastLine do
  begin
    if Index <> AnIndex then
    begin
      if Index <> -1 then
      begin
        NewUndoChain(1);
        if UndoChain <> nil then
        begin
          UndoChain^.SavePos := Pos;
          UndoChain^.SaveArea := SelArea;
          UndoChain^.SaveSel := Sel;
        end;
        ReplaceLine(Index, Line);
        AddUndoChain;
      end;
      if AnIndex = FileLines^.Count then
      begin
        NewUndoChain(1);
        NewLine(AnIndex, '');
        AddUndoChain;
        DrawFlag := True;
        SetLimit(Limit.X, FileLines^.Count + Size.Y);
        DrawFlag := False;
      end;
      GetValidLine(AnIndex, Line);
      Index := AnIndex;
      Pos.X := Delta.X + Cursor.X;
      Pos.Y := Delta.Y + Cursor.Y;
      SelArea := Area^;
      Sel := IsSelected;
      if LocalEditOptions and eoEnableUndo <> 0 then
        EnableCommands(UndoCommands);
    end;
  end;
end;

procedure TFileEditor.SetLastLine(const ALine: String; AnIndex: Integer);
begin
  with LastLine do
  begin
    Line := ALine;
    Index := AnIndex;
  end;
end;

procedure TFileEditor.SaveLastLine;
begin
  with LastLine do if Index <> -1 then
  begin
    NewUndoChain(1);
    if UndoChain <> nil then
    begin
      UndoChain^.SavePos := Pos;
      UndoChain^.SaveArea := SelArea;
      UndoChain^.SaveSel := Sel;
    end;
    ReplaceLine(Index, Line);
    AddUndoChain;
    SetLastLine('', -1);
  end;
end;

procedure TFileEditor.Undo;
begin
  UndoPrim(@Self);
end;

procedure TFileEditor.Redo;
begin
  RedoPrim(@Self);
end;

procedure TFileEditor.UndoError;
begin
  UndoErrorPrim(@Self);
end;

function TFileEditor.GetUndoChain: PUndoChain;
var
  L: Longint;
  P: PUndoChain;
begin
  L := Longint(UndoList^.At(UndoList^.Count - 1));
  if L = 0 then P := nil
  else
  begin
    SwapStream^.Seek(L);
    P := PUndoChain(SwapStream^.Get);
    if SwapStream^.Status <> stOk then
    begin
      if P <> nil then Dispose(P, Done);
      P := nil;
      UndoError;
    end;
  end;
  GetUndoChain := P;
end;

function TFileEditor.GetRedoChain: PUndoChain;
var
  L: Longint;
  P: PUndoChain;
begin
  L := Longint(RedoList^.At(RedoList^.Count - 1));
  if L = 0 then P := nil
  else
  begin
    SwapStream^.Seek(L);
    P := PUndoChain(SwapStream^.Get);
    if SwapStream^.Status <> stOk then
    begin
      if P <> nil then Dispose(P, Done);
      P := nil;
      UndoError;
    end;
  end;
  GetRedoChain := P;
end;

procedure TFileEditor.NewUndoChain(ARange: Integer);
begin
  if LocalEditOptions and eoEnableUndo = 0 then UndoChain := nil
  else if UndoChain <> nil then Inc(UndoChain^.NestedCount)
  else if (ARange > MaxCollectionSize) or
    (MaxAvail <= LongMul(ARange, SizeOf(Pointer)) + $2000) then UndoError
  else
  begin
    UndoChain := New(PUndoChain, Init(ARange, 1));
    UndoChain^.SavePos.X := Delta.X + Cursor.X;
    UndoChain^.SavePos.Y := Delta.Y + Cursor.Y;
    UndoChain^.SaveArea := Area^;
    UndoChain^.SaveSel := IsSelected;
  end;
end;

procedure TFileEditor.AddUndoChain;
begin
  AddUndoChainPrim(@Self);
end;

procedure TFileEditor.AddRedoChain;
begin
  AddRedoChainPrim(@Self);
end;

function TFileEditor.WordChar(Ch: Char): Boolean;
begin
  WordChar := not (Ch in LocalWordDelims);
end;

function TFileEditor.Search(const Match: String; AOptions: Word): Boolean;
begin
  Search := SearchPrim(@Self, Match, AOptions);
end;

function TFileEditor.GetWord(var B, E: Byte): String;
begin
  GetWord := GetWordPrim(@Self, B, E);
end;

function TFileEditor.GetLine: String;
begin
  GetLine := GetLinePrim(@Self);
end;

procedure TFileEditor.SwapTruncate;

function IsFirst(P: Pointer): Boolean; far;
begin
  IsFirst := P <> nil;
end;

var
  P: Pointer;
begin
  if (DiskSwapStream <> nil) and (SwapStream = DiskSwapStream) and
     (SwapStream^.GetSize = SwapSize) then
  begin
    P := FileLines^.FirstThat(@IsFirst);
    if P <> nil then
    begin
      SwapStream^.Seek(Longint(P));
      SwapStream^.Truncate;
    end;
  end;
end;

procedure TFileEditor.UpdateHistory;
var
  I, P, X, Y: Integer;
  R: PHistoryRec;
  S: String;
begin
  I := HistoryIndex(ReopenHistoryID,
    EditorTypes[Options and ofHex <> 0] + FileName^ + #$FF);
  if I <> -1 then
  begin
    R := HistoryList^.At(I);
    S := R^.StrPtr^;
    HistLock := Byte(R^.Lock);
    HistoryList^.AtFree(I);
    S := System.Copy(S, Pos(#$FF, S) + 1, 255);
    P := Pos(#$FF, S);
    if P <> 0 then
    begin
      if S[Length(S)] = #$FF then
      begin
	Dec(S[0]);
	State := State or sfSemicolon;
	SyntaxWord := swASM;
	Comment := ';';
      end;
      Val(System.Copy(S, 1, P - 1), X, I);
      Val(System.Copy(S, P + 1, 5), Y, I);
      GoToPos(X, Y);
      P := Pos(#$FF'PLACES', S);
      if P <> 0 then Move(S[P + 7], Places, SizeOf(TPlaces));
    end;
  end;
{ Added 20.09.2002 to support command line positioning }
  if (ParamStrCol >= 0) or (ParamStrRow >= 0) then
  begin
    if ParamStrCol >= 0 then X := ParamStrCol else X := Delta.X + Cursor.X;
    if ParamStrRow >= 0 then Y := ParamStrRow else Y := Delta.Y + Cursor.Y;
    GoToPos(X, Y);
  end;
end;

procedure TFileEditor.NewTitle(const Name: FNameStr);
begin
{
  DisposeStr(FileName);
  FileName := NewStr(Name);
}
  DisposeStrUMB(FileName);
  FileName := NewStrUMB(Name);
  DisposeStr(PWindow(Owner)^.Title);
  PWindow(Owner)^.Title := NewStr(Name);
  PWindow(Owner)^.Frame^.DrawView;
end;

{ TEditorWindow }
constructor TEditorWindow.Init(Bounds: TRect; var FileName: String);
var
  Control, IControl: PView;
  R: TRect;
begin
  TWindow.Init(Bounds, FileName, WindowNumAvail);
  Options := Options or (ofTileable + ofASCII + ofNewSize);

  GetExtent(R);
  Inc(R.A.X, 30); Dec(R.B.X, 2); R.A.Y := Pred(R.B.Y);
  Control := New(PScrollBar, Init(R));
  Insert(Control);

  GetExtent(R);
  Inc(R.A.X, 2); R.A.Y := Pred(R.B.Y); R.B.X := R.A.X + 27;
  IControl := New(PIndicator, Init(R));
  IControl^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(IControl);

  GetExtent(R);
  R.Grow(-1, -1);
  Editor := New(PFileEditor, Init(R, PScrollBar(Control),
    StandardScrollBar(sbVertical + sbHandleKeyboard), PIndicator(IControl)));
  Insert(Editor);
  PFileEditor(Editor)^.ReadFile(FileName);
end;

constructor TEditorWindow.Load(var S: TStream);
var
  Name: FNameStr;
begin
  TWindow.Load(S);
  GetSubViewPtr(S, Editor);
  if Options and ofNewSize = 0 then SetNewSizePrim(@Self);
  if Editor^.State and sfNoname <> 0 then Name := ''
  else Name := Title^;
  PFileEditor(Editor)^.ReadFile(Name);
end;

procedure TEditorWindow.ChangeBounds(var Bounds: TRect);
var
  R: TRect;
begin
  TWindow.ChangeBounds(Bounds);
  if ((Size.X = Editor^.Size.X) and (Size.X < Owner^.Size.X)) or
     ((Size.Y = Editor^.Size.Y) and (Size.Y < Owner^.Size.Y)) then
  begin
    GetExtent(R);
    R.Grow(-1, -1);
    Editor^.Locate(R);
  end;
end;

procedure TEditorWindow.Close;
const
  ofHTML = $8000;
var
  M: Byte;
  I: Integer;
  DX, DY: String[5];
  S: String;

function UsingSwapFile(P: PView): Boolean; far;
begin
  if TypeOf(P^) = TypeOf(TWinIcon) then P := PWinIcon(P)^.Window;
  UsingSwapFile := (P <> @Self) and
    (P^.Options and (ofASCII + ofHex + ofHTML) <> 0);
end;

begin
  with PFileEditor(Editor)^ do
  begin
    if IsDebug then
    begin
      Pending.What := evCommand;
      Pending.Command := cmClose;
      Pending.InfoPtr := nil;
      if not AbortUserProgram then Exit;
    end;
    M := SaveOrCancel;
    if (M = cmCancel) or ((M = cmYes) and not Save('', False)) then Exit;
  end;
  if TheSpooler^.InQueue(Editor) then
    if PrinterQueueMsgBox <> cmOk then Exit
    else TheSpooler^.DoUpdate := True;
  if (Editor^.State and sfNoname = 0) and (Length(Title^) <= 222) then
  begin
    S := EditorTypes[Editor^.Options and ofHex <> 0] + Title^;
    with PFileEditor(Editor)^ do
    begin
      Str(GetLinePos, DX);
      Str((Delta.Y + Cursor.Y):5, DY);
    end;
    S := S + #$FF + DX + #$FF + DY + #$FF#$FF;
    if Size.X = Editor^.Size.X then
      FillChar(S[Length(S) + 1], 8, OpenWideFiller)
    else Move(Origin, S[Length(S) + 1], 8);
    Inc(S[0], 8);
    if Length(S) < 254 - SizeOf(TPlaces) - 8 then
    begin
      S := S + #$FF'PLACES';
      Move(PFileEditor(Editor)^.Places, S[Length(S) + 1], SizeOf(TPlaces));
      Inc(S[0], SizeOf(TPlaces) + 1);
      S[Length(S)] := #0;
    end;
    if Editor^.State and sfSemicolon <> 0 then
    begin
      Inc(S[0]);
      S[Length(S)] := #$FF;
    end;
    HistoryAdd(ReopenHistoryID, S, False);
    if PFileEditor(Editor)^.HistLock <> 0 then
    begin
      I := HistoryIndex(ReopenHistoryID, S);
      if I <> -1 then
        Byte(PHistoryRec(HistoryList^.At(I))^.Lock) :=
          PFileEditor(Editor)^.HistLock;
    end;
  end;
  if Desktop^.FirstThat(@UsingSwapFile) = nil then
  begin
    DisableCommands(SaveAllCommands);
    if not PFileEditor(Editor)^.IsClip and (TheBack = nil) then
    begin
      PFileEditor(Editor)^.SwapStream^.Seek(10);
      PFileEditor(Editor)^.SwapStream^.Truncate;
    end;
  end;
  if PFileEditor(Editor)^.ParamStrExitOnClose then
  begin
    Pending.What := evCommand;
    Pending.Command := cmQuit;
    Pending.InfoPtr := nil;
  end;
  TWindow.Close;
end;

function TEditorWindow.GetPalette: PPalette;
const
  P: String[Length(CEditorWindow)] = CEditorWindow;
begin
  GetPalette := @P;
end;

function TEditorWindow.GetTitle(MaxSize: Integer): TTitleStr;
var
  S: TTitleStr;
begin
  if Title^[2] <> ':' then S := Title^
  else S := TrimmedName(Title^, Byte(MaxSize));
  if PFileEditor(Editor)^.UnixMode then S := S + ' (UNIX)';
  GetTitle := S;
end;

procedure TEditorWindow.SizeLimits(var Min, Max: TPoint);
begin
  TWindow.SizeLimits(Min, Max);
  Min.X := 35;
end;

procedure TEditorWindow.Store(var S: TStream);
begin
  TWindow.Store(S);
  PutSubViewPtr(S, Editor);
end;

procedure TEditorWindow.Zoom;
var
  CtrlDown, Full, Wide: Boolean;
  R: TRect;
begin
  CtrlDown := GetShiftState and
    (kbCtrlShift + kbLeftShift + kbRightShift) <> 0;
  Full := Longint(Size) = Longint(Owner^.Size);
  Wide := Longint(Size) = Longint(Editor^.Size);
  if not CtrlDown or not Full then TWindow.Zoom;
  if CtrlDown or Wide then
  begin
    GetExtent(R);
    if Wide then R.Grow(-1, -1);
    Editor^.Locate(R);
  end;
end;

end.