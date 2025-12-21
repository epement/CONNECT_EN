                .MODEL  TPASCAL
                locals
                .DATA

                EXTRN   Crc32Table : DWORD            ; 256-DWORD array


                .CODE

                EXTRN   UpcaseMap: DWord
IncCRC          PROC FAR @@pBuff:DWORD,@@Count:WORD,@@pCRC:DWORD
                PUBLIC  IncCRC

                les     si,@@pCRC
                mov     cx,es:[si]
                mov     dx,es:[si+2]
                mov     di,OFFSET Crc32Table
                les     si,@@pBuff
                cld
                push    bp
                mov     bp,@@Count
                inc     bp
                jmp     SHORT @@ic1
@@ic0:
                xor     ax,ax
                lods    BYTE PTR es:[si]
                mov     bx,ax
                xor     bl,cl
                mov     cl,ch
                mov     ch,dl
                mov     dl,dh
                mov     dh,bh
                shl     bx,1
                shl     bx,1
                xor     cx,[bx+di]
                xor     dx,[bx+di+2]
                test    si,si
                jnz     @@ic1
                mov     ax,es
                add     ax,1000h
                mov     es,ax
@@ic1:
                dec     bp
                jnz     @@ic0
                pop     bp
                les     si,@@pCRC
                mov     es:[si],cx
                mov     es:[si+2],dx
                ret

IncCRC          ENDP

IncCRCUC        PROC FAR @@pBuff:DWORD,@@Count:WORD,@@pCRC:DWORD
                PUBLIC  IncCRCUC

                les     si,@@pCRC
                mov     cx,es:[si]
                mov     dx,es:[si+2]
                mov     di,OFFSET Crc32Table
                les     si,@@pBuff
                cld
                push    bp
                mov     bp,@@Count
                inc     bp
                jmp     SHORT @@ic1
@@ic0:
                xor     ax,ax
                lods    BYTE PTR es:[si]
                push    es
                mov     bx, seg UpCaseMap
                mov     es, bx
                mov     bx, offset UpCaseMap
                xlat    es:[bx]
                pop     es
                mov     bx,ax
                xor     bl,cl
                mov     cl,ch
                mov     ch,dl
                mov     dl,dh
                mov     dh,bh
                shl     bx,1
                shl     bx,1
                xor     cx,[bx+di]
                xor     dx,[bx+di+2]
                test    si,si
                jnz     @@ic1
                mov     ax,es
                add     ax,1000h
                mov     es,ax
@@ic1:
                dec     bp
                jnz     @@ic0
                pop     bp
                les     si,@@pCRC
                mov     es:[si],cx
                mov     es:[si+2],dx
                ret

IncCRCUC        ENDP

CODE            ENDS

                END



