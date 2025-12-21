        ifndef  ??version
?debug  macro
        endm
publicdll macro name
        public  name
        endm
        endif
        ?debug  V 300h
        ?debug  S "WRAP.C"
        ?debug  C E90273931F06575241502E43
_TEXT   segment byte public 'CODE'
_TEXT   ends
DGROUP  group   _DATA,_BSS
        assume  cs:_TEXT,ds:DGROUP
_DATA   segment word public 'DATA'
d@      label   byte
d@w     label   word
_DATA   ends
_BSS    segment word public 'BSS'
b@      label   byte
b@w     label   word
_BSS    ends
_DATA   segment word public 'DATA'
U       label   byte
        db      131
        db      144
        db      145
        db      138
        db      145
        db      146
        db      1 dup (0)
_DATA   ends
_TEXT   segment byte public 'CODE'
        ?debug  C E80106575241502E430273931F
   ;
   ;    extern pascal near wrap()
   ;
        ?debug  L 243
        assume  cs:_TEXT
WRAP    proc    near
        ?debug  B
        push    bp
        mov     bp,sp
        sub     sp,10
        push    si
        push    di
        ?debug  B
   ;
   ;    {
   ;            register int i,j;
   ;            int hpp,k;
   ;
   ;            {
   ;                    lword = strlen(wordc);
   ;
        ?debug  L 249
        mov     ax,offset DGROUP:WORDC
        push    ax
        call    near ptr _strlen
        pop     cx
        mov     word ptr DGROUP:lword,ax
   ;
   ;                    hpp = 0;
   ;
        ?debug  L 250
        mov     word ptr [bp-2],0
   ;
   ;                    for(i=0; i<100; i++) wh[i] = 2;
   ;
        ?debug  L 251
        mov     cx,100
        mov     di,offset DGROUP:WH
        push    ds
        pop     es
        mov     ax,2
        rep     stosw
   ;
   ;                    j = 0; i = 0;
   ;
        ?debug  L 252
        xor     si,si
        xor     ax,ax
        shl     ax,1
        add     ax,offset DGROUP:hp
        mov     word ptr [bp-6],ax
        jmp     short @1@254
@1@170:
   ;
   ;                    while((i=quasipref(wordc + j)) != 0){
   ;                            j += i;
   ;
        ?debug  L 254
        add     si,di
   ;
   ;                            hp[hpp++] = i;
   ;
        ?debug  L 255
        mov     bx,word ptr [bp-6]
        mov     word ptr [bx],di
        add     word ptr [bp-6],2
        inc     word ptr [bp-2]
@1@254:
        ?debug  L 253
        mov     ax,si
        add     ax,offset DGROUP:WORDC
        push    ax
        call    near ptr _quasipref
        pop     cx
        mov     di,ax
        or      ax,ax
        jne     short @1@170
   ;
   ;                            }
   ;                    hp[hpp] = 0;
   ;
        ?debug  L 257
        mov     bx,word ptr [bp-2]
        shl     bx,1
        mov     word ptr DGROUP:hp[bx],0
   ;
   ;                    if(hpp == 0) goto LETTER;
   ;
        ?debug  L 258
        cmp     word ptr [bp-2],0
        je      short @1@562
   ;
   ;                    wh[j+1] = 0;    /* Второй символ в R */
   ;
        ?debug  L 259
        mov     bx,si
        shl     bx,1
        mov     word ptr DGROUP:WH[bx+2],0
   ;
   ;                    wh[lword-1] = 0;        /* Последний символ в R */
   ;
        ?debug  L 260
        mov     bx,word ptr DGROUP:lword
        shl     bx,1
        mov     word ptr DGROUP:WH[bx-2],0
   ;
   ;                    wh[j-1] = 0;    /* Последний символ в последней квазиприставке */
   ;
        ?debug  L 261
        mov     bx,si
        shl     bx,1
        mov     word ptr DGROUP:WH[bx-2],0
   ;
   ;                    wh[j - hp[hpp-1] + 1] = 0; /* Второй символ в последней квазиприставке */
   ;
        ?debug  L 262
        mov     bx,word ptr [bp-2]
        shl     bx,1
        mov     ax,si
        sub     ax,word ptr DGROUP:hp[bx-2]
        shl     ax,1
        mov     bx,ax
        mov     word ptr DGROUP:WH[bx+2],0
   ;
   ;                    j = 0;
   ;
        ?debug  L 263
        xor     si,si
   ;
   ;                    for(i=0; i<hpp; i++){   /* Цикл по квазиприставкам */
   ;
        ?debug  L 264
        xor     di,di
        mov     dx,offset DGROUP:hp
        cmp     di,word ptr [bp-2]
        jge     short @1@562
@1@394:
   ;
   ;                            if(hp[i] != 1) wh[j + hp[i]] = 1;
   ;
        ?debug  L 265
        mov     bx,dx
        cmp     word ptr [bx],1
        je      short @1@450
        mov     ax,si
        add     ax,word ptr [bx]
        shl     ax,1
        mov     bx,ax
        mov     word ptr DGROUP:WH[bx],1
@1@450:
   ;
   ;                            j += hp[i];
   ;
        ?debug  L 266
        mov     bx,dx
        add     si,word ptr [bx]
        ?debug  L 264
        add     dx,2
        inc     di
        cmp     di,word ptr [bp-2]
        jl      short @1@394
@1@562:
   ;
   ;                    }
   ;
   ;    LETTER:
   ;                    j = 0;
   ;
        ?debug  L 270
        xor     si,si
   ;
   ;                    for(i=0; i<hpp; i++){   /* Цикл по квазиприставкам */
   ;
        ?debug  L 271
        xor     di,di
        mov     word ptr [bp-10],offset DGROUP:hp
        cmp     di,word ptr [bp-2]
        jl      @@45
        jmp     @1@1318
@@45:
@1@646:
   ;
   ;                            if(hp[i]<4){
   ;
        ?debug  L 272
        mov     bx,word ptr [bp-10]
        cmp     word ptr [bx],4
        jge     short @1@898
   ;
   ;                                    for(k=0; k<hp[i]; k++)
   ;
        ?debug  L 273
        mov     word ptr [bp-4],0
        mov     dx,si
        shl     dx,1
        add     dx,offset DGROUP:WH
        jmp     short @1@842
@1@730:
   ;
   ;                                            if(wh[j+k] == 2) wh[j+k] = 0;
   ;
        ?debug  L 274
        mov     bx,dx
        cmp     word ptr [bx],2
        jne     short @1@786
        mov     word ptr [bx],0
@1@786:
        ?debug  L 273
        add     dx,2
        inc     word ptr [bp-4]
@1@842:
        mov     bx,word ptr [bp-10]
        mov     ax,word ptr [bx]
        cmp     ax,word ptr [bp-4]
        jg      short @1@730
        jmp     @1@1206
@1@898:
   ;
   ;                                    j += hp[i];
   ;                                    continue;
   ;                            }
   ;                            strncpy(cp1, &wordc[j], hp[i]);
   ;
        ?debug  L 278
        mov     bx,word ptr [bp-10]
        push    word ptr [bx]
        mov     ax,si
        add     ax,offset DGROUP:WORDC
        push    ax
        mov     ax,offset DGROUP:cp1
        push    ax
        call    near ptr _strncpy
        add     sp,6
   ;
   ;                            cp1[hp[i]] = '\0';
   ;
        ?debug  L 279
        mov     bx,word ptr [bp-10]
        mov     bx,word ptr [bx]
        mov     byte ptr DGROUP:cp1[bx],0
   ;
   ;                            if(wh[j]==2) wh[j] = 0;
   ;
        ?debug  L 280
        mov     bx,si
        shl     bx,1
        cmp     word ptr DGROUP:WH[bx],2
        jne     short @1@954
        mov     bx,si
        shl     bx,1
        mov     word ptr DGROUP:WH[bx],0
@1@954:
   ;
   ;                            if(wh[j+1] == 2) wh[j+1] = 0;
   ;
        ?debug  L 281
        mov     bx,si
        shl     bx,1
        cmp     word ptr DGROUP:WH[bx+2],2
        jne     short @1@1010
        mov     bx,si
        shl     bx,1
        mov     word ptr DGROUP:WH[bx+2],0
@1@1010:
   ;
   ;                            for(k=3; k<hp[i]; k++)
   ;
        ?debug  L 282
        mov     word ptr [bp-4],3
        mov     ax,si
        add     ax,3
        shl     ax,1
        add     ax,offset DGROUP:WH-2
        mov     word ptr [bp-8],ax
        jmp     short @1@1178
@1@1066:
   ;
   ;                                    if(wh[j+k-1] == 2) wh[j+k-1] = letter(cp1, k);
   ;
        ?debug  L 283
        mov     bx,word ptr [bp-8]
        cmp     word ptr [bx],2
        jne     short @1@1122
        push    word ptr [bp-4]
        mov     ax,offset DGROUP:cp1
        push    ax
        call    near ptr _letter
        pop     cx
        pop     cx
        mov     bx,word ptr [bp-8]
        mov     word ptr [bx],ax
@1@1122:
        ?debug  L 282
        add     word ptr [bp-8],2
        inc     word ptr [bp-4]
@1@1178:
        mov     bx,word ptr [bp-10]
        mov     ax,word ptr [bx]
        cmp     ax,word ptr [bp-4]
        jg      short @1@1066
@1@1206:
   ;
   ;                            j += hp[i];
   ;
        ?debug  L 284
        mov     bx,word ptr [bp-10]
        add     si,word ptr [bx]
        ?debug  L 271
        add     word ptr [bp-10],2
        inc     di
        cmp     di,word ptr [bp-2]
        jge     @@46
        jmp     @1@646
@@46:
@1@1318:
   ;
   ;                    }
   ;                    if(wh[j]==2) wh[j] = 0;
   ;
        ?debug  L 286
        mov     bx,si
        shl     bx,1
        cmp     word ptr DGROUP:WH[bx],2
        jne     short @1@1374
        mov     bx,si
        shl     bx,1
        mov     word ptr DGROUP:WH[bx],0
@1@1374:
   ;
   ;                    if(wh[j+1] == 2) wh[j+1] = 0;
   ;
        ?debug  L 287
        mov     bx,si
        shl     bx,1
        cmp     word ptr DGROUP:WH[bx+2],2
        jne     short @1@1430
        mov     bx,si
        shl     bx,1
        mov     word ptr DGROUP:WH[bx+2],0
@1@1430:
   ;
   ;                    strcpy(cp1, &wordc[j]);
   ;
        ?debug  L 288
        mov     ax,si
        add     ax,offset DGROUP:WORDC
        push    ax
        mov     ax,offset DGROUP:cp1
        push    ax
        call    near ptr _strcpy
        pop     cx
        pop     cx
   ;
   ;                    lword = strlen(cp1);
   ;
        ?debug  L 289
        mov     ax,offset DGROUP:cp1
        push    ax
        call    near ptr _strlen
        pop     cx
        mov     word ptr DGROUP:lword,ax
   ;
   ;                    for(i=3; i<lword; i++)
   ;
        ?debug  L 290
        mov     di,3
        add     si,3
        shl     si,1
        add     si,offset DGROUP:WH-2
        cmp     di,word ptr DGROUP:lword
        jge     short @1@1654
@1@1514:
   ;
   ;                            if(wh[j+i-1] == 2) wh[j+i-1] = letter(cp1, i);
   ;
        ?debug  L 291
        cmp     word ptr [si],2
        jne     short @1@1570
        push    di
        mov     ax,offset DGROUP:cp1
        push    ax
        call    near ptr _letter
        pop     cx
        pop     cx
        mov     word ptr [si],ax
@1@1570:
        ?debug  L 290
        add     si,2
        inc     di
        cmp     di,word ptr DGROUP:lword
        jl      short @1@1514
@1@1654:
   ;
   ;                    lword = strlen(wordc);
   ;
        ?debug  L 292
        mov     ax,offset DGROUP:WORDC
        push    ax
        call    near ptr _strlen
        pop     cx
        mov     word ptr DGROUP:lword,ax
   ;
   ;            }
   ;
   ;    }
   ;
        ?debug  L 295
        pop     di
        pop     si
        mov     sp,bp
        pop     bp
        ret
        ?debug  C E6016B0402FCFF00036870700402FEFF00016A04+
        ?debug  C 08012B004C0204060001690408013C007A020407+
        ?debug  C 00
        ?debug  E
        ?debug  E
