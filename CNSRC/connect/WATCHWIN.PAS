{$I-,X+,O+,F+}
unit WatchWin;

interface

uses Dos, Objects, Drivers, Views, Dialogs;

type
  PWatchViewer = ^TWatchViewer;
  TWatchViewer = object(TListViewer)
    WatchLines: PCollection;
    constructor Init(var Bounds: TRect; ANumCols: Integer;
      AHScrollBar, AVScrollBar: PScrollBar);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure AddWatch;
    procedure EditWatch;
    procedure DeleteWatch;
    procedure ClearWatches;
    procedure Store(var S: TStream);
  end;

  PWatchWindow = ^TWatchWindow;
  TWatchWindow = object(TWindow)
    WatchViewer: PWatchViewer;
    constructor Init;
    constructor Load(var S: TStream);
    destructor Done; virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
  end;

const
  CWatchColor      = #$38#$3F#$3A#$13#$13#$30#$5F#$1E;
  CWatchBlackWhite = #$07#$0F#$07#$70#$70#$07#$70#$70;
  CWatchMonochrome = #$07#$0F#$07#$70#$70#$07#$70#$70;
  CWatchWindow     = #105#106#107#108#109#110#111#112;
  CWatchViewer     = #6#6#7#2#7;

procedure RSRWatchWindow(RSR: PResourceFile);
procedure Watch;
procedure Modify;

implementation

uses Memory, App, MsgBox, EditMsg, FindDlg, StrCol, HeapUMB, Compiler,
  Procs, History, WinPos, CNWinPos, TPString, Consts, Commands;

function EnterWatch(ATitle: String; var S: String): Boolean;
var
  D: PDialog;
  Control: PInputLine;
  R: TRect;
  C: Word;
begin
  C := cmCancel;
  R.Assign(0, 0, 55, 7);
  R.Move((Desktop^.Size.X - R.B.X) div 2, (Desktop^.Size.Y - R.B.Y) div 2);
  D := New(PDialog, Init(R, ATitle));
  with D^ do
  begin
    HelpCtx := hcEnterWatch;

    R.Assign(20, 2, Size.X - 6, 3);
    Control := New(PDragInputLine, Init(R, 255));
    Insert(Control);
    StandardHistory(Control, WatchHistoryId);
    R.Assign(2, 2, 20, 3);
    Insert(New(PLabel, Init(R, '~W~atch expression', Control)));

    StandardButtonRow(D, True);
  end;
  C := Application^.ExecuteDialog(D, @S, False);
  EnterWatch := (C <> cmCancel) and (S <> '');
end;

