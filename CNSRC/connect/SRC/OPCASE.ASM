;******************************************************
;                  OPCASE.ASM 1.10
;              String handling routines
;     Copyright (c) TurboPower Software 1987, 1989.
;                All rights reserved.
;******************************************************

        INCLUDE OPCOMMON.ASM

;****************************************************** Code

CODE    SEGMENT BYTE PUBLIC

        ASSUME  CS:CODE
        PUBLIC  UpCaseMap
        PUBLIC  LoCaseMap
        PUBLIC  Upcase, Locase
        PUBLIC  StUpcase, StLocase
        PUBLIC  UpcaseSt, LocaseSt
        PUBLIC  UpCasePrim, LoCasePrim
        PUBLIC  MoveFast

;****************************************************** DefaultUpcase
;!!.02 new routine
;Works with Code Page 437, the standard U.S. character set
;Entry : character to upcase in AL, assumed >=#128
;Exit  : uppercase in AL
;        BX wiped out

UpCaseMap LABEL BYTE                    ;Maps international characters
                                        ;#0..#255
        db 000h,001h,002h,003h,004h,005h,006h,007h ; 0
        db 008h,009h,00ah,00bh,00ch,00dh,00eh,00fh
        db 010h,011h,012h,013h,014h,015h,016h,017h ; 1
        db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
        db 020h,021h,022h,023h,024h,025h,026h,027h ; 2
        db 028h,029h,02Ah,02Bh,02Ch,02Dh,02Eh,02Fh
        db 030h,031h,032h,033h,034h,035h,036h,037h ; 3
        db 038h,039h,03Ah,03Bh,03Ch,03Dh,03Eh,03Fh
        db 040h,041h,042h,043h,044h,045h,046h,047h ; 4
        db 048h,049h,04Ah,04Bh,04Ch,04Dh,04Eh,04Fh
        db 050h,051h,052h,053h,054h,055h,056h,057h ; 5
        db 058h,059h,05Ah,05Bh,05Ch,05Dh,05Eh,05Fh
        db 060h,041h,042h,043h,044h,045h,046h,047h ; 6
        db 048h,049h,04Ah,04Bh,04Ch,04Dh,04Eh,04Fh
        db 050h,051h,052h,053h,054h,055h,056h,057h ; 7
        db 058h,059h,05Ah,07Bh,07Ch,07Dh,07Eh,07Fh
        db 080h,081h,082h,083h,084h,085h,086h,087h ; 8
        db 088h,089h,08Ah,08Bh,08Ch,08Dh,08Eh,08Fh
        db 090h,091h,092h,093h,094h,095h,096h,097h ; 9
        db 098h,099h,09Ah,09Bh,09Ch,09Dh,09Eh,09Fh
        db 080h,081h,082h,083h,084h,085h,086h,087h ; A
        db 088h,089h,08Ah,08Bh,08Ch,08Dh,08Eh,08Fh
        db 0B0h,0B1h,0B2h,0B3h,0B4h,0B5h,0B6h,0B7h ; B
        db 0B8h,0B9h,0BAh,0BBh,0BCh,0BDh,0BEh,0BFh
        db 0C0h,0C1h,0C2h,0C3h,0C4h,0C5h,0C6h,0C7h ; C
        db 0C8h,0C9h,0CAh,0CBh,0CCh,0CDh,0CEh,0CFh
        db 0D0h,0D1h,0D2h,0D3h,0D4h,0D5h,0D6h,0D7h ; D
        db 0D8h,0D9h,0DAh,0DBh,0DCh,0DDh,0DEh,0DFh
        db 090h,091h,092h,093h,094h,095h,096h,097h ; E
        db 098h,099h,09Ah,09Bh,09Ch,09Dh,09Eh,09Fh
        db 0F0h,0F0h,0F2h,0F3h,0F4h,0F5h,0F6h,0F7h ; F
        db 0F8h,0F9h,0FAh,0FBh,0FCh,0FDh,0FEh,0FFh

DefaultUpcase PROC FAR
        MOV     BX,OFFSET UpCaseMap
        XLAT    CS:[BX]                 ;Use map table
        RET
DefaultUpcase ENDP

;****************************************************** UpcasePrim
;!!.02 modified for generalized international uppercasing function
;Entry : character to upcase in AL
;Exit  : uppercase in AL

UpcasePrim PROC FAR
UpcasePrimNear:                         ;!!.02
        push    bx
        MOV     BX,OFFSET UpCaseMap
        XLAT    CS:[BX]                 ;Use map table
        pop     bx
        RET
UpcasePrim ENDP

;****************************************************** Upcase

;function UpCase(Ch : Char) : Char;
;Return uppercase of char, with international character support

UpCase  PROC    FAR
        MOV     BX,SP
        MOV     AL,SS:[BX+4]            ;AL = input character
        PUSH    CS                      ;!!.02
        CALL    UpcasePrimNear          ;!!.02
        RET     2
