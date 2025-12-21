{$X+,F+,O+}
unit DragDrop;

interface

uses Objects, Drivers, Views, Dialogs;

type
  PDragWindow = ^TDragWindow;
  TDragWindow = object(TWindow)
    Caller: PView;
    Src: PStaticText;
    Dst: PStaticText;
    MinX: Integer;
    Cancel: Boolean;
    AppTitle: Boolean;
    constructor Init(var Bounds: TRect; ATitle: TTitleStr;
      ACaller: PView; AHelpCtx: Word; const AText: TTitleStr);
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure GetEvent(var Event: TEvent); virtual;
    function GetHelpCtx: Word; virtual;
    function GetPalette: PPalette; virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
  end;

implementation

uses App, DirPrim, TPString, Consts, Commands, Defaults;

constructor TDragWindow.Init(var Bounds: TRect; ATitle: TTitleStr;
  ACaller: PView; AHelpCtx: Word; const AText: TTitleStr);
begin
  TWindow.Init(Bounds, ATitle, wnNoNumber);
  HelpCtx := AHelpCtx;
  Flags := wfMove;
  Caller := ACaller;
  MinX := Bounds.B.X - Bounds.A.X;
  Bounds.Assign(2, 1, Size.X - 2, 2);
  Src := New(PStaticText, Init(Bounds, ^C + AText));
  Src^.GrowMode := Src^.GrowMode or gfGrowHiX;
  Insert(Src);
  if HelpCtx = hcDragAndDrop then
  begin
    Bounds.Assign(2, 2, Size.X - 2, 3);
    Dst := New(PStaticText, Init(Bounds, ''));
    Dst^.GrowMode := Dst^.GrowMode or gfGrowHiX;
    Insert(Dst);
    GetBounds(Bounds);
    ChangeBounds(Bounds);
  end;
end;

procedure TDragWindow.ChangeBounds(var Bounds: TRect);
var
  I: Integer;
  P: PString;
  S: String[127];
begin
  if HelpCtx = hcDragAndDrop then
  begin
    P := Message(Desktop, evBroadcast, cmGetDest, @Bounds.A);
    if P = nil then S := '' else S := P^;
    if S = '' then S := ^C'(delete)'
    else if S = #0 then S := 'to'
    else if (Length(S) = 3) and (S[2] = ':') then S := 'to ' + S
    else
    begin
      I := ScreenWidth - Bounds.A.X - 7;
      if I < MinX - 7 then I := MinX - 7;
      S := 'to ' + TrimmedName(ClearedSlash(S), I);
    end;
    I := Length(S) + 4;
    if I < MinX then I := MinX;
    Bounds.B.X := Bounds.A.X + I;
    inherited ChangeBounds(Bounds);
    if (Dst^.Text <> nil) and (Dst^.Text^ = S) then Exit;
    DisposeStr(Dst^.Text);
    Dst^.Text := NewStr(S);
    Dst^.DrawView;
  end
  else inherited ChangeBounds(Bounds);
end;

procedure TDragWindow.GetEvent(var Event: TEvent);
var
  R: TRect;
begin
  if not AppTitle then
  begin
    AppTitle := True;
    SetApplicationTitle('Drag-And-Drop operation (' + Title^ + ')');
  end;
  if (ddMode = ddButtonUp) and (Flags and wfClose = 0) then
  begin
    Flags := Flags or wfClose;
    repeat until not MouseEvent(Event, evMouseUp);
  end;
  TWindow.GetEvent(Event);
  if (Event.What = evKeyDown) and (Event.KeyCode = kbEsc) then
  begin
    Event.What := evMouseUp;
    Cancel := True;
  end
  else if (Event.What = evMouseDown) and (Flags and wfClose <> 0) then
    Event.What := evMouseUp;
end;

function TDragWindow.GetHelpCtx: Word;
begin
  GetHelpCtx := HelpCtx;
end;

function TDragWindow.GetPalette: PPalette;
begin
  GetPalette := Caller^.GetPalette;
end;

procedure TDragWindow.SetState(AState: Word; Enable: Boolean);
begin
  TGroup.SetState(AState, Enable);
end;

end.