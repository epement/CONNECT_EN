{$F-,O-,X+}
unit TpMemChk;

interface

function GetMemCheck(var P; Bytes: Word): Boolean;
procedure FreeMemCheck(var P; Bytes: Word);

implementation

uses Memory;

function GetMemCheck(var P; Bytes: Word): Boolean;
begin
  Pointer(P) := MemAlloc(Bytes);
  GetMemCheck := Pointer(P) <> nil;
end;

procedure FreeMemCheck(var P; Bytes : Word);
begin
  if Pointer(P) <> nil then
  begin
    FreeMem(Pointer(P), Bytes);
    Pointer(P) := nil;
  end;
end;

end.
