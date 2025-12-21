STRLEN_TEXT     segment byte public 'CODE'
STRLEN_TEXT     ends

DGROUP  group   _DATA,_BSS
        assume  cs:STRLEN_TEXT,ds:DGROUP

_DATA   segment word public 'DATA'
d@      label   byte
d@w     label   word
_DATA   ends

_BSS    segment word public 'BSS'
b@      label   byte
b@w     label   word
_BSS    ends

STRLEN_TEXT     segment byte public 'CODE'
   ;
   ;    size_t _CType _FARFUNC strlen(const char *str)
   ;
        assume  cs:STRLEN_TEXT
_strlen proc    far
        push    bp
        mov     bp,sp
        push    di
   ;
   ;    {
   ;      #if !(LDATA)
   ;      asm     mov     ax,ds
   ;      asm     mov     es,ax
   ;      asm     mov     di,str
   ;      asm     xor     ax,ax
   ;      #else
   ;      asm     les     di,str
   ;
        les          di,[bp+6]
   ;
   ;      asm     xor     ax,ax
   ;
        xor          ax,ax
   ;
   ;      asm     cmp     ax,W1(str)
   ;
        cmp          ax,(word ptr ([bp+6]) [2])
   ;
   ;      asm     jne     start
   ;
        jne     short @1@198
   ;
   ;      asm     cmp     ax,di
   ;
        cmp          ax,di
   ;
   ;      asm     je      out
   ;
        je      short @1@366
@1@198:
   ;
   ;      #endif
   ;
   ;      start:
   ;      asm     cld
   ;
        cld
   ;
   ;      asm     mov     cx, -1
   ;
        mov          cx, -1
   ;
   ;      asm     repne   scasb
   ;
        repne   scasb
   ;
   ;      asm     xchg    ax,cx
   ;
        xchg        ax,cx
   ;
   ;      asm     not     ax
   ;
        not          ax
   ;
   ;      asm     dec     ax
   ;
        dec          ax
@1@366:
   ;
   ;
   ;      out:
   ;      return(_AX);
   ;
   ;
   ;    }
   ;
        pop     di
        pop     bp
        ret
_strlen endp

STRLEN_TEXT     ends

_DATA   segment word public 'DATA'
s@      label   byte
_DATA   ends

STRLEN_TEXT     segment byte public 'CODE'
STRLEN_TEXT     ends

        public  _strlen
_s@     equ     s@
        end
