{$I-,F+,O+,X+}
unit ExeView;

interface

uses Objects;

function GetExeInfo(const ExeName: FNameStr; List: PCollection): Boolean;

implementation

uses Drivers, LFN, HeapUMB, TPString;

type
  TEXEHeader = record
    Signature,
    PartPage,
    PageCnt,
    ReloCnt,
    HdrSize,
    MinMem,
    MaxMem,
    ReloSS,
    ExeSP,
    ChkSum,
    ExeIP,
    ReloCS,
    TablOff,
    Overlay : Word;
    L1Ch          {4 BYTEs   ???}
     : Longint;
    W20           {20h    WORD    behavior bits}
     : Word;
    A22           {22h 26 BYTEs   reserved for additional behavior info}
     : Array[0..25] of byte;
    OfsNewExe     {3Ch    DWORD   offset of new executable (NE,LE,etc) header within disk file,
                   or 00000000h if plain MZ executable}
     : Longint;
  end;

  TNewEXEHeader = record
    Signature,    {00h  2 BYTEs   "NE" (4Eh 45h) signature}
    LnkVer,       {02h  2 BYTEs   linker version (major, then minor)}
    OfsEntryTbl,  {04h    WORD    offset from start of this header to entry table (see #0719)}
    EntryTblSize  {06h    WORD    length of entry table in bytes}
     : Word;
    CRC           {08h    DWORD   file load CRC (0 in Borland's TPW)}
     : Longint;
    PrgFlg        {0Ch    BYTE    program flags (see #0713)}
     : Byte;
    AppFlg        {0Dh    BYTE    application flags (see #0714)}
     : Byte;
    AutoDataIdx,  {0Eh    WORD    auto data segment index}
    HeapSize,     {10h    WORD    initial local heap size}
    StackSize,    {12h    WORD    initial stack size (added to data seg, 0000h if SS <> DS)}
    ExeIP,
    ReloCS,       {14h    DWORD   program entry point (CS:IP), "CS" is index into segment table}
    ReloSS,
    ExeSP,        {18h    DWORD   initial stack pointer (SS:SP), "SS" is segment index
                                  if SS=automatic data segment and SP=0000h, the stack pointer is
                                  set to the top of the automatic data segment, just below the
                                  local heap}
    SegmCnt,      {1Ch    WORD    segment count}
    ModRefCnt,    {1Eh    WORD    module reference count}
    NResSize,     {20h    WORD    length of nonresident names table in bytes}
    OfsSegmTbl,   {22h    WORD    offset from start of this header to segment table (see #0717)}
    OfsResTbl,    {24h    WORD    offset from start of this header to resource table}
    OfsRresTbl,   {26h    WORD    offset from start of this header to resident names table}
    OfsModRefTbl, {28h    WORD    offset from start of this header to module reference table}
    OfsHdrImpTbl  {2Ah    WORD    offset from start of this header to imported names table
                                  (array of counted strings, terminated with a string of length 00h)}
     : Word;
    OfsNResTbl    {2Ch    DWORD   offset from start of file to nonresident names table}
     : Longint;
    MovEntCnt,    {30h    WORD    count of moveable entry point listed in entry table}
    AligCnt,      {32h    WORD    file alignment size shift count
                                  0 is equivalent to 9 (default 512-byte pages) }
    ResTblCnt     {34h    WORD    number of resource table entries}
     : Word;
    OS            {36h    BYTE    target operating system
                   00h unknown
                   01h OS/2
                   02h Windows
                   03h European MS-DOS 4.x
                   04h Windows 386
                   05h BOSS (Borland Operating System Services)}
     : Byte;
    ExeFlg        {37h    BYTE    other EXE flags (see #0715)}
     : Byte;
    W38,          {38h    WORD    offset to return thunks or start of gangload area}
    W3A,          {3Ah    WORD    offset to segment reference thunks or length of gangload area}
    MinSwapSize   {3Ch    WORD    minimum code swap area size}
     : Word;
    LWinVers,     {3Eh  2 BYTEs   expected Windows version (minor version first)}
    HWinWers
     : Byte;
                  {Note:   this header is documented in detail in the Windows 3.1 SDK Programmer's
                   Reference, Vol 4.}
  end;

  TLEHeader = record
    Signature     {00h  2 BYTEs   "LE" (4Ch 45h) signature (Windows)
                   "LX" (4Ch 58h) signature (OS/2)}
     : Word;
    B02,          {02h    BYTE    byte order (00h = little-endian, nonzero = big-endian)}
    B03           {03h    BYTE    word order (00h = little-endian, nonzero = big-endian)}
     : Byte;
    L04           {04h    DWORD   executable format level}
     : Longint;
    CPU,          {08h    WORD    CPU type (see also INT 15/AH=C9h)
                   01h Intel 80286 or upwardly compatible
                   02h Intel 80386 or upwardly compatible
                   03h Intel 80486 or upwardly compatible
                   04h Intel Pentium (80586) or upwardly compatible
                   20h Intel i860 (N10) or compatible
                   21h Intel "N11" or compatible
                   40h MIPS Mark I (R2000, R3000) or compatible
                   41h MIPS Mark II (R6000) or compatible
                   42h MIPS Mark III (R4000) or compatible}
    OS            {0Ah    WORD    target operating system
                   01h OS/2
                   02h Windows
                   03h European DOS 4.0
                   04h Windows 386}
     : Word;
    ModVer,       {0Ch    DWORD   module version}
    ModType,      {10h    DWORD   module type (see #0726)}
    NumMemPgs,    {14h    DWORD   number of memory pages}
    CS,           {18h    Initial CS:EIP
                   DWORD   object number}
    EIP,          {DWORD   offset}
    SS,           {20h    Initial SS:ESP
                   DWORD   object number}
    ESP,          {DWORD   offset}
    MemPgSize,    {28h    DWORD   memory page size}
    BytesLastPg,  {2Ch    DWORD   (Windows LE) bytes on last page
                   (OS/2 LX) page offset shift count}
    FixupSize,    {30h    DWORD   fixup section size}
    FixupChkSum,  {34h    DWORD   fixup section checksum}
    LodSectSize,  {38h    DWORD   loader section size}
    LodSectChkSum,{3Ch    DWORD   loader section checksum}
    OfsObjTbl,    {40h    DWORD   offset of object table (see #0727)}
    ObjTblEntrCnt,{44h    DWORD   object table entries}
    OfsPgMapTbl,  {48h    DWORD   object page map table offset}
    L4C,          {4Ch    DWORD   object iterate data map offset}
    L50,          {50h    DWORD   resource table offset}
    L54,          {54h    DWORD   resource table entries}
    L58,          {58h    DWORD   resident names table offset}
    L5C,          {5Ch    DWORD   entry table offset}
    L60,          {60h    DWORD   module directives table offset}
    L64,          {64h    DWORD   Module Directives entries}
    L68,          {68h    DWORD   Fixup page table offset}
    L6C,          {6Ch    DWORD   Fixup record table offset}
    L70,          {70h    DWORD   imported modules name table offset}
    L74,          {74h    DWORD   imported modules count}
    L78,          {78h    DWORD   imported procedures name table offset}
    L7C,          {7Ch    DWORD   per-page checksum table offset}
    L80,          {80h    DWORD   data pages offset}
    L84,          {84h    DWORD   preload page count}
    L88,          {88h    DWORD   non-resident names table offset}
    L8C,          {8Ch    DWORD   non-resident names table length}
    L90,          {90h    DWORD   non-resident names checksum}
    L94,          {94h    DWORD   automatic data object}
    L98,          {98h    DWORD   debug information offset}
    L9C,          {9Ch    DWORD   debug information length}
    LA0,          {A0h    DWORD   preload instance pages number}
    LA4,          {A4h    DWORD   demand instance pages number}
    LA8           {A8h    DWORD   extra heap allocation}
     : Longint;
    AAC           {ACh 20 BYTEs   reserved}
     : Array[0..19] of byte;
    DevId,        {C0h    WORD    device ID (MS-Windows VxD only)}
    DDKVer        {C2h    WORD    DDK version (MS-Windows VxD only)}
     : Longint;
   {Note:   used by EMM386.EXE, QEMM, and Windows 3.0 Enhanced Mode drivers}
  end;


function DWordMul(X, Y : Integer): Longint; Inline($5A/$58/$f7/$E2);

function GetEXEImageSize(const Hdr): Longint;assembler;
asm
    les di, Hdr
    mov ax, es:[di].TEXEHeader.PageCnt
    mov dx,200h
    mul dx
    mov cx, es:[di].TEXEHeader.PartPage
    neg cx
    and cx,1ffh
    sub ax,cx
    sbb dx,0
    mov cx, es:[di].TEXEHeader.HdrSize
    xor bx,bx
    shl cx,1
    adc bx,0
    shl cx,1
    adc bx,0
    shl cx,1
    adc bx,0
    shl cx,1
    adc bx,0
    sub ax,cx
    sbb dx,bx
end;

function DelZero(S : String):String;
begin
 While (Length(S) > 0) and (S[1] = '0') do Delete(S,1,1);
 DelZero := S;
end;

function Value2Str(V: Longint): String;
var
  S: String;
begin
  Str(V, S);
  Value2Str := S;
end;

function GetExeInfo(const ExeName: FNameStr; List: PCollection): Boolean;
var
 OldFlag: Boolean;
 NewPos : Longint;
 S : FNameStr;
 F : lFile;
 P : Array[0..SizeOf(TLEHeader)] of Byte;
 Descr : String;

procedure NewLine(const S: String);
begin
{  List^.Insert(NewStr(S + '|'));}
  List^.Insert(NewStrUMB(S + '|'));
end;

label
  ReadOldHeader, Quit;
begin
 GetExeInfo := False;
 OldFlag := False;
 lAssignFile(F, ExeName);
 lResetReadOnly(F, 1);
 if ioResult <> 0 then Exit;
ReadOldHeader:
 FillChar(Descr, SizeOf(Descr), 0);
 FillChar(P, SizeOf(TEXEHeader), 0);
 BlockRead(F.F, P, SizeOf(TEXEHeader));
 InOutRes := 0;
 with TEXEHeader((@P)^) do
  begin
   if (Signature <> $5A4D) and (Signature <> $4D5A) then Goto Quit;
   if (TablOff < $40) or OldFlag then
    begin
     NewLine('Old EXE Header                |' + Char(Lo(Signature)) +
						 Char(Hi(Signature)));
     NewLine('DOS File Size                 |' + Value2Str(FileSize(F.F)));
     NewLine('Load Image Size               |' + Value2Str(GetEXEImageSize(P)));
     NewLine('Relocation Table entry count  |' + HexW(ReloCnt));
     NewLine('Relocation Table address      |' + HexW(TablOff));
     NewLine('Size of header record         |' + DelZero(HexL(DWordMul(HdrSize, $10))));
     NewLine('Minimum Memory Requirement    |' + DelZero(HexL(DWordMul(MinMem, $10))));
     NewLine('Maximum Memory Requirement    |' + DelZero(HexL(DWordMul(MaxMem, $10))));
     NewLine('File load checksum            |' + HexW(ChkSum));
     NewLine('Overlay Number                |' + HexW(Overlay));
     NewLine('Initial Stack Segment (SS:SP) |' + HexW(ReloSS) + ':' +
						HexW(ExeSP));
     NewLine('Program Entry Point   (CS:IP) |' + HexW(ReloCS) + ':' +
						HexW(ExeIP));
     GetExeInfo := True;
    end
   else
    begin
     NewPos := OfsNewExe;
     Seek(F.F, NewPos);
     FillChar(P, SizeOf(TNewEXEHeader), 0);
     BlockRead(F.F, P, SizeOf(TNewEXEHeader));
     InOutRes := 0;
     with TNewEXEHeader((@P)^) do if Signature = $454E then
      begin
       NewLine('New EXE Header                |' + Char(Lo(Signature)) +
						   Char(Hi(Signature)));

       case OS of
	$01:  S := 'OS/2';
	$02:  S := 'Windows ' + Value2Str(HWinWers) + '.' + Value2Str(LWinVers);
	$03:  S := 'European MS-DOS 4.x';
	$04:  S := 'Windows 386';
	$05:  S := 'BOSS (Borland Operating System Services)';
	else  S := 'unknown';
       end; {case}
       NewLine('Operating system              |' + S);

       NewLine('DOS File Size                 |' + Value2Str(FileSize(F.F)));
       NewLine('File Load CRC                 |' + HexL(CRC));
       NewLine('Program Entry Point   (CS:IP) |' + HexW(ReloCS) + ':' +
						   HexW(ExeIP));
       NewLine('Initial Stack Pointer (SS:SP) |' + HexW(ReloSS) + ':' +
						   HexW(ExeSP));
       NewLine('Initial Local Heap Size       |' + HexW(HeapSize));
       NewLine('Initial Stack Size            |' + HexW(StackSize));
       NewLine('Segment count                 |' + HexW(SegmCnt));
       NewLine('Module reference count        |' + HexW(ModRefCnt));
       NewLine('Moveable Entry Point Count    |' + HexW(MovEntCnt));
       NewLine('Miminum code swap area size   |' + HexW(MinSwapSize));
       NewLine('Linker Version                |' + Value2Str(Lo(LnkVer)) + '.' +
						   Value2Str(Hi(LnkVer)));
       if OfsNResTbl <> 0 then
	begin
	 Seek(F.F, OfsNResTbl);
	 BlockRead(F.F, Descr, SizeOf(Descr));
	 InOutRes := 0;
	 NewLine('Description: |' + Descr);
	end;
       GetExeInfo := True;
      end
     else
      if (Signature = $454C) or
	 (Signature = $584C) then with TLEHeader((@P)^) do
      begin
       Seek(F.F, NewPos);
       FillChar(P, SizeOf(TLEHeader), 0);
       BlockRead(F.F, P, SizeOf(TLEHeader));
       InOutRes := 0;
       NewLine('Linear Executable Header      |' + Char(Lo(Signature)) +
						  Char(Hi(Signature)));

       if B02 = 0 then S := 'Little-endian'
       else S := 'Big-endian';
       NewLine('Byte Order                    |' + S);

       if B03 = 0 then S := 'Little-endian'
       else S := 'Big-endian';
       NewLine('Word Order                    |' + S);

       NewLine('Format level                  |' + HexL(L04));
	case CPU of
	 $01: S := '80286';
	 $02: S := '80386';
	 $03: S := '80486';
	 $04: S := 'Pentium';
	 $20: S := 'i860';
	 $21: S := 'Intel "N11"';
	 $40: S := 'MIPS Mark I (R2000, R3000)';
	 $41: S := 'MIPS Mark II (R6000)';
	 $42: S := 'MIPS Mark III (R4000)';
	 else S := 'unknown';
	end;
       NewLine('CPU type                      |' + S);

	case OS of
	 01: S := 'OS/2';
	 02: S := 'Windows';
	 03: S := 'European DOS 4.0';
	 04: S := 'Windows 386';
	 else S := 'unknown';
	end;
       NewLine('Operating system              |' + S);

       NewLine('DOS File Size                 |' + Value2Str(FileSize(F.F)));
       NewLine('Module version                |' + HexL(ModVer));
       NewLine('Page count                    |' + HexL(NumMemPgs));
       NewLine('Starting EIP object number    |' + HexL(CS));
       NewLine('Starting EIP                  |' + HexL(EIP));
       NewLine('Starting ESP object number    |' + HexL(SS));
       NewLine('Starting ESP                  |' + HexL(ESP));
       NewLine('Page size                     |' + HexL(MemPgSize));
       NewLine('Fixup size                    |' + HexL(FixupSize));
       NewLine('Loader section size           |' + HexL(LodSectSize));
       if L88 <> 0 then
	begin
	 Seek(F.F, L88);
	 BlockRead(F.F, Descr, SizeOf(Descr));
	 InOutRes := 0;
	 NewLine('Description: |' + Descr);
	end;
       GetExeInfo := True;
      end
     else
      begin
	Seek(F.F, 0);
	OldFlag := True;
	Goto ReadOldHeader;
      end;
    end;
  end;
Quit:
  Close(F.F);
  InOutRes := 0;
end;

end.
