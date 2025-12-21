{$I-,F+,O+,X+}
unit ListEdit;

interface

uses Objects, Drivers, Views;

type
  PIndicator = ^TIndicator;
  TIndicator = object(TView)
    procedure Draw; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
  end;

  PListEditor = ^TListEditor;
  TListEditor = object(TScroller)
    List: PCollection;
    Name: FNameStr;
    Line: String;
    Idx: Integer;
    Modified: Boolean;
    DisposeList: Boolean;
    constructor Init(var Bounds: TRect;
      AHScrollBar, AVScrollBar: PScrollBar;
      AList: PCollection; AName: FNameStr; Modal: Boolean);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure GetLine(Index: Integer; var S: String); virtual;
    procedure InsertLine(Index: Integer; const S: String); virtual;
    procedure ReplaceLine(Index: Integer; const S: String); virtual;
    procedure FreeLine(Index: Integer); virtual;
    procedure InsertChar(C: Char);
    procedure DeleteChar(Backward: Boolean);
    procedure DeleteLine;
    procedure Enter;
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
    procedure ToggleInsert;
    procedure UpdateLine(Index: Integer);
    procedure UpdateIndicator;
  end;

  PListWindow = ^TListWindow;
  TListWindow = object(TWindow)
    Editor: PListEditor;
    Indicator: PIndicator;
    constructor Init(Bounds: TRect; ATitle: TTitleStr;
      AList: PCollection; AName: FNameStr; Modal: Boolean);
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
  end;

  TSavePromptFunc = function: Word;
  TSaveFunc = function(P: Pointer; const Name: FNameStr): Word;
  TSaveAsFunc = function(P: Pointer; var Name: FNameStr): Word;
  TPrintFunc = function(P: Pointer): Word;

function DefSavePromptFunc: Word;
function DefSaveFunc(P: Pointer; const Name: FNameStr): Word;
function DefSaveAsFunc(P: Pointer; var Name: FNameStr): Word;
function DefPrintFunc(P: Pointer): Word;

const
  SavePromptFunc: TSavePromptFunc = DefSavePromptFunc;
  SaveFunc: TSaveFunc = DefSaveFunc;
  SaveAsFunc: TSaveAsFunc = DefSaveAsFunc;
  PrintFunc: TPrintFunc = DefPrintFunc;

procedure EditList(AList: PCollection; AName: FNameStr;
  ATitle: TTitleStr; AHelpCtx: Word; Modal: Boolean);

implementation

uses Dialogs, App, MsgBox, StdDlg, HistList, History,
  DosTools, Printer, TPString, Commands;

procedure TIndicator.Draw;
type
  TParams = Array[0..1] of Longint;
var
  S: String;
  B: TDrawBuffer;
  Params: TParams;
  C: Byte;
  Ch: Char;
begin
  if State and sfActive = 0 then
  begin
    C := GetColor(1);
    Ch := '─';
  end
  else if State and sfDragging <> 0 then
  begin
    C := GetColor(3);
    Ch := '─';
  end
  else
  begin
    Ch := '═';
    C := GetColor(2);
  end;
  MoveChar(B, Ch, C, Size.X);
  with PListWindow(Owner)^.Editor^ do
  begin
    Params[0] := Delta.Y + Cursor.Y + 1;
    Params[1] := Delta.X + Cursor.X + 1;
    FormatStr(S, ' %d:%d ', Params);
    if Modified then MoveChar(B, '', C, 1);
  end;
  MoveStr(B[3], S, C);
  WriteLine(0, 0, Size.X, 1, B);
end;

procedure TIndicator.SetState(AState: Word; Enable: Boolean);
begin
  Inherited SetState(AState, Enable);
  DrawView;
end;

constructor TListEditor.Init(var Bounds: TRect; AHScrollBar,
  AVScrollBar: PScrollBar; AList: PCollection; AName: FNameStr;
  Modal: Boolean);
