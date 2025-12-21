		jumps
		locals
		.model Small
		include	strucs.mac
		include	repeats.mac

public		FileRead
;Procedure FileRead(Var	Buffer;	BuffSize : Word	; Var FileName : ASCIIZ);

		.data
extrn		IORes :	Word

		.code
extrn		FileClose : near
;Procedure FileClose(Handle : Word);

extrn		FileOpen : near
;Procedure FileOpen (var FileStr : ASCIIZ; var Handle :	Word,Mode: Word);

FileRead	proc near
;Procedure FileRead(Var	Buffer;	BuffSize : Word; Var FileName :	ASCIIZ);
arg @@FileName : DWord,	@@BuffSize : Word, @@Buffer : DWord = @@ParamSize
Local @@Handler	: Word = @@LocalSize
		BeginProc @@LocalSize
		pushs <ds,es>
		les di,@@FileName
		pushs <es,di>
		lea di,@@Handler
		pushs<ss,di>
		xor ax,ax ;mov ax,0
		push ax
		call FileOpen
		cmp IORes,0
		jnz @@Exit
		mov ah,3fh
		mov bx,@@Handler
		push ds
		lds dx,@@Buffer
		mov cx,@@BuffSize
		int 21h
		pop ds
		mov IORes,ax
		jc @@Exit
		mov IORes,0
		push @@Handler
		call FileClose
@@Exit:		pops <es,ds>
		EndProc	@@ParamSize
FileRead	endp
		end

