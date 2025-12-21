
; *******************************************************
; *                                                     *
; *     Turbo Pascal Runtime Library Version 6.0        *
; *     CRT Interface Unit                              *
; *                                                     *
; *     Copyright (C) 1988,91 Borland International     *
; *                                                     *
; *******************************************************

        TITLE   CNCRT
        locals
        jumps
;        INCLUDE SE.ASM

; Coordinate record


; BIOS workspace equates

Timer           EQU     (DWORD PTR 6CH)

DATA    SEGMENT WORD PUBLIC

; Local workspace

DelayCnt        DW      ?
ScanCode        DB      ?
DATA    ENDS

CODE    SEGMENT BYTE PUBLIC

        ASSUME  CS:CODE,DS:DATA

; Externals

        PUBLIC  Delay, Sound, NoSound
        PUBLIC  KeyPressed, ReadKey, DelayInit

; One-time initialization

DelayInit:
        MOV     ax, 40h
        MOV     ES, ax
        MOV     DI,OFFSET Timer
        MOV     BL,ES:[DI]
@@2:    CMP     BL,ES:[DI]
        JE      @@2
        MOV     BL,ES:[DI]
        MOV     AX,-28
        CWD
        CALL    DelayLoop
        NOT     AX
        NOT     DX
        MOV     CX,55
        cmp     dx,55
        jb      @@3
        mov     ax,-1
        jmp     @@4
@@3:    DIV     CX
@@4:    MOV     DelayCnt,AX
        RETF

; Delay specified number of milliseconds

Delay:

        MOV     BX,SP
        MOV     CX,SS:[BX+4]
        JCXZ    @@2
        mov     ax, 40h
        MOV     ES, ax
        XOR     DI,DI
        MOV     BL,ES:[DI]
@@1:    MOV     AX,DelayCnt
        XOR     DX,DX
        CALL    DelayLoop
        LOOP    @@1
@@2:    RETF    2

; Delay one timer tick or by CX iterations

DelayLoop:

@@1:    SUB     AX,1
        SBB     DX,0
        JC      @@2
        CMP     BL,ES:[DI]
        JE      @@1
@@2:    RET

; Start sound generator

Sound:

        MOV     BX,SP
        MOV     BX,SS:[BX+4]
        MOV     AX,34DDH
        MOV     DX,0012H
        CMP     DX,BX
        JNC     @@2
        DIV     BX
        MOV     BX,AX
        IN      AL,61H
        TEST    AL,3
        JNZ     @@1
        OR      AL,3
        OUT     61H,AL
        MOV     AL,0B6H
        OUT     43H,AL
@@1:    MOV     AL,BL
        OUT     42H,AL
        MOV     AL,BH
        OUT     42H,AL
@@2:    RETF    2

; Turn off sound generator

NoSound:

        IN      AL,61H
        AND     AL,0FCH
        OUT     61H,AL
        RETF

; Return true if key is available

KeyPressed:

        CMP     ScanCode,0
        JNE     @@1
        MOV     AH,1
        INT     16H
        MOV     AL,0
        JE      @@2
@@1:    MOV     AL,1
@@2:    RETF

; Read character from keyboard
; Out   AL = Character

ReadKey:

        MOV     AL,ScanCode
        MOV     ScanCode,0
        OR      AL,AL
        JNE     @@1
        XOR     AH,AH
        INT     16H
        OR      AL,AL
        JNE     @@1
        MOV     ScanCode,AH
        OR      AH,AH
        JNE     @@1
        MOV     AL,'C'-64
@@1:
        RETF


CODE    ENDS

        END
