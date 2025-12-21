{$F+,O+,X+}
unit HTMLFind;

interface

uses Objects, Views, Drivers, Dialogs;

type
  PHTMLFindAllList = ^THTMLFindAllList;
  THTMLFindAllList = object(TListViewer)
    Caller: PView;
    Buffer: PCollection;
    TopLine: Integer;
    XLAT: Boolean;
    constructor Init(var Bounds: TRect; ANumCols: Integer;
      AHScrollBar, AVScrollBar: PScrollBar; AXLAT: Boolean);
    destructor Done; virtual;
    procedure GetData(var Rec); virtual;
    procedure GetLine(Index: Integer; var S: String);
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
    procedure ClipCopy;
    procedure UpdateCommands;
  end;

function HTMLFindAllDialog(Count: Integer; AXLAT: Boolean): PDialog;

implementation

uses App, Swaps, HTMLView, FindAll, StrCol, EditMsg, ClipPrim, HeapUMB,
  Keyboard, TPString, Consts, Commands, Defaults;

const
  MaxLines = 64;

constructor THTMLFindAllList.Init(var Bounds: TRect; ANumCols: Integer;
  AHScrollBar, AVScrollBar: PScrollBar; AXLAT: Boolean);
begin
  TListViewer.Init(Bounds, 1, AHScrollBar, AVScrollBar);
  GrowMode := gfGrowHiY;
  Buffer := New(PStringsCollection, Init(MaxLines, 1));
  XLAT := AXLAT;
end;

destructor THTMLFindAllList.Done;
begin
  Dispose(Buffer, Done);
  TListViewer.Done;
end;

procedure THTMLFindAllList.GetData(var Rec);
begin
  Integer(Rec) := Integer(PSwapLinesCollection(
    PHTMLViewer(Caller)^.FindAllList)^.ExtraAt(Focused));
end;

procedure THTMLFindAllList.GetLine(Index: Integer; var S: String);
var
  I, N: Integer;
  P: PString;
  L: Longint;

procedure HTMLLineToText;
var
  II: Integer;
  SS: String;
begin
  SS := '';
  II := 1;
  while II < Length(S) do
  begin
    if XLAT then S[II] := PHTMLViewer(Caller)^.XLATTable[S[II]];
    Inc(SS[0]);
    SS[Length(SS)] := S[II];
    Inc(II, 2);
  end;
  S := Trim(SS);
end;

begin
  if (Index < TopLine) or (Index >= TopLine + Buffer^.Count) then
  begin
    Buffer^.FreeAll;
    TopLine := Index - MaxLines div 2;
    if TopLine + MaxLines > Range then TopLine := Range - MaxLines;
    if TopLine < 0 then TopLine := 0;
    I := TopLine;
    while (I < TopLine + MaxLines) and (I < Range) do
    begin
      N := Integer(PSwapLinesCollection(
	PHTMLViewer(Caller)^.FindAllList)^.ExtraAt(I));
      L := Longint(PSwapLinesCollection(
	PHTMLViewer(Caller)^.FileLines)^.ExtraAt(N));
      if L = 0 then S := ''
      else with PHTMLViewer(Caller)^.SwapStream^ do
      begin
	Seek(L);
	Read(S[0], 1);
	Read(S[1], Byte(S[0]));
	HTMLLineToText;
      end;
{        Buffer^.Insert(NewStr(S));}
      Buffer^.Insert(NewStrUMB(S));
      Inc(I);
    end;
  end;
  I := Index - TopLine;
  P := Buffer^.At(I);
  if P = nil then S := '' else S := P^;
end;

function THTMLFindAllList.GetText(Item: Integer; MaxLen: Integer): String;
var
  I: Integer;
  L: Longint;
  C, S: String;
begin
  GetLine(Item, S);
  I := Integer(PSwapLinesCollection(
    PHTMLViewer(Caller)^.FindAllList)^.ExtraAt(Item));
  L := I + 1;
  FormatStr(C, '%-5d ', L);
  GetText := C + S;
