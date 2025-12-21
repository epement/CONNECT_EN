{$F-,O-,X+}
unit UserPrim;

{$DEFINE CONNECT}

interface

function User(var C, B, A: Longint): Longint;

implementation

uses Objects, CompPrim, Compiler, Procs, CPUWin, Defaults;

function User;
type
  TPtr = record
    Offset, Segment: Word;
  end;
const
  Signature = 'Connect_User_1';
var
  CountB, CountC, SegB,SegC, OffsB, OffsC, RAX, RDX: Word;
  UsProg: Pointer;
  Index: Integer;
begin
  if PString(A)^ <> Signature then Procs.Error(29, 0); {Invalid user file}
  if MemoryList^.Search(Pointer(B), Index) then
    CountB := MemoryPtr(MemoryList^.At(Index))^.BlockSize
  else CountB := 0;
  if MemoryList^.Search(Pointer(C), Index) then
    CountC := MemoryPtr(MemoryList^.At(Index))^.BlockSize
  else CountC :=0;
  SegB := TPtr(B).Segment;
  SegC := TPtr(C).Segment;
  OffsB := TPtr(B).Offset;
  OffsC := TPtr(C).Offset;
  UsProg := Pointer(A + Length(Signature) + 1);
{$IFNDEF DEBUG80}
{$IFDEF CONNECT}
  if Debugging and OpenCPUWindow and not CPUInUse then
  begin
    GetTraceVectors;
asm
    PUSH DS
    PUSH ES
    MOV CX,CountB
    MOV BX,CountC
    MOV ES,SegC
    MOV DS,SegB
    MOV DI,OffsC
    MOV SI,OffsB
    push cs
    mov ax,offset @L1
    push ax
    pushf
    pop ax
    or ax,100h
    push ax
    mov ax,word ptr UsProg+2
    push ax
    mov ax,word ptr UsProg
    push ax
    iret
@L1:
    push ax
    pushf
    pop ax
    and ax,0FEFFh
    push ax
    popf
    pop ax
    MOV RAX,AX
    MOV RDX,DX
    MOV SegC,ES
    MOV SegB,DS
    MOV OffsC,DI
    MOV OffsB,SI
    POP ES
    POP DS
end;
    CloseCPUWindow;
    SetTraceVectors;
  end
  else
{$ENDIF}
{$ENDIF}
  begin
asm
    PUSH DS
    PUSH ES
    MOV CX,CountB
    MOV BX,CountC
    MOV ES,SegC
    MOV DS,SegB
    MOV DI,OffsC
    MOV SI,OffsB
    CALL UsProg
    MOV RAX,AX
    MOV RDX,DX
    MOV SegC,ES
    MOV SegB,DS
    MOV OffsC,DI
    MOV OffsB,SI
    POP ES
    POP DS
end;
   end;
   TPtr(B).Segment := SegB;
   TPtr(C).Segment := SegC;
   TPtr(B).Offset := OffsB;
   TPtr(C).Offset := OffsC;
   User := RAX + $10000 * RDX;
end;

end.