                jumps
                locals
                .model Small
                include repeats.mac
                include strucs.mac

public          Buff_Size
;function Buff_Size(Var Str : String) : Word;
                .data
                PascalStr BuffKey,</B>

                .code
extrn           PosStr : near
;function PosStr(var SubStr,ScanStr) : Byte;

extrn           UpStr : near
;procedure UpStr(Var Str);

extrn           Delete : near
;procedure Delete(var Str,Index,Count: Word);

Buff_Size       proc near
;function Buff_Size(Var Str : String) : Word;
arg @@Str : DWord = @@ParamSize
Local @@Value : Word, @@Index : Byte, @@Count : Byte = @@LocalSize
                BeginProc @@LocalSize
                pushs <es,ds,si,di>
                mov @@Value,0
                mov @@Count,0
                mov @@Index,0
                lds si,@@Str
                mov ax,@Data
                push ax
                mov ax,offset BuffKey
                push ax
                pushs <ds,si>
                call PosStr
                or al,al
                jz @@Quit
                mov @@Index,al
                pushs <ds,si>
                xor ah,ah
                push ax
                mov al,2
                push ax
                call Delete
                mov al,@@Index
                xor ah,ah
                add si,ax
@@L0:           lodsb
                cmp al,'0'
                jb @@Exit
                cmp al,'9'
                ja @@Exit
                sub al,'0'
                mov bl,al
                xor bh,bh
                mov ax,10
                mul @@Value
                mov @@Value,ax
                add @@Value,bx
                inc @@Count
                jmp @@L0
@@Exit:         lds si,@@Str
                pushs <ds,si>
                xor ah,ah
                mov al,@@Index
                push ax
                mov al,@@Count
                push ax
                call Delete
@@Quit:         mov ax,@@Value
                pops <di,si,ds,es>
                EndProc @@ParamSize
Buff_Size       endp
                end
