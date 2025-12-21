{$I-,X+,F+,O+}
unit DirPrim;

interface

uses Dos, Objects, Drivers, Views, Dialogs;

type
  TDrivesArray = Array['A'..'\'] of Byte;

  PInputChar = ^TInputChar;
  TInputChar = object(TView)
    Data: Char;
    constructor Init(var Bounds: TRect);
    function DataSize: Word; virtual;
    procedure Draw; virtual;
    procedure GetData(var Rec); virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SetData(var Rec); virtual;
  end;

function GetCurDrive: Char;
procedure SetCurDrive(Drive: Char);
procedure GetDrives(var Num: Byte; var Drives: TDrivesArray);
function DriveValid(Drive: Char; var BytesFree: Real): Boolean;
procedure GetRedirDevices(List: PCollection);
function ClearedSlash(ADir: FNameStr): FNameStr;
function AddedSlash(ADir: FNameStr): FNameStr;
procedure InvertSlashes(var S: String);
function UCPos(S1, S2: String): Integer;
function PromptLikeStr(const S: String): String;
procedure GetCurDir(D: Byte; var S: String);
function PrevDir(ADir: FNameStr): FNameStr;
function RootName(const ADir: FNameStr): FNameStr;
function CNFileName(const Name: FNameStr): FNameStr;
function ThisFileExists(const FileName: FNameStr): Boolean;
function DirPresent(ADir: FNameStr): Boolean;
procedure SetSearchRecName(const Name: FNameStr;
  var SR: SearchRec; var Long: Boolean);
function QuasiShortName(const Name: String): String;
function CRCShortName(const Name: String): String;
procedure SetFirstFoundName(const Names: String; var Path: FNameStr);
procedure SetNextFoundName(const Names, Name: String; var Path: FNameStr);
function InitSimpleDialog(var Bounds: TRect;
  const ATitle: TTitleStr; AHelpCtx: Word): PDialog;
function DriveReadyDlg(var ADrive: Char): Word;
function DriveReady(var ADrive: Char; var BytesFree: Real): Boolean;
procedure ValidDir(var ADir: String; var BytesFree: Real);
procedure FormatBytes(var Result: String; Bytes, Limit: Longint);
procedure FormatFloatBytes(var Result: String; Bytes, Limit: Real);
procedure ExpandName(var SSS: String; Count: Word);
function WildCardMatch(const Name, Card: FNameStr): Boolean;
procedure ExpandWildCards(var N, E, SourceName, SourceExt: String);
function IsWild(const S: String): Boolean;
function OnlyWildChars(const S: String): Boolean;

implementation

uses App, Strings, RevPos, ProgPath, CRC32, Disks, DrvList, LFN,
  HeapUMB, TPString, Consts, Defaults;

constructor TInputChar.Init(var Bounds: TRect);
begin
  Inherited Init(Bounds);
  State := State or sfCursorVis;
  Options := Options or (ofSelectable + ofFirstClick);
end;

function TInputChar.DataSize: Word;
begin
  DataSize := SizeOf(Char);
end;

procedure TInputChar.Draw;
var
  B: TDrawBuffer;
begin
  MoveChar(B, Data, GetColor(1), 1);
  WriteLine(0, 0, 1, 1, B);
end;

procedure TInputChar.GetData(var Rec);
begin
  Char(Rec) := Data;
end;

function TInputChar.GetPalette: PPalette;
const
  P: String[1] = #19;
begin
  GetPalette := @P;
end;

procedure TInputChar.HandleEvent(var Event: TEvent);
begin
  Inherited HandleEvent(Event);
  if (Event.What = evKeyDown) and ((Event.KeyCode = kbShiftTab) or
     (Event.CharCode in [^G, ^I, ^K, ^T, ^Y, #32..#255])) then
  begin
    if not (Event.CharCode in [#0, ^I]) then
    begin
      if Event.CharCode in [^G, ^K, ^T, ^Y] then
        Event.CharCode := #32;
      SetData(Event.CharCode);
    end;
    Event.What := evNothing;
  end;
end;

procedure TInputChar.SetData(var Rec);
begin
  Data := Char(Rec);
  DrawView;
end;

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
{ Added 2005.10.18 to avoid problems under WinNT }
  if DriveListOptions and dlGetFromUser = 0 then
  begin
    if (Equipment and $0001 = 0) and (Drives['A'] = 1) then
    begin
      Drives['A'] := 0;
      Dec(Num);
    end;
    if (Equipment and $00C0 <> $40) and (Drives['B'] = 1) then
    begin
      Drives['B'] := 0;
      Dec(Num);
    end;
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
{  BytesFree := FDiskFree(Byte(Drive) - $40);}
  BytesFree := FDiskFree(Drive + ':\');
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

procedure GetRedirDevices(List: PCollection);
var
  I: Integer;
  W: Word;
  P: PString;
  LocalName: Array[0..15] of Char;
  NetworkName: Array[0..127] of Char;
begin
  if DriveListOptions and dlUserResources <> 0 then
  for I := 0 to NetList^.Count - 1 do
  begin
    P := NetList^.At(I);
    if (P <> nil) and (Length(P^) > 1) and
       (Byte(P^[Length(P^)]) and udEnabled <> 0) then
{      List^.Insert(NewStr(Copy(P^, 1, Length(P^) - 1)))}
      List^.Insert(NewStrUMB(Copy(P^, 1, Length(P^) - 1)))
  end
  else for W := 0 to 255 do
  begin
    if not GetRedirEntry(W, @LocalName, @NetworkName) then Break;
    if not ((LocalName[0] in ['A'..'Z']) and (LocalName[1] = ':')) then
{      List^.Insert(NewStr(StrPas(PChar(@NetworkName))));}
      List^.Insert(NewStrUMB(StrPas(PChar(@NetworkName))));
  end;
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
  FailSysErrors := True;
  lGetDir(D, S);
  FailSysErrors := False;
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

function CNFileName(const Name: FNameStr): FNameStr;
var
  I: Integer;
  E, S: String;
begin
  S := Trim(Name);
  I := UCPos('$CN', S);
  if I <> 0 then
  begin
    Delete(S, I, 3);
    Insert(ClearedSlash(ProgramPath), S, I);
  end;
  if (S <> '') and (S[1] = '$') then
  begin
    I := Pos('\', S);
    if I = 0 then I := Length(S) + 1;
    E := GetEnv(Copy(S, 2, I - 2));
    if E <> '' then
    begin
      Delete(S, 1, I - 1);
      Insert(ClearedSlash(E), S, 1);
    end;
  end;
  CNFileName := S;
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
  else if (Pos('\\', ADir) = 1) and
    (Length(ADir) <= Length(RootName(ADir))) then DirPresent := True
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
  B, L: Integer;
  E: String[3];
  N: String[8];
begin
  B := RPos('.', Name);
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
  I: Integer;
  S, C: String;
begin
  if Names = '' then
  begin
    Path := '';
    Exit;
  end;
  S := Names;
  FailSysErrors := True;
  repeat
    I := Pos(';', S);
    if I = 0 then I := Length(S) + 1;
    C := Concat(Path, Trim(Copy(S, 1, I - 1)));
    if (Length(C) > Length(Path)) and ThisFileExists(C) then
    begin
      FailSysErrors := False;
      Path := C;
      Exit;
    end;
    Delete(S, 1, I);
    TrimSt(S);
  until S = '';
  FailSysErrors := False;
  I := Pos(';', Names);
  if I = 0 then I := Length(Names) + 1;
  if I = 1 then Path := ''
  else Path := Concat(Path, Trim(Copy(Names, 1, I - 1)));
end;

procedure SetNextFoundName(const Names, Name: String; var Path: FNameStr);
var
  Found: Boolean;
  I: Integer;
  S, C: String;
begin
  if Names = '' then
  begin
    Path := '';
    Exit;
  end;
  S := Names;
  Found := False;
  FailSysErrors := True;
  repeat
    I := Pos(';', S);
    if I = 0 then I := Length(S) + 1;
    C := Trim(Copy(S, 1, I - 1));
    if (Name <> '') and (StUpcase(C) = StUpcase(Name)) then Found := True
    else
    begin
      C := Concat(Path, C);
      if Found and (Length(C) > Length(Path)) and ThisFileExists(C) then
      begin
	FailSysErrors := False;
	Path := C;
	Exit;
      end;
    end;
    Delete(S, 1, I);
    TrimSt(S);
  until S = '';
  FailSysErrors := False;
  I := Pos(';', Names);
  if I = 0 then I := Length(Names) + 1;
  if I = 1 then Path := ''
  else Path := Concat(Path, Trim(Copy(Names, 1, I - 1)));
end;

function InitSimpleDialog(var Bounds: TRect;
  const ATitle: TTitleStr; AHelpCtx: Word): PDialog;
var
  D: PDialog;
begin
  D := New(PDialog, Init(Bounds, ATitle));
  D^.HelpCtx := AHelpCtx;
  StandardButtonRow(D, False);
  InitSimpleDialog := D;
end;

function DriveReadyDlg(var ADrive: Char): Word;
var
  C: Char;
  D: PDialog;
  R: TRect;
begin
  R.Assign(0, 0, 45, 7);
  D := InitSimpleDialog(R, 'Error', hcDriveReadyDialog);
  with D^ do
  begin
    Options := Options or ofCentered;
    R.Assign(2, 2, Size.X - 2, Size.Y - 1);
    Insert(New(PStaticText, Init(R,
      ^C'Can''t read the disk in drive ' + ADrive + ':'#13 +
      ^C'Press ENTER to try again, ESC to abort,'#13 +
      'or enter a different drive letter here  :')));
    R.Assign(Size.X - 4, Size.Y - 3, Size.X - 3, Size.Y - 2);
    Insert(New(PInputChar, Init(R)));
  end;
  C := Upcase(ADrive);
  if not DisableSounds then Write(^G);
  DriveReadyDlg := Application^.ExecuteDialog(D, @C, True);
  ADrive := Upcase(C);
end;

function DriveReady(var ADrive: Char; var BytesFree: Real): Boolean;
var
  SaveDrive: Char;
  Ready: Boolean;
  C: Word;
begin
  C := 0;
  SaveDrive := ' ';
  Ready := False;
  while (SaveDrive <> ADrive) and (C <> cmCancel) and not Ready do
  begin
    LogEvent := lcDiskRead;
    DrawStatusLine('Testing whether or not the disk in drive ' +
      ADrive + ': is available and ready.');
    SaveDrive := ADrive;
    FailSysErrors := True;
    Ready := DriveValid(ADrive, BytesFree);
    FailSysErrors := False;
    if not Ready then C := DriveReadyDlg(ADrive);
  end;
  if C = cmCancel then DriveReady := False
  else if Ready then DriveReady := True
  else DriveReady := DriveValid(ADrive, BytesFree);
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
    BytesFree := FDiskFree(ADir);
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
    Bytes := Bytes / 1024.0;
    if Bytes > 99999999.0 then
    begin
      Bytes := Bytes / 1024.0;
      S := ' M';
    end
    else S := ' K';
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

{
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
}

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
  mov al,'"'
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
  while Name[Length(Name)] = '"' do Dec(Name[0]);
  N := Name;
  for Index := 1 to 255 do
    if Ext[Index] = '?' then Ext[Index] := AExt[Index];
  while Ext[Length(Ext)] = '"' do Dec(Ext[0]);
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
