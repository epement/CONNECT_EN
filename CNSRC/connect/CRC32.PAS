{$F+,O+,X+}
unit CRC32;

interface

procedure IncCRC(const Buff; Count: Word; var CRC: Longint);
procedure IncCRCUC(const Buff; Count: Word; var CRC: Longint);
function GetStringCRC32(const S: String): Longint;
function GetStringCRC32UC(const S: String): Longint;

implementation

uses APMisc, TPString;

{$L CCRC.OBJ}
procedure IncCRC(const Buff; Count: Word; var CRC: Longint); external;
procedure IncCRCUC(const Buff; Count: Word; var CRC: Longint); external;

function GetStringCRC32(const S: String): Longint;
var
  L: Longint;
begin
  L := -1;
  IncCRC(S, Length(S) + 1, L);
  GetStringCRC32 := L;
end;

function GetStringCRC32UC(const S: String): Longint;
var
  L: Longint;
begin
  L := -1;
  IncCRCUC(S, Length(S) + 1, L);
  GetStringCRC32UC := L;
end;

end.