WRAP    endp
   ;
   ;    static quasipref(wordc)
   ;
        ?debug  L 297
        assume  cs:_TEXT
quasipref       proc    near
        ?debug  B
        push    bp
        mov     bp,sp
        sub     sp,8
        push    si
        push    di
        ?debug  B
   ;
   ;    char *wordc;
   ;    {
   ;            register struct Qpref far *s;
   ;            register char far *cp;
   ;            register int i, lpref;
   ;            char *chp1;
   ;            int  temp1;
   ;
   ;            for(s=Qpr(),i=0; i<Qsize; i++, s++)
   ;
        ?debug  L 306
        call    near ptr QPR
        mov     word ptr [bp-2],dx
        mov     word ptr [bp-4],ax
        xor     di,di
        jmp     @2@562
@2@58:
   ;
   ;            {
   ;                    lpref = f_strlen( s->pref );      // [BT]
   ;
        ?debug  L 308
        push    word ptr [bp-2] ;ds Fixed!!!
        les     bx,dword ptr [bp-4]
        push    word ptr es:[bx]
        call    far ptr _f_strlen
        pop     cx
        pop     cx
        mov     si,ax
   ;
   ;                    if(lpref > lword) continue;
   ;
        ?debug  L 309
        cmp     si,word ptr DGROUP:lword
        jle     @@47
        jmp     @2@534
@@47:
   ;
   ;                    if(f_strncmp(s->pref, wordc, lpref) != 0) continue;
   ;
        ?debug  L 310
        push    si
        push    ds
        push    word ptr [bp+4]
        push    word ptr [bp-2];ds Fixed!!!
        les     bx,dword ptr [bp-4]
        push    word ptr es:[bx]
        call    far ptr _f_strncmp
        add     sp,10
        or      ax,ax
        je      @@48
        jmp     @2@534
@@48:
   ;
   ;                    cp = s->locks;
   ;
        ?debug  L 311
        les     bx,dword ptr [bp-4]
        mov     ax,word ptr es:[bx+2]
;        mov     word ptr [bp-6],ds Fixed!!!
        mov     word ptr [bp-8],ax
        mov     ax,word ptr [bp-2] ;Fixed!!!
        mov     word ptr [bp-6],ax
        jmp     short @2@198
@2@142:
   ;
   ;                    while(*cp)
   ;                            if(f_strncmp(&wordc[lpref], cp++, 2) == 0) goto Cont;
   ;
        ?debug  L 313
        mov     ax,2
        push    ax
        mov     ax,word ptr [bp-8]
        inc     word ptr [bp-8]
        push    word ptr [bp-6]
        push    ax
        push    ds
        mov     ax,word ptr [bp+4]
        add     ax,si
        push    ax
        call    far ptr _f_strncmp
        add     sp,10
        or      ax,ax
        je      short @2@534
   ;
   ;                            else cp++;
   ;
        ?debug  L 314
        inc     word ptr [bp-8]
@2@198:
        ?debug  L 312
        les     bx,dword ptr [bp-8]
        cmp     byte ptr es:[bx],0
        jne     short @2@142
   ;
   ;                    if(lpref > (lword-3)) return(0);
   ;
        ?debug  L 315
        mov     ax,word ptr DGROUP:lword
        add     ax,-3
        cmp     ax,si
        jl      short @2@590
   ;
   ;                    chp1 = wordc + lpref;
   ;
        ?debug  L 316
        mov     di,word ptr [bp+4]
        add     di,si
        jmp     short @2@310
@2@282:
   ;
   ;                    while(*chp1) if(vowel(*chp1++)) goto Yes;
   ;
        ?debug  L 317
        mov     bx,di
        inc     di
        mov     al,byte ptr [bx]
        cbw
        push    ax
        call    near ptr _vowel
        pop     cx
        or      ax,ax
        jne     short @2@366
@2@310:
        cmp     byte ptr [di],0
        jne     short @2@282
   ;
   ;                    return(0);
   ;
        ?debug  L 318
        jmp     short @2@590
@2@366:
   ;
   ;            Yes:    if(spec(wordc[lpref])) return(lpref + 1);
   ;
        ?debug  L 319
        mov     bx,word ptr [bp+4]
        add     bx,si
        mov     al,byte ptr [bx]
        cbw
        push    ax
        call    near ptr _spec
        pop     cx
        or      ax,ax
        je      short @2@422
        mov     ax,si
        inc     ax
        jmp     short @2@618
@2@422:
   ;
   ;                    if(consonant(wordc[lpref - 1]) && vowel(wordc[lpref]))
   ;
        ?debug  L 320
        mov     bx,word ptr [bp+4]
        mov     al,byte ptr [bx+si-1]
        cbw
        push    ax
        call    near ptr _consonant
        pop     cx
        or      ax,ax
        je      short @2@506
        mov     bx,word ptr [bp+4]
        add     bx,si
        mov     al,byte ptr [bx]
        cbw
        push    ax
        call    near ptr _vowel
        pop     cx
        or      ax,ax
        je      short @2@506
   ;
   ;                            return(lpref - 1);
   ;
        ?debug  L 321
        mov     ax,si
        dec     ax
        jmp     short @2@618
@2@506:
   ;
   ;                    else return(lpref);
   ;
        ?debug  L 322
        mov     ax,si
        jmp     short @2@618
@2@534:
        ?debug  L 306
        inc     di
        add     word ptr [bp-4],4
@2@562:
        cmp     di,202
        jge     @@49
        jmp     @2@58
@@49:
@2@590:
   ;
   ;            Cont: continue;
   ;            }
   ;            return(0);
   ;
        ?debug  L 325
        xor     ax,ax
@2@618:
   ;
   ;
   ;    }
   ;
        ?debug  L 327
        pop     di
        pop     si
        mov     sp,bp
        pop     bp
        ret
        ?debug  C E318000200150204
        ?debug  C E319000400160200
        ?debug  C E31B05517072656604001E01
        ?debug  C E31A000400161B00
        ?debug  C E60463687031180801A100A700040700056C7072+
        ?debug  C 656604080126000F010406000169040801130017+
        ?debug  C 010407000263701902F8FF0001731A02FCFF0005+
        ?debug  C 776F726463180A040000
        ?debug  E
        ?debug  E
