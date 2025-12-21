unit PrnStat;

interface

uses Dos;

const
  prnOk = $90;
  prnOutOfPaper = $38;

function PrnStatus: Byte;

implementation

function PrnStatus: Byte;
var
  r: Registers;
begin
  r.ah := 2;
  r.dx := 0;
  Intr($17, r);
  PrnStatus := r.ah;
end;

end.
