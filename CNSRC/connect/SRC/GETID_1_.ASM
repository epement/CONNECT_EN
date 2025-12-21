                .MODEL   TPASCAL
                jumps
                locals
                .CODE
                public GetLeftId, ZInTest, GetRightId, Getliterals, SCopy
                public GetRight

ZInTest:        push   bp
                mov    bp,sp
                push   cx dx
                mov    al,[bp+0Ah]
                mov    ah,1
                mov    dx,20h
                mov    ch,al
                mov    cl,3
                shr    ch,cl
                sub    ch,dh
                jb     @@1
                cmp    ch,dl
                jnb    @@1
                mov    dl,ch
                xor    dh,dh
                and    al,7
                mov    cl,al
                mov    al,ah
                rol    al,cl
                jmp    @@3
@@1:            cwd
                xchg   dx,ax
                xor    dx,dx
@@3:            les    di,[bp+6]
                add    di,dx
                test   es:[di],al
                mov    al,0
                je     @@2
                inc    ax
@@2:            pop    dx cx
                mov    sp,bp
                pop    bp
                retf   6
comment~
 function GetLeftId(Const S : String; var Ps : Byte) : String;
 var
  Str : String;
 begin
  Str := '';
  while (Ps > 1) and (S[Ps-1] in IdChars) do
   begin
    if S[Ps-1] <> ' ' then Str := S[Ps-1] + Str;
    Dec(Ps);
   end;
  GetLeftId := Str;
 end;
~
; function GetLeftId(Const S : String;Const IdChars : Set of char; var Ps : Byte) : String;
GetLeftId       proc far @@Result : dword, @@S : dword, @@IdChars : dword, @@Ps : Dword
                push ds
                lds si,@@Ps
                mov cx,[si]
                xor ch,ch
                dec cl
                lds si,@@S
                mov dx,si
                add si,cx
                les di,@@Result
                mov byte ptr es:[di],0
                add di,255
                std
                xor bh,bh      ; счетчик длины @@Result
@@L0:           lodsb
                cmp al,' '
                jne @@2
                or bh,bh
                je @@L1
@@2:            mov bl,al
                push es di bx
                push ax
                les di,@@IDChars
                push es di cs
                call ZInTest
                pop bx di es
                or al,al
                jz @@Exit
                mov al,bl
                inc bh
                stosb
@@L1:           loop @@L0
@@Exit:         or bh,bh
                jz @@l2
                jcxz @@L3
                xchg dx,si
                sub dx,si
                add dl,2
                jmp @@L4
@@L3:           mov dl,1
@@L4:           lds si,@@Ps
                mov [si],dl
                les di,@@Result
                mov es:[di],bh
                mov cl,bh
                xor ch,ch
                add di,cx
                lds si,@@Result
                add si,255
                rep movsb
@@L2:           cld
                pop ds
                pop bp
                retf 12
GetLeftId       endp
comment~
 function GetRightId(Const S : String; var Ps : Byte) : String;
 var
  Str : String;
 begin
  Str := '';
  while (Ps < Length(S)) and (S[Ps+1] in IdChars) do
   begin
    if S[Ps+1] <> ' ' then Str := Str + S[Ps+1];
    Inc(Ps);
   end;
  GetRightId := Str;
 end;
~
; function GetRightId(Const S : String;Const IdChars : Set of char; var Ps : Byte) : String;
GetRightId      proc far @@Result : dword, @@S : dword, @@IdChars : dword, @@Ps : Dword
                push ds
                lds si,@@Ps
                mov al,[si]
                xor ah,ah
                lds si,@@S
                mov dx,si
                inc dx
                mov cl,[si]
                xor ch,ch
                sub cl,al
                add si,ax
                inc si
                les di,@@Result
                mov byte ptr es:[di],0
                inc di
                cld
                xor bh,bh
@@L0:           lodsb
                cmp al,' '
                jne @@2
                or bh,bh
                je @@L1
@@2:            mov bl,al
                push es di bx
                push ax
                les di,@@IDChars
                push es di cs
                call ZInTest
                pop bx di es
                or al,al
                jz @@Exit
                mov al,bl
                inc bh
                stosb
