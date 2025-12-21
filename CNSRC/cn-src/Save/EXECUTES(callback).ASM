                locals
                jumps
                .model small
                include strucs.mac
                include int1.mac
                include repeats.mac
                include exchtype.inc
                ;MsgRun = 1
                .stack 80h

                .data
Error1          db 'Incorrect DOS version.',13,10,'$'
Error2          db 'Memory alloc error.',13,10,'$'
public          Error2
Error3          db 'Invalid directory.',13,10,'$'
Error4          db 'Failed to load CONNECT.EXE.',13,10,'$'
Copyright       db 'The IBM HandShaker  Version 8.0 '
                db ' Copyright (c) 1991,05 KHEMZ Inc.',13,10,'$'
                PascalStr ConnectName,<CONNECT>
                ASCIIZString ConnectExeName,<CONNECT.EXE>
                DosStr <MyPath>
public          MyPath
                String <CMDStr>,128
                DosStr <ExecProg>

                PascalStr SetVar,<COMSPEC=>
                PascalStr CommOpt,</C >
                PascalStr SnippKey,</S>
                String <TempStr>,128
public          TempStr
Space           db 1,20h

PSPSeg          dw ?
ExchBuffer      ExchBufferType <?>
public          ExchBuffer
BuffPtr         db 10,1,2,3,4,5
BuffPtr_Ptr     Pointer <offset ExchBuffer,?>
                db 0dh
BuffPtrLen      equ $ - offset BuffPtr
Result          db true
Report          dw ?
STDOutHandler   dw ?
STDErrHandler   dw ?
SnippLoad       db False
SnippBuffSize   dw 16000
public          SnippBuffSize
extrn           IORes : Word

                .code

extrn           Exec : near
;function Exec(var MyPath : ASCIIZ; CMDStr : String; PSPSeg : Word) : Byte;

extrn           EnvStr : near
;procedure  EnvStr(var SetVar : PasString; var DStr : ASCIIZ; PSPSeg : Word);

extrn           GetProgStr : near
;Procedure GetProgStr(var MyPath : PasString; PSPSeg : Word);

extrn          PrintStr : near
;Procedure PrintStr(var OutStr : DosString);

extrn          FileCreate : near
;Procedure FileCreate(var FileStr : ASCIIZ, Handle : Word);

extrn          FileAppend : near
;Procedure FileAppnd (var FileStr : ASCIIZ; var Handle : Word);

extrn          LoadSnipp : near
;procedure LoadSnipp(Seg : Word);

extrn          GetDir : near
;Procedure GetDir(var DirStr : ASCIIZ);

extrn          SetDir : near
;Procedure SetDir(var NewDirStr : ASCIIZ);

extrn          FileClose : near
;Procedure FileClose(Handle : Word);

extrn          HandleDUP : near
;procedure HandleDUP(SHandler: Word; var DHandler: Word);

extrn          FORCDUP : near
;procedure FORCDUP(SHandler, DHandler: Word);

extrn          ASCIIZLen : near
;function ASCIIZLen(var ASCIIZStr : ASCIIZ) : Word

extrn          ConcatPasStr : near
;procedure ConcatPasStr(var SStr,DStr : PasStr)

extrn          PosStr : near
;function PosStr(var SubStr,ScanStr) : Byte;

extrn          UpStr : near
;procedure UpStr(Var Str);

extrn          Delete : near
;procedure Delete(var Str,Index,Count);

extrn          Buff_Size : near
;function Buff_Size(Var Str : String) : Word;

extrn          Init_Snipp : near


CopyASCIIZ macro
local l0
l0:             lodsb
                stosb
                or al,al
                jnz l0
endm

Start:          mov ax,@data
                mov ds,ax
                mov PSPSeg,es

                mov ah,30h
                int 21h
                cmp al,3h
                jnb AllocMem
                mov dx,offset Error1
                jmp Error_Mes ;Incorrect DOS version

