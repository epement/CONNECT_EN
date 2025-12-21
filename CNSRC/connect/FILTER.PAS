{$A+,B-,D-,E+,F-,G-,I+,L-,N+,O-,P-,Q-,R-,S+,T-,V+,X+,Y-}
{$M 16384,0,655360}

Program Filter;

Uses
 Objects, Filters, TpString;
var
 SS,Flt,ComStr : String;

function GetParam(Var Param : String; const Key, ComStr : String) : Boolean;
 var
  Ps : Byte;
 begin
   Ps := Pos(Key,ComStr);
   if Ps <> 0 then
    begin
      Param := '';
      Inc(Ps,2);
      GetParam := True;
      while (ComStr[Ps] <> '/') and (Ps <= Length(ComStr)) do
       begin
        Param := Param + ComStr[Ps];
        Inc(Ps);
       end;
    end
   else GetParam := False;
 end;

begin
 WriteLn('Filter /sstring /ffilter');
 Writeln('Copyright (C) 1994, by Orlov D.,2:461/27');

 ComStr := StUpCase(PString(Ptr(PrefixSeg,$80))^);

 if not GetParam(Flt, '/F', ComStr) then
  begin
   WriteLn('missing /ffilter');
   Halt(1);
  end;

 if GetParam(SS, '/S', ComStr) then
  begin
   Writeln(StringFilter(SS,Flt));
   Halt;
  end;

 while not eof do
  begin
   ReadLn(SS);
   Writeln(StringFilter(SS,Flt));
  end;
end.