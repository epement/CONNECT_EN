		.MODEL	 TPASCAL
		jumps
		locals
		.CODE
		public findfCBr,findCBr,findQCBr

;function findfCBr(Var Str : String; OBr : Byte) : Byte;
findfCBr	proc far @@S : Dword, @@Obr : Byte
		push ds
		lds si,@@S
		mov cl,[di]
		sub cl,@@Obr
		inc cl
		xor ch,ch
		mov al,@@Obr
		xor ah,ah
		add si,ax
		mov dx,si
		xor bx,bx
		cld
@@L0:		lodsb
		cmp al,'{'
		jne @@L1
		inc bl
@@L1:		cmp al,'}'
		jne @@L2
		inc bh
@@L2:		cmp bl,bh
		je @@L3
		loop @@L0
@@L3:		cmp bl,bh
		mov al,0
		jne @@Exit
		mov ax,si
		sub ax,dx
		add al,@@Obr
		dec al
@@Exit:		pop ds
		mov sp,bp
		pop bp
		retf 6
findfCBr	endp

;function findCBr(Var Str : String; OBr	: Byte)	: Byte;
findCBr	proc far @@S : Dword, @@Obr : Byte
		push ds
		lds si,@@S
		mov cl,[di]
		sub cl,@@Obr
		inc cl
		xor ch,ch
		mov al,@@Obr
		xor ah,ah
		add si,ax
		mov dx,si
		xor bx,bx
		cld
@@L0:		lodsb
		cmp al,'('
		jne @@L1
		inc bl
@@L1:		cmp al,')'
		jne @@L2
		inc bh
@@L2:		cmp bl,bh
		je @@L3
		loop @@L0
@@L3:		cmp bl,bh
		mov al,0
		jne @@Exit
		mov ax,si
		sub ax,dx
		add al,@@Obr
		dec al
@@Exit:		pop ds
		mov sp,bp
		pop bp
		retf 6
findCBr		endp

;function findQCBr(Var Str : String; OBr : Byte) : Byte;
findQCBr	proc far @@S : Dword, @@Obr : Byte
		push ds
		lds si,@@S
		mov cl,[di]
		sub cl,@@Obr
		inc cl
		xor ch,ch
		mov al,@@Obr
		xor ah,ah
		add si,ax
		mov dx,si
		xor bx,bx
		cld
@@L0:		lodsb
		cmp al,'['
		jne @@L1
		inc bl
@@L1:		cmp al,']'
		jne @@L2
		inc bh
@@L2:		cmp bl,bh
		je @@L3
		loop @@L0
@@L3:		cmp bl,bh
		mov al,0
		jne @@Exit
		mov ax,si
		sub ax,dx
		add al,@@Obr
		dec al
@@Exit:		pop ds
		mov sp,bp
		pop bp
		retf 6
findQCBr	endp

		end
