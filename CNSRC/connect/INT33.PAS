Uses DOS, CRT;

var
 Regs: Registers;
 BS: Word;
 M: Word;
 P: Pointer;

procedure MouseHandler;far;assembler;
asm
 mov M, ax
 mov BS, bx
end;

{
INT 33h  AX=000C
 INT 33 - MS MOUSE v1.0+ - DEFINE INTERRUPT SUBROUTINE PARAMETERS
         AX = 000Ch
         CX = call mask (see #2842)
         ES:DX -> FAR routine (see #2843)
 See: AX=0018h
}

begin

 P := @MouseHandler;
 with Regs do
  begin
   ax := $C;
   cx := $ff;
   es := seg(P^);
   dx := ofs(P^);
   intr($33, Regs);
  end;
  while not keypressed do if BS <> 0 then WriteLn(M, ' ', BS);
end.