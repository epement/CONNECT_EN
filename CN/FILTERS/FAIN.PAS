Program	FAin;
Var
 S : String;
Const
 Flag :	Boolean	= True;
begin
 while not eof do
  begin
   ReadLn(S);
   if Flag and (Pos('File name', S) = 0) then Continue;
   Flag	:= False;
   WriteLn(S);
  end;
end.