begin
  Inherited Init(Bounds, AHScrollbar, AVScrollBar);
  GrowMode := gfGrowHiX + gfGrowHiY;
  ShowCursor;
  Limit.X := 255;
  Limit.Y := AList^.Count + 1;
  SetLimit(Limit.X, Limit.Y);
  List := AList;
  Name := AName;
  Idx := -1;
  DisposeList := not Modal;
end;

destructor TListEditor.Done;
begin
  if DisposeList and (List <> nil) then Dispose(List, Done);
  Inherited Done;
end;

procedure TListEditor.Draw;
var
  S: String;
  B: TDrawBuffer;
  C: Word;
  I: Integer;
begin
  C := GetColor(1);
  for I := 0 to Size.Y - 1 do
  begin
    MoveChar(B, ' ', C, Size.X);
    if Delta.Y + I < List^.Count then
    begin
      GetLine(Delta.Y + I, S);
      MoveStr(B, System.Copy(S, Delta.X + 1, Size.X), C);
    end;
    WriteLine(0, I, Size.X, 1, B);
  end;
end;

procedure TListEditor.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
begin
  Inherited HandleEvent(Event);
  case Event.What of
    evMouseDown: if MouseInView(Event.Where) then
      begin
	repeat
	  if MouseInView(Event.Where) then
	  begin
	    MakeLocal(Event.Where, Mouse);
	    while Delta.Y + Mouse.Y > List^.Count do Dec(Mouse.Y);
	    SetCursor(Mouse.X, Mouse.Y);
	  end
	  else
	  begin
	    Mouse.X := 0;
	    Mouse.Y := 0;
	    MakeGlobal(Mouse, Mouse);
	    if Event.Where.X < Mouse.X then GoLeft;
	    if Event.Where.X > Mouse.X + Size.X - 1 then GoRight;
	    if Event.Where.Y < Mouse.Y then GoUp;
	    if Event.Where.Y > Mouse.Y + Size.Y - 1 then GoDown;
	  end;
	  UpdateIndicator;
	until not MouseEvent(Event, evMouseMove + evMouseAuto);
	ClearEvent(Event);
      end;
    evKeyDown:
      begin
	if Cursor.X < 0 then ScrollTo(0, Delta.Y);
	if Cursor.X >= Size.X then ScrollTo(Cursor.X - Size.X + 1, Delta.Y);
	if Cursor.Y < 0 then ScrollTo(Delta.X, Delta.Y + Cursor.Y);
	if Cursor.Y >= Size.Y then
	  ScrollTo(Delta.X, Delta.Y + Cursor.Y - Size.Y + 1);
	if Event.CharCode = ^Y then DeleteLine
	else if Event.CharCode >= #32 then InsertChar(Event.CharCode)
	else case CtrlToArrow(Event.KeyCode) of
	  kbBack:      DeleteChar(True);
	  kbDel:       DeleteChar(False);
	  kbDown:      GoDown;
	  kbUp:        GoUp;
	  kbRight:     GoRight;
	  kbLeft:      GoLeft;
	  kbPgDn:      GoPgDn;
	  kbPgUp:      GoPgUp;
	  kbCtrlPgDn:  GoCtrlPgDn;
	  kbCtrlPgUp:  GoCtrlPgUp;
	  kbHome:      GoHome;
	  kbEnd:       GoEnd;
	  kbIns:       ToggleInsert;
	  kbEnter:     Enter;
	  kbEsc:
	    begin
	      Pending.What := evCommand;
	      Pending.Command := cmClose;
	    end;
	  else Exit;
	end;
	UpdateIndicator;
	ClearEvent(Event);
      end;
    evCommand:
      begin
	UpdateLine(-1);
	case Event.Command of
	  cmSave:
	    if Name = '' then
	      if SaveAsFunc(List, Name) = cmOk then Modified := False else
	    else if SaveFunc(List, Name) = cmOk then Modified := False;
	  cmSaveAs: if SaveAsFunc(List, Name) = cmOk then Modified := False;
	  cmPrint: PrintFunc(List);
	  else Exit;
	end;
	UpdateIndicator;
	ClearEvent(Event);
      end;
    evBroadcast:
      begin
	case Event.Command of
	  cmUpdateViews:
	    begin
	      if Event.InfoPtr <> nil then
		List^.Insert(NewStr(PString(Event.InfoPtr)^));
	      SetLimit(Limit.X, List^.Count + 1);
	      GoCtrlPgDn;
	      DrawView;
	      Modified := True;
	      UpdateIndicator;
	    end;
	end;
      end;
  end;
