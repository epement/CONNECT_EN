{$F+,O-,X+}
unit HideMain;

interface

procedure UpdateMainViews;

implementation

uses Objects, App, Gauges, Defaults;

procedure UpdateMainViews;
var
  R: TRect;
begin
  if HideOptions and hvMenuBar <> 0 then MenuBar^.Hide
  else MenuBar^.Show;
  if HideOptions and hvStatusLine <> 0 then StatusLine^.Hide
  else StatusLine^.Show;
  if HideOptions and hvClock <> 0 then Clock^.Hide
  else Clock^.Show;
  if HideOptions and hvHeap <> 0 then Heap^.Hide
  else Heap^.Show;
  Application^.GetExtent(R);
  if HideOptions and hvMenuBar = 0 then Inc(R.A.Y);
  if HideOptions and hvStatusLine = 0 then Dec(R.B.Y);
  Desktop^.Locate(R);
end;

end.