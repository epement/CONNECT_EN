Uses int2f;
var
 Result: Longint;

begin
 Inst_CN_NT;
 Result := SHExec(ParamStr(1), ParamStr(2), -1);
 WriteLn(Result);
end.