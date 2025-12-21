	.386p
	ifdef ??version
	if ??version GT 500H
	.mmx
	endif
	endif
	model flat
	ifndef	??version
	?debug	macro
	endm
	endif
	?debug	S "t1.cpp"
	?debug	T "t1.cpp"
_TEXT	segment dword public use32 'CODE'
_TEXT	ends
_DATA	segment dword public use32 'DATA'
_DATA	ends
_BSS	segment dword public use32 'BSS'
_BSS	ends
DGROUP	group	_BSS,_DATA
_BSS	segment dword public use32 'BSS'
	align	4
_x1	label	byte
	db	80	dup(?)
_BSS	ends
_TEXT	segment dword public use32 'CODE'
@aaa$qv	segment virtual
@@aaa$qv	proc	near
?live16385@0:
 ;	
 ;	void aaa()
 ;	
	push ebp
	mov ebp,esp
 ;	
 ;	{
 ;	}
 ;	
@1:
@2:
	pop ebp
	ret 
_INIT_	segment word public use32 'INITDATA'
_INIT_	ends
@@aaa$qv	endp
@aaa$qv	ends
_TEXT	ends
_INIT_	segment word public use32 'INITDATA'
	db	0
	db	32
	dd	@_STCON0_$qv
_INIT_	ends
_TEXT	segment dword public use32 'CODE'
@aaa$qv	segment virtual
@aaa$qv	ends
_TEXT	ends
_DATA	segment dword public use32 'DATA'
	align	4
@_$DCB$@_STCON0_$qv	label	dword
	dd	@@$xt$a10$3xxx
	dd	0
	dd	_x1
	dd	0
	align	4
@_$ECTC$@_STCON0_$qv	label	dword
	dd	0
	dd	-36
	dw	0
	dw	5
	dd	0
	dd	@_$DCB$@_STCON0_$qv
_DATA	ends
_TEXT	segment dword public use32 'CODE'
@_STCON0_$qv	proc	near
@@_STCON0_$qv equ @_STCON0_$qv
?live1@0:
	push ebp
	mov ebp,esp
	add esp,-36
@3:
	mov eax,offset @_$ECTC$@_STCON0_$qv
	call @__InitExceptBlockLDTC
	push offset @@xxx@$bdtr$qv
	push 1
	push offset @@xxx@$bctr$qv
	push 1
	push 10
	push 8
	push offset _x1
	call @_vector_new_ldtc_$qpvuiuiuit1uit1
	add esp,28
	add dword ptr [ebp-8],10
	mov word ptr [ebp-20],8
	mov edx,dword ptr [ebp-36]
	mov dword ptr fs:[0],edx
@4:
	mov esp,ebp
	pop ebp
	ret 
_EXIT_	segment word public use32 'EXITDATA'
_EXIT_	ends
@_STCON0_$qv	endp
_TEXT	ends
_EXIT_	segment word public use32 'EXITDATA'
	db	0
	db	32
	dd	@_STDES0_$qv
_EXIT_	ends
_TEXT	segment dword public use32 'CODE'
_TEXT	ends
_DATA	segment dword public use32 'DATA'
	align	4
@_$ECTD$@_STDES0_$qv	label	dword
	dd	0
	dd	-36
_DATA	ends
_TEXT	segment dword public use32 'CODE'
@_STDES0_$qv	proc	near
@@_STDES0_$qv equ @_STDES0_$qv
?live1@48:
	push ebp
	mov ebp,esp
	add esp,-36
@5:
	mov eax,offset @_$ECTD$@_STDES0_$qv
	call @__InitExceptBlockLDTC
	add dword ptr [ebp-8],-10
	push offset @@xxx@$bdtr$qv
	push 1
	push 10
	push 8
	push offset _x1
	call @_vector_delete_ldtc_$qpvuiuiuit1
	add esp,20
	mov edx,dword ptr [ebp-36]
	mov dword ptr fs:[0],edx
@6:
	mov esp,ebp
	pop ebp
	ret 
@_STDES0_$qv	endp
_TEXT	ends
_TEXT	segment dword public use32 'CODE'
@$xt$a10$3xxx	segment virtual
	align	2
@@$xt$a10$3xxx	label	byte
	dd	80
	dw	1024
	dw	16
	dd	@@$xt$3xxx
	dd	10
	db	120
	db	120
	db	120
	db	91
	db	49
	db	48
	db	93
	db	0
