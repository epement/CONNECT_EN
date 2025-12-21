Uses DOS;

const
 DRIVE_UNKNOWN   = 0;  {The drive type cannot be determined.}
 DRIVE_INVALID   = 1;  {The root directory does not exist.}
 DRIVE_REMOVABLE = 2;  {The drive can be removed from the drive.}
 DRIVE_FIXED     = 3;  {The disk cannot be removed from the drive.}
 DRIVE_REMOTE    = 4;  {The drive is a remote (network) drive.}
 DRIVE_CDROM     = 5;  {The drive is a CD-ROM drive.}
 DRIVE_RAMDISK   = 6;  {The drive is a RAM disk.}


const
 Magic = $1117;
 CN_NT: Boolean = False;

var
 DriveType: Word;
 Drives: Longint;
 SectorsPerCluster: Word;
 BytesPerSector: Word;
 NumberOfFreeClusters: Longint;
 TotalNumberOfClusters: Longint;

function Inst_CN_NT: Boolean;
var
 Regs: Registers;
begin
 Regs.ax := $1710;  {inst check}
 Intr($2f, Regs);
 CN_NT := Regs.ax = Magic;
 Inst_CN_NT := CN_NT;
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
                          var SectorsPerCluster: Word;
                          var BytesPerSector: Word;
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
    begin
     PathName[Length(PathName)+1] := #0;
     Regs.ax := $1711; {GetFreeDIskSize}
     Regs.bx := ofs(PathName[1]);
     Regs.es := seg(PathName[1]);
     Intr($2f, Regs);
     SectorsPerCluster := Regs.ax;
     BytesPerSector := Regs.bx;
     NumberOfFreeClusters := longint(Regs.dx) shl 16 +Regs.cx;
     TotalNumberOfClusters := longint(Regs.si) shl 16 +Regs.bp;
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
    begin
     PathName[Length(PathName)+1] := #0;
     Regs.ax := $1712;  {GetDriveType}
     Regs.bx := ofs(PathName[1]);
     Regs.es := seg(PathName[1]);
     Intr($2f, Regs);
    end;
  end;
 GetDriveType := Regs.ax;
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
  begin
   Regs.ax := $1713; {GetLogicalDrives}
   Intr($2f, Regs);
  end;
 GetLogicalDrives := Longint(Regs.bx) shl 16 + Regs.ax;
end;

begin
 Inst_CN_NT;
 GetFreeDiskSize('C:',
                  SectorsPerCluster,
                  BytesPerSector,
                  NumberOfFreeClusters,
                  TotalNumberOfClusters);

 WriteLn(SectorsPerCluster, #13#10,
         BytesPerSector, #13#10,
         NumberOfFreeClusters, #13#10,
         TotalNumberOfClusters, #13#10,
         GetDriveType('C:'), #13#10,
         GetLogicalDrives);

end.