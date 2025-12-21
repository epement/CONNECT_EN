{$F+,I-,O+,X+}
unit DosCase;

interface

{
 Format of DOS 2.11+ country info:
 Offset  Size    Description     (Table 1053)
  00h    WORD    date format (see #1052)
  02h  5 BYTEs   ASCIZ currency symbol string
  07h  2 BYTEs   ASCIZ thousands separator
  09h  2 BYTEs   ASCIZ decimal separator
  0Bh  2 BYTEs   ASCIZ date separator
  0Dh  2 BYTEs   ASCIZ time separator
  0Fh    BYTE    currency format
		 bit 2 = set if currency symbol replaces decimal point
		 bit 1 = number of spaces between value and currency symbol
		 bit 0 = 0 if currency symbol precedes value
			 1 if currency symbol follows value
  10h    BYTE    number of digits after decimal in currency
  11h    BYTE    time format
		 bit 0 = 0 if 12-hour clock
			 1 if 24-hour clock
  12h    DWORD   address of case map routine
		 (FAR CALL, AL = character to map to upper case [>= 80h])
  16h  2 BYTEs   ASCIZ data-list separator
  18h 10 BYTEs   reserved
}

type
  TCountryInfo = record
    DateFormat: Word;
    CurrencySymbol: Array[0..4] of Char;
    ThousandsSeparator: Array[0..1] of Char;
    DecimalSeparator: Array[0..1] of Char;
    DateSeparator: Array[0..1] of Char;
    TimeSeparator: Array[0..1] of Char;
    CurrencyFormat: Byte;
    DecimalDigits: Byte;
    TimeFormat: Byte;
    CaseMapRoutine: Pointer;
    DataListSeparator: Array[0..1] of Char;
    Reserved: Array[0..9] of Char;
  end;

procedure SetDosCase;
procedure SetAltCase;
procedure GetCountrySpecificInfo(var Info: TCountryInfo);
procedure SetCountrySpecificInfo;

implementation

uses Dos, Objects, TPString, Defaults;

{$L DOSCASE.OBJ}
procedure UpTable;external;
procedure LoTable;external;

{
 INT 21h  AH=38
 INT 21 - DOS 2+ - GET COUNTRY-SPECIFIC INFORMATION
	 AH = 38h
 --DOS 2.x--
	 AL = 00h get current-country info
	 DS:DX -> buffer for returned info (see #1052,#1053)
 Return: CF set on error
	     AX = error code (02h)
	 CF clear if successful
	     AX = country code (MS-DOS 2.11 only)
	     buffer at DS:DX filled
 --DOS 3.0+--
	 AL = 00h for current country
	 AL = 01h thru 0FEh for specific country with code <255 (see #1054)
	 AL = 0FFh for specific country with code >= 255
	    BX = 16-bit country code (see #1054)
	 DS:DX -> buffer for returned info (see #1053)
 Return: CF set on error
	     AX = error code (02h)
	 CF clear if successful
	     AX = country code (Novell NWDOS v7.0)
	     BX = country code
	     DS:DX buffer filled
 Note:   this function is not supported by the Borland DPMI host, but no error
	   is returned; as a workaround, one should allocate a buffer in
	   conventional memory with INT 31/AX=0100h and simulate an INT 21 with
	   INT 31/AX=0300h
}

procedure GetCountrySpecificInfo(var Info: TCountryInfo); assembler;
asm
	MOV	AX,3800H
	PUSH	DS
	LDS	DX,Info
	INT	21H
	POP	DS
end;

{
 INT 21h  AH=65
 INT 21 - DOS 4.0+ - COUNTRY-DEPENDENT CHARACTER CAPITALIZATION
	 AH = 65h
	 AL = function
	     20h capitalize character
		 DL = character to capitalize
		 Return: DL = capitalized character
	     21h capitalize string
		 DS:DX -> string to capitalize
		 CX = length of string
	     22h capitalize ASCIZ string
		 DS:DX -> ASCIZ string to capitalize
 Return: CF set on error
	     AX = error code (see #1332 at AH=59h/BX=0000h)
	 CF clear if successful
 Note:   these calls have been documented for DOS 5+, but were undocumented in
	   DOS 4.x.
}

type
  PUpLoTable = ^TUpLoTable;
  TUpLoTable = Array[#128..#255] of Char;

{
function DOSUpcase(C: Char): Char; assembler;
asm
	MOV     AX,6520H
	MOV     DL,C
	INT     21H
	MOV     AL,DL
end;
}

procedure DOSTblUpcase(var Tbl: TUpLoTable); assembler;
asm
	MOV     AX,6521H
	PUSH    DS
	LDS     DX,Tbl
	MOV     CX,128
	INT     21H
	POP     DS
end;

procedure SetCountryCharTables(var UpTable, LoTable: TUpLoTable);
var
  C, UC, LC: Char;
begin
  for C := #128 to #255 do UpTable[C] := C;

  DOSTblUpcase(UpTable);

  for C := #128 to #255 do
  begin
    LoTable[C] := C;
    UC := UpTable[C];
{
    if (C <> UC) and (UC > #127) then LoTable[UC] := C
}
    if C <> UC then for LC := #128 to #255 do
      if UpTable[LC] = UC then LoTable[LC] := C;
  end;
end;

procedure SetDosCase;
var
  PLT, PUT: PChar;
begin
  if Lo(DosVersion) < 4 then Exit;
  PLT := @LoCaseMap;
  Inc(PLT, 128);
  PUT := @UpCaseMap;
  Inc(PUT, 128);
  SetCountryCharTables(PUpLoTable(PUT)^, PUpLoTable(PLT)^);
end;

function DataAddress(P: Pointer): Pointer;
type
  SO = record
    O, S: Word;
  end;
  JumpInstr = record
    Opcode: Byte;
    Address: Pointer;
  end;
begin
  if SO(P).S <> CSeg then DataAddress := JumpInstr(P^).Address
  else DataAddress := P;
end;

procedure SetAltCase;
var
  PLT, PUT: PChar;
begin
  PLT := @LoCaseMap;
  Inc(PLT, 128);
  PUT := @UpCaseMap;
  Inc(PUT, 128);
  Move(DataAddress(@LoTable)^, PLT^, 128);
  Move(DataAddress(@UpTable)^, PUT^, 128);
end;

procedure SetCountrySpecificInfo;
var
  Info: TCountryInfo;
begin
  if Lo(DosVersion) < 3 then Exit;
  GetCountrySpecificInfo(Info);
  if UseDOSCountryInfo and ciDate <> 0 then
    if Info.DateFormat > csYYMMDD then CountryDate := csYYDDMM
    else CountryDate := Info.DateFormat;
  if UseDOSCountryInfo and ciTime <> 0 then
    if Info.TimeFormat and 1 <> 0 then CountryTime := cs24Hour
    else CountryTime := cs12Hour;
  if UseDOSCountryInfo and ciDateSep <> 0 then
    DateSeparator := Info.DateSeparator[0];
  if UseDOSCountryInfo and ciTimeSep <> 0 then
    TimeSeparator := Info.TimeSeparator[0];
  if UseDOSCountryInfo and ciThouSep <> 0 then
    ThousandsSeparator := Info.ThousandsSeparator[0];
  if UseDOSCountryInfo and ciCharMap <> 0 then SetDosCase;
end;

end.
