; -----------------------------------------------------------------------------
; SMM.ASM	Tests if central processor is SMMable.		  Version 1.04
;
; Copyright(c) 1994,95 by B-coolWare.  Written by Bobby Z.
; This code is part of TMi0SDGL(tm) CPU/FPU Feature Detection Library.
; -----------------------------------------------------------------------------
; SMM = System Management Mode
;
; SMM support is available on all new SL Enhanced CPUs but it requires special
; hardware on motherboard to be usable. Such hardware is usually present in
; notebook computers and likes and is used to implement power saving functions.

; The following code uses several approaches to determine whether processor is
; SL Enhanced: first it uses the fact that SL Enhanced 486s (at least from
; Intel) support so-called Virtual Mode Extension (VME) which can be checked
; using CPUID instruction. Then it tries to execute a special SMM instruction
; that should work only on CPUs with SMM support. If either check fails, it
; assumes that CPU is not SL Enhanced.

	INCLUDE	HEADER.ASH

	.CODE

EF_ID	equ	00200000h	; ID flag of EFLAGS
ffVME	equ	2		; VME support feature flag

	PUBLIC	isSMMAble

int6H:			; INT 6 (invalid instruction) trap hook
	clr	ax
	add	sp,4	; restore stack and jump past offending instruction
	popf
	jmp	Past_invalid

check386	proc near	; SMM is only supported on 386s and higher
	push	sp
	pop	ax
	cmp	ax,sp
	jnz	@@2
	pushf
	mov	ax,7000h
	push	ax
	popf
	pushf
	pop	ax
	popf
	and	ah,70h
	jnz	@@1
@@2:
	stc
	ret
@@1:
	clc
	ret
	endp

getVMEFlag	proc	near
; Intel's SL Enhanced 486s do support VME, while prior models unlikely.
	.386
	pushfd
	pushfd
	pop	eax
	xor	eax,EF_ID	; check if ID flag flips, that is that CPUID
	push	eax		; is supported on this CPU
	popfd
	pushfd
	pop	ebx
	popfd
	and	eax,EF_ID
	and	ebx,EF_ID
	cmp	eax,ebx		; should be equal if ID flag flipped
	mov	ah,0
	jnz	@@fail
	mov	eax,1		; get processor ID and feature flags
IF ??version LT 400h
	db	0Fh,0A2h
ELSE
	.586
	cpuid
ENDIF
	and	ah,0Fh		; mask out family ID
	cmp	ah,4		; 486 family?
	jnz	@@fail		; no - no use in VME flag
	test	dx,ffVME	; yes - test if VME flag set
	jz	@@fail
	clc
	jmp	@@Q
@@fail:
	stc
	.8086
@@Q:
	ret
	endp

isSMMAble	PROC
	call	check386	; 386 or up?
	mov	ax,0		; assume false
	jc	@@Q
	call	getVMEFlag	; if current CPU supports CPUID and VME flag is
	mov	al,1		; assume true
	jnc	@@Q		; set, then this CPU is SL Enhanced (not P5+)
	cmp	ah,5		; ah contains family ID or 0 if CPUID not
	mov	ax,0		; assume false
	jae	@@Q		; supported. Following test don't work on P5+.
	push	ds
	mov	ax,3506h	; get current INT 6 vector
	int	21h
	mov	ax,2506h	; hook INT 6
	mov	dx,offset int6H
	push	cs
	pop	ds
	int	21h
	pop	ds
	clr	ax		; AX = 0
	mov	cl,1		; CL = 1
	mov	dl,ds:[bx+si]	; save byte at [bx+si] in dl

;	The following code ( 0F12C1 ) is SMM instruction UMOV AL,CL that moves
;	data from/to main memory nevertheless the processor is in SMM or not.

;	Cyrix chips doesn't generate INT 6 on this instruction. Instead, two
;	bytes 0F12 gets skipped and the next instruction appears to be
;	{rol word ptr [bx+si],0} ( C10000 ).

	db	0Fh
	adc	al,cl
	add 	ds:[bx+si],al
Past_Invalid:
	mov	ds:[bx+si],dl	; restoring possibly damaged data
	push	ds
	push	es
	pop	ds
	mov	dx,bx
	push	ax
	mov	ax,2506h	; restore INT 6 vector
	int	21h
	pop	ax
	pop	ds
@@Q:
	ret
	ENDP


	END
