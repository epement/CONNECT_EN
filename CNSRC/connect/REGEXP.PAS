{$F+,O+,X+}
unit Regexp;
interface
{
 Спецификаторы,  аналогичные  используемым в GREP, в строке поиска.
 Спецификаторами являются ^, $, ., *, +, ?, (), [], \, |. Они озна-
 чают следующее:

     ^ - в начале строки означает начало строки.
     $ - в конце выражения означает конец строки.
     . - означает любой символ.
     * - символ,  сопровождаемый звездочкой,  означает любое  число
         повторений (включая нуль)  этого  символа.  Например,  bo*
         означает bot, b, boo, и даже be.
     + - символ,  сопровождаемый знаком плюса, означает любое число
         повторений   этого   символа  (но не нуль).  Например, bo+
         означает bot или boo, но не be или b.
     ? - символ, сопровождаемый знаком вопроса означает одно или не
         одного  вхождения  этого символа. Например be? означает b,
         be, но не bo.
    [] - символы   в  квадратных  скобках  означают  какой-то  один
         символ, стоящий в этих скобках.  Например,  [bot] означает
         или b, или o, или t.
   [^] - этот знак  в  квадратных  скобках в начале строки означает
         "не".  Таким образом,  [^bot] означает любой символ, кроме
         b, o или t.
   [-] - внутри квадратных  скобок  означает   диапазон   символов.
         Например, [b-o] означает любой символ от b до o.
    \  - перед символом спецификатора говорит о том, что нужно рас-
         сматривать  этот символ как литеру, а не как спецификатор.
         Например, \^ означает ^, а не начало строки.
   (r) - означает r и представляет собой группу.
    | -  между символами или выражениями в круглых скобках означает
         логическое ИЛИ между этими выражениями.

                             ЗАМЕНЫ СТРОК

    & -  Вставляет исходную строку.
   \n -  Вставляет текст, сопоставленный с группой номер 'n'(0-9).
         Например поиск выражения
          ([A-Z]+)([0-9]+)
         в строке
          --- AB56 ---
         и замене ее на
          & -> \1\0
         даст в результате
          --- AB56 -> 56AB ---
}

type

 SubExpArrPtr = ^SubExpArr;
 {SubExpArr = array[0..9] of PChar;}
 SubExpArr = array[0..10] of PChar;

 PRegExp = ^RegExpr;
 RegExprPtr = ^RegExpr;
 RegExpr = record
   startp,
   endp: SubExpArr;
   regstart,
   reganch: char;           { Internal use only. }
   regmust: PChar;          { Internal use only. }
   regmlen: word;           { Internal use only. }
   rprogram: array[0..0] of byte;  { Unwarranted chumminess with compiler. }
 end;

{ Added 2005.09.19 to support regexp autoincrement counter }
var
  RegExpCounter: Longint;

function RegComp(Exp: PChar): Pointer;

function RegCompile(const Expr : String): Pointer;
{
  Возвращает указатель на скомпилированное регулярное выражение
  или Nil, в случае ошибки в нем.
}

function RegError: String;
{
  Возвращает сообщение об ошибке, возникающей при компилировании
  регулярного выражения.
}

function RegExec(RegEx: PRegExp; Strg: PChar): integer;

function RegEx(Reg: Pointer; Strg: PChar): integer;
{
  Ищет в строке Strg скомпилированное регулярное выражение.
  Возвращает 0 если не находит.
}

function RegSearch(Exp: Pointer; Const Strg: String): String;
{
  Ищет в строке Strg скомпилированное регулярное выражение.
  Возвращает подстроку, ему соответствующую.
}

function RegExBack(Exp: Pointer; Strg: PChar): Integer;
{
  Ищет в строке Strg начиная с ее конца скомпилированное регулярное
  выражение. Возвращает 0 если не находит.
}

function RegSearchBack(Exp: Pointer; const Strg: String): String;
{
  Ищет в строке Strg начиная с ее конца скомпилированное регулярное
  выражение. Возвращает подстроку, ему соответствующую.
}

function regsub(prog: PRegExp; const replace: string;
                var dest: string): Boolean;
{
  Вызывается после RegExec и в строке dest возвращает
  результат замены найденного выражения на строку replace.
}

procedure RegFree(P: Pointer);
{
  Освобождает память, выделенную под скомпилированное регулярное
  выражение.
}

implementation

uses Dos, Memory, Strings, Drivers, Dialogs;

var
 _RegError: word;

{ Added 2005.09.27 to support regexp timestamps }
type
  TFormatDateTimeRec = record
    Year, Month, Day, Hour, Min, Sec: Longint;
  end;

var
  DTR: DateTime;
  FDTR: TFormatDateTimeRec;
  DTL: Longint;

