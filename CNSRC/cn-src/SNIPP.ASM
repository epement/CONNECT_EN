                model TINY
                JUMPS
                locals
                include repeats.mac
                include strucs.mac
                include int1.mac

PosType         struc
 X              db ?
 Y              db ?
PosType         ends

ExchBufferType  struc
 VideoSeg       dw ?
 BufferEnd      dw ?
 BufferPtr      Pointer <?,?>
ExchBufferType  ends

cseg            segment word public 'code'
                assume cs:cseg
                dw 55aah
                jmp Snipp_Init
                jmp Snipp_Done
                jmp Snipp_ClearBuffer

Save09Vec       Pointer <?,?>
KeyPressed      db ?
Pos1            PosType <0,0>
Pos2            PosType <0,0>

ScreenSeg       dw 0B800h
Rows            db 25
TextPtr         dw 0
ParentPtr       Pointer <?,?>
TxtBufferEnd    dw offset TxtBuffer+2000h
ActivFlag       db 0
Up_             equ 48h
Down_           equ 50h
Left_           equ 4bh
Right_          equ 4dh
Enter_          equ 1ch
Escape_         equ 1
Maska           equ 55h ; for Color mode
;Maska           equ 7fh ; for Mono mode

HandleBreak     proc far
                push es ds ax bx cx dx di si bp
                mov ax, cs
                mov ds, ax
                mov ax, 40h
                mov es, ax
                in  al, 60h
                mov ah, es:byte ptr 17h
                and ah,0ch

                pushf
                call dword ptr Save09Vec

                cmp ax,0c11h ;Alt-Ctrl-W pressed
                jne pop2
                cmp cs:ActivFlag,True
                je pop2
                mov cs:ActivFlag,True
                call Snipp
                mov cs:ActivFlag,False
pop2:           pop  bp si di dx cx bx ax ds es
                iret
HandleBreak     endp

Scr2Buff        proc near
                assume ds:nothing,es:cseg
                push ds
                mov ds,cs:ScreenSeg
                xor si,si
                mov di,offset ScrBuffer
                mov ax,cs
                mov es,ax
                mov cx,4000
                cld
                rep movsw
                pop ds
                ret
Scr2Buff        endp

Buff2Scr        proc near
                pushs <es,di,si,cx,ax,dx>
                assume ds:cseg
                mov es,ScreenSeg
                xor di,di
                mov si,offset ScrBuffer
                mov cx,4000
                cld
                rep movsw
                pops <dx,ax,cx,si,di,es>
                ret
Buff2Scr        endp

GetEvent        proc near
                xor ah,ah
                int 16h
                ret
GetEvent        endp

GetOffset       proc near
arg @@Pos : Word = @@ParamSize
@@LocalSize = 0
                BeginProc @@LocalSize
                push ax
                xor ah,ah
                mov al,@@Pos.Y
                mov bl,160
                mul bl
                mov bl,@@Pos.X
                xor bh,bh
                shl bx,1
                add bx,ax
                pop ax
                EndProc @@ParamSize
GetOffset       endp

PosHandle       proc near
                assume ds:cseg,es:nothing,cs:cseg
                push cx
                mov cl,Rows
                cmp ah,Up_
                je @@Up_
                cmp ah,Down_
                je @@Down_
                cmp ah,Left_
                je @@Left_
                cmp ah,Right_
                je @@Right_
                pop cx
                ret
@@Up_:          dec Pos1.Y
                jmp @@NewPos
@@Down_:        inc Pos1.Y
                jmp @@NewPos
@@Left_:        dec Pos1.X
                jmp @@NewPos
@@Right_:       inc Pos1.X
@@NewPos:       mov bx,Pos2
                cmp Pos1.Y,cl   ;25
                jl @@L1
                mov Pos1.Y,bh
@@L1:           cmp Pos1.Y,bh
                jge @@L2
                dec cl
                mov Pos1.Y,cl   ;24
@@L2:           cmp Pos1.X,80
                jl @@L3
                mov Pos1.X,bl
@@L3:           cmp Pos1.X,bl
                jge @@L4
                mov Pos1.X,79
@@L4:           pop cx
                ret
PosHandle       endp

Cursor          proc near
                assume ds:cseg,es:nothing,cs:cseg
                mov es,ScreenSeg
                xor di,di
                mov si,offset ScrBuffer
                push Pos1
                call GetOffset
                add si,bx
                add di,bx
                movsw
                call PosHandle
                push Pos1
                call GetOffset
                xor byte ptr es:[bx+1],Maska
                ret
Cursor          endp

HighLight       proc near
@@ParamSize = 0
local @@Pos : Word = @@LocalSize
                BeginProc @@LocalSize
                assume ds:cseg,es:nothing,cs:cseg
                mov es,ScreenSeg
                mov ax,Pos2
                mov @@Pos,ax
                xor cx,cx
                mov cl,Pos1.Y
                inc cl
                sub cl,Pos2.Y
                mov dl,Pos1.X
                inc dl
                sub dl,Pos2.X
                jz @@Exit
@@L2:           push cx
                mov cl,dl
                mov @@Pos.X,al
@@L1:           push @@Pos
                call GetOffset
                xor byte ptr es:[bx+1],Maska
                inc @@Pos.X
                loop @@L1
                pop cx
                jcxz @@Exit
                inc @@Pos.Y
                loop @@L2
@@Exit:         EndProc @@ParamSize
HighLight       endp

