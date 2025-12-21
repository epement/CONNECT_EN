{$I-,F+,O+,X+}
unit TilePrim;

interface

uses Objects;

procedure CascadeViews(var R: TRect);
procedure TileViews(var R: TRect);
procedure StandardTileError;

implementation

uses Views, App, MsgBox;

function Tileable(P: PView): Boolean;
begin
  Tileable := (P^.Options and ofTileable <> 0) and
    (P^.State and sfVisible <> 0);
end;

procedure CascadeViews(var R: TRect);
var
  CascadeNum, NumViews: Integer;
  LastView: PView;
  Min, Max: TPoint;

procedure DoCount(P: PView); far;
begin
  if Tileable(P) then
  begin
    Inc(CascadeNum);
    LastView := P;
  end;
end;

procedure DoCascade(P: PView); far;
var
  NR: TRect;
begin
  if Tileable(P) and (CascadeNum >= 0) then
  begin
    NR.Copy(R);
    Inc(NR.A.X, CascadeNum); Inc(NR.A.Y, CascadeNum);
    Dec(NR.B.Y, NumViews - (CascadeNum + 1));
    P^.Locate(NR);
    Dec(CascadeNum);
  end;
end;

begin
  with Desktop^ do
  begin
    CascadeNum := 0;
    ForEach(@DoCount);
    if CascadeNum > 0 then
    begin
      NumViews := CascadeNum;
      LastView^.SizeLimits(Min, Max);
      if (Min.X > R.B.X - R.A.X - CascadeNum) or
	 (Min.Y > R.B.Y - R.A.Y - CascadeNum) then TileError
      else
      begin
	Dec(CascadeNum);
	Lock;
	ForEach(@DoCascade);
	Unlock;
      end;
    end;
  end;
end;

function ISqr(X: Integer): Integer; assembler;
asm
	MOV	CX,X
	MOV	BX,0
@@1:    INC     BX
	MOV	AX,BX
	IMUL	AX
	CMP	AX,CX
	JLE	@@1
	MOV	AX,BX
	DEC     AX
end;

procedure MostEqualDivisors(N: Integer; var X, Y: Integer; FavorY: Boolean);
var
  I: Integer;
begin
  I := ISqr(N);
  if ((N mod I) <> 0) then
    if (N mod (I+1)) = 0 then Inc(I);
  if I < (N div I) then I := N div I;
  if FavorY then
  begin
    X := N div I;
    Y := I;
  end
  else
  begin
    Y := N div I;
    X := I;
  end;
end;

procedure TileViews(var R: TRect);
var
  NumCols, NumRows, NumTileable, LeftOver, TileNum: Integer;

procedure DoCountTileable(P: PView); far;
begin
  if Tileable(P) then Inc(NumTileable);
end;

function DividerLoc(Lo, Hi, Num, Pos: Integer): Integer;
begin
  DividerLoc := LongDiv(LongMul(Hi - Lo, Pos), Num) + Lo;
end;

procedure CalcTileRect(Pos: Integer; var NR: TRect);
var
  X,Y,D: Integer;
begin
  D := (NumCols - LeftOver) * NumRows;
  if Pos < D then
  begin
    X := Pos div NumRows;
    Y := Pos mod NumRows;
  end else
  begin
    X := (Pos - D) div (NumRows + 1) + (NumCols - LeftOver);
    Y := (Pos - D) mod (NumRows + 1);
  end;
  NR.A.X := DividerLoc(R.A.X, R.B.X, NumCols, X);
  NR.B.X := DividerLoc(R.A.X, R.B.X, NumCols, X+1);
  if Pos >= D then
  begin
    NR.A.Y := DividerLoc(R.A.Y, R.B.Y, NumRows+1, Y);
    NR.B.Y := DividerLoc(R.A.Y, R.B.Y, NumRows+1, Y+1);
  end else
  begin
    NR.A.Y := DividerLoc(R.A.Y, R.B.Y, NumRows, Y);
    NR.B.Y := DividerLoc(R.A.Y, R.B.Y, NumRows, Y+1);
  end;
end;

procedure DoTile(P: PView); far;
var
  R: TRect;
begin
  if Tileable(P) then
  begin
    CalcTileRect(TileNum, R);
    P^.Locate(R);
    Dec(TileNum);
  end;
end;

begin
  with Desktop^ do
  begin
    NumTileable := 0;
    ForEach(@DoCountTileable);
    if NumTileable > 0 then
    begin
      MostEqualDivisors(NumTileable, NumCols, NumRows,
	R.B.X - R.A.X < (R.B.Y - R.A.Y) * 2.46);
      if ((R.B.X - R.A.X) div NumCols = 0) or
	 ((R.B.Y - R.A.Y) div NumRows = 0) then TileError
      else
      begin
	LeftOver := NumTileable mod NumCols;
	TileNum := NumTileable-1;
	Lock;
	ForEach(@DoTile);
	Unlock;
      end;
    end;
  end;
end;

procedure StandardTileError;
begin
  MessageBox(^C'Tile/Cascade area too small to complete request.',
    nil, mfError + mfOkButton);
end;

end.