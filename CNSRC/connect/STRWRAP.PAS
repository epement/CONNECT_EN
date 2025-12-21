{$F+,O+,X+}
unit StrWrap;

interface

procedure WrapStr(var S: String; const Chars; Len: Byte);
{
 S     -  Разбиваемая строка.
 Chars -  Множество, содержащее разделители слов
 Len   -  Длина строки после разбиения.
 Так строка
 'Окно File Manager представляет собой файловый процессор, аналогичный'
 при Len = 30 вернется в виде
 'Окно File Manager представля- ет собой файловый процессор, аналогичный'
}

implementation

var
  WordC: Array[0..$FF] of Char;
  Wh: Array[0..$FF] of Integer;

{$L NSTRNCMP.OBJ}
procedure _strncmp; external;
{$L NSTRLEN.OBJ}
procedure _strlen; external;
{$L FSTRNCMP.OBJ}
procedure _f_strncmp; external;
{$L FSTRLEN.OBJ}
procedure _f_strlen; external;

{$L NSTRCPY.OBJ}
procedure _strcpy; external;
{$L NSTRNCPY.OBJ}
procedure _strncpy; external;
{$L WRAP.OBJ}
procedure Wrap; near; external;

{$L Strgs.obj}
procedure PQpr; far; external;

function DataAddress(P : Pointer) : Pointer;
type
  SO = record
    O, S : Word;
  end;
  JumpInstr = record
    Opcode : Byte;
    Address : Pointer;
  end;
begin
  if SO(P).S <> CSeg then DataAddress := JumpInstr(P^).Address
  else DataAddress := P;
end;

function Qpr : Pointer; near;
begin
 Qpr := DataAddress(@PQpr);
end;

procedure WrapStr(var S: String; const Chars; Len: Byte);
type
  CSet = Set of Char;
const
  Latins = ['A'..'Z', 'a'..'z'];
  Vowels = ['A', 'E', 'I', 'O', 'U', 'Y', 'a', 'e', 'i', 'o', 'u', 'y'];
var
  I, L, M, N: Byte;

function ValidDiv: Boolean;
var
  K: Byte;
begin
  ValidDiv := True;
  for K := I + 1 to L - 1 do
    if WordC[K] in Vowels then Exit;
  ValidDiv := False;
end;

begin
  if (Length(S) < 4) or (Len < 2) then Exit;
  if (Length(S) > Len) and (S[Len + 1] = ' ') then Exit;
  L := Len;
  while (L > 0) and not (S[L] in CSet(Chars)) do Dec(L);
  if L >= Len - 2 then Exit;
  Inc(L);
  N := L;
  M := Length(S);
  I := 0;
  while (L <= M) and not (S[L] in CSet(Chars)) do
  begin
    WordC[I] := S[L];
    Inc(L);
    Inc(I);
  end;
  if I < 4 then Exit;
  WordC[I] := #0;
  Wrap;
  L := I;
  I := Len - N;
  while (I > 0) and (Wh[I] <> 1) do Dec(I);
  if I > 0 then Insert('- ', S, N + I)
  else
  begin
    M := 0;
    I := 0;
    repeat
      if WordC[I] = #0 then Break;
      if WordC[I] in Latins then
      begin
        if (I > 1) and (I < L - 1) and (M > 0) then Wh[I] := 1;
        if WordC[I] in Vowels then Inc(M);
      end;
      Inc(I);
    until False;
    I := Len - N;
    while (I > 0) and ((Wh[I] <> 1) or not ValidDiv) do Dec(I);
    if I > 0 then Insert('- ', S, N + I);
  end;
end;

end.
