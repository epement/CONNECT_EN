uses CDCtl;

var
  Drive: Byte;
begin
  CDGetDriveLetterList;
  CDGetDriveDeviceList;
  Drive := CDDriveLetterList[0];
  if not CDDriveCheck(Drive) then Writeln(
    'CD-ROM drive ' + Char(Drive + $41) + ': not accessible.')
  else CDPlayAudio(Drive, 0, MaxLongint);
end.
