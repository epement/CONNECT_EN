                jumps
                locals
                .model Small
                include strucs.mac
                include repeats.mac


public          LoadSnipp
;Procedure LoadSnipp(Seg : Word);

                .data
ifdef DB80
                ASCIIZString SnippName,<DB.EXE>
else
                ASCIIZString SnippName,<CN.EXE>
endif

extrn           IORes : Word
extrn           TempStr : Byte
extrn           MyPath : Byte

                .code


CopyASCIIZ macro
local l0
l0:             lodsb
                stosb
                or al,al ;cmp al,0
                jnz l0
endm

LoadSnipp       proc near
;Procedure LoadSnipp(Seg : Word);
arg @@Seg : Word = @@ParamSize
Local @@Handler : Word = @@LocalSize
                BeginProc @@LocalSize
                push si di
                mov si,offset MyPath
                mov di,offset TempStr
                lodsb
                mov cl,al
                xor ch,ch
                rep movsb
                cmp  byte ptr es:[di-1],'\'
                je @@SlashPresent
                mov al,'\'
                stosb
@@SlashPresent: mov si,offset SnippName
                CopyASCIIZ

                mov dx,offset TempStr
                mov ax,3d00h
                int 21h        ; Open file
                jnc @@Read
                mov IORes,ax
                jmp @@Exit
@@Read:         mov @@Handler,ax
                mov ah,3fh
                mov bx,@@Handler
                push ds
                mov ds,@@Seg
                xor dx,dx      ; ds:dx --> Buffer
                mov cx,8       ; cx = Count
                int 21h        ; Read file with handle
                jc @@DiskErr
                mov ax, word ptr ds:[Signature]
                cmp ax,5a4dH   ;'MZ'
                mov ax,1
                stc
                jne @@DiskErr
                mov ax,word ptr ds:[PageCnt]
                mov dx,200h
                mul dx
                mov cx,word ptr ds:[PartPage]
                neg cx
                and cx,1ffh
                sub ax,cx
                sbb dx,0
                mov cx,dx
                mov dx,ax
                mov ax, 4200H ;Seek offset from beginning of file
                int 21H
                jc @@DiskErr
                mov ah,3fh
                mov bx,@@Handler
                xor dx,dx      ; ds:dx --> Buffer
                mov cx,1024    ; cx = Count
                int 21h        ; Read file with handle
                jc @@DiskErr
                mov bx,@@Handler
                mov ah,3eh
                int 21h      ; Close file
@@DiskErr:      pop ds
                mov IORes,ax
                jc @@Exit
                mov IORes,0

                pushs <es,di>
                xor di,di
                mov es,@@Seg
                mov ax,word ptr es:[di]
                sub ax,55aah
                mov IORes,ax
                pops <di,es>
@@Exit:         pops <di,si>
                EndProc @@ParamSize
LoadSnipp       endp
                end