end;

procedure TListEditor.GetLine(Index: Integer; var S: String);
var
  P: PString;
begin
  if Index = Idx then S := Line
  else
  begin
    P := List^.At(Index);
    if P = nil then S := '' else S := TrimTrail(P^);
  end;
end;

procedure TListEditor.FreeLine(Index: Integer);
begin
  if Index < List^.Count then List^.AtFree(Index);
end;

procedure TListEditor.InsertLine(Index: Integer; const S: String);
begin
  if Index <= List^.Count then List^.AtInsert(Index, NewStr(TrimTrail(S)));
end;

procedure TListEditor.ReplaceLine(Index: Integer; const S: String);
begin
  FreeLine(Index);
  InsertLine(Index, S);
end;

procedure TListEditor.InsertChar(C: Char);
var
  I: Integer;
  B: Byte;
begin
  I := Delta.Y + Cursor.Y;
  B := Delta.X + Cursor.X + 1;
  UpdateLine(I);
  if B > Length(Line) then
  begin
    if C = #32 then
    begin
      GoRight;
      Exit;
    end;
    Line := Pad(Line, B);
    Line[Length(Line)] := C;
  end
  else
  if Length(Line) = 255 then
  begin
    Write(^G);
    Exit;
  end
  else if State and sfCursorIns = 0 then Insert(C, Line, B)
  else Line[B] := C;
  Modified := True;
  if Cursor.X = Size.X - 1 then ScrollTo(Delta.X + Size.X div 4, Delta.Y);
  GoRight;
  DrawView;
end;

procedure TListEditor.DeleteChar(Backward: Boolean);
var
  S: String;
  I: Integer;
  B: Byte;
begin
  I := Delta.Y + Cursor.Y;
  B := Delta.X + Cursor.X + 1;
  if I = List^.Count then Exit;
  UpdateLine(I);
  if Backward then
    if (B > Length(Line) + 1) or (Line = '') or (B = 1) then
    begin
      GoLeft;
      Exit;
    end
    else
    begin
      Delete(Line, B - 1, 1);
      GoLeft;
    end
  else
  begin
    if B > Length(Line) then
    begin
      if (I = List^.Count - 1) and (Line <> '') then Exit;
      GetLine(I + 1, S);
      if B + Length(S) <= 256 then
      begin
	Line := Pad(Line, B - 1) + S;
	if (I = List^.Count - 1) and (Line = '') then FreeLine(I)
	else
	begin
	  FreeLine(I + 1);
	  ReplaceLine(I, Line);
	end;
	SetLimit(Limit.X, List^.Count + 1);
      end
      else Write(^G);
    end
    else Delete(Line, B, 1);
  end;
  Modified := True;
  DrawView;
end;

procedure TListEditor.DeleteLine;
var
  I: Integer;
begin
  I := Delta.Y + Cursor.Y;
  if I = List^.Count then Exit;
  UpdateLine(-1);
  FreeLine(I);
  Modified := True;
  SetLimit(Limit.X, List^.Count + 1);
  GoHome;
  DrawView;
end;

procedure TListEditor.Enter;
var
  S: String;
  I: Integer;
  B: Byte;
begin
  I := Delta.Y + Cursor.Y;
  B := Delta.X + Cursor.X + 1;
  UpdateLine(-1);
  if not (State and sfCursorIns <> 0) then
  begin
    GetLine(I, S);
    if B > Length(S) then
      if I = List^.Count then InsertLine(I, '')
      else InsertLine(I + 1, '')
    else
    begin
      ReplaceLine(I, System.Copy(S, 1, B - 1));
      S := System.Copy(S, B, 255);
      InsertLine(I + 1, S);
    end;
    Modified := True;
    SetLimit(Limit.X, List^.Count + 1);
  end;
  GoDown;
  GoHome;
  DrawView;
