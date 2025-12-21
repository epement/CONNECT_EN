{$I-,F+,O+,X+}
unit SpellChk;

interface

uses Objects;

procedure InitCRCStream(const AName: FNameStr; var Stream: PStream);
function CRCSearch(S: PStream; CRC: Longint; var Pos: Longint): Boolean;
procedure CRCAdd(S: PStream; APos: Longint; CRC: Longint);
procedure CRCDelete(S: PStream; APos: Longint);

implementation

uses DirPrim, DataBase;

procedure InitCRCStream(const AName: FNameStr; var Stream: PStream);
var
  Mode: Word;
  S, C: String[40];
begin
  if ThisFileExists(AName) then Mode := stOpen
  else Mode := stCreate;
  Stream := New(PDosStream, Init(AName, Mode));
  S := 'CONNECT Spell Checker CRC32 Dictionary'#26#0;
  if Mode = stCreate then Stream^.Write(S[1], 40)
  else
  begin
    C[0] := #40;
    Stream^.Read(C[1], 40);
    if C <> S then Stream^.Status := stError;
  end;
end;

function CRCSearch(S: PStream; CRC: Longint; var Pos: Longint): Boolean;
var
  L, H, I, J, C: Longint;
begin
  CRCSearch := False;
  L := 10;
  H := S^.GetSize div SizeOf(Longint) - 1;
  while L <= H do
  begin
    I := (L + H) shr 1;
    S^.Seek(I * SizeOf(Longint));
    S^.Read(C, SizeOf(Longint));
    if C = CRC then
    begin
      L := I;
      CRCSearch := True;
      Break;
    end
    else if (LongRec(C).Hi < LongRec(CRC).Hi) or
      ((LongRec(C).Hi = LongRec(CRC).Hi) and
       (LongRec(C).Lo < LongRec(CRC).Lo)) then L := I + 1
    else H := I - 1;
  end;
  Pos := L * SizeOf(Longint);
end;

procedure CRCAdd(S: PStream; APos: Longint; CRC: Longint);
begin
  InsertBlock(S, APos, SizeOf(Longint), CRC);
end;

procedure CRCDelete(S: PStream; APos: Longint);
begin
  DeleteBlock(S, APos, SizeOf(Longint));
end;

end.