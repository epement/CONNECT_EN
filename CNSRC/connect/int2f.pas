Unit int2f;
interface

const
 {Drive types for GetDriveType() function}
 drive_Unknown   = 0;  {The drive type cannot be determined.}
 drive_Invalid   = 1;  {The root directory does not exist.}
 drive_Removable = 2;  {The drive can be removed from the drive.}
 drive_Fixed     = 3;  {The disk cannot be removed from the drive.}
 drive_Remote    = 4;  {The drive is a remote (network) drive.}
 drive_Cdrom     = 5;  {The drive is a CD-ROM drive.}
 drive_Ramdisk   = 6;  {The drive is a RAM disk.}


 {File/Dir attributes for ntSetFAttr()/ntGetFAttr() functions}
 file_Attribute_Readonly             = $00000001; {*}
 file_Attribute_Hidden               = $00000002; {*}
 file_Attribute_System               = $00000004; {*}
 file_Attribute_Directory            = $00000010;
 file_Attribute_Archive              = $00000020; {*}
 file_Attribute_Device               = $00000040;
 file_Attribute_Normal               = $00000080;
 file_Attribute_Temporary            = $00000100;
 file_Attribute_Sparse_File          = $00000200;
 file_Attribute_Reparse_Point        = $00000400;
 file_Attribute_Compressed           = $00000800; {*}
 file_Attribute_Offline              = $00001000;
 file_Attribute_Not_Content_Indexed  = $00002000;
 file_Attribute_Encrypted            = $00004000; {*}

 {Console events for GetConsoleCtl function}
 CTRL_C_EVENT           = 1;
 CTRL_CLOSE_EVENT       = 2;
 CTRL_BREAK_EVENT       = 3;
 CTRL_LOGOFF_EVENT      = 4;
 CTRL_SHUTDOWN_EVENT    = 5;

 {File date and time}
 CreationTime           = 0;
 LastAccessTime         = 1;
 LastWriteTime          = 2;


{ GetVolumeInformation Flags }
 fs_Case_Is_Preserved          = $00000002;
 fs_Case_Sensitive             = $00000001;
 fs_Unicode_Stored_On_Disk     = $00000004;
 fs_Persistent_ACLs            = $00000008;
 fs_Vol_is_Compressed          = $00008000;
 fs_File_Compression           = $00000010;



const
 CN_NT: Boolean = False;

function Inst_CN_NT: Boolean;
procedure GetFreeDiskSize(PathName: String;
                          var SectorsPerCluster: Longint;
                          var BytesPerSector: Longint;
                          var NumberOfFreeClusters: Longint;
                          var TotalNumberOfClusters: Longint);
function GetDriveType(PathName: String): Word;
function GetLogicalDrives: Longint;
procedure GetCompFileSize(Name: String;
                          var FileSize: Longint;
                          var CompSize: Longint);

function ExecNT(cmd, redir: PChar; Flags: Longint): Longint;
function SHExec(cmd, params: String; Flag: Integer): Longint;
function DelToTrash(Name: String): Boolean;
function EmptyTrash(Name: String): Boolean;
function SysInfo(var SiBuf): Longint;
procedure ScrInfo(var ScrBuf);
function SetLabel(Root, VLabel: String): Boolean;
function GetLabel(Root: String): String;
function GetVolumeInfo(Root: String;
                       var SN: Longint;
                       var FileSystemFlags: Longint): Boolean;
function SetTitle(Title: String): Boolean;
function ntSetFAttr(fName: String; fAttr: Longint): Boolean;
function ntGetFAttr(fName: String): Longint;
function GetConsoleCtl: Longint;
function ntSetFTime(fName: String; fTime: Longint; tTime: Byte): Boolean;
function ntGetFTime(fName: String; var fTime: Longint; tTime: Byte): Boolean;

