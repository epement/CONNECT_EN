uses Dos;

var
  ftime : Longint; { For Get/SetFTime}
  dt : DateTime; { For Pack/UnpackTime }
                 { For WinDos use TDateTime }
  C, i: Integer;
  S: String;


function LeadingZero(w : Word) : String;
var
  s : String;
begin
  Str(w:0,s);
  if Length(s) = 1 then
    s := '0' + s;
  LeadingZero := s;
end;

begin
 i := 1;
 repeat
  if ParamCount = 0 then ReadLn(S)
  else S := ParamStr(i);
  if S <> '' then
   begin
    Val('$'+S, ftime, c);
    UnpackTime(ftime,dt);
    with dt do
      begin
        Writeln(Year, '-',
                LeadingZero(Month), '-',
                LeadingZero(Day), ' ',
                LeadingZero(hour),':',
                LeadingZero(min),':',
                LeadingZero(sec));
      end;
    inc(i);
   end;
 until S = '';
end.