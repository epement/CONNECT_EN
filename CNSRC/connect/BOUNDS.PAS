{$I-,X+,O+,F+}
unit Bounds;

interface

uses Objects, Drivers, Views;

type
  PBounds = ^TBounds;
  TBounds = object(TView)
    Title: PString;
    DoDraw: Boolean;
    DragState: Byte;
    EndState: Word;
    ZoomRect: TRect;
    constructor Init(var Bounds: TRect; ATitle: TTitleStr);
    destructor Done; virtual;
    procedure ChangeBounds(var Bounds: TRect); virtual;
    procedure GetEvent(var Event: TEvent); virtual;
    function GetPalette: PPalette; virtual;
    procedure Draw; virtual;
    function Execute: Word; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Zoom; virtual;
    function GetMouseShape(var Event: TEvent): Char; virtual;
  end;

const
  CBoundsColor = #$3A;
  CBoundsBlackWhite = #$07;
  CBoundsMonochrome = #$07;
  CBounds = #159;

  drsNone = 0;
  drsKey = 1;
  drsMouse = 2;

implementation

constructor TBounds.Init(var Bounds: TRect; ATitle: TTitleStr);
begin
  TView.Init(Bounds);
  HelpCtx := hcDragging;
  Title := NewStr(ATitle);
  GetBounds(ZoomRect);
end;

destructor TBounds.Done;
begin
  DisposeStr(Title);
  TView.Done;
end;

procedure TBounds.ChangeBounds(var Bounds: TRect);
begin
  TView.ChangeBounds(Bounds);
  Owner^.Lock;
  DoDraw := True;
end;

procedure TBounds.GetEvent(var Event: TEvent);
begin
  TView.GetEvent(Event);
  if DoDraw then
  begin
    Hide;
    Show;
    Owner^.Unlock;
    DoDraw := False;
  end;
  if (DragState = drsKey) and (Event.What = evNothing) then
  begin
    Event.What := evKeyDown;
    Event.KeyCode := kbEnter;
  end;
end;

function TBounds.GetPalette: PPalette;
const
  P: String[Length(CBounds)] = CBounds;
begin
  GetPalette := @P;
end;

procedure TBounds.Draw;
var
  Color: Word;
  I: Integer;
  B: TDrawBuffer;
begin
  Color := GetColor(1);
  MoveChar(B, 'Ä', Color, Size.X);
  Char(B[0]) := 'Ú';
  Char(B[1]) := '[';
  Char(B[2]) := 'þ';
  Char(B[3]) := ']';
  I := (Size.X - Length(Title^)) div 2 - 1;
  if I < 5 then I := 5;
  MoveStr(B[I], ' ' + Title^ + ' ', Color);
  if Length(Title^) + 12 > Size.X then Char(B[Size.X - 6]) := ' ';
  Char(B[Size.X - 4]) := '[';
  if Longint(Size) = Longint(Owner^.Size) then Char(B[Size.X - 3]) := ''
  else Char(B[Size.X - 3]) := '';
  Char(B[Size.X - 2]) := ']';
  Char(B[Size.X - 1]) := '¿';
  WriteLine(0, 0, Size.X, 1, B);

  for I := 1 to Size.Y - 2 do
  begin
    Char(B[0]) := '³';
    WriteLine(0, I, 1, 1, B);
  end;

  for I := 1 to Size.Y - 2 do
  begin
    Char(B[Size.X - 1]) := '³';
    WriteLine(Size.X - 1, I, 1, 1, B);
  end;

  MoveChar(B, 'Ä', Color, Size.X);
  Char(B[0]) := 'À';
  Char(B[Size.X - 1]) := 'Ù';
  WriteLine(0, Size.Y - 1, Size.X, 1, B);
end;

function TBounds.Execute: Word;
var
  E: TEvent;
begin
  EndState := 0;
  repeat
    GetEvent(E);
    HandleEvent(E);
  until EndState <> 0;
  Execute := EndState;
end;