function SetDirCheck(Dir: String): Longint; {Handle}
function SetTreeCheck(Dir: String): Longint; {Handle}
function DirCheck(var Handle: Longint): Boolean;
procedure DirFree(Handle: Longint);
function SysCopy(src, dest: String; Flag: Word; progress: pointer): Boolean;
function WinMsgBox(Text, Caption: String; Flag: Longint): Longint;
function CommOpen(Comm: Byte; Baud: Word; Bits: Byte;
                  Parity: Char; Stop: Byte): Boolean;
function ReadBuf(Comm: Word; var Buf; Count: Word): Word;
function WriteBuf(Comm: Word; var Buf; Count: Word): Word;
function CommClose(Comm: Word): Boolean;
function CommCTL(Comm, CTL: Word): Boolean;

implementation

Uses
 DOS, Strings;

const
 Magic = $1117;

function Inst_CN_NT: Boolean;
var
 Regs: Registers;
begin
 with Regs do
  begin
   ax := $1710;  {inst check}
   Intr($2f, Regs);
   CN_NT := ax = Magic;
   Inst_CN_NT := CN_NT;
  end;
end;

{
The GetDiskFreeSpace function retrieves information about the specified
disk, including the amount of free space on the disk.

BOOL GetDiskFreeSpace(

    LPCTSTR lpRootPathName,     // address of root path
    LPDWORD lpSectorsPerCluster, // address of sectors per cluster
    LPDWORD lpBytesPerSector,   // address of bytes per sector
    LPDWORD lpNumberOfFreeClusters,  // address of number of free clusters
    LPDWORD lpTotalNumberOfClusters  // address of total number of clusters
   );


Parameters

lpRootPathName

Points to a null-terminated string that specifies the root directory
of the disk to return information about. If lpRootPathName
is NULL, the function uses the root of the current directory.

lpSectorsPerCluster

Points to a variable for the number of sectors per cluster.

lpBytesPerSector

Points to a variable for the number of bytes per sector.

lpNumberOfFreeClusters

Points to a variable for the total number of free clusters on the disk.

lpTotalNumberOfClusters

Points to a variable for the total number of clusters on the disk.



Return Values

If the function succeeds, the return value is nonzero.
If the function fails, the return value is zero. To get extended error
information, call GetLastError.

Remarks

Windows 95:

The GetDiskFreeSpace function returns incorrect values for volumes
that are larger than 2 gigabytes. The function caps the values
stored into *lpNumberOfFreeClusters and *lpTotalNumberOfClusters
so as to never report volume sizes that are greater than 2 gigabytes.

Even on volumes that are smaller than 2 gigabytes, the values stored
into *lpSectorsPerCluster, *lpNumberOfFreeClusters, and
*lpTotalNumberOfClusters values may be incorrect.
That is because the operating system manipulates the values so
that computations with them yield the correct volume size.

}
procedure GetFreeDiskSize(PathName: String;
                          var SectorsPerCluster: Longint;
                          var BytesPerSector: Longint;
                          var NumberOfFreeClusters: Longint;
                          var TotalNumberOfClusters: Longint);
var
 Regs: Registers;

begin
 SectorsPerCluster := 0;
 BytesPerSector := 0;
 NumberOfFreeClusters := 0;
 TotalNumberOfClusters := 0;

 if CN_NT then
  begin
   if Length(PathName) < 255 then
    with Regs do
     begin
      PathName[Length(PathName)+1] := #0;
      ax := $1711; {GetFreeDIskSize}
      bx := ofs(PathName[1]);
      es := seg(PathName[1]);
      Intr($2f, Regs);
      SectorsPerCluster := ax;
      BytesPerSector := bx;
      NumberOfFreeClusters := longint(dx) shl 16 + cx;
      TotalNumberOfClusters := longint(bp) shl 16 + si;
     end;
  end;
end;

