{$F+,I-,O+,X+}
unit Disks;

interface

type
  DiskClass =
    (Floppy360, Floppy12, Floppy720, Floppy144, Floppy288, OtherFloppy,
     Bernoulli, HardDisk, RamDisk, SubstDrive, NetDisk, UnknownDisk,
     InvalidDrive, CDROMDisk, DoubleSpaceDisk, Stacker4Disk, NetResource);

  TSeekDrive = (sdDisk, sdUser, sdAuto);

  TUserDrives = Array['A'..'Z'] of Byte;

{ Added 2005.11.01 }
  TExtDiskInfoRec = record
    InfoLevel: Word;
    SerialNumber: Longint;
    VolumeLabel: Array[1..11] of Char;
    FileSystem: Array[1..8] of Char;
  end;

const
  udNoLFN   = $40;
  udEnabled = $80;

var
  UserDrives: TUserDrives;

function Inst_CN_NT: Boolean;
function GetDiskClass(Drive: Char; var SubstDriveChar: Char): DiskClass;
function GetDiskDescription(Class: DiskClass): String;
function WhatFloppy(Drive: Char): Byte;
function IsRemovable(Drive: Char): Boolean;
function IsRemote(Drive: Char): Boolean;
procedure ClassifyDrive(Drive: Char; var Class: DiskClass);
function FDiskSize(const Path: String): Real;
function FDiskFree(const Path: String): Real;
function TotalDiskSpace(const Path: String): Longint;
function FreeDiskSpace(const Path: String): Longint;
{
function LDiskSize(Drive: Byte): Longint;
function LDiskFree(Drive: Byte): Longint;
}
function GetClusterSize(const Path: String): Longint;

function UserDrivesEnabled: Byte;
function UserDriveEnabled(Drive: Char): Boolean;
function GetUserDriveClass(Drive: Char): DiskClass;
function DriveAvailable(Drive: Char; Mode: TSeekDrive): Boolean;
function GetExtDiskInfo(Drive: Char; var R: TExtDiskInfoRec): Boolean;

function NT_GetVolumeLabel(Root: String): String;
procedure NT_GetCompFileSize(FileName: String;
  var CFileSizeLo: Longint; var CFileSizeHi: Longint);

{ Added 2006.01.30 to avoid GetFTime problems with CD files }
function GetFileTime(const S: String; var L: Longint): Boolean;

implementation

uses Dos, Drivers, Strings, DirPrim, LFN, Defaults;

function Inst_CN_NT: Boolean;
const
  Magic = $1117;
  CN_NT_Checked: Boolean = False;
var
  Regs: Registers;
begin
  if not CN_NT_Checked then
  begin
    CN_NT_Checked := True;
    Regs.ax := $1710;  {inst check}
    Intr($2f, Regs);
    CN_NT := Regs.ax = Magic;
  end;
  Inst_CN_NT := CN_NT;
end;

function GetDiskClass(Drive: Char; var SubstDriveChar: Char): DiskClass;
type
  ParamBlock = record
    DriveNumber, DeviceDriverUnit: Byte;
    BytesPerSector: Word;
    SectorsPerCluster, ShiftFactor: Byte;
    ReservedBootSectors: Word;
    FatCopies: Byte;
    RootDirEntries, FirstDataSector, HighestCluster: Word;
    SectorsPerFat: Byte;
    RootDirStartingSector: Word;
    DeviceDriverAddress: Pointer;
    Media2and3: Byte;
    Media4: Byte;
    NextDeviceParamBlock: Pointer;
  end;
  ParamBlockPtr = ^ParamBlock;
var
  Invalid: Boolean;
  DriveNum: Byte;
  MediaDescriptor: Byte;
  Regs: Registers;
  Path: Array[0..3] of Char;
