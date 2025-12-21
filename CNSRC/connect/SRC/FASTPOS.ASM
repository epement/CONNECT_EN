		.model TPascal
		.code
		public FastPos
FastPos		proc
		push   bp
		mov    bp,sp
		push   ds
		lds    si,[bp+0Ah]
		cld
		lodsb
		or     al,al
		je     @@3
		mov    dl,al
		xor    dh,dh
		les    di,[bp+06]
		mov    cl,es:[di]
		xor    ch,ch
		sub    cx,dx
		jb     @@3
		inc    cx
		inc    di
@@1:		lodsb
		repnz scasb
		jne    @@3
		mov    ax,di
		mov    bx,cx
		mov    cx,dx
		dec    cx
		rep cmpsb
		je     @@4
		mov    di,ax
		mov    cx,bx
		mov    si,[bp+0Ah]
		inc    si
		jmp    @@1
@@3:		xor    ax,ax
		jmp    @@5
@@4:		dec    ax
		sub    ax,[bp+06]
@@5:		pop    ds
		pop    bp
		retf   0008
FastPos		endp
		end
