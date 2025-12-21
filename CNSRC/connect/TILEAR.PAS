{$I-,F+,O+,X+}
unit TileAr;

interface

uses Objects;

var
  TileArea: TRect;

function GetTileArea: Boolean;

implementation

uses Views, App, Bounds;

function GetTileArea: Boolean;
var
  C: Word;
  B: PBounds;
begin
  GetTileArea := False;
  B := New(PBounds, Init(TileArea, 'Tile/Cascade area'));
  if Application^.ValidView(B) <> nil then
  begin
    C := Desktop^.ExecView(B);
    if C = cmOk then B^.GetBounds(TileArea);
    Dispose(B, Done);
    GetTileArea := C = cmOk;
  end;
end;

end.