{$L REGEXP.OBJ}
function RegExec(RegEx: PRegExp; Strg: PChar): integer; external;
function RegComp(Exp: PChar): Pointer; external;
{$L STRNCMP.OBJ}
procedure _strncmp; external;
{$L STRLEN.OBJ}
procedure _strlen; external;
{$L STRCSPN.OBJ}
procedure _strcspn; external;
{$L STRCHR.OBJ}
procedure _strchr; external;

procedure RegFree(P: Pointer);
begin
 if P <> Nil then
  begin
   Dec(Word(P),2);
   FreeMem(P,Word(P^)+2);
  end;
end;

function malloc(Size : Word) : Pointer;
var
 P : Pointer;
begin
 P := MemAlloc(Size+2);
 if P <> Nil then
  begin
   Word(P^) := Size;
   Inc(Word(P),2);
  end;
 malloc := P;
end;

function RegError;
begin
 case _regerror of
   0:  RegError := '';
   1:  RegError := 'No match found for regular expression';
   2:  RegError := 'Invalid parameter passed to function';
   3:  RegError := 'Regular expression too complex';
   4:  RegError := 'Out of memory';
   5:  RegError := 'Too many sub-expressions';
   6:  RegError := 'Unmatched ''(''';
   7:  RegError := 'Invalid use of a repeat';
   8:  RegError := 'Nested repeats not allowed';
   9:  RegError := 'Invalid range specifier';
   10: RegError := 'Unmatched ''[''';
   11: RegError := 'Trailing ''\\'' not allowed';
 end;
end;

function RegCompile(const Expr : String) : Pointer;
var
 W: Word;
 SStr : Array[0..255] of Char;
begin
 asm
  mov dx,ds
  lds si,Expr
  mov ax,ss
  mov es,ax
  lea di,SStr
  lodsb
  xor ah,ah
  mov cx,ax
  rep movsb
  xor al,al
  stosb
  mov ds,dx
 end;
 RegCompile := RegComp(SStr);
{ Added 2005.09.19 to support regexp autoincrement counter }
 RegExpCounter := 0;
{ Added 2005.09.27 to support regexp timestamps }
 GetDate(DTR.Year, DTR.Month, DTR.Day, W);
 GetTime(DTR.Hour, DTR.Min, DTR.Sec, W);
 PackTime(DTR, DTL);
 FDTR.Year := DTR.Year;
 FDTR.Month := DTR.Month;
 FDTR.Day := DTR.Day;
 FDTR.Hour := DTR.Hour;
 FDTR.Min := DTR.Min;
 FDTR.Sec := DTR.Sec;
end;

function RegEx(Reg: Pointer; Strg: PChar): integer;
begin
 RegEx := RegExec(Reg, Strg);
end;

function RegSearch(Exp: Pointer; Const Strg: String): String;
var
 SStr : Array[0..255] of Char;
begin
 asm
  mov dx,ds
  lds si,Strg
  mov ax,ss
  mov es,ax
  lea di,SStr
  lodsb
  xor ah,ah
  mov cx,ax
  rep movsb
  xor al,al
  stosb
  mov ds,dx
 end;
 if RegExec(Exp,SStr) <> 0 then
  asm
    mov dx,ds
    les di,Exp
    mov si,es:[di]
    mov ds,es:[di+2]
    mov cx,es:[di+44]
    sub cx,es:[di]
    xor ch,ch
    les di,[bp+0eh]
    mov es:[di],cl
    inc di
    rep movsb
    mov ds,dx
  end
 else RegSearch := '';
end;

function RegExBack(Exp: Pointer; Strg: PChar): Integer;
var
  P, SavePtr: PChar;
