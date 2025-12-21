                jumps
                locals
                .model Small
                include strucs.mac
public          PrintStr
;Procedure PrintStr(var OutStr : DosString);

public          FileAppend
;Procedure FileAppnd (var FileStr : ASCIIZ; var Handle : Word);

;public          FileCreate
;Procedure FileCreate (var FileStr : ASCIIZ; var Handle : Word);

Public           FileOpen
;Procedure FileOpen (var FileStr : ASCIIZ; var Handle : Word,Mode: Word);

public          GetDir
;Procedure GetDir(var DirStr : ASCIIZ);

public          SetDir
;Procedure SetDir(var NewDirStr : ASCIIZ);

public          FileClose
;Procedure FileClose(Handle : Word);

public          HandleDUP
;procedure HandleDUP(SHandler: Word; var DHandler: Word);

public          FORCDUP
;procedure FORCDUP(SHandler, DHandler: Word);

public          IORes

                .data
IORes           dw ?
                .code

ResultIO Macro
                jnc $ + 5
                mov IORes,ax
endm

PrintStr        proc near
;Procedure PrintStr(var OutStr : DosString);
arg @@OutStr : DWord = @@ParamSize
                push bp
                mov bp,sp
                push ds
                lds dx,@@OutStr
                mov ah,9
                int 21h
                pop ds
                mov IORes,0
                mov sp,bp
                pop bp
                ret @@ParamSize
PrintStr        endp

GetDir          proc near
;Procedure GetDir(var DirStr : ASCIIZ);
@@DirStr        equ [bp + 4]
                push bp
                mov bp,sp
                mov IORes,0
                mov ah,19h ;GetCurDrive
                int 21h
                ResultIO
                jc @@Error
                add al,'A'
                les di,@@DirStr
                stosb
                mov ax,'\:'
                stosw
                push ds
                lds si,@@DirStr
                mov si,di
                mov ah,47h
                xor dl,dl ;mov dl,0
                int 21h
                pop ds
                ResultIO
@@Error:        mov sp,bp
                pop bp
                ret 4
GetDir          endp

SetDir          proc near
;Procedure SetDir(var NewDirStr : ASCIIZ);
@@NewDirStr     equ [bp + 4]
                push bp
                mov bp,sp
                push ds
                lds dx,@@NewDirStr
                mov bx,dx
                mov ah,0eh
                mov dl,byte ptr ds:[bx]
                sub dl,'A'
                int 21h
                mov dx,bx
                mov ah,3bh
                int 21h
                pop ds
                ResultIO
                mov sp,bp
                pop bp
                ret 4
SetDir          endp
comment~
FileCreate      proc near
;Procedure FileCreate (var FileStr : ASCIIZ; var Handle : Word);
arg @@Handle : DWord,@@FileStr : DWord = @@ParamSize
                push bp
                mov bp,sp
                push ds
                lds dx,@@FileStr
                mov ah,3ch
                mov cx,20h
                int 21h
                lds bx,@@Handle
                mov word ptr ds:[bx],ax
                pop ds
                ResultIO
                mov sp,bp
                pop bp
                ret @@ParamSize
FileCreate      endp
~
FileAppend      proc near
;Procedure FileAppnd (var FileStr : ASCIIZ; var Handle : Word);
arg @@Handle : DWord,@@FileStr : DWord = @@ParamSize
                push bp
                mov bp,sp
                push ds
                lds dx,@@FileStr
                mov ax,2
                mov ah,3dh
                int 21h
                jc @@Create
                push ax
                mov bx,ax
                mov ax,4202h
                xor cx,cx
                xor dx,dx
                int 21h
                pop ax
                jmp @@1
@@Create:       lds dx,@@FileStr
                mov ah,3ch
                mov cx,20h
                int 21h
@@1:            lds bx,@@Handle
                mov word ptr ds:[bx],ax
                pop ds
                ResultIO
                mov sp,bp
                pop bp
                ret @@ParamSize
FileAppend      endp

FileOpen        proc near
;Procedure FileOpen (var FileStr : ASCIIZ; var Handle : Word,Mode: Word);
arg @@Mode : word,@@Handle : DWord,@@FileStr : DWord = @@ParamSize
                push bp
                mov bp,sp
                push ds
                lds dx,@@FileStr
                mov ax,@@Mode
                mov ah,3dh
                int 21h
                lds bx,@@Handle
                mov word ptr ds:[bx],ax
                pop ds
                ResultIO
                mov sp,bp
                pop bp
                ret @@ParamSize
FileOpen        endp

FileClose       proc near
;Procedure FileClose(Handle : Word);
arg @@Handle : Word = @@ParamSize
@@LocalSize = 0
                BeginProc @@LocalSize
                mov ah,3eh
                mov bx,@@Handle
                int 21h
                ResultIO
                EndProc @@ParamSize
FileClose       endp

HandleDUP       proc near
;procedure HandleDUP(SHandler: Word; var DHandler: Word);
arg @@DHandler : DWord, @@SHandler : Word =@@ParamSize
@@LocalSize = 0
                BeginProc @@LocalSize
                mov ah,45h
                mov bx,@@SHandler
                int 21h
                push ds
                lds bx,@@DHandler
                mov word ptr ds:[bx],ax
                pop ds
                ResultIO
                EndProc @@ParamSize
HandleDUP       endp

FORCDUP         proc near
;procedure FORCDUP(SHandler, DHandler: Word);
@@DHandler      equ [bp + 4]
@@SHandler      equ [bp + 6]
                push bp
                mov bp,sp
                mov ah,46h
                mov bx,@@SHandler
                mov cx,@@DHandler
                int 21h
                ResultIO
                mov sp,bp
                pop bp
                ret 4
FORCDUP         endp
                end
