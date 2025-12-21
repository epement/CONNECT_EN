                locals
                jumps
                .model small
                include strucs.mac
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
Copyright       db 'The Intel 8080 Debugger  Version 1.0 '
                db ' Copyright (c) 1991,93 KHEMZ Inc.',13,10,'$'
                PascalStr ConnectName,<DEBUG80>
                ASCIIZString ConnectExeName,<DEBUG80.EXE>
                DosStr <MyPath>
public          MyPath
                String <CMDStr>,128
                DosStr <ExecProg>
                DosStr <OldDir>
                PascalStr SetVar,<COMSPEC=>
ifdef MsgRun
                PascalStr RunMsg,<Running >
LineTerm        db 3,13,10,'$'
endif
                PascalStr CommOpt,</C>
                PascalStr SnippKey,</S>
                String <TempStr>,128
public          TempStr
Space           db 1,20h

ReportExt       db 5,'.RPT',0
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

;extrn          FileCreate : near
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
                or al,al ;cmp al,0
                jnz l0
endm

Start:          mov  ax,@data
                mov  ds,ax
                mov PSPSeg,es

                mov ah,30h
                int 21h
                cmp al,3h
                jnb AllocMem
                mov dx,offset Error1
                jmp Error_Mes ;Incorrect DOS version

AllocMem:       ;mov ah,4ah
                ;mov bx,0e2h; 0F3h; 3888 byets
                ;int 21h  ; Realloc PSP Seg
                ;Release all memory except the amount currently being used
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

PrintCopyr:     mov ax,offset Copyright
                push ds
                push ax
                call PrintStr

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

                mov ax,offset OldDir
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
                mov di,offset ExchBuffer.RedirectFlag
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

                cmp ExchBuffer.RedirectFlag,true
                je Redirect
                jmp NoRedirect

Redirect:
ifdef MsgRun
                mov ax,offset RunMsg
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

                mov ax,offset LineTerm
                push ds
                push ax

                mov ax,offset TempStr
                push ds
                push ax
                call ConcatPasStr

                mov ax,offset TempStr+1
                push ds
                push ax
                call PrintStr
endif
                mov ax,offset ExchBuffer.ConfigMask
                push ds
                push ax

                mov bx,offset TempStr
                push ds
                push bx
                mov byte ptr ds:[bx],0
                call ConcatPasStr

                mov ax,offset ReportExt
                push ds
                push ax

                mov ax,offset TempStr
                push ds
                push ax
                call ConcatPasStr

                mov ax,offset TempStr+1
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

                mov ax,offset SetVar
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

                push PSPSeg
                call Exec
                mov IORes,ax
                mov ExchBuffer.Error,al
                or al,al ;cmp al,0
                jne MainLoop
                cmp ExchBuffer.RedirectFlag,true
                jne MainLoop

                push STDOutHandler
                mov ax,1
                push ax
                call FORCDUP

                push STDOutHandler
                call FileClose
                mov ax,IORes
                mov ExchBuffer.Error,al
                jmp MainLoop
Error_Mes:      mov  ah,9
public          Error_Mes
                int  21h
                mov  ax,4c01h
                int  21h
Quit:           cmp ExchBuffer.SnippInUse,True
                jne @@L1
                call dword ptr ExchBuffer.Snipp_Done
                push es
                mov ah,49h ; free memory
                mov es,ExchBuffer.Snipp_Init.Segment_
                int 21h
                pop es
                jnc @@L1
                mov dx,offset Error2
                jmp Error_Mes ; Memory alloc error;
@@L1:           mov ax,offset OldDir
                push ds
                push ax
                call SetDir
                cmp IORes,0
                mov dx,offset Error3
                jne Error_Mes
                mov  ax,4c00h
                int  21h
end             start