@@L1:           loop @@L0
@@Exit:         or bh,bh
                jz @@L2
                xchg dx,si
                sub dx,si
                jcxz @@L3
                dec dx
@@L3:           les di,@@Ps
                mov es:[di],dl
                les di,@@Result
                mov es:[di],bh
@@L2:           pop ds
                pop bp
                retf 12
GetRightId      endp

; function GetRight(Const S : String;Const IdChars : Set of char; var Ps : Byte) : String;
GetRight        proc far @@Result : dword, @@S : dword, @@IdChars : dword, @@Ps : Dword
                push ds
                lds si,@@Ps
                mov al,[si]
                xor ah,ah
                lds si,@@S
                mov dx,si
                inc dx
                mov cl,[si]
                xor ch,ch
                sub cl,al
                add si,ax
                inc si
                les di,@@Result
                mov byte ptr es:[di],0
                inc di
                cld
                xor bh,bh
@@L0:           lodsb
                mov bl,al
                push es di bx
                push ax
                les di,@@IDChars
                push es di cs
                call ZInTest
                pop bx di es
                or al,al
                jz @@Exit
                mov al,bl
                inc bh
                stosb
@@L1:           loop @@L0
@@Exit:         or bh,bh
                jz @@L2
                xchg dx,si
                sub dx,si
                jcxz @@L3
                dec dx
@@L3:           les di,@@Ps
                mov es:[di],dl
                les di,@@Result
                mov es:[di],bh
@@L2:           pop ds
                pop bp
                retf 12
GetRight        endp

comment ~
function GetLiterals(const Str : String;  var Ps1,Ps2 : Byte):String;
{Читает строку Str начиная с Ps1}
{Возвращает найденную в литералах строку и ее начальную и конечную}
{позиции в исходной строке}
~
Getliterals     proc far @@Result : dword, @@S : dword, @@Ps1 : dword, @@Ps2 : Dword
                push ds
                lds si,@@Ps1
                mov bl,[si]
                xor dh,dh
                xor bh,bh
                lds si,@@S
                lodsb
                xor ah,ah
                sub al,bl
                jb @@Exit
                mov cx,ax
                inc cx
                les di,@@S
                add di,bx
                mov al,22h ; " ; 27h ; '
                cld
@@Loop1:        repne scasb
                jcxz @@Exit
@@1:            mov bx,di
                sub bx,si ; bl=ps1
                mov bh,bl
                mov si,di
                les di,@@Result
                inc di
@@Loop2:        lodsb
                cmp al,'"'
                je @@Exit
                stosb
                inc bh    ; bh = ps2
                inc dh    ; dh = Length(@@Result)
                loop @@loop2
                xor bh,bh
@@Exit:         les di,@@Result
                mov es:[di],dh ;@@Result[0] = dh
                les di,@@Ps1
                mov es:[di],bl
                or bh,bh
                je @@2
                inc bh
@@2:            les di,@@Ps2
                mov es:[di],bh
                pop ds
                pop bp
                retf 12
Getliterals     endp

; copy standard function
; in    [sp+8] = destination pointer
;       [sp+4] = source pointer
;       [sp+2] = index
;       [sp]   = length
; out   sp     = sp+8

SCopy:          cld
                mov     bx,sp
                mov     dx,ds
                mov al,ss:[bx+4] ; Count
                mov cl,ss:[bx+6] ; Index
                xor ah,ah
                xor ch,ch
                sub ax,cx
                ja @@L1
                neg ax
                mov ah,ss:[bx+4]
                mov ss:[bx+6],ah
@@L1:           mov ss:[bx+4],al
                les     di,ss:[bx+12]
                lds     si,ss:[bx+8]
                mov     al,[si]
                xor     ah,ah
                mov     cx,ss:[bx+6]
                or      cx,cx
                jg      @@1
                mov     cx,1
@@1:            add     si,cx
                sub     ax,cx
                jb      @@3
                inc     ax
                mov     cx,ss:[bx+4]
                or      cx,cx
                jge     @@2
                xor     cx,cx
@@2:            cmp     ax,cx
                jbe     @@4
                mov     ax,cx
                jmp     short @@4
@@3:            xor     ax,ax
@@4:            stosb
                mov     cx,ax
                rep     movsb
                mov     ds,dx
                retf    8
                end
