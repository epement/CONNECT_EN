                jumps
                locals
                .model Small
                include repeats.mac
                include strucs.mac
                .code

public          PosStr
;function PosStr(var SubStr,ScanStr) : Byte;

public          UpStr
;procedure UpStr(Var Str);

public          Delete
;procedure Delete(var Str,Index,Count);

PosStr          proc near
;function PosStr(var SubStr,ScanStr) : Byte;
arg @@ScanStr : DWord,@@SubStr : DWord = @@ParamSize
local @@StrLength : Word = @@LocalSize
                push bp
                mov bp,sp
                sub sp,@@LocalSize
                pushs <es,di,ds,si>
                cld

                lds si,@@SubStr
                lodsb
                xor ch,ch
                mov cl,al
                mov @@StrLength,cx

                les di,@@ScanStr
                mov al,byte ptr es:[di]
                inc di
                xor ch,ch
                mov cl,al
                jcxz @@NotOK

@@l0:           pushs <cx,si>
                mov cx,@@StrLength
                repe cmpsb
                pops <si,cx>
                loopne @@l0
                je @@OK

@@NotOK:        xor al,al
                jmp @@Exit

@@OK:           mov ax,di
                les di,@@ScanStr
                sub ax,di
                sub al,byte ptr ds:[si-1]

@@Exit:         pops <si,ds,di,es>
                mov sp,bp
                pop bp
                ret @@ParamSize
PosStr          endp

UpStr           proc near
;procedure UpStr(Var Str);
arg @@Str : DWord = @@ParamSize
@@LocalSize = 0
                BeginProc @@LocalSize
                pushs <es,ds,si,di>
                lds si,@@Str
                les di,@@Str
                xor ax,ax
                lodsb
                or al,al
                jz @@Exit
                mov cx,ax
                stosb
@@L1:           lodsb
                cmp al,'a'
                jb @@L0
                cmp al,'z'
                ja @@L0
                sub al,32;'A'-'a'
@@L0:           stosb
                loop @@L1
@@Exit:         pops <di,si,ds,es>
                EndProc @@ParamSize
UpStr           endp

Delete          proc near
;procedure Delete(var Str,Index,Count);
arg @@Count : Word, @@Index : Word, @@Str : DWord = @@ParamSize
@@LocalSize = 0
                BeginProc @@LocalSize
                pushs <es,ds,si,di>
                cmp @@Count,0
                je @@Exit
                lds si,@@Str
                les di,@@Str
                xor cx,cx
                mov cl,byte ptr ds:[si]
                inc cl
                sub cx,@@Count
                sub cx,@@Index
                jb @@Exit
                add si,@@Index
                add si,@@Count
                add di,@@Index
                cld
                rep movsb
                mov ax,@@Count
                lds si,@@Str
                sub byte ptr ds:[si],al
@@Exit:         pops <di,si,ds,es>
                EndProc @@ParamSize
Delete          endp
                end
