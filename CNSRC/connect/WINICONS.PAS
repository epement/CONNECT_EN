{$F+,O+,X+}
unit WinIcons;

interface

uses Objects, Drivers, Views;

type
  PWinIcon = ^TWinIcon;
  TWinIcon = object(TWindow)
    Window: PWindow;
    constructor Init(AWindow: PWindow);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Draw; virtual;
    function GetTitle(MaxSize: Integer): TTitleStr; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetState(AState: Word; Enable: Boolean); virtual;
    procedure SizeLimits(var Min, Max: TPoint); virtual;
    procedure Store(var S: TStream);
    function Valid(Command: Word): Boolean; virtual;
    function GetMouseShape(var Event: TEvent): Char; virtual;
    procedure Update;
  end;

const
  WinIconHelpCtx: Word = 0;

implementation

uses App;

constructor TWinIcon.Init(AWindow: PWindow);
var
  SaveOptions: Word;
  R: TRect;
begin
  if AWindow^.Flags and wfMini = 0 then R.Assign(
    AWindow^.Origin.X + AWindow^.Size.X - 2, AWindow^.Origin.Y,
    AWindow^.Origin.X + AWindow^.Size.X, AWindow^.Origin.Y + 1)
  else R.Copy(AWindow^.IconRect);
  TView.Init(R);
  Options := Options or (ofFirstClick + ofSelectable + ofTopSelect);
  HelpCtx := WinIconHelpCtx;
  EventMask := $FFFF;
  Flags := wfMove + wfClose + wfZoom + wfIcon;
  Window := AWindow;
  Number := Window^.Number;
  SaveOptions := Window^.Options;
  Window^.Options := Window^.Options and not ofSelectable;
  Desktop^.Delete(Window);
  Window^.Options := SaveOptions;
  Application^.InsertWindow(@Self);
  Window^.Icon := @Self;
end;

constructor TWinIcon.Load(var S: TStream);
begin
  TView.Load(S);
  Flags := wfMove + wfClose + wfZoom + wfIcon;
  Window := PWindow(S.Get);
  if Window <> nil then
  begin
    Number := Window^.Number;
    Window^.Icon := @Self;
  end;
end;

destructor TWinIcon.Done;
begin
  if Window <> nil then
    if Application^.EndState <> cmQuit then
    begin
      GetBounds(Window^.IconRect);
      Options := Options and not ofSelectable;
      Desktop^.Delete(@Self);
      Window^.Icon := nil;
      Window^.Show;
      Application^.InsertWindow(Window);
    end
    else Dispose(Window, Done);
  TView.Done;
end;

procedure TWinIcon.Draw;
var
  C: Byte;
  B: TDrawBuffer;
begin
  if Window = nil then C := $1F
  else
  begin
    if State and sfDragging <> 0 then C := 3
    else if State and sfSelected <> 0 then C := 2
    else C := 1;
    Window^.Owner := Owner;
    C := Window^.GetColor(C);
    Window^.Owner := nil;
  end;
  MoveStr(B, GetTitle(Size.X - 2), C);
  WriteLine(0, 0, Size.X, 1, B);
end;

function TWinIcon.GetTitle(MaxSize: Integer): TTitleStr;
var
  S: TTitleStr;
begin
  if Window = nil then S := ''
  else S := Window^.GetTitle(MaxSize);
  GetTitle := '[' + S + ']';
end;

procedure TWinIcon.HandleEvent(var Event: TEvent);
var
  Min, Max: TPoint;
  R, Limits: TRect;

procedure Change(DX, DY: Integer);
begin
  Inc(R.A.X, DX);
  Inc(R.B.X, DX);
  Inc(R.A.Y, DY);
  Inc(R.B.Y, DY);
end;

procedure Place(X, Y: Integer);
begin
  R.Assign(X, Y, X + R.B.X - R.A.X, Y + R.B.Y - R.A.Y);
end;

procedure KeyMove;
begin
  GetBounds(R);
  Owner^.GetExtent(Limits);
  case CtrlToArrow(Event.KeyCode) of
    kbLeft: if R.B.X > Limits.A.X + 1 then Change(-1, 0);
    kbRight: if R.A.X < Limits.B.X - 1 then Change(1, 0);
    kbUp: if R.B.Y > Limits.A.Y + 1 then Change(0, -1);
    kbDown: if R.A.Y < Limits.B.Y - 1 then Change(0, 1);
    kbCtrlLeft: if R.B.X > Limits.A.X + 8 then Change(-8, 0)
      else Place(Limits.A.X - Size.X + 1, R.A.Y);
    kbCtrlRight: if R.A.X < Limits.B.X - 8 then Change(8, 0)
      else Place(Limits.B.X - 1, R.A.Y);
    kbHome: Place(Limits.A.X, R.A.Y);
    kbEnd: Place(Limits.B.X - Size.X, R.A.Y);
    kbPgUp: Place(R.A.X, Limits.A.Y);
    kbPgDn: Place(R.A.X, Limits.B.Y - Size.Y);
    else Exit;
  end;
  Locate(R);
  Event.What := evNothing;
end;

procedure Drag;
begin
  Owner^.GetExtent(Limits);
  SizeLimits(Min, Max);
  DragView(Event, dmDragMove, Limits, Min, Max);
  Event.What := evNothing;
end;

begin
  TView.HandleEvent(Event);
  if Event.What = evKeyDown then KeyMove
  else if Event.What = evMouseDown then
    if Event.Double then
    begin
      Event.What := evNothing;
      Free;
    end
    else Drag
  else if Event.What = evCommand then
    case Event.Command of
      cmResize: Drag;
      cmOk, cmZoom:
	begin
	  Event.What := evNothing;
	  Free;
	end;
      cmClose:
	begin
	  Event.What := evNothing;
	  Message(Window, evCommand, cmClose, nil);
	  if Window = nil then Free;
	end;
    end
  else if (Event.What = evBroadcast) and (Window <> nil) then
    Window^.HandleEvent(Event);
end;

procedure TWinIcon.SetState(AState: Word; Enable: Boolean);
begin
  TWindow.SetState(AState, Enable);
  if State and sfExposed <> 0 then Update;
end;

procedure TWinIcon.SizeLimits(var Min, Max: TPoint);
begin
  TView.SizeLimits(Min, Max);
  Min.X := 2;
  Min.Y := 1;
end;

procedure TWinIcon.Store(var S: TStream);
begin
  TView.Store(S);
  S.Put(Window);
end;

function TWinIcon.Valid(Command: Word): Boolean;
begin
  Valid := (Window <> nil) and
    Inherited Valid(Command) and Window^.Valid(Command);
end;

function TWinIcon.GetMouseShape(var Event: TEvent): Char;
begin
  if (State and sfActive <> 0) and (State and sfFocused <> 0) then
    GetMouseShape := ''
  else GetMouseShape := Inherited GetMouseShape(Event);
end;

procedure TWinIcon.Update;
var
  R: TRect;
  S: TTitleStr;
begin
  GetBounds(R);
  S := GetTitle(ScreenWidth);
  if R.A.X < ScreenWidth div 2 then R.B.X := R.A.X + Length(S)
  else R.A.X := R.B.X - Length(S);
  while R.B.X - R.A.X > ScreenWidth do Dec(R.B.X);
  while R.B.X <= 0 do
  begin
    Inc(R.A.X);
    Inc(R.B.X);
  end;
  while R.A.X >= ScreenWidth do
  begin
    Dec(R.A.X);
    Dec(R.B.X);
  end;
  Locate(R);
  DrawView;
end;

end.