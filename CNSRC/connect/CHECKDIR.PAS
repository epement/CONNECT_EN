{$I-}
unit CheckDir;

interface

uses Dos, Objects;

function DriveReady(Drive: Char): Boolean;
function DriveValid(Drive: Char): Boolean;
{function PathValid(const Path: FNameStr): Boolean;}

implementation

uses LFN;

function DriveReady(Drive: Char): Boolean; assembler;
asm
	MOV	DL,Drive
	MOV	AH,36H
	SUB	DL,'A'-1
	INT	21H
	INC	AX
	JE	@@2
@@1:	MOV	AL,1
@@2:
end;

function DriveValid(Drive: Char): Boolean; assembler;
asm
	MOV	AH,19H
	INT	21H
	MOV	BL,AL
	MOV	DL,Drive
	SUB	DL,'A'
	MOV	AH,0EH
	INT	21H
	MOV	AH,19H
	INT	21H
	MOV	CX,0
	CMP	AL,DL
	JNE	@@1
	MOV	CX,1
	MOV	DL,BL
	MOV	AH,0EH
	INT	21H
@@1:	XCHG	AX,CX
end;

{
function PathValid(const Path: FNameStr): Boolean;
var
  ExpPath: FNameStr;
  SR: lSearchRec;
begin
  ExpPath := lFExpand(Path);
  if Length(ExpPath) <= 3 then PathValid := DriveValid(ExpPath[1])
  else
  begin
    if ExpPath[Length(ExpPath)] = '\' then Dec(ExpPath[0]);
    lFindFirst(ExpPath, AnyFile and not VolumeID, SR);
    lFindClose(SR);
    PathValid := (DosError = 0) and (SR.SR.Attr and Directory <> 0);
  end;
end;
}

end.