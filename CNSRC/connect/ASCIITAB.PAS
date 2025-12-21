{************************************************}
{                                                }
{   Turbo Pascal 6.0                             }
{   Turbo Vision Demo                            }
{   Copyright (c) 1990 by Borland International  }
{                                                }
{************************************************}

unit ASCIITab;

{$X+,O+,F+}

{ Ascii table viewer. See TVDEMO.PAS for an example program
 that uses this unit.
}

interface

uses Objects, App, Views, Drivers;

type
  PTable = ^TTable;
  TTable = object(TView)
    procedure Draw; virtual;
    procedure HandleEvent(var Event:TEvent); virtual;
  end;

  PReport = ^TReport;
  TReport = object(TView)
    ASCIIChar: Longint;
    constructor Load(var S: TStream);
    procedure Draw; virtual;
    procedure HandleEvent(var Event:TEvent); virtual;
    procedure Store(var S: TStream);
  end;

  PASCIIChart = ^TASCIIChart;
  TASCIIChart = object(TWindow)
    constructor Init;
    constructor Load(var S: TStream);
    function GetHelpCtx: Word; virtual;
    procedure HandleEvent(var Event:TEvent); virtual;
{ Added 2005.10.03 }
    procedure SetState(AState: Word; Enable: Boolean); virtual;
  end;

procedure ASCIITable;
procedure RSRASCIITab(RSR: PResourceFile);
procedure LoadASCIITab;
procedure ExecASCIITab;

implementation

uses Dialogs, MsgBox, EditMsg, HotKeys, KeyDlg, UserScr, WinPos, CNWinPos,
  Consts, Commands, Defaults;

const
  cmCharFocused = 910;
  ModalInUse: Boolean = False;
  ModalCaller: PView = nil;

procedure TTable.Draw;
var
  Color: Byte;
  X, Y: Integer;
  Buf: TDrawBuffer;
begin
  Color := GetColor(6);
  for Y := 0 to Size.Y - 1 do
  begin
    MoveChar(Buf, ' ', Color, Size.X);
    for X := 0 to Size.X - 1 do
      MoveChar(Buf[x], Chr(32 * y + x), Color, 1);
    WriteLine(0, y, Size.X, 1, Buf);
  end;
end;

procedure TTable.HandleEvent(var Event: TEvent);
var
  P: Pointer;
  CurrentSpot: TPoint;

procedure CharFocused;
begin
  Message(Owner, evBroadcast, cmCharFocused,
    Pointer(Cursor.X + 32 * Cursor.Y));
end;

procedure CharSelected;

function CanHandle(AView: PView): Boolean; far;
begin
  CanHandle :=
    (AView^.State and sfActive = 0) and
    (AView^.State and sfVisible <> 0) and
    (AView^.Options and ofSelectable <> 0);
end;

var
  SaveKeys: Word;
begin
  if Owner^.State and sfModal <> 0 then P := ModalCaller
  else P := Owner^.Owner^.FirstThat(@CanHandle);
  if P = nil then Exit;
  SaveKeys := WordStarKeys;
  WordStarKeys := 0;
  Message(P, evKeyDown, Word(Cursor.X + 32 * Cursor.Y), nil);
  WordStarKeys := SaveKeys;
  if GetShiftState and kbCtrlShift <> 0 then
  begin
    Pending.What := evCommand;
    Pending.Command := cmClose;
    Pending.InfoPtr := nil;
  end;
  Event.What := evNothing;
end;

procedure KeyCodeDlg;
const
  W: Word = 0;
var
  Top: Boolean;
  D: PHotKeyDialog;
  R: TRect;
begin
  Owner^.GetBounds(R);
  Inc(R.A.X, 4); R.B.X := R.A.X + 26;
  Inc(R.A.Y, 2); R.B.Y := R.A.Y + 7;
  D := New(PHotKeyDialog, Init(R, 'Key codes'));
  with D^ do
  begin
    HelpCtx := hcKeyView;
    R.Assign(1, 2, Size.X - 1, 3);
    KeyView := New(PKeyView, Init(R));
    Insert(KeyView);
    KeyView^.Options := KeyView^.Options or ofCentered;
    R.Assign(2, 4, 12, 6);
    Insert(New(PButton, Init(R, '~C~opy', cmDefault, bfDefault)));
    R.Assign(13, 4, 23, 6);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  Top := Owner^.Owner = Pointer(Application);
  Application^.ExecuteDialog(D, @W, Top);
