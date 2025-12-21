{$I-,F+,O+,X+}
unit HelpPrim;

interface

uses Objects;

const
  MaxHelps = 10;

type
  TPrevHelpRec = record
    PrevName: PString;
    PrevIndex: Word;
    PrevDelta: TPoint;
    PrevCursor: TPoint;
    PrevSize: TPoint;
    PrevOrg: TPoint;
  end;

  TPrevHelpArray = Array[0..MaxHelps - 1] of TPrevHelpRec;

const
  PrevHelpUsed: Boolean = False;
  PrevHelpIndex: Byte = 0;

var
  PrevHelps: TPrevHelpArray;

procedure LoadPrevHelpArray(var S: TStream);
procedure StorePrevHelpArray(var S: TStream);

implementation

uses HeapUMB;

procedure LoadPrevHelpArray(var S: TStream);
var
  I: Integer;
begin
  for I := 0 to MaxHelps - 1 do
  begin
{    PrevHelps[I].PrevName := S.ReadStr;}
    PrevHelps[I].PrevName := ReadStrUMB(@S);
    S.Read(PrevHelps[I].PrevIndex,
      SizeOf(TPrevHelpRec) - SizeOf(PString));
  end;
  S.Read(PrevHelpIndex, SizeOf(Byte));
end;

procedure StorePrevHelpArray(var S: TStream);
var
  I: Integer;
begin
  for I := 0 to MaxHelps - 1 do
  begin
    S.WriteStr(PrevHelps[I].PrevName);
    S.Write(PrevHelps[I].PrevIndex,
      SizeOf(TPrevHelpRec) - SizeOf(PString));
  end;
  S.Write(PrevHelpIndex, SizeOf(Byte));
end;

end.