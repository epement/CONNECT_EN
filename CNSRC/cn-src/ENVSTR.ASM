		jumps
		locals
		.model Small
		include	repeats.mac
		include	strucs.mac
		.code

public		EnvStr
;procedure  EnvStr(var SetVar,DStr : String;PSPSeg : Word)

public		GetProgStr
;Procedure GetProgStr(var MyPath; PSPSeg : Word);

public		ASCIIZLen
;function ASCIIZLen(var	ASCIIZStr) : Word

;public		 FirstParam
;Procedure FirstParam(PSPSeg : word);

public		ConcatPasStr
;procedure ConcatPasStr(var SStr,DStr :	PasStr)

;public		 CharPresent
;function CharPresent(var ScanStr : PasStr, Char : Byte):Byte

EnvStr		proc near

;procedure  EnvStr(var SetVar,DStr : String;PSPSeg : Word)
;var
; StrLength : Byte;
arg @@PSPSeg : Word, @@DStr : DWord, @@SetVar :	DWord =	@@ParamSize
Local @@StrLength : word = @@LocalSize
		BeginProc @@LocalSize
		push ds
		push es
		mov ds,@@PSPSeg
		mov es,	Word Ptr ds:[002ch]
		lds si,@@SetVar
		cld
		lodsb
		xor ch,ch
		mov cl,al
		mov @@StrLength,cx

		xor di,di
		xor cx,cx
@@l0:		push cx
		push si
		mov cx,@@StrLength
		repe cmpsb
		pop si
		pop cx
		loopne @@l0
		jne @@Exit
		mov si,di
		mov dx,es
		mov ds,dx
		les di,@@DStr
@@l1:		lodsb
		stosb
		or al,al ;cmp al,0
		jnz @@l1
@@Exit:		pop es
		pop ds
		EndProc	@@ParamSize
EnvStr		endp

GetProgStr	proc near
;Procedure GetProgStr(var MyPath; PSPSeg : Word);
arg @@pspseg : word,@@mypath:dword = @@paramsize
;@@PSPSeg	 equ [bp + 4]
;@@MyPath	 equ [bp + 6]
;@@ParamSize	 equ 6
		push bp
		mov bp,sp
		push ds
		push es
		mov ds,@@PSPSeg
		mov es,	Word Ptr ds:[002ch]
		xor di,di
		cld
		xor al,al
@@l0:		cmp al,	byte ptr es:[di]
		je @@l1
		mov cx,0ffffh
		repnz scasb
		jmp @@l0
@@l1:		add di,3
		mov si,di
		mov cx,100h
		repnz scasb
		std
		dec di
		mov al,'\'
		xchg bl,cl
		not bl
		mov cx,100h
		repnz scasb
		cld
		not cl
		sub bl,cl
		inc bl
		mov cl,bl
		push es
		pop ds
		les di,@@MyPath
		mov byte ptr es:[di],bl
		inc di
		rep movsb
		pop es
		pop ds
		mov sp,bp
		pop bp
		ret @@ParamSize
GetProgStr	endp

ASCIIZLen	proc near
;function ASCIIZLen(var	ASCIIZStr) : Word
@@ASCIIZStr	equ [bp	+ 4]
@@ParamSize	equ 4
		push bp
		mov bp,sp
		push es
		push di
		cld
		les di,@@ASCIIZStr
		xor al,al ;mov al,0
		mov cx,0ffffh
		repne scasb
		je @@L0
		mov ax,0ffffh
		jmp @@Exit
@@L0:		not cx
		dec cx
		mov ax,cx
@@Exit:		pop di
		pop es
		mov sp,bp
		pop bp
		ret @@ParamSize
ASCIIZLen	endp

comment~
FirstParam	proc near
;Procedure FirstParam(PSPSeg : word);
arg @@PSPSeg : Word = @@ParamSize
local @@StrLength : Byte = @@LocalSize
		push bp
		mov bp,sp
		sub sp,@@LocalSize
		pushs <es,di,ds,si>
		mov es,@@PSPSeg
		mov ds,@@PSPSeg
		mov si,80h
		mov di,81h
		lodsb
		mov @@StrLength,al
		or al,al ;cmp al,0
		je @@Exit
@@Space1:	lodsb
		cmp al,' '
		jne @@L1
		dec byte ptr ds:[80h]
		dec @@StrLength
		jmp @@Space1
@@L1:		xor ah,ah
@@L0:		stosb
		lodsb
		inc ah
		cmp al,' '
		je @@Space2
		cmp ah,@@StrLength
		jnc @@Space2
		jmp @@L0
@@Space2:	sub di,81h
		mov ax,di
		mov byte ptr ds:[80h],al
		cmp byte ptr ds:[81h],0dh
		jne @@Exit
		mov byte ptr ds:[80h],0
@@Exit:		pops<si,ds,di,es>
		mov sp,bp
		pop bp
		ret @@ParamSize
FirstParam	endp
~

ConcatPasStr	proc near
;procedure ConcatPasStr(var SStr,DStr :	PasStr)
arg @@DStr : DWord, @@SStr : DWord = @@ParamSize
@@LocalSize = 0
		BeginProc @@LocalSize
		pushs <ds,es,di,si>
		les di,@@DStr
		lds si,@@SStr
		lodsb
		mov cl,byte ptr	es:[di]	; Length(DSstr)
		xor ch,ch
		add byte ptr es:[di],al
		add di,cx
		inc di
		mov cl,al
		cld
		rep movsb
		pops <si,di,es,ds>
		EndProc	@@ParamSize
ConcatPasStr	endp

comment~
CharPresent	proc near
;function CharPresent(var ScanStr : PasStr, Char : Byte):Byte
arg @@Char : Byte, @@ScanStr : DWord = @@ParamSize
@@LocalSize = 0
		BeginProc @@LocalSize
		pushs <es,di>
		les di,@@ScanStr
		mov cl,byte ptr	es:[di]
		inc di
		mov al,@@Char
		repne scasb
		je @@OK
		xor al,al
		jmp @@Exit
@@OK:		mov al,1
@@Exit:		pops <di,es>
		EndProc	@@ParamSize
CharPresent	endp
~
		end
