unit PosFunc;
interface
 Function RPos(C:byte;var S ) :Byte;
 Function APos(C:Char;var S ) :Byte;
implementation
 Function RPos(C:byte;var S ) :Byte;
  begin
   asm
    les di,S
    mov cl,es:[di]
    mov ah,cl
    xor ch,ch
    add di,cx
    mov al,C
    std
    repne scasb
    cld
    mov @Result,0
    jnz @L0
    inc cl
    mov @Result,cl
  @L0:
   end;
 end;

 Function APos(C:Char;var S ) :Byte;
  begin
   asm
    les di,S
    mov cl,es:[di]
    inc di
    mov ah,cl
    xor ch,ch
    mov al,C
    cld
repne scasb
    mov @Result,0
    jnz @L0
    sub ah,cl
    mov @Result,ah
@L0:
   end;
  end;
end.