Uses int2f;
var
 DriveType: Word;
 Drives: Longint;
 SectorsPerCluster: Longint;
 BytesPerSector: Longint;
 NumberOfFreeClusters: Longint;
 TotalNumberOfClusters: Longint;

function Size2str(Size: Real): String;
var
 S: String;
 c: Char;
begin
 if Size > 1073741824.0 then
  begin
   Size := Size / 1073741824.0;
   c := 'G';
  end
 else
 if Size > 1048576.0 then
  begin
   Size := Size / 1048576.0;
   c := 'M';
  end
 else
 if Size > 1024.0 then
  begin
   Size := Size / 1024.0;
   c := 'K';
  end
 else c := 'B';

 Str(Size:4:4, S);
 Size2str := S+c;
end;

function DriveString: String;
 var
  S: String[32];
  D, M: Longint;
  i: Char;
  j: Byte;
begin
 M := 1;
 D := GetLogicalDrives;
 j := 1;
 for i := 'A' to 'Z' do
  begin
   if (D and M) <> 0 then
    begin
     S[0] := chr(j);
     S[j] := i;
     inc(j);
    end;
   M := M shl 1;
  end;
 DriveString := S;
end;


begin
 Inst_CN_NT;
 GetFreeDiskSize(ParamStr(1),
                 SectorsPerCluster,
                 BytesPerSector,
                 NumberOfFreeClusters,
                 TotalNumberOfClusters);

 WriteLn('SectorsPerCluster = ', SectorsPerCluster, #13#10,
         'BytesPerSector = ', BytesPerSector, #13#10,
         'NumberOfFreeClusters = ', NumberOfFreeClusters, #13#10,
         'TotalNumberOfClusters = ', TotalNumberOfClusters, #13#10,
         'Size = ', Size2str((1.0*SectorsPerCluster) * BytesPerSector * TotalNumberOfClusters), #13#10,
         'Free = ', Size2str((1.0*SectorsPerCluster) * BytesPerSector * NumberOfFreeClusters), #13#10,
         'DriveType = ', GetDriveType(ParamStr(1)), #13#10,
         'LogicalDrives = ', GetLogicalDrives, #13#10,
         DriveString);

end.