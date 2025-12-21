{$I-,F+,O+,X+}
unit ViewFind;

interface

uses Objects, Views, Drivers, Dialogs;

type
  PViewerFindAllList = ^TViewerFindAllList;
  TViewerFindAllList = object(TListViewer)
    Caller: PView;
    LineBuffer: PCollection;
    TopLine: Integer;
    constructor Init(var Bounds: TRect; ANumCols: Integer;
      AHScrollBar, AVScrollBar: PScrollBar);
    destructor Done; virtual;
    procedure GetData(var Rec); virtual;
    procedure GetLine(Index: Integer; var S: String); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    function GetCallerCount: Integer; virtual;
    function GetCallerPtr(Index: Integer): Pointer; virtual;
    procedure DeleteFocused; virtual;
    procedure ClipCopy;
    procedure UpdateCommands; virtual;
  end;

  PHexViewerFindAllList = ^THexViewerFindAllList;
  THexViewerFindAllList = object(TViewerFindAllList)
    procedure GetLine(Index: Integer; var S: String); virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    function GetCallerCount: Integer; virtual;
    function GetCallerPtr(Index: Integer): Pointer; virtual;
    procedure DeleteFocused; virtual;
    procedure UpdateCommands; virtual;
  end;

function ViewerFindAllDialog(Count: Integer; Hex: Boolean): PDialog;

implementation

uses App, Swaps, ClipPrim, TxtView, HexView, FindAll, StrCol, HeapUMB,
  DosTools, EditMsg, Keyboard, TPString, Consts, Commands, Defaults;

const
  MaxLines = 64;

