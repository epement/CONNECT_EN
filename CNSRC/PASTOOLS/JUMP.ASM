;Jump.asm
                Jumps
                Locals
Pointer         struc
 Offset_        dw ?
 Segment_       dw ?
Pointer         ends

JumpRec         struc
StackPointer    dw ?
BasePointer     dw ?
StackSegm       dw ?
DataSegm        dw ?
RetAddr         Pointer <?,?>
JumpRec         ends

cseg            segment para public 'CODE'
                assume cs : cseg
                public SetJump
                public LongJump

JumpArray       JumpRec 10 dup (<>)
Index           dw 0

SetJump         proc far
                mov ax, Index
                mov bx, Size JumpRec
                mul bx
                mov bx,ax
                mov JumpArray[bx].StackPointer,bp
                add JumpArray[bx].StackPointer,6
                mov ax,[bp]
                mov JumpArray[bx].BasePointer,ax
                mov ax,[bp+2]
                mov JumpArray[bx].RetAddr.Offset_,ax
                mov ax,[bp+4]
                mov JumpArray[bx].RetAddr.Segment_,ax
                mov JumpArray[bx].StackSegm,ss
                mov JumpArray[bx].DataSegm,ds
                inc Index
                retf
SetJump         endp

LongJump        proc far
                dec Index
                mov ax, Index
                or ax,ax
                jns @@1
                retf
@@1:            mov bx, Size JumpRec
                mul bx
                mov bx,ax
                mov sp,JumpArray[bx].StackPointer
                mov bp,JumpArray[bx].BasePointer
                mov ss,JumpArray[bx].StackSegm
                mov ds,JumpArray[bx].DataSegm
                jmp JumpArray[bx].RetAddr
LongJump        endp

cseg ends
end

