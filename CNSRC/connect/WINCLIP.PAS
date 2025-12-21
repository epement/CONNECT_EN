unit WinClip;

interface

function IdentifyWinOldAp: WordBool;
function OpenWinClipboard: WordBool;
function ClearWinClipboard: WordBool;
function SetWinClipboardData(Buffer: Pointer; Size: Longint): WordBool;
function GetWinClipboardDataSize: Longint;
function GetWinClipboardData(Buffer: Pointer): WordBool;
function CloseWinClipboard: WordBool;

implementation

function IdentifyWinOldAp: WordBool; assembler;
asm
	MOV	AX,1700H
	INT	2FH
	SUB	AX,1700H
end;

function OpenWinClipboard: WordBool; assembler;
asm
	MOV	AX,1701H
	INT	2FH
end;

function ClearWinClipboard: WordBool; assembler;
asm
	MOV	AX,1702H
	INT	2FH
end;

function SetWinClipboardData(
  Buffer: Pointer; Size: Longint): WordBool; assembler;
asm
	MOV	AX,1703H
	MOV	DX,7
	LES	BX,Buffer
	MOV	CX,WORD	PTR Size
	MOV	SI,WORD	PTR Size+2
	INT	2FH
end;

function GetWinClipboardDataSize: Longint; assembler;
asm
	MOV	AX,1704H
	MOV	DX,7
	INT	2FH
end;

function GetWinClipboardData(Buffer: Pointer): WordBool; assembler;
asm
	MOV	AX,1705H
	MOV	DX,7
	LES	BX,Buffer
	INT	2FH
end;

function CloseWinClipboard: WordBool; assembler;
asm
	MOV	AX,1708H
	INT	2FH
end;

end.
