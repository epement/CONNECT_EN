{$F+,O+,X+}
unit WinPos;

interface

uses Objects, Views;

type
  PWinPosRec = ^TWinPosRec;
  TWinPosRec = record
    AX, AY, BX, BY: Single;
  end;

function ValidWinPos(const R: TWinPosRec): Boolean;
procedure GetWinPos(P: PView; var R: TWinPosRec);
procedure SetWinPos(Owner: PView; const R: TWinPosRec; var Bounds: TRect);

implementation

function ValidWinPos(const R: TWinPosRec): Boolean;
begin
  ValidWinPos :=
    (R.AX <> 0.0) or (R.AY <> 0.0) or (R.BX <> 0.0) or (R.BY <> 0.0);
end;

procedure GetWinPos(P: PView; var R: TWinPosRec);
begin
  if (P = nil) or (P^.Owner = nil) then Exit;
  R.AX := P^.Origin.X / P^.Owner^.Size.X;
  R.AY := P^.Origin.Y / P^.Owner^.Size.Y;
  R.BX := (P^.Origin.X + P^.Size.X) / P^.Owner^.Size.X;
  R.BY := (P^.Origin.Y + P^.Size.Y) / P^.Owner^.Size.Y;
end;

procedure SetWinPos(Owner: PView; const R: TWinPosRec; var Bounds: TRect);
begin
  Bounds.Assign(
    Round(Owner^.Size.X * R.AX),
    Round(Owner^.Size.Y * R.AY),
    Round(Owner^.Size.X * R.BX),
    Round(Owner^.Size.Y * R.BY));
end;

end.