quasipref       endp
   ;
   ;    static letter(w, m)
   ;
        ?debug  L 329
        assume  cs:_TEXT
letter  proc    near
        ?debug  B
        push    bp
        mov     bp,sp
        push    si
        push    di
        mov     si,word ptr [bp+4]
        mov     di,word ptr [bp+6]
        ?debug  B
   ;
   ;    char *w;
   ;    {
   ;
   ;            if(spec(w[m-1])) return(0);
   ;
        ?debug  L 333
        mov     bx,si
        mov     al,byte ptr [bx+di-1]
        cbw
        push    ax
        call    near ptr _spec
        pop     cx
        or      ax,ax
        je      short @3@86
@3@58:
        xor     ax,ax
        jmp     @3@534
@3@86:
   ;
   ;            if(!vows(w, m-1)) return(0);
   ;
        ?debug  L 334
        mov     ax,di
        dec     ax
        push    ax
        push    si
        call    near ptr _vows
        pop     cx
        pop     cx
        or      ax,ax
        je      short @3@58
   ;
   ;            if(!vows(&w[m-1], 0)) return(0);
   ;
        ?debug  L 335
        xor     ax,ax
        push    ax
        mov     ax,di
        add     ax,si
        dec     ax
        push    ax
        call    near ptr _vows
        pop     cx
        pop     cx
        or      ax,ax
        je      short @3@58
   ;
   ;            if(vowel(w[m-1])){
   ;
        ?debug  L 336
        mov     bx,si
        mov     al,byte ptr [bx+di-1]
        cbw
        push    ax
        call    near ptr _vowel
        pop     cx
        or      ax,ax
        je      short @3@226
   ;
   ;                    if(consonant(w[m-2])) return(0);
   ;
        ?debug  L 337
        mov     bx,si
        mov     al,byte ptr [bx+di-2]
        cbw
        push    ax
        call    near ptr _consonant
        pop     cx
        or      ax,ax
        jne     short @3@58
   ;
   ;                    if(vowel(w[m-2])) return(1);
   ;
        ?debug  L 338
        mov     bx,si
        mov     al,byte ptr [bx+di-2]
        cbw
        push    ax
        call    near ptr _vowel
        pop     cx
        or      ax,ax
        je      @@50
        jmp     @3@506
@@50:
@3@226:
   ;
   ;            }
   ;
   ;            if(w[m-1] == w[m]) return(0);
   ;
        ?debug  L 341
        mov     bx,di
        add     bx,si
        mov     dx,bx
        mov     al,byte ptr [bx-1]
        mov     bx,di
        cmp     al,byte ptr [bx+si]
        je      short @3@58
   ;
   ;
   ;            if(spec(w[m-2])) return(1);
   ;
        ?debug  L 343
        mov     bx,dx
        mov     al,byte ptr [bx-2]
        cbw
        push    ax
        call    near ptr _spec
        pop     cx
        or      ax,ax
        jne     short @3@506
   ;
   ;
   ;            if(vowel(w[m-2])){
   ;
        ?debug  L 345
        mov     bx,si
        mov     al,byte ptr [bx+di-2]
        cbw
        push    ax
        call    near ptr _vowel
        pop     cx
        or      ax,ax
        je      short @3@450
   ;
   ;                    if(spec(w[m])) return(0);
   ;
        ?debug  L 346
        mov     bx,di
        mov     al,byte ptr [bx+si]
        cbw
        push    ax
        call    near ptr _spec
        pop     cx
        or      ax,ax
        je      @@51
        jmp     @3@58
@@51:
   ;
   ;                    if(consonant(w[m]) && (!lock(&w[m-1]))) return(0);
   ;
        ?debug  L 347
        mov     bx,di
        mov     al,byte ptr [bx+si]
        cbw
        push    ax
        call    near ptr _consonant
        pop     cx
        or      ax,ax
        je      short @3@506
        mov     ax,di
        add     ax,si
        dec     ax
        push    ax
        call    near ptr _lock
        pop     cx
        or      ax,ax
        jne     short @3@506
        jmp     @3@58
        jmp     short @3@506
@3@450:
   ;
   ;                    return(1);
   ;            }
   ;
   ;            if((w[m-3] == w[m-2]) || lock(&w[m-2])) return(0);
   ;
        ?debug  L 351
        mov     bx,di
        add     bx,si
        mov     dx,bx
        mov     al,byte ptr [bx-3]
        cmp     al,byte ptr [bx-2]
        jne     @@52
        jmp     @3@58
@@52:
        mov     ax,dx
        add     ax,-2
        push    ax
        call    near ptr _lock
        pop     cx
        or      ax,ax
        je      @@53
        jmp     @3@58
@@53:
@3@506:
        mov     ax,1
@3@534:
   ;
   ;            else return(1);
   ;    }
   ;
        ?debug  L 353
        pop     di
        pop     si
        pop     bp
        ret
        ?debug  C E601771808010800F1000C0600016D0408010B00+
        ?debug  C F1000C0700
        ?debug  E
        ?debug  E
