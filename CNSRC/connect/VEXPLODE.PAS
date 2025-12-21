{$F+,O+,X+}
unit VExplode;

interface

uses Objects, Views;

type
  PExploder = ^TExploder;
  TExploder = object(TView)
    Color: Byte;
    constructor Init(var Bounds: TRect; AColor: Byte);
    procedure Draw; virtual;
  end;

procedure Implode(P: PView);
procedure Explode(Owner: PGroup; P, Target: PView);

implementation

uses CNCrt, Drivers;

constructor TExploder.Init(var Bounds: TRect; AColor: Byte);
begin
  TView.Init(Bounds);
  Color := AColor;
end;

procedure TExploder.Draw;
var
  B: TDrawBuffer;
begin
  MoveChar(B, 'Ä', Color, Size.X);
  Char(B[0]) := 'Ú';
  Char(B[Size.X - 1]) := '¿';
  WriteLine(0, 0, Size.X, 1, B);

  MoveChar(B, ' ', Color, Size.X);
  Char(B[0]) := '³';
  Char(B[Size.X - 1]) := '³';
  WriteLine(0, 1, Size.X, Size.Y - 2, B);

  MoveChar(B, 'Ä', Color, Size.X);
  Char(B[0]) := 'À';
  Char(B[Size.X - 1]) := 'Ù';
  WriteLine(0, Size.Y - 1, Size.X, 1, B);
end;

procedure Implode(P: PView);
var
  Bounds, R: TRect;
  E: PExploder;
  Ratio: Real;
  Count, I: Integer;
  SaveOptions: Word;
begin
  with P^ do
  begin
    if Owner = nil then Exit;
    SaveOptions := Options;
    Options := Options and not ofSelectable;
    GetBounds(Bounds);
    R.A.X := (Bounds.A.X + Bounds.B.X) div 2 - 1;
    R.A.Y := (Bounds.A.Y + Bounds.B.Y) div 2 - 1;
    R.B.X := R.A.X + 2;
    R.B.Y := R.A.Y + 2;
    E := New(PExploder, Init(Bounds, GetColor(1)));
    Owner^.Insert(E);
    SetState(sfVisible, False);
    Ratio := Size.X / Size.Y;
    Count := Size.X div 2 + Size.Y div 2;
    for I := 1 to Count do
    begin
      if E^.Size.X / E^.Size.Y > Ratio then
      begin
	if Bounds.A.X < R.A.X then Inc(Bounds.A.X);
	if Bounds.B.X > R.B.X then Dec(Bounds.B.X);
      end
      else
      begin
	if Bounds.A.Y < R.A.Y then Inc(Bounds.A.Y);
	if Bounds.B.Y > R.B.Y then Dec(Bounds.B.Y);
      end;
      E^.Locate(Bounds);
      if ExplodeDelay <> 0 then Delay(
	((ScreenWidth div 2 + ScreenHeight div 2) div Count) * ExplodeDelay);
    end;
    E^.Locate(R);
    if ExplodeDelay <> 0 then Delay(
      ((ScreenWidth div 2 + ScreenHeight div 2) div Count) * ExplodeDelay);
    Owner^.Delete(E);
    Dispose(E, Done);
    Options := SaveOptions;
  end;
end;

procedure Explode(Owner: PGroup; P, Target: PView);
var
  Bounds, R: TRect;
  E: PExploder;
  Ratio: Real;
  Count, I: Integer;
begin
  P^.GetBounds(Bounds);
  R.A.X := (Bounds.A.X + Bounds.B.X) div 2 - 1;
  R.A.Y := (Bounds.A.Y + Bounds.B.Y) div 2 - 1;
  R.B.X := R.A.X + 2;
  R.B.Y := R.A.Y + 2;
  E := New(PExploder, Init(R, P^.GetColor(1)));
  Owner^.Insert(E);
  if ExplodeDelay <> 0 then Delay(ExplodeDelay);
  Ratio := P^.Size.X / P^.Size.Y;
  Count := P^.Size.X div 2 + P^.Size.Y div 2;
  for I := 1 to Count do
  begin
    if E^.Size.X / E^.Size.Y < Ratio then
    begin
      if R.A.X > Bounds.A.X then Dec(R.A.X);
      if R.B.X < Bounds.B.X then Inc(R.B.X);
    end
    else
    begin
      if R.A.Y > Bounds.A.Y then Dec(R.A.Y);
      if R.B.Y < Bounds.B.Y then Inc(R.B.Y);
    end;
    E^.Locate(R);
    if ExplodeDelay <> 0 then Delay(
      ((ScreenWidth div 2 + ScreenHeight div 2) div Count) * ExplodeDelay);
  end;
  E^.Locate(Bounds);
  P^.Show;
  Owner^.Delete(E);
  Dispose(E, Done);
end;

end.