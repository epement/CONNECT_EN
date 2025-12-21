unit OvrUMB;

  { Unit OvrUMB : Uses an upper memory block as overlay buffer         }
  {                                                                    }
  {   Version 1.0 (10/27/93)                                           }
  {                                                                    }
  {   Author : Jean-Marc Lasgouttes                                    }
  {                                                                    }
  {   e-mail : Jean-Marc.Lasgouttes@inria.fr                           }


{$F-,O-,S-}


interface

  uses Overlay;

  const OvrUMBSeg:word=0;      {The Segment of the overlay buffer}

  Procedure OvrSetBufUMB(Size:longint);
  {Frees the current overlay buffer (which must be before the heap),
   allocates a new buffer of Size bytes in upper memory and sets the
   overlay manager to use this buffer.

    - The Heap must be empty

    - No Overlays must be loaded

    - Should not be used if the buffer has been already reallocated
      somewhere}

  Procedure OvrMovBufToUMB;
  {Same procedure as OvrSetBufUMB, except that the size of the UMB buffer
   is the same as the size of the original one. This is the most convenient
   procedure to use.}

  Procedure OvrInitUMBBuf;
  {Startup code moved to procedure to optionally add
   local ExitProc to global Exit chain. 04.01.96}

  procedure MoveHeapToUMB;
  procedure RestoreHeapFromUMB;
  {Procedures to add a piece of memory to a child process upon Exec}

implementation

  var   OldExitProc:Pointer;   {The old ExitProc (surprise!)}
	SaveUMBLink:byte;
	SaveMemStrat:Word;     {Temporary variables to save system state}


  Function AllocateUMB(UMBSize:word):word; assembler;
  {Allocates a block of size UMBSize in upper memory and returns the
   segment of the allocated block. If there is an error, the result is zero}
  asm
    MOV   AX, 5802h                    {Save UMB Link state}
    INT   21h
    MOV   SaveUMBLink, AL              {If this function is not recognized}
    JC    @@1                          {  then DOS version <5 : Error}
    MOV   AX, 5800h		       {Save memory allocation strategy}
    INT   21h
    MOV   SaveMemStrat, AX

    MOV   AX, 5803h                    {Add UMB to DOS memory chain}
    MOV   BX, 1
    INT   21h
    JC    @@1			       {Error: no UMB provider}
    MOV   AX, 5801h                    {Set memory allocation strategy to}
    MOV   BX, 41h                      {  use only upper memory}
    INT   21h

    MOV   AH, 48h                      {Allocate UMBSize segments of memory}
    MOV   BX, UMBSize
    INT   21h
    JNC   @@2

@@1:XOR   AX, AX                       {If there is an error the result is 0}
@@2:PUSH  AX                           {Push the result in the stack}

    MOV   AX, 5803h	               {Reset the UMB link state}
    MOV   BL, SaveUMBLink
    XOR   BH,BH
    INT   21h
    MOV   AX, 5801h		       {Reset the memory allocation strategy}
    MOV   BX, SaveMemStrat
    INT   21h

    POP   AX                           {Get the result in AX}
  end;

  Procedure ReleaseUMB(UMBSeg:word); assembler;
  {Releases the block corresponding to UMBSeg if UMBSeg<>0}
  asm
    MOV   AX, UMBSeg                   {If the segment is zero, do nothing}
    CMP   AX, 0
    JZ    @@1
    MOV   AX, 5802h	               {Save UMB Link state}
    INT   21h
    MOV   SaveUMBLink, AL
    MOV   AX, 5803h
    XOR   BX,BX		               {Remove UMB from DOS memory chain}
    INT   21h
    MOV   AH, 49h                      {Free block used by UMBSeg}
    MOV   ES, UMBSeg
    INT   21h
    MOV   AX, 5803h                    {Reset UMB link state}
    MOV   BL, SaveUMBLink
    XOR   BH,BH
    INT   21h
@@1:
  end;

  Procedure PrimSetBufUMB(Size:word); assembler;
  {The basic procedure called by OvrSetBufUMB and OvrMovBufToUMB. Size
   is given in paragraphs.}
  asm
    XOR   AX, AX                       {Check for errors: }
    CMP   AX, OvrDOSHandle             {  Is the Overlay file opened?}
    JZ    @@3
    CMP   AX, OvrLoadList              {  Are there some Overlays loaded?}
    JNZ   @@3
    MOV   AX, OvrHeapEnd               {  Is the buffer already rellocated?}
    CMP   AX, WORD PTR HeapOrg+2
    JNZ   @@3
    CMP   AX, WORD PTR HeapPtr+2       {  Is there something in the heap?}
    JNZ   @@3
    PUSH  WORD PTR Size
    CALL  AllocateUMB                  {Allocate a buffer in upper memory}
    MOV   OvrUMBSeg, AX                {Keep the segment in OvrUMBSeg}
    CMP   AX,0                         {Is the allocation successful?}
    JNZ   @@1
    MOV   AX, ovrNoMemory              {Not enough UMB}
    JMP   @@2