letter  endp
   ;
   ;    static vowel(c)
   ;
        ?debug  L 355
        assume  cs:_TEXT
vowel   proc    near
        ?debug  B
        push    bp
        mov     bp,sp
        sub     sp,2
        ?debug  B
   ;
   ;    char c;
   ;    {
   ;            switch (c&0377)  {
   ;
        ?debug  L 358
        mov     al,byte ptr [bp+4]
        cbw
        and     ax,255
        mov     word ptr [bp-2],ax
        mov     cx,18
        mov     bx,offset @4@C50
@4@86:
        mov     ax,word ptr cs:[bx]
        cmp     ax,word ptr [bp-2]
        je      short @4@170
        add     bx,2
        loop    short @4@86
        jmp     short @4@226
@4@170:
        jmp     word ptr cs:[bx+36]
@4@198:
   ;
   ;            case 'А'&0xff: case 'а'&0xff:                   /*  А   */
   ;            case 'Е'&0xff: case 'е'&0xff:                   /*  Е   */
   ;            case 'И'&0xff: case 'и'&0xff:                   /*  И   */
   ;            case 'О'&0xff: case 'о'&0xff:                   /*  О   */
   ;            case 'У'&0xff: case 'у'&0xff:                   /*  У   */
   ;            case 'Ы'&0xff: case 'ы'&0xff:                   /*  Ы   */
   ;            case 'Э'&0xff: case 'э'&0xff:                   /*  Э   */
   ;            case 'Ю'&0xff: case 'ю'&0xff:                   /*  Ю   */
   ;            case 'Я'&0xff: case 'я'&0xff:   return(1);      /*  Я   */
   ;
        ?debug  L 367
        mov     ax,1
        jmp     short @4@254
@4@226:
   ;
   ;
   ;            default:        return(0);
   ;
        ?debug  L 369
        xor     ax,ax
@4@254:
   ;
   ;            }
   ;    }
   ;
        ?debug  L 371
        mov     sp,bp
        pop     bp
        ret
        ?debug  C E60163020A040000
        ?debug  E
        ?debug  E
