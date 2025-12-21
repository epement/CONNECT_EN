unit OS2Clip;

interface

function OS2Detected: WordBool;

implementation

function OS2Detected: WordBool; assembler;
asm
	MOV	AX,4010H
	INT	2FH
	SUB	AX,4010H
end;

end.