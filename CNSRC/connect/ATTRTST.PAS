Uses DOS, int2f, Strings, TPString;

type
  lAPIType = (lDOS, lWIN95, lOS2);

  lSearchRec = record
    SR: SearchRec;
    {Attr:Word;}
    FileHandle: Word;
    FullName: String;
    FindFirstMode: lAPIType;
    { Other fields will be added later }
  end;

  TNameZ = Array[0..259] of Char;

  lFile = record
    F: File;
    FullName: TNameZ;
    AssignFileMode: lAPIType;
    { Other fields will be added later }
  end;

  lText = record
    T: Text;
    FullName: TNameZ;
    AssignTextMode: lAPIType;
    { Other fields will be added later }
  end;

  lCompareType = (lLess, lEqual, lGreater);



type
  lFindDataRec = record
    LoAttr: Word;
    HiAttr: Word;
    LoCreationTime: Longint;
    HiCreationTime: Longint;
    LoLastAccessTime: Longint;
    HiLastAccessTime: Longint;
    LoLastModificationTime: Longint;
    HiLastModificationTime: Longint;
    HiSize: Longint;
    LoSize: Longint;
    Reserved: Array[0..7] of Byte;
    FullName: TNameZ;
    ShortName: Array[0..13] of Char;
  end;


procedure NameToNameZ(const Name: String; var NameZ: TNameZ);
begin
  Move(Name[1], NameZ, Length(Name));
  NameZ[Length(Name)] := #0;
end;


procedure FindDataToSearchRec(var FindData: lFindDataRec; var R: lSearchRec);
begin
  R.SR.Attr := FindData.LoAttr;
  {R.Attr := FindData.LoAttr;}
  R.SR.Time := FindData.LoLastModificationTime;
  R.SR.Size := FindData.LoSize;
  R.SR.Name := StrPas(FindData.ShortName);
  R.FullName := StrPas(FindData.FullName);
  if R.SR.Name = '' then
  begin
    R.SR.Name := R.FullName;
    R.FullName := '';
  end;
end;


procedure lWIN95FindFirst(const Path: String; Attr: Word; var R: lSearchRec);
var
  I: Integer;
  Regs: Registers;
  FindData: lFindDataRec;
begin
  NameToNameZ(Path, FindData.FullName);
  with Regs do
  begin
    AX := $714E;
    CX := Attr;
    SI := 1;
    DS := Seg(FindData.FullName);
    DX := Ofs(FindData.FullName);
    ES := Seg(FindData);
    DI := Ofs(FindData);
    asm
     stc
    end;
    Intr($21, Regs);
    if Flags and fCarry <> 0 then
    begin
      R.FileHandle := $FFFF;
      DosError := AX;
    end
    else
    begin
      R.FileHandle := AX;
      FindDataToSearchRec(FindData, R);
      DosError := 0;
    end;
  end;
end;

(*
 INT 21h  AX=714F
 INT 21 - Windows95 - LONG FILENAME - FIND NEXT MATCHING FILE
         AX = 714Fh
         BX = filefind handle (from AX=714Eh)
         SI = date/time format
         ES:DI -> buffer for FindData record
 Return: CF clear if successful
             CX = Unicode conversion flags
         CF set on error
             AX = error code
                 7100h if function not supported
 Note:   this function is only available when IFSMgr is running,
         not under bare MS-DOS 7
*)

procedure lWIN95FindNext(var R: lSearchRec);
var
  Regs: Registers;
  FindData: lFindDataRec;
begin
  with Regs do
  begin
    AX := $714F;
    BX := R.FileHandle;
    SI := 1;
    ES := Seg(FindData);
    DI := Ofs(FindData);
    asm
     stc
    end;
    Intr($21, Regs);
    if Flags and fCarry <> 0 then DosError := AX
    else
    begin
      FindDataToSearchRec(FindData, R);
      DosError := 0;
    end;
  end;
end;

(*
 INT 21h  AX=71A1
 INT 21 - Windows95 - LONG FILENAME - "FindClose" -
          TERMINATE DIRECTORY SEARCH
         AX = 71A1h
         BX = filefind handle (from AX=714Eh)
 Return: CF clear if successful
         CF set on error
            AX = error code
                 7100h if function not supported
 Notes:  this function must be called after starting a search
         with AX=714Eh, to indicate that the search handle
         returned by that function will no longer be used
         this function is only available when IFSMgr is running,
         not under bare MS-DOS 7
*)

procedure lWIN95FindClose(var R: lSearchRec);
var
  Regs: Registers;
begin
  if R.FileHandle <> $FFFF then with Regs do
  begin
    AX := $71A1;
    BX := R.FileHandle;
    Intr($21, Regs);
  end;
end;

var
 Attr: Word;
 R: lSearchRec;
begin
 Attr := SizeOf(R);
 Attr := $ff;
 lWIN95FindFirst(ParamStr(1), Attr, R);

 While DosError = 0 do
  begin
   lWIN95FindNext(R);
   WriteLn(R.SR.Name, ' '{, HexW(R.Attr)});
  end;

 lWIN95FindClose(R);

end.