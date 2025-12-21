STRCSPN_TEXT    segment byte public 'CODE'
STRCSPN_TEXT    ends

DGROUP  group   _DATA,_BSS
        assume  cs:STRCSPN_TEXT,ds:DGROUP

_DATA   segment word public 'DATA'
d@      label   byte
d@w     label   word
_DATA   ends

_BSS    segment word public 'BSS'
b@      label   byte
b@w     label   word
_BSS    ends

STRCSPN_TEXT    segment byte public 'CODE'
   ;
   ;    size_t _FARFUNC strcspn(const char *s1, const char *s2)
   ;
        assume  cs:STRCSPN_TEXT
_strcspn        proc    far
        push    bp
        mov     bp,sp
        sub     sp,4
   ;
   ;    {
   ;            register const char *srchs2;
   ;            int len;
   ;
   ;            for (len = 0; *s1; s1++, len++)
   ;
        xor     cx,cx
        jmp     short @1@198
@1@58:
   ;
   ;                    for (srchs2 = s2; *srchs2; srchs2++)
   ;
        mov     ax,word ptr [bp+12]
        mov     dx,word ptr [bp+10]
        mov     word ptr [bp-2],ax
        mov     word ptr [bp-4],dx
        jmp     short @1@142
@1@86:
   ;
   ;                            if (*s1 == *srchs2) goto bye;
   ;
        les     bx,dword ptr [bp+6]
        mov     al,byte ptr es:[bx]
        les     bx,dword ptr [bp-4]
        cmp     al,byte ptr es:[bx]
        je      short @1@226
        inc     word ptr [bp-4]
@1@142:
        les     bx,dword ptr [bp-4]
        cmp     byte ptr es:[bx],0
        jne     short @1@86
        inc     word ptr [bp+6]
        inc     cx
@1@198:
        les     bx,dword ptr [bp+6]
        cmp     byte ptr es:[bx],0
        jne     short @1@58
@1@226:
   ;
   ;    bye:
   ;            return (len);
   ;
        mov     ax,cx
   ;
   ;    }
   ;
        mov     sp,bp
        pop     bp
        ret
_strcspn        endp

STRCSPN_TEXT    ends

_DATA   segment word public 'DATA'
s@      label   byte
_DATA   ends

STRCSPN_TEXT    segment byte public 'CODE'
STRCSPN_TEXT    ends

        public  _strcspn
_s@     equ     s@
        end
