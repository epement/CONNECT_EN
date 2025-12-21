                NAME    HEAP
                EXTRN   UMBRUNERROR :BYTE
                EXTRN   HEAPERROR :BYTE
                EXTRN   UMBFREELIST :BYTE
                EXTRN   UMBHEAPEND :BYTE
                EXTRN   UMBHEAPPTR :BYTE
                EXTRN   UMBHEAPORG :BYTE
DATA            SEGMENT WORD PUBLIC  ''

L1              DW ?

DATA            ENDS

CODE            SEGMENT BYTE PUBLIC  ''
                ASSUME  CS:CODE ,DS:DATA

                PUBLIC  UMBGETMEM
                PUBLIC  UMBFREEMEM
                PUBLIC  UMBMEMAVAIL
                PUBLIC  UMBMAXAVAIL

L2:             push    ax
                call    near ptr UMBRUNERROR
UMBGETMEM:      push    bp
                mov     bp,sp
                mov     ax,word ptr +6H[bp]
                call    near ptr L14
                pop     bp
                jb      short L3
                retf    0002H
L3:             mov     ax,00cbH
                jmp     short L2
UMBFREEMEM:     push    bp
                mov     bp,sp
                mov     ax,word ptr +6H[bp]
                les     cx,dword ptr +8H[bp]
                mov     bx,es
                call    near ptr L24
                pop     bp
                jb      short L4
                retf    0006H
L4:             mov     ax,00ccH
                jmp     short L2
UMBMEMAVAIL:    mov     bx,offset L8
                jmp     short L13
L5:             add     dx,1000H
                jmp     short L7
L6:             add     ax,word ptr +4H[si]
                jb      short L5
L7:             add     dx,word ptr +6H[si]
                lds     si,dword ptr [si]
L8:             mov     bx,ds
                cmp     bx,di
                jne     short L6
                ret
UMBMAXAVAIL:    mov     bx,offset L12
                jmp     short L13
L9:             cmp     dx,word ptr +6H[si]
                ja      short L11
                jb      short L10
                cmp     ax,word ptr +4H[si]
                jae     short L11
L10:            mov     ax,word ptr +4H[si]
                mov     dx,word ptr +6H[si]
L11:            lds     si,dword ptr [si]
L12:            mov     bx,ds
                cmp     bx,di
                jne     short L9
                ret
L13:            mov     ax,word ptr UMBHEAPEND
                mov     dx,word ptr UMBHEAPEND+2H
                sub     ax,word ptr UMBHEAPPTR
                sbb     dx,word ptr UMBHEAPPTR+2H
                and     ax,000fH
                push    ds
                mov     di,word ptr UMBHEAPPTR+2H
                lds     si,dword ptr UMBFREELIST
                call    bx
                pop     ds
                mov     cl,04H
                rol     dx,cl
                mov     cx,dx
                and     cl,0f0H
                and     dx,000fH
                add     ax,cx
                adc     dx,0000H
                retf
L14:            or      ax,ax
                je      short L20
                mov     word ptr L1,ax
L15:            call    near ptr L34
                mov     di,offset UMBFREELIST
                mov     cx,ds
                mov     es,cx
L16:            mov     cx,di
                mov     bx,es
                les     di,dword ptr es:[di]
                mov     si,es
                cmp     si,word ptr UMBHEAPPTR+2H
                je      short L21
                cmp     dx,word ptr es:+6H[di]
                ja      short L16
                jb      short L17
                cmp     ax,word ptr es:+4H[di]
                ja      short L16
L17:            push    es
                push    di
                push    bx
                push    cx
                mov     cx,word ptr es:[di]
                mov     bx,word ptr es:+2H[di]
                je      short L18
                push    bx
                push    cx
                mov     cx,word ptr es:+4H[di]
                mov     bx,word ptr es:+6H[di]
                sub     cx,ax
                sbb     bx,dx
                and     cx,000fH
                add     ax,di
                add     dx,si
                add     al,0f0H
                adc     dx,0000H
                and     al,0fH
                mov     di,ax
                mov     es,dx
                pop     word ptr es:[di]
                pop     word ptr es:+2H[di]
                mov     word ptr es:+4H[di],cx
                mov     word ptr es:+6H[di],bx
                mov     cx,di
                mov     bx,es