begin
  GetDiskClass := InvalidDrive;

  SubstDriveChar := Drive;

  Drive := Upcase(Drive);
  case Drive of
    'A'..'Z': DriveNum := Ord(Drive) - $40;
    else Exit;
  end;

  with Regs do begin
    AH := $1C;
    DL := DriveNum;
    MsDos(Regs);
    MediaDescriptor := Mem[DS:BX];

    AH := $32;
    DL := DriveNum;
    MsDos(Regs);

    Invalid := (Flags and fCarry <> 0) or (AL = $FF);

    with ParamBlockPtr(Ptr(DS,BX))^ do begin
      if not Invalid and (DriveNumber <> Pred(DriveNum)) then begin
        GetDiskClass := SubstDrive;
        SubstDriveChar := Char(Ord('A') + DriveNumber);
      end
      else if FatCopies = 1 then
        GetDiskClass := RamDisk
      else if MediaDescriptor = $F8 then
        {if Invalid then GetDiskClass := HardFAT32
        else if HighestCluster <= 4087 then GetDiskClass := HardFAT12
        else} GetDiskClass := HardDisk
      else if (MediaDescriptor = $FD) and (SectorsPerFat <> 2) then
        GetDiskClass := Bernoulli
      else if MediaDescriptor >= $F9 then
        case HighestCluster of
           355 : GetDiskClass := Floppy360;
           714,
          1423 : GetDiskClass := Floppy720;
          2372 : GetDiskClass := Floppy12;
          else   GetDiskClass := OtherFloppy;
        end
      else if (MediaDescriptor = $F0) and (HighestCluster = 2848) then
        GetDiskClass := Floppy144
      else if CN_NT then with Regs do
      begin
        Path[0] := Drive;
        Path[1] := ':';
        Path[2] := '\';
        Path[3] := #0;
        AX := $1712;  {GetDriveType}
        BX := Ofs(Path);
        ES := Seg(Path);
        Intr($2F, Regs);
        if Flags and fCarry <> 0 then GetDiskClass := UnknownDisk
        else case AX of
          1: GetDiskClass := InvalidDrive;
          2: GetDiskClass := OtherFloppy;
          3: GetDiskClass := HardDisk;
          4: GetDiskClass := NetDisk;
          5: GetDiskClass := CDROMDisk;
          6: GetDiskClass := RAMDisk;
          else GetDiskClass := UnknownDisk;
        end;
      end
      else GetDiskClass := UnknownDisk;
    end;
  end;
end;

