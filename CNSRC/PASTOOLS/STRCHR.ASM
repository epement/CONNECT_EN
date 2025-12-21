
STRCHR_TEXT     segment byte public 'CODE'
STRCHR_TEXT     ends

DGROUP  group   _DATA,_BSS

        assume  cs:STRCHR_TEXT,ds:DGROUP

_DATA   segment word public 'DATA'
d@      label   byte
d@w     label   word
_DATA   ends

_BSS    segment word public 'BSS'
b@      label   byte
b@w     label   word
_BSS    ends

STRCHR_TEXT     segment byte public 'CODE'
   ;
   ;    char _FAR * _CType _FARFUNC strchr(const char _FAR *s, int c)
   ;
        assume  cs:STRCHR_TEXT
_strchr proc    far
        push    bp
        mov     bp,sp
        push    si
   ;
   ;    {
   ;    asm     cld
   ;
        cld
   ;
   ;    #if  defined(__LARGE__) || defined(__COMPACT__)
   ;    asm push    ds
   ;
        push        ds
   ;
   ;    #endif
   ;    asm LDS_    si, s
   ;
        LDS         si, [bp+6]
   ;
   ;    asm mov bl,c
   ;
        mov      bl,[bp+10]
   ;
   ;    asm test    si, 1           /* SI even? */
   ;
        test        si, 1
   ;
   ;    asm jz  cmp_loop
   ;
        je      short @1@338
   ;
   ;    asm lodsb
   ;
        lodsb
   ;
   ;    asm cmp al, bl          /* process first character */
   ;
        cmp      al, bl
   ;
   ;    asm je  success2
   ;
        je      short @1@646
   ;
   ;    asm and al, al
   ;
        and      al, al
   ;
   ;    asm jz  failure
   ;
        je      short @1@590
@1@338:
   ;
   ;    cmp_loop:
   ;    asm lodsw               /* get 2 chars at a time */
   ;
        lodsw
   ;
   ;    asm cmp al, bl
   ;
        cmp      al, bl
   ;
   ;    asm je  success1        /* if first  char matches */
   ;
        je      short @1@674
   ;
   ;    asm and al, al
   ;
        and      al, al
   ;
   ;    asm jz  failure         /* give up if end of string */
   ;
        je      short @1@590
   ;
   ;    asm cmp ah, bl
   ;
        cmp      ah, bl
   ;
   ;    asm je  success2        /* if second char matches */
   ;
        je      short @1@646
   ;
   ;    asm and ah, ah
   ;
        and      ah, ah
   ;
   ;    asm jnz cmp_loop        /* continue if more characters */
   ;
        jne     short @1@338
@1@590:
   ;
   ;    failure:
   ;    #if  defined(__LARGE__) || defined(__COMPACT__)
   ;    asm pop ds
   ;
        pop      ds
   ;
   ;    #endif
   ;            return( NULL );
   ;
        xor     dx,dx
        xor     ax,ax
        jmp     short @1@758
@1@646:
   ;
   ;    success2:
   ;    asm inc si
   ;
        inc      si
@1@674:
   ;
   ;    success1:
   ;    asm lea ax, [si-2]      /* point AX at matching char */
   ;
        lea      ax, [si-2]
   ;
   ;    #if LDATA
   ;    asm mov dx,ds
   ;
        mov      dx,ds
   ;
   ;    #endif
   ;    #if  defined(__LARGE__) || defined(__COMPACT__)
   ;    asm pop ds
   ;
        pop      ds
@1@758:
   ;
   ;    #endif
   ;
   ;    #if LDATA
   ;            return( (char *)(MK_LONG) );
   ;
   ;
   ;    #else
   ;            return( (char *)_AX );
   ;    #endif
   ;    }
   ;
        pop     si
        pop     bp
        ret
_strchr endp

STRCHR_TEXT     ends

_DATA   segment word public 'DATA'
s@      label   byte
_DATA   ends

STRCHR_TEXT     segment byte public 'CODE'
STRCHR_TEXT     ends

        public  _strchr
_s@     equ     s@
        end
