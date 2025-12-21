STRNCMP_TEXT    segment byte public 'CODE'
STRNCMP_TEXT    ends

DGROUP  group   _DATA,_BSS
        assume  cs:STRNCMP_TEXT,ds:DGROUP

_DATA   segment word public 'DATA'
d@      label   byte
d@w     label   word
_DATA   ends

_BSS    segment word public 'BSS'
b@      label   byte
b@w     label   word
_BSS    ends

STRNCMP_TEXT    segment byte public 'CODE'
   ;
   ;    int _CType _FARFUNC strncmp(const char _FAR *str1, const char _FAR *str2, size_t maxlen)
   ;
        assume  cs:STRNCMP_TEXT
_strncmp        proc    far
        push    bp
        mov     bp,sp
        push    si
        push    di
   ;
   ;    {
   ;    #if defined(__LARGE__) || defined(__COMPACT__)
   ;    asm     mov     dx, ds
   ;
        mov          dx, ds
   ;
   ;    #endif
   ;    #if !(LDATA)
   ;    asm     mov     ax, ds      /* ES = DS */
   ;    asm     mov     es, ax
   ;    #endif
   ;    asm     cld
   ;
        cld
   ;
   ;
   ;    /*   Determine size of 2nd source string. */
   ;    asm     LES_    di, str2
   ;
        LES         di, [bp+10]
   ;
   ;    asm     mov     si, di
   ;
        mov          si, di
   ;
   ;    asm     mov     ax, maxlen
   ;
        mov          ax, [bp+14]
   ;
   ;    asm     mov     cx, ax
   ;
        mov          cx, ax
   ;
   ;    asm     jcxz    ncm_end
   ;
        jcxz    short @1@590
   ;
   ;    asm     mov     bx, ax
   ;
        mov          bx, ax
   ;
   ;    asm     xor     al, al
   ;
        xor          al, al
   ;
   ;    asm     repne   scasb
   ;
        repne   scasb
   ;
   ;    asm     sub     bx, cx
   ;
        sub          bx, cx
   ;
   ;    asm     mov     cx, bx
   ;
        mov          cx, bx
   ;
   ;
   ;    asm     mov     di, si
   ;
        mov          di, si
   ;
   ;    asm     LDS_    si, str1
   ;
        LDS         si, [bp+6]
   ;
   ;
   ;    /*
   ;    Scan until either *s2 terminates, a difference is found, or "limit" is
   ;    reached.  Note that it is sufficient to check only for right termination,
   ;    since if the left terminates before the right then that difference will
   ;    also terminate the scan.
   ;    */
   ;    asm     repe    cmpsb
   ;
        repe    cmpsb
   ;
   ;
   ;    /*
   ;      The result is the signed difference of the final character pair, be they
   ;      equal or different.
   ;      We need to do the full word subtract here because ANSI requires unsigned
   ;      comparisons. A simple byte subtract with a CBW would produce the wrong
   ;      result in some cases.
   ;    */
   ;    asm     mov     al, [si-1]
   ;
        mov          al, [si-1]
   ;
   ;    asm     mov     bl, ES_ [di-1]
   ;
        mov          bl, ES: [di-1]
   ;
   ;    asm     xor     ah, ah  /* zero out high order bytes so the subtraction */
   ;
        xor          ah, ah
   ;
   ;    asm     mov     bh, ah  /* will work.                                   */
   ;
        mov          bh, ah
   ;
   ;    asm     sub     ax, bx
   ;
        sub          ax, bx
@1@590:
   ;
   ;
   ;    ncm_end:
   ;    #if defined(__LARGE__) || defined(__COMPACT__)
   ;    asm     mov     ds, dx
   ;
        mov          ds, dx
   ;
   ;    #endif
   ;            return _AX;
   ;
   ;
   ;    }
   ;
        pop     di
        pop     si
        pop     bp
        ret
_strncmp        endp

STRNCMP_TEXT    ends

_DATA   segment word public 'DATA'
s@      label   byte
_DATA   ends

STRNCMP_TEXT    segment byte public 'CODE'
STRNCMP_TEXT    ends

        public  _strncmp
_s@     equ     s@
        end
