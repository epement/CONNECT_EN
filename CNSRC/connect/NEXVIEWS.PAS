{$F+,O+,X+}
unit NexViews;

interface

uses Views;

procedure GetNextView(Owner: PGroup; Key: Word; var NV: PView);

implementation

uses Objects, Drivers;

procedure GetNextView(Owner: PGroup; Key: Word; var NV: PView);
var
  Q: Real;

function Closer(Point1, Point2, OrgPoint: TPoint): Boolean;
begin
  Closer :=
    Sqr(OrgPoint.X - Point1.X) + Sqr((OrgPoint.Y - Point1.Y) * Q) <
    Sqr(OrgPoint.X - Point2.X) + Sqr((OrgPoint.Y - Point2.Y) * Q);
end;

procedure GetNearest(P: PView); far;
begin
  if (P^.Options and ofSelectable <> 0) and
     (P^.State and (sfDisabled + sfSelected) = 0) and
     P^.Exposed then with Owner^ do
  case Key of
    kbAltRight:
      if NV = nil then
	if P^.Origin.X > Current^.Origin.X then NV := P
	else
      else if (P^.Origin.X > Current^.Origin.X) and
	Closer(P^.Origin, NV^.Origin, Current^.Origin) then
	  NV := P;
    kbAltLeft:
      if NV = nil then
	if P^.Origin.X < Current^.Origin.X then NV := P
	else
      else if (P^.Origin.X < Current^.Origin.X) and
	Closer(P^.Origin, NV^.Origin, Current^.Origin) then
	  NV := P;
    kbAltUp:
      if NV = nil then
	if P^.Origin.Y < Current^.Origin.Y then NV := P
	else
      else if (P^.Origin.Y < Current^.Origin.Y) and
	Closer(P^.Origin, NV^.Origin, Current^.Origin) then
	  NV := P;
    kbAltDn:
      if NV = nil then
	if P^.Origin.Y > Current^.Origin.Y then NV := P
	else
      else if (P^.Origin.Y > Current^.Origin.Y) and
	Closer(P^.Origin, NV^.Origin, Current^.Origin) then
	  NV := P;
  end;
end;

begin
  NV := nil;
  if Owner^.Current = nil then Exit;
  Q := 2.46;
  Owner^.ForEach(@GetNearest);
end;

end.