{$O+,F+,X+}
unit WinList;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PWinCollection = ^TWinCollection;
  TWinCollection = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PWinList = ^TWinList;
  TWinList = object(TListViewer)
    WinCollection: PWinCollection;
    constructor Init(var Bounds: TRect; ANumCols: Integer;
      AHScrollBar, AVScrollBar: PScrollBar);
    destructor Done; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure FillList;
    procedure WindowFlags;
  end;

  PReopenViewer = ^TReopenViewer;
  TReopenViewer = object(THistoryViewer)
    function GetCopyText(Item: Integer; MaxLen: Integer): String; virtual;
    function GetText(Item: Integer; MaxLen: Integer): String; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PReopenWindow = ^TReopenWindow;
  TReopenWindow = object(THistoryWindow)
    procedure InitViewer(HistoryId: Word); virtual;
  end;

  PWinDialog = ^TWinDialog;
  TWinDialog = object(TDialog)
    WindowList: PWinList;
    SaveCommands: TCommandSet;
    constructor Init;
    destructor Done; virtual;
    procedure EndModal(Command: Word); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure List;

implementation

uses WinIcons, App, HistList, Memory, MsgBox, History, Compiler,
  TPString, Consts, Commands;

procedure TWinCollection.FreeItem(Item: Pointer);
begin
end;

constructor TWinList.Init(var Bounds: TRect; ANumCols: Integer;
  AHScrollBar, AVScrollBar: PScrollBar);
begin
  TListViewer.Init(Bounds, 1, AHScrollBar, AVScrollBar);
  GrowMode := gfGrowHiY;
  WinCollection := New(PWinCollection, Init(10, 10));
  FillList;
  if Range > 1 then FocusItem(1);
end;

destructor TWinList.Done;
begin
  if WinCollection <> nil then Dispose(WinCollection, Done);
  TListViewer.Done;
end;

function TWinList.GetText(Item: Integer; MaxLen: Integer): String;
var
  P: PWindow;
  S: String;
begin
  P := WinCollection^.At(Item);
  if P = nil then GetText := ''
  else
  begin
    S := '    ' + P^.GetTitle(255);
    if P^.Number > 0 then S[1] := Char(P^.Number + $30);
    if P^.State and sfVisible = 0 then S[3] := '°';
    GetText := S;
  end;
end;

procedure TWinList.HandleEvent(var Event: TEvent);
begin
  if ((Event.What = evMouseDown) and Event.Double) or
     ((Event.What = evKeyDown) and (Event.CharCode = ' ')) then
  begin
    Pending.What := evCommand;
    Pending.Command := cmOk;
    Event.What := evNothing;
  end
  else TListViewer.HandleEvent(Event);
end;

procedure TWinList.FillList;
var
  CanHide, CanShow: Boolean;

procedure StuffWindow(W: PView); far;
begin
  if W <> Desktop^.Last then
  begin
    WinCollection^.Insert(W);
    if W^.State and sfVisible <> 0 then CanHide := True
    else CanShow := True;
  end;
end;

begin
  CanHide := False;
  CanShow := False;
  Desktop^.ForEach(@StuffWindow);
  SetRange(WinCollection^.Count);
  if WinCollection^.Count > 0 then EnableCommands(
    NewCommands + DeleteCommands + RunItemCommands + ModifyCommands)
  else DisableCommands(
    NewCommands + DeleteCommands + RunItemCommands + ModifyCommands);
  if CanHide then EnableCommands(HideCommands)
  else DisableCommands(HideCommands);
  if CanShow then EnableCommands(ShowCommands)
  else DisableCommands(ShowCommands);
end;

procedure TWinList.WindowFlags;
const
  flShadow = 1;
  flTileable = 2;
var
  V, Control: PView;
  D: PDialog;
  R: TRect;
  W: Word;

function IsTileable(P: PView): Boolean; far;
begin
  IsTileable := (P^.Options and ofTileable <> 0) and
    (P^.State and sfVisible <> 0);
end;

