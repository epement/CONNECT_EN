{$A+,B-,D+,E+,F+,G-,I-,L+,N+,O+,P-,Q-,R-,S-,T-,V-,X+,Y-}
{$M 16384,0,655360}

USES REGEXP;

const
 src = '++++++++++ 456 +++++++++ :123: a b c ';
 reg = ':([0-9]+):';
 repl = '(&)\0';
var
 dst, s: String;
 P: PRegExp;
 len: byte;
begin
 P := RegCompile(reg);
 if P <> Nil then
  begin
   s := RegSearch(P, src);
   if (p^.startp[1] <> nil) and
      (p^.endp[1] <> nil) then
     begin
       len := p^.endp[1] - p^.startp[1];
       if (len <= 255) then
	begin
	 move(p^.startp[1]^, s[1], len);
         s[0] := char(len);
	end;
     end;
   WriteLn(s);
   regsub(P, repl, dst);
   WriteLn(dst);
  end;
end.