{$I-,F+,O+,X+}
unit ClipBrd;

interface

uses Objects, Drivers, Views, FEditor;

type

  { TClipEditor }

  PClipEditor = ^TClipEditor;
  TClipEditor = object(TFileEditor)
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar; AnIndicator: PIndicator);
    destructor Done; virtual;
    function GetHelpCtx: Word; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure ReadFile(var FName: String); virtual;
    procedure Copy; virtual;
    procedure Paste; virtual;
  end;

  { TClipWindow }

  PClipWindow = ^TClipWindow;
  TClipWindow = object(TEditorWindow)
    constructor Init(Bounds: TRect; var FileName: String);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Close; virtual;
  end;

const
  TheClipboard: PClipWindow = nil;

procedure RSRClipWindow(RSR: PResourceFile);
procedure ShowClipboard;
procedure ExecClipboard;

procedure ClipCopyToMT(const S: String; var Event: TEvent);
procedure ClipPasteFromMT(var Event: TEvent);

procedure IncSearchFromClipboard(Caller: PView);

implementation

uses Dos, WinIcons, App, MsgBox, EditMsg, RegExp, StrCol, HeapUMB,
  ClipPrim, Swaps, Snipper, WinPos, CNWinPos, Spooler, Consts, Commands;

{ TClipEditor }
constructor TClipEditor.Init(var Bounds: TRect; AHScrollBar,
  AVScrollBar: PScrollBar; AnIndicator: PIndicator);
begin
  TScroller.Init(Bounds, AHScrollbar, AVScrollBar);
  GrowMode := gfGrowHiX + gfGrowHiY;
  Indicator := AnIndicator;
  ClearPlaces;
  ClearBreakPoints;
end;

destructor TClipEditor.Done;
begin
  if CommentRegExp <> nil then RegFree(CommentRegExp);
  if FindAllList <> nil then Dispose(FindAllList, Done);
  if RedoList <> nil then Dispose(RedoList, Done);
  if UndoList <> nil then Dispose(UndoList, Done);
  if NewLines <> nil then Dispose(NewLines, Done);
{  DisposeStr(FileName);}
  DisposeStrUMB(FileName);
  TScroller.Done;
end;

function TClipEditor.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then GetHelpCtx := hcDragging
  else if IncSearch then GetHelpCtx := hcEditIncSearch
  else if IsCtrlKPressed then GetHelpCtx := hcCtrlKPressed
  else if IsCtrlQPressed then GetHelpCtx := hcCtrlQPressed
  else if IsCtrlPPressed then GetHelpCtx := hcCtrlPPressed
  else if IsCtrlOPressed then GetHelpCtx := hcCtrlOPressed
  else if State and sfDrawSingle <> 0 then GetHelpCtx := hcDrawSingle
  else if State and sfDrawDouble <> 0 then GetHelpCtx := hcDrawDouble
  else GetHelpCtx := hcClipboard;
end;

procedure TClipEditor.HandleEvent(var Event: TEvent);
begin
  if Event.What = evBroadcast then
    case Event.Command of
      cmIsASCII, cmQuit, cmSaveAll, cmRun, cmProgramReset,
      cmGoToCursor, cmTraceInto, cmStepOver, cmGetSource,
      cmUpdateTime, cmNewSwapStream, cmComments: Exit;
      cmCopy, cmPaste: SaveLastLine;
      cmUpdateViews:
	begin
	  SaveLastLine;
	  SetLimit(Limit.X, FileLines^.Count + Size.Y);
	  IsModified := IsModified or (FileLines^.Count <> 0);
	  IsSelected := ClipAreaSelected;
	  if IsSelected then
	  begin
	    IsSelected := False;
	    Highlight(Area^.KB, Area^.PB, Area^.KK, Area^.PK);
	  end;
	  DrawView;
	  Indicator^.DrawView;
	end;
    end;
  if Event.What = evCommand then
    case Event.Command of
      cmUpdateASCII, cmSave, cmCompile: Exit;
      cmCopyToMT, cmPasteFromMT: Event.InfoByte := 1;
      cmCancel: if Owner^.State and sfModal <> 0 then
	begin
	  SaveLastLine;
	  Owner^.EndModal(cmCancel);
	  Event.What := evNothing;
	end
    end;
  if (Owner^.State and sfModal <> 0) and (Event.What = evKeyDown) then
    case Event.KeyCode of
      kbAltBack:
	begin
	  Event.What := evCommand;
	  Event.Command := cmUndo;
	end;
      kbCtrlEnter:
	begin
	  Event.What := evCommand;
	  Event.Command := cmRedo;
	end;
    end;
  TFileEditor.HandleEvent(Event);
