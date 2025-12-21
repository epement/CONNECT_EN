function is_cntr(const s: string): boolean;
 var
  i: byte;
  res: boolean;
  flg: boolean;
begin
 i := 0;
 flg := false;
 repeat
  inc(i);
  if s[i] = '%' then flg := true
  else
  if flg and (s[i] in ['0'..'9']) then continue
  else
  if flg and (s[i] = 'd') then break
  else flg := false;
 until i = length(s);
 is_cntr := flg;
end;

begin
 WriteLn(is_cntr('abcd%03dff'));
end.