function GetDiskDescription(Class: DiskClass): String;
begin
  case Class of
    Floppy360: GetDiskDescription := 'Floppy 360 kB 5¬';
    Floppy720: GetDiskDescription := 'Floppy 720 kB 5¬';
    Floppy12: GetDiskDescription := 'Floppy 1.2 MB 5«';
    Floppy144: GetDiskDescription := 'Floppy 1.44 MB 3«';
    Floppy288: GetDiskDescription := 'Floppy 2.88 MB 3«';
    OtherFloppy: GetDiskDescription := 'Floppy drive';
    Bernoulli: GetDiskDescription := 'Bernoulli drive';
    HardDisk: GetDiskDescription := 'Hard disk'; {(FAT16)';}
    RamDisk: GetDiskDescription := 'RAM disk';
    SubstDrive: GetDiskDescription := 'Substitute drive';
    NetDisk: GetDiskDescription := 'Network disk';
    UnknownDisk: GetDiskDescription := 'Unknown disk';
    CDROMDisk: GetDiskDescription := 'CD-ROM disk';
    DoubleSpaceDisk: GetDiskDescription := 'DoubleSpace disk';
    Stacker4Disk: GetDiskDescription := 'Stacker disk';
    NetResource: GetDiskDescription := 'Network resource';
{
    HardFAT32: GetDiskDescription := 'Hard disk (FAT32)';
    HardFAT12: GetDiskDescription := 'Hard disk (FAT12)';
}
    else GetDiskDescription := 'Invalid drive';
  end;
end;

function DriveInstalled(Drive: Char): Boolean; assembler;
asm
        MOV     AH,19H
        INT     21H
        MOV     BL,AL
        MOV     DL,Drive
        SUB     DL,'A'
        MOV     AH,0EH
        INT     21H
        MOV     AH,19H
        INT     21H
        MOV     CX,0
        CMP     AL,DL
        JNE     @@1
        MOV     CX,1
        MOV     DL,BL
        MOV     AH,0EH
        INT     21H
@@1:    XCHG    AX,CX
end;

function WhatFloppy(Drive: Char): Byte;
begin
  Drive := Upcase(Drive);
asm
        MOV     DL,Drive
        SUB     DL,'A'
        MOV     AX,0800H
        INT     13H
        JNC     @@1
        XOR     BX,BX
@@1:
        MOV     @Result,BL
end;
end;

function IsRemovable(Drive: Char): Boolean;
begin
  Drive := Upcase(Drive);
asm
        MOV     BL,Drive
        SUB     BL,'A'-1
        MOV     AX,4408H
        INT     21H
        XOR     AL,1
        MOV     @Result,AL
end;
end;

function IsRemote(Drive: Char): Boolean;
begin
  Drive := Upcase(Drive);
asm
        MOV     BL,Drive
        SUB     BL,'A'-1
        MOV     AX,4409H
        INT     21H
        JC      @@1
        CMP     AL,0
        JNE     @@1
        TEST    DX,1000H
        JE      @@1
        MOV     AL,1
        JMP     @@2
@@1:
        XOR     AL,AL
@@2:
        MOV     @Result,AL
end;
end;

function IsSubst(Drive: Char): Boolean;
begin
  Drive := Upcase(Drive);
asm
        MOV     BL,Drive
        SUB     BL,'A'-1
        MOV     AX,4409H
        INT     21H
        JC      @@1
        CMP     AL,0
        JNE     @@1
        TEST    DX,8000H
        JE      @@1
        MOV     AL,1
        JMP     @@2
@@1:
        XOR     AL,AL
@@2:
        MOV     @Result,AL
end;
end;

function IsCD_ROM(Drive: Char): Boolean; { Check for CD-ROM v2.00+ }
begin
  Drive := Upcase(Drive);
asm
        MOV     AX,1500H
        SUB     BX,BX
        INT     2FH
        OR      BX,BX
        JZ      @@1
        MOV     AX,150BH
        SUB     CH,CH
        MOV     CL,Drive
        SUB     CL,'A' { -1 Fixed 19.09.95 }
        INT     2FH
        CMP     BX,0ADADH
        JNE     @@1
        OR      AX,AX
        JZ      @@2
        MOV     AL,1
        JMP     @@2
@@1:
        XOR     AL,AL
@@2:
        MOV     @Result,AL
end;
end;

function IsDoubleSpace(Drive: Char): Boolean;
begin
  Drive := Upcase(Drive);
asm
        MOV     AX,4A11H
        MOV     BX,1
        MOV     DL,Drive
        SUB     DL,'A'
        INT     2FH
        OR      AX,AX
        JNZ     @@1
        CMP     DL,BL
        JE      @@1
        TEST    BL,10000000B
        JZ      @@1
        ADD     DL,'A'
        CMP     DL,Drive
        JNE     @@1
        MOV     AL,1
        JMP     @@2
@@1:
        XOR     AL,AL
@@2:
        MOV     @Result,AL
end;
end;

procedure ClassifyDrive(Drive: Char; var Class: DiskClass);
var
  B: Byte;
  SD: Char;
begin
  FailSysErrors := True;
  if (DriveListOptions and dlGetFromUser <> 0) and
    UserDriveEnabled(Drive) then Class := GetUserDriveClass(Drive)
  else if DisableSysInfo then Class := UnknownDisk
  else if IsCD_ROM(Drive) then Class := CDROMDisk
  else if IsRemote(Drive) then Class := NetDisk
  else if IsSubst(Drive) then Class := SubstDrive
  else if IsDoubleSpace(Drive) then Class := DoubleSpaceDisk
  else
  begin
    B := WhatFloppy(Drive);
    Dec(B);
    if B <= Byte(OtherFloppy) then Class := DiskClass(B)
    else Class := GetDiskClass(Drive, SD);
  end;
  FailSysErrors := False;
end;

function GetDiskInfo(APath: String;
  var AAvailClusters, ATotalClusters,
  ABytesPerSector, ASectorsPerCluster: Longint): Boolean;
type
  TEFS = record
    r1: Word;
    r2: Word;
    SectorsPerCluster: Longint;
    BytesPerSector: Longint;
    AvailClusters: Longint;
    TotalClusters: Longint;
    r3: Array[0..23] of Byte;
  end;
var
  Drive: Byte;
  EFS: TEFS;
  Regs: Registers;
  Path: Array[0..256] of Char;
begin
  if APath = '' then
  begin
    Regs.AH := $19;
    Intr($21, Regs);
    Path[0] := Char(Regs.AL + $41);
    Path[1] := ':';
    Path[2] := '\';
    Path[3] := #0;
    Drive := 0;
  end
  else
  begin
    APath := AddedSlash(RootName(APath));
    Move(APath[1], Path, Length(APath));
    Path[Length(APath)] := #0;
    if not (APath[1] in ['A'..'Z', 'a'..'z']) then Drive := $FF
    else Drive := Byte(Upcase(APath[1])) - Byte($40);
  end;
  if CN_NT then with Regs do
  begin
    AX := $1711; {GetFreeDiskSize}
    BX := Ofs(Path);
    ES := Seg(Path);
    Intr($2F, Regs);
    if (Flags and fCarry <> 0) or (AX = 0) or (BX = 0) then
    begin
      CancelSysErrors := True;
      GetDiskInfo := False;
    end
    else
    begin
      ASectorsPerCluster := AX;
      ABytesPerSector := BX;
      AAvailClusters := Longint(DX) shl 16 + CX;
      ATotalClusters := Longint(BP) shl 16 + SI;
      GetDiskInfo := True;
    end;
  end
  else
  begin
    FillChar(EFS, SizeOf(EFS), 0);
    with Regs do
    begin
      AX := $7303;
      DS := Seg(Path);
      DX := Ofs(Path);
      ES := Seg(EFS);
      DI := Ofs(EFS);
      CX := SizeOf(EFS);
      asm
        stc
      end;
      Intr($21, Regs);
    end;
    if Regs.Flags and fCarry <> 0 then
    begin
      asm
        mov ah,36h
        mov dl,Drive
        int 21h
        mov Word ptr EFS.SectorsPerCluster,ax
        mov Word ptr EFS.AvailClusters,bx
        mov Word ptr EFS.BytesPerSector,cx
        mov Word ptr EFS.TotalClusters,dx
      end;
    end;
    if EFS.SectorsPerCluster = $FFFF then GetDiskInfo := False
    else
    begin
      GetDiskInfo := True;
      ASectorsPerCluster := EFS.SectorsPerCluster;
      AAvailClusters := EFS.AvailClusters;
      ABytesPerSector := EFS.BytesPerSector;
      ATotalClusters := EFS.TotalClusters;
    end;
  end;
end;

function GetClusterSize(const Path: String): Longint;
var
  Size: Longint;
  ClustersAvailable, TotalClusters,
  BytesPerSector, SectorsPerCluster: Longint;
begin
  Size := 0;
  if GetDiskInfo(Path, ClustersAvailable, TotalClusters,
    BytesPerSector, SectorsPerCluster) then
      Size := BytesPerSector * SectorsPerCluster;
  if Size = 0 then Size := $8000;
  GetClusterSize := Size;
end;

function FDiskSize(const Path: String): Real;
var
  ClustersAvailable, TotalClusters,
  BytesPerSector, SectorsPerCluster: Longint;
  R: Real;
begin
  if GetDiskInfo(Path, ClustersAvailable, TotalClusters,
    BytesPerSector, SectorsPerCluster) then
  begin
    R := SectorsPerCluster;
    FDiskSize := R * BytesPerSector * TotalClusters;
  end
  else FDiskSize := -1;
end;

function FDiskFree(const Path: String): Real;
var
  ClustersAvailable, TotalClusters,
  BytesPerSector, SectorsPerCluster: Longint;
  R: Real;
begin
  if GetDiskInfo(Path, ClustersAvailable, TotalClusters,
    BytesPerSector, SectorsPerCluster) then
  begin
    R := SectorsPerCluster;
    FDiskFree := R * BytesPerSector * ClustersAvailable;
  end
  else FDiskFree := -1;
end;

function TotalDiskSpace(const Path: String): Longint;
var
  L: Longint;
  R: Real;
begin
  R := FDiskSize(Path);
  if R < 0 then L := -1
  else if R > MaxLongint then L := MaxLongint
  else L := Trunc(R);
  TotalDiskSpace := L;
end;

function FreeDiskSpace(const Path: String): Longint;
var
  L: Longint;
  R: Real;
begin
  R := FDiskFree(Path);
{ Fixed 2005.12.06 }
{
  if R < 0 then L := -1
  else if R > MaxLongint then L := MaxLongint
}
  if (R < 0) or (R > MaxLongint) then L := MaxLongint
  else L := Trunc(R);
  FreeDiskSpace := L;
end;

{
function LDiskSize(Drive: Byte): Longint;
var
  ClustersAvailable, TotalClusters,
  BytesPerSector, SectorsPerCluster: Longint;
begin
  if GetDiskInfo(Drive, ClustersAvailable, TotalClusters,
    BytesPerSector, SectorsPerCluster) then
   LDiskSize := SectorsPerCluster * BytesPerSector * TotalClusters
  else LDiskSize := -1;
end;

function LDiskFree(Drive: Byte): Longint;
var
  ClustersAvailable, TotalClusters,
  BytesPerSector, SectorsPerCluster: Longint;
begin
  if GetDiskInfo(Drive, ClustersAvailable, TotalClusters,
    BytesPerSector, SectorsPerCluster) then
   LDiskFree := SectorsPerCluster * BytesPerSector * ClustersAvailable
  else LDiskFree := -1;
end;
}

function UserDrivesEnabled: Byte;
var
  B: Byte;
  Drive: Char;
begin
  B := 0;
  for Drive := 'A' to 'Z' do
    if UserDrives[Drive] and udEnabled <> 0 then Inc(B);
  UserDrivesEnabled := B;
end;

function UserDriveEnabled(Drive: Char): Boolean;
begin
  UserDriveEnabled := UserDrives[Drive] and udEnabled <> 0;
end;

function GetUserDriveClass(Drive: Char): DiskClass;
var
  B: Byte;
begin
  B := UserDrives[Drive] and not (udNoLFN + udEnabled);
  if B = 0 then B := Byte(UnknownDisk) else Dec(B);
  GetUserDriveClass := DiskClass(B);
end;

function NT_GetLogicalDrives: Longint;
var
 Regs: Registers;
begin
 Regs.ax := 0;
 Regs.bx := 0;
 Regs.ax := $1713; {GetLogicalDrives}
 Intr($2f, Regs);
 NT_GetLogicalDrives := Longint(Regs.bx) shl 16 + Regs.ax;
end;

function DriveAvailable(Drive: Char; Mode: TSeekDrive): Boolean;
var
  I: Integer;
  L: Longint;
  User: Boolean;
begin
  if Mode = sdDisk then User := False
  else if Mode = sdUser then User := True
  else User := UserDrivesEnabled <> 0;
  if User and (DriveListOptions and dlGetFromUser <> 0) then
    DriveAvailable := UserDriveEnabled(Drive)
{ Added 2005.12.28 }
  else if CN_NT then
  begin
    L := NT_GetLogicalDrives;
    I := Byte(Drive) - Byte('A');
    DriveAvailable := (L and (Longint(1) shl I) <> 0);
  end
{ Added 2005.10.18 to avoid problems under WinNT }
  else if Drive < 'C' then DriveAvailable := True
  else DriveAvailable := DriveInstalled(Drive);
end;

function GetExtDiskInfo(Drive: Char; var R: TExtDiskInfoRec): Boolean;
var
  B: Boolean;
  Regs: Registers;
begin
  GetExtDiskInfo := False;
  FillChar(R, SizeOf(TExtDiskInfoRec), 0);
  if DisableSysInfo then Exit;
  Drive := Upcase(Drive);
  B := FailSysErrors;
  FailSysErrors := True;
  with Regs do
  begin
    AL := 0; {get}
    AH := $69;
    BL := Byte(Drive) - Byte('A') + 1;
    BH := 0;
    DS := Seg(R);
    DX := Ofs(R);
    Intr($21, Regs);
    GetExtDiskInfo := Flags and fCarry = 0;
  end;
  FailSysErrors := B;
end;

function NT_GetVolumeLabel(Root: String): String;
var
 Regs: Registers;
 Res: Boolean;
 VLabel: String[32];
 SN: Longint;
begin
{ VLabel := 'Llabel';}
 Res := False;
 if CN_NT and (Length(Root) < 254) then
  With Regs do
  begin
   Root[Length(Root)+1] := #0;
   ax := $1719; {}
   bx := ofs(Root[1]);
   es := seg(Root[1]);
   cx := ofs(VLabel[1]);
   ds := seg(VLabel[1]);
   Intr($2f, Regs);
   SN := longint(bx) shl 16 + cx;
   Res := Boolean(ax);
  end;
 if Not Res then VLabel := ''
 else VLabel[0] := char(StrLen(Pchar(Addr(VLabel[1]))));
 NT_GetVolumeLabel := VLabel;
end;

procedure NT_GetCompFileSize(FileName: String;
  var CFileSizeLo: Longint; var CFileSizeHi: Longint);
var
  Regs: Registers;
begin
  CFileSizeLo := 0;
  CFileSizeHi := 0;
  if Length(FileName) < 255 then
  begin
    FileName[Length(FileName) + 1] := #0;
    with Regs do
    begin
      AX := $1714; {GetCompressedFileSize}
      BX := Ofs(FileName[1]);
      ES := Seg(FileName[1]);
      Intr($2F, Regs);
      CFileSizeLo := Longint(BX) shl 16 + AX;
      CFileSizeHi := Longint(DX) shl 16 + CX;
    end;
  end;
end;

{ Added 2006.01.30 to avoid GetFTime problems with CD files }
function GetFileTime(const S: String; var L: Longint): Boolean;
var
  SR: lSearchRec;
begin
  lFindFirst(S, AnyFile and not (VolumeID + Directory), SR);
  lFindClose(SR);
  if DosError = 0 then
  begin
    L := SR.SR.Time;
    GetFileTime := True;
  end
  else GetFileTime := False;
end;

end.