Uses
 CRT, int2f;

var
 b: byte;
 Handle: Longint;
begin
 Inst_CN_NT;
 Handle := SetTreeCheck(ParamStr(1));
 if Handle <> -1 then
  begin
   repeat
    if DirCheck(Handle) then Writeln('Changes in ', ParamStr(1));
   until KeyPressed{b <> 0};
   DirFree(Handle);
  end;
end.