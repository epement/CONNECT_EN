{$F+,O+,X+,B-}
Unit StrCalc;
interface
type
 TFmt = (fAuto, fDec, fHex, fBin, fOct, fChar, fExp, fScient, fBytes);

var
 ErrorCode: Byte;
 function CalcStr(SStr: String; Fmt: TFmt): String;
 procedure CalcStrInit;
 procedure CalcStrDone;
 procedure GetSciStr(E: Extended; var S: String);
 procedure GetBytesStr(E: Extended; var S: String);
 procedure GetExpStr(R: Extended; var S: String);

implementation
uses
 GetId, RevPos, TpString, Jump, Objects, Memory;

type
 PVarItem = ^TVarItem;
 TVarItem = record
  Name : Pstring;
  Value : Extended;
 end;

 PVarColl = ^TVarColl;
 TVarColl = object(TSortedCollection)
  procedure FreeItem(Item: Pointer); virtual;
  function Compare(Key1, Key2: Pointer): Integer; virtual;
 end;

const
 OpCount = 22;
 Operators: Array [0 .. OpCount] of String[2] =
  ('E-','E+',#1,'^','/','%','*','--','-','+','&&','||','#','>>','<<','>=',
   '<=','>','<','<>','=','&','|');
 IdChars: Set Of Char = [#18,'─','$','0'..'9','_','.','A'..'Z','a'..'z'];
 TerminalChars: Set Of Char = [#18, '+','$','-','.','_',' ','0'..'9','.','A'..'Z','a'..'z'];
 Digits: Set Of Char = ['0'..'9'];
 FnCount = 17;
 Functions: Array[0..FnCount] of String[7] =
  ('ARCCOS(', 'ARCSIN(', 'ARCTG(', 'SING(', 'SIN(', 'COSG(','COS(', 'CTGG(',
   'CTG(', 'TGG(', 'TG(', 'SQRT(', 'LG(', 'LN(', 'EXP10(', 'EXP(', 'ABS(',
   'NOT(');
 ResFmt: TFmt = fDec;
 FmtSet: Set of TFmt = [fDec];
 VarColl: PVarColl = Nil;
var
 ErrorStr: String[32];
 ExitSave: Pointer;

procedure TVarColl.FreeItem(Item: Pointer);
begin
 if Item <> Nil then
  begin
   DisposeStr(PVarItem(Item)^.Name);
   FreeMem(Item, SizeOf(TVarItem));
  end;
end;

function TVarColl.Compare(Key1, Key2: Pointer): Integer;
var
 C: CompareType;
begin
 C := CompUCString(PVarItem(Key1)^.Name^, PVarItem(Key2)^.Name^);
 if C = Equal then Compare := 0
 else if C = Greater then Compare := 1
 else Compare := -1
end;

procedure Error(Code: Byte);
begin
 ErrorCode  := Code;
 case Code of
  200: ErrorStr := 'Division by zero';
  205: ErrorStr := 'Floating point overflow';
  206: ErrorStr := 'Floating point underflow';
  207: ErrorStr := 'Invalid floating point operation';
  5: ErrorStr := 'Syntax error';
  6..8: ErrorStr := 'Invalid brackets';
  10: ErrorStr := 'Invalid argument';
  13: ErrorStr := 'Line too long';
  14: ErrorStr := 'Integer overflow';
 else ErrorStr := 'Internal error';
end {case};
 LongJump;
end;

procedure CalcExitProc; far;
var
  C: Byte;
begin
  ExitProc := ExitSave;
  if ExitCode in [200, 205..207] then
  begin
    ErrorAddr := nil;
    C := ExitCode;
    ExitCode := 0;
    Error(C);
  end;
end;

const
 Alpha: Array[0..31] of char = '0123456789ABCDEFGHIJKLMNOPQRSTUV';
 Beta: Array['0'..'V'] of byte =
  (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 0, 10, 11, 12, 13, 14,
   15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31);
type
 ExtArray = Array[0..9] of byte;

procedure ShrM(var Buf; Size, Cnt: Word); assembler;
asm
        mov cx, Cnt
@@2:    mov bx, cx
        les si, Buf
        clc
        mov cx, Size
@@1:    rcr byte ptr es:[si], 1
        inc si
        loop @@1
        mov cx, bx
        loop @@2
end;

procedure ShlM(var Buf; Size, Cnt: Word); assembler;
asm
        mov cx, Cnt
@@2:    mov bx, cx
        mov cx, Size
        les si, Buf
        add si, cx
        clc
@@1:    dec si
        rcl byte ptr es:[si], 1
        loop @@1
        mov cx, bx
        loop @@2
end;

procedure Ext2Str(E: Extended; Var S: String);
var
 i: Byte;
begin
 S[0] := #17;
 S[1] := #18;
 for i := 15 downto 0 do
  begin
   S[i+2] := Alpha[ExtArray(E)[9] and $1f];
   Shrm(E, SizeOf(Extended), 5);
  end;
end;

function Str2Ext(const S: String; var E: Extended): Boolean;
var
 i: Byte;
begin
 Str2Ext := False;
 if (S[0] <> #17) or (S[1] <> #18) then Exit;
 for i := 0 to 15 do
  begin
   Shlm(E, SizeOf(Extended), 5);
   ExtArray(E)[9] := ExtArray(E)[9] or Beta[S[i+2]];
  end;
 Str2Ext := True;
end;

function Power(X, Y: Real): Real;
begin
  Power := Exp(Y * Ln(X));
end;

function Str2Oct(const S: String; var L: Longint): Boolean;
var
  B: Byte;
  Ch: Char;
  R: Real;
begin
  Str2Oct := False;
  if S[0] > #10 then Exit;
  L := 0;
  R := Length(S) - 1;
  for B := 1 to Byte(S[0]) do
  begin
    if not (S[B] in ['0'..'7']) then Exit;
    L := L + (Byte(S[B]) - $30) * Trunc(Power(8, R));
    R := R - 1;
  end;
  if (L < -2147483647) or (L > 2147483647) then Exit;
  Str2Oct := True;
end;

function Str2Bin(const S: String; var L: Longint): Boolean;
var
  B: Byte;
  Ch: Char;
  R: Real;
begin
  Str2Bin := False;
  if S[0] > #32 then Exit;
  L := 0;
  R := Length(S) - 1;
  for B := 1 to Byte(S[0]) do
  begin
    if not (S[B] in ['0'..'1']) then Exit;
    L := L + (Byte(S[B]) - $30) * Trunc(Power(2, R));
    R := R - 1;
  end;
  if (L < -2147483647) or (L > 2147483647) then Exit;
  Str2Bin := True;
end;

procedure Vall(S: String; var V:Longint; var Code: Integer);
var
 L: Longint;
begin
 System.Val(S, V, Code);
 if S[1] = '$' then
  begin
   if Code = 0 then Include(FmtSet, fHex)
   else Error(14);
  end;
 if Code <> 0 then
  begin
   if (Length(S) > 2) and (S[1] = '0') and (UpCase(S[2]) = 'X') then
   begin
    System.Delete(S, 1, 2);
    System.Insert('$',S, 1);
    System.Val(S, V, Code);
    if Code = 0 then Include(FmtSet, fHex)
    else Error(14);
   end
   else
   if (Length(S) > 2) and (S[1] = '0') and (UpCase(S[2]) = 'O') then
   begin
    System.Delete(S, 1, 2);
    if Str2Oct(S, L) then Code := 0
    else Code := 1;
    if Code = 0 then Include(FmtSet, fOct);
    V := L;
   end
   else
   if (Length(S) > 2) and (S[1] = '0') and (UpCase(S[2]) = 'B') then
   begin
    System.Delete(S, 1, 2);
    if Str2Bin(S, L) then Code := 0
    else Code := 1;
    if Code = 0 then Include(FmtSet, fBin);
    V := L;
   end
   else
   if (Length(S) > 1) and (UpCase(S[Length(S)]) = 'H') then
   begin
    Dec(S[0]);
    System.Insert('$',S, 1);
    System.Val(S, V, Code);
    if Code = 0 then Include(FmtSet, fHex)
    else Error(14);
   end
   else
   if (Length(S) > 1) and (UpCase(S[Length(S)]) = 'O') then
   begin
    Dec(S[0]);
    if Str2Oct(S, L) then Code := 0
    else Code := 1;
    if Code = 0 then Include(FmtSet, fOct);
    V := L;
   end
   else if (Length(S) > 1) and (UpCase(S[Length(S)]) = 'B') then
   begin
    Dec(S[0]);
    if Str2Bin(S, L) then Code := 0
    else Code := 1;
    if Code = 0 then Include(FmtSet, fBin);
    V := L;
   end
   else
   if (Length(S) = 4) and (S[1] = '\') then
   begin
    System.Delete(S, 1, 1);
    if Str2Oct(S, L) and (L< 256) then Code := 0
    else Code := 1;
    if Code = 0 then Include(FmtSet, fOct);
    V := L;
   end
   else
   if (Length(S) = 2) and (S[1] = '\') then
   begin
     Code := 0;
     case UpCase(S[2]) of
      'A' : L := 7;   {BEL     Звуковой сигнал}
      'B' : L := 8;   {BS      Забой}
      'F' : L := $0C; {FF      Перевод бланка}
      'N' : L := $0A; {LF      Новая строка (перевод строки)}
      'R' : L := $0D; {CR      Возврат каретки}
      'T' : L := $09; {HT      Табуляция (горизонтальная)}
      'V' : L := $0B; {VT      Вертикальная табуляция}
      'E' : L := 27;
     else Code := 1;
     end;
    if Code = 0 then Include(FmtSet, fOct);
    V := L;
   end;
  end;
end;

procedure Val(const S: String; var V: Extended; var Code: Integer);
var
 L: Longint;
 CExp: Char;
 SS: String;
 Exp: integer;
begin
 Code := 0;
 if Str2Ext(S, V) then Exit;
 System.Val(S, V, Code);
 if (Code = 0) and
    (not (fExp in FmtSet)) and
    ((Pos('E', S) <> 0) or (Pos('e', S) <> 0)) then Include(FmtSet, fExp);
 if Code <> 0 then
  begin
   Vall(S, L, Code);
   if Code = 0 then V := L
   else if (Upcase(S[Length(S)]) = 'B') and
	   (Upcase(S[Length(S) - 1]) in ['K', 'M', 'G', 'T']) then
    begin
     CExp := Upcase(S[Length(S) - 1]);
     SS := S;
     Dec(SS[0], 2);
     System.Val(SS, V, Code);
     if Code = 0 then
      begin
       case CExp of
	'K': V := V * 1024.0;
	'M': V := V * 1024.0 * 1024.0;
	'G': V := V * 1024.0 * 1024.0 * 1024.0;
	'T': V := V * 1024.0 * 1024.0 * 1024.0 * 1024.0;
       else Code := 1;
       end;
       if Code = 0 then Include(FmtSet, fBytes);
      end
     else Code := 1;
    end
   else
    begin
     CExp := S[Length(S)];
     SS := S;
     Dec(SS[0]);
     System.Val(SS, V, Code);
     if (Code = 0) and (CExp in ['T','G','M','K','k','D','d',
				  's','m','u','n','p','f', 'a']) then
      begin
       case CExp of
	'T': V := V * 1E12;
	'G': V := V * 1E9;
	'M': V := V * 1E6;
	'k': V := V * 1E3;
	'K': V := V * 1E3;
	'D': V := V * 10;
	'd': V := V * 10;
	's': V := V * 1E-2;
	'm': V := V * 1E-3;
	'u': V := V * 1E-6;
	'n': V := V * 1E-9;
	'p': V := V * 1E-12;
	'f': V := V * 1E-15;
	'a': V := V * 1E-18;
       else Code := 1;
       end;
       if Code = 0 then Include(FmtSet, fScient);
      end
     else Code := 1;
    end;
  end;
end;

procedure GetExpStr(R: Extended; var S: String);
var
  I, Code: Integer;
begin
  Str(R:18:-1, S);
  repeat
    I := Pos(' ', S);
    if I = 0 then Break;
    Delete(S, I, 1);
  until False;
  I := Pos('E', S);
  while I > 1 do
  begin
    Dec(I);
    if S[I] in ['0', '.'] then Delete(S, I, 1)
    else Break;
  end;
  I := Pos('E', S) + 1;
  if I > 1 then while I <= Length(S) do
  begin
    if S[I] in ['0', '+'] then Delete(S, I, 1)
    else if S[I] = '-' then Inc(I)
    else Break;
  end;
  if S[Length(S)] = 'E' then Dec(S[0]);
  if (S = '') or (S = '-') then S := '0';
end;

procedure GetSciStr(E: Extended; var S: String);
var
  C: Char;
  D, R: Extended;
  Code: Integer;
begin
  R := Abs(E);

  if R = 0 then
  begin
    S := '0';
    Exit;
  end;

  if R < 100.0E-18 then
  begin
    D := 1.0E18;
    C := 'a';
  end
  else if R < 100.0E-15 then
  begin
    D := 1.0E15;
    C := 'f';
  end
  else if R < 100.0E-12 then
  begin
    D := 1.0E12;
    C := 'p';
  end
  else if R < 100.0E-9 then
  begin
    D := 1.0E9;
    C := 'n';
  end
  else if R < 100.0E-6 then
  begin
    D := 1.0E6;
    C := 'u';
  end
  else if R < 100.0E-3 then
  begin
    D := 1.0E3;
    C := 'm';
  end
  else if R >= 1.0E12 then
  begin
    D := 1.0E-12;
    C := 'T';
  end
  else if R >= 1.0E9 then
  begin
    D := 1.0E-9;
    C := 'G';
  end
  else if R >= 1.0E6 then
  begin
    D := 1.0E-6;
    C := 'M';
  end
  else if R >= 1.0E3 then
  begin
    D := 1.0E-3;
    C := 'K';
  end
  else
  begin
    D := 1.0;
    C := #0;
  end;
  E := E * D;
  Str(E:0:10, S);
  if (Pos('E', S) = 0) and (Pos('.', S) <> 0) then
  begin
    while S[Length(S)] = '0' do Dec(S[0]);
    if S[Length(S)] = '.' then Dec(S[0]);
  end;
  if C <> #0 then S := S + C;
end;

procedure GetBytesStr(E: Extended; var S: String);
var
  C: Char;
  I: Integer;
  D: Extended;
begin
  if E < 1 then
  begin
    S := '0';
    Exit;
  end;

  if E < 1024.0 then
  begin
    D := 1.0;
    C := #0;
  end
  else if E < 1024.0 * 1024.0 then
  begin
    D := 1024.0;
    C := 'K';
  end
  else if E < 1024.0 * 1024.0 * 1024.0 then
  begin
    D := 1024.0 * 1024.0;
    C := 'M';
  end
  else if E < 1024.0 * 1024.0 * 1024.0 * 1024.0 then
  begin
    D := 1024.0 * 1024.0 * 1024.0;
    C := 'G';
  end
  else
  begin
    D := 1024.0 * 1024.0 * 1024.0 * 1024.0;
    C := 'T';
  end;
  E := E / D;
  Str(E:0:10, S);
  if C = #0 then
  begin
    I := Pos('.', S);
    if I <> 0 then S[0] := Char(I - 1);
  end
  else if (Pos('E', S) = 0) and (Pos('.', S) <> 0) then
  begin
    while S[Length(S)] = '0' do Dec(S[0]);
    if S[Length(S)] = '.' then Dec(S[0]);
  end;
  if C <> #0 then S := S + ' ' + C + 'B';
end;

function StrFmt(R: Extended): String;
var
 S: String;
begin
 case ResFmt of
  fDec: if (Abs(R) > 1e-5) and (Abs(R) < 1e15) then System.Str(R:0:16, S)
        else GetExpStr(R, S);
  fHex,
  fBin,
  fOct,
  fChar:if Frac(R) = 0 then
         begin
          if (R >= 0) and (R <= 255) then
           begin
             case ResFmt of
              fHex:  S := HexB(Trunc(R)) + 'h';
              fBin:  S := BinaryB(Trunc(R)) + 'b';
              fOct:  S := OctalB(Trunc(R)) + 'o';
              fChar: S := '"' + Char(Trunc(R)) + '"';
             end;
           end
          else
          if (R >= 0) and (R <= $ffff) then
           begin
             case ResFmt of
              fHex:  S := HexW(Trunc(R)) + 'h';
              fBin:  S := BinaryW(Trunc(R)) + 'b';
              fOct:  S := OctalW(Trunc(R)) + 'o';
              fChar: System.Str(R:0:0, S);
             end;
           end
          else
          if (R >= -2147483648.0) and (R <= 2147483647.0) then
           begin
             case ResFmt of
              fHex:  S := HexL(Trunc(R)) + 'h';
              fBin:  S := BinaryL(Trunc(R)) + 'b';
              fOct:  S := OctalL(Trunc(R)) + 'o';
              fChar: System.Str(R:0:0, S);
             end;
           end
          else
          if (Abs(R) > 1e-5) and (Abs(R) < 1e15) then System.Str(R:0:16, S)
          else GetExpStr(R, S);
         end
        else
          if (Abs(R) > 1e-5) and (Abs(R) < 1e15) then System.Str(R:0:16, S)
          else GetExpStr(R, S);
  fExp: GetExpStr(R, S);
  fScient: GetSciStr(R, S);
  fBytes: GetBytesStr(R, S);
 end;
 if (ResFmt in [fDec, fHex, fBin, fOct, fChar]) and (Pos('.', S) <> 0) and
    (Pos('E', S) = 0) then
  begin
   while S[Length(S)] = '0' do Dec(S[0]);
   if S[Length(S)] = '.' then Dec(S[0]);
  end;
 StrFmt := S;
end;

procedure Str2Str(var Str: String);
var
 E: Extended;
 Code: Integer;
begin
 Val(Str, E, Code);
 if Code = 0 then
  begin
   if ResFmt = fAuto then
    for ResFmt := fBytes downto fDec do
     if ResFmt in FmtSet then Break;
   Str := StrFmt(E);
  end
 else Str := 'Internal error';
end;

function PosWord(const SubStr,Str: String;
                 const TerminalChars : CharSet) : Byte;
 var
  Left, Right : Boolean;
  Ps, Ps1, SS0, S0 : Byte;
 begin
  PosWord := 0;
  Ps1 := 0;
  SS0 := Byte(SubStr[0]);
  S0 := Byte(Str[0]);
  repeat
   Ps := FIPos(SubStr,Str,Ps1);
   if Ps = 0 then Exit;
   Left := (Ps = 1) or (Str[Ps-1] in TerminalChars);
   Right := (Ps + SS0 - 1 = S0) or (Str[Ps + SS0] in TerminalChars);
   Ps1 := Ps;
  until Left and Right;
  PosWord := Ps;
 end;

function GetKeyAddress(const S : String) : Pointer;
var
 J : Integer;
 PStr : PString;
 Item : PVarItem;
begin
 if VarColl <> Nil then
  begin
   PStr := @S;
   if not VarColl^.Search(@PStr,J) then
    begin
     Item := MemAlloc(SizeOf(TVarItem));
     Item^.Name := NewStr(S);
     Item^.Value := 0;
     VarColl^.AtInsert(J, Item);
    end;
    GetKeyAddress := Addr(PVarItem(VarColl^.At(J))^.Value)
   end
 else GetKeyAddress := Nil;
end;

function ParseKey(S:String) : Extended;
var
 J : Integer;
 P: PVarItem;
 PStr : PString;
 D : Extended;
 L : Longint;
 Code : Integer;
begin
 if Str2Ext(S, D) then
  begin
   ParseKey := D;
   Exit;
  end;

 PStr := @S;
 if (VarColl <> Nil) and VarColl^.Search(@PStr,J) then
  begin
   P := VarColl^.At(J);
   ParseKey := P^.Value;
   Exit;
  end;

 Vall(S, L, Code);
 if Code = 0 then
  begin
   ParseKey := L;
   Exit;
  end;

 Val(S, D, Code);
 if Code = 0 then
  begin
   ParseKey := D;
   Exit;
  end;

 if CompUCString(S, 'PI') = Equal then
  begin
   ParseKey := Pi;
   Exit;
  end;
 Error(5);
end;

function StrI(D : Extended) : String;
var
 Code : Integer;
 SS : String;
begin
 Str(D:0:0,SS);
 StrI := SS;
end;

function StrD(D : Extended) : String;
var
 Code : Integer;
 SS : String;
begin
 Str(D:0:10,SS);
 StrD := SS;
end;

{('E-','E+','E','^','/','%','*','--','-','+','&&','||',
  '#','>>','<<','>=','<=','>','<','<>','=','&','|');}

function CallOp(Right,Left : Extended; Op : Byte) : String;
var
 R : Extended;
 B,BB : Byte;
 L, LL: Longint;
 Code : Integer;
 S : String;
begin
 case Op of
  0 : {E-} Val(StrD(Left) + 'E-' + StrI(Right), R, Code);
  1,  {E+}
  2 : {E}  Val(StrD(Left) + 'E' + StrI(Right), R, Code);
  3 : {^}  R := Exp(Right * Ln(Left));
  4 : {/}  R := Left / Right;
  5 : {%}  R := Trunc(Left / Right);
  6 : {*}  R := Left * Right;
  8 : {-}  R := Left - Right;
  7,  {--}
  9 : {+}  R := Left + Right;
  10: {&&} begin
            LL := Trunc(Left); L := Trunc(Right);
            R := LL and L;
           end;
  11: {||} begin
            LL := Trunc(Left); L := Trunc(Right);
            R := LL or L;
           end;
  12: {#}  begin
            LL := Trunc(Left); L := Trunc(Right);
            R := LL xor L;
           end;
  13: {>>} begin
            LL := Trunc(Left); B := Trunc(Right);
            R := LL shr B;
           end;
  14: {<<} begin
            LL := Trunc(Left); B := Trunc(Right);
            R := LL shl B;
           end;
  15: {>=} begin
            B := Byte(Left >= Right);
            R := B;
           end;
  16: {<=} begin
            B := Byte(Left <= Right);
            R := B;
           end;
  17:  {>} begin
            B := Byte(Left > Right);
            R := B;
           end;
  18: {<}  begin
            B := Byte(Left < Right);
            R := B;
           end;
  19: {<>} begin
            B := Byte(Left <> Right);
            R := B;
           end;
  20: {=}  begin
            B := Byte(Left = Right);
            R := B;
           end;
  21: {&}  begin
            BB := Trunc(Left); B := Trunc(Right);
            R := byte(boolean(B) and boolean(BB));
           end;
  22: {|}  begin
            BB := Trunc(Left); B := Trunc(Right);
            R := byte(boolean(B) or boolean(BB));
           end;
 end; {case}
 if Op in [0..2] then
 begin
  if Code = 0 then Include(FmtSet, fExp)
  else Error(255);
 end;
 Ext2Str(R, S);
 CallOp := S;
end;

procedure CompileStr(var SStr : String);
var
 OpIndex, Ps, Lps, Rps : Byte;
 Code : Integer;
 Result, RResult, LResult : Extended;
 LSubStr, RSubStr : String;
begin
 if SStr = '' then Exit;
 Ps := 0;
 for OpIndex := 0 to OpCount do
  repeat
   if OpIndex < 3 then Ps := PosWord(Operators[OpIndex],SStr,Digits)
   else Ps := PosWord(Operators[OpIndex],SStr,TerminalChars);
   if Ps <> 0 then
    begin
     Lps := Ps;
     LSubStr := GetLeftId(SStr, IdChars, LPs);
     if LSubStr <> '' then
      begin
       if Pos(LSubStr, SStr) = 0 then Error(5); {Syntax Error}
       LResult := ParseKey(LSubStr);
      end
     else LResult := 0;
     RPs := Ps  + Length(Operators[OpIndex]) - 1;
     if SStr[RPs+1] in ['-','+'] then
      begin
       Inc(RPs);
       RSubStr := SStr[RPs] + GetRightId(SStr, IdChars, RPs);
      end
     else RSubStr := GetRightId(SStr,IdChars,RPs);
     if RSubStr = '' then Error(5); {Syntax Error}
     if Pos(RSubStr,SStr) = 0 then Error(5); {Syntax Error}
     RResult := ParseKey(RSubStr);
     LSubStr := CallOp(RResult,LResult,OpIndex);
     Delete(SStr,LPs,RPs-LPs + 1);
     Insert(LSubStr,SStr,LPs);
     if Word(Length(SStr)) + Length(LSubStr) > 255 then Error(13);
    end;
  until Ps = 0;
  if SStr[1] <> #18 then Ext2Str(ParseKey(SStr), SStr);
end;

Procedure BrackMax(Var Str : String);
 var
  Index,OBr,Cbr : Byte;
  SubStr : String;
  begin
   OBr:=0; CBr:=0; Index:=1;
   while (CBr = 0) and (Index <= Length(Str)) do
    begin
     if Str[Index] = '(' then OBr := Index;
     if Str[Index] = ')' then CBr := Index+1;
     Inc(Index);
    end;
    if (CBr <> 0) and (OBr <> 0) and (CBr > OBr) then
       begin
         if (CBr <= Length(Str)) and (Str[Cbr] in IdChars) then Error(5);
         if (Obr > 1) and (Str[Obr-1] in IdChars) then Error(5);
         SubStr := Copy(Str,OBr,CBr-OBr);
         Delete(SubStr,1,1);
         Dec(SubStr[0]);
         CompileStr(SubStr);
         Delete(Str,OBr,CBr-OBr);
         if Word(Length(Str)) + Length(SubStr) > 255 then Error(13);
         Insert(SubStr,Str,Obr);
         BrackMax(Str);
       end
    else if (CBr = 0) and (OBr = 0) then CompileStr(Str)
         else if CBr < OBr then Error(6)  {() Error}
              else if CBr <> 0 then Error(7) {() Error}
                   else Error(8); {() Error}
  end;

 {('ARCCOS(', 'ARCSIN(', 'ARCTG(', 'SING(', 'SIN(', 'COSG(','COS(', 'CTGG(',
 'CTG(', 'TGG(', 'TG(',  'SQRT(',   'LG(',    'LN(',  'EXP10(', 'EXP(',
 'ABS(' );}
 procedure CallFn(FnIdx : Byte; var Arg : String);
 var
  R, FR : Extended;
  Code : Integer;
 begin
  Val(Arg, R, Code);
  if Code <> 0 then Error(10);{ Неверный аргумент функции}
  case FnIdx of
   0: {ARCCOS}    FR := ArcTan(Sqrt(1-Sqr(R))/R);
   1: {ARCSIN}    FR := ArcTan(R/Sqrt(1-Sqr(R)));
   2: {ARCTG}     FR := ArcTan(R);
   3: {SING}      FR := Sin(Pi*R/180);
   4: {SIN}       FR := Sin(R);
   5: {COSG}      FR := Cos(Pi*R/180);
   6: {COS}       FR := Cos(R);
   7: {CTGG}      FR := Cos(Pi*R/180)/Sin(Pi*R/180);
   8: {CTG}       FR := Cos(R)/Sin(R);
   9: {TGG}       FR := Sin(Pi*R/180)/Cos(Pi*R/180);
   10:{TG}        FR := Sin(R)/Cos(R);
   11:{SQRT}      FR := Sqrt(R);
   12:{LG}        FR := Ln(R)/Ln(10);
   13:{LN}        FR := Ln(R);
   14:{EXP10}     FR := Exp(R*ln(10));
   15:{EXP}       FR := Exp(R);
   16:{ABS}       FR := Abs(R);
   17:{NOT}       FR := Not(Trunc(R));
  end;
  Ext2Str(FR, Arg);
 end;

 Procedure CompileFn(Var Str : String);
 var
  FnIndex, FnMIndex, FnPos, Ps,
  FnMPos, OBr, CBr, Args, N: Byte;
  SubStr, RSubStr: String[128];
 begin
  SetJump;
  if Length(Str) = 255 then Error(13);
  if Pos(#18, Str) <> 0 then Error(5);
  repeat
   {Найдем первую с конца функцию}
   FnMpos := 0;
   for FnIndex := 0 to FnCount do
    begin
     FnPos := RPos(Functions[FnIndex], stUpCase(Str));
     if (FnPos > 1) and (Str[FnPos-1] in IdChars) then Continue;
     if FnPos > FnMPos then
      begin
       FnMPos := FnPos;
       FnMIndex := FnIndex;
      end;
    end;
   if FnMPos <> 0 then
    begin
     if (FnMPos > 1) and (Str[FnMPos-1] in IdChars) then Error(5);
     {проверяем, что перед функцией не число}
     OBr := FIPos('(',Str,FnMPos);
     if OBr = 0 then Error(7); { "(" expected}
     CBr := findCBr(Str,OBr);
     if CBr = 0 then Error(6);
     if (CBr < Length(Str)) and (Str[Cbr+1] in IdChars) then Error(5);
     {проверяем, что после функции не число}
     SubStr := Copy(Str,Obr + 1,Cbr - Obr-1);
     BrackMax(SubStr);
     CallFn(FnMIndex,SubStr);
     Delete(Str,FnMPos,CBr-FnMPos + 1);
     if Word(Length(Str)) + Length(SubStr) > 255 then Error(13);
     Insert(SubStr,Str,FnMPos);
    end;
  until FnMPos = 0;
  BrackMax(Str);
  Str2Str(Str);
  LongJump;
 end;

function CalcStr(SStr: String; Fmt: TFmt): String;
var
 Ps: Byte;
 Code: Integer;
 Ptr: ^Extended;
 D: Extended;
 SubStr: String;
begin
 SStr := DelChar(' ',SStr);
 if SStr = '' then
 begin
   CalcStr := '0';
   Exit;
 end;
 ResFmt := Fmt;
 FmtSet := [fDec];
 Ptr := Nil;
 ErrorCode := 0;
 ExitSave := ExitProc;
 ExitProc := @CalcExitProc;
 for Ps := 1 to Length(SStr) do
  if SStr[Ps] = 'e' then SStr[Ps] := 'E';
 Ps := Pos(':=',SStr);
 if Ps <> 0 then
  begin
    SubStr := Trim(Copy(SStr,1,Ps-1));
    if SubStr <> '' then
     begin
      SStr := Copy(SStr,Ps + 2,255);
      CompileFn(SStr);
      Ptr := GetKeyAddress(SubStr);
     end;
   end
 else CompileFn(SStr);
 ExitProc := ExitSave;
 if ErrorCode <> 0 then CalcStr := ErrorStr
 else CalcStr := SStr;
 if Ptr <> Nil then
  begin
   Val(SStr, D, Code);
   if Code = 0 then Ptr^ := D;
  end;
end;

procedure CalcStrInit;
begin
 VarColl := New(PVarColl, Init(10,10));
end;

procedure CalcStrDone;
begin
 Dispose(VarColl,Done);
 VarColl := Nil;
end;

end.