vowel   endp
@4@C50  label   word
        db      128
        db      0
        db      133
        db      0
        db      136
        db      0
        db      142
        db      0
        db      147
        db      0
        db      155
        db      0
        db      157
        db      0
        db      158
        db      0
        db      159
        db      0
        db      160
        db      0
        db      165
        db      0
        db      168
        db      0
        db      174
        db      0
        db      227
        db      0
        db      235
        db      0
        db      237
        db      0
        db      238
        db      0
        db      239
        db      0
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
        dw      @4@198
   ;
   ;    static consonant(c)
   ;
        ?debug  L 373
        assume  cs:_TEXT
consonant       proc    near
        ?debug  B
        push    bp
        mov     bp,sp
        ?debug  B
   ;
   ;    char c;
   ;    {
   ;            if(vowel(c)) return(0);
   ;
        ?debug  L 376
        mov     al,byte ptr [bp+4]
        cbw
        push    ax
        call    near ptr vowel
        pop     cx
        or      ax,ax
        je      short @5@86
@5@58:
        xor     ax,ax
        jmp     short @5@142
@5@86:
   ;
   ;            if(spec(c)) return(0);
   ;
        ?debug  L 377
        mov     al,byte ptr [bp+4]
        cbw
        push    ax
        call    near ptr _spec
        pop     cx
        or      ax,ax
        jne     short @5@58
   ;
   ;            return(1);
   ;
        ?debug  L 378
        mov     ax,1
@5@142:
   ;
   ;    }
   ;
        ?debug  L 379
        pop     bp
        ret
        ?debug  C E60163020A040000
        ?debug  E
        ?debug  E
