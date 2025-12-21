{$F+,I-,O-,X+}
unit DosTools;

interface

function EscPressed: Boolean;
(*
procedure StuffKey(W: Word);
procedure StuffString(S: String);
*)
procedure Pause(MS: Word);
(*
function HercPresent: Boolean;
function ThisFileExists(const FileName: String): Boolean;
function GetTickCount: Longint;
function GetTotalMem: Longint;
function GetFreeMem: Longint;
function GetClusterSize(Drive: Byte): Word;
function GetDiskInfo(Drive: Byte; var ClustersAvailable, TotalClusters,
  BytesPerSector, SectorsPerCluster: Word): Boolean;
*)
function TextSeek(var F: Text; Target: LongInt): Boolean;
function TextFileSize(var F: Text): LongInt;
function TextPos(var F: Text): LongInt;
function IsDevice(Handle: Word): Boolean;
function NotAccessible(Handle: Word): Boolean;
procedure DeviceBinaryMode(Handle: Word);
function FileHandlesOpen(CountDevices: Boolean): Byte;
function FileHandlesLeft: Byte;

implementation

uses Dos, CNCrt;

function EscPressed: Boolean;
begin
  EscPressed := KeyPressed and (ReadKey = #27);
end;

(*
procedure StuffKey(W: Word);
const
  KbdStart = $1E;
  KbdEnd = $3C;
var
  KbdHead: Word absolute $40 : $1A;
  KbdTail: Word absolute $40 : $1C;
  SaveKbdTail: Word;
begin
  SaveKbdTail := KbdTail;
  if KbdTail = KbdEnd then KbdTail := KbdStart
  else Inc(KbdTail, 2);
  if KbdTail = KbdHead then KbdTail := SaveKbdTail
  else MemW[$40:SaveKbdTail] := W;
end;

procedure StuffString(S: String);
var
  B: Byte;
begin
  if Length(S) > 16 then S[0] := #16;
  for B := 1 to Length(S) do StuffKey(Ord(S[B]));
end;
*)

procedure Pause(MS: Word);
var
  I: Integer;
begin
  for I := 0 to MS div 100 - 1 do
  begin
    if KeyPressed then Exit;
    Delay(100);
  end;
  Delay(MS mod 100);
end;

(*
function HercPresent : Boolean;
begin
  inline(
    $31/$DB/               {xor bx,bx}
    $CD/$11/               {int $11}
    $25/$30/$00/           {and ax,$30     ;check equipment list}
    $3D/$30/$00/           {cmp ax,$30     ;"switches" set for mono?}
    $75/$18/               {jne done       ;no - quit}
    $BA/$BA/$03/           {mov dx,$3BA    ;Take a reading}
    $EC/                   {in al,dx}
    $24/$80/               {and al,$80}
    $88/$C4/               {mov ah,al      ;Save bit 7 for test}
    $B9/$00/$80/           {mov cx,$8000   ;How many times to test}
			   {Examine:}
    $EC/                   {in al,dx       ;Take another reading}
    $24/$80/               {and al,$80     ;Isolate bit 7}
    $38/$E0/               {cmp al,ah}
    $75/$05/               {jne herc       ;If bit 7 changes then it}
    $E2/$F7/               {loop examine   ; is a Hercules}
    $E9/$01/$00/           {jmp done       ;it must be something else}
			   {Herc:}
    $43/                   {inc bx         ;return true}
			   {Done:}
    $88/$5E/$FF);          {mov [bp-1],bl  ;set function result}
end;

function ThisFileExists(const FileName: String): Boolean;
var
  Attr: Word;
  F: File;
begin
  Assign(F, FileName);
  GetFAttr(F, Attr);
  ThisFileExists := (DosError = 0) and (Attr and Directory = 0);
end;

function GetTickCount: Longint;
var
  L: Longint;
  B: Byte;
begin
  L := 0;
  B := Mem[$40:$6C];
  repeat until (B <> Mem[$40:$6C]) or KeyPressed;
  B := Mem[$40:$6C];
  repeat
    Inc(L);
  until (B <> Mem[$40:$6C]) or KeyPressed;
  if KeyPressed then L := 0;
  GetTickCount := L;
end;

function GetTotalMem: Longint;
begin
  GetTotalMem := Longint(Word(Ptr(0, $413)^)) shl 10;
end;

function GetFreeMem: Longint;
begin
  GetFreeMem := GetTotalMem - Longint(PrefixSeg) shl 4;
end;

function GetClusterSize(Drive: Byte): Word;
var
  ClustersAvailable, TotalClusters,
  BytesPerSector, SectorsPerCluster: Word;
begin
  if GetDiskInfo(Drive, ClustersAvailable, TotalClusters,
    BytesPerSector, SectorsPerCluster) and
      (BytesPerSector <> 0) and (SectorsPerCluster <> 0) then
    GetClusterSize := BytesPerSector * SectorsPerCluster
  else GetClusterSize := 512;
end;

{$L diskinfo.obj}

function GetDiskInfo(Drive: Byte; var ClustersAvailable, TotalClusters,
  BytesPerSector, SectorsPerCluster: Word): Boolean; external;
*)

type
  LongRec = record
    Lo, Hi: Word;
  end;

function TextSeek(var F: Text; Target: Longint): Boolean;
var
  T: LongRec absolute Target;
  Pos: LongInt;
  Regs: Registers;
begin
  with Regs, TextRec(F) do
  begin
    TextSeek := False;
    if Mode <> FMInput then Exit;
    AX := $4201;
    BX := Handle;
    CX := 0;
    DX := 0;
    MsDos(Regs);
    if Odd(Flags) then Exit;
    LongRec(Pos).Hi := DX;
    LongRec(Pos).Lo := AX;
    Dec(Pos, BufEnd);
    Pos := Target - Pos;
    if (Pos >= 0) and (Pos < BufEnd) then BufPos := Pos
    else
    begin
      AX := $4200;
      BX := Handle;
      CX := T.Hi;
      DX := T.Lo;
      MsDos(Regs);
      if Odd(Flags) then Exit;
      BufEnd := 0;
      BufPos := 0;
    end;
  end;
  TextSeek := True;
end;

function TextFileSize(var F: Text): LongInt;
var
  OldHi, OldLow: Integer;
  Regs: Registers;
begin
  with Regs, TextRec(F) do
  begin
    if Mode = FMClosed then
    begin
      TextFileSize := -1;
      Exit;
    end;
    AX := $4201;
    BX := Handle;
    CX := 0;
    DX := 0;
    MsDos(Regs);
    if Odd(Flags) then
    begin
      TextFileSize := -1;
      Exit;
    end;
    OldHi := DX;
    OldLow := AX;
    AX := $4202;
    BX := Handle;
    CX := 0;
    DX := 0;
    MsDos(Regs);
    if Odd(Flags) then
    begin
      TextFileSize := -1;
      Exit;
    end;
    TextFileSize := LongInt(DX) shl 16 + AX;
    AX := $4200;
    BX := Handle;
    CX := OldHi;
    DX := OldLow;
    MsDos(Regs);
    if Odd(Flags) then TextFileSize := -1;
  end;
end;

function TextPos(var F: Text): LongInt;
var
  Position: LongInt;
  Regs: Registers;
begin
  with Regs, TextRec(F) do
  begin
    if Mode = FMClosed then
    begin
      TextPos := -1;
      Exit;
    end;
    AX := $4201;
    BX := Handle;
    CX := 0;
    DX := 0;
    MsDos(Regs);
    if Odd(Flags) then
    begin
      TextPos := -1;
      Exit;
    end;
    LongRec(Position).Hi := DX;
    LongRec(Position).Lo := AX;
    if Mode = FMOutput then Inc(Position, BufPos)
    else if BufEnd <> 0 then Dec(Position, BufEnd - BufPos);
    TextPos := Position;
  end;
end;

function IsDevice(Handle: Word): Boolean; assembler;
asm
	MOV	AX,4400h
	MOV	BX,Handle
	INT	21h
	XOR	AL,AL
	TEST	DX,80h
	JE	@@1
	INC	AL
@@1:
end;

function NotAccessible(Handle: Word): Boolean; assembler;
asm
	MOV	AX,4400h
	MOV	BX,Handle
	INT	21h
	XOR	AL,AL
	TEST	DX,80h
	JE	@@1
	CMP	DX,0A0C0h
	JE	@@1
	CMP	DX,80C0h
	JE	@@1
	INC	AL
@@1:
end;

procedure DeviceBinaryMode(Handle: Word); assembler;
asm
	 MOV    BX,Handle
	 MOV 	AX,4400H
	 INT 	21H
	 OR     DL,20H
	 MOV    DH,0
	 MOV    AX,4401H
	 INT    21H
end;

function FileHandlesOpen(CountDevices: Boolean): Byte;
type
  HandleTable = Array[0..254] of Byte;
var
  I, N, Max: Byte;
  HandlesPtr: ^HandleTable;
begin
  HandlesPtr := Pointer(MemL[PrefixSeg:$34]);
  Max := Mem[PrefixSeg:$0032] - 1;
  N := 0;
  for I := 0 to Max do
    if HandlesPtr^[I] <> $FF then
      if I <= 4 then Inc(N, Ord(CountDevices))
      else Inc(N);
  FileHandlesOpen := N;
end;

function FileHandlesLeft: Byte;
const
  NullName: Array[1..4] of Char = 'NUL'#0;
  MaxHandles = 255;
var
  N: Byte;
  Handles: Array[1..MaxHandles] of Word;
begin
  inline(
    $30/$ED/                    {xor ch,ch            ;CX = MaxHandles}
    $B1/<MaxHandles/            {mov cl,<MaxHandles}
    $BA/>NullName/              {mov dx,>NullName     ;DS:DX => NullName}
    $BF/>InOutRes/              {mov di,>InOutRes     ;DS:DI => InOutRes}
    $8D/$B6/>Handles/           {lea si,[bp+>Handles] ;SI has offset for Handles[1]}
				{Next:}
    $B8/$02/$3D/                {mov ax,$3D02         ;DOS open file function}
    $CD/$21/                    {int $21              ;call DOS}
    $72/$0B/                    {jc Close             ;start closing if CF set}
    $38/$2D/                    {cmp [di],ch          ;IoResult = 0?}
    $75/$07/                    {jne Close            ;if not, start closing}
    $36/                        {ss:}
    $89/$04/                    {mov [si],ax          ;save the Handle}
    $46/                        {inc si               ;inc pointer into Handles}
    $46/                        {inc si}
    $E2/$EE/                    {loop Next            ;repeat if CX > 0}
				{Close:}
    $F6/$D1/                    {not cl               ;flip bits in cl}
    $88/$8E/>N/                 {mov [bp+>N],cl       ;save handle count in N}
    $E3/$0C/                    {jcxz Done            ;done if count is 0}
				{CloseOne:}
    $4E/                        {dec si               ;dec pointer into Handles}
    $4E/                        {dec si}
    $36/                        {ss:}
    $8B/$1C/                    {mov bx,[si]          ;get the handle into BX}
    $B8/$00/$3E/                {mov ax,$3E00         ;DOS close file function}
    $CD/$21/                    {int $21              ;call DOS, ignore error}
    $E2/$F4/                    {loop CloseOne        ;do it again}
				{Done:}
    $89/$0D);                   {mov [di],cx          ;clear IoResult (CX = 0)}

  FileHandlesLeft := N;
end;

end.