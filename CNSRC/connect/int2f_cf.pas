Uses int2f;
var
 FileSize, CompSize: Longint;

function Size2str(Size: Real): String;
var
 S: String;
 c: Char;
begin
 if Size > 1073741824.0 then
  begin
   Size := Size / 1073741824.0;
   c := 'G';
  end
 else
 if Size > 1048576.0 then
  begin
   Size := Size / 1048576.0;
   c := 'M';
  end
 else
 if Size > 1024.0 then
  begin
   Size := Size / 1024.0;
   c := 'K';
  end
 else c := 'B';

 Str(Size:4:4, S);
 Size2str := S+c;
end;

begin
 Inst_CN_NT;
 GetCompFileSize(ParamStr(1),
                 FileSize,
                 CompSize);

 WriteLn('FileSize = ', Size2str(FileSize), #13#10,
         'CompSize = ', Size2str(CompSize));

end.