consonant       endp
   ;
   ;    static spec(c)
   ;
        ?debug  L 381
        assume  cs:_TEXT
spec    proc    near
        ?debug  B
        push    bp
        mov     bp,sp
        sub     sp,2
        ?debug  B
   ;
   ;    unsigned char c;
   ;    {
   ;            switch(c&0377) {
   ;
        ?debug  L 384
        mov     al,byte ptr [bp+4]
        mov     ah,0
        and     ax,255
        mov     word ptr [bp-2],ax
        mov     cx,6
        mov     bx,offset @6@C50
@6@86:
        mov     ax,word ptr cs:[bx]
        cmp     ax,word ptr [bp-2]
        je      short @6@170
        add     bx,2
        loop    short @6@86
        jmp     short @6@226
@6@170:
        jmp     word ptr cs:[bx+12]
@6@198:
   ;
   ;                   case 'Й'&0xff: case 'й'&0xff:
   ;                   case 'Ь'&0xff: case 'ь'&0xff:
   ;                   case 'ъ'&0xff: case 'Ъ'&0xff:
   ;                   return(1);
   ;
        ?debug  L 388
        mov     ax,1
        jmp     short @6@254
@6@226:
   ;
   ;            default: return(0);
   ;
        ?debug  L 389
        xor     ax,ax
@6@254:
   ;
   ;            }
   ;    }
   ;
        ?debug  L 391
        mov     sp,bp
        pop     bp
        ret
        ?debug  C E60163080A040000
        ?debug  E
        ?debug  E
