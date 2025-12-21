                .MODEL   TPASCAL
                jumps
                locals
                .CODE
                PUBLIC   RPos, FPos, RIPos, FIPos, Count, DelChar, ReplaceChar

; function RPos(SubStr,Str : String) : Byte;
RPos            PROC FAR @@SubStr_: DWORD, @@Str_ : DWORD
                PUSH    DS
                LDS     SI,@@SubStr_
                LES     DI,@@Str_
                MOV     CL,ES:[DI]
                XOR     CH,CH
                JCXZ    @@3
                add     di,cx
                cld
                LODSB
                CMP     AL,1
                JB      @@5 ;{Exit}
                JA      @@1
                LODSB
                std
                REPNE   SCASB
                JNE     @@3
                inc     DI
                JMP     @@5
@@1:            XOR     AH,AH   ;{ax = Length(SubStr)}
                add     si,ax
                dec     si
                std
                MOV     DX,CX   ;{cx = Length(Str)}
                SUB     DX,AX   ;{dx = Length(Str) - Length(SubStr)}
                JB      @@3
                INC     DX
@@2:            MOV     CX,AX
                REP     CMPSB
                JE      @@4
                SUB     CX,AX
                sub     SI,CX
                sub     DI,CX
                dec     DI
                DEC     DX
                JNE     @@2
@@3:            XOR     AX,AX
                JMP     @@6
@@4:            inc     di
@@5:            MOV     AX,DI
                SUB     AX,Word ptr @@Str_
@@6:            POP     DS
                ret
RPos            endp

; function FPos(SubStr,Str : String) : Byte;
FPos            PROC FAR @@SubStr_: DWORD, @@Str_ : DWORD
                CLD
                PUSH    DS
                LDS     SI,SS:@@SubStr_
                LES     DI,SS:@@Str_
                MOV     CL,ES:[DI]
                XOR     CH,CH
                JCXZ    @@3
                INC     DI
                LODSB
                CMP     AL,1
                JB      @@5
                JA      @@1
                LODSB
                REPNE   SCASB
                JNE     @@3
                DEC     DI
                JMP     SHORT @@5
@@1:            XOR     AH,AH
                MOV     DX,CX
                SUB     DX,AX
                JB      @@3
                INC     DX
@@2:            MOV     CX,AX
                REP     CMPSB
                JE      @@4
                SUB     CX,AX
                ADD     SI,CX
                ADD     DI,CX
                INC     DI
                DEC     DX
                JNE     @@2
@@3:            XOR     AX,AX
                JMP     SHORT @@6
@@4:            SUB     DI,AX
@@5:            MOV     AX,DI
                SUB     AX,Word ptr @@Str_
@@6:            POP     DS
                RET
FPos            endp


; function RIPos(SubStr,Str : String; Ps : Byte) : Byte;
RIPos           PROC FAR @@SubStr_: DWORD, @@Str_ : DWORD, @@Ps : Byte
                PUSH    DS
                LDS     SI,@@SubStr_
                LES     DI,@@Str_
                MOV     CL,ES:[DI] ;Length(Str);
                mov     al,@@Ps
                or al,al
                je @@3
                xor     ah,ah
                XOR     CH,CH
                JCXZ    @@3
                cmp     cl,al
                jb      @@3
                add     di,ax
                cld
                LODSB
                CMP     AL,1
                JB      @@5 ;{Exit}
                JA      @@1
                LODSB
                std
                mov cl,@@Ps
                ;dec cl
                REPNE   SCASB
                JNE     @@3
                inc     DI
                JMP     @@5
@@1:            XOR     AH,AH   ;{ax = Length(SubStr)}
                add     si,ax
                dec     si
                std
                MOV     CL,ES:[DI]
                MOV     DX,CX   ;{cx = Length(Str)}
                SUB     DX,AX   ;{dx = Length(Str) - Length(SubStr)}
                JB      @@3
                INC     DX
