{$F+,O+,X+}
unit Filters;

interface

function PosWord(Const SubStr,Str: String ; Const Terminal) : Byte;
{
  Ищет подстроку SubStr	в строке Str как слово,	ограниченное символами
  из множества Terminal	: Set of Char
}
function RGSearch(const	SubStr:	String;	const Strg : String) : String;
{
  Ищет в строке	Strg регулярное	выражение SubStr. Возвращает
  удовлетворяющую ему подстроку
}
function StringFilter(const Strg: String; Flt: String):	String;
{
  Фильтры $COPY(), $SEARCH(), $POS() заменяются	на соответствующие
  их аргументам	части строки, обрабатываемой фильтром.

  Фильтр $COPY() имеет два аргумента в виде числовых значений
  начальной и конечной позиций в исходной строке, либо в виде
  заключенных в	" " подстрок, между которыми находится искомая
  подстрока. В " " также может быть регулярное выражение. Если
  подстрока может рассматриваться как регулярное выражение, то
  ищется именно	оно.

  Так, например, если исходная строка имеет вид:

    D:\DOC\TXT.DOC  53	Hello world !

  то фильтр вида $COPY(1," ") вернет:

    D:\DOC\TXT.DOC

  т.е все символы, начиная с первого по	первый встретившийся пробел.

  Фильтр $SEARCH() имеет один аргумент в виде регулярного выражения,
  заключенного в " ". Для той же строки	фильтр вида $SEARCH("
  [0-9]+") вернет 53 (пробел и ненулевое количесво символов от 0 до
  9).

  Фильтр $POS()	имеет один аргумент в виде регулярного выражения,
  заключенного в " ". Для той же строки	фильтр вида $POS(" [0-9]+")
  вернет 16 (позицию пробела и ненулевого количесва символов от	0 до
  9 в строке).

  Все остальные	символы	в строке фильтра возвращаются без изменений.
  Так, фильтр вида

    file $COPY(1," ") line($SEARCH(" [0-9]+"))

  для той же строки вернет:

    file D:\DOC\TXT.DOC	line( 53)

  Если результатом фильтра должно быть число, а	в исходной строке
  оно задано в Hex-формате, надо перед фильтром	добавить символ	$.
  Например, $$COPY(10,14).
}

implementation

uses Revpos,GetID,tpString,Objects,Memory,RegExp;

type
 PSRec = ^TSRec;
 TSRec = record
  Ps : Byte;
  Ps2 :	Byte;
  PSearch : Pstring;
 end;

 PColl = ^TColl;
 TColl = object(TCollection)
  procedure FreeItem(Item: Pointer); virtual;
 end;

 procedure TColl.FreeItem(Item : Pointer);
 begin
  if Item <> Nil then
   begin
     DisposeStr(PSRec(Item)^.PSearch);
     FreeMem(Item,SizeOf(TSRec));
   end;
 end;

function RGSearch(const	SubStr:	String;	const Strg : String) : String;
var
 RegExpr : Pointer;
 SS : String;
begin
 RegExpr := RegCompile(SubStr);
 if RegExpr <> nil then
 begin
   SS := RegSearch(RegExpr,Strg);
   if SS = '' then RGSearch := SubStr
   else	RGSearch := SS;
   RegFree(RegExpr);
 end;
end;

function StringFilter(const Strg: String; Flt :	String):String;
Label
 Error;
var
 Ps1,Ps2,Ps3: Byte;
 Arg1,Arg2 : Byte;
 Code :	Integer;
 Index : Word;
 SRec :	PSRec;
 Coll :	Pcoll;
 RegExpr : Pointer;
 SStr, SS: String;
