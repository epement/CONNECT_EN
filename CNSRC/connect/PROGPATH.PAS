unit ProgPath;

interface

uses Dos;

var
  ProgramPath: String[67];

procedure GetProgPath;

implementation

procedure GetProgPath;
begin
  ProgramPath := FExpand(ParamStr(0));
  while (ProgramPath[0] <> #0) and
    (ProgramPath[Byte(ProgramPath[0])] <> '\') do
      Dec(ProgramPath[0]);
end;

begin
  GetProgPath;
end.