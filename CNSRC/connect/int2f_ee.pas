Uses int2f;
var
 Result: Longint;
 cmd, redir: PChar;

begin
 Inst_CN_NT;
 cmd := 'C:\HT-PIC\bin\picc.exe -E -O -G -Zg -INTEL -D24 -ASMLIST -Mmap -16F73 -DB400 -RESROMFFA-FFF C:\Pic\400.c'#0#0;
 redir := 'C:\ooo'#0;
 Result := ExecNT(cmd, redir, 0);
end.