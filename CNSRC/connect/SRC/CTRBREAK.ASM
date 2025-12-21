                .model tpascal
                jumps
                locals
Pointer         struc
 Offset_        dw ?
 Segment_       dw ?
Pointer         ends

GetIntVec Macro Vec,SaveVec
                push es
                push ax
                mov ax,0
                mov es,ax
                cli
                mov ax,es:[Vec*4]
                mov &SaveVec&.Offset_,ax
                mov ax,es:[Vec*4+2]
                mov &SaveVec&.Segment_,ax
                sti
                pop ax
                pop es
endm

SetIntVec Macro Vec,SaveVec
                push es
                push ax
                mov ax,0
                mov es,ax
                mov ax,&SaveVec&.Offset_
                cli
                mov es:[Vec*4],ax
                mov ax,&SaveVec&.Segment_
                mov es:[Vec*4+2],ax
                sti
                pop ax
                pop es
endm

SetIntVecProc Macro Vec,Procedure
                push es
                push ax
                mov ax,0
                mov es,ax
                mov ax,Offset Procedure
                cli
                mov es:[Vec*4],ax
                mov ax,cs
                mov es:[Vec*4+2],ax
                sti
                pop ax
                pop es
endm


                .code
extrn           _Stop : far

Save09Vec       Pointer <0,0>

HandleBreak     proc far
                push es
                push ds
                push ax
                push bx
                push cx
                push dx
                push di
                push si
                mov ax,cs
                mov ds,ax
pop1:           pushf
                call dword ptr Save09Vec
                mov ah,1
                int 16h
                mov bl,ah
                mov ah,2
                int 16h
                and al,00000100b
                cmp al,00000100b   ;Ctrl pressed
                jne pop2
                cmp bl,0
                jne pop2
                SetIntVec 9,Save09Vec
                call _Stop
pop2:           pop si
                pop di
                pop dx
                pop cx
                pop bx
                pop ax
                pop ds
                pop es
                iret
HandleBreak     endp

SetBreakHandler proc far
public          SetBreakHandler
                GetIntVec 9,Save09Vec
                SetIntVecProc 9,HandleBreak
                retf
SetBreakHandler endp

RestoreBreak    proc far
public          RestoreBreak
                SetIntVec 09h,Save09Vec
                retf
RestoreBreak    endp
                end