constructor TWatchViewer.Init(var Bounds: TRect; ANumCols: Integer;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TListViewer.Init(Bounds, ANumCols, AHScrollbar, AVScrollBar);
  GrowMode := gfGrowHiX + gfGrowHiY;
  WatchLines := New(PStringsCollection, Init(4, 1));
  WatchLines^.Insert(nil);
end;

constructor TWatchViewer.Load(var S: TStream);
var
  FName: FNameStr;
begin
  TListViewer.Load(S);
  WatchLines := PStringsCollection(S.Get);
end;

destructor TWatchViewer.Done;
begin
  if WatchLines <> nil then Dispose(WatchLines, Done);
  TListViewer.Done;
end;

function TWatchViewer.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else GetHelpCtx := hcWatchWindow;
end;

function TWatchViewer.GetPalette: PPalette;
const
  P: String[Length(CWatchViewer)] = CWatchViewer;
begin
  GetPalette := @P;
end;

function TWatchViewer.GetText(Item: Integer; MaxLen: Integer): String;
const
  Unknown = 'Unknown identifier';
  Incorrect = 'Expression incorrectly terminated';
  Cannot = 'Cannot evaluate this expression';
var
  I: Integer;
  Value: Longint;
  P: PString;
  S, DS, PS, SS: String;

procedure FormatMem(var Dest: String; const Source: String; Blk: Longint);
var
  I: Integer;
  Ch: Char;
  St: String;
begin
  if Source[0] = #1 then Ch := 'D' else Ch := Upcase(Source[2]);
  case Ch of
    'C':
      begin
        Dest[0] := Char(251 - Length(S));
        FillChar(Dest[1], Length(Dest), ' ');
        I := 0;
        while I < Length(Dest) div 2 do
        begin
          Dest[I * 2 + 1] := PString(Blk)^[I];
          Inc(I);
        end;
        Dest := '''' + Dest + '''';
      end;
    'S':
      begin
        Dest[0] := Char(251 - Length(S));
        Move(PString(Blk)^[0], Dest[1], Length(Dest));
        Dest := '''' + Dest + '''';
      end;
    'X':
      begin
        Dest[0] := #0;
        I := 0;
        while Length(Dest) < 251 - Length(S) do
        begin
          Dest := Dest + '$' + HexB(Byte(PString(Blk)^[I])) + ' ';
          Inc(I);
        end;
      end;
    'D':
      begin
        Dest[0] := #0;
        I := 0;
        while Length(Dest) < 251 - Length(S) do
        begin
          Str(Byte(PString(Blk)^[I]), St);
          Dest := Dest + St + ' ';
          Inc(I);
        end;
      end;
    else Dest := Incorrect;
  end;
end;

begin
  P := WatchLines^.At(Item);
  if P = nil then S := '' else S := P^;
  if S[0] = #0 then SS := ''
  else if not Debugging then SS := Unknown
  else
  begin
    I := Pos(',', S);
    if I <> 0 then DS := Trim(Copy(S, I + 1, 255)) else DS := '';
    if I <> 0 then PS := Trim(Copy(S, 1, I - 1)) else PS := S;
    if not GetParameter(PS, Value) then
      if (Pos('+', PS) <> 0) or
	 (Pos('-', PS) <> 0) or
	 (Pos('*', PS) <> 0) or
	 (Pos('/', PS) <> 0) then SS := Cannot
      else SS := Unknown
    else if DS[0] = #0 then FormatStr(SS, '%d', Value)
    else if Upcase(DS[1]) = 'M' then FormatMem(SS, DS, Value)
    else case Upcase(DS[Length(DS)]) of
      'C', 'S': FormatStr(SS, '''%' + DS + '''', Value);
      'D', 'X': FormatStr(SS, '%' + DS, Value);
      else SS := Incorrect;
    end;
  end;
  if SS[0] = #0 then GetText := ''
  else GetText := S + ': ' + SS;
end;

procedure TWatchViewer.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmEditWatch;
    Event.What := evNothing;
  end;
  TListViewer.HandleEvent(Event);
  if Event.What = evBroadcast then
  begin
    case Event.Command of
      cmAddWatch: AddWatch;
      cmEditWatch: EditWatch;
      cmDeleteWatch: DeleteWatch;
      cmClearWatches: ClearWatches;
      cmUpdateViews:
        begin
          DrawView;
          Exit;
        end;
      else Exit;
    end;
    ClearEvent(Event);
  end;
end;

procedure TWatchViewer.SetState(AState: Word; Enable: Boolean);
begin
  TListViewer.SetState(AState, Enable);
  if (AState and sfExposed <> 0) and Enable then
  begin
    SetRange(WatchLines^.Count);
    HScrollBar^.SetRange(0, 255);
  end;
end;

procedure TWatchViewer.AddWatch;
var
  P: Pointer;
  S: String;
begin
  P := Message(Desktop, evBroadcast, cmGetWord, nil);
  if P = nil then S := '' else S := PString(P)^;
  if EnterWatch('Add watch', S) then with WatchLines^ do
  begin
{    AtInsert(Focused, NewStr(S));}
    AtInsert(Focused, NewStrUMB(S));
    SetRange(Count);
    FocusItem(Focused);
    DrawView;
  end;
end;

procedure TWatchViewer.EditWatch;
var
  P: PString;
  S: String;
begin
  if Focused = Range - 1 then
  begin
    AddWatch;
    Exit;
  end;
  P := WatchLines^.At(Focused);
  if P = nil then S := '' else S := P^;
  if EnterWatch('Edit watch', S) then with WatchLines^ do
  begin
    AtFree(Focused);
{    AtInsert(Focused, NewStr(S));}
    AtInsert(Focused, NewStrUMB(S));
    SetRange(Count);
    DrawView;
  end;
end;

procedure TWatchViewer.DeleteWatch;
begin
  if Focused = Range - 1 then Exit;
  WatchLines^.AtFree(Focused);
  SetRange(WatchLines^.Count);
  DrawView;
end;

procedure TWatchViewer.ClearWatches;
begin
  WatchLines^.FreeAll;
  WatchLines^.Insert(nil);
  SetRange(WatchLines^.Count);
  FocusItem(0);
  DrawView;
end;

procedure TWatchViewer.Store(var S: TStream);
begin
  TListViewer.Store(S);
  S.Put(WatchLines);
end;

constructor TWatchWindow.Init;
var
  R: TRect;
begin
  Desktop^.GetExtent(R); R.A.Y := R.B.Y - 8;
  TWindow.Init(R, 'Watches', wnNoNumber);
  Options := Options or ofValidate;
  GetExtent(R);
  R.Grow(-1, -1);
  WatchViewer := New(PWatchViewer, Init(R, 1,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard)));
  Insert(WatchViewer);
  EnableCommands(WatchCommands);
  WinPos := @WatcWinPos;
end;

constructor TWatchWindow.Load(var S: TStream);
begin
  TWindow.Load(S);
  GetSubViewPtr(S, WatchViewer);
  EnableCommands(WatchCommands);
  WinPos := @WatcWinPos;
end;

destructor TWatchWindow.Done;
begin
  TWindow.Done;
  DisableCommands(WatchCommands);
end;

function TWatchWindow.GetPalette: PPalette;
const
  P: String[Length(CWatchWindow)] = CWatchWindow;
begin
  GetPalette := @P;
end;

procedure TWatchWindow.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
  begin
    Event.What := evCommand;
    Event.Command := cmClose;
    Event.InfoPtr := @Self;
  end
  else if (Event.What = evBroadcast) and (Event.Command = cmWatch) then
  begin
    Deiconize;
    Show;
    Select;
    ClearEvent(Event);
  end;
  TWindow.HandleEvent(Event);
end;

procedure TWatchWindow.SizeLimits(var Min, Max: TPoint);
begin
  TWindow.SizeLimits(Min, Max);
  Min.X := 19;
end;

procedure TWatchWindow.Store(var S: TStream);
begin
  TWindow.Store(S);
  PutSubViewPtr(S, WatchViewer);
end;

procedure RSRWatchWindow(RSR: PResourceFile);
var
  W: PWatchWindow;
begin
  W := New(PWatchWindow, Init);
  RSR^.Put(W, 'WATCHWINDOW');
  Dispose(W, Done);
end;

procedure Watch;
var
  R: TRect;
  W: PWatchWindow;
begin
  W := PWatchWindow(Resource^.Get('WATCHWINDOW'));
  if W <> nil then
  begin
    if (WinPosMask and wpWatc <> 0) and ValidWinPos(WatcWinPos) then
      SetWinPos(Desktop, WatcWinPos, R)
    else
    begin
      Desktop^.GetExtent(R);
      R.A.Y := R.B.Y - 8;
    end;
    W^.Locate(R);
    Application^.InsertWindow(W);
  end
  else ResourceNotFoundMsgBox('Watches window');
end;

procedure Modify;
type
  DialogData = record
    Parameter: String[255];
    NewValue: String[11];
  end;
const
  ModifyData: DialogData = (Parameter: ''; NewValue: '');
var
  R: TRect;
  D: PDialog;
  Control: PView;
  L, Param: Longint;
  P: Pointer;
  I: Integer;
begin
  R.Assign(0, 0, 55, 9);
  D := New(PDialog, Init(R, 'Modify'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcModify;

    R.Assign(13, 2, Size.X - 6, 3);
    Control := New(PDragInputLine, Init(R, 255));
    Insert(Control);
    R.Assign(2, 2, 13, 3);
    Insert(New(PLabel, Init(R, '~P~arameter', Control)));
    StandardHistory(Control, WatchHistoryId);

    R.Assign(13, 4, 26, 5);
    Control := New(PInputLine, Init(R, 11));
    Insert(Control);
    R.Assign(2, 4, 13, 5);
    Insert(New(PLabel, Init(R, '~N~ew value', Control)));

    StandardButtonRow(D, True);
  end;
  P := Message(Desktop, evBroadcast, cmGetWord, nil);
  if P <> nil then ModifyData.Parameter := PString(P)^;
  if Application^.ExecuteDialog(D, @ModifyData, False) <> cmCancel then
  begin
    if Str2Long(ModifyData.NewValue, L) then
    begin
      if GetParameter(ModifyData.Parameter, Param) and
        BlockUsed(Pointer(Param), I) and (MessageBox(
        ^C'The specified parameter points'#13 +
        ^C'to a memory block allocated by the'#13 +
        ^C'executed program. Modify still ?',
        nil, mfConfirmation + mfOkCancel) = cmCancel) then
      else SetParameter(ModifyData.Parameter, L);
      Message(Desktop, evBroadcast, cmUpdateViews, nil);
    end;
  end;
end;

end.