end;

{ Added 2005.10.03 }
procedure CopyToClipboard;
var
  S: String[1];
begin
  S := Char(Cursor.X + 32 * Cursor.Y);
  Message(Application, evBroadcast, cmCopy, @S);
end;

begin
  if Event.What = evMouseDown then
  begin
    if (Event.Buttons = mbRightButton) and
       Owner^.MouseInView(Event.Where) then
    begin
      repeat until not MouseEvent(Event, evMouseDown);
      KeyCodeDlg;
    end
    else
    repeat
      if MouseInView(Event.Where) then
      begin
	MakeLocal(Event.Where, CurrentSpot);
	SetCursor(CurrentSpot.X, CurrentSpot.Y);
	CharFocused;
      end;
    until not MouseEvent(Event, evMouseMove);
    if Event.Double then CharSelected;
    Event.What := evNothing;
  end;
  if Event.What = evKeyDown then
    with Cursor do begin
      case Event.KeyCode of
	kbEnter, kbCtrlEnter:
	  begin
	    CharSelected;
	    Exit;
	  end;
	kbEsc:
	  begin
	    Pending.What := evCommand;
	    Pending.Command := cmClose;
	    Pending.InfoPtr := Owner;
	    Event.What := evNothing;
	  end;
	kbHome: SetCursor(0, 0);
	kbEnd: SetCursor(Size.X - 1, Size.Y - 1);
	kbUp: if Y > 0 then SetCursor(X, Y - 1);
	kbDown: if Y < Size.Y - 1 then SetCursor(X, Y + 1);
	kbLeft: if X > 0 then SetCursor(X - 1, Y);
	kbRight: if X < Size.X - 1 then SetCursor(X + 1, Y);
	kbCtrlUp, kbCtrlDn: KeyCodeDlg;
{ Added 2005.10.03 }
	kbCtrlIns: CopyToClipboard;
	kbCtrlF12:
	  begin
	    Pending.What := evCommand;
	    Pending.Command := cmCopyToMT;
	    Pending.InfoPtr := Owner;
	  end;
      else
	SetCursor(ord(Event.CharCode) mod 32, ord(Event.CharCode) div 32);
      end;
      CharFocused;
      Event.What := evNothing;
    end;
{ Added 2005.10.03 }
  if Event.What = evCommand then
  begin
    if Event.Command = cmCopy then CopyToClipboard
    else Exit;
    Event.What := evNothing;
  end;
end;

{ TReport }

constructor TReport.Load(var S: TStream);
begin
  TView.Load(S);
  S.Read(ASCIIChar, SizeOf(ASCIIChar));
end;

procedure TReport.Draw;
var
  C: Word;
  B: TDrawBuffer;
  S: String;
begin
  FormatStr(S, 'Char: %c Decimal: %0#%-3d Hex: %0#%02x', ASCIIChar);
  C := GetColor(6);
  MoveChar(B, ' ', C, Size.X);
  MoveStr(B[1], S, C);
  WordRec(B[Length(S) + 2]).Hi := Byte(ASCIIChar);
  WordRec(B[Length(S) + 2]).Lo := 254;
  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TReport.HandleEvent(var Event: TEvent);
begin
  TView.HandleEvent(Event);
  if Event.What = evBroadcast then
    case Event.Command of
      cmCharFocused:
	begin
	  ASCIIChar := Event.InfoLong;
	  DrawView;
	end;
      cmASCIITable:
	begin
	  PWindow(Owner)^.Deiconize;
	  Owner^.Show;
	  Owner^.Select;
	  ClearEvent(Event);
	end;
    end;
end;

procedure TReport.Store(var S: TStream);
begin
  TView.Store(S);
  S.Write(ASCIIChar, SizeOf(ASCIIChar));
end;

constructor TASCIIChart.Init;
var
  Control: PVIew;
  R: TRect;