begin
 Coll := new(PColl, Init(10,10));
 StringFilter := 'Filter error';
 Ps1 :=	1;
 repeat
  SStr := GetLiterals(Flt,Ps1,Ps2);
  if Ps2 <> 0 then
   begin
    Delete(Flt,Ps1,Ps2-Ps1+1);
    SRec := MemAlloc(SizeOf(TSRec));
    if SRec <> nil then
     begin
      RegExpr := RegCompile(SStr);
      if RegExpr <> Nil	then
       begin
	SS := RegSearch(RegExpr,Strg);
	if SS <> '' then
	 begin
	  SRec^.Ps := Pos(SS,Strg);
	  SRec^.Ps2 := SRec^.Ps	+ Length(SS);
	  SRec^.PSearch	:= NewStr(SS);
	 end
	else
	 begin
	  SRec^.Ps := 0;
	  SRec^.Ps2 := 0;
	  SRec^.PSearch	:= Nil;
	 end;
       end
      else
       begin
	SRec^.Ps := Pos(SStr,Strg);
	SRec^.Ps2 := SRec^.Ps +	Length(SStr);
	if SRec^.Ps <> 0 then SRec^.PSearch := NewStr(SStr)
	else SRec^.PSearch := Nil;
       end;
      RegFree(RegExpr);
      Coll^.Insert(SRec);
      Str(Coll^.Count-1,SStr);
      Insert('$$' + SStr,Flt,Ps1);
     end;
   end;
 until Ps2 = 0;

 Ps1 :=	0;
 repeat
  Ps1 := FIPos('$COPY(',StUpCase(Flt),Ps1);
  if Ps1 <> 0 then
   begin
    Ps2	:= FIPos(',',Flt,Ps1+6);
    if Ps2 =  0	then GoTo Error;
    SStr := SCopy(Flt,Ps1+6,Ps2);
    if Pos('$$',SStr) <> 0 then
    begin
     Delete(SStr,1,2);
     Val(DelChar(' ',SStr),Index,Code);
     if	Code <>	0 then GoTo Error;
     Arg1 := TSRec(Coll^.At(Index)^).Ps2;
    end
    else
     begin
      Val(DelChar(' ',SStr),Arg1,Code);
      if Code <> 0 then	GoTo Error;
     end;
    Ps3	:= FiPos(')',Flt,Ps2);
    SStr := SCopy(Flt,Ps2 + 1,Ps3);
    if Pos('$$',SStr) <> 0 then
    begin
     Delete(SStr,1,2);
     Val(DelChar(' ',SStr),Index,Code);
     if	Code <>	0 then GoTo Error;
     Arg2 := TSRec(Coll^.At(Index)^).Ps;
    end
    else
     begin
      Val(DelChar(' ',SStr),Arg2,Code);
      if Code <> 0 then	GoTo Error;
     end;
    Delete(Flt,Ps1,Ps3-Ps1+1);
    if (Arg1 <>	0) and (Arg2 <>	0) then
      Insert(SCopy(Strg,Arg1,Arg2),Flt,Ps1);
   end;
 until Ps1 = 0;

 Ps1 :=	0;
 repeat
  Ps1 := FIPos('$SEARCH(',StUpCase(Flt),Ps1);
  if Ps1 <> 0 then
   begin
    Ps3	:= FiPos(')',Flt,Ps1);
    SStr := SCopy(Flt,Ps1 + 8,Ps3);
    if Pos('$$',SStr) =	0 then GoTo Error;
    Delete(SStr,1,2);
    Val(DelChar(' ',SStr),Index,Code);
    if Code <> 0 then GoTo Error;
    Delete(Flt,Ps1,Ps3-Ps1+1);
    if TSRec(Coll^.At(Index)^).PSearch <> Nil then
     Insert(SRec^.PSearch^,Flt,Ps1);
   end;
 until Ps1 = 0;

 Ps1 :=	0;
 repeat
  Ps1 := FIPos('$POS(',StUpCase(Flt),Ps1);
  if Ps1 <> 0 then
   begin
    Ps3	:= FiPos(')',Flt,Ps1);
    SStr := SCopy(Flt,Ps1 + 5, Ps3);
    if Pos('$$',SStr) =	0 then GoTo Error;
    Delete(SStr,1,2);
    Val(DelChar(' ',SStr),Index,Code);
    if Code <> 0 then GoTo Error;
    Delete(Flt,Ps1,Ps3-Ps1+1);
    if TSRec(Coll^.At(Index)^).PSearch <> Nil then
     begin
      Str(Pos(SRec^.PSearch^, Strg), SStr);
      Insert(SStr, Flt,Ps1);
     end;
   end;
 until Ps1 = 0;

 StringFilter := Flt;
Error:
 Dispose(Coll,Done);
end;

function PosWord(Const SubStr,Str: String ; Const Terminal) : Byte;
type
 CharSet = Set of char;
var
 Find :	Boolean;
 Ps, Ps1, SS0, S0 : Byte;
begin
 PosWord := 0;
 Ps1 :=	0;
 SS0 :=	Byte(SubStr[0]);
 S0 := Byte(Str[0]);
 repeat
  Ps :=	FIPos(SubStr,Str,Ps1);
  if Ps	= 0 then Exit;
  Find := (Ps =	0) or ((Ps = 1)	or (Str[Ps-1] in CharSet(Terminal))) and
   ((Ps	+ SS0 -	1 = S0)	or (Str[Ps + SS0] in CharSet(Terminal)));
  Ps1 := Ps;
 until	Find;
 PosWord := Ps;
end;

end.
