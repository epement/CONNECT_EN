Unit tpString;
Interface
 function Trim(S : string) : string;
 function StUpcase(const S : string) : string;
Implementation

  function Trim(S : string) : string;
    {-Return a string with leading and trailing white space removed}
  var
    I : Word;
    SLen : Byte absolute S;
  begin
    while (SLen > 0) and (S[SLen] in [#0, #32, #255]) do
      Dec(SLen);

    I := 1;
    while (I <= SLen) and (S[I] in [#0, #32, #255]) do
      Inc(I);
    Dec(I);
    if I > 0 then
      Delete(S, 1, I);

    Trim := S;
  end;

function StUpcase(const S : string) : string;
  {-Convert lower case letters in string to uppercase, with intl chars}
var
 i : Integer;
 SS: String;
begin
 SS[0] := S[0];
  for i := 1 to length(S) do
   SS[i] := UpCase(S[i]);
 StUpcase := SS;
end;

end.
