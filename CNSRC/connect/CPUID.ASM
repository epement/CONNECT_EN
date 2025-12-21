                jumps
                locals
                .model Medium
public           cpuid, cpuidtst
                .data
                .code
                .386
CPUID           proc far
;procedure cpuid(i: longint; var eax; var ebx;
;                 var ecx; var edx);far;External;

;  begin
                push   bp
                mov    bp,sp
                mov    ax,[bp+16h] ; i
                mov    dx,[bp+18h]
                push   dx
                push   ax
                pop    eax
                dw 0a20fh; cpuid
                push   edx
                push   ecx
                push   ebx
                push   eax
;  eax_ := eax;
                pop    ax
                pop    dx
                les    di,[bp+12h] ;eax
                mov    es:[di],ax
                mov    es:[di+02h],dx
;  ebx_ := ebx;
                pop    ax
                pop    dx
                les    di,[bp+0eh] ;ebx
                mov    es:[di],ax
                mov    es:[di+02h],dx
;  ecx_ := i;
                pop    ax
                pop    dx
                les    di,[bp+0ah] ;ecx
                mov    es:[di],ax
                mov    es:[di+02h],dx
;  edx_ := i;
                pop    ax
                pop    dx
                les    di,[bp+06h] ;edx
                mov    es:[di],ax
                mov    es:[di+02h],dx
; end;
                pop    bp
                retf   0014h

CPUID           endp

CPUIDTST        proc far
                db 66h
                pushf
                db 66h
                pushf
                pop  eax
                mov  ecx,eax
                xor  eax,200000h
                push eax
                db 66h
                popf
                db 66h
                pushf
                pop  eax
                db 66h
                popf
                xor  eax,ecx
                setnz al
                retf
CPUIDTST        endp
                end