{
The GetDriveType function determines whether a disk drive is a
removable, fixed, CD-ROM, RAM disk, or network drive.

UINT GetDriveType(
    LPCTSTR lpRootPathName      // address of root path
   );


Parameters

lpRootPathName

Points to a null-terminated string that specifies the root
directory of the disk to return information about. If lpRootPathName
is NULL, the function uses the root of the current directory.


Return Values

The return value specifies the type of drive.
It can be one of the following values:

Value   Meaning
0               The drive type cannot be determined.
1               The root directory does not exist.
DRIVE_REMOVABLE The drive can be removed from the drive.
DRIVE_FIXED     The disk cannot be removed from the drive.
DRIVE_REMOTE    The drive is a remote (network) drive.
DRIVE_CDROM     The drive is a CD-ROM drive.
DRIVE_RAMDISK   The drive is a RAM disk.
}

function GetDriveType(PathName: String): Word;
var
 Regs: Registers;
begin
 Regs.ax := 0;
 if CN_NT then
  begin
   if Length(PathName) < 255 then
    with Regs do
     begin
      PathName[Length(PathName)+1] := #0;
      ax := $1712;  {GetDriveType}
      bx := ofs(PathName[1]);
      es := seg(PathName[1]);
      Intr($2f, Regs);
      GetDriveType := ax;
     end;
  end;
end;

{
The GetLogicalDrives function returns a bitmask representing the
currently available disk drives.

DWORD GetLogicalDrives(VOID)

Parameters

This function has no parameters.

Return Values

If the function succeeds, the return value is a bitmask representing
the currently available disk drives. Bit position 0 (the least-significant
bit) is drive A, bit position 1 is drive B, bit position 2 is drive C, and
so on. If the function fails, the return value is zero.
}

function GetLogicalDrives: Longint;
var
 Regs: Registers;
begin
 Regs.ax := 0;
 Regs.bx := 0;
 if CN_NT then
  with Regs do
   begin
    ax := $1713; {GetLogicalDrives}
    Intr($2f, Regs);
    GetLogicalDrives := Longint(bx) shl 16 + ax;
   end;
end;

procedure GetCompFileSize(Name: String;
                          var FileSize: Longint;
                          var CompSize: Longint);
var
 Regs: Registers;

begin
 FileSize := 0;
 CompSize := 0;

 if CN_NT then
  begin
   if Length(Name) < 255 then
    with Regs do
     begin
      Name[Length(Name)+1] := #0;
      ax := $1714; {GetCompressedFileSize}
      bx := ofs(Name[1]);
      es := seg(Name[1]);
      Intr($2f, Regs);
      FileSize := longint(bx) shl 16 + ax;
      CompSize := longint(dx) shl 16 + cx;
     end;
  end;
end;

function ExecNT(cmd, redir: PChar; Flags: Longint): Longint;
var
 Regs: Registers;
 Result: Longint;
 pa, pb: Pchar;
begin
 Result := -1;
 if CN_NT then
  With Regs do
  begin
   ax := $1715; {ExecNT}
   bx := ofs(cmd^);
   es := seg(cmd^);
   cx := ofs(redir^);
   ds := seg(redir^);
   dx := Flags and $FFFC;
   si := Flags shr 16;
   bp := Flags and $3;{options, eoErrIgnore = 1 eoErrZero = 2}
   Intr($2f, Regs);
   Result := longint(bx) shl 16 + ax;
  end;
 ExecNT := Result;
end;

function DelToTrash(Name: String): Boolean;
var
 Regs: Registers;
 Res: boolean;

begin
 if CN_NT then
  begin
   if Length(Name) < 254 then
    With Regs do
      begin
       Name[Length(Name)+1] := #0;
       Name[Length(Name)+2] := #0;
       ax := $1716; {Del_Trash}
       bx := ofs(Name[1]);
       es := seg(Name[1]);
       Intr($2f, Regs);
       Res := boolean(ax);
      end;
  end;
end;

function EmptyTrash(Name: String): Boolean;
var
 Regs: Registers;
 Res: boolean;

begin
 Res := False;
 if CN_NT then
  begin
   if Length(Name) < 254 then
    With Regs do
      begin
       Name[Length(Name)+1] := #0;
       Name[Length(Name)+2] := #0;
       ax := $1717; {EmptyTrash}
       bx := ofs(Name[1]);
       es := seg(Name[1]);
       Intr($2f, Regs);
       Res := boolean(ax);
      end;
   EmptyTrash := Res;
  end;
