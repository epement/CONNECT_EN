{$I-,X+,O+,F+}
unit MsgWin;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PMessageViewer = ^TMessageViewer;
  TMessageViewer = object(TListViewer)
    FileName: PString;
    MessageLines: PCollection;
    constructor Init(var Bounds: TRect; ANumCols: Integer;
      AHScrollBar, AVScrollBar: PScrollBar; const AFileName: FNameStr);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure Store(var S: TStream);
    procedure ReadMessage(const FName: FNameStr);
    procedure Update;
    procedure Search(const Match: String; AOptions: Word);
    procedure FindDlg;
  end;

  PMessageWindow = ^TMessageWindow;
  TMessageWindow = object(TWindow)
    MessageViewer: PMessageViewer;
    constructor Init(const AFileName: FNameStr);
    constructor Load(var S: TStream);
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
    procedure GoToSource(ACommand: Word);
  end;

const
  CMessageColor      = #$38#$3F#$3A#$13#$13#$30#$4A#$1E;
  CMessageBlackWhite = #$07#$0F#$07#$70#$70#$07#$70#$70;
  CMessageMonochrome = #$07#$0F#$07#$70#$70#$07#$70#$70;
  CMessageWindow     = #88#89#90#91#92#93#94#95;
  CMessageViewer     = #6#6#7#2#7;

procedure MessageWindow;

implementation

uses Dos, Memory, App, MsgBox, HistList, History, FindDlg, EditMsg,
  RegExp, StrCol, HeapUMB, Filters, DirPrim, DosTools, ExecPrim, RevPos,
  Keyboard, WinPos, CNWinPos, LFN, TPString, Consts, Commands, Defaults;

constructor TMessageViewer.Init(var Bounds: TRect; ANumCols: Integer;
  AHScrollBar, AVScrollBar: PScrollBar; const AFileName: FNameStr);
begin
  TListViewer.Init(Bounds, ANumCols, AHScrollbar, AVScrollBar);
  GrowMode := gfGrowHiX + gfGrowHiY;
  FileName := nil;
  ReadMessage(AFileName);
end;

constructor TMessageViewer.Load(var S: TStream);
var
  FName: FNameStr;
begin
  TListViewer.Load(S);
{  FileName := S.ReadStr;}
  FileName := ReadStrUMB(@S);
  FName := FileName^;
  ReadMessage(FName);
end;

destructor TMessageViewer.Done;
begin
  if MessageLines <> nil then Dispose(MessageLines, Done);
{  DisposeStr(FileName);}
  DisposeStrUMB(FileName);
  TListViewer.Done;
end;

function TMessageViewer.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else GetHelpCtx := hcMessage;
end;

function TMessageViewer.GetPalette: PPalette;
const
  P: String[Length(CMessageViewer)] = CMessageViewer;
begin
  GetPalette := @P;
end;

function TMessageViewer.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: PString;
begin
  if Item < 0 then P := nil
  else P := MessageLines^.At(Item + 2);
  if P = nil then GetText := ''
  else GetText := Detab(P^, 8);
end;

procedure TMessageViewer.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmOk;
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and (Event.KeyCode = kbDel) and
    (Range <> 0) then
  begin
    MessageLines^.AtFree(Focused + 2);
    Range := MessageLines^.Count - 2;
    if Range < 0 then Range := 0;
    SetRange(Range);
    DrawView;
    Event.What := evNothing;
  end
  else TListViewer.HandleEvent(Event);
  if Event.What = evKeyDown then
  begin
    case Event.CharCode of
      ^L: Search(SearchData.MatchStr,
	 SearchData.Options or frFromCursor);
      ^B: Search(SearchData.MatchStr,
	 SearchData.Options or (frFromCursor + frBackward));
      ^U: Search(SearchData.MatchStr,
	 (SearchData.Options or frFromCursor) and not frBackward);
      else Exit;
    end;
    Event.What := evNothing;
  end
  else if (Event.What = evCommand) and (Event.Command = cmFind) then
  begin
    FindDlg;
    Event.What := evNothing;
  end;
end;

procedure TMessageViewer.SetState(AState: Word; Enable: Boolean);
begin
  TListViewer.SetState(AState, Enable);
  if Enable and (AState and sfExposed <> 0) then
  begin
    SetRange(Range);
    HScrollBar^.SetRange(0, 255);
    FocusItem(Focused);
  end;
  if Enable and (AState = sfFocused) then
    EnableCommands(CopyCommands + FindCommands + MTCopyCommands)
  else if not Enable and
    (((AState = sfActive) and GetState(sfExposed)) or
     (AState = sfExposed)) then DisableCommands(
       CopyCommands + MTCopyCommands + FindCommands);
end;

procedure TMessageViewer.ReadMessage(const FName: FNameStr);
var
  SaveCount: Integer;
  FileToView: Text;
  S: String;