spec    endp
@6@C50  label   word
        db      137
        db      0
        db      154
        db      0
        db      156
        db      0
        db      169
        db      0
        db      234
        db      0
        db      236
        db      0
        dw      @6@198
        dw      @6@198
        dw      @6@198
        dw      @6@198
        dw      @6@198
        dw      @6@198
   ;
   ;    static vows(st, n)
   ;
        ?debug  L 393
        assume  cs:_TEXT
vows    proc    near
        ?debug  B
        push    bp
        mov     bp,sp
        push    si
        push    di
        mov     di,word ptr [bp+6]
        ?debug  B
   ;
   ;    char *st;
   ;    {
   ;
   ;            register int i;
   ;            register char *cp;
   ;
   ;            i = n;
   ;
        ?debug  L 400
   ;
   ;            cp = st;
   ;
        ?debug  L 401
        mov     si,word ptr [bp+4]
   ;
   ;
   ;            if(i==0)
   ;
        ?debug  L 403
        or      di,di
        jne     short @7@226
        jmp     short @7@142
@7@86:
   ;
   ;                    {while(*cp) if(vowel(*cp++)) return(1);}
   ;
        ?debug  L 404
        mov     bx,si
        inc     si
        mov     al,byte ptr [bx]
        cbw
        push    ax
        call    near ptr vowel
        pop     cx
        or      ax,ax
        je      short @7@142
@7@114:
        mov     ax,1
        jmp     short @7@282
@7@142:
        cmp     byte ptr [si],0
        jne     short @7@86
        jmp     short @7@254
@7@198:
   ;
   ;            else
   ;                    {while(n--) if(vowel(*cp++)) return(1);}
   ;
        ?debug  L 406
        mov     bx,si
        inc     si
        mov     al,byte ptr [bx]
        cbw
        push    ax
        call    near ptr vowel
        pop     cx
        or      ax,ax
        jne     short @7@114
@7@226:
        mov     ax,di
        dec     di
        or      ax,ax
        jne     short @7@198
@7@254:
   ;
   ;
   ;            return(0);
   ;
        ?debug  L 408
        xor     ax,ax
@7@282:
   ;
   ;    }
   ;
        ?debug  L 409
        pop     di
        pop     si
        pop     bp
        ret
        ?debug  C E60263701808010B003C00040600016904080100+
        ?debug  C 000000040000027374180A040000016E04080108+
        ?debug  C 004E000C0700
        ?debug  E
        ?debug  E
vows    endp
   ;
   ;    static lock(st)
   ;
        ?debug  L 411
        assume  cs:_TEXT
