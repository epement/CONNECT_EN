{$S-,G+}
Unit Heap_UMB;
interface
procedure Extend_Heap;

implementation

const
 UMBBlocks = 8;

var
 Segs, Sizes : Array[1..UMBBlocks] of word;
 ExitSave: Pointer;
 IsUmb, UmbInUse : Boolean;

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
 i, j, Segm, Size : Word;

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
   Segs[i] := Segm;
   Sizes[i] := Size;
  end;
end;

Procedure UMB_ExitProc; far;
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

procedure Extend_Heap;
type
 Rec = record
  P: Pointer;
  L: Longint;
 end;

var
 i, j, w: Word;
 P: ^Rec;
 L1, L2: Longint;

begin
 if not UmbInUse and IsUmb then
  begin
   UmbInUse := True;
   for i := 1 to UMBBlocks - 1 do
    for j := i + 1 to UMBBlocks do
     if Segs[j] < Segs[i] then
      begin
       w := Segs[i]; Segs[i] := Segs[j]; Segs[j] := w;
       w := Sizes[i]; Sizes[i] := Sizes[j]; Sizes[j] := w;
      end;
   P := HeapPtr;
   i := Seg(HeapEnd^) - Seg(HeapPtr^);
   Move(i, P^.L, 2);
   P^.L := P^.L shl $10;
   i := 1;
   while (Sizes[i] > 0) and (i <= UMBBlocks) do
    if Sizes[i] <> 0 then
      begin
       if Seg(HeapEnd^) < Segs[i] then
        begin
         P^.P := Ptr(Segs[i],0);
         P := P^.P;
         P^.P := HeapPtr;
         Move(Sizes[i], P^.L, 2);
         P^.L := P^.L shl $10;
        end;
       Inc(i);
      end;
   if (Sizes[1] > 0) and (Seg(HeapEnd^) < Segs[1]) then
    begin
     HeapEnd := Ptr(Segs[1] + Sizes[1], 0);
     HeapPtr := Ptr(Segs[1], 0);
    end
  end;
end;

begin
 UmbInUse := False;
 if XMSTest then
  begin
   FillChar(Sizes, SizeOf(Sizes), 0);
   ExitSave := ExitProc;
   ExitProc := @UMB_ExitProc;
   AllocUMB;
   IsUmb := True;
  end
 else IsUmb := False;
end.
