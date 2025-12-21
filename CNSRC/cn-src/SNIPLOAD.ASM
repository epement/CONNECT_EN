                jumps
                locals
                .model Small
                include strucs.mac
                include repeats.mac

public          LoadSnipp
;Procedure LoadSnipp(Seg : Word);

                .data
                ASCIIZString SnippName,<SNIPP.BIN>
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

extrn           FileRead : near
;Procedure FileRead(Var Buffer; BuffSize : Word ; Var FileName : ASCIIZ);

LoadSnipp       proc near
;Procedure LoadSnipp(Seg : Word);
arg @@Seg : Word = @@ParamSize
@@LocalSize = 0
                BeginProc @@LocalSize
                pushs <si,di>
                mov ax,@@Seg
                push ax
                xor ax,ax
                push ax
                mov ax,1024     ;CodeSize
                push ax

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

                mov ax,offset TempStr
                pushs <ds,ax>
                call FileRead
                cmp IORes,0
                jne @@Exit
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