lock    proc    near
        ?debug  B
        push    bp
        mov     bp,sp
        push    si
        mov     si,word ptr [bp+4]
        ?debug  B
   ;
   ;    char *st;
   ;    {
   ;
   ;            if(strncmp(&U[0], st, 2) == 0) return(1);
   ;
        ?debug  L 415
        mov     ax,2
        push    ax
        push    si
        mov     ax,offset DGROUP:U
        push    ax
        call    near ptr _strncmp
        add     sp,6
        or      ax,ax
        jne     short @8@86
@8@58:
        mov     ax,1
        jmp     short @8@170
@8@86:
   ;
   ;            if(strncmp(&U[2], st, 2) == 0) return(1);
   ;
        ?debug  L 416
        mov     ax,2
        push    ax
        push    si
        mov     ax,offset DGROUP:U+2
        push    ax
        call    near ptr _strncmp
        add     sp,6
        or      ax,ax
        je      short @8@58
   ;
   ;            if(strncmp(&U[4], st, 2) == 0) return(1);
   ;
        ?debug  L 417
        mov     ax,2
        push    ax
        push    si
        mov     ax,offset DGROUP:U+4
        push    ax
        call    near ptr _strncmp
        add     sp,6
        or      ax,ax
        je      short @8@58
   ;
   ;
   ;            return(0);
   ;
        ?debug  L 419
        xor     ax,ax
@8@170:
   ;
   ;    }
   ;
        ?debug  L 420
        pop     si
        pop     bp
        ret
        ?debug  C E6027374180801070040000C0600
        ?debug  E
        ?debug  E
lock    endp
_TEXT   ends
_BSS    segment word public 'BSS'
lword   label   word
        db      2 dup (?)
hp      label   word
        db      80 dup (?)
cp1     label   byte
        db      100 dup (?)
        ?debug  C E9
        ?debug  C FA55030000
_BSS    ends
_DATA   segment word public 'DATA'
s@      label   byte
_DATA   ends
_TEXT   segment byte public 'CODE'
_TEXT   ends
_lock   equ     lock
_vows   equ     vows
_consonant      equ     consonant
_spec   equ     spec
_vowel  equ     vowel
_letter equ     letter
_quasipref      equ     quasipref
        public  WRAP
        extrn   QPR:near
        extrn   _f_strncmp:far
        extrn   _f_strlen:far
        extrn   _strncmp:near
        extrn   _strcpy:near
        extrn   _strncpy:near
        extrn   _strlen:near
_lword  equ     lword
_hp     equ     hp
_cp1    equ     cp1
        extrn   WH:word
        extrn   WORDC:byte
_U      equ     U
_s@     equ     s@
        ?debug  C EA0109
        ?debug  C E31C00000023040000
        ?debug  C E31D00000023040000
        ?debug  C E31E00000023040000
        ?debug  C E31F00000023040000
        ?debug  C E32000000023040000
        ?debug  C E32100000023040000
        ?debug  C E32200000023040000
        ?debug  C E32300000023040100
        ?debug  C EC0457524150231800
        ?debug  C E32400000023190100
        ?debug  C EB035150522400
        ?debug  C E32500000023040400
        ?debug  C EB0A5F665F7374726E636D702500
        ?debug  C E32600000023040400
        ?debug  C EB095F665F7374726C656E2600
        ?debug  C E32700000023040000
        ?debug  C EB085F7374726E636D702700
        ?debug  C E32800000023040000
        ?debug  C EB075F7374726370792800
        ?debug  C E32900000023040000
        ?debug  C EB085F7374726E6370792900
        ?debug  C E32A00000023040000
        ?debug  C EB075F7374726C656E2A00
        ?debug  C E32B0050001A04
        ?debug  C E32C0064001A02
        ?debug  C E32D00FE011A04
        ?debug  C EB0257482D00
        ?debug  C E32E00FF001A02
        ?debug  C EB05574F5244432E00
        ?debug  C E32F0007001A02
        ?debug  C E6056C776F7264040000030000000268702B0000+
        ?debug  C 03020000036370312C00000352000001552F0000+
        ?debug  C 02000001E1000551707265661B07010A00
        ?debug  F lock 28 24 0
        ?debug  F vows 29 24 0
        ?debug  F consonant 30 24 0
        ?debug  F spec 31 24 0
        ?debug  F vowel 32 24 0
        ?debug  F letter 33 24 0
        ?debug  F quasipref 34 24 0
        ?debug  C E20004707265661800056C6F636B7318C0040000+
        ?debug  C 00
        end
