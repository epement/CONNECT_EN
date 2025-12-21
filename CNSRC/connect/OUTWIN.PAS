{$I-,X+,O+,F+}
unit OutWin;

interface

uses Objects, Drivers, Views;

type
  POutputCollection = ^TOutputCollection;
  TOutputCollection = object(TCollection)
    procedure FreeItem(P: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
  end;

  POutput = ^TOutput;
  TOutput = object(TScroller)
    DrawFlag: Boolean;
    OutputCollection: PCollection;
    EscSeq: String[127];
    Esc: Boolean;
    CurColor: Byte;
    SaveDelta: TPoint;
    SaveCursor: TPoint;
    ReservedStr: String[16];
    ReservedFlag: Boolean;
    LoY: Byte;
    HiY: Byte;
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Draw; virtual;
    function GetHelpCtx: Word; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure ClipCopy;
    function CheckEsc(AChar: Char): Boolean;
    procedure Clear;
    procedure DoEscSeq;
    procedure Enter;
    procedure EscClear;
    procedure EscClearEol;
    procedure EscDel;
    procedure EscDelLine;
    procedure EscDn;
    procedure EscEnter;
    procedure EscIns;
    procedure EscInsLine;
    procedure EscMoveCursor;
    procedure EscScrollDn;
    procedure EscScrollUp;
    procedure EscSendPos; virtual;
    procedure EscSetAttr;
    procedure EscSetCursor;
    procedure EscSetLoHi;
    procedure EscUp;
    procedure GetChar(AChar: Char); virtual;
    function GetWidth: Integer; virtual;
    function GetHeight: Integer; virtual;
    procedure NewLine(Index: Integer);
    procedure OptionsDialog; virtual;
    procedure PopUp(AnOrigin: TPoint);
    procedure UpdateLimit;
    procedure ValidLoHi;
  end;

  POutputWindow = ^TOutputWindow;
  TOutputWindow = object(TWindow)
    Scroller: POutput;
    constructor Init;
    constructor Load(var S: TStream);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
    procedure Zoom; virtual;
  end;

const
  COutputColor      = #$07#$0F#$0A#$31#$31#$07#$71#$71;
  COutputBlackWhite = #$07#$0F#$07#$70#$70#$07#$70#$70;
  COutputMonochrome = #$07#$0F#$07#$70#$70#$07#$70#$70;
  COutputViewer     = #6#7#8;
  COutputWindow     = #72#73#74#75#76#77#78#79;

  ANSIColors: Array[30..37] of Byte = (0, 4, 2, 6, 1, 5, 3, 7);

  TheOutput: POutput = nil;
  MaxEscLen = 126;

function MapColor(C: Byte): Byte;
procedure RSROutputWindow(RSR: PResourceFile);
procedure OpenOutput;
procedure OutStr(const S: String);

implementation

uses Memory, Menus, Dialogs, App, MsgBox, Popups, Swaps, CNInputs, ClipPrim,
  EditMsg, WinPos, CNWinPos, HeapUMB, TPString, Consts, Commands, Defaults;

function MapColor(C: Byte): Byte;
const
  MonoTable: Array[0..15] of Byte =
    (0, 1, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 15, 15);
var
  Fore, Back: Byte;
begin
  if (Lo(ScreenMode) <> smCO80) and (Lo(ScreenMode) <> smFont8x8) then
  begin
    Fore := C and $F;
    Back := (C shr 4) and $7;
      case Lo(ScreenMode) of
	smBW80, smMono:
          begin
            Fore := MonoTable[Fore];
            Back := MonoTable[Back];
	  end;
      end;
    if Lo(ScreenMode) = smMono then
      if (Fore or Back) <> 0 then
        if (Fore = 0) or (Back = $07) then
        begin
          Fore := 0;
          Back := $7;
        end
        else if Back <> 0 then Back := 0;
    if (C and $80) <> 0 then Back := Back or $08;
    MapColor := Byte(Back shl 4) or Fore;
  end
  else MapColor := C;
end;

procedure TOutputCollection.FreeItem(P: Pointer);
begin
  if P <> nil then
{    FreeMem(P, SizeOf(TDrawBuffer));}
    FreeMemUMB(P, SizeOf(TDrawBuffer));
end;

function TOutputCollection.GetItem(var S: TStream): Pointer;
var
  Item: Pointer;
begin
{
  Item := MemAlloc(SizeOf(TDrawBuffer));
  if Item <> nil then S.Read(Item^, SizeOf(TDrawBuffer));
}
  if LowMemory then Item := nil
  else
  begin
    GetMemUMB(Item, SizeOf(TDrawBuffer));
    S.Read(Item^, SizeOf(TDrawBuffer));
  end;
  GetItem := Item;
end;

procedure TOutputCollection.PutItem(var S: TStream; Item: Pointer);
begin
  S.Write(Item^, SizeOf(TDrawBuffer));
end;

constructor TOutput.Init(var Bounds: TRect;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
  State := State or sfCursorVis;
  GrowMode := gfGrowHiX + gfGrowHiY;
  OutputCollection := New(POutputCollection, Init(MaxOutputLines, 1));
  CurColor := $07;
  HiY := MaxOutputLines;
  EnableCommands(OutputCommands);
end;

constructor TOutput.Load(var S: TStream);
begin
  TScroller.Load(S);
  OutputCollection := POutputCollection(S.Get);
  S.Read(CurColor,
    SizeOf(CurColor) + SizeOf(SaveDelta) + SizeOf(SaveCursor) +
    SizeOf(ReservedStr) + SizeOf(ReservedFlag) + SizeOf(LoY) + SizeOf(HiY));
  EnableCommands(OutputCommands);
end;

destructor TOutput.Done;
begin
  if OutputCollection <> nil then Dispose(OutputCollection, Done);
  TScroller.Done;
  TheOutput := nil;
  DisableCommands(OutputCommands);
end;

procedure TOutput.Draw;
var
  I, Y: Integer;
  B: TDrawBuffer;
begin
  if DrawFlag then
  begin
    I := Delta.Y + Cursor.Y;
    if I < OutputCollection^.Count then Writeline(0, Cursor.Y, Size.X, 1,
      TDrawBuffer(OutputCollection^.At(I)^)[Delta.X])
    else
    begin
      MoveChar(B, ' ', $07, Size.X);
      WriteLine(0, Cursor.Y, Size.X, 1, B);
    end;
  end
  else for Y := 0 to Size.Y - 1 do
  begin
    I := Delta.Y + Y;
    if I < OutputCollection^.Count then Writeline(0, Y, Size.X, 1,
      TDrawBuffer(OutputCollection^.At(I)^)[Delta.X])
    else
    begin
      MoveChar(B, ' ', $07, Size.X);
      Writeline(0, Y, Size.X, 1, B);
    end;
  end;
end;

function TOutput.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else GetHelpCtx := hcOutputWindow;
end;

procedure TOutput.HandleEvent(var Event: TEvent);
var
  Spot: TPoint;
begin
  TScroller.HandleEvent(Event);
  if (Event.What = evMouseDown) and (Event.Buttons = mbRightButton) then
  begin
    repeat until not MouseEvent(Event, evMouseDown);
    PopUp(Event.Where);
    Event.What := evNothing;
  end
  else if Event.What = evCommand then
  begin
    case Event.Command of
      cmCopy: ClipCopy;
      cmExecOptions: OptionsDialog;
      cmPopup:
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
  else if Event.What = evBroadcast then
  begin
    case Event.Command of
      cmOutput:
	begin
	  PWindow(Owner)^.Deiconize;
          Owner^.Show;
	  Owner^.Select;
        end;
      cmClearOutput:
        begin
          CurColor := $07;
          Clear;
        end;
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

procedure TOutput.SetState(AState: Word; Enable: Boolean);
begin
  TScroller.SetState(AState, Enable);
  if (AState = sfFocused) and Enable then
    EnableCommands(CopyCommands + MTCopyCommands)
  else if not Enable and
    (((AState and (sfActive + sfSelected) <> 0) and GetState(sfExposed)) or
    (AState = sfExposed)) then DisableCommands(
      CopyCommands + MTCopyCommands);
end;

procedure TOutput.Store(var S: TStream);
begin
  TScroller.Store(S);
  S.Put(OutputCollection);
  S.Write(CurColor,
    SizeOf(CurColor) + SizeOf(SaveDelta) + SizeOf(SaveCursor) +
    SizeOf(ReservedStr) + SizeOf(ReservedFlag) + SizeOf(LoY) + SizeOf(HiY));
end;

procedure GetStr(const Buf; var Str: String); assembler;
asm
        MOV     DX,DS
        LDS     SI,Buf
        LES     DI,Str
        MOV     BYTE PTR ES:[DI],MaxViewWidth
        INC     DI
        CLD
        MOV     CX,MaxViewWidth
@@1:    LODSW
        STOSB
        LOOP    @@1
        MOV     DS,DX
end;

procedure TOutput.ClipCopy;
var
  I, N, SaveCount, MaxLen: Integer;
  C: String[1];
  S: String;
begin
  if DiskClipStream = nil then Exit;
  SetExpandClipAreaFlag;
  MaxLen := 0;
  I := 0;
  N := 0;
  SaveCount := ClipLines^.Count;
  while I < OutputCollection^.Count do
  begin
    GetStr(OutputCollection^.At(I)^, S);
    TrailTrim(S);
    if S = '' then Inc(N)
    else
    begin
      C := '';
      for N := N - 1 downto 0 do PutClipLine(C);
      PutClipLine(S);
      if not MarkColumns or (Length(S) > MaxLen) then MaxLen := Length(S);
    end;
    if ClipOverflow then Break;
    Inc(I);
  end;
  SetOrExpandClipArea(SaveCount, MaxLen + 1);
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

function TOutput.CheckEsc(AChar: Char): Boolean;
begin
  CheckEsc := False;
  if (not Esc and (AChar <> #27)) or
     (Esc and (AChar = #27) and (EscSeq = '')) then Exit;
  Esc := True;
  CheckEsc := True;
  if AChar <> #27 then
  begin
    Inc(EscSeq[0]);
    EscSeq[Length(EscSeq)] := AChar;
  end;
  if (EscSeq = '') or (EscSeq = '[') then Exit;
  if not (AChar in ['0'..'9', ';', '?']) or
    (Length(EscSeq) > MaxEscLen) then DoEscSeq;
end;

procedure TOutput.Clear;
var
  I: Integer;
begin
  OutputCollection^.FreeAll;
  ScrollTo(0, 0);
  SetCursor(0, 0);
  for I := 0 to GetHeight - 1 do NewLine(I);
  SetLimit(GetWidth, GetHeight);
  DrawView;
end;

procedure TOutput.DoEscSeq;
begin
  if Length(EscSeq) = 1 then
    case EscSeq[1] of
      'D': EscDn;
      'E': EscEnter;
      'M': EscUp;
    end
  else
    case EscSeq[Length(EscSeq)] of
      'J':             EscClear;
      'K':             EscClearEol;
      'P':             EscDel;
      'M':             EscDelLine;
      '@':             EscIns;
      'L':             EscInsLine;
      'A'..'D':        EscMoveCursor;
      'T':             EscScrollDn;
      'S':             EscScrollUp;
      'm':             EscSetAttr;
      'H','f','s','u': EscSetCursor;
      'r':             EscSetLoHi;
      'n':             EscSendPos;
    end;
  Esc := False;
  EscSeq := '';
end;

procedure TOutput.Enter;
begin
  if Delta.Y + Cursor.Y + 1 = Limit.Y then
  begin
    NewLine(OutputCollection^.Count);
    DrawView;
    Exit;
  end;
  DrawFlag := True;
  DrawView;
  DrawFlag := False;
  SetCursor(Cursor.X, Cursor.Y + 1);
  if Cursor.Y >= Size.Y then ScrollTo(Delta.X, Delta.Y + 1);
  if Cursor.Y >= Size.Y then SetCursor(Cursor.X, Size.Y - 1);
end;

procedure TOutput.EscClear;
var
  C: Byte;
  I: Integer;
  P: ^TDrawBuffer;
begin
  C := CurColor;
  if C = 0 then C := $07;
  if EscSeq = '[2J' then Clear
  else if EscSeq = '[1J' then
  begin
    for I := 0 to Delta.Y + Cursor.Y - 1 do
    begin
      P := OutputCollection^.At(I);
      if P <> nil then MoveChar(P^, ' ', C, MaxViewWidth);
    end;
    I := Delta.Y + Cursor.Y;
    P := OutputCollection^.At(I);
    if P <> nil then MoveChar(P^, ' ', C, Delta.X + Cursor.X + 1);
    DrawView;
  end
  else if (EscSeq = '[0J') or (EscSeq = '[J') then
  begin
    for I := Delta.Y + Cursor.Y + 1 to OutputCollection^.Count - 1 do
    begin
      P := OutputCollection^.At(I);
      if P <> nil then MoveChar(P^, ' ', C, MaxViewWidth);
    end;
    I := Delta.Y + Cursor.Y;
    P := OutputCollection^.At(I);
    if P <> nil then MoveChar(
      P^[Delta.X + Cursor.X], ' ', C, MaxViewWidth - Delta.X - Cursor.X);
    DrawView;
  end;
end;

procedure TOutput.EscClearEol;
var
  C: Byte;
  P: ^TDrawBuffer;
begin
  P := OutputCollection^.At(Delta.Y + Cursor.Y);
  if P = nil then Exit;
  C := CurColor;
  if C = 0 then C := $07;
  if EscSeq = '[2K' then MoveChar(P^, ' ', C, MaxViewWidth)
  else if EscSeq = '[1K' then MoveChar(P^, ' ', C, Delta.X + Cursor.X + 1)
  else if (EscSeq = '[0K') or (EscSeq = '[K') then MoveChar(
    P^[Delta.X + Cursor.X], ' ', C, MaxViewWidth - Delta.X - Cursor.X);
  DrawFlag := True;
  DrawView;
  DrawFlag := False;
end;

procedure TOutput.EscDel;
var
  S: String[3];
  P: ^TDrawBuffer;
  D, Code: Integer;
begin
  S := Copy(EscSeq, 2, Length(EscSeq) - 2);
  if S = '' then D := 1
  else
  begin
    Val(S, D, Code);
    if D = 0 then Exit;
  end;
  P := OutputCollection^.At(Delta.Y + Cursor.Y);
  if P = nil then Exit;
  if Delta.X + Cursor.X + D > GetWidth then
    D := GetWidth - Delta.X - Cursor.X;
  Move(P^[Delta.X + Cursor.X + D], P^[Delta.X + Cursor.X],
    (GetWidth - Delta.X - Cursor.X - D) * 2);
  MoveChar(P^[GetWidth - D], ' ', 0, D);
  DrawFlag := True;
  DrawView;
  DrawFlag := False;
end;

procedure TOutput.EscDelLine;
var
  S: String[3];
  D, Code: Integer;
begin
  ValidLoHi;
  if Delta.Y + Cursor.Y > HiY then Exit;
  S := Copy(EscSeq, 2, Length(EscSeq) - 2);
  if S = '' then D := 1
  else
  begin
    Val(S, D, Code);
    if D = 0 then Exit;
  end;
  if Delta.Y + Cursor.Y + D > HiY + 1 then
    D := HiY + 1 - Delta.Y - Cursor.Y;
  for Code := 1 to D do
  begin
    OutputCollection^.AtFree(Delta.Y + Cursor.Y);
    NewLine(HiY);
  end;
  DrawView;
end;

procedure TOutput.EscDn;
begin
  ValidLoHi;
  if Delta.Y + Cursor.Y < HiY then
  begin
    SetCursor(Cursor.X, Cursor.Y + 1);
    if Cursor.Y >= Size.Y then ScrollTo(Delta.X, Delta.Y + 1);
  end
  else
  begin
    SetCursor(Cursor.X, HiY - Delta.Y);
    if Cursor.Y < 0 then
      ScrollTo(Self.Delta.X, Self.Delta.Y + Cursor.Y)
    else if Cursor.Y >= Size.Y then
      ScrollTo(Self.Delta.X, Self.Delta.Y + Cursor.Y - Size.Y + 1);
    OutputCollection^.AtFree(LoY);
    NewLine(HiY);
    DrawView;
  end;
end;

procedure TOutput.EscUp;
begin
  ValidLoHi;
  if Delta.Y + Cursor.Y > LoY then
  begin
    SetCursor(Cursor.X, Cursor.Y - 1);
    if Cursor.Y < 0 then ScrollTo(Delta.X, Delta.Y - 1);
  end
  else
  begin
    SetCursor(Cursor.X, LoY - Delta.Y);
    if Cursor.Y < 0 then
      ScrollTo(Self.Delta.X, Self.Delta.Y + Cursor.Y)
    else if Cursor.Y >= Size.Y then
      ScrollTo(Self.Delta.X, Self.Delta.Y + Cursor.Y - Size.Y + 1);
    OutputCollection^.AtFree(HiY);
    NewLine(LoY);
    DrawView;
  end;
end;

procedure TOutput.EscEnter;
begin
  EscDn;
  ScrollTo(0, Delta.Y);
  SetCursor(0, Cursor.Y);
end;

procedure TOutput.EscIns;
var
  S: String[3];
  P: ^TDrawBuffer;
  D, Code: Integer;
begin
  S := Copy(EscSeq, 2, Length(EscSeq) - 2);
  if S = '' then D := 1
  else
  begin
    Val(S, D, Code);
    if D = 0 then Exit;
  end;
  P := OutputCollection^.At(Delta.Y + Cursor.Y);
  if P = nil then Exit;
  if Delta.X + Cursor.X + D > GetWidth then
    D := GetWidth - Delta.X - Cursor.X;
  Move(P^[Delta.X + Cursor.X], P^[Delta.X + Cursor.X + D],
    (GetWidth - Delta.X - Cursor.X - D) * 2);
  MoveChar(P^[Delta.X + Cursor.X], ' ', 0, D);
  DrawFlag := True;
  DrawView;
  DrawFlag := False;
end;

procedure TOutput.EscInsLine;
var
  S: String[3];
  D, Code: Integer;
begin
  ValidLoHi;
  if Delta.Y + Cursor.Y > HiY then Exit;
  S := Copy(EscSeq, 2, Length(EscSeq) - 2);
  if S = '' then D := 1
  else
  begin
    Val(S, D, Code);
    if D = 0 then Exit;
  end;
  if Delta.Y + Cursor.Y + D > HiY + 1 then
    D := HiY - Delta.Y - Cursor.Y;
  for Code := 1 to D do
  begin
    OutputCollection^.AtFree(HiY);
    NewLine(Delta.Y + Cursor.Y);
  end;
  DrawView;
end;

procedure TOutput.EscMoveCursor;
var
  S: String[3];
  D, Code: Integer;
  C: Char;
begin
  S := Copy(EscSeq, 2, Length(EscSeq) - 2);
  if S = '' then D := 1
  else
  begin
    Val(S, D, Code);
    if D = 0 then Exit;
  end;
  C := EscSeq[Length(EscSeq)];
  case C of
    'A': Dec(Cursor.Y, D);
    'B': Inc(Cursor.Y, D);
    'C': Inc(Cursor.X, D);
    'D': Dec(Cursor.X, D);
    else Exit;
  end;
  if Delta.X + Cursor.X >= Limit.X then
    Cursor.X := Limit.X - Delta.X - 1;
  if Cursor.X < 0 then ScrollTo(Delta.X - D, Delta.Y)
  else if Cursor.X >= Size.X then ScrollTo(Delta.X + D, Delta.Y);
  if Delta.Y + Cursor.Y >= Limit.Y then
    Cursor.Y := Limit.Y - Delta.Y - 1;
  if Cursor.Y < 0 then ScrollTo(Delta.X, Delta.Y - D)
  else if Cursor.Y >= Size.Y then ScrollTo(Delta.X, Delta.Y + D);
  if Cursor.X < 0 then Cursor.X := 0
  else if Cursor.X >= Size.X then Cursor.X := Size.X - 1;
  if Cursor.Y < 0 then Cursor.Y := 0
  else if Cursor.Y >= Size.Y then Cursor.Y := Size.Y - 1;
  SetCursor(Cursor.X, Cursor.Y);
end;

procedure TOutput.EscScrollDn;
var
  S: String[3];
  D, Code: Integer;
begin
  ValidLoHi;
  S := Copy(EscSeq, 2, Length(EscSeq) - 2);
  if S = '' then D := 1
  else
  begin
    Val(S, D, Code);
    if D = 0 then Exit;
  end;
  if D > HiY - LoY + 1 then D := HiY - LoY + 1;
  for Code := 1 to D do
  begin
    OutputCollection^.AtFree(HiY);
    NewLine(LoY);
  end;
  DrawView;
end;

procedure TOutput.EscScrollUp;
var
  S: String[3];
  D, Code: Integer;
begin
  ValidLoHi;
  S := Copy(EscSeq, 2, Length(EscSeq) - 2);
  if S = '' then D := 1
  else
  begin
    Val(S, D, Code);
    if D = 0 then Exit;
  end;
  if D > HiY - LoY + 1 then D := HiY - LoY + 1;
  for Code := 1 to D do
  begin
    OutputCollection^.AtFree(LoY);
    NewLine(HiY);
  end;
  DrawView;
end;

procedure TOutput.EscSendPos;
begin
end;

procedure TOutput.EscSetAttr;
var
  S: String[3];
  P: Byte;
  I, Code: Integer;
begin
  S := '';
  P := 2;
  while P <= Length(EscSeq) do
  begin
    if not (EscSeq[P] in ['0'..'9']) then
    begin
      Val(S, I, Code);
      case I of
        0: CurColor := $07;
        1: CurColor := CurColor or $8;
        2: CurColor := CurColor and not $8;
        4: CurColor := $01;
        5: CurColor := CurColor or $80;
        7: CurColor := (CurColor and $0F) shl 4 or
             (CurColor and $F0) shr 4;
        8: CurColor := 0;
        30..37: CurColor := CurColor and $F0 or ANSIColors[I] or
          (CurColor and $0F and $8);
        40..47: CurColor := CurColor and $0F or
          (ANSIColors[I - 10] shl 4) or (CurColor and $F0 and $80);
      end;
      S := '';
    end
    else S := S + EscSeq[P];
    Inc(P);
  end;
  CurColor := MapColor(CurColor);
end;

procedure TOutput.EscSetCursor;
var
  S: String[3];
  Which: Boolean;
  P: Byte;
  I, Code: Integer;
begin
  if EscSeq = '[s' then
  begin
    SaveDelta := Delta;
    SaveCursor := Cursor;
  end
  else if EscSeq = '[u' then
  begin
    ScrollTo(SaveDelta.X, SaveDelta.Y);
    SetCursor(SaveCursor.X, SaveCursor.Y);
  end
  else if (EscSeq = '[f') or (EscSeq = '[H') then
  begin
    ScrollTo(0, 0);
    SetCursor(0, 0)
  end
  else
  begin
    S := '';
    P := 2;
    Which := False;
    while P <= Length(EscSeq) do
    begin
      if not (EscSeq[P] in ['0'..'9']) then
      begin
        Val(S, I, Code);
        if Code = 0 then
        begin
          Dec(I);
          if Which then
          begin
            if I < 0 then I := 0
            else if I >= Limit.X then I := Limit.X - 1;
            SetCursor(I - Delta.X, Cursor.Y);
            if Cursor.X < 0 then
              ScrollTo(Self.Delta.X + Cursor.X, Self.Delta.Y)
            else if Cursor.X >= Size.X then
              ScrollTo(Self.Delta.X + Cursor.X - Size.X + 1, Self.Delta.Y);
          end
          else
          begin
            if I < 0 then I := 0
            else if I >= Limit.Y then I := Limit.Y - 1;
            SetCursor(Cursor.X, I - Delta.Y);
            if Cursor.Y < 0 then
              ScrollTo(Self.Delta.X, Self.Delta.Y + Cursor.Y)
            else if Cursor.Y >= Size.Y then
              ScrollTo(Self.Delta.X, Self.Delta.Y + Cursor.Y - Size.Y + 1);
          end;
        end;
        S := '';
        Which := not Which;
      end
      else S := S + EscSeq[P];
      Inc(P);
    end;
  end;
end;

procedure TOutput.EscSetLoHi;
var
  S: String[3];
  Which: Boolean;
  P, B: Byte;
  Code: Integer;
begin
  LoY := 0;
  HiY := MaxOutputLines;
  S := '';
  P := 2;
  Which := False;
  while P <= Length(EscSeq) do
  begin
    if not (EscSeq[P] in ['0'..'9']) then
    begin
      Val(S, B, Code);
      if B <> 0 then
      begin
        Dec(B);
        if Which then HiY := B
        else LoY := B;
      end;
      S := '';
      Which := not Which;
    end
    else S := S + EscSeq[P];
    Inc(P);
  end;
  if HiY <= LoY then HiY := MaxOutputLines;
  ScrollTo(0, 0);
  SetCursor(0, 0)
end;

procedure TOutput.GetChar(AChar: Char);
var
  I: Integer;
  P: ^TDrawBuffer;
begin
  with OutputCollection^ do
  begin
    if Count = 0 then Clear;
    UpdateLimit;
    if Self.Delta.X + Cursor.X >= Self.Limit.X then
      SetCursor(Self.Limit.X - Self.Delta.X - 1, Cursor.Y);
    if Cursor.X < 0 then
      ScrollTo(Self.Delta.X + Cursor.X, Self.Delta.Y)
    else if Cursor.X >= Size.X then
      ScrollTo(Self.Delta.X + Cursor.X - Size.X + 1, Self.Delta.Y);
    if (Cursor.Y < 0) or (Cursor.Y >= Size.Y) then
      ScrollTo(Self.Delta.X, Self.Delta.Y + Cursor.Y - Size.Y div 2);
    if CheckEsc(AChar) then Exit;
    P := At(Self.Delta.Y + Cursor.Y);
    if P = nil then Exit;
    case AChar of
      #7:
        begin
          if not DisableSounds then Write(^G);
          Exit;
        end;
      #8: if Self.Delta.X + Cursor.X > 0 then
        begin
          SetCursor(Cursor.X - 1, Cursor.Y);
          if Cursor.X < 0 then
            ScrollTo(Self.Delta.X - 1, Self.Delta.Y);
          if OutputOptions and ooDestructiveBS <> 0 then
            WordRec(P^[Self.Delta.X + Cursor.X]).Lo := 0;
        end;
      #9:
        begin
          I := 9 - ((Self.Delta.X + Cursor.X + 1) mod 8);
          if I = 9 then I := 1;
          SetCursor(Cursor.X + I, Cursor.Y);
          if Cursor.X >= Size.X then
            ScrollTo(Self.Delta.X + Cursor.X - Size.X + 1, Self.Delta.Y);
          if Cursor.X >= Size.X then SetCursor(Size.X - 1, Cursor.Y);
        end;
      #10:
        begin
          if OutputOptions and ooAddReturn <> 0 then
          begin
            ScrollTo(0, Self.Delta.Y);
            SetCursor(0, Cursor.Y);
          end;
          Enter;
        end;
      #12:
        begin
          Clear;
          Exit;
        end;
      #13:
        begin
          ScrollTo(0, Self.Delta.Y);
          SetCursor(0, Cursor.Y);
          if OutputOptions and ooAddLineFeed <> 0 then Enter;
        end;
      else
      begin
	if CurColor = 0 then AChar := ' ';
	WordRec(P^[Self.Delta.X + Cursor.X]).Lo := Byte(AChar);
        WordRec(P^[Self.Delta.X + Cursor.X]).Hi := CurColor;
	SetCursor(Cursor.X + 1, Cursor.Y);
	if Cursor.X >= Size.X then
          if Self.Limit.X = Size.X then DrawView
          else ScrollTo(Self.Delta.X + 1, Self.Delta.Y);
        if Self.Delta.X + Cursor.X >= Self.Limit.X then
          if OutputOptions and ooAutoWrap <> 0 then
          begin
            Enter;
            ScrollTo(0, Self.Delta.Y);
            SetCursor(0, Cursor.Y);
          end
          else SetCursor(Cursor.X - 1, Cursor.Y);
      end;
    end;
  end;
  DrawFlag := True;
  DrawView;
  DrawFlag := False;
end;

function TOutput.GetWidth: Integer;
begin
  GetWidth := OutputWidth;
end;

function TOutput.GetHeight: Integer;
begin
  GetHeight := OutputHeight;
end;

procedure TOutput.NewLine(Index: Integer);
var
  C: Byte;
  P: Pointer;
begin
  C := CurColor;
  if C = 0 then C := $07;
  with OutputCollection^ do
  begin
    while Count >= GetHeight do AtFree(0);
{
    P := MemAlloc(SizeOf(TDrawBuffer));
    if P <> nil then
}
    if not LowMemory then
    begin
      GetMemUMB(P, SizeOf(TDrawBuffer));
      MoveChar(P^, ' ', C, MaxViewWidth);
      if Index > Count then Index := Count;
      AtInsert(Index, P);
    end;
  end;
end;

function OutputOptionsDialog: PDialog;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 44, 12);
  D := New(PDialog, Init(R, 'Output options'));
  with D^ do
  begin
    HelpCtx := hcOutputOptions;
    Options := Options or ofCentered;

    R.Assign(3, 3, 30, 7);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('Add ~L~ine Feed',
      NewSItem('Add ~R~eturn',
      NewSItem('Auto ~w~rap',
      NewSItem('Destructive ~B~ackspace', nil))))));
    Insert(Control);
    R.Assign(2, 2, 30, 3);
    Insert(New(PLabel, Init(R, 'Output options', Control)));

    R.Assign(11, Size.Y - 3, 16, Size.Y - 2);
    Control := New(PCInputLine, Init(R, 3, 1, MaxViewWidth));
    Insert(Control);
    R.Assign(2, Size.Y - 3, 11, Size.Y - 2);
    Insert(New(PLabel, Init(R, '~C~olumns', Control)));

    R.Assign(26, Size.Y - 3, 30, Size.Y - 2);
    Control := New(PCInputLine, Init(R, 2, 1, MaxOutputLines));
    Insert(Control);
    R.Assign(20, Size.Y - 3, 26, Size.Y - 2);
    Insert(New(PLabel, Init(R, 'R~o~ws', Control)));

    R.Assign(Size.X - 13, 3, Size.X - 3, 5);
    StandardOkButton(R, D);
    Inc(R.A.Y, 3); Inc(R.B.Y, 3);
    StandardCancelButton(R, D);
    Inc(R.A.Y, 3); Inc(R.B.Y, 3);
    StandardHelpButton(R, D);
    SelectNext(False);
  end;
  OutputOptionsDialog := PDialog(Application^.ValidView(D));
end;

procedure TOutput.OptionsDialog;
type
  TDialogData = record
    Opt: Word;
    Col: String[3];
    Row: String[2];
  end;
var
  D: PDialog;
  Data: TDialogData;
  Code: Integer;
begin
  D := PDialog(Resource^.Get('OUTPUTDIALOG'));
  if D = nil then
  begin
    ResourceNotFoundMsgBox('Output options dialog');
    Exit;
  end;
  Data.Opt := OutputOptions;
  Str(OutputWidth, Data.Col);
  Str(OutputHeight, Data.Row);
  if Application^.ExecuteDialog(D, @Data, False) <> cmCancel then
  begin
    OutputOptions := Data.Opt;
    Val(Data.Col, OutputWidth, Code);
    Val(Data.Row, OutputHeight, Code);
  end;
end;

procedure TOutput.PopUp(AnOrigin: TPoint);
begin
  ShowPopup(AnOrigin, NewMenu(
    NewItem('~C~opy', 'Ctrl+Ins', kbCtrlIns, cmCopy, hcCopyOutput,
    NewItem('C~l~ear', 'Ctrl+Del', kbCtrlDel, cmClearOutput, hcDClearOutput,
    NewItem('~O~ptions...', '', kbNoKey, cmExecOptions, hcOOptions,
      nil)))));
end;

procedure TOutput.UpdateLimit;
var
  I: Integer;
begin
  if (Limit.X <> GetWidth) or (Limit.Y <> GetHeight) then
  begin
    while OutputCollection^.Count > GetHeight do
    begin
      OutputCollection^.AtFree(0);
      Dec(Cursor.Y);
    end;
    for I := 1 to GetHeight - OutputCollection^.Count do
      NewLine(OutputCollection^.Count);
    SetLimit(GetWidth, GetHeight);
  end;
end;

procedure TOutput.ValidLoHi;
begin
  if LoY >= Limit.Y - 1 then LoY := Limit.Y - 2;
  if HiY >= Limit.Y then HiY := Limit.Y - 1;
end;

constructor TOutputWindow.Init;
var
  R: TRect;
begin
  Desktop^.GetExtent(R); R.A.Y := R.B.Y - 8;
  TWindow.Init(R, 'Output', wnNoNumber);
  Options := Options or ofValidate;
  GetExtent(R);
  R.Grow(-1, -1);
  Scroller := New(POutput, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard)));
  Insert(Scroller);
  WinPos := @OutpWinPos;
end;

constructor TOutputWindow.Load(var S: TStream);
begin
  TWindow.Load(S);
  GetSubViewPtr(S, Scroller);
  WinPos := @OutpWinPos;
  TheOutput := Scroller;
end;

procedure TOutputWindow.ChangeBounds(var Bounds: TRect);
var
  R: TRect;
begin
  TWindow.ChangeBounds(Bounds);
  if ((Size.X = Scroller^.Size.X) and (Size.X < Owner^.Size.X)) or
     ((Size.Y = Scroller^.Size.Y) and (Size.Y < Owner^.Size.Y)) then
  begin
    GetExtent(R);
    R.Grow(-1, -1);
    Scroller^.Locate(R);
  end;
  if (WinPos <> nil) and
     (Size.X = Scroller^.Size.X) and (Size.Y = Scroller^.Size.Y) then
    PWinPosRec(WinPos)^.AX := -1;
end;

function TOutputWindow.GetPalette: PPalette;
const
  P: String[Length(COutputWindow)] = COutputWindow;
begin
  GetPalette := @P;
end;

procedure TOutputWindow.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evKeyDown) and
     (Event.CharCode in
       [^S, ^D, ^E, ^X, ^A, ^F, ^G, ^V, ^R, ^C, ^H, #27]) then Exit;
  TWindow.HandleEvent(Event);
end;

procedure TOutputWindow.SizeLimits(var Min, Max: TPoint);
begin
  TWindow.SizeLimits(Min, Max);
  Min.X := 20;
end;

procedure TOutputWindow.Store(var S: TStream);
begin
  TWindow.Store(S);
  PutSubViewPtr(S, Scroller);
end;

procedure TOutputWindow.Zoom;
var
  R: TRect;
begin
  TWindow.Zoom;
  if (Longint(Size) = Longint(Owner^.Size)) and
     (GetShiftState and (kbCtrlShift + kbLeftShift + kbRightShift) = 0) then
  begin
    GetExtent(R);
    Scroller^.Locate(R);
    if WinPos <> nil then PWinPosRec(WinPos)^.AX := -1;
  end;
end;

procedure OutStr(const S: String);
var
  B: Byte;
begin
  if TheOutput = nil then
  begin
    OpenOutput;
    if TheOutput = nil then Exit;
  end;
  for B := 1 to Length(S) do TheOutput^.GetChar(S[B]);
end;

procedure RSROutputWindow(RSR: PResourceFile);
var
  W: POutputWindow;
  D: PDialog;
begin
  W := New(POutputWindow, Init);
  RSR^.Put(W, 'OUTPUTWINDOW');
  Dispose(W, Done);
  D := OutputOptionsDialog;
  if D <> nil then
  begin
    RSR^.Put(D, 'OUTPUTDIALOG');
    Dispose(D, Done);
  end;
end;

procedure OpenOutput;
var
  Wide: Boolean;
  W: PWindow;
  R: TRect;
begin
  if Message(Desktop, evBroadcast, cmOutput, nil) = nil then
  begin
    W := POutputWindow(Resource^.Get('OUTPUTWINDOW'));
    if W <> nil then
    begin
      Wide := OutpWinPos.AX = -1;
      if not Wide and (WinPosMask and wpOutp <> 0) and
	ValidWinPos(OutpWinPos) then
	  SetWinPos(Desktop, OutpWinPos, R)
      else
      begin
	Desktop^.GetExtent(R);
	if not Wide then R.A.Y := R.B.Y - 8;
      end;
      W^.Locate(R);
      if Wide then
      begin
	W^.GetExtent(R);
	POutputWindow(W)^.Scroller^.Locate(R);
      end;
      Application^.InsertWindow(W);
    end
    else ResourceNotFoundMsgBox('Output window');
  end;
end;

end.