constructor TViewerFindAllList.Init(var Bounds: TRect; ANumCols: Integer;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TListViewer.Init(Bounds, 1, AHScrollBar, AVScrollBar);
  GrowMode := gfGrowHiY;
  LineBuffer := New(PStringsCollection, Init(MaxLines, 1));
end;

destructor TViewerFindAllList.Done;
begin
  Dispose(LineBuffer, Done);
  TListViewer.Done;
end;

procedure TViewerFindAllList.GetData(var Rec);
begin
  Longint(Rec) := Longint(GetCallerPtr(Focused));
end;

procedure TViewerFindAllList.GetLine(Index: Integer; var S: String);
var
  I: Integer;
  P: PString;
  L: Longint;
begin
  if (Index < TopLine) or (Index >= TopLine + LineBuffer^.Count) then
  begin
    LineBuffer^.FreeAll;
    TopLine := Index - MaxLines div 2;
    if TopLine + MaxLines > Range then TopLine := Range - MaxLines;
    if TopLine < 0 then TopLine := 0;
    I := TopLine;
    with PTextViewer(Caller)^ do
    begin
      OpenSource;
      while (I < TopLine + MaxLines) and (I < Range) do
      begin
	L := Longint(GetCallerPtr(I));
	TextSeek(Source, L);
	if Eof(Source) then S := ''
	else ReadLine(S);
	S := Trim(Detab(S, TabSize));
{	LineBuffer^.Insert(NewStr(S));}
	LineBuffer^.Insert(NewStrUMB(S));
	Inc(I);
      end;
      CloseSource;
    end;
  end;
  I := Index - TopLine;
  P := LineBuffer^.At(I);
  if P = nil then S := '' else S := P^;
end;

function TViewerFindAllList.GetText(Item: Integer; MaxLen: Integer): String;
var
  S: String;
begin
  GetLine(Item, S);
  GetText := S;
end;

procedure TViewerFindAllList.HandleEvent(var Event: TEvent);
var
  P: Pointer;
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    Event.What := evCommand;
    if Event.CharCode = ' ' then Event.Command := cmModifyItem
    else Event.Command := cmNewItem;
  end
  else if Event.What = evKeyDown then
    case Event.KeyCode of
      kbDel:
	begin
	  Event.What := evCommand;
	  Event.Command := cmDeleteItem;
	end;
      kbCtrlIns:
	begin
	  Event.What := evCommand;
	  Event.Command := cmCopy;
	end;
    end;
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmNewItem: if CommandEnabled(cmNewItem) then EndModal(cmOk);
      cmModifyItem: if CommandEnabled(cmModifyItem) then
	Message(Caller, evBroadcast, cmTrackSource, GetCallerPtr(Focused));
      cmDeleteItem: if CommandEnabled(cmDeleteItem) then
	begin
	  DeleteFocused;
	  LineBuffer^.FreeAll;
	  TopLine := MaxInt;
	  SetRange(GetCallerCount);
	  UpdateCommands;
	  DrawView;
	end;
      cmCopy: ClipCopy;
      else Exit;
    end;
    Event.What := evNothing;
  end;
  TListViewer.HandleEvent(Event);
end;

procedure TViewerFindAllList.SetData(var Rec);
var
  C, I: Integer;
  L: Longint;
begin
  Caller := PView(Rec);
  SetRange(GetCallerCount);
  if TypeOf(Caller^) = TypeOf(THexViewer) then
  begin
    HScrollBar^.SetRange(0, 0);
    L := PHexViewer(Caller)^.CurPos;
  end
  else
  begin
    HScrollBar^.SetRange(0, $FF);
    L := PTextViewer(Caller)^.CurPos.FilePos;
  end;
  C := GetCallerCount;
  I := 0;
  while (I < C - 1) and (Longint(GetCallerPtr(I)) < L) do Inc(I);
  FocusItem(I);
  UpdateCommands;
end;

function TViewerFindAllList.GetCallerCount: Integer;
begin
  GetCallerCount := PTextViewer(Caller)^.FindAllList^.Count;
end;

function TViewerFindAllList.GetCallerPtr(Index: Integer): Pointer;
begin
  GetCallerPtr :=
    PSwapLinesCollection(
      PTextViewer(Caller)^.FindAllList)^.ExtraAt(Index);
end;

procedure TViewerFindAllList.DeleteFocused;
begin
  PSwapLinesCollection(
    PTextViewer(Caller)^.FindAllList)^.ExtraAtFree(Focused);
end;

procedure TViewerFindAllList.ClipCopy;
var
  I, SaveCount, MaxLen: Integer;
  S: String;
begin
  if (DiskClipStream = nil) or (GetCallerCount = 0) then Exit;
  SetExpandClipAreaFlag;
  DrawFindAllClipCopyStatus;
  MaxLen := 0;
  SaveCount := ClipLines^.Count;
  for I := 0 to GetCallerCount - 1 do
  begin
    GetLine(I, S);
    PutClipLine(S);
    if not MarkColumns or (Length(S) > MaxLen) then MaxLen := Length(S);
    if ClipOverflow or ((KbdStatus = 1) and AbortAction) then Break;
  end;
  SetOrExpandClipArea(SaveCount, MaxLen + 1);
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure TViewerFindAllList.UpdateCommands;
var
  C: TCommandSet;
begin
  C := NewCommands + ModifyCommands + DeleteCommands;
  if GetCallerCount = 0 then DisableCommands(C)
  else EnableCommands(C);
end;

procedure THexViewerFindAllList.GetLine(Index: Integer; var S: String);
var
  W: Word;
  I: Integer;
  P: PString;
  L: Longint;
  SS: String;
begin
  if (Index < TopLine) or (Index >= TopLine + LineBuffer^.Count) then
  begin
    LineBuffer^.FreeAll;
    TopLine := Index - MaxLines div 2;
    if TopLine + MaxLines > Range then TopLine := Range - MaxLines;
    if TopLine < 0 then TopLine := 0;
    I := TopLine;
    with PHexViewer(Caller)^ do
    begin
      OpenSource;
      while (I < TopLine + MaxLines) and (I < Range) do
      begin
	SS[0] := #16;
	FillChar(SS[1], 16, 0);
	L := Longint(GetCallerPtr(I));
	Seek(Source.F, L);
	BlockRead(Source.F, SS[1], $10, W);
{	LineBuffer^.Insert(NewStr(Trim(SS)));}
	LineBuffer^.Insert(NewStrUMB(Trim(SS)));
	Inc(I);
      end;
      CloseSource;
    end;
  end;
  I := Index - TopLine;
  P := LineBuffer^.At(I);
  if P = nil then S := '' else S := P^;
end;

function THexViewerFindAllList.GetText(
  Item: Integer; MaxLen: Integer): String;
var
  L: Longint;
  S, C: String;
begin
  GetLine(Item, S);
  L := Longint(GetCallerPtr(Item));
  FormatStr(C, '%07x ', L);
  GetText := C + S;
end;

function THexViewerFindAllList.GetCallerCount: Integer;
begin
  GetCallerCount := PHexViewer(Caller)^.FindAllList^.Count;
end;

function THexViewerFindAllList.GetCallerPtr(Index: Integer): Pointer;
begin
  GetCallerPtr :=
    PSwapLinesCollection(
      PHexViewer(Caller)^.FindAllList)^.ExtraAt(Index);
end;

procedure THexViewerFindAllList.DeleteFocused;
begin
  PSwapLinesCollection(
    PHexViewer(Caller)^.FindAllList)^.ExtraAtFree(Focused);
end;

procedure THexViewerFindAllList.UpdateCommands;
begin
  Inherited UpdateCommands;
  DisableCommands(ModifyCommands);
end;

function InitFindAllViewer(var R: TRect; HBar, VBar: PScrollBar;
  InfoPtr: Pointer): PView;
begin
  if InfoPtr <> nil then InitFindAllViewer :=
    New(PHexViewerFindAllList, Init(R, 1, HBar, VBar))
  else InitFindAllViewer :=
    New(PViewerFindAllList, Init(R, 1, HBar, VBar));
end;

function ViewerFindAllDialog(Count: Integer; Hex: Boolean): PDialog;
var
  R: TRect;
  F: TInitViewerFunc;
  P: Pointer;
begin
  R.Assign(0, 0, 69, ScreenHeight - 14);
  if Hex then Dec(R.B.X, 25);
  F := InitFindAllViewer;
  if Hex then P := @P else P := nil;
  ViewerFindAllDialog := CustomFindAllDialog(R,
    '~V~iewer' + FoundLinesCountStr(Count), F, P);
end;

end.