begin
  V := WinCollection^.At(Focused);
  if V <> nil then
  begin
    R.Assign(0, 0, 24, 9);
    D := New(PDialog, Init(R, 'Window flags'));
    with D^ do
    begin
      Options := Options or ofCentered;
      HelpCtx := hcWindowFlags;
      R.Assign(5, 3, 19, 5);
      Control := New(PCheckBoxes, Init(R,
	NewSItem('~S~hadow',
	NewSItem('~T~ileable', nil))));
      Insert(Control);
      R.Assign(4, 2, 19, 3);
      Insert(New(PLabel, Init(R, 'Flags', Control)));

      R.Assign(3, Size.Y - 3, 9, Size.Y - 1);
      StandardOkButton(R, D);
      R.Assign(Size.X - 13, Size.Y - 3, Size.X - 3, Size.Y - 1);
      StandardCancelButton(R, D);
      SelectNext(False);
    end;
    W := 0;
    if V^.State and sfShadow <> 0 then W := W or flShadow;
    if V^.Options and ofTileable <> 0 then W := W or flTileable;
    if Application^.ExecuteDialog(D, @W, True) <> cmCancel then
    begin
      V^.SetState(sfShadow, W and flShadow <> 0);
      if (W and flTileable <> 0) and
	 (PWindow(V)^.Flags and wfGrow <> 0) then
	V^.Options := V^.Options or ofTileable
      else V^.Options := V^.Options and not ofTileable;
      V^.DrawView;
      if Desktop^.FirstThat(@IsTileable) <> nil then
	EnableCommands(TileCommands) else DisableCommands(TileCommands);
    end;
  end;
end;

function TReopenViewer.GetCopyText(Item: Integer; MaxLen: Integer): String;
var
  S: String;
begin
  S := GetText(Item, MaxLen);
  Delete(S, 1, 8);
  GetCopyText := S;
end;

function TReopenViewer.GetText(Item: Integer; MaxLen: Integer): String;
var
  S: String;