UpCase  ENDP

;****************************************************** LocasePrim

;Entry : character to locase in AL
;Exit  : lowercase in AL
;        BX wiped out

LoCaseMap LABEL BYTE                    ;Maps international characters
                                        ;#0..#255
        db 000h,001h,002h,003h,004h,005h,006h,007h ; 0
        db 008h,009h,00ah,00bh,00ch,00dh,00eh,00fh
        db 010h,011h,012h,013h,014h,015h,016h,017h ; 1
        db 018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
        db 020h,021h,022h,023h,024h,025h,026h,027h ; 2
        db 028h,029h,02Ah,02Bh,02Ch,02Dh,02Eh,02Fh
        db 030h,031h,032h,033h,034h,035h,036h,037h ; 3
        db 038h,039h,03Ah,03Bh,03Ch,03Dh,03Eh,03Fh
        db 040h,061h,062h,063h,064h,065h,066h,067h ; 4
        db 068h,069h,06Ah,06Bh,06Ch,06Dh,06Eh,06Fh
        db 070h,071h,072h,073h,074h,075h,076h,077h ; 5
        db 078h,079h,07Ah,05Bh,05Ch,05Dh,05Eh,05Fh
        db 060h,061h,062h,063h,064h,065h,066h,067h ; 6
        db 068h,069h,06Ah,06Bh,06Ch,06Dh,06Eh,06Fh
        db 070h,071h,072h,073h,074h,075h,076h,077h ; 7
        db 078h,079h,07Ah,07Bh,07Ch,07Dh,07Eh,077h
        db 0A0h,0A1h,0A2h,0A3h,0A4h,0A5h,0A6h,0A7h ; 8
        db 0A8h,0A9h,0AAh,0ABh,0ACh,0ADh,0AEh,0AFh
        db 0E0h,0E1h,0E2h,0E3h,0E4h,0E5h,0E6h,0E7h ; 9
        db 0E8h,0E9h,0EAh,0EBh,0ECh,0EDh,0EEh,0EFh
        db 0A0h,0A1h,0A2h,0A3h,0A4h,0A5h,0A6h,0A7h ; A
        db 0A8h,0A9h,0AAh,0ABh,0ACh,0ADh,0AEh,0AFh
        db 0B0h,0B1h,0B2h,0B3h,0B4h,0B5h,0B6h,0B7h ; B
        db 0B8h,0B9h,0BAh,0BBh,0BCh,0BDh,0BEh,0BFh
        db 0C0h,0C1h,0C2h,0C3h,0C4h,0C5h,0C6h,0C7h ; C
        db 0C8h,0C9h,0CAh,0CBh,0CCh,0CDh,0CEh,0CFh
        db 0D0h,0D1h,0D2h,0D3h,0D4h,0D5h,0D6h,0D7h ; D
        db 0D8h,0D9h,0DAh,0DBh,0DCh,0DDh,0DEh,0DFh
        db 0E0h,0E1h,0E2h,0E3h,0E4h,0E5h,0E6h,0E7h ; E
        db 0E8h,0E9h,0EAh,0EBh,0ECh,0EDh,0EEh,0EFh
        db 0F1h,0F1h,0F2h,0F3h,0F4h,0F5h,0F6h,0F7h ; F
        db 0F8h,0F9h,0FAh,0FBh,0FCh,0FDh,0FEh,0FFh

LoCasePrim PROC FAR
LoCasePrimNear:                         ;!!.02
        push    bx
        MOV     BX,OFFSET LoCaseMap
        XLAT    CS:[BX]                 ;Use map table
        pop     bx
        RET
LoCasePrim ENDP

;****************************************************** Locase

;function Locase(Ch : Char) : Char;
;Return lowercase of char, with international character support

LoCase  PROC    FAR
        MOV     BX,SP
        MOV     AL,SS:[BX+4]            ;AL = input character
        PUSH    CS                      ;!!.02
        CALL    LoCasePrimNear          ;!!.02
        RET     2
LoCase  ENDP

;****************************************************** StLocase

;function StLocase(S : string) : string;
;Convert upper case letters in string to lower case

StLocase PROC FAR
         ;MOV     DX,OFFSET LocasePrim
         MOV     DX,OFFSET LoCaseMap
         JMP     SHORT StCaseNear
StLocase ENDP

;****************************************************** StUpcase

;function StUpcase(S : string) : string;
;Convert lower case letters in string to upper case

StUpcase PROC FAR
         ;MOV     DX,OFFSET UpcasePrim
         MOV     DX,OFFSET UpCaseMap
         ; falls through into StCase
StUpcase ENDP

