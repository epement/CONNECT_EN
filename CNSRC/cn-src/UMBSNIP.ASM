                locals
                jumps
                .model small
                include strucs.mac
                include repeats.mac
                include exchtype.inc

                .data
extrn           ExchBuffer : ExchBufferType
Error5          db 'Failed to load SNIPPER.',13,10,'$'
extrn           Error2 : Byte
extrn           IORes : Word
extrn           SnippBuffSize : Word
UMBFlag         db 0
UMBInUse        db 0
Strategy        dw 0
minSize         equ 8950 ; 4912 (25 lines) 8912 (50 lines)

                .code

extrn           LoadSnipp : near
extrn           Error_Mes : near
public          Init_Snipp
Init_Snipp      proc near
                cmp ExchBuffer.SnippFlag,true
                jne SnippUnLoad
                cmp ExchBuffer.SnippInUse,True ;1
                je NoSnipp
                cmp SnippBuffSize,1000
                jb @@Default
                cmp SnippBuffSize,60000
                ja @@Default
                mov bx,SnippBuffSize
                add bx,minSize
                sh r,bx,4
                jmp @@alloc
@@Default:      mov bx,2cch ;buffer = 2.5k
@@alloc:        call UMB
                mov ah,48h
                int 21h
                jnc Snipp
                mov dx,offset Error2
                jmp Error_Mes ; Memory alloc error;
Snipp:          call RestoreUMB
                mov ExchBuffer.TxtBufferPtr.Segment_,ax
                mov ExchBuffer.Snipp_Init.Segment_,ax
                mov ExchBuffer.Snipp_Done.Segment_,ax
                mov ExchBuffer.Snipp_ClearBuffer.Segment_,ax
                mov ExchBuffer.Snipp_Init.Offset_,2h
                mov ExchBuffer.Snipp_Done.Offset_,5h
                mov ExchBuffer.Snipp_ClearBuffer.Offset_,8h
                push ax
                call LoadSnipp
                cmp IORes,0
                je InitSnipp
                mov dx,offset Error5
                mov  ah,9
                int  21h
                push es
                mov es,ExchBuffer.Snipp_Init.Segment_
                mov ah,49h
                int 21h
                pop es
                jnc NoSnipp
                mov dx,offset Error2
                jmp Error_Mes ; Memory alloc error;
InitSnipp:      mov si,offset ExchBuffer.VideoSeg
                call dword ptr ExchBuffer.Snipp_Init
                mov ExchBuffer.SnippInUse,True
                jmp NoSnipp
SnippUnLoad:    cmp ExchBuffer.SnippInUse,True ;1
                jne NoSnipp
                call dword ptr ExchBuffer.Snipp_Done
                mov ExchBuffer.SnippInUse,False
                push es
                mov ah,49h ; free memory
                mov es,ExchBuffer.Snipp_Init.Segment_
                int 21h
                pop es
                jnc NoSnipp
                mov dx,offset Error2
                jmp Error_Mes ; Memory alloc error;
NoSnipp:        ret
Init_Snipp      endp

UMB             proc near
                push ax bx dx
                mov ah,30h
                int 21h
                cmp al,5h
                jb @@Error      ; DosVersion < 5.0
                mov ax,5802h
                int 21h
                jc @@Error
                mov UMBFlag,al
                mov ax,5800h
                int 21h
                jc @@Error
                mov Strategy,ax
                mov ax,5803h
                mov bx,1
                int 21h
                jc @@Error
                mov ax,5801h
                mov bx,81h      ; Srategy_Flag
                int 21h
                jc @@Error
                mov UMBInUse,1
                jmp @@Quit
@@Error:        mov UMBInUse,0
@@Quit:         pop dx bx ax
                ret
UMB             endp

RestoreUMB      proc near
                push ax bx dx
                cmp UMBInUse,1
                jne @@Quit
                mov ax,5803h
                mov bl,UMBFlag
                xor bh,bh
                int 21h
                jc @@Quit
                mov ax,5801h
                mov bx,Strategy
                int 21h
@@Quit:         pop dx bx ax
                ret
RestoreUMB      endp

                end