begin
  if (Strg^ = #0) or (RegExec(Exp, Strg) = 0) then
  begin
    RegExBack := 0;
    Exit;
  end;
  repeat
    P := PRegExp(Exp)^.StartP[0];
    SavePtr := P;
    Inc(P);
    if (P^ = #0) or (RegExec(Exp, P) = 0) then
    begin
      PRegExp(Exp)^.StartP[0] := SavePtr;
      Break;
    end;
  until False;
  RegExBack := 1;
end;

function RegSearchBack(Exp: Pointer; const Strg: String): String;
var
  I: Integer;
  S, SS, SSS: String;
begin
  S := Strg;
  SS := '';
  repeat
    SSS := RegSearch(Exp, S);
    if SSS = '' then Break;
    SS := SSS;
    I := Pos(SS, S);
    if I = 255 then Break;
    S := Copy(S, I + 1, 255);
    if S = '' then Break;
  until False;
  RegSearchBack := SS;
end;

{
 - regsub - perform substitutions after a regexp match
}

{ Added 2005.09.25 }
{
^U      Uppercase
^L      Lowercase
^E      QWERTY
^R      ЙЦУКЕН
^I      Capitalize
^H      Hex
^T      Volapyuk
^W      VolToRus
^B      UkrVolapyuk
^G      VolToUkr
Alt+n   XLAT

Example:
xlt^1[&]
}

function is_cntr(const s: string): boolean;
 var
  i: byte;
  flg: boolean;
begin
 i := 0;
 flg := false;
 repeat
  inc(i);
  if s[i] = '%' then flg := true
  else
  if flg and (s[i] in ['0'..'9']) then continue
  else
  if flg and (s[i] = 'd') then break
  else flg := false;
 until i = length(s);
 is_cntr := flg;
end;

procedure FinalizeRegSub(var S: String; cntr: boolean);
const
  xltChars = ['0'..'9', 'B', 'E', 'G', 'H', 'I', 'L', 'R', 'T', 'U', 'W', '_', '^'];
var
  C: Char;
  W, DayOfWeek, Sec100: Word;
  A: TConvertAction;
  I, J, K: Integer;
  SS, FS: String;
begin
{ Format date/time }
  repeat
    I := Pos('time^[', S);
    if (I = 0) or (Length(S) < I + 7) then Break;
    J := I + 6;
    K := 0;
    while J <= Length(S) do
    begin
      if S[J] = '[' then Inc(K)
      else if S[J] = ']' then
        if K <> 0 then Dec(K) else Break;
      Inc(J);
    end;
    SS := Copy(S, I + 6, J - (I + 6));
    repeat
      K := Pos('%$', SS);
      if K = 0 then Break;
      FormatStr(FS, '%08x', DTL);
      Delete(SS, K, 2);
      Insert(FS, SS, K);
    until False;
    FormatStr(FS, SS, FDTR);
    Delete(S, I, J - I + 1);
    Insert(FS, S, I);
  until False;

{ Format counter }
  if cntr then
   begin
    SS := S;
    FormatStr(S, SS, RegExpCounter);
    Inc(RegExpCounter);
   end;

{ Decode string }
  repeat
    I := Pos('xlt^', S);
    if (I = 0) or (Length(S) < I + 6) or not (S[I + 4] in xltChars) or
       (S[I + 5] <> '[') then Break;
    J := I + 6;
    K := 0;
    while J <= Length(S) do
    begin
      if S[J] = '[' then Inc(K)
      else if S[J] = ']' then
        if K <> 0 then Dec(K) else Break;
      Inc(J);
    end;
    SS := Copy(S, I + 6, J - (I + 6));
    if I = 1 then C := #0 else C := S[I - 1];
    W := 0;
    case S[I + 4] of
      '0'..'9':
        begin
          A := caXLAT;
          if S[I + 4] = '0' then W := kbAlt0
          else W := kbAlt1 + (Byte(S[I + 4]) - Byte('1')) shl 1;
        end;
      'B': A := caUkrVolapyuk;
      'E': A := caLatin;
      'G': A := caVolToUkr;
      'H': A := caHex;
      'I': A := caCaps;
      'L': A := caLocase;
      'R': A := caRus;
      'T': A := caVolapyuk;
      'U': A := caUpcase;
      'W': A := caVolToRus;
      '_': A := caSpaceToUnderline;
      '^': A := caUnderlineToSpace;
      else Break;
    end;
    ConvertString(SS, A, C, W);
    Delete(S, I, J - I + 1);
    Insert(SS, S, I);
  until False;
end;

const
  MAGIC = 156;

function regsub(prog: PRegExp; const replace: string;
                var dest: string): Boolean;
  var
    i: Byte;
    c: char;
    no: integer;
    len: word;
  begin
    regsub := False;
    dest := '';
    if (prog <> nil) and (prog^.rprogram[0] = MAGIC) then
      begin
        i := 1;
        c := replace[i];
        Inc(i);
        while (i <= length(replace)+1) do
          begin
            if c = '&' then no := 0
            else if (c = '\') and (i <= length(replace)) and
                    (replace[i] in ['0'..'9'])  then
                   begin
                     no := Ord(replace[i]) - Ord('0') + 1;
                     Inc(i);
                   end
                 else no := -1;
            if no < 0 then
              begin
                { Ordinary character. }
                if (c = '\') and (i <= length(replace)) then
                 begin
                   c := replace[i];
                   inc(i);
                 end;
                if length(dest) < 255 then
                 begin
                   inc(dest[0]);
                   dest[length(dest)] := c;
                 end;
              end
            else
              if (prog^.startp[no] <> nil) and
                 (prog^.endp[no] <> nil) then
                begin
                  len := prog^.endp[no] - prog^.startp[no];
                  if (len + length(dest) <= 255) then
                   begin
                    move(prog^.startp[no]^, dest[length(dest)+1], len);
                    inc(dest[0], len);
                   end;
                end;
            c := replace[i];
            Inc(i);
          end;
{ Added 2005.09.25 }
        FinalizeRegSub(Dest, is_cntr(replace));
        regsub := True;
      end;
  end;

end.