@$xt$a10$3xxx	ends
_TEXT	ends
_DATA	segment dword public use32 'DATA'
@_$DCE$@xxx@$bctr$qv	segment virtual
	align	2
@@_$DCE$@xxx@$bctr$qv	label	dword
	dd	@@$xt$p3xxx
	dd	5
	dd	8
	dd	0
@_$DCE$@xxx@$bctr$qv	ends
_DATA	ends
_DATA	segment dword public use32 'DATA'
@_$ECTF$@xxx@$bctr$qv	segment virtual
	align	2
@@_$ECTF$@xxx@$bctr$qv	label	dword
	dd	0
	dd	-36
	dw	0
	dw	5
	dd	0
	dd	@@_$DCE$@xxx@$bctr$qv
@_$ECTF$@xxx@$bctr$qv	ends
_DATA	ends
_TEXT	segment dword public use32 'CODE'
@xxx@$bctr$qv	segment virtual
@@xxx@$bctr$qv	proc	near
?live16386@0:
	push ebp
	mov ebp,esp
	add esp,-36
@7:
	mov eax,offset @@_$ECTF$@xxx@$bctr$qv
	call @__InitExceptBlockLDTC
	mov word ptr [ebp-20],8
	push offset s@
	call @_printf
	pop ecx
	mov edx,dword ptr [ebp-36]
	mov dword ptr fs:[0],edx
	mov eax,dword ptr [ebp+8]
@9:
@8:
	mov esp,ebp
	pop ebp
	ret 
@@xxx@$bctr$qv	endp
@xxx@$bctr$qv	ends
_TEXT	ends
_TEXT	segment dword public use32 'CODE'
@xxx@$bdtr$qv	segment virtual
@@xxx@$bdtr$qv	proc	near
?live16387@0:
	push ebp
	mov ebp,esp
	push ebx
	mov ebx,dword ptr [ebp+8]
@10:
	test ebx,ebx
	je        short @11
	push offset s@+5
	call @_printf
	pop ecx
	test byte ptr [ebp+12],1
	je        short @12
	push ebx
	call @$bdele$qpv
	pop ecx
@12:
@11:
@13:
	pop ebx
	pop ebp
	ret 
@@xxx@$bdtr$qv	endp
@xxx@$bdtr$qv	ends
_TEXT	ends
_TEXT	segment dword public use32 'CODE'
@$xt$p3xxx	segment virtual
	align	2
@@$xt$p3xxx	label	dword
	dd	4
	dw	16
	dw	12
	dd	@@$xt$3xxx
	db	120
	db	120
	db	120
	db	32
	db	42
	db	0
@$xt$p3xxx	ends
_TEXT	ends
_TEXT	segment dword public use32 'CODE'
@$xt$3xxx	segment virtual
	align	2
@@$xt$3xxx	label	byte
	dd	8
	dw	3
	dw	48
	dd	-1
	dd	3
	dw	52
	dw	56
	dd	0
	dw	0
	dw	0
	dd	0
	dd	1
	dd	1
	dd	@@xxx@$bdtr$qv
	dw	1
	dw	60
	db	120
	db	120
	db	120
	db	0
	dd	0
	dd	0
	dd	0
@$xt$3xxx	ends
_TEXT	ends
_DATA	segment dword public use32 'DATA'
s@	label	byte
	;	s@+0:
	db	"xxx",10,0
	;	s@+5:
	db	"~xxx",10,0
	align	4
_DATA	ends
_TEXT	segment dword public use32 'CODE'
_TEXT	ends
 extrn __Exception_list:dword
	public	_x1
 extrn @_vector_new_ldtc_$qpvuiuiuit1uit1:near
 extrn @__InitExceptBlockLDTC:near
 extrn @_vector_delete_ldtc_$qpvuiuiuit1:near
@_printf equ _printf
 extrn _printf:near
 extrn @$bdele$qpv:near
	?debug	D "C:\Program Files\Borland\CBuilder6\Include\_nfile.h" 11326 35844
	?debug	D "C:\Program Files\Borland\CBuilder6\Include\_null.h" 11326 35844
	?debug	D "C:\Program Files\Borland\CBuilder6\Include\_defs.h" 11326 35844
	?debug	D "C:\Program Files\Borland\CBuilder6\Include\_stddef.h" 11326 35844
	?debug	D "C:\Program Files\Borland\CBuilder6\Include\stdio.h" 11326 35885
	?debug	D "t1.cpp" 13594 22295
	end