begin
{
  DisposeStr(FileName);
  FileName := NewStr(FName);
}
  DisposeStrUMB(FileName);
  FileName := NewStrUMB(FName);
  MessageLines := New(PStringsCollection, Init(16, 16));
  if FileName <> nil then
  begin
    Assign(FileToView, FileName^);
    Reset(FileToView);
    if IOResult = 0 then
    begin
      while not Eof(FileToView) do
      begin
	Readln(FileToView, S);
	SaveCount := MessageLines^.Count;
{	MessageLines^.Insert(NewStr(S));}
	MessageLines^.Insert(NewStrUMB(S));
	if SaveCount = MessageLines^.Count then
	begin
	  MessageBox(^C'Message too long...truncating.',
	    nil, mfError + mfOkButton);
	  Break;
	end;
      end;
      Close(FileToView);
    end;
  end;
  Range := MessageLines^.Count - 2;
  if Range < 0 then Range := 0;
end;

procedure TMessageViewer.Update;
var
  Name: FNameStr;
begin
  if MessageLines <> nil then Dispose(MessageLines, Done);
  if FileName = nil then Name := ''
  else Name := FileName^;
  ReadMessage(Name);
  SetRange(Range);
end;

procedure TMessageViewer.Store(var S: TStream);
begin
  TListViewer.Store(S);
  S.WriteStr(FileName);
end;

procedure TMessageViewer.Search(const Match: String; AOptions: Word);
var
  Back, Aborted: Boolean;
  FoundPos: Byte;
  Index, EI: Integer;
  RegExpr: Pointer;
  P: PString;
  Str, SubS, RGS: String;

procedure FindPos;
begin
  if AOptions and frWholeWordsOnly <> 0 then
    FoundPos := WordPos(SubS, Str, WordDelims, Back)
  else if Back then FoundPos := RPos(SubS, Str)
  else FoundPos := Pos(SubS, Str);
end;

begin
  if Match = '' then Exit;
  DrawStatusLine(SearchMsg);
  SubS := Match;
  if AOptions and frCaseSensitive = 0 then UpcaseSt(SubS);
  if AOptions and frRegExp <> 0 then RegExpr := RegCompile(SubS)
  else RegExpr := nil;
  Back := AOptions and frBackward <> 0;
  if AOptions and frFromCursor <> 0 then
    if Back then Index := Focused + 1
    else Index := Focused + 3
  else if Back then Index := MessageLines^.Count - 1
  else Index := 2;
  if Back then EI := 2
  else EI := MessageLines^.Count - 1;
  FoundPos := 0;
  Aborted := False;
  if (Back and (Index >= EI)) or (not Back and (Index <= EI)) then
  repeat
    P := MessageLines^.At(Index);
    if P <> nil then
    begin
      Str := Detab(P^, 8);
      if AOptions and frCaseSensitive = 0 then UpcaseSt(Str);
      if (AOptions and frRegExp <> 0) and (RegExpr <> nil) then
      begin
	if Back then RGS := RegSearchBack(RegExpr, Str)
	else RGS := RegSearch(RegExpr, Str);
	if RGS <> '' then SubS := RGS;
      end;
      FindPos;
    end;
    if (KbdStatus = 1) and AbortAction then
    begin
      Aborted := True;
      Break;
    end;
    if FoundPos <> 0 then Break;
    if Back then
    begin
      Dec(Index);
      if Index < EI then Break;
    end
    else
    begin
      Inc(Index);
      if Index > EI then Break;
    end;
  until False;
  RegFree(RegExpr);
  if not Aborted then
    if FoundPos = 0 then SearchStringNotFoundMsgBox
    else FocusItem(Index - 2);
end;

procedure TMessageViewer.FindDlg;
begin
  SearchData.MatchStr := HistoryStr(FindHistoryID, 0);
  if Application^.ExecuteDialog(LoadFindDialog(
    False, True, frSelectedText), @SearchData, False) <> cmCancel then
      Search(SearchData.MatchStr, SearchData.Options);
end;

constructor TMessageWindow.Init(const AFileName: FNameStr);
var
  R: TRect;
begin
  Desktop^.GetExtent(R); R.A.Y := R.B.Y - 8;
  TWindow.Init(R, 'Message', wnNoNumber);
  Options := Options or ofValidate;
  GetExtent(R);
  R.Grow(-1, -1);
  MessageViewer := New(PMessageViewer, Init(R, 1,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    AFileName));
  Insert(MessageViewer);
  WinPos := @MesgWinPos;
end;

constructor TMessageWindow.Load(var S: TStream);
begin
  TWindow.Load(S);
  GetSubViewPtr(S, MessageViewer);
  WinPos := @MesgWinPos;
end;

function TMessageWindow.GetPalette: PPalette;
const
  P: String[Length(CMessageWindow)] = CMessageWindow;
begin
  GetPalette := @P;
end;

procedure TMessageWindow.GoToSource(ACommand: Word);
var
  CtrlDown, Found, SaveExplode: Boolean;
  B: Byte;
  IsOpenCommand, OpenCommand: Word;
  Index, Ps, Code: Integer;
  L: Longint;
  S, NameFilter, LineFilter, ColumnFilter: String;

function GetNumLines(const Macro: String; var Filter: String): Integer;
var
 Ps, Ps1: Byte;
 I: Integer;