end;

function SysInfo(var SiBuf): Longint;
var
 Regs: Registers;

begin
 if CN_NT then
  begin
    With Regs do
      begin
       ax := $1718; {SysInfo}
       bx := ofs(SiBuf);
       es := seg(SiBuf);
       Intr($2f, Regs);
       SysInfo := Longint(bx) shl 16 + ax;
      end;
  end;
end;

function GetLabel(Root: String): String;
var
 Regs: Registers;
 Res: Boolean;
 VLabel: String[32];
 SN: Longint;
 FileSystemFlags: Longint;
begin
 if CN_NT and (Length(Root) < 254) then
  With Regs do
  begin
   Root[Length(Root)+1] := #0;
   ax := $1719; {GetVolumeInformation}
   bx := ofs(Root[1]);
   es := seg(Root[1]);
   cx := ofs(VLabel[1]);
   ds := seg(VLabel[1]);
   Intr($2f, Regs);
   SN := longint(bx) shl 16 + cx;
   FileSystemFlags := longint(si) shl 16 + dx;
   Res := Boolean(ax);
  end;
 if Not Res then VLabel := ''
 else VLabel[0] := char(StrLen(Pchar(Addr(VLabel[1]))));
 GetLabel := VLabel;
end;

function GetVolumeInfo(Root: String;
                       var SN: Longint;
                       var FileSystemFlags: Longint): Boolean;
var
 Regs: Registers;
 Res: Boolean;
begin
 if CN_NT and (Length(Root) < 254) then
  With Regs do
  begin
   Root[Length(Root)+1] := #0;
   ax := $1719; {GetVolumeInformation}
   bx := ofs(Root[1]);
   es := seg(Root[1]);
   cx := 0;
   ds := 0;
   Intr($2f, Regs);
   SN := longint(bx) shl 16 + cx;
   FileSystemFlags := longint(si) shl 16 + dx;
   Res := Boolean(ax);
  end;
 GetVolumeInfo := Res;
end;

function SetLabel(Root, VLabel: String): Boolean;
var
 Regs: Registers;
 Res: Boolean;

begin
 if CN_NT and (Length(Root) < 254) and (Length(VLabel) < 254) then
  With Regs do
  begin
   Root[Length(Root)+1] := #0;
   VLabel[Length(VLabel)+1] := #0;
   ax := $1720; {}
   bx := ofs(Root[1]);
   es := seg(Root[1]);
   cx := ofs(VLabel[1]);
   ds := seg(VLabel[1]);
   Intr($2f, Regs);
   Res := Boolean(Regs.ax);
  end;
 SetLabel := Res;
end;

function SetTitle(Title: String): Boolean;
var
 Regs: Registers;
 Res: Boolean;

begin
 if CN_NT and (Length(Title) < 254) then
  With Regs do
  begin
   Title[Length(Title)+1] := #0;
   ax := $1721; {}
   bx := ofs(Title[1]);
   es := seg(Title[1]);
   Intr($2f, Regs);
   Res := Boolean(Regs.ax);
  end;
 SetTitle := Res;
end;

function ntSetFAttr(fName: String; fAttr: Longint): Boolean;
var
 Regs: Registers;
 Res: Boolean;

begin
 if CN_NT and (Length(fName) < 254) then
  With Regs do
  begin
   fName[Length(fName)+1] := #0;
   ax := $1722; {}
   bx := ofs(fName[1]);
   es := seg(fName[1]);
   cx := Word(fAttr);
   dx := fAttr shr 16;
   Intr($2f, Regs);
   Res := Boolean(Regs.ax);
  end;
 ntSetFAttr := Res;
end;

function ntGetFAttr(fName: String): Longint;
var
 Regs: Registers;