end;

procedure THTMLFindAllList.HandleEvent(var Event: TEvent);
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
	begin
	  PHTMLViewer(Caller)^.DrawFlag := True;
	  LongRec(P).Hi := Integer(PSwapLinesCollection(
	    PHTMLViewer(Caller)^.FindAllList)^.ExtraAt(Focused));
	  LongRec(P).Lo := 0;
	  if Caller^.Size.Y > 3 then PHTMLViewer(Caller)^.ScrollTo(
	    PHTMLViewer(Caller)^.Delta.X, LongRec(P).Hi - 2);
	  Message(Caller, evBroadcast, cmGoToLine, P);
	  PHTMLViewer(Caller)^.DrawFlag := False;
	  Message(Caller, evBroadcast, cmTrackSource, P);
	end;
      cmDeleteItem: if CommandEnabled(cmDeleteItem) then
	begin
	  PSwapLinesCollection(
	    PHTMLViewer(Caller)^.FindAllList)^.ExtraAtFree(Focused);
	  Buffer^.FreeAll;
	  TopLine := MaxInt;
	  SetRange(PHTMLViewer(Caller)^.FindAllList^.Count);
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

procedure THTMLFindAllList.SetData(var Rec);
var
  I, N: Integer;
begin
  Caller := PView(Rec);
  SetRange(PHTMLViewer(Caller)^.FindAllList^.Count);
  HScrollBar^.SetRange(0, 261);
  I := 0;
  with PHTMLViewer(Caller)^ do
  begin
    N := Delta.Y + Cursor.Y;
    while (I < FindAllList^.Count - 1) and
      (Integer(PSwapLinesCollection(
	FindAllList)^.ExtraAt(I)) < N) do Inc(I);
  end;
  FocusItem(I);
  UpdateCommands;
end;

procedure THTMLFindAllList.ClipCopy;
var
  I, SaveCount, MaxLen: Integer;
  S: String;
begin
  if (DiskClipStream = nil) or
     (PHTMLViewer(Caller)^.FindAllList^.Count = 0) then Exit;
  DrawFindAllClipCopyStatus;
  SetExpandClipAreaFlag;
  MaxLen := 0;
  SaveCount := ClipLines^.Count;
  for I := 0 to PHTMLViewer(Caller)^.FindAllList^.Count - 1 do
  begin
    GetLine(I, S);
    PutClipLine(S);
    if not MarkColumns or (Length(S) > MaxLen) then MaxLen := Length(S);
    if ClipOverflow or ((KbdStatus = 1) and AbortAction) then Break;
  end;
  SetOrExpandClipArea(SaveCount, MaxLen + 1);
  Message(Desktop, evBroadcast, cmUpdateViews, nil);
end;

procedure THTMLFindAllList.UpdateCommands;
begin
  if PHTMLViewer(Caller)^.FindAllList^.Count = 0 then
    DisableCommands(NewCommands + ModifyCommands + DeleteCommands)
  else EnableCommands(NewCommands + DeleteCommands + ModifyCommands);
end;

function InitFindAllViewer(var R: TRect; HBar, VBar: PScrollBar;
  InfoPtr: Pointer): PView;
begin
  InitFindAllViewer := New(PHTMLFindAllList, Init(
    R, 1, HBar, VBar, InfoPtr <> nil));
end;

function HTMLFindAllDialog(Count: Integer; AXLAT: Boolean): PDialog;
var
  R: TRect;
  F: TInitViewerFunc;
  P: Pointer;
begin
  R.Assign(0, 0, 69, ScreenHeight - 14);
  F := InitFindAllViewer;
  if AXLAT then P := @P else P := nil;
  HTMLFindAllDialog := CustomFindAllDialog(R,
    '~V~iewer' + FoundLinesCountStr(Count), F, P);
end;

end.