beep            proc near
                push bx ax
                mov ax,0e07h
                xor bx,bx
                int 10h
                pop ax bx
                ret
beep            endp

TxtCopy         proc near
@@ParamSize = 0
local @@Pos : Word,@@LengthPtr : Word = @@LocalSize
                BeginProc @@LocalSize
                assume ds:cseg,es:cseg,cs:cseg
                mov ax,cs
                mov es,ax
                mov di,offset TxtBuffer
                add di,TextPtr
                mov ax,Pos2
                mov @@Pos,ax
                xor cx,cx
                mov cl,Pos1.Y
                inc cl
                sub cl,Pos2.Y
                mov dl,Pos1.X
                inc dl
                sub dl,Pos2.X
                jz @@Exit
                mov dh,al
@@L2:           push cx
                mov cl,dl
                mov @@Pos.X,dh ;X1
                mov byte ptr es:[di],cl
                mov @@LengthPtr,di
                inc di
@@L1:           push @@Pos
                call GetOffset
                mov al,byte ptr ds:[offset ScrBuffer+bx]
                cmp di,TxtBufferEnd
                jb @@L4
                call beep
                pop cx
                jmp @@L5
@@L4:           stosb
                inc @@Pos.X
                loop @@L1
                call @@ClearSpace
                pop cx
                jcxz @@Exit
                inc @@Pos.Y
                loop @@L2
@@L5:           mov TextPtr,di
                sub TextPtr,offset TxtBuffer
@@Exit:         EndProc @@ParamSize

@@ClearSpace:   push bx
                mov bx,@@LengthPtr
@@L7:           cmp byte ptr es:[di-1],20h ; ' '
                jne @@L6
                dec di
                dec byte ptr es:[bx]
                jmp @@L7
@@L6:           pop bx
                ret
TxtCopy         endp

Snipp           proc near
                mov ax, 40h
                mov es, ax
                mov al, es:byte ptr 49h ; Video Mode
                mov bh, es:byte ptr 62h ; Active Page
                cmp al,2
                je @@L2
                cmp al,3
                je @@L2
                cmp al,7
                je @@L2
                ret
@@L2:           or bh,bh
                je @@L3
                ret

@@L3:           call GetRowsNumber
                call Scr2Buff
                mov Word ptr Pos2,0
@@loop1:        call GetEvent
                cmp ah,Escape_
                jz @@Exit
                cmp ah,Enter_
                jz @@l1
                call Cursor
                jmp @@loop1
@@l1:           mov ax,Pos1
                mov Pos2,ax
@@loop2:        call GetEvent
                cmp ah,Escape_
                jz @@Exit
                cmp ah,Enter_
                jz @@Copy
                call PosHandle
                call Buff2Scr
                call HighLight
                jmp @@loop2
@@Copy:         call TxtCopy
@@Exit:         call Buff2Scr
                mov ax,Pos2
                mov Pos1,ax
                mov es,ParentPtr.Segment_
                mov di,ParentPtr.Offset_
                mov ax,TextPtr
                mov es:[di.BufferEnd],ax
                mov ax,offset TxtBuffer
                mov es:[di.BufferPtr.Offset_],ax
                mov es:[di.BufferPtr.Segment_],cs
                ret
Snipp           endp

GetVideoBuff    proc near
                push ax es
                mov ax, 40h
                mov es, ax
                mov al, es:byte ptr 49h ; Video Mode
                mov bx,0B800h
                cmp al, 7
                jne @@done
@@Herc:         mov bx,0B000h
@@Done:         pop es ax
                ret
GetVideoBuff    endp

GetRowsNumber   proc near
                assume ds:cseg,es:nothing,cs:cseg
                push es ax
                mov ax, 40h
                mov es, ax
                mov dl, es:byte ptr 84h ; Rows on screen minus one
                pop ax es
                or dl, dl
                jne @@1
                mov dl, 24
@@1:            inc dl
                mov Rows,dl
                ret
GetRowsNumber   endp

Snipp_Init      proc far
                pushs <ds,es,di,si,bp,ax,bx,cx,dx>
                mov ax,cs
                mov es,ax
                assume es:cseg,ds:nothing
                mov ParentPtr.Offset_,si
                mov ParentPtr.Segment_,ds
                mov ds,ax
                assume ds:cseg
                dec ax
                mov es,ax
                assume es:nothing
                mov ax,es:[3] ; MCB.Length
                dec ax
                sh l,ax,4
                mov TxtBufferEnd,ax
                call GetVideoBuff
                mov ScreenSeg,bx
                mov ActivFlag,False
                mov TextPtr,0
                GetIntVec 9,Save09Vec
                SetIntVecProc 9,HandleBreak
                pops <dx,cx,bx,ax,bp,si,di,es,ds>
                retf
Snipp_Init      endp

Snipp_Done      Proc far
                pushs <ds,es,di,si,cx>
                mov ax,cs
                mov ds,ax
                assume ds:cseg
                mov ActivFlag,False
                SetIntVec 09h,Save09Vec
                pops <cx,si,di,es,ds>
                retf
Snipp_Done      endp

Snipp_ClearBuffer Proc far
                pushs <ds,ax>
                mov ax,cs
                mov ds,ax
                assume ds:cseg
                mov TextPtr,0
                pops <ax,ds>
                retf
Snipp_ClearBuffer endp

                even
ScrBuffer       dw 4000 dup (?)
TxtBuffer       db 2000h dup (?)
cseg            ends
                END