AllocMem:       ;Release all memory except the amount currently being used
                ;end of stack is end of non-heap portion of program
                mov bx,sp
                add bx,15    ;convert sp into paragraphs
                shr bx,4
                mov ax,ss    ;calculate size of program using es PSP address
                add bx,ax
                mov ax,es
                sub bx,ax
                mov ah,4ah   ;resize memory block with PSP
                int 21h      ;address in es
                jnc PrintCopyr
                mov dx,offset Error2
                jmp Error_Mes ; Memory alloc error;
callback:
                db 0eah    ; jmp far + a16:a16:
callback_off:
                dw 0000h
callback_seg:
                dw 0000h
setup_callback:
                mov word ptr cs:callback_off, cx
                mov word ptr cs:callback_seg, dx
                mov dx, cs
                mov cx, offset callback
                iret
my_int_2f:
                cmp ax, 17ffh
                je setup_callback;
                cmp ah, 17h
                je oldapp_handler
                cmp ax, 168eh ; Windows95 - TITLE - SET APPLICATION TITLE
                je SetTitle
                db 0eah    ; jmp far + a16:a16:
old_int_2f_off:
                dw 0000h
old_int_2f_seg:
                dw 0000h
SetTitle:       mov ax, 21h ;cn_nt.dll SetTitle function
                mov bx, di  ; Title offset

oldapp_handler:
                push di     ; save di
                mov di, ax  ; use di to pass fct nr, as ax:
                db  0b8h    ; mov ax, + i16:
vdd_handle:
                dw  0000h

                dw  0c4c4h          ; ntcall:
                db  058h, 02h       ; DispatchCall
                pop di              ; restore di
                iret

vdd_name:       db 'CN_NT.DLL',0
vdd_init:       db 'CN_NT_InitVDD',0
vdd_disp:       db 'CN_NT_CallVDD',0

PrintCopyr:     mov ax,offset Copyright
                push ds
                push ax
                call PrintStr

                ; CN_NT installation check

                push ds
                push es
                mov ax, cs
                mov ds, ax
                mov es, ax

                mov ax,1700h
                push ax
                int 2Fh
                pop dx
                cmp ax,dx
                jne already_installed

                ; dos_get_true_version_number
                mov ax, 3306h
                int 21h

                cmp bx,03205h
                mov word ptr cs:old_int_2f_off, 0
                mov word ptr cs:old_int_2f_seg, 0
                jne not_on_nt

                ; RegisterModule()
                mov ax, cs
                mov si, offset vdd_name
                mov di, offset vdd_init
                mov bx, offset vdd_disp
                mov bp, offset callback
                dw 0c4c4h          ; ntcall:
                db 058h,000h       ; RegisterModule
                jc dll_not_load

init_ok:
                mov word ptr cs:vdd_handle, ax

                ;GetIntVec 2fh, OldInt2f
                mov ax,0352fh
                int 21h
                mov word ptr cs:old_int_2f_off, bx
                mov word ptr cs:old_int_2f_seg, es

                ;SetIntVecProc 2fh, my_int_2f
                mov ax, cs
                mov ds, ax
                mov dx, offset my_int_2f
                mov ax,0252fh
                int 21h
                clc
                jmp dll_ok

already_installed:
dll_not_load:
not_on_nt:
                stc
dll_ok:
                pop es
                pop ds
                mov ax, word ptr cs:vdd_handle
                mov ExchBuffer.CN_NT_Handler, ax
                jnc set_dll_ok
set_dll_err:
                and ExchBuffer.Options, not CN_NT
                jmp dll_next
set_dll_ok:
                or ExchBuffer.Options, CN_NT
dll_next:
                push es
                mov ax,80h
                push ax
                call UpStr

                push es
                mov ax,80h
                push ax
                call Buff_Size
                mov SnippBuffSize,ax

                push ds
                mov ax,offset SnippKey
                push ax
                push es
                mov ax,80h
                push ax
                call PosStr
                or al,al
                jz NoSnipKey
                push es
                mov bx,80h
                push bx
                xor ah,ah
                push ax
                mov ax,2
                push ax
                call Delete
                mov SnippLoad,True