begin
  S := THistoryViewer.GetText(Item, MaxLen);
  S[0] := Char(Pos(#$FF, S) - 1);
  GetText := S;
end;

procedure TReopenViewer.HandleEvent(var Event: TEvent);
var
  C: Char;
  I: Integer;
  S: String;
begin
  if (Event.What = evKeyDown) and (Event.CharCode in ['0'..'9']) then
  begin
    C := Event.CharCode;
    repeat
      I := HistoryCount(HistoryId);
      THistoryViewer.HandleEvent(Event);
      if I = HistoryCount(HistoryId) then Break;
      Event.What := evKeyDown;
      Event.CharCode := C;
    until False;
  end;
  if ((Event.What = evMouseDown) and (Event.Double)) or
     ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) then
  begin
    Message(Application, evCommand, cmReopen + Focused, nil);
    SetRange(HistoryCount(HistoryId));
    HScrollBar^.SetRange(0, HistoryWidth(HistoryId) - Size.X + 3);
    Message(Application, evBroadcast, cmUpdateViews, nil);
    DrawView;
    Event.What := evNothing;
  end
  else if (Event.What = evKeyDown) and
    ((Event.KeyCode = kbCtrlEnter) or (Event.CharCode = ^\)) then
  begin
    S := HistoryStr(ReopenHistoryID, Focused);
    I := Pos(#$FF, S);
    if I <> 0 then S[0] := Char(I - 1);
    S := System.Copy(S, 7, 255);
    if Message(Desktop, evBroadcast, cmReopen, @S) <> nil then
    begin
      Pending.What := evCommand;
      Pending.Command := cmCancel;
      EndModal(cmCancel);
    end;
    Event.What := evNothing;
  end
  else THistoryViewer.HandleEvent(Event);
end;

procedure TReopenWindow.InitViewer(HistoryId: Word);
var
  R: TRect;
begin
  DisposeStr(Title);
  Title := NewStr('Reopen a file');
  HelpCtx := hcReopen;
  GetExtent(R);
  R.Grow(-1,-1);
  Viewer := New(PReopenViewer, Init(R,
    StandardScrollBar(sbHorizontal + sbHandleKeyboard),
    StandardScrollBar(sbVertical + sbHandleKeyboard),
    HistoryId));
  Insert(Viewer);
  Viewer^.FocusItem(0);
end;

constructor TWinDialog.Init;
var
  HBar, VBar: PScrollBar;
  R: TRect;
begin
  R.Assign(0, 0, 69, ScreenHeight - 4);
  TDialog.Init(R, 'Window list');
  Options := Options or ofCentered;
  GrowMode := GrowMode + gfGrowHiY;
  HelpCtx := hcWList;

  R.Assign(3, Size.Y - 2, Size.X - 15, Size.Y - 1);
  HBar := New(PScrollBar, Init(R));
  HBar^.Options := HBar^.Options or ofPostProcess;
  HBar^.SetRange(0, 255);
  Insert(HBar);

  R.Assign(Size.X - 15, 2, Size.X - 14, Size.Y - 2);
  VBar := New(PScrollBar, Init(R));
  VBar^.Options := VBar^.Options or ofPostProcess;
  Insert(VBar);

  R.Assign(3, 2, Size.X - 15, Size.Y - 2);
  WindowList := New(PWinList, Init(R, 1,
    PScrollBar(HBar), PScrollBar(VBar)));
  Insert(WindowList);
  R.Assign(2, 1, Size.X - 14, 2);
  Insert(New(PLabel, Init(R, '~W~indows', WindowList)));

  R.Assign(Size.X - 13, 2, Size.X - 3, 4);
  StandardOkButton(R, @Self);
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~A~ctive', cmModifyItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~H~ide', cmHide, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~S~how', cmShow, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~I~con', cmNewItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~D~elete', cmDeleteItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~R~eopen', cmList, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  Insert(New(PButton, Init(R, '~F~lags', cmRunItem, bfNormal)));
  Inc(R.A.Y, 2); Inc(R.B.Y, 2);
  StandardCancelButton(R, @Self);
  SelectNext(False);
  GetCommands(SaveCommands);
end;

destructor TWinDialog.Done;
begin
  SetCommands(SaveCommands);
  TDialog.Done;
end;

procedure TWinDialog.EndModal(Command: Word);
var
  P: PView;
begin
  TDialog.EndModal(Command);
  if Command = cmOk then
  begin
    with WindowList^ do P := WinCollection^.At(Focused);
    if P <> nil then
    begin
      P^.Show;
      P^.Select;
      GetCommands(SaveCommands);
    end;
  end;
end;

procedure TWinDialog.HandleEvent(var Event: TEvent);
const
  DialogCommands: TCommandSet = [cmNext, cmPrev, cmResize, cmClose];
var
  P: Pointer;
  W: PWindow;
  R: TRect;
  Count: Integer;
  SaveExplode: Boolean;

procedure UpdateWinChanges;
begin
  GetCommands(SaveCommands);
  EnableCommands(DialogCommands);
  WindowList^.WinCollection^.FreeAll;
  WindowList^.FillList;
end;

begin
  if (Event.What = evKeyDown) and (Event.CharCode in ['1'..'9']) and
     (Message(Desktop, evBroadcast, cmSelectWindowNum,
	Pointer(Byte(Event.CharCode) - $30)) <> nil) then
  begin
    Event.What := evCommand;
    Event.Command := cmCancel;
  end;
  TDialog.HandleEvent(Event);
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbDel:
	begin
	  Event.What := evCommand;
	  Event.Command := cmDeleteItem;
	end;
      kbIns:
	begin
	  Event.What := evCommand;
	  Event.Command := cmList;
	end;
    end;
  if Event.What = evBroadcast then
     case Event.Command of
       cmUpdateViews: with WindowList^ do
	 begin
	   Count := WinCollection^.Count;
	   WinCollection^.FreeAll;
	   FillList;
	   if Count = 0 then FocusItem(0)
	   else FocusItem(Focused + WinCollection^.Count - Count);
	   DrawView;
	   GetCommands(SaveCommands);
	 end;
     end;
  if Event.What = evCommand then with WindowList^ do
  begin
    case Event.Command of
      cmHide:
	begin
	  P := WinCollection^.At(Focused);
	  if P <> nil then
	  begin
	    SaveExplode := DoExplode;
	    DoExplode := False;
	    PWindow(P)^.Hide;
	    DoExplode := SaveExplode;
	    UpdateWinChanges;
	  end;
	end;
      cmShow:
	begin
	  P := WinCollection^.At(Focused);
	  if P <> nil then
	  begin
	    PWindow(P)^.Show;
	    UpdateWinChanges;
	  end;
	end;
      cmNewItem:
	begin
	  P := WinCollection^.At(Focused);
	  if P <> nil then
	  begin
	    if PWindow(P)^.Flags and wfIcon <> 0 then
	      PWinIcon(P)^.Window^.Deiconize
	    else PWindow(P)^.Iconize;
	    UpdateWinChanges;
	  end;
	end;
      cmDeleteItem:
	begin
	  P := WinCollection^.At(Focused);
	  if P <> nil then
	  begin
	    Message(PWindow(P), evCommand, cmClose, nil);
	    UpdateWinChanges;
	  end;
	end;
      cmRunItem:
	begin
	  WindowList^.WindowFlags;
	  GetCommands(SaveCommands);
	end;
      cmList:
	begin
	  WindowList^.GetBounds(R);
	  Inc(R.B.X); Inc(R.B.Y);
	  W := New(PReopenWindow, Init(R, ReopenHistoryID));
	  if Application^.ValidView(W) <> nil then
	  begin
	    ExecView(W);
	    Dispose(W, Done);
	    Message(Application, evBroadcast, cmUpdateViews, nil);
	  end;
	end;
      cmModifyItem:
	begin
	  P := WinCollection^.At(Focused);
	  if P <> nil then
	  begin
	    PWindow(P)^.Select;
	    UpdateWinChanges;
	  end;
	end;
      else Exit;
    end;
    WindowList^.Select;
    WindowList^.DrawView;
    Event.What := evNothing;
  end;
end;

procedure List;
begin
  Application^.ExecuteDialog(New(PWinDialog, Init), nil, True);
  Application^.SetState(sfFocused, True);
end;

end.
