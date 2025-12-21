unit Revpos;
interface

function RPos(SubStr,Str : String) : Byte;
{ Ищет подстроку SubStr в строке Str начиная с конца Str ( c права на лево)}

function FPos(SubStr,Str : String) : Byte;
{ Полный аналог Pos (для симметрии) }

function RIPos(SubStr,Str : String; Ps : Byte) : Byte;
{ Ищет подстроку SubStr в строке Str начиная с позиции Ps ( c права на лево)}

function FIPos(SubStr,Str : String; Ps : Byte) : Byte;
{ Ищет подстроку SubStr в строке Str начиная с позиции Ps ( c лева на право)}

function Count(SubStr,Str : String) : Byte;
{ Считает кличество подсткрок SubStr в строке Str }

function DelChar(Ch : Char; Str : String) : String;
{ Удаляет все символы Ch из строки Str и возвращяет результат}

function ReplaceChar(SCh,DCh : Char; Str : String) : String;
{ Заменяет все символы SCh на DCh в строке Str и возвращяет результат}
implementation
{$L rpos.obj}
function RPos; external;
function FPos; external;
function RIPos; external;
function FIPos; external;
function Count; external;
function DelChar; external;
function ReplaceChar; external;
end.

