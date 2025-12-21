{$F+,O+,X+}
unit GetID;
interface
function GetLeftId(Const S : String; Const IdChars ;
                   var Ps : Byte) : String;
function GetRightId(Const S : String; Const IdChars ;
                    var Ps : Byte) : String;
function GetRight(Const S : String; Const IdChars ; var Ps : Byte) : String;
function ZInTest(C : Char;Const S) : Boolean;
function findfCBr(Var Str : String; OBr : Byte) : Byte; (*{...}*)
function findQCBr(Var Str : String; OBr : Byte) : Byte; (*[...]*)
function findCBr(Var Str : String; OBr : Byte) : Byte;  (*(...)*)
function GetLiterals(const Str : String;  var Ps1,Ps2 : Byte):String;
function SCopy(const Str : String; From,To_ : Byte):String;
{Читает строку Str начиная с Ps3}
{Возвращает найденную в литералах строку и ее начальную и конечную}
{позиции в исходной строке}
implementation
{$L GETID.OBJ}
{$L findcbr.obj}
function GetLeftId; external;
function ZInTest; external;
function GetRightId; external;
function findfCBr;external;
function findCBr;external;
function findQCBr;external;
function GetLiterals;external;
function SCopy;external;
function GetRight;external;
end.