L18:            pop     di
                pop     es
                mov     word ptr es:[di],cx
                mov     word ptr es:+2H[di],bx
                pop     ax
                pop     dx
                clc
L19:            ret
L20:            xor     ax,ax
                cwd
                ret
L21:            add     ax,di
                add     dx,si
                add     al,0f0H
                adc     dx,0000H
                and     al,0fH
                cmp     dx,word ptr UMBHEAPEND+2H
                jb      short L22
                ja      short L23
                cmp     ax,word ptr UMBHEAPEND
                ja      short L23
L22:            push    es
                push    di
                mov     di,cx
                mov     es,bx
                mov     word ptr UMBHEAPPTR,ax
                mov     word ptr UMBHEAPPTR+2H,dx
                mov     word ptr es:[di],ax
                mov     word ptr es:+2H[di],dx
                xor     ax,ax
                push    ax
                call    dword ptr HEAPERROR
                pop     ax
                pop     dx
                clc
                ret
L23:            push    word ptr L1
                call    dword ptr HEAPERROR
                cmp     al,01H
                jb      short L19
                je      short L20
                mov     ax,word ptr L1
                jmp     near ptr L15
L24:            or      ax,ax
                je      short L30
                test    cx,0fff7H
                jne     short L29
                cmp     bx,word ptr UMBHEAPORG+2H
                ja      short L25
                jb      short L29
                cmp     cx,word ptr UMBHEAPORG
                jb      short L29
L25:            cmp     bx,word ptr UMBHEAPPTR+2H
                jb      short L26
                ja      short L29
                cmp     cx,word ptr UMBHEAPPTR
                jae     short L29
L26:            call    near ptr L34
                mov     di,cx
                mov     es,bx
                mov     word ptr es:+4H[di],ax
                mov     word ptr es:+6H[di],dx
                mov     di,offset UMBFREELIST
                mov     ax,ds
                mov     es,ax
L27:            mov     ax,di
                mov     dx,es
                les     di,dword ptr es:[di]
                mov     si,es
                cmp     bx,si
                ja      short L27
                jb      short L28
                cmp     cx,di
                ja      short L27
                je      short L29
L28:            push    dx
                push    ax
                call    near ptr L31
                pop     cx
                pop     bx
                call    near ptr L31
                clc
                ret
L29:            stc
L30:            ret
L31:            mov     ax,di
                mov     dx,es
                mov     di,cx
                mov     es,bx
                add     cx,word ptr es:+4H[di]
                add     bx,word ptr es:+6H[di]
                add     cl,0f0H
                adc     bx,0000H
                and     cl,0fH
                cmp     bx,dx
                jne     short L33
                cmp     cx,ax
                jne     short L33
                cmp     dx,word ptr UMBHEAPPTR+2H
                jne     short L32
                cmp     ax,word ptr UMBHEAPPTR
                jne     short L32
                mov     word ptr UMBHEAPPTR,di
                mov     word ptr UMBHEAPPTR+2H,es
                ret
L32:            push    ds
                push    di
                mov     si,ax
                mov     ds,dx
                cld
                movsw
                movsw
                lodsw
                xchg    ax,dx
                lodsw
                xchg    ax,dx
                add     ax,word ptr es:[di]
                add     dx,word ptr es:+2H[di]
                add     al,0f0H
                adc     dx,0000H
                and     al,0fH
                stosw
                xchg    ax,dx
                stosw
                pop     di
                pop     ds
                ret
L33:            mov     word ptr es:[di],ax
                mov     word ptr es:+2H[di],dx
                ret
L34:            add     ax,0007H
                mov     dx,ax
                rcr     dx,1
                shr     dx,1
                shr     dx,1
                shr     dx,1
                and     ax,0008H
                ret
CODE            ENDS

                END