procedure TBounds.HandleEvent(var Event: TEvent);
var
  Mouse: TPoint;
  Limits: TRect;

procedure GrowView(AMode: Byte);
begin
  DragState := drsMouse;
  DragView(Event, AMode, Limits, MinWinSize, Owner^.Size);
  DragState := drsNone;
  Event.What := evNothing;
end;

begin
  TView.HandleEvent(Event);
  if Event.What = evNothing then Exit;
  Owner^.GetExtent(Limits);
  if Event.What = evKeyDown then
    case Event.KeyCode of
      kbEnter:
	begin
	  Event.What := evCommand;
	  Event.Command := cmOk;
	end;
      kbEsc:
	begin
	  Event.What := evCommand;
	  Event.Command := cmCancel;
	end;
      else
      begin
	DragState := drsKey;
	PutEvent(Event);
	DragView(Event, dmDragMove + dmDragGrow + dmLimitLoY,
	  Limits, MinWinSize, Owner^.Size);
	DragState := drsNone;
	Event.What := evNothing;
      end;
    end;
  if (Event.What = evMouseDown) and MouseInView(Event.Where) then
  begin
    MakeLocal(Event.Where, Mouse);
    if Mouse.Y = 0 then
    begin
      if (Mouse.X >= 1) and (Mouse.X <= 4) then
      begin
	Event.What := evCommand;
	Event.Command := cmClose;
      end
      else if Event.Double or
	((Mouse.X >= Size.X - 5) and (Mouse.X <= Size.X - 3)) then
      begin
	Event.What := evCommand;
	Event.Command := cmZoom;
      end
      else if Mouse.X <= 1 then
      begin
	if Mouse.X = 1 then Dec(Event.Where.X);
	GrowView(dmDragGrow + dmLimitLoX);
      end
      else if Mouse.X >= Size.X - 2 then
      begin
	if Mouse.X = Size.X - 2 then Inc(Event.Where.X);
	GrowView(dmDragGrow + dmLimitHiX);
      end
      else GrowView(dmDragMove + dmLimitLoY);
    end
    else if Mouse.Y >= Size.Y - 1 then
    begin
      if Mouse.X <= 1 then
      begin
	if Mouse.X = 1 then Dec(Event.Where.X);
	GrowView(dmDragGrow + dmLimitHiY);
      end
      else if Mouse.X >= Size.X - 2 then GrowView(0)
      else GrowView(dmDragMove + dmLimitLoY);
    end
    else if (Mouse.X = 0) or (Mouse.X = Size.X - 1) then
      GrowView(dmDragMove + dmLimitLoY)
    else if Event.Double then
    begin
      Event.What := evCommand;
      Event.Command := cmOk;
    end;
  end;
  if Event.What = evCommand then
  begin
    case Event.Command of
      cmCancel, cmClose, cmOk: EndState := Event.Command;
      cmZoom: Zoom;
      else Exit;
    end;
    Event.What := evNothing;
  end;
end;

procedure TBounds.Zoom;
var
  R: TRect;
begin
  if Longint(Size) <> Longint(Owner^.Size) then
  begin
    GetBounds(ZoomRect);
    Owner^.GetExtent(R);
    Locate(R);
  end else Locate(ZoomRect);
end;

function TBounds.GetMouseShape(var Event: TEvent): Char;
var
  C: Char;
  P: TPoint;
begin
  C := Inherited GetMouseShape(Event);
  MakeLocal(Event.Where, P);
  if (P.X > 0) and (P.X < Size.X - 1) and
     (P.Y > 0) and (P.Y < Size.Y - 1) then
  else if P.Y = 0 then
    if ((P.X >= 1) and (P.X <= 3)) or
       ((P.X >= Size.X - 4) and (P.X <= Size.X - 2)) then
    else if (P.X = 0) or (P.X = Size.X - 1) then C := ''
    else C := ''
  else if P.Y = Size.Y - 1 then
    if (P.X = 0) or (P.X = Size.X - 1) then C := ''
    else C := ''
  else C := '';
  GetMouseShape := C;
end;

end.