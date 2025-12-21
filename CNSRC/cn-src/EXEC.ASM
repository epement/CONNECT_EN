
;               exec.asm
                jumps
                locals
                .model Small
                include strucs.mac

EBPType struc
 EnvSeg    dw ?
 ComStrPtr Pointer <?,?>
 FCB1Ptr   Pointer <?,?>
 FCB2Ptr   Pointer <?,?>
EBPType ends

                .code
public          Exec
;function Exec(var ProgStr, CMDStr : String; PSPSeg : Word) : Byte

SaveSS          dw ?
SaveSP          dw ?
SaveDS          dw ?
SaveES          dw ?
DTAAddr         Pointer <?,?>

Exec            proc near

;function Exec(var ProgStr, CMDStr : String; PSPSeg : Word) : Byte
;var
; ExecParam : EBPType

@@ProgStr       equ [bp + 0ah]
@@CMDStr        equ [bp + 6]
@@PSPSeg        equ [bp + 4]
@@ExecParam     equ [bp - Type EBPType]
; begin
                push bp
                mov bp,sp
                sub sp,Type EBPType
                push ds
                ; Save Regs
                mov SaveSS,ss
                mov SaveSP,sp
                mov SaveDS,ds
                mov SaveES,es

;                mov ax,5801h
;                mov bx,1
;                int 21h

                ; Get DTAAddr
                mov ah,2fh
                int 21h
                mov DTAAddr.Segment_,es
                mov DTAAddr.Offset_,bx
                ; EnvSeg
                mov @@ExecParam.EnvSeg,0
                ; CMDStr
                les bx,@@CMDStr
                mov @@ExecParam.ComStrPtr.Offset_,bx
                mov @@ExecParam.ComStrPtr.Segment_,es
                ; FCB1
                mov es,@@PSPSeg
                mov @@ExecParam.FCB1Ptr.Offset_,5ch
                mov @@ExecParam.FCB1Ptr.Segment_,es
                ; FCB2
                mov @@ExecParam.FCB2Ptr.Offset_,6ch
                mov @@ExecParam.FCB2Ptr.Segment_,es
                ; ProgStr
                lds dx,@@ProgStr
                ; EBP
                mov ax,ss
                mov es,ax
                lea bx,@@ExecParam
                ; Execute
                mov ax,4b00h
                int 21h
                ; Restore Regs
                mov ss,SaveSS
                mov sp,SaveSP
                mov ds,SaveDS
                mov es,SaveES
                ; Set TDAAddr
                pushf
                mov dx,DTAAddr.Offset_
                mov ds,DTAAddr.Segment_
                mov ah,1ah
                int 21h
                popf
                jc @@Errors
; end
                xor ax,ax
@@Errors:       pop ds
                mov sp,bp
                pop bp
                ret 0ah
Exec            endp

                end
