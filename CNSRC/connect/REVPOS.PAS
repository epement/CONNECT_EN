{$F+,O+,X+}
unit Revpos;
interface
function RPos(SubStr,Str : String) : Byte;
function FPos(SubStr,Str : String) : Byte;
function RIPos(SubStr,Str : String; Ps : Byte) : Byte;
function FIPos(SubStr,Str : String; Ps : Byte) : Byte;
function Count(SubStr,Str : String) : Byte;
function DelChar(Ch : Char; Str : String) : String;
function ReplaceChar(SCh,DCh : Char; Str : String) : String;
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

