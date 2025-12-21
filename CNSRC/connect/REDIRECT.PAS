unit Redirect;

interface

uses Dos, Objects;

procedure Output2File(const Name: FNameStr; StdErr: Boolean);
procedure StdOutput(StdErr: Boolean);

implementation

var
  Dest: Text;
  STDOutHandler: Word;
  STDErrHandler: Word;
  Handler: Word absolute Dest;

procedure FORCDUP(SHandler, DHandler: Word);
var
  r: Registers;
begin
  r.ah := $46;
  r.bx := SHandler;
  r.cx := DHandler;
  MsDos(r);
end;

procedure DUP(SHandler: Word; var DHandler: Word);
var
  R: Registers;
begin
  r.ah := $45;
  r.bx := SHandler;
  MsDos(r);
  DHandler := r.ax;
end;

procedure DOSClose(Handler: Word);
var
  R: Registers;
begin
  r.ah := $3E;
  r.bx := Handler;
  MSDOS(r);
end;

procedure Output2File(const Name: FNameStr; StdErr: Boolean);
begin
  Assign(Dest, Name);
  Append(Dest);
  DUP(1, STDOutHandler);
  FORCDUP(Handler, 1);
  if StdErr then
  begin
    DUP(2, STDErrHandler);
    FORCDUP(Handler, 2);
  end;
  Close(Dest);
end;

procedure StdOutput(StdErr: Boolean);
begin
  FORCDUP(STDOutHandler, 1);
  DOSClose(STDOutHandler);
  if StdErr then
  begin
    FORCDUP(STDErrHandler, 2);
    DOSClose(STDErrHandler);
  end;
end;

end.
