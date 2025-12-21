                model TINY
                JUMPS
                locals
cseg            segment word public 'code'
                assume cs:cseg

; Keyboard shift flags

kbShiftKey      EQU     03H
kbCtrlKey       EQU     04H
kbAltKey        EQU     08H
KeyFlags        EQU     (BYTE PTR 17H)
KeyBufHead      EQU     (WORD PTR 1AH)
KeyBufTail      EQU     (WORD PTR 1CH)
KeyBufOrg       EQU     (WORD PTR 1EH)
KeyBufEnd       EQU     (WORD PTR 3EH)

OldInt09        DD      0       ;Saved INT 09H vector
KeyCode         dw 0
Int09Handler:

        PUSH    DS
        PUSH    AX
        MOV     AX,40H
        MOV     DS,AX
        IN      AL,60H
        MOV     AH,DS:KeyFlags

        mov KeyCode, ax

        PUSHF
        CALL    OldInt09
        pop     ax
        POP     DS
        IRET
cseg            ends

end
