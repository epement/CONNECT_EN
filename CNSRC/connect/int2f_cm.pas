Uses int2f, crt;
var
 c, cc : Char;

begin
 Inst_CN_NT;
 if CommOpen(1, 9600, 8, 'N', 1) then
  begin
   c := ' ';
   repeat
    if KeyPressed then
     begin
      c := ReadKey;
      WriteBuf(1, c, 1);
     end;
    while ReadBuf(1, cc, 1) > 0 do Write(cc);
    asm
     mov ax, $1680
     int $2f
    end
   until c = #27;
   CommClose(1);
  end;
end.