@@1:MOV   AX, OvrHeapOrg
    MOV   WORD PTR HeapOrg+2, AX       {Seg(HeapOrg):=OvrHeapOrg}
    MOV   WORD PTR HeapPtr+2, AX       {Seg(HeapPtr):=OvrHeapOrg}
    MOV   WORD PTR FreeList+2, AX      {Seg(FreeList):=OvrHeapOrg}
    XOR   AX, AX
    MOV   WORD PTR HeapOrg, AX         {Ofs(HeapOrg):=0}
    MOV   WORD PTR HeapPtr, AX         {Ofs(HeapPtr):=0}
    MOV   WORD PTR FreeList, AX        {Ofs(FreeList):=0}
    MOV   AX, OvrUMBSeg
    MOV   OvrHeapOrg, AX               {OvrHeapOrg:=OvrUMBSeg }
    MOV   OvrHeapPtr, AX               {OvrHeapPtr:=OvrUMBSeg }
    ADD   AX, Size
    MOV   OvrHeapEnd, AX               {OvrHeapEnd:=OvrUMBSeg+Size}
    MOV   AX, ovrOK                    {Success}
    JMP   @@2
@@3:MOV   AX, ovrError
@@2:MOV   OvrResult, AX                {Put the result in OvrResult}
  end;

  Procedure OvrSetBufUMB(Size:longint); assembler;
  asm
    MOV   AX, WORD PTR Size            {Transform Size}
    MOV   DX, WORD PTR Size+2          {  into a number of paragraphs}
    MOV   CL, 04h
    SHR   AX, CL
    ROR   DX, CL
    AND   DX, 0F000h
    OR    AX, DX                       {  the result is in AX}
    CMP   AX, OvrHeapSize              {If AX < OvrHeapSize --> Error}
    JB    @@1
    PUSH  AX
    CALL  PrimSetBufUMB                {Actually allocate and set the buffer}
    JMP   @@2
@@1:MOV   AX, ovrError                 {Report an Error}
    MOV   OvrResult, AX
@@2:
  end;

  Procedure OvrMovBufToUMB; assembler;
  asm
    MOV   AX, OvrHeapEnd               {Compute the size of the}
    SUB   AX, OvrHeapOrg               {  current Overlay buffer}
    PUSH  AX
    CALL  PrimSetBufUMB                {Actually allocate and set the buffer}
  end;

  Procedure OvrUMBExitProc; far;
  begin
    ExitProc:=OldExitProc;             {Chain to the old exit handler}
    ReleaseUMB(OvrUMBSeg);             {Release the overlay buffer}
  end;

  procedure OvrInitUMBBuf;
  begin
    OvrMovBufToUMB;
    if OvrUMBSeg <> 0 then
    begin
      OldExitProc:=ExitProc;
      ExitProc:=@OvrUMBExitProc;       {Release the UMB on exit}
    end;
  end;

type
  PtrRec = record
  Ofs, Seg: Word;
end;

var
  OvrMovedHeapOrg: Word;

procedure MoveHeapToUMB;
begin
  OvrMovedHeapOrg := OvrHeapEnd - 1;
  repeat
    Move(Ptr(PtrRec(HeapPtr).Seg, 0)^, Ptr(OvrMovedHeapOrg, 0)^, 16);
    if (PtrRec(HeapPtr).Seg = PtrRec(HeapOrg).Seg) or
       (OvrMovedHeapOrg = OvrHeapOrg) then Exit;
    Dec(PtrRec(HeapPtr).Seg);
    Dec(OvrMovedHeapOrg);
  until False;
end;

procedure RestoreHeapFromUMB;
begin
  repeat
    Move(Ptr(OvrMovedHeapOrg, 0)^, Ptr(PtrRec(HeapPtr).Seg, 0)^, 16);
    Inc(OvrMovedHeapOrg);
    if OvrMovedHeapOrg = OvrHeapEnd then Exit;
    Inc(PtrRec(HeapPtr).Seg);
  until False;
end;

end.