NoSnipKey:      mov bx,80h
                add bl,byte ptr es:[bx]
                mov byte ptr es:[bx+1],0dh
                mov ax,offset MyPath
                push ds
                push ax

                push PSPSeg
                Call GetProgStr

                mov ax,offset ExchBuffer.OldDir
                push ds
                push ax
                call GetDir
                cmp IORes,0
                jz InitExchBuff
                mov dx,offset Error3
                jmp Error_Mes

InitExchBuff:   cld
                push ds
                pop es
                mov di,offset ExchBuffer.ProgrToExecute
                xor ax,ax
                stosb
                mov di,offset ExchBuffer.CmdLine
                stosb
                mov di,offset ExchBuffer.Source
                stosb
                mov di,offset ExchBuffer.Error
                stosb
                mov di,offset ExchBuffer.Options
                stosb
                mov di,offset ExchBuffer.SnippFlag
                stosb
                mov di,offset ExchBuffer.SnippInUse
                stosb
                mov di,offset ExchBuffer.TxtBufferEnd
                stosw

                mov si,offset MyPath
                push ds
                push si

                mov di,offset ExchBuffer.ConfigMask
                mov byte ptr ds:[di],al
                push ds
                push di
                call ConcatPasStr

                mov si,offset ConnectName
                push ds
                push si

                push ds
                push di
                call ConcatPasStr

                mov BuffPtr_Ptr.Segment_,ds

FullPath:       mov dx,es
                mov es,PSPSeg
                cmp byte ptr es:[80],116
                jbe @@1
                mov byte ptr es:[80],116
@@1:            push es
                mov es,dx
                mov ax,80h
                push ax

                mov ax,offset CMDStr
                push ds
                push ax
                call ConcatPasStr

BuffCopy:       mov ax,offset BuffPtr
                push ds
                push ax

                mov ax,offset CMDStr
                push ds
                push ax
                call ConcatPasStr

                mov si,offset MyPath
                mov di,offset ExecProg
                lodsb
                mov cl,al
                xor ch,ch
                rep movsb
                cmp  byte ptr es:[di-1],'\'
                je SlashPresent
                mov al,'\'
                stosb
SlashPresent:   mov si,offset ConnectExeName
                CopyASCIIZ

                cmp SnippLoad,true
                jne MainLoop
                mov ExchBuffer.SnippFlag,true
                call Init_Snipp

MainLoop:       mov ax,offset ExecProg
                push ds
                push ax

                mov ax,offset CMDStr
                push ds
                push ax

                push PSPSeg
                call Exec  ;Exec CONNECT.EXE
                or al,al
                jz ClearCMDStr
                mov dx,offset Error4
                jmp Error_Mes

ClearCMDStr:    mov ax,offset BuffPtr
                push ds
                push ax

                mov bx,offset CMDStr
                push ds
                push bx
                mov byte ptr ds:[bx],0
                call ConcatPasStr

                cmp ExchBuffer.ProgrToExecute,0
                je Quit

                test ExchBuffer.Options,RedirFlag
                jz NoRedirect

Redirect:       mov ax,offset ExchBuffer.ReportFile
                push ds
                push ax

                mov ax,offset Report
                push ds
                push ax
                ;call FileCreate
                call FileAppend
                cmp IORes,0
                je DUPHandler
                jmp ErrorRedir

DUPHandler:     mov ax,1
                push ax

                mov ax,offset STDOutHandler
                push ds
                push ax
                call HandleDUP
                cmp IORes,0
                je DUPFORC
                jmp ErrorRedir

DUPFORC:        push Report
                mov ax,1
                push ax
                call FORCDUP
                cmp IORes,0
                ;je CloseFile
                je DUPHandler2
                jmp ErrorRedir

DUPHandler2:
                test ExchBuffer.Options,RedirFlag2
                je CloseFile
                mov ax,2
                push ax

                mov ax,offset STDErrHandler
                push ds
                push ax
                call HandleDUP
                cmp IORes,0
                je DUPFORC2
                jmp ErrorRedir

