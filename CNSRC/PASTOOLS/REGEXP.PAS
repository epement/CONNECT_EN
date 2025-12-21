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
         и змене ее на
          & -> \1\0
         даст в результате
          --- AB56 -> 56AB ---
}

type

 SubExpArrPtr = ^SubExpArr;
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

function RegComp(Exp: PChar): Pointer;

function RegCompile(const Expr: String): Pointer;
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
uses
 Memory, Strings;

var
 _RegError: word;

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

function malloc(Size: Word): Pointer;
var
 P: Pointer;
begin
 P := MemAlloc(Size + 2);
 if P <> Nil then
  begin
   Word(P^) := Size;
   Inc(Word(P), 2);
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

function RegCompile(const Expr: String): Pointer;
var
 SStr: Array[0 .. 255] of Char;
begin
 asm
  mov dx, ds
  lds si, Expr
  mov ax, ss
  mov es, ax
  lea di, SStr
  lodsb
  xor ah, ah
  mov cx, ax
  rep movsb
  xor al, al
  stosb
  mov ds, dx
 end;
 RegCompile := RegComp(SStr);
end;

function RegEx(Reg: Pointer; Strg: PChar): integer;
begin
 RegEx := RegExec(Reg, Strg);
end;

function RegSearch(Exp: Pointer; Const Strg: String): String;
var
 SStr: Array[0 .. 255] of Char;
begin
 asm
  mov dx, ds
  lds si, Strg
  mov ax, ss
  mov es, ax
  lea di, SStr
  lodsb
  xor ah, ah
  mov cx, ax
  rep movsb
  xor al, al
  stosb
  mov ds, dx
 end;
 if RegExec(Exp, SStr) <> 0 then
  asm
    mov dx, ds
    les di, Exp
    mov si, es:[di]
    mov ds, es:[di+2]
    mov cx, es:[di+44]
    sub cx, es:[di]
    xor ch, ch
    les di, [bp + 0eh]
    mov es:[di], cl
    inc di
    rep movsb
    mov ds, dx
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
  B: Byte;
  S, SS, SSS: String;
begin
  S := Strg;
  SS := '';
  repeat
    SSS := RegSearch(Exp, S);
    if SSS = '' then Break;
    SS := SSS;
    B := Pos(SS, S);
    if B = 255 then Break;
    S := Copy(S, B + 1, 255);
    if S = '' then Break;
  until False;
  RegSearchBack := SS;
end;

{
 - regsub - perform substitutions after a regexp match
}
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
        regsub := True;
      end;
  end;

end.