.model large
.data
$S22    db      0FFh
$S8     db      000h
$S5     db      000h
$S6     db      000h
__gr_ErrCode    dw      00000h

.code
        public detectgraph
detectgraph:
        push    bp
        mov     bp,sp
        push    ds
        mov     ax,@data
        mov     ds,ax
        push    [bp+008h]
        push    [bp+006h]
        push    [bp+00Ch]
        push    [bp+00Ah]

        call    far ptr __gr_detectgraph
        add     sp,+008h
        les     bx,dword ptr [bp+006h]
        cmp     word ptr es:[bx],+000h
        jnl     $L125
        mov     ax,0FFFEh
        mov     es:[bx],ax
        mov     __gr_ErrCode,ax
$L125:  pop     ds
        pop     bp
        retf    8

__gr_detectgraph:
        push    bp
        mov     bp,sp
        push    ds
        mov     ax,@DATA
        mov     ds, ax
        push    si
        push    di
        push    word ptr $S22
        call    near ptr $L24
        pop     word ptr $S22
        pop     di
        pop     si
        pop     ds
        pop     bp
        retf

$L24:   push    bp
        call    $L30
        pop     bp
        les     di,dword ptr [bp+006h]
        mov     al,$S5
        xor     ah,ah
        cmp     al,0FFh
        jnz     $L31
        mov     ah,al
$L31:   mov     es:[di],ax
        xor     ah,ah
        mov     al,$S8
        les     di,dword ptr [bp+00Ah]
        mov     es:[di],ax
        ret

$L30:   mov     byte ptr $S22,0FFh
        mov     byte ptr $S5,0FFh
        mov     byte ptr $S8,00h
        call    near ptr $L39
        mov     bl,$S5
        cmp     bl,0FFh
        jz      $L40
        xor     bh,bh
        mov     al,cs:[bx+$S29]
        mov     $S22,al
        mov     al,byte ptr cs:[bx+$S41]
        mov     $S8,al
        mov     al,byte ptr cs:[bx+$S28]
        mov     $S6,al
$L40:   ret
$L39:   mov     ah,0Fh
        int     10h
        cmp     al,07h
        jz      $L42
        call    $L43
        jnc     $L44
        mov     byte ptr $S5,06h
        ret
$L44:   call    near ptr $L45
        jnc     $L46
$L52:   call    near ptr $L47
        ret

$L46:   call    $L48
        and     ax,ax
        jz      $L49
        mov     byte ptr $S5,0Ah
        ret
$L49:   mov     byte ptr $S5,01h
        call    $L50
        jnc     $L51
        mov     byte ptr $S5,02h
$L51:   ret

$L42:   call    near ptr $L45
        jc      $L52
        call    $L53
        and     al,al
        jz      $L54
        mov     byte ptr $S5,07h
        ret
$L54:   mov     si,0B800h
        mov     es,si
        xor     si,si
        mov     ax,es:[si]
        not     ax
        not     word ptr es:[si]
        nop
        nop
        cmp     ax,es:[si]
        jnz     $L55
        mov     byte ptr $S5,01h
$L55:   ret
$L43:   xor     al,al
        ret

$L45:   mov     ax,1200h
        mov     bl,10h
        mov     bh,0FFh
        mov     cl,0Fh
        int     10h
        cmp     cl,0Ch
        jnl     $L56
        cmp     bh,01h
        jg      $L56
        cmp     bl,03h
        jg      $L56
        stc
        ret
$L56:   clc
        ret

$L50:   mov     ax,1A00h
        int     10h
        cmp     al,1Ah
        jnz     $L62
        cmp     bl,07h
        jz      $L63
        cmp     bl,08h
        jz      $L63
        cmp     bl,0Bh
        jc      $L62
        cmp     bl,0Ch
        jnbe    $L62
$L63:   stc
        ret
$L62:   clc
        ret

$L48:   mov     al,06h
        xor     cx,cx
        xor     dx,dx
        mov     ah,30h
        int     10h
        mov     ax,cx
        or      ax,dx
        jz      $L69
        push    ds
        mov     ds,cx
        mov     bx,dx
        mov     al,[bx+002h]
        pop     ds
        or      al,al
        jz      $L70
        cmp     al,02h
        jnz     $L69
$L70:   mov     dx,0188h
        in      al,dx
        test    al,04h
        jz      $L69
        mov     ax,0001h
        ret
$L69:   xor     ax,ax
        ret

$L47:   mov     byte ptr $S5,04h
        cmp     bh,01h
        jz      $L57
        call    near ptr $L58
        jc      $L59
        and     bl,bl
        jz      $L59
        mov     byte ptr $S5,03h
        call    near ptr $L50
        jc      $L60
        mov     bx,0C000h
        mov     es,bx
        mov     bx,0039h
        cmp     word ptr es:[bx],345Ah
        jnz     $L59
        cmp     word ptr es:[bx+002h],3934h
        jnz     $L59
$L60:   mov     byte ptr $S5,09h
$L59:   ret
$L57:   mov     byte ptr $S5,05h
        ret
$L58:   cmp     cl,02h
        jc      $L61
        cmp     cl,06h
        cmc
        jnc     $L61
        cmp     cl,08h
$L61:   ret

$L53:   mov     dx,03BAh
        xor     bl,bl
        in      al,dx
        and     al,80h
        mov     ah,al
        mov     cx,8000h
$L66:   in      al,dx
        and     al,80h
        cmp     al,ah
        jz      $L64
        inc     bl
        cmp     bl,0Ah
        jnc     $L65
$L64:   loop    $L66
        xor     al,al
        ret
$L65:   mov     cx,8000h
$L68:   in      al,dx
        and     al,30h
        cmp     al,10h
        jnz     $L67
        loop    $L68
        mov     al,02h
        ret
$L67:   mov     al,01h
        ret


$S29    db 000h, 000h, 000h, 001h, 001h, 001h, 002h
        db 003h, 004h, 001h, 005h, 006h, 007h, 0FFh
$S41    db 000h, 004h, 005h, 001h, 000h, 000h, 000h
        db 000h, 005h, 002h, 000h, 000h, 000h, 000h
$S28    db 000h, 004h, 005h, 001h, 001h, 000h, 001h
        db 000h, 005h, 002h, 000h, 000h, 000h, 07Fh
end