DUPFORC2:       push Report
                mov ax,2
                push ax
                call FORCDUP
                cmp IORes,0
                je CloseFile
                jmp ErrorRedir

CloseFile:      push Report
                call FileClose
                mov ax,IORes
                mov ExchBuffer.Error,al
                or ax,ax ;cmp ax,0
                mov Result,true
                je NoRedirect
ErrorRedir:     mov Result,false
                mov ax,IORes
                mov ExchBuffer.Error,al
                jmp MainLoop

NoRedirect:     call Init_Snipp

                test ExchBuffer.Options, CommandFlag
                jne UseCommand

                mov ax,offset ExchBuffer.ProgrToExecute + 1
                push ds
                push ax

                mov ax,offset ExchBuffer.CmdLine
                push ds
                push ax
                jmp Execute

UseCommand:     mov ax,offset SetVar
                push ds
                push ax

                mov ax,offset Copyright
                push ds
                push ax

                push PSPSeg
                call EnvStr

                mov ax,offset CommOpt
                push ds
                push ax

                mov bx,offset TempStr
                mov byte ptr ds:[bx],0
                push ds
                push bx
                call ConcatPasStr

                mov ax,offset ExchBuffer.ProgrToExecute
                push ds
                push ax

                mov ax,offset TempStr
                push ds
                push ax
                call ConcatPasStr

                mov ax,offset Space
                push ds
                push ax

                mov ax,offset TempStr
                push ds
                push ax
                call ConcatPasStr

                mov ax,offset ExchBuffer.CmdLine
                push ds
                push ax

                mov ax,offset TempStr
                push ds
                push ax
                call ConcatPasStr

                mov ax,offset Copyright
                push ds
                push ax

                mov ax,offset TempStr
                push ds
                push ax

Execute:        push PSPSeg
                call Exec
                mov IORes,ax
                mov ExchBuffer.Error,al
                or al,al ;cmp al,0
                jne MainLoop
                test ExchBuffer.Options,RedirFlag
                jz MainLoop

                push STDOutHandler
                mov ax,1
                push ax
                call FORCDUP

                push STDOutHandler
                call FileClose
                mov ax,IORes
                mov ExchBuffer.Error,al

                test ExchBuffer.Options,RedirFlag2
                je MainLoop

                push STDErrHandler
                mov ax,2
                push ax
                call FORCDUP

                push STDErrHandler
                call FileClose
                mov ax,IORes
                mov ExchBuffer.Error,al
                jmp MainLoop

Error_Mes:      mov  ah,9
public          Error_Mes
                int  21h
Quit:
                cmp word ptr cs:old_int_2f_off, 0
                jne @@ll1
                cmp word ptr cs:old_int_2f_seg, 0
                je @@ll2

@@ll1:
                ;SetIntVec 2fh, OldInt2f

                push ds
                mov dx, word ptr cs:old_int_2f_off
                mov ax, word ptr cs:old_int_2f_seg
                mov ds, ax
                mov ax,0252fh
                int 21h

                mov si, offset vdd_name
                mov di, offset vdd_init
                mov bx, offset vdd_disp
                mov ax, word ptr cs:vdd_handle

                dw 0c4c4h          ; ntcall:
                db 058h,01h        ; UnRegisterModule

                pop ds

@@ll2:
                cmp ExchBuffer.SnippInUse,True
                jne @@L1
                call dword ptr ExchBuffer.Snipp_Done
                push es
                mov ah,49h ; free memory
                mov es,ExchBuffer.Snipp_Init.Segment_
                int 21h
                pop es
                jnc @@L1
                mov dx,offset Error2
                jmp Err_Msg ; Memory alloc error;

@@L1:           mov ax,offset ExchBuffer.OldDir
                push ds
                push ax
                call SetDir
                cmp IORes,0
                mov dx,offset Error3
                jne Err_Msg

                mov  ax,4c00h
                int  21h
Err_Msg:        mov  ah,9
                int  21h
                mov  ax,4c01h
                int  21h
end             start