begin
  R.Assign(1, 1, 35, 13);
  TWindow.Init(R, 'ASCII Chart', wnNoNumber);
  Flags := Flags and not (wfGrow + wfZoom);
  GrowMode := gfExplode;
  Palette := wpGrayWindow;

  R.Assign(1, Size.Y - 2, Size.X - 1, Size.Y - 1);
  Control := New(PReport, Init(R));
  with Control^ do
  begin
    Options := Options or ofFramed;
    EventMask := EventMask or evBroadcast;
  end;
  Insert(Control);

  R.Assign(1, 1, Size.X - 1, Size.Y - 3);
  Control := New(PTable, Init(R));
  with Control^ do
  begin
    Options := Options or (ofSelectable + ofFramed);
    BlockCursor;
    ShowCursor;
  end;
  Insert(Control);

  WinPos := @CharWinPos;
end;

constructor TASCIIChart.Load(var S: TStream);
begin
  TWindow.Load(S);
  WinPos := @CharWinPos;
end;

function TASCIIChart.GetHelpCtx: Word;
begin
  if State and sfDragging <> 0 then
    GetHelpCtx := hcDragging
  else GetHelpCtx := hcASCIITable;
end;

procedure TASCIIChart.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evCommand) and (Event.Command = cmCancel) and
     (State and sfModal <> 0) then
  begin
    EndModal(cmCancel);
    Event.What := evNothing;
  end
  else TWindow.HandleEvent(Event);
end;

{ Added 2005.10.03 }
procedure TASCIIChart.SetState(AState: Word; Enable: Boolean);
begin
  inherited SetState(AState, Enable);
  if Enable and (AState = sfFocused) then EnableCommands(
    CopyCommands + MTCopyCommands)
  else if not Enable and
    (((AState = sfActive) and GetState(sfExposed)) or
      (AState = sfExposed)) then DisableCommands(
	CopyCommands + MTCopyCommands);
end;

procedure ASCIITable;
begin
  Application^.InsertWindow(New(PASCIIChart, Init));
end;

procedure RSRASCIITab(RSR: PResourceFile);
var
  P: PASCIIChart;
begin
  P := New(PASCIIChart, Init);
  RSR^.Put(P, 'ASCIITAB');
  Dispose(P, Done);
end;

procedure PrepareCursorChar;
type
  TVideoArray = Array[0..24, 0..79] of Word;
var
  CursorState: Word;
  CursorPos: TPoint;
begin
  CursorState := GetCursorState;
  if CursorState = $2000 then Exit;
  GetCursorPos(CursorPos);
  Pending.What := evKeyDown;
  Pending.CharCode := Char(
    TVideoArray(ScreenBuffer^)[CursorPos.Y, CursorPos.X]);
end;

procedure LoadASCIITab;
var
  R: TRect;
  P: PASCIIChart;
begin
  if Message(Desktop, evBroadcast, cmASCIITable, nil) <> nil then Exit;
  P := PASCIIChart(Resource^.Get('ASCIITAB'));
  if P <> nil then
  begin
    PrepareCursorChar;
    if (WinPosMask and wpChar <> 0) and ValidWinPos(CharWinPos) then
    begin
      SetWinPos(Desktop, CharWinPos, R);
      P^.MoveTo(R.A.X, R.A.Y);
    end;
    Application^.InsertWindow(P);
  end
  else ResourceNotFoundMsgBox('ASCII table');
end;

procedure ExecASCIITab;
var
  R: TRect;
  P: PASCIIChart;
  O: PGroup;
begin
  if ModalInUse then Exit;
  P := PASCIIChart(Resource^.Get('ASCIITAB'));
  if Application^.ValidView(P) <> nil then
  begin
    ModalCaller := Application^.TopView;
    ModalInUse := True;
    PrepareCursorChar;
    if Desktop = Pointer(Application^.Current) then O := Desktop
    else O := Application;
    if (WinPosMask and wpChar <> 0) and ValidWinPos(CharWinPos) then
    begin
      SetWinPos(O, CharWinPos, R);
      P^.MoveTo(R.A.X, R.A.Y);
    end
    else if Pointer(O) = Application then
      P^.MoveTo(1, Desktop^.Origin.Y + 1);
    O^.ExecView(P);
    Dispose(P, Done);
    ModalCaller := nil;
    ModalInUse := False;
  end;
end;

end.
