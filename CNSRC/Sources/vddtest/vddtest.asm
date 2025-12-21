;-----------------------------------------------------------------------------
;
;       DOS 16 bit to Protected mode 32 bit interface using NTVDM Call
;
;-----------------------------------------------------------------------------
;This example by Steve Murray of AirBorn, 22 November 2004, www.airborn.com.au
.model small
.stack 200h
.data

handle  dw      0
MsgSnOn db  "DOS 16 bit to Protected 32 bit interface using NTVDM Call",13,10
MsgInit db  "Press a key to initialize the 32 bit DLL",13,10,36
MsgSend db  "  --Returned from Init--",13,10
        db  "Press a key  to dispatch a message to the 32 bit DLL",13,10,36
MsgSent db  "  --Returned from Dispatch--",13,10
        db  "The value returned from the DLL was: "
RetVal  db  "X",13,10
        db  "Press a key to exit this program",13,10,36
DLLfail db      13,10,"DLL File path incorrect or required file not found: "
DLLname db      "VDDTEST.DLL",0,13,10,36
DLLFailLen   =  $ - DLLfail
DLLinit db      "AxInit",0
DLLdisp db      "AxDisp",0

.code
start:
        mov     ax,@data        ;Get the data segment
        mov     ds,ax           ;  and initialize ds
        lea     dx,MsgSnOn      ;Address the first message: "About to Init"
        mov     ah,9            ;Code for Print $ terminated string to std out
        int     21h             ;Print the message

        mov     ah,0            ;Code for Get Keystroke (returns in al)
        int     16h             ;Wait for a keystroke

        call    Register        ;Execute RegisterModule - starts the DLL
        jc      Fail            ;Jump if RegisterModule operation failed

        lea     dx,MsgSend      ;Address the second message: "Ok, About to Send"
        mov     ah,9            ;Code for Print $ terminated string to std out
        int     21h

        mov     ah,0            ;Code for Get Keystroke (returns in al)
        int     16h             ;Wait for a keystroke

        mov     bh,0
        mov     bl,al           ;Place the keystroke in bl
        call    Dispatch        ;  and Dispatch to the DLL

        lea     di,RetVal       ;Address the return value location
        mov     [di],al         ;Save the returned character

        lea     dx,MsgSent      ;Address the third message: "Ok, value received"
        mov     ah,9            ;Code for Print $ terminated string to std out
        int     21h

        mov     ah,0            ;Code for Get Keystroke (returns in al)
        int     16h             ;Wait for a keystroke
        jmp     Exit

Fail:   lea     dx,DLLfail      ;Address the fourth message "DLL init failed"
        mov     ah,9            ;Code for Print $ terminated string to std out
        int     21h
        jmp     Exit


Exit:   mov     ah,4Ch          ;Code for Program Terminate
        int     21h             ;Exit the program


Register  Proc Near             ;Execute the NTVDM Register module
        push    ds              ;Move ds segment
        pop     es              ;  to es
        lea     si,DLLname      ;Point to our desired drivers DLL name
        lea     di,DLLinit      ;Point to the desired Init routine name
        lea     bx,DLLdisp      ;Point to the desired dispatch routine name
                                ;So now we have       Dispatch in ds:bx
                                ;                     Init     in es:di
                                ;  and                DLLname  in ds:si

        db 0C4h,0C4h,58h,0h     ;--Execute NTVDM RegisterModule-----
                                ;We should have invoked our DLL at this point
        lea     di,Handle       ;Address our handle location
        mov     [di],ax         ;Save the VDD handle sent back to us by NTVDM

        jnc     RgDone          ;Jump if we have a good VDD handle
        mov     ax,0
        mov     [di],ax         ;--ELSE we have a problem - probably no DLL----
RgDone: ret
Register endp


Dispatch  Proc Near             ;Enter with Dispatch code in bx; ax overwritten
        lea     di,Handle       ;Address the handle
        mov     ax,[di]         ;Get the handle
        add     ax,0            ;Test the VDD handle
        jz      DispatchDone    ;  and exit if it is invalid

        db 0C4h,0C4h,58h,2h     ;--Execute NTVDM DispatchCall-----
DispatchDone:
        ret
Dispatch endp

End start
