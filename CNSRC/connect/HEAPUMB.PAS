{$F+,O+,S-}
Unit HeapUMB;

interface

uses Objects;

procedure InitUMBHeap;
function MaxAvailUMB: Longint;
function MemAvailUMB: Longint;
procedure GetMemUMB(var P; Size: Word);
procedure FreeMemUMB(var P; Size: Word);
function NewStrUMB(const S: String): PString;
procedure DisposeStrUMB(P: PString);
function ReadStrUMB(S: PStream): PString;

implementation

uses ConOvr;

type
 PFreeRec = ^TFreeRec;
 TFreeRec = record
    Next : PFreeRec;
    Size : Longint;
  end;

const
 UMBBlocks = 8;
 UMBHeapOrg: Pointer = nil;       { Heap origin }
 UMBHeapPtr: Pointer = nil;       { Heap pointer }
 UMBHeapEnd: Pointer = nil;       { Heap end }
 UMBFreeList: Pointer = nil;      { Free list pointer }

var
 Segs, Sizes : Array[1..UMBBlocks] of word;
 ExitSave : Pointer;
const
 UmbInUse : Boolean = False;

{$L heap.obj}
function UMBGetMem(Size: Word): Pointer; far; external;
procedure UMBFreeMem(var P: Pointer; Size: Word); far; external;
function  UMBMaxAvail: Longint; far; external;
function  UMBMemAvail: Longint; far; external;

procedure UMBRunError(Err: Word); near;
begin
 RunError(Err);
end;

function XMSTest: Boolean;
var
 B : Boolean;
begin
 B := False;
 asm
  mov ax,4300h
  int 2Fh
  cmp al,80h
  jne @@1
  inc B
 @@1:
 end;
 XMSTest := B
end;

procedure AllocUMB;
var
 i, j, w, Segm, Size : Word;

begin
 for I := 1 to UMBBlocks do
  begin
   Segs[i] := 0;
   Sizes[i] := 0;
  end;
 asm
  mov    ax,5801h
  mov    bx,-1
  int    21h
  mov    ax,5803h
  mov    bx,0001h
  int    21h
 end;
 for i := 1 to UMBBlocks do
  begin
   Segm := 0;
   Size := 0;
   asm
    mov    ax,4800h
    mov    bx,-1
    int    21h
    cmp    bx,0
    je     @@4
    mov    ax,4800h
    int    21h
    jb     @@4
    mov    Segm, ax
    mov    Size, bx
   @@4:
   end;
   if Segm >= $A000 then
   begin
     Segs[i] := Segm;
     Sizes[i] := Size;
   end
   else
   asm
      mov ax, 4901h
      mov bx, Segm
      mov es, bx
      int 21h
   end;
  end;
 for i := 1 to UMBBlocks - 1 do
  for j := i + 1 to UMBBlocks do
   if (Segs[j] > 0) and (Segs[i] > Segs[j]) then
    begin
     w := Segs[i]; Segs[i] := Segs[j]; Segs[j] := w;
     w := Sizes[i]; Sizes[i] := Sizes[j]; Sizes[j] := w;
    end;
end;

procedure Extend_Heap;
var
 i, j, w: Word;
 P: PFreeRec;
begin
 P := UMBHeapPtr;
 i := Seg(UMBHeapEnd^) - Seg(UMBHeapPtr^);
 Move(i, P^.Size, 2);
 P^.Size := P^.Size shl $10;
 i := 1;
 while (Sizes[i] > 0) and (i <= UMBBlocks) do
  if Sizes[i] <> 0 then
    begin
     if Seg(UMBHeapEnd^) < Segs[i] then
      begin
       P^.Next := Ptr(Segs[i],0);
       P := P^.Next;
       P^.Next := UMBHeapPtr;
       Move(Sizes[i], P^.Size, 2);
       P^.Size := P^.Size shl $10;
      end;
     Inc(i);
    end;
 if (Sizes[1] > 0) and (Seg(UMBHeapEnd^) < Segs[1]) then;
  begin
   UMBHeapEnd := Ptr(Segs[2] + Sizes[2], 0);
   UMBHeapPtr := Ptr(Segs[2], 0);
  end;
end;

procedure UMB_ExitProc; far;
var
 I, Segm : Word;
begin
 ExitProc := ExitSave;
 asm
  mov ax, 5803h
  mov bx, 0
  int 21h
 end;
 for I := 1 to UMBBlocks do
  begin
   Segm := Segs[I];
   if Segm > 0 then
    begin
     asm
      mov ax, 4901h
      mov bx, Segm
      mov es, bx
      int 21h
     end;
    end;
  end;
end;

procedure GetMemUMB(var P; Size: Word);
begin
 if UmbInUse and (UMBMaxAvail >= Size) then
   Pointer(P) := UMBGetMem(Size)
 else System.GetMem(Pointer(P), Size);
end;

procedure FreeMemUMB(var P; Size: Word);
begin
 if UmbInUse and (PtrRec(P).Seg > $A000) then
  asm
   les di, P

   push word ptr es:[di+2]
   push word ptr es:[di]

   push Size
   call  UMBFreeMem;
  end
 else System.FreeMem(Pointer(P), Size);
end;

function NewStrUMB(const S: String): PString;
var
  L: Integer;
  P: PString;
begin
  if S = '' then NewStrUMB := nil
  else
  begin
    L := Length(S) + 1;
    GetMemUMB(Pointer(P), L);
    Move(S, P^, L);
    NewStrUMB := P;
  end;
end;

procedure DisposeStrUMB(P: PString);
begin
  if P <> nil then FreeMemUMB(Pointer(P), Length(P^) + 1);
end;

function ReadStrUMB(S: PStream): PString;
var
  L: Byte;
  P: PString;
begin
  S^.Read(L, 1);
  if L = 0 then ReadStrUMB := nil
  else
  begin
    GetMemUMB(P, L + 1);
    P^[0] := Char(L);
    S^.Read(P^[1], L);
    ReadStrUMB := P;
  end;
end;

function MaxAvailUMB: Longint;
var
 L1, L2 : Longint;
begin
 if UmbInUse then
  begin
   L1 := System.MaxAvail;
   L2 := UMBMaxAvail;
   if L1 > L2 then MaxAvailUMB := L1
   else MaxAvailUMB := L2;
  end
 else MaxAvailUMB := System.MaxAvail;
end;

function MemAvailUMB: Longint;
begin
 if UmbInUse then MemAvailUMB := System.MemAvail + UMBMemAvail
 else MemAvailUMB := System.MemAvail;
end;

procedure InitUMBHeap;
begin
 if (ovMem and ovHeapUMB <> 0) and XMSTest then
  begin
   FillChar(Sizes, SizeOf(Sizes), 0);
   AllocUMB;
   UMBHeapEnd := Ptr(Segs[1] + Sizes[1], 0);
   UMBHeapPtr := Ptr(Segs[1], 0);
   UMBFreeList := UMBHeapPtr;
   UMBHeapOrg := UMBHeapPtr;
   UmbInUse := Segs[1] <> 0;
   if UmbInUse then Extend_Heap;
   ExitSave := ExitProc;
   ExitProc := @UMB_ExitProc;
  end;
end;

end.
