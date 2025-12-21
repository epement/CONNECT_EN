;******************************************************
;                  DICTION.ASM 7.00
;     Copyright (c) TurboPower Software 1988, 1993.
;                All rights reserved.
;******************************************************

;       DICTION.ASM
;       Primitive string routines for DICTION unit

DATA    SEGMENT BYTE PUBLIC

DATA    ENDS

CODE    SEGMENT BYTE PUBLIC

        ASSUME  CS:CODE,DS:DATA

        PUBLIC  FastUpcase
        PUBLIC  Hash

;****************************************************** FastUpcase

;procedure FastUpcase(var S : string);

;Fast uppercasing routine for a string.

;equates for parameters:
S       EQU     DWORD PTR [BP+4]

FastUpcase    PROC NEAR

        PUSH    BP                      ;Save BP
        MOV     BP,SP                   ;Set up stack frame
        MOV     DX,DS                   ;Save DS in DX

        LDS     SI,S                    ;DS:SI points to string
        CLD                             ;Go forward
        XOR     AH,AH                   ;Clear AH
        LODSB                           ;Length into AX
        MOV     CX,AX                   ;Length into CX
        JCXZ    FUDone                  ;Done if CX = 0

        MOV     AX,DS                   ;AX = DS
        MOV     ES,AX                   ;ES = DS
        MOV     DI,SI                   ;ES:DI points to S[1]

        MOV     AH,0DFh                 ;AH = UpCase mask
        MOV     BH,'z'                  ;BH = 'z'
        MOV     BL,'a'                  ;BL = 'a'

FUNext: LODSB                           ;Next char into AL
        CMP     AL,BL                   ;AL < 'a'?
        JB      FUNoStore               ;If so, don't change the char
        CMP     AL,BH                   ;AL > 'z'?
        JA      FUNoStore               ;If so, don't change the char
        AND     AL,AH                   ;Else, convert to uppercase
        STOSB                           ;Store the converted character
        LOOP    FUNext                  ;Repeat if CX <> 0
        JMP     FUDone                  ;Done if CX = 0

FUNoStore:
        INC     DI                      ;Skip this character
        LOOP    FUNext                  ;Repeat if CX <> 0

FUDone:
        MOV     DS,DX                   ;Restore DS from DX
        MOV     SP,BP                   ;Restore SP
        POP     BP                      ;Restore BP
        RET     4                       ;Remove parameters and return

FastUpcase    ENDP

;****************************************************** Hash

;function Hash(MaxHash : Word; var s : string) : word;

;Compute a simple hash function of a string
; Thanks to James H. Cowden for an improvement to this hash function

;equates for parameters:
MaxHash EQU     WORD PTR [BP+8]
S       EQU     DWORD PTR [BP+4]
MagicFactor EQU 13H

Hash    PROC NEAR

        PUSH    BP                      ;Save BP
        MOV     BP,SP                   ;Set up stack frame
        PUSH    DS                      ;Save DS
        XOR     BX,BX                   ;Sum kept in BX

        LDS     SI,S                    ;DS:SI points to string
        CLD                             ;Go forward
        LODSB                           ;Length into AX
        XOR     AH,AH                   ;Clear top byte
        MOV     CX,AX                   ;Length into CX
        JCXZ    HDone                   ;Done if CX = 0

HNext:  LODSB                           ;Next char into AL
        ADD     BX,AX                   ;Sum into BX
        LOOP    HNext

HDone:  MOV     AX,BX                   ;Sum into AX
        MOV     BX,MagicFactor          ;Reduce hash probes with magic factor
        MUL     BX
        XOR     DX,DX                   ;Clear top word of sum
        MOV     BX,MaxHash              ;Get the modulus
        DIV     BX                      ;Compute MOD
        MOV     AX,DX                   ;Remainder into AX for function result

        POP     DS                      ;Restore DS
        MOV     SP,BP                   ;Restore SP
        POP     BP                      ;Restore BP
        RET     6                       ;Remove parameters and return

Hash    ENDP


CODE    ENDS

        END
