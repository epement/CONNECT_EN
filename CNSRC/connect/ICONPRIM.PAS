{$F+,O-,X+}
unit IconPrim;

interface

uses Icons;

procedure RunPrim(Icon: PIcon);

implementation

uses Compiler, Procs;

procedure RunPrim(Icon: PIcon);
begin
  with Icon^ do
  begin
    Running := True;
    InitProgram(FileName^);
    InitRTL(Params);
    Run;
    DoneRTL;
    DoneProgram;
    if ProgTerminated then State := State or sfAborted
    else State := State and not sfAborted;
    Running := False;
    if AbortProgram then PutEvent(AbortPending);
  end;
end;

end.