end;

procedure TListEditor.FastScrollTo(Y: Integer);
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

procedure TListEditor.GoRight;
begin
  if Delta.X + Cursor.X = Limit.X - 1 then Exit;
  SetCursor(Cursor.X + 1, Cursor.Y);
  if Cursor.X = Size.X then ScrollTo(Delta.X + 1, Delta.Y);
end;

procedure TListEditor.GoLeft;
begin
  if Delta.X + Cursor.X = 0 then Exit;
  SetCursor(Cursor.X - 1, Cursor.Y);
  if Cursor.X < 0 then ScrollTo(Delta.X - 1, Delta.Y);
end;

procedure TListEditor.GoDown;
begin
  if Delta.Y + Cursor.Y = List^.Count then Exit;
  if Cursor.Y < Size.Y - 1 then SetCursor(Cursor.X, Cursor.Y + 1)
  else FastScrollTo(Delta.Y + 1);
end;

procedure TListEditor.GoUp;
begin
  if Delta.Y + Cursor.Y = 0 then Exit;
  if Cursor.Y > 0 then SetCursor(Cursor.X, Cursor.Y - 1)
  else FastScrollTo(Delta.Y - 1);
end;

procedure TListEditor.GoPgDn;
begin
  if Delta.Y + Size.Y >= List^.Count then GoCtrlPgDn
  else FastScrollTo(Delta.Y + Size.Y - 1);
  while Delta.Y + Cursor.Y > List^.Count do GoUp;
end;

procedure TListEditor.GoPgUp;
begin
  if Delta.Y = 0 then GoCtrlPgUp
  else FastScrollTo(Delta.Y - Size.Y + 1);
end;

procedure TListEditor.GoCtrlPgDn;
begin
  ScrollTo(0, List^.Count);
  SetCursor(0, Size.Y - 1);
  while Delta.Y + Cursor.Y > List^.Count do GoUp;
end;

procedure TListEditor.GoCtrlPgUp;
begin
  ScrollTo(0, 0);
  SetCursor(0, 0);
end;

procedure TListEditor.GoHome;
begin
  ScrollTo(0, Delta.Y);
  SetCursor(0, Cursor.Y);
end;

procedure TListEditor.GoEnd;
var
  S: String;
  I: Integer;
begin
  I := Delta.Y + Cursor.Y;
  GetLine(I, S);
  ScrollTo(0, Delta.Y);
  SetCursor(Length(S) - Delta.X, Cursor.Y);
  if Cursor.X >= Size.X then ScrollTo(Cursor.X - Size.X + 1, Delta.Y);
end;

procedure TListEditor.ToggleInsert;
begin
  if State and sfCursorIns <> 0 then NormalCursor else BlockCursor;
end;

procedure TListEditor.UpdateLine(Index: Integer);
begin
  if Index = Idx then Exit;
  ReplaceLine(Idx, Line);
  if Index = List^.Count then
  begin
    InsertLine(Index, '');
    SetLimit(Limit.X, List^.Count + 1);
  end;
  GetLine(Index, Line);
  Idx := Index;
end;

procedure TListEditor.UpdateIndicator;
begin
  PListWindow(Owner)^.Indicator^.DrawView;
end;

constructor TListWindow.Init(Bounds: TRect; ATitle: TTitleStr;
  AList: PCollection; AName: FNameStr; Modal: Boolean);
var
  R: TRect;
  Control: PView;
begin
  Inherited Init(Bounds, ATitle, wnNoNumber);
  Options := Options or ofTileable;

  GetExtent(R);
  Inc(R.A.X, 17); Dec(R.B.X, 2); R.A.Y := Pred(R.B.Y);
  Control := New(PScrollBar, Init(R));
  Insert(Control);

  GetExtent(R);
  Inc(R.A.X, 2); R.A.Y := Pred(R.B.Y); R.B.X := R.A.X + 14;
  Indicator := New(PIndicator, Init(R));
  Indicator^.GrowMode := gfGrowLoY + gfGrowHiY;
  Insert(Indicator);

  GetExtent(R);
  R.Grow(-1, -1);
  Editor := New(PListEditor, Init(R,
    PScrollBar(Control),
    StandardScrollBar(sbVertical + sbHandleKeyboard), AList, AName, Modal));
  Insert(Editor);