begin
 if CN_NT and (Length(fName) < 254) then
  With Regs do
  begin
   fName[Length(fName)+1] := #0;
   ax := $1723; {}
   bx := ofs(fName[1]);
   es := seg(fName[1]);
   Intr($2f, Regs);
   ntGetFAttr := longint(bx) shl 16 + ax;
  end;
end;

function GetConsoleCtl: Longint;
var
 Regs: Registers;

begin
 if CN_NT then
  With Regs do
  begin
   ax := $170f; {}
   Intr($2f, Regs);
   GetConsoleCtl := longint(bx) shl 16 + ax;
  end;
end;

(*
INT 21h  AX=71A7 BL=01
 INT 21 - Windows95 - LONG FILENAME - DOS TIME TO FILE TIME
         AX = 71A7h
         BL = 01h
         CX = DOS time (see #1351)
         DX = DOS date (see #1352)
         BH = hundredths (10-millisecond units past time in CX)
         ES:DI -> buffer for QWORD file time
 Return: CF clear if successful
             ES:DI buffer filled
         CF set on error
             AX = error code
                 7100h if function not supported
 Desc:   convert DOS-style date and time (local timezone) into Win95 64-bit
           file time (UTC)
 See: AX=71A6h,AX=71A7h/BL=00h

 Bitfields for file time:
 Bit(s)  Description     (Table 1351)
  15-11  hours (0-23)
  10-5   minutes
  4-0    seconds/2

 See: INT 21h  AX=5700

 Bitfields for file date:
 Bit(s)  Description     (Table 1352)
  15-9   year - 1980
  8-5    month
  4-0    day
 See: INT 21h  AX=5700
*)


function ntSetFTime(fName: String; fTime: Longint; tTime: Byte): Boolean;
type
 tFileTime = record
   fTimeLow, fTimeHigh: Longint;
 end;

var
 fTimeLowHigh: tFileTime;
 Regs: Registers;
 Res: Boolean;

begin
 if CN_NT and (Length(fName) < 254) then
  With Regs, fTimeLowHigh do
  begin
   fName[Length(fName)+1] := #0;
   ax := $71a7;
   bl := 1;
   cx := Word(fTime);
   dx := fTime shr 16;
   bh := 0;
   di := ofs(fTimeLowHigh);
   es := seg(fTimeLowHigh);
   Intr($21, Regs);
   if (Flags and fCarry) = 0 then
    begin
     ax := $1724; {}
     bx := ofs(fName[1]);
     es := seg(fName[1]);
     cx := Word(fTimeLow);
     dx := fTimeLow shr 16;
     si := Word(fTimeHigh);
     bp := fTimeHigh shr 16;
     ds := tTime;
     Intr($2f, Regs);
     Res := Boolean(ax);
    end
   else Res := False;
  end;
 ntSetFTime := Res;
end;

(*
INT 21h  AX=71A7 BL=00
 INT 21 - Windows95 - LONG FILENAME - FILE TIME TO DOS TIME
         AX = 71A7h
         BL = 00h
         DS:SI -> QWORD file time
 Return: CF clear if successful
             CX = DOS time (see #1351)
             DX = DOS date (see #1352)
             BH = hundredths (10-millisecond units past time in CX)
         CF set on error
             AX = error code
                 7100h if function not supported
 Desc:   convert Win95 64-bit file time (UTC) into DOS-style date and time
           (local timezone)
 Note:   the conversion fails if the file time's value is outside the range
           01jan1980 and 31dec2107
 See: AX=71A6h,AX=71A7h/BL=01h
*)

function ntGetFTime(fName: String; var fTime: Longint; tTime: Byte): Boolean;
type
 tFileTime = record
   fTimeLow, fTimeHigh: Longint;
 end;

var
 fTimeLowHigh: tFileTime;
 Regs: Registers;
 Res: Boolean;

begin
 if CN_NT and (Length(fName) < 254) then
  With Regs, fTimeLowHigh do
  begin
   fName[Length(fName)+1] := #0;
   ax := $1725; {}
   bx := ofs(fName[1]);
   es := seg(fName[1]);
   ds := tTime;
   Intr($2f, Regs);
   fTimeLow :=  Longint(dx) shl 16 + cx;
   fTimeHigh := Longint(bp) shl 16 + si;
   Res := Boolean(ax);
   if Res then
    begin
     ax := $71a7;
     bl := 0;
     si := ofs(fTimeLowHigh);
     ds := seg(fTimeLowHigh);
     Intr($21, Regs);
     if (Flags and fCarry) = 0 then
       fTime := Longint(dx) shl 16 + cx
     else Res := False;
    end;
  end;
 ntGetFTime := Res;
end;


function SetDirCheck(Dir: String): Longint; {Handle}
var
 Regs: Registers;

begin
 if CN_NT and (Length(Dir) < 254) then
  With Regs do
  begin
   Dir[Length(Dir)+1] := #0;
   ax := $170d; {}
   bx := ofs(Dir[1]);
   es := seg(Dir[1]);
   cx := 0;
   dx := 0;
   si := 0;
   Intr($2f, Regs);
   SetDirCheck := Longint(dx) shl 16 + cx;
  end;
end;

function SetTreeCheck(Dir: String): Longint; {Handle}
var
 Regs: Registers;

begin
 if CN_NT and (Length(Dir) < 254) then
  With Regs do
  begin
   Dir[Length(Dir)+1] := #0;
   ax := $170d; {}
   bx := ofs(Dir[1]);
   es := seg(Dir[1]);
   cx := 0;
   dx := 0;
   si := 3;
   Intr($2f, Regs);
   SetTreeCheck := Longint(dx) shl 16 + cx;
  end;
end;


function DirCheck(var Handle: Longint): Boolean;
var
 Regs: Registers;

begin
 if CN_NT then
  With Regs do
  begin
   ax := $170d; {}
   bx := 0;
   es := 0;
   cx := Word(Handle);
   dx := Word(Handle shr 16);
   si := 1;
   Intr($2f, Regs);
   Handle := Longint(dx) shl 16 + cx;
   DirCheck := Boolean(ax);
  end;
end;

procedure DirFree(Handle: Longint);
var
 Regs: Registers;

begin
 if CN_NT then
  With Regs do
  begin
   ax := $170d; {}
   bx := 0;
   es := 0;
   cx := Word(Handle);
   dx := Word(Handle shr 16);
   si := 2;
   Intr($2f, Regs);
  end;
end;

procedure ScrInfo(var ScrBuf);
var
 Regs: Registers;

begin
 if CN_NT then
  begin
    With Regs do
      begin
       ax := $1726; {ScrInfo}
       bx := ofs(ScrBuf);
       es := seg(ScrBuf);
       Intr($2f, Regs);
      end;
  end;
end;


function SHExec(cmd, params: String; Flag: Integer): Longint;
var
 Regs: Registers;

begin
 if CN_NT and (Length(cmd) < 254) and (Length(params) < 254) then
  With Regs do
  begin
   cmd[Length(cmd)+1] := #0;
   params[Length(params)+1] := #0;
   ax := $170e; {}
   bx := ofs(cmd[1]);
   es := seg(cmd[1]);
   cx := ofs(params[1]);
   ds := seg(params[1]);
   dx := Flag;
   Intr($2f, Regs);
   SHExec := Longint(bx) shl 16 + ax;
  end;
end;

function SysCopy(src, dest: String; Flag: Word; progress: pointer): Boolean;
var
 Regs: Registers;

begin
 if CN_NT and (Length(src) < 254) and (Length(dest) < 254) then
  With Regs do
  begin
   src[Length(src)+1] := #0;
   dest[Length(dest)+1] := #0;
   ax := $1727; {}
   bx := ofs(src[1]);
   es := seg(src[1]);
   cx := ofs(dest[1]);
   ds := seg(dest[1]);
   dx := Flag;
   bp := seg(progress^);
   si := ofs(progress^);
   Intr($2f, Regs);
   SysCopy := boolean(ax);
  end;
end;

function WinMsgBox(Text, Caption: String; Flag: Longint): Longint;
var
 Regs: Registers;

begin
 if CN_NT and (Length(Text) < 254) and (Length(Caption) < 254) then
  With Regs do
  begin
   Text[Length(Text)+1] := #0;
   Caption[Length(Caption)+1] := #0;
   ax := $1728; {}
   bx := ofs(Text[1]);
   es := seg(Text[1]);
   cx := ofs(Caption[1]);
   ds := seg(Caption[1]);
   dx := Word(Flag);
   si := Flag shr 16;
   Intr($2f, Regs);
   WinMsgBox := Longint(bx) shl 16 + ax;
  end;
end;

(*
 *
 * CommFunc
 *
 * Arguments:
 *     Client(DX)    = Address / command code

    0xBBCC

     high byte : "BB" : NT port base (8 for COM8 etc) (used in OPEN only)
     Low byte: : "CC" : Command

    Commands:

    0 : INIT    DH = Port (1 - Com1, 2 - Com2)
                DL = 0
                CX = baud rate
                BL & 0x0f = bits (5, 6, 7, 8)
                BL & 0xf0 = stops (1 - , 2 - 1.5, 3 - 2)
                BH & 0x0f = parity (0 - none, 1 - even, 2 - odd)

    1 : READ    DH = Port (1 - Com1, 2 - Com2)
                DL = 1
                CX = number of chars to read
                ES:SI = buffer
                return : CX = actual read

    2 : WRITE   DH = Port (1 - Com1, 2 - Com2)
                DL = 2
                CX = number of chars to write
                ES:SI = buffer
                return : CX = actual written

    3 : CLOSE   DH = Port (1 - Com1, 2 - Com2)
                DL = 3

    4 : MDM_CTL DH = Port (1 - Com1, 2 - Com2)
                DL = 4
                CX = EscapeCommFunction signal code

 * Return Value:
 *     Client Carry Clear:  SUCCESS  AX = 0
 *     Client Carry Set:    FAILURE, AX = reason
 *
 *)

function CommOpen(Comm: Byte; Baud: Word; Bits: Byte;
                  Parity: Char; Stop: Byte): Boolean;
var
 Regs: Registers;

begin
 if CN_NT then
  With Regs do
  begin
   ax := $170c;
   cx := Baud;
   dh := Comm;
   dl := 0;
   bl := Bits + 16 * Stop;
   case Parity of
    'N', 'n' : bh := 0;
    'E', 'e' : bh := 1;
    'O', 'o' : bh := 2;
   end;
   Intr($2f, Regs);
   CommOpen := boolean(ax = 0);
  end;
end;

function ReadBuf(Comm: Word; var Buf; Count: Word): Word;
var
 Regs: Registers;

begin
 if CN_NT then
  With Regs do
  begin
   ax := $170c;
   si := ofs(Buf);
   es := seg(Buf);
   cx := Count;
   dh := Comm;
   dl := 1;
   Intr($2f, Regs);
   ReadBuf := cx;
  end;
end;

function WriteBuf(Comm: Word; var Buf; Count: Word): Word;
var
 Regs: Registers;

begin
 if CN_NT then
  With Regs do
  begin
   ax := $170c;
   si := ofs(Buf);
   es := seg(Buf);
   cx := Count;
   dh := Comm;
   dl := 2;
   Intr($2f, Regs);
   WriteBuf := cx;
  end;
end;

function CommClose(Comm: Word): Boolean;
var
 Regs: Registers;

begin
 if CN_NT then
  With Regs do
  begin
   ax := $170c;
   dh := Comm;
   dl := 3;
   Intr($2f, Regs);
   CommClose := boolean(ax = 0);
  end;
end;

function CommCTL(Comm, CTL: Word): Boolean;
var
 Regs: Registers;

begin
 if CN_NT then
  With Regs do
  begin
   ax := $170c;
   cx := CTL;
   dh := Comm;
   dl := 4;
   Intr($2f, Regs);
   CommCTL := boolean(ax = 0);
  end;
end;

end.