begin
  I := 0;
  Ps := Pos(Macro, StUpcase(Filter));
  if Ps <> 0 then
  begin
    Ps1 := FIPos(')', Filter, Ps);
    if Ps1 <> 0 then
    begin
      Val(Copy(Filter, Ps + Length(Macro),
	Ps1 - Ps - Length(Macro)), I, Code);
      System.Delete(Filter, Ps, Ps1 - Ps + 1);
    end;
  end;
  GetNumLines := I;
end;

function GetLineNumber: Boolean;
begin
  GetLineNumber := False;
  Index := 0;
  Ps := 0;
  if LineFilter = '' then Exit;
  Val(ColumnFilter, Ps, Code);
  Dec(Ps);
  if Ps < 0 then Ps := 0;
  Val(LineFilter, Index, Code);
  if Code <> 0 then Exit;
  Dec(Index);
  if Index < 0 then Index := 0;
  GetLineNumber := True;
end;

procedure GetWindow;
begin
  if Message(Desktop, evBroadcast, IsOpenCommand, @NameFilter) = nil then
  begin
    if not ThisFileExists(NameFilter) then
    begin
      L := Index + 1;
      MessageBox(
	^C'Cannot find source file.'#13^C'Source position is:'#13^C +
	TrimmedName(NameFilter, 20) + ' line %d.',
	@L, mfError + mfOkButton);
    end
    else Message(Application, evCommand, OpenCommand, @NameFilter);
  end;
end;

begin
  if MessageViewer^.Range = 0 then Exit;
  CtrlDown := GetShiftState and kbCtrlShift <> 0;
  if CtrlDown then
  begin
    IsOpenCommand := cmOpenTextViewer;
    OpenCommand := cmOpenTextViewer;
  end
  else
  begin
    IsOpenCommand := cmASCIIOpened;
    OpenCommand := cmOpenASCII;
  end;
  SaveExplode := DoExplode;
  DoExplode := False;
  Desktop^.Lock;
  with MessageViewer^ do
  begin
    GetFilters(MessageLines^.At(0), MessageLines^.At(1),
      NameFilter, LineFilter, ColumnFilter);
    Index := Focused +
      GetNumLines('$DOWN(', NameFilter) -
      GetNumLines('$UP(', NameFilter);
    S := GetText(Index, 255);
    NameFilter := Trim(StringFilter(S, NameFilter));

    if NameFilter = '' then NameFilter := SourceName
    else NameFilter := lFExpand(NameFilter);
    if NameFilter <> '' then
    begin
      Index := Focused +
	GetNumLines('$DOWN(', LineFilter) -
	GetNumLines('$UP(', LineFilter);
      S := GetText(Index, 255);
      LineFilter := Trim(StringFilter(S, LineFilter));

      Index := Focused +
	GetNumLines('$DOWN(', ColumnFilter) -
	GetNumLines('$UP(', ColumnFilter);
      S := GetText(Index, 255);
      ColumnFilter := Trim(StringFilter(S, ColumnFilter));

      Found := GetLineNumber;
      GetWindow;
      if Message(Desktop, evBroadcast, IsOpenCommand, @NameFilter) <> nil then
	if Found then
	begin
	  LongRec(L).Lo := Ps;
	  LongRec(L).Hi := Index;
	  Message(Desktop, evBroadcast, cmGoToLine, Pointer(L));
	  if ACommand = cmYes then
	  begin
	    if CtrlDown then L := -1;
	    Message(Desktop, evBroadcast, cmTrackSource, Pointer(L));
	  end;
	end;
    end;
  end;
  if ACommand = cmYes then Select;
  Desktop^.Unlock;
  DoExplode := SaveExplode;
end;

procedure TMessageWindow.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evCommand) and
     ((Event.Command = cmOk) or (Event.Command = cmYes)) then
  begin
    GoToSource(Event.Command);
    Event.What := evNothing;
  end;
  if (Event.What = evBroadcast) and (Event.Command = cmIsMessage) then
  begin
    MessageViewer^.Update;
    Deiconize;
    Show;
    Select;
    MessageViewer^.DrawView;
    ClearEvent(Event);
  end;
  if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
  begin
    Event.What := evCommand;
    Event.Command := cmClose;
    Event.InfoPtr := @Self;
  end;
  TWindow.HandleEvent(Event);
end;

procedure TMessageWindow.SizeLimits(var Min, Max: TPoint);
begin
  TWindow.SizeLimits(Min, Max);
  Min.X := 19;
end;

procedure TMessageWindow.Store(var S: TStream);
begin
  TWindow.Store(S);
  PutSubViewPtr(S, MessageViewer);
end;

procedure MessageWindow;
var
  W: PMessageWindow;
  R: TRect;
begin
  if Message(Desktop, evBroadcast, cmIsMessage, nil) = nil then
  begin
    W := New(PMessageWindow, Init(ReportFile));
    if (WinPosMask and wpMesg <> 0) and ValidWinPos(MesgWinPos) then
    begin
      SetWinPos(Desktop, MesgWinPos, R);
      W^.Locate(R);
    end;
    Application^.InsertWindow(W);
  end;
end;

end.