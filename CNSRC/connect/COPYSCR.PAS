{$F+,O+,X+}
unit CopyScr;

interface

procedure ClipCopyUserScreen;

implementation

uses Objects, Drivers, Swaps, ClipPrim, UserScr, TPString, Defaults;

procedure GetStr(const Buf; var Str: String); assembler;
asm
	MOV	DX,DS
	LDS	SI,Buf
	LES	DI,Str
	MOV	BYTE PTR ES:[DI],80
	INC 	DI
	CLD
	MOV	CX,80
@@1:	LODSW
	STOSB
	LOOP	@@1
	MOV	DS,DX
end;

procedure ClipCopyUserScreen;
var
  I, N, SaveCount, MaxLen: Integer;
  C: String[1];
  S: String;
begin
  if DiskClipStream = nil then Exit;
  SetExpandClipAreaFlag;
  MaxLen := 0;
  I := 0;
  N := 0;
  SaveCount := ClipLines^.Count;
  while I < UserScreenRows do
  begin
    GetStr(UserScreenBuffer^[I * UserScreenCols], S);
    TrailTrim(S);
    if S = '' then Inc(N)
    else
    begin
      C := '';
      for N := N - 1 downto 0 do PutClipLine(C);
      PutClipLine(S);
      if not MarkColumns or (Length(S) > MaxLen) then MaxLen := Length(S);
    end;
    if (DiskClipStream^.Status <> stOk) or
       (PSwapLinesCollection(ClipLines)^.Status = coOverflow) then
    begin
      DiskClipStream^.Reset;
      PSwapLinesCollection(ClipLines)^.Status := 0;
      if not DisableSounds then Write(^G);
      Break;
    end;
    Inc(I);
  end;
  SetOrExpandClipArea(SaveCount, MaxLen + 1);
end;

end.