;****************************************************** StCase
;Convert string to one case or another, depending on DX
StCase  PROC    FAR
StCaseNear:
        StackFrame
        PUSH    DS
        CLD                             ;go forward
        LDS     SI,SS:[BX+4]            ;DS:SI => S
        LES     DI,SS:[BX+8]            ;ES:DI => function result
        mov     bx,dx
        LODSB                           ;AL = Length(S)
        STOSB                           ;Set length of result
        SetZero CH                      ;CH = 0
        MOV     CL,AL                   ;CX = Length(S)
        JCXZ    SUDone                  ;Done if CX is 0
SUNext:
        LODSB                           ;Next char into AL
;        PUSH    CS                      ;Fake a FAR CALL
;        CALL    DX                      ;Uppercase it
        xlat    cs:[bx]
        STOSB                           ;Store char in result
        LOOP    SUNext                  ;repeat
SUDone:
        POP     DS
        RET     4
StCase  ENDP
;******************************************************
LocaseSt PROC FAR
         MOV     DX,OFFSET LoCaseMap
         JMP     SHORT CaseNearSt
LocaseSt ENDP

;****************************************************** StUpcase

;procedure UpcaseSt(var S : string);
;Convert lower case letters in string to upper case

UpcaseSt PROC FAR
         MOV     DX,OFFSET UpCaseMap
         ; falls through into StCase
UpcaseSt ENDP

;****************************************************** CaseSt
;Convert string to one case or another, depending on DX
CaseSt  PROC    FAR
CaseNearSt:
        StackFrame
        PUSH    DS
        CLD                             ;go forward
        LDS     SI,SS:[BX+4]            ;DS:SI => S
        mov     bx,dx
        LODSB                           ;AL = Length(S)
        SetZero CH                      ;CH = 0
        MOV     CL,AL                   ;CX = Length(S)
        JCXZ    SUDoneSt                ;Done if CX is 0
SUNextSt:
        mov     al,[si]
        xlat    cs:[bx]
        mov     [si],al
        inc     si
        LOOP    SUNextSt                ;repeat
SUDoneSt:
        POP     DS
        RET     4
CaseSt  ENDP

;****************************************************** MoveFast

; procedure MoveFast(var Src, Dest; Count : Word);
; Move Count bytes from Src to Dest

; Thanks to Pat Ritchey for portions of this routine

mfSrc   EQU     DWORD PTR [BP+12]
mfDest  EQU     DWORD PTR [BP+8]
mfCount EQU     WORD PTR [BP+6]

MoveFast        PROC FAR

        PUSH    BP                      ;set up stack frame
        MOV     BP,SP
        PUSH    DS                      ;save DS
        LDS     SI,mfSrc                ;DS:SI => Src
        LES     DI,mfDest               ;ES:DI => Dest
        MOV     CX,mfCount              ;CX    =  Count
        JCXZ    mfDone                  ;Do nothing if CX = 0
        MOV     BX,DS                   ;Isolate high nibble of the 20-bit
        MOV     DX,ES                   ;addresses in ES:DI and DS:SI
        MOV     AH,BH                   ;into AH and AL -- this compares the
        MOV     AL,DH                   ;top 4 bits of the 20-bit address
        AND     AX,0F0F0h
        CMP     AH,AL                   ;Compare high nibbles
        JA      mfForward               ;Go forward if source is higher
        JB      mfReverse               ;Go backward if source is below dest
        PUSH    CX                      ;High nibbles of segments are equal--
        MOV     CX,4                    ;merge SI and DI with the remaining
        SHL     BX,CL                   ;12 bits of ES and DI so we can
        SHL     DX,CL                   ;compare the last 16 bits of the
        POP     CX                      ;20-bit addresses
        ADD     BX,SI
        ADD     DX,DI
        CMP     BX,DX                   ;Is source above dest?
        JA      mfForward               ;If so, go forward
mfReverse:
        STD                             ;go backward
        ADD     SI,CX                   ;point just beyond the ends
        ADD     DI,CX
        DEC     SI                      ;point to the actual ends
        DEC     DI
        TEST    DI,1                    ;is destination offset odd?
        JNZ     mfRevWord
        MOVSB                           ;move the odd byte
        DEC     CX                      ;decrement loop count
mfRevWord:
        DEC     SI                      ;point to the beginning of the word
        DEC     DI
        SHR     CX,1                    ;CX = words to move
        REP     MOVSW
        JNC     mfDone                  ;is there an odd byte to move?
        INC     SI                      ;point to the next byte
        INC     DI
        JMP     SHORT mfOddByte
mfForward:
        CLD                             ;go forward
        TEST    DI,1                    ;is destination offset odd?
        JZ      mfForWord
        MOVSB                           ;move the odd byte
        DEC     CX                      ;decrement loop count
mfForWord:
        SHR     CX,1                    ;CX = words to move
        REP     MOVSW
        JNC     mfDone                  ;is there an odd byte to move?
mfOddByte:
        MOVSB                           ;move the odd byte
mfDone:
        POP     DS                      ;restore DS
        POP     BP                      ;restore BP
        RET     10

MoveFast        ENDP

CODE    ENDS

        END
