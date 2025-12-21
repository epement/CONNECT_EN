 (* Get a disk's volume label *)
  function GETLABFN (device : char) : string;
  var FileInfo : SearchRec;
      fsplit_dir  : DirStr;
      fsplit_name : NameStr;
      fsplit_ext  : ExtStr;
      stash       : byte;
  begin
    getlabfn := '';
    device := UpCase (device);
    if (device < 'A') or (device > 'Z') then exit;
    {}
    stash := fileMode;
    FileMode := $40;
    FindFirst (device + ':\*.*', AnyFile, FileInfo);
    while DosError = 0 do
      begin
        if ((FileInfo.Attr and VolumeId) > 0) then
          begin
            FSplit (FExpand(FileInfo.Name),
                    fsplit_dir, fsplit_name, fsplit_ext);
            Delete (fsplit_ext, 1, 1);
            getlabfn := fsplit_name + fsplit_ext;
            FileMode := stash;
            exit;
          end;
        FindNext (FileInfo);
      end; {while}
    FileMode := stash;
  end; (* getlabfn *)