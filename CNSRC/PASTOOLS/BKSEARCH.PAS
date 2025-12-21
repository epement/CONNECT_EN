unit BKSearch;
interface

function RSearch(Const Buff; Length: Word; const Str : String) : Word;
{ Ищет подстроку Str в буфере Buff длиной Length начиная с конца
  Buff ( c права на лево) }

implementation
{$L rsearch.obj}
function RSearch; external;
end.


