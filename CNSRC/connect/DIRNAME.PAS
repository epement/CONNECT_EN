var
  I: Integer;
  S: String;
  T: Text;
begin
  if ParamCount = 0 then Exit;
  Assign(T, ParamStr(1));
  Reset(T);
  Readln(T, S);
  Close(T);
  if S[Length(S)] <> '\' then Exit;
  Dec(S[0]);
  I := Length(S);
  while (I > 0) and (S[I] <> '\') do Dec(I);
  S := 'x=' + Copy(S, I + 1, 255);
  Assign(T, ParamStr(1));
  Rewrite(T);
  Writeln(T, S);
  Close(T);
end.