end;

procedure TClipEditor.Copy;
begin
  GoCtrlPgDn;
  InsertBlock(Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
  Indicator^.DrawView;
  DrawView;
end;

procedure TClipEditor.Paste;
begin
  InsertBlock(Delta.Y + Cursor.Y, Succ(Delta.X + Cursor.X));
  Indicator^.DrawView;
  DrawView;
end;

procedure TClipEditor.ReadFile(var FName: String);
var
  Line: String;
begin
{  if Area <> nil then FreeMem(Area, SizeOf(Area^));}
  if Area <> nil then FreeMemUMB(Area, SizeOf(Area^));
  Area := ClipArea;
  SwapStream := DiskClipStream;
  if SwapStream = nil then
  begin
    SwapAccessErrorMsgBox;
    IsValid := False;
    Exit;
  end;
  FileLines := ClipLines;
  NewTitle(FName);
  IsValid := True;
  IsModified := FileLines^.Count > 1;
  UnixMode := False;
  FileAttr := Archive;
  IsCtrlKPressed := False;
  IsCtrlQPressed := False;
  IsCtrlPPressed := False;
  IsCtrlOPressed := False;
  IsInsert := State and sfCursorIns = 0;
  IsDebug := False;
  IsClip := True;
  TopLine := MaxInt;
  SourceLine := -1;
  SetLastLine('', -1);
  UndoCount := 0;
  GetLocalFields;
  NewLines := New(PStringsCollection, Init(NumLines, 1));
  UndoList := New(PSwapLinesCollection, Init(8, 8));
  RedoList := New(PSwapLinesCollection, Init(8, 8));
  FindAllList := New(PSwapLinesCollection, Init(8, 8));
  IsSelected := ClipAreaSelected;
  SelectFromX := 1;
  Limit.X := 255;
  Limit.Y := FileLines^.Count;
  if Limit.Y > 0 then Inc(Limit.Y, Size.Y);
  SetLimit(Limit.X, Limit.Y);
  ShowCursor;
  if Delta.Y + Cursor.Y > FileLines^.Count then GoCtrlPgDn;
end;

procedure TClipEditor.SetState(AState: Word; Enable: Boolean);
const
  TabooCommands = [cmSave, cmCompile, cmToggleBreakpoint,
    cmClearBreakpoints, cmUpdateASCII, cmUpdateHex];
begin
  TFileEditor.SetState(AState, Enable);
  if (AState = sfFocused) and Enable then DisableCommands(TabooCommands);
end;

{ TClipWindow }
constructor TClipWindow.Init(Bounds: TRect; var FileName: String);
var
  Control, IControl: PView;
  R: TRect;
begin
  TWindow.Init(Bounds, FileName, wnNoNumber);
  Options := Options or (ofTileable + ofNewSize);

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
  Editor := New(PClipEditor, Init(R, PScrollBar(Control),
    StandardScrollBar(sbVertical + sbHandleKeyboard), PIndicator(IControl)));
  Insert(Editor);
  PClipEditor(Editor)^.ReadFile(FileName);

  WinPos := @ClipWinPos;
end;

constructor TClipWindow.Load(var S: TStream);
begin
  TEditorWindow.Load(S);
  WinPos := @ClipWinPos;
  TheClipboard := @Self;
end;

destructor TClipWindow.Done;
begin
  TWindow.Done;
  TheClipboard := nil;
end;

procedure TClipWindow.Close;
begin
  with PClipEditor(Editor)^ do SaveLastLine;
  if TheSpooler^.InQueue(Editor) then
    if PrinterQueueMsgBox <> cmOk then Exit
    else TheSpooler^.DoUpdate := True;
  if Icon <> nil then
  begin
    PWinIcon(Icon)^.Window := nil;
    Icon := nil;
    Flags := Flags and not wfMini;
  end
  else if Owner <> nil then Owner^.Delete(@Self);
end;

procedure RSRClipWindow(RSR: PResourceFile);
var
  W: PClipWindow;
  R: TRect;
  S: String;
begin
  Desktop^.GetExtent(R);
  S := 'Clipboard';
  W := New(PClipWindow, Init(R, S));
  RSR^.Put(W, 'CLIPWINDOW');
  Dispose(W, Done);
end;

procedure ShowClipboard;
var
  R: TRect;
begin
  if TheClipboard = nil then Resource^.Get('CLIPWINDOW');
  if TheClipboard <> nil then
  begin
    TheClipboard^.Deiconize;
    if TheClipboard^.Owner <> nil then TheClipboard^.Select
    else if Application^.ValidView(TheClipboard) <> nil then
    begin
      if (WinPosMask and wpClip <> 0) and ValidWinPos(ClipWinPos) then
	SetWinPos(Desktop, ClipWinPos, R)
      else Desktop^.GetExtent(R);
      TheClipboard^.Locate(R);
      Desktop^.Insert(TheClipboard);
    end;
    Message(TheClipboard, evBroadcast, cmUpdateViews, nil);
  end
  else ResourceNotFoundMsgBox('Clipboard');
end;

procedure ExecClipboard;
var
  O: PGroup;
  R: TRect;
begin
  if TheClipboard = nil then Resource^.Get('CLIPWINDOW');
  if TheClipboard <> nil then
  begin
    if (TheClipboard^.Owner <> nil) or
       (TheClipboard^.Icon <> nil) then Exit;
    if Application^.ValidView(TheClipboard) <> nil then
    begin
      Message(TheClipboard, evBroadcast, cmUpdateViews, nil);
      if Desktop = Pointer(Application^.Current) then O := Desktop
      else O := Application;
      if (WinPosMask and wpClip <> 0) and ValidWinPos(ClipWinPos) then
	SetWinPos(O, ClipWinPos, R)
      else O^.GetExtent(R);
      TheClipboard^.Locate(R);
      O^.ExecView(TheClipboard);
    end;
  end
  else ResourceNotFoundMsgBox('Clipboard');
end;

procedure RestoreClipLines(Index: Integer; AnArea: TArea; ASel: Boolean);
var
  I: Integer;
begin
  for I := ClipLines^.Count - 1 downto Index do
    PSwapLinesCollection(ClipLines)^.ExtraAtFree(I);
  ClipArea^ := AnArea;
  ClipAreaSelected := ASel;
end;

procedure ClipCopyToMT(const S: String; var Event: TEvent);
var
  SaveSel: Boolean;
  SaveCount: Integer;
  SaveArea: TArea;
begin
  if DiskClipStream = nil then Exit;
  if Event.InfoByte <> 1 then
  begin
    SaveCount := ClipLines^.Count;
    SaveArea := ClipArea^;
    SaveSel := ClipAreaSelected;
    if TheClipboard <> nil then TheClipboard^.EventMask :=
      TheClipboard^.EventMask and not evBroadcast;
{ Added 2005.10.07 to support $winclip directive }
    if S <> '' then Message(Application, evBroadcast, cmCopy, @S)
    else Message(Application, evCommand, cmCopy, nil);
  end
  else SaveCount := -1;
  if SaveCount <> ClipLines^.Count then CopyToMultitasker;
  if SaveCount <> -1 then
    RestoreClipLines(SaveCount, SaveArea, SaveSel);
  if TheClipboard <> nil then TheClipboard^.EventMask :=
    TheClipboard^.EventMask or evBroadcast;
end;

procedure ClipPasteFromMT(var Event: TEvent);
var
  SaveSel, Clip: Boolean;
  SaveCount: Integer;
  SaveArea: TArea;
begin
  if DiskClipStream = nil then Exit;
  SaveCount := ClipLines^.Count;
  SaveArea := ClipArea^;
  SaveSel := ClipAreaSelected;
  Clip := Event.InfoByte = 1;
  if not Clip and (TheClipboard <> nil) then TheClipboard^.EventMask :=
    TheClipboard^.EventMask and not evBroadcast;
  PasteFromMultitasker;
  if not Clip and (SaveCount <> ClipLines^.Count) then
  begin
    Message(Application, evCommand, cmPaste, nil);
    RestoreClipLines(SaveCount, SaveArea, SaveSel);
  end;
  if TheClipboard <> nil then TheClipboard^.EventMask :=
    TheClipboard^.EventMask or evBroadcast;
end;

procedure IncSearchFromClipboard(Caller: PView);
var
  B: Byte;
  Event: TEvent;
  S: String;
begin
  Message(Application, evBroadcast, cmUpdateViews, nil);
  GetClipLine(ClipArea^.KB, S);
  EditorAborted := False;
  for B := 1 to Length(S) do
  begin
    Event.What := evKeyDown;
    Event.CharCode := S[B];
    Caller^.HandleEvent(Event);
    if EditorAborted then Exit;
  end;
end;

end.