end;

procedure TListWindow.HandleEvent(var Event: TEvent);

procedure SaveOrCancel;
var
  C: Word;
begin
  C := SavePromptFunc;
  case C of
    cmYes: with Editor^ do
      begin
	UpdateLine(-1);
	if Name = '' then C := SaveAsFunc(List, Name)
	else C := SaveFunc(List, Name);
	if C <> cmOk then ClearEvent(Event)
	else Modified := False;
	UpdateIndicator;
      end;
    cmCancel: ClearEvent(Event);
  end;
end;

begin
  if Editor^.Modified then
    if ((Event.What = evBroadcast) and (Event.Command = cmQuit)) or
       ((Event.What = evCommand) and (Event.Command = cmClose)) then
      SaveOrCancel;
  if (Event.What = evCommand) and
     ((Event.Command = cmClose) or (Event.Command = cmCancel)) and
     (State and sfModal <> 0) then
  begin
    EndModal(cmCancel);
    ClearEvent(Event);
  end;
  Inherited HandleEvent(Event);
end;

procedure TListWindow.SizeLimits(var Min, Max: TPoint);
begin
  Inherited SizeLimits(Min, Max);
  Min.X := 22;
end;

function DefSavePromptFunc: Word;
begin
  DefSavePromptFunc := MessageBox(
    ^C'Записать изменения в файл ?',
    nil, mfConfirmation + mfYesNoCancel);
end;

function DefSaveFunc(P: Pointer; const Name: FNameStr): Word;
var
  F: Text;
  List: PCollection;
  PS: PString;
  I: Integer;
begin
  DefSaveFunc := cmOk;
  DrawStatusLine('Записывается файл ' + TrimmedName(Name, 45) + '.');
  List := PCollection(P);
  Assign(F, Name);
  Rewrite(F);
  for I := 0 to List^.Count - 1 do
  begin
    if IOResult <> 0 then
    begin
      DefSaveFunc := cmCancel;
      Break;
    end;
    PS := List^.At(I);
    if PS = nil then Writeln(F) else Writeln(F, PS^);
  end;
  Close(F);
  InOutRes := 0;
end;

function DefSaveAsFunc(P: Pointer; var Name: FNameStr): Word;
var
  S: FNameStr;
  C: Word;
begin
  if Name = '' then S := HistoryStr(HistoryID, 0)
  else S := Name;
  C := Application^.ExecuteDialog(
    New(PFileDialog, Init('*.*', 'Записать в файл',
      '~И~мя', fdOkButton + fdHelpButton, HistoryID)), @S, False);
  if (C <> cmCancel) and ThisFileExists(S) then
    C := MessageBox(^C'Такой файл уже существует. Переписать ?',
      nil, mfConfirmation + mfOkCancel);
  if C <> cmCancel then C := SaveFunc(P, S);
  if C <> cmCancel then Name := S;
  DefSaveAsFunc := C;
end;

function DefPrintFunc(P: Pointer): Word;
var
  List: PCollection;
  PS: PString;
  I: Integer;
begin
  DefPrintFunc := cmOk;
  DrawStatusLine('Печатается текст.');
  List := PCollection(P);
  for I := 0 to List^.Count - 1 do
  begin
    PS := List^.At(I);
    if PS = nil then Writeln(Lst) else Writeln(Lst, PS^);
  end;
end;

procedure EditList(AList: PCollection; AName: FNameStr;
  ATitle: TTitleStr; AHelpCtx: Word; Modal: Boolean);
var
  R: TRect;
  W: PListWindow;
begin
  if AList = nil then Exit;
  Desktop^.GetExtent(R);
  W := New(PListWindow, Init(R, ATitle, AList, AName, Modal));
  W^.HelpCtx := AHelpCtx;
  if Modal then Application^.ExecuteDialog(PDialog(W), nil, False)
  else Application^.InsertWindow(W);
end;

end.