@@2:            MOV     CX,AX
                REP     CMPSB
                JE      @@4
                SUB     CX,AX
                sub     SI,CX
                sub     DI,CX
                dec     DI
                DEC     DX
                JNE     @@2
@@3:            XOR     AX,AX
                JMP     @@6
@@4:            inc     di
@@5:            MOV     AX,DI
                SUB     AX,Word ptr @@Str_
@@6:            POP     DS
                ret
RIPos           endp

; function RPos(SubStr,Str : String; Ps : Byte) : Byte;
FIPos           PROC FAR @@SubStr_: DWORD, @@Str_ : DWORD, @@Ps : Byte;
                CLD
                PUSH    DS
                LDS     SI,SS:@@SubStr_
                LES     DI,SS:@@Str_
                MOV     CL,ES:[DI]
                mov     al,@@Ps
                xor     ah,ah
                XOR     CH,CH
                JCXZ    @@3
                sub     cl,al
                JCXZ    @@3
                jb      @@3
                add     di,ax
                INC     DI
                LODSB
                CMP     AL,1
                JB      @@5
                JA      @@1
                LODSB
                REPNE   SCASB
                JNE     @@3
                DEC     DI
                JMP     SHORT @@5
@@1:            XOR     AH,AH
                MOV     DX,CX
                SUB     DX,AX
                JB      @@3
                INC     DX
@@2:            MOV     CX,AX
                REP     CMPSB
                JE      @@4
                SUB     CX,AX
                ADD     SI,CX
                ADD     DI,CX
                INC     DI
                DEC     DX
                JNE     @@2
@@3:            XOR     AX,AX
                JMP     SHORT @@6
@@4:            SUB     DI,AX
@@5:            MOV     AX,DI
                SUB     AX,Word ptr @@Str_
@@6:            POP     DS
                RET
FIPos           endp

; function Count(SubStr,Str : String) : Byte;
Count           Proc far @@SubStr_: DWORD, @@Str_ : DWORD
@@Ps_           equ     [bp - 1]
@@Cnt           equ     [bp - 2]
                xor     ax,ax
                push    ax      ;Ps := 0; Cnt := 0;
@@1:            inc     Byte Ptr @@Cnt
                les     di,@@SubStr_
                push    es
                push    di
                les     di,@@Str_
                push    es
                push    di
                mov     al,@@Ps_
                push    ax
                call    FIPos
                mov     @@Ps_,al
                or      al,al
                jne     @@1
                mov     al,@@Cnt
                dec     al
                mov     sp,bp
                ret
Count           endp

; function DelChar(Ch : Char;Str : String) : String;
DelChar         proc far @@Result_ : DWORD, @@Ch_ : Byte, @@Str_: DWORD
                push ds
                lds si,@@Str_
                les di,@@Result_
                xor ch,ch
                xor ah,ah
                lodsb
                stosb
                or al,al
                je @@L3
                mov cl,al
@@L1:           lodsb
                cmp al,@@Ch_
                je @@L2
                stosb
                inc ah
@@L2:           loop @@L1
                les di,@@Result_
                mov es:[di],ah
@@L3:           pop ds
                mov sp,bp
                pop bp
                retf 6
DelChar         endp

; function ReplaceChar(SCh,DCh : Char;Str : String) : String;
ReplaceChar     proc far @@Result_ : DWORD, @@Sh_ : Byte, @@Dh_ : Byte, @@Str_: DWORD
                push ds
                lds si,@@Str_
                les di,@@Result_
                xor ch,ch
                xor ah,ah
                lodsb
                or al,al
                je @@L3
                mov cl,al
                stosb
@@L1:           lodsb
                cmp al,@@Sh_
                jne @@L2
                mov al,@@Dh_
@@L2:           stosb
                loop @@L1
                les di,@@Result_
@@L3:           pop ds
                mov sp,bp
                pop bp
                retf 8
ReplaceChar     endp
                end
