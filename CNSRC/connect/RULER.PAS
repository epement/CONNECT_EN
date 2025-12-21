{$F+,O+,X+}
unit Ruler;

interface

uses Objects, Drivers, Views;

type
  PRuler = ^TRuler;
  TRuler = object(TView)
    Direction: Byte;
    procedure Draw; virtual;
  end;

const
  CRulerNormal  = 205;
  CRulerColored = 206;
  CRulerColor   = #$30#$3E;
  CRulerBW      = #$70#$7F;
  CRulerMono    = #$70#$7F;

  rdHorizontal  = 0;
  rdVertical    = 1;

procedure DragRuler(var Event: TEvent);

implementation

uses App;

procedure TRuler.Draw;
var
  C, I, M, N: Byte;
  S: String[3];
  B: TDrawBuffer;
begin
  N := Byte(Application^.GetPalette^[CRulerNormal]);
  C := Byte(Application^.GetPalette^[CRulerColored]);
  if Direction = rdHorizontal then M := Size.X else M := Size.Y;
  for I := 1 to M do
  begin
    Str(I:3, S);
    if S[3] = '0' then MoveChar(B[I - 1], S[2], C, 1)
    else MoveChar(B[I - 1], S[3], N, 1);
  end;
  if Direction = rdHorizontal then WriteLine(0, 0, Size.X, 1, B)
  else WriteBuf(0, 0, 1, Size.Y, B);
end;

procedure DragRuler(var Event: TEvent);
var
  R: TRect;
  H, V: TRuler;

procedure SetRect(Direction: Byte);
begin
  R.A.X := Event.Where.X;
  R.A.Y := Event.Where.Y;
  if Direction = rdHorizontal then
  begin
    R.B.X := R.A.X + Application^.Size.X;
    R.B.Y := R.A.Y + 1;
  end
  else
  begin
    R.B.X := R.A.X + 1;
    R.B.Y := R.A.Y + Application^.Size.Y;
  end;
end;

begin
  SetMouseShape(#0);
  SetRect(rdHorizontal);
  H.Init(R);
  Application^.Insert(@H);
  SetRect(rdVertical);
  V.Init(R);
  V.Direction := rdVertical;
  Application^.Insert(@V);
  repeat
    SetRect(rdHorizontal);
    H.Locate(R);
    SetRect(rdVertical);
    V.Locate(R);
  until not Application^.MouseEvent(Event, evMouseMove);
  H.Done;
  V.Done;
  UpdateMouseShape := True;
end;

end.