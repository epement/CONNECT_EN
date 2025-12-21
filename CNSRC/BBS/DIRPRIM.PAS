{$I-,X+,F+,O+}
unit DirPrim;

interface

uses Dos, Objects;

type
  TDrivesArray = Array['A'..'\'] of Byte;

const
 ThousandsSeparator: Char = ',';

function GetCurDrive: Char;
procedure SetCurDrive(Drive: Char);
procedure GetDrives(var Num: Byte; var Drives: TDrivesArray);
function DriveValid(Drive: Char; var BytesFree: Real): Boolean;
function ClearedSlash(ADir: FNameStr): FNameStr;
function AddedSlash(ADir: FNameStr): FNameStr;
procedure InvertSlashes(var S: String);
function UCPos(S1, S2: String): Integer;
function PromptLikeStr(const S: String): String;
procedure GetCurDir(D: Byte; var S: String);
function PrevDir(ADir: FNameStr): FNameStr;
function RootName(const ADir: FNameStr): FNameStr;
function ThisFileExists(const FileName: FNameStr): Boolean;
function DirPresent(ADir: FNameStr): Boolean;
procedure SetSearchRecName(const Name: FNameStr;
  var SR: SearchRec; var Long: Boolean);
function QuasiShortName(const Name: String): String;
function CRCShortName(const Name: String): String;
procedure SetFirstFoundName(const Names: String; var Path: FNameStr);
procedure ValidDir(var ADir: String; var BytesFree: Real);
procedure FormatBytes(var Result: String; Bytes, Limit: Longint);
procedure FormatFloatBytes(var Result: String; Bytes, Limit: Real);
procedure ExpandName(var SSS: String; Count: Word);
function WildCardMatch(const Name, Card: FNameStr): Boolean;
procedure ExpandWildCards(var N, E, SourceName, SourceExt: String);
function IsWild(const S: String): Boolean;
function OnlyWildChars(const S: String): Boolean;

implementation

uses Strings, RevPos, CRC32, Disks, LFN,
  HeapUMB, TPString;

function GetCurDrive: Char;
var
  R: Registers;
begin
  R.AH := $19;
  MSDOS(R);
  GetCurDrive := Char(R.AL + $41);
end;

procedure SetCurDrive(Drive: Char);
var
  R: Registers;
begin
  R.AH := $0E;
  R.DL := Byte(Drive) - $41;
  MSDOS(R);
end;

procedure GetDrives(var Num: Byte; var Drives: TDrivesArray);
var
  C: Char;
  Mode: TSeekDrive;
  Equipment: Word absolute $0:$410;
begin
  Num := 0;
  FillChar(Drives, SizeOf(TDrivesArray), 0);
  if UserDrivesEnabled <> 0 then Mode := sdUser
  else Mode := sdDisk;
  for C := 'A' to 'Z' do
    if DriveAvailable(C, Mode) then
    begin
      Drives[C] := 1;
      Inc(Num);
    end;
  if (Equipment and $00C0 <> $40) and (Drives['B'] = 1) then
  begin
    Drives['B'] := 0;
    Dec(Num);
  end;
end;

{
function DriveValid(Drive: Char; var BytesFree: Longint): Boolean; assembler;
asm
        MOV     DL,Drive
        MOV     AH,36H
        SUB     DL,'A'-1
        INT     21H
        INC     AX
        JE      @@1
        DEC     AX
        MUL     CX
        MUL     BX
        LES     DI,DWORD PTR [BP+6]
        STOSW
        MOV     AX,DX
        STOSW
        MOV     AL,1
@@1:
end;
}

function DriveValid(Drive: Char; var BytesFree: Real): Boolean;
begin
  BytesFree := FDiskFree(Byte(Drive) - $40);
  DriveValid := BytesFree >= 0;
end;

function GetRedirEntry(Entry: Word; Local, Net: Pointer): Boolean; assembler;
asm
        PUSH    DS
        LDS     SI,Local
        LES     DI,Net
        MOV     AX,5F02H
        MOV     BX,Entry
        XOR     CX,CX
        INT     21H
        POP     DS
        SBB     AL,AL
        INC     AL
        SUB     BL,3
        AND     AL,BL
end;


function ClearedSlash(ADir: FNameStr): FNameStr;
begin
  while ADir[Byte(ADir[0])] = '\' do Dec(ADir[0]);
  ClearedSlash := ADir;
end;

function AddedSlash(ADir: FNameStr): FNameStr;
begin
  while ADir[Byte(ADir[0])] = '\' do Dec(ADir[0]);
  if ADir[0] < #255 then Inc(ADir[0]);
  ADir[Byte(ADir[0])] := '\';
  AddedSlash := ADir;
end;

procedure InvertSlashes(var S: String);
var
  B, L: Byte;
begin
  L := Length(S);
  for B := 1 to L do if S[B] = '/' then S[B] := '\';
end;

function UCPos(S1, S2: String): Integer;
begin
  UpcaseSt(S1);
  UpcaseSt(S2);
  UCPos := Pos(S1, S2);
end;

function PromptLikeStr(const S: String): String;
var
  B: Byte;
  Dir: FNameStr;
  SS: String;
begin
  SS := S;
  UpcaseSt(SS);
  GetDir(0, Dir);
  if Pos(Dir, SS) <> 1 then B := 1
  else
  begin
    B := Length(Dir) + 1;
    if (Length(S) >= B) and (S[B] = '\') then Inc(B);
  end;
  PromptLikeStr := Dir + '>' + Copy(S, B, 255);
end;

procedure GetCurDir(D: Byte; var S: String);
begin
  lGetDir(D, S);
  while S[Byte(S[0])] = '\' do Dec(S[0]);
end;

function PrevDir(ADir: FNameStr): FNameStr;
begin
  while ADir[Byte(ADir[0])] = '\' do Dec(ADir[0]);
  while (ADir[0] > #3) and (ADir[Byte(ADir[0])] <> '\') do Dec(ADir[0]);
  if ADir[0] > #2 then Dec(ADir[0]);
  PrevDir := ADir;
end;

function RootName(const ADir: FNameStr): FNameStr;
var
  B: Byte;
begin
  if ADir[1] <> '\' then RootName := ADir[1] + ':'
  else
  begin
    B := 3;
    while (B <= Length(ADir)) and (ADir[B] <> '\') do Inc(B);
    Inc(B);
    while (B <= Length(ADir)) and (ADir[B] <> '\') do Inc(B);
    RootName := Copy(ADir, 1, B - 1);
  end;
end;


function ThisFileExists(const FileName: FNameStr): Boolean;
var
  Attr: Word;
  F: ^lFile;
begin
  GetMem(F, SizeOf(lFile));
  lAssignFile(F^, FileName);
  lGetFAttr(F^, Attr);
  ThisFileExists := (DosError = 0) and (Attr and Directory = 0);
  FreeMem(F, SizeOf(lFile));
end;

function DirPresent(ADir: FNameStr): Boolean;
var
  SR: ^lSearchRec;
  R: Real;
begin
  while ADir[Byte(ADir[0])] = '\' do Dec(ADir[0]);
  if (ADir[0] = #2) and (ADir[2] = ':') then
    DirPresent := DriveValid(Upcase(ADir[1]), R)
  else
  begin
    GetMem(SR, SizeOf(lSearchRec));
    lFindFirst(ADir, AnyFile and not VolumeID, SR^);
    lFindClose(SR^);
    DirPresent := (DosError = 0) and (SR^.SR.Attr and Directory <> 0) and
      (SR^.SR.Name[1] <> '.') and not IsWild(ADir);
    FreeMem(SR, SizeOf(lSearchRec));
  end;
{
    if (DosError <> 0) or (SR.SR.Attr and Directory = 0) or
       (SR.SR.Name[1] = '.') then DirPresent := False
    else if Pos('\\', ADir) = 1 then DirPresent := True
    else
    begin
      if (SR.FullName <> '') and
         (StUpcase(SR.FullName) = StUpcase(System.Copy(
           ADir, Byte(ADir[0]) - Byte(SR.FullName[0]) + 1, 255))) then
        DirPresent := True
      else DirPresent := SR.SR.Name = StUpcase(System.Copy(
        ADir, Byte(ADir[0]) - Byte(SR.SR.Name[0]) + 1, 255));
    end;
  end;
}
end;

procedure SetSearchRecName(const Name: FNameStr;
  var SR: SearchRec; var Long: Boolean);
var
  B, L: Byte;
  E: String[3];
  N: String[8];
begin
  B := Pos('.', Name);
  L := Length(Name);
  Long := ((B = 0) and (L > 8)) or
    ((B <> 0) and (L - B > 3)) or (B > 9);
  if Long and (B <> 0) and (B <> L) then
  begin
    N := Copy(Name, 1, B - 1);
    E := Copy(Name, B + 1, 3);
    SR.Name := Concat(N, '.', E);
  end
  else SR.Name := Name;
{  UpcaseSt(SR.Name);}
end;

function QuasiShortName(const Name: String): String;
var
  I, N, E, L, Len: Integer;
  S: String;
begin
  N := 1; E := 0; L := 0;
  Len := Length(Name);
  for I := 1 to Len do
  begin
    if (Name[I] = '\') or ((N <= 8) and (E <= 4)) then
    begin
      Inc(L);
      S[L] := Name[I];
    end;
    if (Name[I] = '.') and (E = 0) then
    begin
      if N > 8 then
      begin
        Inc(L);
        S[L] := '.';
      end;
      N := 1;
      E := 1;
    end;
    if E = 0 then Inc(N)
    else Inc(E);
    if Name[I] = '\' then
    begin
      N := 1;
      E := 0;
    end;
  end;
  S[0] := Char(L);
  QuasiShortName := S;
end;

function CRCShortName(const Name: String): String;
var
  Slash: Boolean;
  ColonPos: Byte;
  I, L, Len: Integer;
  CRC: Longint;
  S: String;
begin
  Slash := False;
  L := 0;
  Len := Length(Name);
  if (Len > 1) and (Name[1] = '\') and (Name[2] = '\') then
    ColonPos := 1
  else ColonPos := Pos(':', Name);
  for I := 1 to Len do
  begin
    if Slash then IncCRCUC(Name[I], 1, CRC)
    else
    begin
      Inc(L);
      S[L] := Name[I];
      S[0] := Char(L);
    end;
    if (I > ColonPos) and (Name[I] = '\') then
    begin
      if Slash then
      begin
        S := Concat(S, HexL(CRC), '\');
        L := Length(S);
      end;
      CRC := -1;
      Slash := True;
    end;
  end;
  if Slash and (CRC <> -1) then S := Concat(S, HexL(CRC));
  CRCShortName := S;
end;

procedure SetFirstFoundName(const Names: String; var Path: FNameStr);
var
  B: Byte;
  S, C: String;
begin
  if Names = '' then
  begin
    Path := '';
    Exit;
  end;
  S := Names;
  repeat
    B := Pos(';', S);
    if B = 0 then B := Length(S) + 1;
    C := Concat(Path, Trim(Copy(S, 1, B - 1)));
    if (Length(C) > Length(Path)) and ThisFileExists(C) then
    begin
      Path := C;
      Exit;
    end;
    Delete(S, 1, B);
    TrimSt(S);
  until S = '';
  B := Pos(';', Names);
  if B = 0 then B := Length(Names) + 1;
  if B = 1 then Path := ''
  else Path := Concat(Path, Trim(Copy(Names, 1, B - 1)));
end;


procedure ValidDir(var ADir: String; var BytesFree: Real);
var
  Ch: Char;
  IsValid: Boolean;
begin
  IsValid := False;
  Ch := Upcase(ADir[1]);
  if (Ch = '\') and (ADir[0] > #2) and (ADir[2] = '\') then
  begin
    BytesFree := 0;
    while (Length(ADir) > Length(RootName(ADir))) and
      not DirPresent(ADir) do ADir := PrevDir(ADir);
  end
  else if DriveReady(Ch, BytesFree) then
  begin
    if Ch <> Upcase(ADir[1]) then GetCurDir(Byte(Ch) - $40, ADir);
    IsValid := ADir[0] = #2;
    while not IsValid do
    begin
      IsValid := (ADir[0] = #2) or DirPresent(ADir);
      if not IsValid then ADir := PrevDir(ADir);
    end;
  end
  else ADir := '';
end;

{ String formatting routines }

{$L FORMAT.OBJ}

procedure FormatStr(var Result: String; const Format: String; var Params);
external {FORMAT};


procedure FormatBytes(var Result: String; Bytes, Limit: Longint);
var
  P: Byte;
  S: String[2];
begin
  if Bytes < 0 then
  begin
    Result := '?';
    Exit;
  end;
  if Bytes < Limit then S := ''
  else
  begin
    Bytes := Bytes shr 10;
    S := ' K';
  end;
  FormatStr(Result, '%d', Bytes);
  if ThousandsSeparator <> #0 then
  begin
    P := Length(Result) + 1;
    while P > 4 do
    begin
      Dec(P, 3);
      System.Insert(ThousandsSeparator, Result, P);
    end;
  end;
  Result := Result + S;
end;

procedure FormatFloatBytes(var Result: String; Bytes, Limit: Real);
var
  P: Byte;
  S: String[2];
begin
  if Bytes < 0 then
  begin
    Result := '?';
    Exit;
  end;
  if Bytes < Limit then S := ''
  else
  begin
    Bytes := Bytes / 1024;
    S := ' K';
  end;
  Str(Bytes:16:0, Result);
  TrimSt(Result);
  if ThousandsSeparator <> #0 then
  begin
    P := Length(Result) + 1;
    while P > 4 do
    begin
      Dec(P, 3);
      System.Insert(ThousandsSeparator, Result, P);
    end;
  end;
  Result := Result + S;
end;

procedure ExpandName(var SSS: String; Count: Word); assembler;
asm
  cld
  les di,SSS
  mov cx,Count
  mov es:[di],cl
  inc di
  mov al,'*'
  repne scasb
  jne @@1
  dec di
  inc cx
  mov al,'?'
  rep stosb
@@1:
end;

{
function WildMatch(const Name, Ext, Mask: String): Boolean;
var
  PointPos, Index: Byte;
  AExt, MaskExt: String[3];
  AName, MaskName: String[8];
begin
asm
  cld
  mov di,sp
  push ss
  pop es
  mov al,' '
  mov cx,bp
  sub cx,di
  rep stosb
end;
  WildMatch := False;
  PointPos := Pos('.', Mask);
  if PointPos <> 0 then MaskExt := Copy(Mask, PointPos + 1, 3);
  AExt := Ext;
  AExt[0] := #3;
  ExpandName(MaskExt, 3);
  for Index := 1 to 3 do
    if (MaskExt[Index] <> '?') and
       (TPString.Upcase(MaskExt[Index]) <>
        TPString.Upcase(AExt[Index])) then Exit;
  if PointPos = 0 then MaskName := Mask
  else MaskName := Copy(Mask, 1, PointPos - 1);
  AName := Name;
  AName[0] := #8;
  ExpandName(MaskName, 8);
  for Index := 1 to 8 do
    if (MaskName[Index] <> '?') and
       (TPString.Upcase(MaskName[Index]) <>
        TPString.Upcase(AName[Index])) then Exit;
  WildMatch := True;
end;
}

function WildCardMatch(const Name, Card: FNameStr): Boolean;
var
  I, J, P, NameLen, CardLen: Integer;
begin
  WildCardMatch := False;
  I := 1;
  J := 1;
  NameLen := Length(Name);
  CardLen := Length(Card);
  P := NameLen + 1;
  while J <= CardLen do
    case Card[J] of
      '*':
        begin
          if P = NameLen + 1 then
          repeat
            Dec(P);
          until (P = 0) or (Name[P] = '.');
          while (J <= CardLen) and (Card[J] <> '.') do Inc(J);
          while (I < P) or
            ((I <= NameLen) and (Name[I] <> '.')) do Inc(I);
        end;
      '?':
        begin
          Inc(I);
          Inc(J);
        end;
      '.':
        begin
          if I <= NameLen then
            if Name[I] = '.' then Inc(I)
            else Exit;
          Inc(J);
        end;
      '+':
        begin
          if I <= NameLen then
            if Name[I] in ['0'..'9'] then Inc(I)
            else Exit;
          Inc(J);
        end;
      else
        begin
          if (I > NameLen) or
             (TPString.Upcase(Card[J]) <>
              TPString.Upcase(Name[I])) then Exit;
          Inc(I);
          Inc(J);
        end;
    end;
  WildCardMatch := (I > NameLen) and (J > CardLen);
end;

procedure ExpandWildCards(var N, E, SourceName, SourceExt: String);
var
  Index: Byte;
  AExt, Ext, AName, Name: String;
begin
asm
  cld
  mov di,sp
  push ss
  pop es
  mov al,' '
  mov cx,bp
  sub cx,di
  rep stosb
end;
  AName := SourceName;
  AName[0] := #255;
  AExt := SourceExt;
  AExt[0] := #255;
  Name := N;
  Ext := E;
  ExpandName(Name, 255);
  ExpandName(Ext, 255);
  for Index := 1 to 255 do
    if Name[Index] = '?' then Name[Index] := AName[Index];
  while Name[Length(Name)] = ' ' do Dec(Name[0]);
  N := Name;
  for Index := 1 to 255 do
    if Ext[Index] = '?' then Ext[Index] := AExt[Index];
  while Ext[Length(Ext)] = ' ' do Dec(Ext[0]);
  E := Ext;
end;

function IsWild(const S: String): Boolean;
begin
  IsWild := (Pos('*', S) > 0) or (Pos('?', S) > 0);
end;

function OnlyWildChars(const S: String): Boolean;
var
  B: Byte;
begin
  for B := 1 to Length(S) do
    if not (S[B] in ['*', '?', '.', ':', '\']) then
    begin
      OnlyWildChars := False;
      Exit;
    end;
  OnlyWildChars := True;
end;

end.