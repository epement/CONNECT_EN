{$I-,X+,F+,O+}
unit DiskPrim;

interface

uses Dos, Objects, Views, DiskBase, Tags, RegExp;

type
  PSearchRec = ^SearchRec;

const
  dsOverwrite = cmYes;
  dsDelete = cmYes;
  dsAll = cmOk;
  dsAppend = cmAppend;
  dsAppendAll = cmAppendAll;
  dsResume = cmResume;
  dsResumeAll = cmResumeAll;
  dsNew = cmNew;
  dsSkip = cmNo;
  dsSkipAll = cmDefault;
  dsCancel = cmCancel;
  dsReadError = cmError;
{ Added 04-12-03 to support disk operation error dialog }
  deRetry = cmYes;
  deIgnore = cmNo;
  deIgnoreAll = cmDefault;
  deCancel = cmCancel;

  AppendAllSet = [dsAppend, dsAppendAll];
  ResumeAllSet = [dsResume, dsResumeAll];
  AppendResumeSet = [dsAppend, dsResume];
  AppendResumeAllSet = [dsAppend, dsAppendAll, dsResume, dsResumeAll];
  AppendResumeSkipAllSet = [dsAppend, dsAppendAll, dsResume, dsResumeAll, dsSkipAll];

  DirFilter: String[12] = '*.*';
  NewMask: String[12] = '*.*';

  LastDiskName: FNameStr = '';
  LastRenMovName: FNameStr = '';
  CheckRenMovName: Boolean = False;

{ Added 04.17.03 to support directory recursive copy/move }
  DirCRCList: PTagList = nil;
  DirCRCListInUse: Boolean = False;

{ Added 05-12-03 to support file splitting }
  SplitCopy: Boolean = False;
  SplitTruncate: Boolean = False;

{ Added 2005.08.30 to support regexp file operations }
  FileRegExp: PRegExp = nil;
  FileRegExpStr1: PString = nil;
  FileRegExpStr2: PString = nil;

{ Added 2005.09.29 to avoid loops copying with regexps }
  FileCRCList: PTagList = nil;

var
  CopyStatus, DeleteStatus, CopyErrorStatus, DeleteErrorStatus: Byte;
  Skipped, CopyOk, CopyLeft, TryAll: Boolean;
  FilesTotal, FilesCopied: Longint;
  BytesTotal, BytesCopied: Real;
{ Added 05-12-03 to support file splitting }
  SplitSize: Longint;
{ Added 20-01-04 to support # in split specification }
  SplitNumber: Longint;
{ Added 2005.09.29 to support regexp file operations }
  FileRegExpInitDirLen: Byte;

function FoundInCRCList(const Name: FNameStr; ACRCList: PTagList): Boolean;
function NT_GetFTime(fName: String; var fTime: Longint; tTime: Byte): Boolean;
procedure FSetAttrPrim(const AName: FNameStr; Attr: Word;
  Time, Time1, Time2: Longint);
procedure SetAttrDirFiles(const ADir: FNameStr;
  Attr: Word; Time, Time1, Time2: Longint; ACRCList: PTagList);
procedure DirSetAttr(const ADir: FNameStr;
  Attr: Word; Time, Time1, Time2: Longint; ACRCList: PTagList);
procedure FDeletePrim(const AName: FNameStr);
procedure DirRemovePrim(const ADir: FNameStr);
procedure ClearDirFiles(const ADir, AMask: FNameStr;
  ACRCList: PTagList);
procedure ClearDirs(const ADir: FNameStr;
  ACRCList: PTagList; All, EmptyOnly: Boolean);
procedure DirDeletePrim(const ADir: FNameStr;
  ACRCList: PTagList; All, EmptyOnly: Boolean);
procedure DeleteFilesByMask(const ADir, AMask: FNameStr;
  ACRCList: PTagList);
function MkDirPrim(const ADir: FNameStr;
  SearchRecPtr: PSearchRec): FNameStr;
function FCopyPrim(const FromName, ToName: FNameStr): FNameStr;
procedure ResetTotals;
procedure DirCountPrim(const ADir, AFilter: FNameStr;
  ACRCList: PTagList);
procedure CopyDirFiles(const FromDir, ToDir, ADir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
procedure CopyDirs(const FromDir, ToDir, ADir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
procedure DirCopyPrim(const FromDir, ToDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
procedure DirCopyFiles(const FromDir, ToDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
procedure CopyFilesByMask(const FromDir, ToDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
function FRenMovPrim(const FromName, ToName: FNameStr): FNameStr;
procedure RenMovDirFiles(const FromDir, ToDir, ADir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
procedure RenMovDirs(const FromDir, ToDir, ADir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
procedure DirRenameFiles(const ADir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
procedure RenameFilesByMask(const ADir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
procedure DirMoveFiles(const FromDir, ToDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
procedure MoveFilesByMask(const FromDir, ToDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
procedure DirRenMovPrim(const FromDir, DestDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList;
  DoRemove: Boolean);
function GetDirInfo(const ADir: FNameStr;
  var NumFiles, NumTagged, NumSubDirs: Longint;
  var FilesSize, NumBytes, TaggedSize, TaggedBytes,
  Compressed, TaggedCompressed: Real;
  CalcTagged, AllowTree, KeyAbort: Boolean): Boolean;

implementation

uses CNCrt, Memory, Drivers, Strings, Dialogs, MsgBox, App, Gauges, Spooler,
  DirPrim, PanelRec, BBSStuff, DirTree, Trees, FMAbort, UnixMask, HeapUMB,
  Keyboard, Disks, LFN, DosTools, Timer, RevPos, TPString, Commands, Consts,
  Defaults;

var
  MoveCopy: Boolean;

function AbortDiskAction: Boolean;
begin
  AbortDiskAction := ((KbdStatus = 1) or (KbdHead <> KbdTail)) and
    FMAbortAction;
end;

procedure DrawStatus(const AName: FNameStr);
begin
  LogEvent := lcDiskRead;
  DrawStatusLine(Concat('Scanning the directory ',
    TrimmedName(ClearedSlash(AName), 45)));
end;

procedure DrawSkipStatus(const AName: FNameStr);
begin
  DrawStatusLine(Concat('Skipping ', TrimmedName(AName, 58), '.'));
end;

procedure UpdateStatistics;
begin
  if CopyStatWindow <> nil then CopyStatWindow^.UpdateSubViews;
end;

procedure SkipFile(const AName: FNameStr; Size: Real; Copied: Longint);
begin
  DrawSkipStatus(AName);
  if BytesTotal >= Size then BytesTotal := BytesTotal - Size
  else BytesTotal := 0;
  if BytesCopied >= Copied then BytesCopied := BytesCopied - Copied
  else BytesCopied := 0;
  if FilesTotal > 0 then Dec(FilesTotal);
  UpdateStatistics;
end;

procedure AddNameAndSlash(const ADir, AName: FNameStr; DoAddSlash: Boolean;
  var S: FNameStr);
begin
  S := ADir + AName;
  if DoAddSlash then S := S + '\';
end;

function ShortFileName(const Name: String): String;
var
  S: String;
begin
  lGetShortFileName(Name, S);
  ShortFileName := S;
end;

{ Added 04.17.03 to support directory recursive copy/move }
procedure AddDirCRCItem(const S: String);
begin
  if DirCRCList = nil then DirCRCList := New(PTagList, Init(16, 16));
  DirCRCList^.InsertName(AddedSlash(S));
end;

{ Added 2005.09.29 to avoid loops copying with regexps }
procedure AddFileCRCItem(const S: String);
begin
  if FileCRCList = nil then FileCRCList := New(PTagList, Init(16, 16));
  FileCRCList^.InsertName(S);
end;

function DirWithin(const FromDir, ToDir: FNameStr;
  var EndSlash: Boolean): Boolean;
var
  FromName, ToName: FNameStr;
begin
  EndSlash := (Length(ToDir) > Length(FromDir)) and
    (ToDir[Length(FromDir) + 1] = '\');
  if DeviceDest(ToDir) <> '' then
    DirWithin := False
  else if UCPos(AddedSlash(FromDir), AddedSlash(ToDir)) <> 0 then
    DirWithin := True
  else
  begin
    lTrueName(FromDir, FromName);
    lTrueName(ToDir, ToName);
    EndSlash := (Length(ToName) > Length(FromName)) and
      (ToName[Length(FromName) + 1] = '\');
    DirWithin := UCPos(AddedSlash(FromName), AddedSlash(ToName)) <> 0;
  end;
end;

function SameDrives(const Name1, Name2: FNameStr): Boolean;
var
  B, C: Byte;
begin
  if TPString.Upcase(Name1[1]) <> TPString.Upcase(Name2[1]) then
    SameDrives := False
  else if Name1[1] = '\' then
  begin
    C := 0;
    B := 1;
    while (B < Length(Name1)) and (B < Length(Name2)) do
    begin
      if TPString.Upcase(Name1[B]) <> TPString.Upcase(Name2[B]) then Break;
      if Name1[B] = '\' then Inc(C);
      if C = 4 then
      begin
        SameDrives := True;
        Exit;
      end;
      Inc(B);
    end;
    SameDrives := False;
  end
  else SameDrives := True;
end;

procedure SendChangeMsg(const Name: FNameStr);
var
  S1, S2: FNameStr;
begin
  if FMAutoRereadOptions <> faModifiedOnly then Exit;
  S1 := Name;
  while (S1 <> '') and (S1[Length(S1)] <> '\') do Dec(S1[0]);
  if S1 <> '' then Dec(S1[0]);
  if CheckRenMovName then S2 := LastRenMovName
  else S2 := LastDiskName;
  while (S2 <> '') and (S2[Length(S2)] <> '\') do Dec(S2[0]);
  if S2 <> '' then Dec(S2[0]);
  if CompUCString(S1, S2) = Equal then Exit;
  Message(Desktop, evBroadcast, cmDiskChanged, @Name);
  if CheckRenMovName then LastRenMovName := Name
  else LastDiskName := Name;
end;

function FoundInCRCList(const Name: FNameStr; ACRCList: PTagList): Boolean;
begin
  if ACRCList = nil then FoundInCRCList := True
  else FoundInCRCList := ACRCList^.NameFound(Name);
end;

{ Added 2005.08.30 to support regexp file operations }
function FileNameMatchesRegExp(const AName: String): Boolean;
var
  I, L: Integer;
  A: Array[0..255] of Char;
begin
  I := RPos('\', AName);
  L := Length(AName) - I;
  Move(AName[I + 1], A[0], L);
  A[L] := #0;
  StrUpper(A);
  FileNameMatchesRegExp := RegExec(FileRegExp, A) <> 0;
end;

function FileRegExpNewName(const AName: String): String;
var
  I, L: Integer;
  A: Array[0..255] of Char;
  S: String;
begin
  FileRegExpNewName := '';
  I := RPos('\', AName);
  L := Length(AName) - I;
  Move(AName[I + 1], A[0], L);
  A[L] := #0;
  StrUpper(A);
  if RegExec(FileRegExp, A) <> 0 then
  begin
    Move(AName[I + 1], A[0], L);
    regsub(FileRegExp, FileRegExpStr2^, S);
    if (Length(FileRegExpStr2^) > 1) and
       (((FileRegExpStr2^[1] in ['A'..'Z', 'a'..'z']) and
         (FileRegExpStr2^[2] = ':')) or
        ((FileRegExpStr2^[1] = '\') and (FileRegExpStr2^[2] = '\'))) then
    begin
      if (FileRegExpInitDirLen <> 0) and (I > FileRegExpInitDirLen) then
        FileRegExpNewName := Concat(AddedSlash(JustPathName(S)),
          Copy(AName, FileRegExpInitDirLen + 1, I - FileRegExpInitDirLen),
            JustFileName(S))
      else FileRegExpNewName := S
    end
    else FileRegExpNewName := Concat(Copy(AName, 1, I), S);
  end;
end;

function CopyRenameFilterPassed(var SR: SearchRec;
  const ALongName: FNameStr): Boolean;
begin
{ Added 2005.08.30 to support regexp file operations }
  if (FileRegExp <> nil) and not FileNameMatchesRegExp(ALongName) then
    CopyRenameFilterPassed := False
  else if CopyRenameFilter.Text = nil then CopyRenameFilterPassed := True
  else
  begin
    if CopyRenameFilter.Unix and (CopyRenameStates = nil) then
    begin
{      GetMem(CopyRenameStates, SizeOf(TState));}
      GetMemUMB(CopyRenameStates, SizeOf(TState));
      MakeAutomaton(CopyRenameFilter.Text^, PState(CopyRenameStates)^);
    end;
    CopyRenameFilterPassed := AdvancedFilterPassed(
      @CopyRenameFilter, CopyRenameStates, SR, ALongName);
  end;
end;

{ Added 2005.09.16 to support prompt before file operation }
type
  TFileAction = (faCopy, faRenMov, faMkDir, faDel);

function FileOperationConfirmed(const FromName: String;
  var ToName: String; Action: TFileAction): Boolean;
var
  B: Byte;
  C: Word;
  D: PDialog;
  R: TRect;
  S: String[20];
begin
  if Action = faDel then C := MessageBox(^C'Delete the file'#13^C'|' +
    FromName + '| ?', nil, mfConfirmation + mfYesAllNoCancel)
  else
  begin
    B := 2;
    R.Assign(0, 0, 70, 8);
    if Action = faMkDir then
    begin
      S := 'Create new directory';
      D := InitCopyDialog(R, S, Boolean(B), False);
    end
    else if Action = faRenMov then
    begin
      S := 'Rename or move';
      D := InitRenMovDialog(R, S + ' "' + TrimmedName(
        FromName, 43) + '" to', Boolean(B), False);
    end
    else
    begin
      S := 'Copy';
      D := InitCopyDialog(R, S + ' "' + TrimmedName(
        FromName, 53) + '" to', Boolean(B), False);
    end;
{   S := D^.Title^;}
    DisposeStr(D^.Title);
    D^.Title := NewStr(S + ' confirmation');
    C := Application^.ExecuteDialog(D, @ToName, True);
  end;
  if C = cmOk then FileCopyOptions :=
    FileCopyOptions and not fsConfirmFileOperation;
  if C = cmCancel then CopyStatus := dsCancel;
  FileOperationConfirmed := (C = cmYes) or (C = cmOk);
end;

function OptUpcaseDir(const FromDir, ToDir: FNameStr): FNameStr;
begin
  if CompUCString(JustFileName(FromDir), JustFileName(ToDir)) = Equal then
    OptUpcaseDir := StUpcase(AddedSlash(JustPathName(ToDir))) +
      JustFileName(ToDir)
  else OptUpcaseDir := StUpcase(ToDir);
end;

procedure Find1st(const AName: FNameStr;
  var Attr: Word; var Size, Time: Longint);
var
  SR: ^lSearchRec;
begin
  GetMem(SR, SizeOf(lSearchRec));
  lFindFirst(AName, AnyFile and not (VolumeID + Directory), SR^);
  lFindClose(SR^);
  Attr := SR^.SR.Attr;
  Size := SR^.SR.Size;
  Time := SR^.SR.Time;
  FreeMem(SR, SizeOf(lSearchRec));
end;

{ Added 2006.01.02 }
(*
function NT_GetFAttr(fName: String): Longint;
var
  Regs: Registers;
begin
  NT_GetFAttr := 0;
  if Length(fName) < 254 then with Regs do
  begin
    fName[Length(fName)+1] := #0;
    ax := $1723; {}
    bx := ofs(fName[1]);
    es := seg(fName[1]);
    Intr($2f, Regs);
    NT_GetFAttr := longint(bx) shl 16 + ax;
  end;
end;
*)

function NT_SetFAttr(fName: String; fAttr: Longint): Boolean;
var
  Regs: Registers;
  Res: Boolean;
begin
  Res := False;
  if Length(fName) < 254 then with Regs do
  begin
    fName[Length(fName)+1] := #0;
    ax := $1722; {}
    bx := ofs(fName[1]);
    es := seg(fName[1]);
    cx := Word(fAttr);
    dx := fAttr shr 16;
    Intr($2f, Regs);
    Res := Boolean(ax);
  end;
  NT_SetFAttr := Res;
end;

function NT_GetFTime(fName: String; var fTime: Longint; tTime: Byte): Boolean;
type
  tFileTime = record
    fTimeLow, fTimeHigh: Longint;
  end;
var
  fTimeLowHigh: tFileTime;
  Regs: Registers;
  Res: Boolean;
begin
  Res := False;
  if Length(fName) < 254 then with Regs, fTimeLowHigh do
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
  NT_GetFTime := Res;
end;

function NT_SetFTime(fName: String; fTime: Longint; tTime: Byte): Boolean;
type
  tFileTime = record
    fTimeLow, fTimeHigh: Longint;
  end;
  LongRec = record
    Lo, Hi: Word;
  end;
var
  T: Longint;
  fTimeLowHigh: tFileTime;
  Regs: Registers;
  Res: Boolean;
begin
  Res := False;

  if (LongRec(fTime).Lo = $FFFF) or (LongRec(fTime).Hi = $FFFF) then
  begin
    if NT_GetFTime(fName, T, tTime) then
    begin
      if LongRec(fTime).Lo = $FFFF then LongRec(fTime).Lo := LongRec(T).Lo;
      if LongRec(fTime).Hi = $FFFF then LongRec(fTime).Hi := LongRec(T).Hi;
    end;
  end;

  if Length(fName) < 254 then with Regs, fTimeLowHigh do
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
  NT_SetFTime := Res;
end;

procedure FSetAttrPrim(const AName: FNameStr; Attr: Word;
  Time, Time1, Time2: Longint);
var
  B: Boolean;
  T: Longint;
  F: ^lFile;
label
  Retry;
begin
  LogEvent := lcDiskWrite;
  DrawStatusLine('Setting new attributes for ' +
    TrimmedName(AName, 43) + '.');
  GetMem(F, SizeOf(lFile));
  lAssignFile(F^, AName);
  if CN_NT then
  begin
    if Time <> -1 then NT_SetFTime(AName, Time, 2);
    if Time1 <> -1 then NT_SetFTime(AName, Time1, 1);
    if Time2 <> -1 then NT_SetFTime(AName, Time2, 0);
  end
  else if Time <> -1 then
  begin
    lResetFile(F^, 1);
    if IOResult = 0 then
    begin
      if (LongRec(Time).Lo = $FFFF) or (LongRec(Time).Hi = $FFFF) then
      begin
        GetFTime(F^.F, T);
        if LongRec(Time).Lo = $FFFF then LongRec(Time).Lo := LongRec(T).Lo;
        if LongRec(Time).Hi = $FFFF then LongRec(Time).Hi := LongRec(T).Hi;
      end;
      SetFTime(F^.F, Time);
      Close(F^.F);
    end;
  end;

  Attr := Attr and not Directory;
Retry:
  if CN_NT then
  begin
    T := Attr;
    B := NT_SetFAttr(AName, T);
  end
  else
  begin
    lSetFAttr(F^, Attr);
    B := DosError = 0;
  end;
  if not B then
  begin
    if CopyErrorStatus <> deIgnoreAll then
      CopyErrorStatus := DiskErrorDialog('Set attributes',
        ^C'Could not set the attributes for'#13^C + TrimmedName(AName, 62) + '.');
    if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(AName)
    else if CopyErrorStatus = deCancel then CopyStatus := dsCancel
    else goto Retry;
  end
  else SendChangeMsg(AName);
  FreeMem(F, SizeOf(lFile));
end;

procedure SetAttrDirFiles(const ADir: FNameStr;
  Attr: Word; Time, Time1, Time2: Longint; ACRCList: PTagList);
var
  SR: ^lSearchRec;
  S: PString;
begin
  CancelSysErrors := False;
  GetMem(S, SizeOf(String));
  GetMem(SR, SizeOf(lSearchRec));
  lFindFirst(ADir + '*.*', AnyFile and not VolumeID, SR^);
  if CancelSysErrors then CopyStatus := dsCancel;
  while (DosError = 0) and (CopyStatus <> dsCancel) do
  begin
    if SR^.SR.Attr and (VolumeID + Directory) = 0 then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(ADir, SR^.FullName, False, S^)
      else AddNameAndSlash(ADir, SR^.SR.Name, False, S^);
      if FoundInCRCList(S^, ACRCList) then
        FSetAttrPrim(S^, Attr, Time, Time1, Time2);
    end;
    if (KbdStatus = 1) and FMAbortAction then CopyStatus := dsCancel
    else lFindNext(SR^);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  FreeMem(S, SizeOf(String));
end;

procedure DirSetAttr(const ADir: FNameStr;
  Attr: Word; Time, Time1, Time2: Longint; ACRCList: PTagList);
var
  S: PString;

procedure DoSetAttr(ADir: PString);
var
  SR: ^lSearchRec;
  Dir: PString;
begin
  if StackOverflow then
  begin
    CopyStatus := dsCancel;
    Exit;
  end;
  Dir := NewStr(ADir^);
  GetMem(SR, SizeOf(lSearchRec));
  SetAttrDirFiles(Dir^, Attr, Time, Time1, Time2, ACRCList);
  if CopyStatus = dsCancel then Exit;
  AddNameAndSlash(Dir^, '*.*', False, S^);
  CancelSysErrors := False;
  lFindFirst(S^, $17, SR^);
  if CancelSysErrors then CopyStatus := dsCancel;
  while (DosError = 0) and (CopyStatus <> dsCancel) do
  begin
    if (SR^.SR.Attr and Directory <> 0) and
       (SR^.SR.Name[1] <> '.') then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(Dir^, SR^.FullName, True, S^)
      else AddNameAndSlash(Dir^, SR^.SR.Name, True, S^);
{ Added 2006.01.03 }
      FSetAttrPrim(S^, Attr, Time, Time1, Time2);
      DoSetAttr(S);
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  GetMem(S, SizeOf(String));
  DoSetAttr(@ADir);
  FreeMem(S, SizeOf(String));
end;

{ Added 2005.12.30 }
function NT_DelToTrash(Name: String): Boolean;
var
 Regs: Registers;
begin
  NT_DelToTrash := False;
  if Length(Name) < 254 then with Regs do
  begin
    Name[Length(Name)+1] := #0;
    Name[Length(Name)+2] := #0;
    ax := $1716; {Del_Trash}
    bx := ofs(Name[1]);
    es := seg(Name[1]);
    Intr($2f, Regs);
    NT_DelToTrash := boolean(ax);
  end;
end;

procedure FDeletePrim(const AName: FNameStr);
var
  B: Boolean;
  Attr: Word;
  ShortName: PString;
  F: ^lFile;
label
  Find, Retry, Quit;
begin
  GetMem(ShortName, SizeOf(String));
  GetMem(F, SizeOf(lFile));
  if DeleteStatus = dsSkip then DeleteStatus := dsDelete;
  lAssignFile(F^, AName);
Find:
  lGetFAttr(F^, Attr);
  if DosError <> 0 then
  begin
    if DeleteErrorStatus <> deIgnoreAll then
      DeleteErrorStatus := DiskErrorDialog('Delete',
        ^C'Could not find the file'#13^C + TrimmedName(AName, 62) + '.');
    if DeleteErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(AName)
    else if DeleteErrorStatus = deCancel then DeleteStatus := dsCancel
    else goto Find;
    goto Quit;
  end;
  if FMOptions and foCopyDescriptions <> 0 then
    lGetShortFileName(AName, ShortName^);
{ Added 2005.09.16 to support prompt before file operation }
  if (FileCopyOptions and fsConfirmFileOperation <> 0) and
    not FileOperationConfirmed(AName, ShortName^, faDel) then goto Quit;
  if Attr and (ReadOnly + Hidden + SysFile) <> 0 then
  begin
    if DeleteStatus <> dsAll then
    begin
      if DeleteStatus <> dsSkipAll then
        DeleteStatus := DelSkipDialog(AName, 'file');
      if DeleteStatus in [dsSkip, dsSkipAll, dsCancel] then
      begin
        DrawSkipStatus(AName);
        Goto Quit;
      end;
    end;
    lSetFAttr(F^, Archive);
    InOutRes := 0;
    SendChangeMsg(AName);
  end;
  LogEvent := lcDiskWrite;
  DrawStatusLine('Deleting the file ' + TrimmedName(AName, 45) + '.');
Retry:
{ Added 2005.12.30 }
  if CN_NT and (FileCopyOptions and fsDelToTrash <> 0) then
    B := NT_DelToTrash(AName)
  else
  begin
    lEraseFile(F^);
    B := IOResult = 0;
  end;
  if not B then
  begin
    if DeleteErrorStatus <> deIgnoreAll then
      DeleteErrorStatus := DiskErrorDialog('Delete',
        ^C'Could not delete the file'#13^C + TrimmedName(AName, 62) + '.');
    if DeleteErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(AName)
    else if DeleteErrorStatus = deCancel then DeleteStatus := dsCancel
    else goto Retry;
  end
  else
  begin
    SendChangeMsg(AName);
    if FMOptions and foCopyDescriptions <> 0 then
      DeleteDescription(AName, ShortName^);
  end;
  if AbortDiskAction then DeleteStatus := dsCancel;
  GiveTicks;
  if Clock <> nil then Clock^.Update;
  if TheSpooler <> nil then TheSpooler^.ProcessItems;
Quit:
  FreeMem(F, SizeOf(lFile));
  FreeMem(ShortName, SizeOf(String));
end;

procedure DirRemovePrim(const ADir: FNameStr);
var
  B: Boolean;
  Attr: Word;
  S: PString;
  F: ^lFile;
label
  Retry1, Retry2, Retry3;
begin
  if ADir[0] < #4 then Exit;
{ Added 2005.08.30 to support regexp file operations }
  if FileRegExp <> nil then Exit;
  GetMem(S, SizeOf(String));
Retry1:
  GetCurDir(0, S^);
  if CompUCString(S^, ADir) = Equal then
  begin
    if DeleteErrorStatus <> deIgnoreAll then
      DeleteErrorStatus := DiskErrorDialog('Delete',
        ^C'Can''t delete the current directory'#13^C + TrimmedName(ADir, 62) + '.');
    if DeleteErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(ADir)
    else if DeleteErrorStatus = deCancel then DeleteStatus := dsCancel
    else goto Retry1;
    FreeMem(S, SizeOf(String));
    Exit;
  end;
  FreeMem(S, SizeOf(String));

  GetMem(F, SizeOf(lFile));
  if DeleteStatus = dsSkip then DeleteStatus := dsDelete;
  lAssignFile(F^, ADir);
Retry2:
  lGetFAttr(F^, Attr);
  if DosError <> 0 then
  begin
    if DeleteErrorStatus <> deIgnoreAll then
      DeleteErrorStatus := DiskErrorDialog('Delete',
        ^C'Could not find the directory'#13^C + TrimmedName(ADir, 62) + '.');
    if DeleteErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(ADir)
    else if DeleteErrorStatus = deCancel then DeleteStatus := dsCancel
    else goto Retry2;
    FreeMem(F, SizeOf(lFile));
    Exit;
  end;
  if Attr and (ReadOnly + Hidden + SysFile) <> 0 then
  begin
    if DeleteStatus <> dsAll then
    begin
      if DeleteStatus <> dsSkipAll then
        DeleteStatus := DelSkipDialog(ADir, 'directory');
      if DeleteStatus in [dsSkip, dsSkipAll, dsCancel] then
      begin
        FreeMem(F, SizeOf(lFile));
        DrawSkipStatus(ADir);
        Exit;
      end;
    end;
    lSetFAttr(F^, 0);
    InOutRes := 0;
  end;
  FreeMem(F, SizeOf(lFile));

  LogEvent := lcDiskWrite;
  DrawStatusLine('Deleting the directory ' + TrimmedName(ADir, 45) + '.');
Retry3:
{ Added 2005.12.30 }
  if CN_NT and (FileCopyOptions and fsDelToTrash <> 0) then
    B := NT_DelToTrash(ADir)
  else
  begin
    lRmDir(ADir);
    B := IOResult = 0;
  end;
  if B then
  begin
    SendChangeMsg(ADir);
    SendChangeMsg(ADir + '\1');
  end
  else
  begin
    if DeleteErrorStatus <> deIgnoreAll then
      DeleteErrorStatus := DiskErrorDialog('Delete',
        ^C'Could not delete the directory'#13^C + TrimmedName(ADir, 62) + '.');
    if DeleteErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(ADir)
    else if DeleteErrorStatus = deCancel then DeleteStatus := dsCancel
    else goto Retry3;
  end;
  GiveTicks;
  if Clock <> nil then Clock^.Update;
  if TheSpooler <> nil then TheSpooler^.ProcessItems;
end;

procedure ClearDirFiles(const ADir, AMask: FNameStr;
  ACRCList: PTagList);
var
  SR: ^lSearchRec;
  S: PString;
begin
  CancelSysErrors := False;
  GetMem(S, SizeOf(String));
  GetMem(SR, SizeOf(lSearchRec));
  lFindFirst(ADir + AMask, AnyFile and not VolumeID, SR^);
  if CancelSysErrors then DeleteStatus := dsCancel;
  while (DosError = 0) and (DeleteStatus <> dsCancel) do
  begin
    if SR^.SR.Attr and (VolumeID + Directory) = 0 then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(ADir, SR^.FullName, False, S^)
      else AddNameAndSlash(ADir, SR^.SR.Name, False, S^);
      if FoundInCRCList(S^, ACRCList) then FDeletePrim(S^);
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  FreeMem(S, SizeOf(String));
end;

procedure ClearDirs(const ADir: FNameStr;
  ACRCList: PTagList; All, EmptyOnly: Boolean);
var
  SaveOpt: Longint;
  S: PString;

procedure DoClearDirs(ADir: PString);
var
  SR: ^lSearchRec;
  Dir: PString;
begin
  if StackOverflow then
  begin
    DeleteStatus := dsCancel;
    Exit;
  end;
  Dir := NewStr(ADir^);
  GetMem(SR, SizeOf(lSearchRec));
  if All then ClearDirFiles(Dir^, '*.*', ACRCList);
  if DeleteStatus = dsCancel then Exit;
  AddNameAndSlash(Dir^, '*.*', False, S^);
  CancelSysErrors := False;
  lFindFirst(S^, $17, SR^);
  if CancelSysErrors then DeleteStatus := dsCancel;
  while (DosError = 0) and (DeleteStatus <> dsCancel) do
  begin
    if (SR^.SR.Attr and Directory <> 0) and (SR^.SR.Name[1] <> '.') then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(Dir^, SR^.FullName, True, S^)
      else AddNameAndSlash(Dir^, SR^.SR.Name, True, S^);
{ Added 04.17.03 to support directory recursive copy/move }
      if not DirCRCListInUse or (DirCRCList = nil) or
         not DirCRCList^.NameFound(S^) then DoClearDirs(S);
    end;
    if (DeleteStatus <> dsCancel) and
       (SR^.SR.Attr and Directory <> 0) and
       (SR^.SR.Name[1] <> '.') then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(Dir^, SR^.FullName, False, S^)
      else AddNameAndSlash(Dir^, SR^.SR.Name, False, S^);
{ Added 04.26.03 to support empty dir deletion }
      if EmptyOnly then DirDeletePrim(S^, nil, False, True) else
{ Added 04.17.03 to support directory recursive copy/move }
      if not DirCRCListInUse or (DirCRCList = nil) or
         not DirCRCList^.NameFound(AddedSlash(S^)) then DirRemovePrim(S^);
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  GetMem(S, SizeOf(String));
  SaveOpt := FMOptions;
  FMOptions := FMOptions and not foCopyDescriptions;
  DoClearDirs(@ADir);
  FMOptions := SaveOpt;
  FreeMem(S, SizeOf(String));
end;

procedure DirDeletePrim(const ADir: FNameStr;
  ACRCList: PTagList; All, EmptyOnly: Boolean);
var
  C: Word;
  SR: ^lSearchRec;
begin
  if (EmptyOnly or (DeleteStatus <> dsAll) and
     (FMOptions and foDirDelPrompt <> 0)) and
    not ((Length(ADir) <= 3) and (ADir[2] = ':')) then
  begin
    CancelSysErrors := False;
    GetMem(SR, SizeOf(lSearchRec));
    lFindFirst(AddedSlash(ADir) + '*.*', AnyFile and not VolumeID, SR^);
    if CancelSysErrors then DeleteStatus := dsCancel;
    while (DosError = 0) and (SR^.SR.Name[1] = '.') do lFindNext(SR^);
    lFindClose(SR^);
    FreeMem(SR, SizeOf(lSearchRec));
    if DosError = 0 then
    begin
      if EmptyOnly then Exit;
      C := MessageBox(^C'The directory |' + ADir +
        '|'#13^C'is not empty.'#13^C'Do you still wish to delete it ?',
        nil, mfConfirmation + mfYesAllNoCancel);
      if C = cmCancel then DeleteStatus := dsCancel
      else if C = cmOk then
      begin
        C := cmYes;
        DeleteStatus := dsAll;
      end;
      if C <> cmYes then Exit;
    end;
  end;
  if not EmptyOnly then
{ Added 2005.12.30 }
    if CN_NT and (FileCopyOptions and fsDelToTrash <> 0) then {}
    else ClearDirs(AddedSlash(ADir), ACRCList, All, False);
  if DeleteStatus <> dsCancel then
  begin
    DirRemovePrim(ADir);
    if not DirPresent(ADir) then DelDirFromTree(ADir);
  end;
end;

procedure DeleteFilesByMask(const ADir, AMask: FNameStr;
  ACRCList: PTagList);
var
  S: PString;

procedure DoDeleteByMask(ADir: PString; const AMask: FNameStr);
var
  SR: ^lSearchRec;
  Dir: PString;
label
  Quit;
begin
  if StackOverflow then
  begin
    DeleteStatus := dsCancel;
    Exit;
  end;
  Dir := NewStr(ADir^);
  GetMem(SR, SizeOf(lSearchRec));
  DrawStatus(Dir^);
  GiveTicks;
  if Clock <> nil then Clock^.Update;
  if TheSpooler <> nil then TheSpooler^.ProcessItems;
  ClearDirFiles(Dir^, AMask, ACRCList);
  if DeleteStatus = dsCancel then Exit;
  AddNameAndSlash(Dir^, '*.*', False, S^);
  CancelSysErrors := False;
  lFindFirst(S^, $17, SR^);
  if CancelSysErrors then DeleteStatus := dsCancel;
  while (DosError = 0) and (DeleteStatus <> dsCancel) do
  begin
    if AbortDiskAction then
    begin
      DeleteStatus := dsCancel;
      Goto Quit;
    end;
    if (SR^.SR.Attr and Directory <> 0) and (SR^.SR.Name[1] <> '.') then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(Dir^, SR^.FullName, True, S^)
      else AddNameAndSlash(Dir^, SR^.SR.Name, True, S^);
      DoDeleteByMask(S, AMask);
    end;
    lFindNext(SR^);
  end;
Quit:
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  GetMem(S, SizeOf(String));
  DoDeleteByMask(@ADir, AMask);
  FreeMem(S, SizeOf(String));
end;

function MkDirPrim(const ADir: FNameStr;
  SearchRecPtr: PSearchRec): FNameStr;
var
  P: Byte;
  Attr: Word;
  Exists, Created: Boolean;
  S: PString;
  F: ^lFile;
label
  Scan, Retry;
begin
  MkDirPrim := '';
  if DeviceDest(ADir) <> '' then Exit;
{ Added 2005.08.30 to support regexp file operations }
  if (FileRegExp <> nil) and (Pos('>', ADir) <> 0) then Exit;
  GetMem(S, SizeOf(String));
  P := 4;
  Created := False;
  repeat
Scan:
    while (P <= Length(ADir)) and (ADir[P] <> '\') do Inc(P);
    if (P < Length(ADir)) and (ADir[P + 1] = '\') then
    begin
      while (P <= Length(ADir)) and (ADir[P] = '\') do Inc(P);
      Goto Scan;
    end;
    S^ := Copy(ADir, 1, P - 1);
    if FMOptions and foForceUpperDirs <> 0 then UpcaseSt(S^);
    while (P <= Length(ADir)) and (ADir[P] = '\') do Inc(P);
    CancelSysErrors := False;
    Exists := DirPresent(S^);
    if CancelSysErrors then
    begin
      CopyStatus := dsCancel;
      Break;
    end;
    if not Exists then
    begin
{ Added 2005.09.16 to support prompt before file operation }
      if (FileCopyOptions and fsConfirmFileOperation <> 0) and
        not FileOperationConfirmed('', S^, faMkDir) then Continue;

      LogEvent := lcDiskWrite;
      DrawStatusLine('Creating the directory ' +
        TrimmedName(S^, 45) + '.');
Retry:
      lMkDir(S^);
      if IOResult <> 0 then
      begin
        if CopyErrorStatus <> deIgnoreAll then
          CopyErrorStatus := DiskErrorDialog('Make directory',
            ^C'Could not create the directory'#13^C + TrimmedName(S^, 62) + '.');
        if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(S^)
        else if CopyErrorStatus = deCancel then CopyStatus := dsCancel
        else goto Retry;
        Break;
      end;
      SendChangeMsg(S^);
      Created := True;
    end;
  until P > Length(ADir);
  if (CopyStatus <> dsCancel) and (SearchRecPtr <> nil) and Created then
  begin
    GetMem(F, SizeOf(lFile));
    lAssignFile(F^, S^);
    Attr := SearchRecPtr^.Attr and not Directory;
    if FileCopyOptions and fsClearReadOnly <> 0 then
      Attr := Attr and not ReadOnly;
    lSetFAttr(F^, Attr);
    FreeMem(F, SizeOf(lFile));
  end;
  FreeMem(S, SizeOf(String));
  if Created then AddDirToTree(ShortFileName(ADir), ADir);
end;

{ Added 2006.01.14 }
const
  Copy_File_Fail_If_Exists = $00000001;
  Copy_File_Restartable = $00000002;
  Copy_File_ClearRO = $00000004;

  {CopyProgressRoutine return value}
  Progress_Continue = 0;  {Continue the copy operation.}
  Progress_Cancel = 1;    {Cancel the copy operation and delete the destination file.}
  Progress_Stop = 2;      {Stop the copy operation. It can be restarted at a later time.}
  Progress_Quiet = 3;     {Continue the copy operation, but stop invoking CopyProgressRoutine to report progress.}

var
  NT_BytesCopied: Real;

function WinMsgBox(Text, Caption: String; Flag: Longint): Longint;
var
 Regs: Registers;

begin
{ Always True }
{ if CN_NT and (Length(Text) < 254) and (Length(Caption) < 254) then}
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


function NT_SysCopyProgressFunc(
  LowLowCopy, LowHighCopy,
  HighLowCopy, HighHighCopy,
  LowLowSize, LowHighSize,
  HighLowSize, HighHighSize: Word): Longint;
{Low = 0 - continue copy, Low = 1 - cancel copy}
{High = CopyProgressRoutine return value}
var
  Key: Char;
  L, Result: Longint;
  R, V: Real;
  S1, S2, S3: String[31];
begin
  if CopyStatus = dsCancel then
  begin
    NT_SysCopyProgressFunc := 1;
    Exit;
  end;

  Result := 0;

  if (KbdStatus = 1) or (KbdHead <> KbdTail) then
  begin
    repeat until KeyPressed or (KbdStatus <> 1);
    if EscPressed then
    begin
      ClearKbd;
      if WinMsgBox('Abort Windows NT System Copy operation ?',
	'Confirmation', $50004) = 6 then Result := 1;
    end;
  end;

  NT_SysCopyProgressFunc := Result;

  if Result <> 0 then
  begin
    CopyStatus := dsCancel;
    Exit;
  end;

  R := LowLowCopy + LowHighCopy * 65536.0 + HighLowCopy * 4294967296.0;
  V := LowLowSize + LowHighSize * 65536.0 + HighLowSize * 4294967296.0;

  Str(R:0:0, S1);
  Str(V:0:0, S2);
  if V = 0 then S3 := '100' else Str((R * 100.0 / V):0:0, S3);
  LogEvent := 0;
  DrawStatusLine('Windows NT CopyFileEx: ' +
    S1 + ' of ' + S2 + ' bytes, ' + S3 + '%');

  BytesCopied := BytesCopied + R - NT_BytesCopied;
  if (R > 0.0) and (NT_BytesCopied = 0.0) then
  begin
    V := V / R;
    if V >= MaxLongint then L := MaxLongint else L := Trunc(V);
    Message(CopyBarWindow, evBroadcast, cmBarVolume, Pointer(L));
  end;
  if R > 0.0 then Message(CopyBarWindow, evBroadcast, cmUpdateBar, nil);
  NT_BytesCopied := R;

  UpdateStatistics;
  GiveTicks;
  if Clock <> nil then Clock^.Update;
end;

procedure NT_SysCopyCallbackFunc; far; assembler;
asm
 push ax
 push bx
 push cx
 push dx
 push si
 push di
 push es
 push ds
 mov ax, SEG @Data
 mov ds, ax
 call NT_SysCopyProgressFunc
 dw $0C4C4
 db $0FE
end;

function NT_SysCopy(src, dest: String; Flag: Word; progress: pointer): Boolean;
var
 Regs: Registers;
begin
 if (Length(src) < 254) and (Length(dest) < 254) then with Regs do
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
   NT_SysCopy := boolean(ax);
  end;
end;

function FCopyPrim(const FromName, ToName: FNameStr): FNameStr;
var
  ToSpecial, ShowBar, NewDest, NewName,
  Flushed, SpaceChecked, Appending, Resuming, ToNul: Boolean;
  FromTrimLen, ToTrimLen, B: Byte;
  BufSize, BufPos, FromAttr, ToAttr, FAttr, NumRead, NumWritten, C: Word;
  Buffer: PByteArray;
  FTime, FSize, TTime, TSize,
  L, BytesWritten, BytesLeft, CurCopied: Longint;
{ Added 05-12-03 to support file splitting }
  SplitCount, SplitPortion, SplitPosition: Longint;
{ Added 2005.11.24 }
  R: Real;
  CurToName: FNameStr;
  SS: String;
  FromF, ToF: lFile;

procedure GetBarCount;
begin
  L := BytesLeft div BufSize;
  if (L = 0) or (BytesLeft mod BufSize <> 0) then Inc(L);
  L := L shl 1;
end;

procedure AllocateBuffer;
var
  Diff: Boolean;
begin
  Diff := False;
  repeat
    Buffer := MemAlloc(BufSize);
    if Buffer <> nil then Break;
    BufSize := BufSize shr 1;
    if BufSize < $400 then Exit;
    Diff := True;
  until False;
  if Heap <> nil then Heap^.Update;
  if not Diff then Exit;
  GetBarCount;
  Message(CopyBarWindow, evBroadcast, cmBarVolume, Pointer(L));
end;

procedure DoneBuffer;
begin
  FreeMem(Buffer, BufSize);
end;

procedure ShowBarWindow;
var
  W: Integer;
begin
  if FileCopyOptions and fsDisableCopyBar = 0 then
  begin
    GetBarCount;
    W := Length(CurToName) - Length(SS);
    if W < 32 - Length(SS) then W := 32 - Length(SS)
    else if W > ScreenWidth - 6 - Length(SS) then
      W := ScreenWidth - 6 - Length(SS);
    OpenCopyBarWindow(Concat(TrimmedName(FromName, W), SS),
      CurToName, L, MoveCopy, CopyLeft);
  end;
  if FileCopyOptions and fsDisableCopyStat = 0 then
    OpenCopyStatWindow(CopyLeft);
  if not RollerInUse then InitRoller;
  RollerBack := CopyLeft;
end;

function TryToCopy: Word;
begin
  TryToCopy := MessageBox(
    ^C'There is not enough free space'#13^C +
    'on ' + RootName(CurToName) + ' to copy "|' +
    FromName + '|".'#13^C'Copy and continue on new disk ?',
    nil, mfWarning + mfYesAllNoCancel);
end;

function GetNewToName(TheRest: Boolean): Boolean;
var
  C: Word;
  D: PDialog;
  R: TRect;
  RS, BS, FN: FNameStr;
  CopyNameData: TCopyNameData;
begin
  if TheRest then
  begin
    RS := 'Copy the rest of ';
    FormatStr(BS, ' (%d bytes) ', BytesLeft);
    if BytesLeft = 1 then System.Delete(BS, Length(BS) - 2, 1);
  end
  else
  begin
    RS := 'Copy ';
    BS := ' ';
  end;
  CopyNameData.ToName := CurToName;
  CopyNameData.Options := Byte(FileCopyOptions and fsNT_SysCopy <> 0);
  R.Assign(0, 0, 70, 8);
  D := InitCopyDialog(R, Concat(
    RS, '"', TrimmedName(FromName, 45 - Length(RS) - Length(BS)),
    '"', BS, 'to'), False, False);
  C := Application^.ExecuteDialog(D, @CopyNameData, True);
  CurToName := CopyNameData.ToName;
  TrimSt(CurToName);
  if (C <> cmCancel) and (CurToName <> '') then
  begin
    if CopyNameData.Options and 1 <> 0 then
      FileCopyOptions := FileCopyOptions or fsNT_SysCopy
    else FileCopyOptions := FileCopyOptions and not fsNT_SysCopy;
    FN := FromName;
    CancelSysErrors := False;
    ValidNames(FN, CurToName);
    GetNewToName := not CancelSysErrors;
  end
  else GetNewToName := False;
end;

procedure DoneFromF;
begin
  Close(FromF.F);
  InOutRes := 0;
end;

procedure DoneToF;
begin
  if not ToSpecial and not Appending and not NewDest then
    SetFTime(ToF.F, FTime);
  Close(ToF.F);
  if not ToSpecial then
  begin
    if (IOResult = 0) and not Appending and
       ((FromAttr and not faFakeAttr) <> Archive) then
      lSetFAttr(ToF, FromAttr and not faFakeAttr);
    SendChangeMsg(CurToName);
  end;
end;

procedure NameLengthsToFit(var L1, L2: Byte; Len: Byte);
begin
  repeat
    if L1 + L2 <= Len then Exit;
    if L1 >= L2 then Dec(L1);
    if L2 >= L1 then Dec(L2);
  until False;
end;

procedure UpdateStatusLine;
var
  R: Real;
  Params: Array[0..2] of Longint;
  CS: String[15];
  PS: String;
begin
  if NumWritten = 0 then Exit;
  Params[0] := BytesWritten;
  if BytesWritten = 1 then CS := '' else CS := 's';
  Params[1] := Longint(@CS);
  if FSize = 0 then Params[2] := 100
  else
  begin
    R := BytesWritten;
    R := R * 100 / lGetFileRealSize(FromAttr, FSize);
    Params[2] := Trunc(R);
  end;
  FormatStr(PS, ': %d byte%s, %d%%', Params);
  if SplitCopy then CS := 'Splitt'
  else if Resuming then CS := 'Resum'
  else if Appending then CS := 'Append'
  else if MoveCopy then CS := 'Mov'
  else CS := 'Copy';
  FromTrimLen := Length(FromName);
  ToTrimLen := Length(CurToName);
  NameLengthsToFit(FromTrimLen, ToTrimLen, 60 - Length(CS) - Length(PS));
  LogEvent := 0;
  DrawStatusLine(
    Concat(CS, 'ing ', TrimmedName(FromName, FromTrimLen),
      ' to ', TrimmedName(CurToName, ToTrimLen), PS));
end;

procedure FixNumWritten;
begin
  Close(ToF.F);
  lResetFile(ToF, 1);
  L := FileSize(ToF.F);
  Seek(ToF.F, L);
  InOutRes := 0;
  NumWritten := L - CurCopied;
end;

{ Added 05-12-03 to support file splitting }
function InitSplit: Boolean;
var
  CS: String[4];
begin
  InitSplit := False;
  if (SplitSize = 0) and (SplitNumber = 0) then
  begin
    MessageBox(^C'Split size incorrectly specified.',
      nil, mfError + mfOkButton);
    Exit;
  end;
  Find1st(FromName, FromAttr, FSize, FTime);
  if FromAttr and faSizeInKB <> 0 then
    if FSize > MaxLongint shr 10 then
    begin
      MessageBox(^C'Can''t split files larger than 2 GB.',
	nil, mfError + mfOkButton);
      Exit;
    end
    else FSize := FSize shl 10;
  if SplitNumber <> 0 then
  begin
    SplitSize := Trunc(FSize / SplitNumber);
    if FSize mod SplitNumber <> 0 then Inc(SplitSize);
  end;
  if SplitSize >= FSize then
  begin
    MessageBox(^C'Split size is greater than or equal to file size.',
      nil, mfError + mfOkButton);
    Exit;
  end;
  FilesTotal := FSize div SplitSize + 1;
  SplitPortion := FSize mod SplitSize;
  if SplitPortion = 0 then
  begin
    SplitPortion := SplitSize;
    Dec(FilesTotal);
  end;
  if MoveCopy then CS := 'move' else CS := 'copy';
  if MessageBox(^C'Split (' + CS + ') the file'#13^C'|' +
    FromName + '|'#13^C'to ' +
    Long2Str(FilesTotal) + ' files by ' +
    Long2Str(SplitSize) + ' bytes ?', nil,
    mfConfirmation + mfOkCancel) <> cmOk then Exit;
  SplitCount := FilesTotal - 1;
  InitSplit := True;
end;

function GetSplitToName: FNameStr;
var
  C: Char;
  S: String;
begin
  FormatStr(S, ToName, SplitCount);
  if S = ToName then
  begin
    Str(FilesTotal - 1, S);
    C := Char(Byte(S[0]) + Byte('0'));
    if C < '3' then C := '3' else if C > '9' then C := '9';
    FormatStr(S, ForceExtension(ToName, '%0' + C + 'd'), SplitCount);
  end;
  GetSplitToName := S;
end;

procedure SetSplitPosition;
begin
  if SplitTruncate or (SplitPortion < SplitSize) then
    SplitPosition := FSize - SplitPortion
  else SplitPosition := SplitPortion * SplitCount;
end;

function DoEraseFile: Word;
begin
  DoEraseFile := MessageBox(^C'Delete the file'#13^C'|' + CurToName + '| ?',
    nil, mfConfirmation + mfYesNo);
end;

label
  SplitLoop, ANew, Find, Reset, IsDev, Rewrite,
  NotAcc, Skip, OpenDest, DoneFrom, NT_Copy;
begin
  FCopyPrim := '';
{ Added 05-12-03 to support file splitting }
  SplitCount := -1;
SplitLoop:
  if AbortDiskAction then
  begin
    CopyStatus := dsCancel;
    Exit;
  end;
  if (CopyStatus = dsSkip) or (CopyStatus = dsReadError) then
    CopyStatus := dsOverwrite;
  Skipped := True;
  CopyOk := False;
  Flushed := True;
  NewDest := False;
  NewName := False;
  BytesWritten := 0;
{ Added 05-12-03 to support file splitting }
  if SplitCopy then
  begin
    if SplitCount = -1 then if not InitSplit then Exit;
    CurToName := GetSplitToName;
    SetSplitPosition;
  end
{ Added 2005.08.30 to support regexp file operations }
  else if FileRegExp <> nil then
  begin
{ Added 2005.09.29 to avoid loops copying with regexps }
    if (FileCRCList <> nil) and FileCRCList^.NameFound(FromName) then Exit;
    CurToName := FileRegExpNewName(FromName);
    if CurToName = '' then Exit;
  end
  else CurToName := ToName;

{ Added 2005.09.16 to support prompt before file operation }
  if (FileCopyOptions and fsConfirmFileOperation <> 0) and
    not FileOperationConfirmed(FromName, CurToName, faCopy) then Exit;

{ Added 2005.09.29 to avoid loops copying with regexps }
  if FileRegExp <> nil then AddFileCRCItem(CurToName);

ANew:
  if CompUCString(FromName, CurToName) = Equal then
  begin
    if CopyErrorStatus <> deIgnoreAll then
      CopyErrorStatus := DiskErrorDialog('Copy',
        ^C'Can''t copy a file to itself:'#13^C + TrimmedName(FromName, 62) + '.');
    if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(FromName)
    else if CopyErrorStatus = deCancel then CopyStatus := dsCancel
    else goto ANew;
    if NewDest then
    begin
      DoneBuffer;
      DoneFromF;
    end;
    Exit;
  end;

  SS := DeviceDest(CurToName);
  if SS <> '' then CurToName := SS;
  ToSpecial := SS <> '';
  ToNul := SS = 'NUL';

  if not NewDest then
  begin
Find:
    Find1st(FromName, FromAttr, FSize, FTime);
    if DosError <> 0 then
    begin
      if CopyErrorStatus <> deIgnoreAll then
	CopyErrorStatus := DiskErrorDialog('Copy',
	  ^C'Could not find the file'#13^C + TrimmedName(FromName, 62) + '.');
      if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(FromName)
      else if CopyErrorStatus = deCancel then CopyStatus := dsCancel
      else goto Find;
      Exit;
    end;
    FAttr := FromAttr;
    if FileCopyOptions and fsClearReadOnly <> 0 then
      FromAttr := FromAttr and not ReadOnly;
{ Added 05-12-03 to support file splitting }
    if SplitCopy then BytesLeft := SplitPortion else
{ Added 2005.11.24 }
    if FromAttr and faSizeInKB <> 0 then
    begin
      R := lGetFileRealSize(FromAttr, FSize);
      if R >= MaxLongint then BytesLeft := MaxLongint
      else BytesLeft := Trunc(R);
    end
    else BytesLeft := FSize;
    if ToSpecial and not ToNul then BufSize := $1000
    else if FSize > $FFF0 then BufSize := $FFF0
    else if FSize > $8000 then BufSize := $8000
    else if FSize > $4000 then BufSize := $4000
    else if FSize > $2000 then BufSize := $2000
    else BufSize := $1000;
  end;

  FormatStr(SS, ' (%d bytes)', BytesLeft);
  if BytesLeft = 1 then System.Delete(SS, Length(SS) - 1, 1);
  ShowBar := CopyStatus in AppendResumeSkipAllSet;
  if not ShowBar then ShowBarWindow;

  if not ToSpecial then
  begin
    CancelSysErrors := False;
    Find1st(CurToName, ToAttr, TSize, TTime);
    if CancelSysErrors then
    begin
      CopyStatus := dsCancel;
      Goto Skip;
    end;
    if DosError <> 0 then ToAttr := 0;
    if (DosError = 0) and not (CopyStatus in AppendResumeAllSet) then
    begin
      if ((CopyStatus = dsAll) and (FileExistsAction <> feCompare)) or
	 (CopyStatus = dsSkipAll) then {}
      else
      begin
        B := CopySkipDialog(FromName, CurToName, FTime, TTime,
	  lGetFileRealSize(FromAttr, FSize),
	  lGetFileRealSize(ToAttr, TSize));
        if (CopyStatus = dsAll) and (FileExistsAction = feCompare) then
          if B = dsSkip then Goto Skip else
        else CopyStatus := B;
      end;
      if CopyStatus in [dsSkip, dsSkipAll, dsCancel] then
      begin
Skip:
        if NewDest then
        begin
          DoneBuffer;
          DoneFromF;
        end;
	SkipFile(FromName, lGetFileRealSize(FromAttr, FSize), BytesWritten);
        Exit;
      end;
      if CopyStatus = dsNew then
      begin
        if not GetNewToName(False) then Goto Skip;
        NewName := True;
        Goto ANew;
      end;
    end;
  end;
  if ShowBar or (CopyStatus in AppendResumeAllSet) then ShowBarWindow;

{ Added 2006.01.14 }
NT_Copy:
  if (FileCopyOptions and fsNT_SysCopy <> 0) and CN_NT and
    not SplitCopy and not NewDest and not (CopyStatus in AppendAllSet) then
  begin
    if ToAttr and (ReadOnly + Hidden + SysFile) <> 0 then
    begin
      lAssignFile(ToF, CurToName);
      lSetFAttr(ToF, Archive);
    end
    else MkDirPrim(PrevDir(CurToName), nil);
    NT_BytesCopied := 0;
    C := Copy_File_Restartable;
    if (FAttr and ReadOnly <> 0) and
       (FileCopyOptions and fsClearReadOnly <> 0) then
      C := C + Copy_File_ClearRO;
    LogEvent := lcDiskWrite;
    DrawStatusLine('Calling Windows NT CopyFileEx function.');
    if not NT_SysCopy(FromName, CurToName, C, @NT_SysCopyCallbackFunc) then
    begin
      if CopyStatus = dsCancel then Exit;
      if CopyErrorStatus <> deIgnoreAll then
        CopyErrorStatus := DiskErrorDialog('Windows NT FileCopyEx',
          ^C'An error occurred on attempt to copy the file'#13^C +
          TrimmedName(FromName, 62) + '.');
      if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(FromName)
      else if CopyErrorStatus = deCancel then CopyStatus := dsCancel
      else goto NT_Copy;
      Exit;
    end;
    Skipped := False;
    CopyOk := True;
    if FMOptions and foCopyDescriptions <> 0 then
    begin
      lGetShortFileName(FromName, SS);
      CopyDescription(FromName, SS, CurToName);
    end;
    Inc(FilesCopied);
    UpdateStatistics;
    FCopyPrim := CurToName;
    Exit;
  end;

  if not NewDest then
  begin
    lAssignFile(FromF, FromName);
Reset:
    lResetReadOnly(FromF, 1);
    if IOResult <> 0 then
    begin
      if CopyErrorStatus <> deIgnoreAll then
        CopyErrorStatus := DiskErrorDialog('Copy',
          ^C'Could not open the file'#13^C + TrimmedName(FromName, 62) + '.');
      if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(FromName)
      else if CopyErrorStatus = deCancel then CopyStatus := dsCancel
      else goto Reset;
      Exit;
    end;
IsDev:
    if IsDevice(FileRec(FromF.F).Handle) then
    begin
      if CopyErrorStatus <> deIgnoreAll then
        CopyErrorStatus := DiskErrorDialog('Copy',
          ^C'File ' + TrimmedName(FromName, 57) + #13^C'is a device.');
      if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(FromName)
      else if CopyErrorStatus = deCancel then CopyStatus := dsCancel
      else goto IsDev;
      Close(FromF.F);
      InOutRes := 0;
      Exit;
    end;
{ Added 05-12-03 to support file splitting }
    if SplitCopy then Seek(FromF.F, SplitPosition);
  end;

  SpaceChecked := False;
  Appending := False;
  Resuming := False;

OpenDest:
  CurCopied := 0;
  lAssignFile(ToF, CurToName);
  if ToSpecial then
  begin
    lRewriteFile(ToF, 1);
    DeviceBinaryMode(FileRec(ToF.F).Handle);
  end
  else
  begin
    if ToAttr and (ReadOnly + Hidden + SysFile) <> 0 then
      lSetFAttr(ToF, Archive);
    CancelSysErrors := False;
    if Appending or (CopyStatus in AppendResumeAllSet) then
    begin
      lResetFile(ToF, 1);
      if InOutRes = 0 then
      begin
        CurCopied := FileSize(ToF.F);
        Seek(ToF.F, CurCopied);
        Appending := True;
      end;
{ Added 25-04-2005 to support file completion }
      if (CopyStatus in ResumeAllSet) or
         (GetShiftState and (kbLeftShift + kbRightShift) <> 0) then
      begin
        Seek(FromF.F, CurCopied);
        Dec(BytesLeft, CurCopied);
        BytesCopied := BytesCopied + CurCopied;
        Resuming := True;
      end;
      if CopyStatus in AppendResumeSet then CopyStatus := dsOverwrite;
    end
    else lRewriteFile(ToF, 1);
    if CancelSysErrors then
    begin
      CopyStatus := dsCancel;
      if NewDest then DoneBuffer;
      DoneFromF;
      Exit;
    end;
    if IOResult <> 0 then
    begin
      MkDirPrim(PrevDir(CurToName), nil);
Rewrite:
      lRewriteFile(ToF, 1);
      if IOResult <> 0 then
      begin
        if CopyStatus <> dsCancel then
        begin
          if CopyErrorStatus <> deIgnoreAll then
            CopyErrorStatus := DiskErrorDialog('Copy',
              ^C'Could not create the file'#13^C + TrimmedName(CurToName, 62) + '.');
          if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(FromName)
          else if CopyErrorStatus = deCancel then CopyStatus := dsCancel
          else goto Rewrite;
        end;
        if NewDest then DoneBuffer;
        DoneFromF;
        Exit;
      end;
    end;
NotAcc:
    if NotAccessible(FileRec(ToF.F).Handle) then
    begin
      if CopyErrorStatus <> deIgnoreAll then
        CopyErrorStatus := DiskErrorDialog('Copy',
          ^C'File ' + TrimmedName(CurToName, 57) + #13^C'is a device.');
      if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(FromName)
      else if CopyErrorStatus = deCancel then CopyStatus := dsCancel
      else goto NotAcc;
      if NewDest then DoneBuffer;
      Close(ToF.F);
      InOutRes := 0;
      DoneFromF;
      Exit;
    end;
    if not SpaceChecked and not TryAll and
      (FMOptions and foCheckFreeSpace <> 0) and
{      (CurToName[1] <> '\') and}
{      (BytesLeft > FreeDiskSpace(Byte(CurToName[1]) - $40)) then}
      (BytesLeft > FreeDiskSpace(CurToName)) then
    begin
      SpaceChecked := True;
      Close(ToF.F);
      if not Appending then lEraseFile(ToF);
      InOutRes := 0;
      C := TryToCopy;
      if C = cmOk then TryAll := True;
      if TryAll or (C = cmYes) then Goto OpenDest;
      if NewDest then DoneBuffer;
      DoneFromF;
      if C = cmCancel then CopyStatus := dsCancel;
      Exit;
    end;
  end;

{ Added 05-12-03 to support file splitting }
  if SplitCopy then SS := 'Splitting'
  else if NewDest then SS := 'Copying the rest of'
  else if Resuming then SS := 'Resuming'
  else if Appending then SS := 'Appending'
  else if MoveCopy then SS := 'Moving'
  else SS := 'Copying';
  FromTrimLen := Length(FromName);
  ToTrimLen := Length(CurToName);
  NameLengthsToFit(FromTrimLen, ToTrimLen, 62 - Length(SS));
  LogEvent := lcDiskWrite;
  DrawStatusLine(
    Concat(SS, ' ', TrimmedName(FromName, FromTrimLen),
      ' to ', TrimmedName(CurToName, ToTrimLen), '.'));

  if not NewDest then AllocateBuffer;
  if Buffer = nil then
  begin
    CopyStatus := dsCancel;
    Application^.OutOfMemory;
  end
  else
  begin
    repeat
      CancelSysErrors := False;
      if Flushed then
      begin
{ Added 05-12-03 to support file splitting }
        if SplitCopy and (BytesLeft < BufSize) then
          BlockRead(FromF.F, Buffer^, BytesLeft, NumRead) else
        BlockRead(FromF.F, Buffer^, BufSize, NumRead);
        if CancelSysErrors then
        begin
          SkipFile(FromName, lGetFileRealSize(FromAttr, FSize), BytesWritten);
          CopyStatus := dsReadError;
          Break;
        end;
        if AbortDiskAction then
        begin
          CopyStatus := dsCancel;
          Break;
        end;
        if NumRead = 0 then Break;
        Message(CopyBarWindow, evBroadcast, cmUpdateBar, nil);
        GiveTicks;
        if Clock <> nil then Clock^.Update;
        UpdateRoller;
        BufPos := 0;
      end;
      if ToNul then NumWritten := NumRead
      else BlockWrite(ToF.F, Buffer^[BufPos], NumRead, NumWritten);
      if CancelSysErrors or AbortDiskAction then
      begin
        CopyStatus := dsCancel;
        Break;
      end;
      Flushed := True;
      Message(CopyBarWindow, evBroadcast, cmUpdateBar, nil);
      if not ToSpecial and
        ((IOResult <> 0) or (NumRead <> NumWritten)) then FixNumWritten;
      Inc(BytesWritten, NumWritten);
      Inc(CurCopied, NumWritten);
      Dec(BytesLeft, NumWritten);
      BytesCopied := BytesCopied + NumWritten;
      UpdateStatusLine;
      UpdateStatistics;
      GiveTicks;
      if Clock <> nil then Clock^.Update;
      if TheSpooler <> nil then TheSpooler^.ProcessItems;
      UpdateRoller;
      if not ToSpecial and (NumRead <> NumWritten) then
      begin
        Inc(BufPos, NumWritten);
        Dec(NumRead, NumWritten);
{       L := FreeDiskSpace(Byte(CurToName[1]) - $40);}
        L := FreeDiskSpace(CurToName);
        if (L > 0) and (L <= NumRead) then
        begin
          BlockWrite(ToF.F, Buffer^[BufPos], L, NumWritten);
          if CancelSysErrors or AbortDiskAction then
          begin
            CopyStatus := dsCancel;
            Break;
          end;
          if (IOResult <> 0) or (Word(L) <> NumWritten) then
            FixNumWritten;
          Inc(BytesWritten, NumWritten);
          Inc(CurCopied, NumWritten);
          Dec(BytesLeft, NumWritten);
          BytesCopied := BytesCopied + NumWritten;
          UpdateStatusLine;
          UpdateStatistics;
          Inc(BufPos, NumWritten);
          Dec(NumRead, NumWritten);
        end;
        L := FileSize(ToF.F);
        DoneToF;
        if L = 0 then
        begin
	  lSetFAttr(ToF, Archive);
          lEraseFile(ToF);
          InOutRes := 0;
        end;
        if not GetNewToName(True) then
        begin
	  if (L <> 0) and (DoEraseFile = cmYes) then
          begin
            lEraseFile(ToF);
            InOutRes := 0;
          end;
          DoneBuffer;
          Goto DoneFrom;
        end;
        Flushed := False;
        NewDest := True;
        NewName := False;
        Goto ANew;
      end;
{ Added 05-12-03 to support file splitting }
      if SplitCopy and (BytesLeft = 0) then Break;
    until False;
    DoneBuffer;
    InOutRes := 0;
  end;
  DoneToF;
  if (CopyStatus = dsCancel) or (CopyStatus = dsReadError) then
  begin
    if not ToSpecial {and not Appending} then
      if DoEraseFile = cmYes then
      begin
        lSetFAttr(ToF, Archive);
        lEraseFile(ToF);
      end
      else DeleteStatus := dsResume;
  end
  else
  begin
    Skipped := False;
    CopyOk := True;
    if FMOptions and foCopyDescriptions <> 0 then
    begin
      lGetShortFileName(FromName, SS);
      CopyDescription(FromName, SS, CurToName);
    end;
    Inc(FilesCopied);
    UpdateStatistics;
  end;
DoneFrom:
  DoneFromF;
{ Added 05-12-03 to support file splitting }
  if SplitCopy and CopyOk then
  begin
    if SplitTruncate then
    begin
      lAssignFile(FromF, FromName);
      lResetFile(FromF, 1);
      if IOResult = 0 then
      begin
        Seek(FromF.F, SplitPosition);
        Truncate(FromF.F);
      end;
      DoneFromF;
      Find1st(FromName, FromAttr, FSize, FTime);
    end;
    Dec(SplitCount);
    if (SplitCount >= Byte(SplitTruncate)) then
    begin
      SplitPortion := SplitSize;
      goto SplitLoop;
    end;
  end;
  FCopyPrim := CurToName;
end;

function NewName(const ADest, AName, AMask: FNameStr): FNameStr;
var
  C: String[1];
  NameExt, MaskExt, Name, MaskName, NameDir, MaskDir, N: String;
begin
  lFSplit(AName, NameDir, Name, NameExt);
  lFSplit(AMask, MaskDir, MaskName, MaskExt);

  if (DriveListOptions and (dlGetFromUser + dlUserResources) <> 0) and
    LFNDisabled(ADest) and ((AMask = '') or IsWild(AMask)) then
  begin
    lGetShortFileName(AName, N);
    lFSplit(N, NameDir, Name, NameExt);
  end;

{ Fixed 10.31.03 to support .ext filenames }
{
  if MaskExt = '' then
    if MaskName = '' then MaskExt := '*' else
  else Delete(MaskExt, 1, 1);
  if MaskName = '' then MaskName := '*';
}

  if (MaskName = '') and (MaskExt = '') then
  begin
    MaskName := '*';
    MaskExt := '*';
  end
  else if MaskExt <> '' then System.Delete(MaskExt, 1, 1);

  if NameExt <> '' then System.Delete(NameExt, 1, 1);
  ExpandWildCards(MaskName, MaskExt, Name, NameExt);
  if MaskExt = '' then C := '' else C := '.';
  NewName := Concat(MaskName, C, MaskExt);
end;

procedure ResetTotals;
begin
  BytesTotal := 0;
  BytesCopied := 0;
  FilesTotal := 0;
  FilesCopied := 0;
end;

procedure CountDirFiles(const ADir, AFilter: FNameStr; ACRCList: PTagList);
var
  SR: ^lSearchRec;
  S: PString;
begin
  DrawStatus(ADir);
  GiveTicks;
  if Clock <> nil then Clock^.Update;
  if TheSpooler <> nil then TheSpooler^.ProcessItems;
  CancelSysErrors := False;
  GetMem(S, SizeOf(String));
  GetMem(SR, SizeOf(lSearchRec));
  lFindFirst(ADir + AFilter, AnyFile and not VolumeID, SR^);
  if CancelSysErrors then CopyStatus := dsCancel;
  while (DosError = 0) and (CopyStatus <> dsCancel) do
  begin
    if SR^.SR.Attr and (VolumeID + Directory) = 0 then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(ADir, SR^.FullName, False, S^)
      else AddNameAndSlash(ADir, SR^.SR.Name, False, S^);
      if FoundInCRCList(S^, ACRCList) and
        CopyRenameFilterPassed(SR^.SR, SR^.FullName) then
      begin
        BytesTotal := BytesTotal + lGetFileRealSize(SR^.SR.Attr, SR^.SR.Size);
        Inc(FilesTotal);
      end;
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  FreeMem(S, SizeOf(String));
end;

procedure CountDirs(const ADir, AFilter: FNameStr; ACRCList: PTagList);
var
  S: PString;

procedure DoCountDirs(ADir: PString; const AFilter: FNameStr);
var
  SR: ^lSearchRec;
  Dir: PString;
begin
  if StackOverflow or AbortDiskAction then
  begin
    CopyStatus := dsCancel;
    Exit;
  end;
  Dir := NewStr(ADir^);
  GetMem(SR, SizeOf(lSearchRec));
  AddNameAndSlash(Dir^, '*.*', False, S^);
  CancelSysErrors := False;
  lFindFirst(S^, $17, SR^);
  if CancelSysErrors then CopyStatus := dsCancel;
  while (DosError = 0) and (CopyStatus <> dsCancel) do
  begin
    if (SR^.SR.Attr and Directory <> 0) and (SR^.SR.Name[1] <> '.') then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(Dir^, SR^.FullName, True, S^)
      else AddNameAndSlash(Dir^, SR^.SR.Name, True, S^);
      CountDirFiles(S^, AFilter, ACRCList);
      if CopyStatus <> dsCancel then DoCountDirs(S, AFilter);
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  GetMem(S, SizeOf(String));
  DoCountDirs(@ADir, AFilter);
  FreeMem(S, SizeOf(String));
end;

procedure DirCountPrim(const ADir, AFilter: FNameStr; ACRCList: PTagList);
begin
  CountDirFiles(AddedSlash(ADir), AFilter, ACRCList);
  if CopyStatus <> dsCancel then
    CountDirs(AddedSlash(ADir), AFilter, ACRCList);
end;

procedure CopyDirFiles(const FromDir, ToDir, ADir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
var
  SaveOpt: Longint;
  PSR: PSearchRec;
  SR: ^lSearchRec;
  ToDirName, S: PString;
label
  Quit;
begin
  GetMem(ToDirName, SizeOf(String));
  GetMem(S, SizeOf(String));
  GetMem(SR, SizeOf(lSearchRec));
  ToDirName^ := AddedSlash(
    ClearedSlash(ToDir) + System.Copy(ADir, Length(FromDir) + 1, 255));
  CancelSysErrors := False;
{ Added 04.28.03 to support optional avoiding empty directory copy }
  if FileCopyOptions and fsSkipEmptyDirs <> 0 then
  begin
    AddNameAndSlash(ADir, '*.*', False, S^);
    lFindFirst(S^, AnyFile and not VolumeID, SR^);
    while not CancelSysErrors and (DosError = 0) and
      (SR^.SR.Name[1] = '.') do lFindNext(SR^);
    lFindClose(SR^);
    if CancelSysErrors then
    begin
      CopyStatus := dsCancel;
      Goto Quit;
    end;
    if DosError <> 0 then goto Quit;
  end;
  lFindFirst(ClearedSlash(ADir), AnyFile and not VolumeID, SR^);
  lFindClose(SR^);
  if CancelSysErrors then
  begin
    CopyStatus := dsCancel;
    Goto Quit;
  end;
  if (DosError = 0) and (SR^.SR.Attr and Directory <> 0) then
    PSR := @SR^.SR else PSR := nil;
  if FoundInCRCList(ClearedSlash(ToDirName^), ACRCList) then
    MkDirPrim(ToDirName^, PSR);
  if CopyStatus = dsCancel then Goto Quit;
  SaveOpt := FMOptions;
  if AFilter = '*.*' then FMOptions := FMOptions and not foCopyDescriptions;
  CancelSysErrors := False;
  lFindFirst(ADir + AFilter, AnyFile and not VolumeID, SR^);
  if CancelSysErrors then CopyStatus := dsCancel;
  while (DosError = 0) and (CopyStatus <> dsCancel) do
  begin
    if (SR^.SR.Attr and (VolumeID + Directory) = 0) and
       (UCPos(FromDir, ADir) <> 0) then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(ADir, SR^.FullName, False, S^)
      else AddNameAndSlash(ADir, SR^.SR.Name, False, S^);
      if FoundInCRCList(S^, ACRCList) and
         CopyRenameFilterPassed(SR^.SR, SR^.FullName) then
        if SR^.FullName <> '' then
          FCopyPrim(S^, ToDirName^ +
            NewName(ToDirName^, SR^.FullName, AMask))
        else FCopyPrim(S^, ToDirName^ +
          NewName(ToDirName^, SR^.SR.Name, AMask));
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FMOptions := SaveOpt;
Quit:
  FreeMem(SR, SizeOf(lSearchRec));
  FreeMem(S, SizeOf(String));
  FreeMem(ToDirName, SizeOf(String));
end;

procedure CopyDirs(const FromDir, ToDir, ADir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
var
  SaveOpt: Longint;
  S: PString;

procedure DoCopyDirs(const FromDir, ToDir: FNameStr;
  ADir: PString; const AFilter, AMask: FNameStr);
var
  SR: ^lSearchRec;
  Dir: PString;
begin
  if StackOverflow then
  begin
    CopyStatus := dsCancel;
    Exit;
  end;
  Dir := NewStr(ADir^);
  GetMem(SR, SizeOf(lSearchRec));
  AddNameAndSlash(Dir^, '*.*', False, S^);
  CancelSysErrors := False;
  lFindFirst(S^, $17, SR^);
  if CancelSysErrors then CopyStatus := dsCancel;
  while (DosError = 0) and (CopyStatus <> dsCancel) do
  begin
    if (SR^.SR.Attr and Directory <> 0) and (SR^.SR.Name[1] <> '.') then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(Dir^, SR^.FullName, True, S^)
      else AddNameAndSlash(Dir^, SR^.SR.Name, True, S^);
{ Added 04.17.03 to support directory recursive copy/move }
      if not DirCRCListInUse or (DirCRCList = nil) or
         not DirCRCList^.NameFound(S^) then
      begin
        CopyDirFiles(FromDir, ToDir, S^, AFilter, AMask, ACRCList);
        if CopyStatus <> dsCancel then
          DoCopyDirs(FromDir, ToDir, S, AFilter, AMask);
      end;
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  GetMem(S, SizeOf(String));
  SaveOpt := FMOptions;
  FMOptions := FMOptions and not foForceUpperDirs;
  if SaveOpt and foForceUpperDirs <> 0 then
    DoCopyDirs(FromDir, OptUpcaseDir(FromDir, ToDir), @ADir, AFilter, AMask)
  else DoCopyDirs(FromDir, ToDir, @ADir, AFilter, AMask);
  FMOptions := SaveOpt;
  FreeMem(S, SizeOf(String));
end;

procedure DirCopyPrim(const FromDir, ToDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
var
  EndSlash: Boolean;
  SaveOpt: Longint;
label
  Retry;
begin
{ Added 04.17.03 to support directory recursive copy/move }
  if FileCopyOptions and fsEnableRecursive <> 0 then AddDirCRCItem(ToDir);
Retry:
  if DirWithin(FromDir, ToDir, EndSlash) then
  begin
    if (FileCopyOptions and fsEnableRecursive = 0) and (FileRegExp = nil) then
    begin
      if CopyErrorStatus <> deIgnoreAll then
        CopyErrorStatus := DiskErrorDialog('Copy',
          ^C'Can''t copy a directory to itself:'#13^C + TrimmedName(FromDir, 62) + '.');
      if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(FromDir)
      else if CopyErrorStatus = deCancel then CopyStatus := dsCancel
      else goto Retry;
      Exit;
    end;
    DirCRCListInUse := True;
  end;
  SaveOpt := FMOptions;
  FMOptions := FMOptions and not foForceUpperDirs;
  if SaveOpt and foForceUpperDirs <> 0 then
    CopyDirFiles(FromDir, OptUpcaseDir(FromDir, ToDir),
      AddedSlash(FromDir), AFilter, AMask, ACRCList)
  else CopyDirFiles(FromDir, ToDir, AddedSlash(FromDir),
    AFilter, AMask, ACRCList);
  FMOptions := SaveOpt;
  if CopyStatus <> dsCancel then
    CopyDirs(FromDir, ToDir, AddedSlash(FromDir),
      AFilter, AMask, ACRCList);
end;

procedure DirCopyFiles(const FromDir, ToDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
var
  SaveOpt: Longint;
  SR: ^lSearchRec;
  S: PString;
begin
  SaveOpt := FMOptions;
  if AFilter = '*.*' then FMOptions := FMOptions and not foCopyDescriptions;
  CancelSysErrors := False;
  GetMem(S, SizeOf(String));
  GetMem(SR, SizeOf(lSearchRec));
  lFindFirst(FromDir + AFilter, AnyFile and not VolumeID, SR^);
  if CancelSysErrors then CopyStatus := dsCancel;
  while (DosError = 0) and (CopyStatus <> dsCancel) do
  begin
    if SR^.SR.Attr and (VolumeID + Directory) = 0 then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(FromDir, SR^.FullName, False, S^)
      else AddNameAndSlash(FromDir, SR^.SR.Name, False, S^);
      if FoundInCRCList(S^, ACRCList) and
         CopyRenameFilterPassed(SR^.SR, SR^.FullName) then
        if SR^.FullName <> '' then
          FCopyPrim(S^, AddedSlash(ToDir) +
            NewName(ToDir, SR^.FullName, AMask))
        else FCopyPrim(S^, AddedSlash(ToDir) +
          NewName(ToDir, SR^.SR.Name, AMask));
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  FreeMem(S, SizeOf(String));
  FMOptions := SaveOpt;
end;

procedure CopyFilesByMask(const FromDir, ToDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
var
  SaveOpt: Longint;
  S: PString;

procedure DoCopyByMask(FromDir: PString;
  const ToDir, AFilter, AMask: FNameStr);
var
  SR: ^lSearchRec;
  Dir: PString;
label
  Quit;
begin
  if StackOverflow then
  begin
    CopyStatus := dsCancel;
    Exit;
  end;
  Dir := NewStr(FromDir^);
  GetMem(SR, SizeOf(lSearchRec));
  DrawStatus(Dir^);
  GiveTicks;
  if Clock <> nil then Clock^.Update;
  if TheSpooler <> nil then TheSpooler^.ProcessItems;
  if CopyStatus = dsCancel then Exit;
  DirCopyFiles(Dir^, ToDir, AFilter, AMask, ACRCList);
  if CopyStatus = dsCancel then Exit;
  AddNameAndSlash(Dir^, '*.*', False, S^);
  CancelSysErrors := False;
  lFindFirst(S^, $17, SR^);
  if CancelSysErrors then CopyStatus := dsCancel;
  while (DosError = 0) and (CopyStatus <> dsCancel) do
  begin
    if AbortDiskAction then
    begin
      CopyStatus := dsCancel;
      GoTo Quit;
    end;
    if (SR^.SR.Attr and Directory <> 0) and (SR^.SR.Name[1] <> '.') then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(Dir^, SR^.FullName, True, S^)
      else AddNameAndSlash(Dir^, SR^.SR.Name, True, S^);
      DoCopyByMask(S, ToDir, AFilter, AMask);
    end;
    lFindNext(SR^);
  end;
Quit:
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  GetMem(S, SizeOf(String));
  MkDirPrim(ToDir, nil);
  SaveOpt := FMOptions;
  FMOptions := FMOptions and not foForceUpperDirs;
  DoCopyByMask(@FromDir, ToDir, AFilter, AMask);
  FMOptions := SaveOpt;
  FreeMem(S, SizeOf(String));
end;

function FRenMovPrim(const FromName, ToName: FNameStr): FNameStr;
var
{ Added 05-28-03 to support case-sensitive rename }
  SameNameUC: Boolean;
  B: Byte;
  SD: Char;
  FromAttr, ToAttr: Word;
  SaveOpt, FromSize, FromTime, ToSize, ToTime, SplitCount: Longint;
  RenSize: Real;
  F: ^lFile;
  DiskFromName, DiskToName, CurToName, ShortName: FNameStr;

function GetNewToName: Boolean;
var
  C: Word;
  D: PDialog;
  R: TRect;
  FN: FNameStr;
  CopyNameData: TCopyNameData;
begin
  CopyNameData.ToName := CurToName;
  CopyNameData.Options := Byte(FileCopyOptions and fsNT_SysCopy <> 0);
  R.Assign(0, 0, 70, 8);
  D := InitRenMovDialog(
    R, 'Rename or move "' + JustFileName(FromName) + '" to', False, False);
  C := Application^.ExecuteDialog(D, @CopyNameData, True);
  CurToName := CopyNameData.ToName;
  TrimSt(CurToName);
  if (C <> cmCancel) and (CurToName <> '') then
  begin
    if CopyNameData.Options and 1 <> 0 then
      FileCopyOptions := FileCopyOptions or fsNT_SysCopy
    else FileCopyOptions := FileCopyOptions and not fsNT_SysCopy;
    FN := FromName;
    CancelSysErrors := False;
    ValidNames(FN, CurToName);
    GetNewToName := not CancelSysErrors;
  end
  else GetNewToName := False;
end;

label
  ANew, Copy, Skip, Retry;
begin
  FRenMovPrim := '';
  Skipped := True;
  if AbortDiskAction then
  begin
    CopyStatus := dsCancel;
    DeleteStatus := dsCancel;
    Exit;
  end;
  lTrueName(FromName, DiskFromName);
{ Added 2005.08.30 to support regexp file operations }
  if FileRegExp <> nil then
  begin
{ Added 2005.09.29 to avoid loops copying with regexps }
    if (FileCRCList <> nil) and FileCRCList^.NameFound(DiskFromName) then Exit;
    CurToName := FileRegExpNewName(DiskFromName);
    if CurToName = '' then Exit;
  end
  else CurToName := ToName;

{ Added 2005.09.16 to support prompt before file operation }
  if (FileCopyOptions and fsConfirmFileOperation <> 0) and
    not FileOperationConfirmed(DiskFromName, CurToName, faRenMov) then Exit;

{ Added 2005.09.29 to avoid loops copying with regexps }
  if FileRegExp <> nil then AddFileCRCItem(CurToName);

ANew:
  lTrueName(CurToName, DiskToName);
{ Added 05-12-03 to support file splitting }
  if SplitCopy then
  begin
    SplitTruncate := SameDrives(DiskFromName, DiskToName);
    goto Copy;
  end;
{ Added 05-28-03 to support case-sensitive rename }
  SameNameUC := CompUCString(DiskFromName, DiskToName) = Equal;
  if not SameDrives(DiskFromName, DiskToName) then
  begin
Copy:
    MoveCopy := True;
    FCopyPrim(FromName, CurToName);
    MoveCopy := False;
{ Added 05-12-03 to support file splitting }
    if SplitCopy and SplitTruncate then
    begin
      SplitTruncate := False;
      if not CopyOk then Exit;
      SplitCount := 0;
      FormatStr(CurToName, ToName, SplitCount);
      if CurToName = ToName then
        FormatStr(CurToName, ForceExtension(ToName, '%03d'), SplitCount);
      SplitCopy := False;
      goto ANew;
    end;
    if CopyOk then FDeletePrim(FromName)
    else Exit;
  end
  else
  begin
    RenSize := 0;
    if CopyStatWindow <> nil then
    begin
      Find1st(FromName, FromAttr, FromSize, FromTime);
      if DosError = 0 then RenSize := lGetFileRealSize(FromAttr, FromSize);
    end;
    CancelSysErrors := False;
    Find1st(CurToName, ToAttr, ToSize, ToTime);
    if CancelSysErrors then
    begin
      CopyStatus := dsCancel;
      DeleteStatus := dsCancel;
      Exit;
    end;
    if (DosError = 0) and (DeviceDest(CurToName) = '') and
{ Added 05-28-03 to support case-sensitive rename }
      not SameNameUC then
    begin
      if CopyStatus <> dsSkipAll then
      begin
        Find1st(FromName, FromAttr, FromSize, FromTime);
        if DosError <> 0 then CopyStatus := dsSkip
        else if ((CopyStatus = dsAll) and (FileExistsAction <> feCompare)) or
          (CopyStatus in AppendResumeSkipAllSet) then {}
        else
        begin
          B := CopySkipDialog(FromName, CurToName, FromTime, ToTime,
            lGetFileRealSize(FromAttr, FromSize),
            lGetFileRealSize(ToAttr, ToSize));
          if (CopyStatus = dsAll) and (FileExistsAction = feCompare) then
            if B = dsSkip then Goto Skip else
          else CopyStatus := B;
        end;
      end;
      if CopyStatus in [dsSkip, dsSkipAll, dsCancel] then
      begin
Skip:
        SkipFile(FromName, RenSize, 0);
        Exit;
      end;
      if CopyStatus in AppendResumeAllSet then Goto Copy;
      if CopyStatus = dsNew then
      begin
        if not GetNewToName then Goto Skip;
        Goto ANew;
      end;
      CheckRenMovName := True;
      SaveOpt := FMOptions;
      FMOptions := FMOptions and not foCopyDescriptions;
      FDeletePrim(CurToName);
      FMOptions := SaveOpt;
      CheckRenMovName := False;
    end;
    SkipFile(FromName, RenSize, 0);
    if FMOptions and foCopyDescriptions <> 0 then
      lGetShortFileName(FromName, ShortName);
    LogEvent := lcDiskWrite;
    DrawStatusLine('Renaming the file ' +
      JustFileName(FromName) + ' to ' +
      TrimmedName(CurToName, 40) + '.');
    GetMem(F, SizeOf(lFile));
    lAssignFile(F^, DiskFromName);
    CancelSysErrors := False;
    lRenameFile(F^, DiskToName);
    if CancelSysErrors then
    begin
      FreeMem(F, SizeOf(lFile));
      CopyStatus := dsCancel;
      DeleteStatus := dsCancel;
      Exit;
    end;
    if IOResult <> 0 then
    begin
      MkDirPrim(PrevDir(CurToName), nil);
Retry:
      lRenameFile(F^, DiskToName);
      if IOResult <> 0 then
      begin
        if CopyErrorStatus <> deIgnoreAll then
          CopyErrorStatus := DiskErrorDialog('Rename',
            ^C'Could not rename the file'#13^C + TrimmedName(FromName, 62) + '.');
        if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(FromName)
        else if CopyErrorStatus = deCancel then
        begin
          CopyStatus := dsCancel;
          DeleteStatus := dsCancel;
        end
        else goto Retry;
        FreeMem(F, SizeOf(lFile));
        Exit;
      end;
    end;
    FreeMem(F, SizeOf(lFile));
    SendChangeMsg(FromName);
    CheckRenMovName := True;
    SendChangeMsg(CurToName);
    CheckRenMovName := False;
    if FMOptions and foCopyDescriptions <> 0 then
      if CompUCString(PrevDir(FromName), PrevDir(CurToName)) = Equal then
        RenameDescription(FromName, ShortName, CurToName)
      else
      begin
        CopyDescription(FromName, ShortName, CurToName);
        DeleteDescription(FromName, ShortName);
      end;
  end;
  Skipped := False;
  GiveTicks;
  if Clock <> nil then Clock^.Update;
  if TheSpooler <> nil then TheSpooler^.ProcessItems;
  FRenMovPrim := CurToName;
end;

procedure RenMovDirFiles(const FromDir, ToDir, ADir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
var
  SaveOpt: Longint;
  PSR: PSearchRec;
  SR: ^lSearchRec;
  ToDirName, S: PString;
label
  Quit;
begin
  GetMem(ToDirName, SizeOf(String));
  GetMem(S, SizeOf(String));
  GetMem(SR, SizeOf(lSearchRec));
  ToDirName^ := AddedSlash(
    ClearedSlash(ToDir) + System.Copy(ADir, Length(FromDir) + 1, 255));
  CancelSysErrors := False;
{ Added 04.28.03 to support optional avoiding empty directory copy }
  if FileCopyOptions and fsSkipEmptyDirs <> 0 then
  begin
    AddNameAndSlash(ADir, '*.*', False, S^);
    lFindFirst(S^, AnyFile and not VolumeID, SR^);
    while not CancelSysErrors and (DosError = 0) and
      (SR^.SR.Name[1] = '.') do lFindNext(SR^);
    lFindClose(SR^);
    if CancelSysErrors then
    begin
      CopyStatus := dsCancel;
      DeleteStatus := dsCancel;
      Goto Quit;
    end;
    if DosError <> 0 then goto Quit;
  end;
  lFindFirst(ClearedSlash(ADir), AnyFile and not VolumeID, SR^);
  lFindClose(SR^);
  if CancelSysErrors then
  begin
    CopyStatus := dsCancel;
    DeleteStatus := dsCancel;
    Goto Quit;
  end;
  if (DosError = 0) and (SR^.SR.Attr and Directory <> 0) then
    PSR := @SR^.SR else PSR := nil;
  if FoundInCRCList(ClearedSlash(ToDirName^), ACRCList) then
    MkDirPrim(ToDirName^, PSR);
  if CopyStatus = dsCancel then Goto Quit;
  SaveOpt := FMOptions;
  if AFilter = '*.*' then FMOptions := FMOptions and not foCopyDescriptions;
  CancelSysErrors := False;
  lFindFirst(ADir + AFilter, AnyFile and not VolumeID, SR^);
  if CancelSysErrors then
  begin
    CopyStatus := dsCancel;
    DeleteStatus := dsCancel;
  end;
  while (DosError = 0) and (CopyStatus <> dsCancel) and
    (DeleteStatus <> dsCancel) do
  begin
    if (SR^.SR.Attr and (VolumeID + Directory) = 0) and
       (UCPos(FromDir, ADir) <> 0) then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(ADir, SR^.FullName, False, S^)
      else AddNameAndSlash(ADir, SR^.SR.Name, False, S^);
      if FoundInCRCList(S^, ACRCList) and
         CopyRenameFilterPassed(SR^.SR, SR^.FullName) then
        if SR^.FullName <> '' then
          FRenMovPrim(S^, ToDirName^ +
            NewName(ToDirName^, SR^.FullName, AMask))
        else FRenMovPrim(S^, ToDirName^ +
          NewName(ToDirName^, SR^.SR.Name, AMask));
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FMOptions := SaveOpt;
Quit:
  FreeMem(SR, SizeOf(lSearchRec));
  FreeMem(S, SizeOf(String));
  FreeMem(ToDirName, SizeOf(String));
end;

procedure RenMovDirs(const FromDir, ToDir, ADir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
var
  SaveOpt: Longint;
  S: PString;

procedure DoRenMovDirs(const FromDir, ToDir: FNameStr;
  ADir: PString; const AFilter, AMask: FNameStr);
var
  SR: ^lSearchRec;
  Dir: PString;
begin
  if StackOverflow then
  begin
    CopyStatus := dsCancel;
    DeleteStatus := dsCancel;
    Exit;
  end;
  Dir := NewStr(ADir^);
  GetMem(SR, SizeOf(lSearchRec));
  AddNameAndSlash(Dir^, '*.*', False, S^);
  CancelSysErrors := False;
  lFindFirst(S^, $17, SR^);
  if CancelSysErrors then
  begin
    CopyStatus := dsCancel;
    DeleteStatus := dsCancel;
  end;
  while (DosError = 0) and (CopyStatus <> dsCancel) and
    (DeleteStatus <> dsCancel) do
  begin
    if (SR^.SR.Attr and Directory <> 0) and (SR^.SR.Name[1] <> '.') then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(Dir^, SR^.FullName, True, S^)
      else AddNameAndSlash(Dir^, SR^.SR.Name, True, S^);
{ Added 04.17.03 to support directory recursive copy/move }
      if not DirCRCListInUse or (DirCRCList = nil) or
         not DirCRCList^.NameFound(S^) then
      begin
        RenMovDirFiles(FromDir, ToDir, S^, AFilter, AMask, ACRCList);
        if (CopyStatus <> dsCancel) and (DeleteStatus <> dsCancel) then
          DoRenMovDirs(FromDir, ToDir, S, AFilter, AMask);
      end;
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  GetMem(S, SizeOf(String));
  SaveOpt := FMOptions;
  FMOptions := FMOptions and not foForceUpperDirs;
  if SaveOpt and foForceUpperDirs <> 0 then
    DoRenMovDirs(FromDir, OptUpcaseDir(FromDir, ToDir), @ADir, AFilter, AMask)
  else DoRenMovDirs(FromDir, ToDir, @ADir, AFilter, AMask);
  FMOptions := SaveOpt;
  FreeMem(S, SizeOf(String));
end;

procedure DirRenameFiles(const ADir, AFilter, AMask: FNameStr;
  ACRCList: PTagList);
var
  SaveOpt: Longint;
  SR: ^lSearchRec;
  S: PString;
begin
  SaveOpt := FMOptions;
  if AFilter = '*.*' then FMOptions := FMOptions and not foCopyDescriptions;
  CancelSysErrors := False;
  GetMem(S, SizeOf(String));
  GetMem(SR, SizeOf(lSearchRec));
  lFindFirst(ADir + AFilter, AnyFile and not VolumeID, SR^);
  if CancelSysErrors then
  begin
    CopyStatus := dsCancel;
    DeleteStatus := dsCancel;
  end;
  while (DosError = 0) and (CopyStatus <> dsCancel) and
    (DeleteStatus <> dsCancel) do
  begin
    if SR^.SR.Attr and (VolumeID + Directory) = 0 then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(ADir, SR^.FullName, False, S^)
      else AddNameAndSlash(ADir, SR^.SR.Name, False, S^);
      if FoundInCRCList(S^, ACRCList) and
         CopyRenameFilterPassed(SR^.SR, SR^.FullName) then
        if SR^.FullName <> '' then
          FRenMovPrim(S^, ADir +
            NewName(ADir, SR^.FullName, AMask))
        else FRenMovPrim(S^, ADir +
          NewName(ADir, SR^.SR.Name, AMask));
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  FreeMem(S, SizeOf(String));
  FMOptions := SaveOpt;
end;

procedure RenameFilesByMask(const ADir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
var
  SaveOpt: Longint;
  S: PString;

procedure DoRenameByMask(ADir: PString; const AFilter, AMask: FNameStr);
var
  SR: ^lSearchRec;
  Dir: PString;
label
  Quit;
begin
  if StackOverflow then
  begin
    CopyStatus := dsCancel;
    DeleteStatus := dsCancel;
    Exit;
  end;
  DrawStatus(ADir^);
  GiveTicks;
  if Clock <> nil then Clock^.Update;
  if TheSpooler <> nil then TheSpooler^.ProcessItems;
  if (CopyStatus = dsCancel) or (DeleteStatus = dsCancel) then Exit;
  DirRenameFiles(ADir^, AFilter, AMask, ACRCList);
  if (CopyStatus = dsCancel) or (DeleteStatus = dsCancel) then Exit;
  Dir := NewStr(ADir^);
  GetMem(SR, SizeOf(lSearchRec));
  AddNameAndSlash(Dir^, '*.*', False, S^);
  CancelSysErrors := False;
  lFindFirst(S^, $17, SR^);
  if CancelSysErrors then
  begin
    CopyStatus := dsCancel;
    DeleteStatus := dsCancel;
  end;
  while (DosError = 0) and (CopyStatus <> dsCancel) and
    (DeleteStatus <> dsCancel) do
  begin
    if AbortDiskAction then
    begin
      CopyStatus := dsCancel;
      DeleteStatus := dsCancel;
      GoTo Quit;
    end;
    if (SR^.SR.Attr and Directory <> 0) and (SR^.SR.Name[1] <> '.') then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(Dir^, SR^.FullName, True, S^)
      else AddNameAndSlash(Dir^, SR^.SR.Name, True, S^);
      DoRenameByMask(S, AFilter, AMask);
    end;
    lFindNext(SR^);
  end;
Quit:
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  GetMem(S, SizeOf(String));
  SaveOpt := FMOptions;
  FMOptions := FMOptions and not foForceUpperDirs;
  DoRenameByMask(@ADir, AFilter, AMask);
  FMOptions := SaveOpt;
  FreeMem(S, SizeOf(String));
end;

procedure DirMoveFiles(const FromDir, ToDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
var
  SaveOpt: Longint;
  SR: ^lSearchRec;
  S: PString;
begin
  SaveOpt := FMOptions;
  if AFilter = '*.*' then FMOptions := FMOptions and not foCopyDescriptions;
  CancelSysErrors := False;
  GetMem(S, SizeOf(String));
  GetMem(SR, SizeOf(lSearchRec));
  lFindFirst(FromDir + AFilter, AnyFile and not VolumeID, SR^);
  if CancelSysErrors then
  begin
    CopyStatus := dsCancel;
    DeleteStatus := dsCancel;
  end;
  while (DosError = 0) and (CopyStatus <> dsCancel) and
    (DeleteStatus <> dsCancel) do
  begin
    if SR^.SR.Attr and (VolumeID + Directory) = 0 then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(FromDir, SR^.FullName, False, S^)
      else AddNameAndSlash(FromDir, SR^.SR.Name, False, S^);
      if FoundInCRCList(S^, ACRCList) and
         CopyRenameFilterPassed(SR^.SR, SR^.FullName) then
        if SR^.FullName <> '' then
          FRenMovPrim(S^, AddedSlash(ToDir) +
            NewName(ToDir, SR^.FullName, AMask))
        else FRenMovPrim(S^, AddedSlash(ToDir) +
          NewName(ToDir, SR^.SR.Name, AMask));
    end;
    lFindNext(SR^);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  FreeMem(S, SizeOf(String));
  FMOptions := SaveOpt;
end;

procedure MoveFilesByMask(const FromDir, ToDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList);
var
  SaveOpt: Longint;
  S: PString;

procedure DoMoveByMask(FromDir: PString;
  const ToDir, AFilter, AMask: FNameStr);
var
  SR: ^lSearchRec;
  Dir: PString;
label
  Quit;
begin
  if StackOverflow then
  begin
    CopyStatus := dsCancel;
    DeleteStatus := dsCancel;
    Exit;
  end;
  DrawStatus(FromDir^);
  GiveTicks;
  if Clock <> nil then Clock^.Update;
  if TheSpooler <> nil then TheSpooler^.ProcessItems;
  if (CopyStatus = dsCancel) or (DeleteStatus = dsCancel) then Exit;
  DirMoveFiles(FromDir^, ToDir, AFilter, AMask, ACRCList);
  if (CopyStatus = dsCancel) or (DeleteStatus = dsCancel) then Exit;
  Dir := NewStr(FromDir^);
  GetMem(SR, SizeOf(lSearchRec));
  AddNameAndSlash(Dir^, '*.*', False, S^);
  CancelSysErrors := False;
  lFindFirst(S^, $17, SR^);
  if CancelSysErrors then
  begin
    CopyStatus := dsCancel;
    DeleteStatus := dsCancel;
  end;
  while (DosError = 0) and (CopyStatus <> dsCancel) and
    (DeleteStatus <> dsCancel) do
  begin
    if AbortDiskAction then
    begin
      CopyStatus := dsCancel;
      DeleteStatus := dsCancel;
      GoTo Quit;
    end;
    if (SR^.SR.Attr and Directory <> 0) and (SR^.SR.Name[1] <> '.') then
    begin
      if SR^.FullName <> '' then
        AddNameAndSlash(Dir^, SR^.FullName, True, S^)
      else AddNameAndSlash(Dir^, SR^.SR.Name, True, S^);
      DoMoveByMask(S, ToDir, AFilter, AMask);
    end;
    lFindNext(SR^);
  end;
Quit:
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  GetMem(S, SizeOf(String));
  MkDirPrim(ToDir, nil);
  SaveOpt := FMOptions;
  FMOptions := FMOptions and not foForceUpperDirs;
  DoMoveByMask(@FromDir, ToDir, AFilter, AMask);
  FMOptions := SaveOpt;
  FreeMem(S, SizeOf(String));
end;

procedure DirRenMovPrim(const FromDir, DestDir,
  AFilter, AMask: FNameStr; ACRCList: PTagList;
  DoRemove: Boolean);
var
  EndSlash, IsWithin: Boolean;
  SaveOpt: Longint;
  ToDir: FNameStr;
  F: ^lFile;
label
  Retry1, Retry2;
begin
  Skipped := True;
  ToDir := DestDir;
  if (CompUCString(FromDir, ToDir) = Equal) and
     (CompUCString(AFilter, AMask) <> Equal) then
    RenameFilesByMask(AddedSlash(FromDir), AFilter, AMask, ACRCList)
  else
  begin
{ Added 2005.09.16 to support prompt before file operation }
  if (FileCopyOptions and fsConfirmFileOperation <> 0) and
     (CompUCString(PrevDir(FromDir), ToDir) <> Equal) and
    not FileOperationConfirmed(FromDir, ToDir, faRenMov) then Exit;

{ Added 04.17.03 to support directory recursive copy/move }
    if FileCopyOptions and fsEnableRecursive <> 0 then AddDirCRCItem(ToDir);
Retry1:
    if DirWithin(FromDir, ToDir, EndSlash) and EndSlash then
    begin
      if (FileCopyOptions and fsEnableRecursive = 0) and (FileRegExp = nil) then
      begin
        if CopyErrorStatus <> deIgnoreAll then
          CopyErrorStatus := DiskErrorDialog('Move',
            ^C'Can''t move a directory to itself:'#13^C + TrimmedName(FromDir, 62) + '.');
        if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(FromDir)
        else if CopyErrorStatus = deCancel then
        begin
          CopyStatus := dsCancel;
          DeleteStatus := dsCancel;
        end
        else goto Retry1;
        Exit;
      end;
      DirCRCListInUse := True;
      IsWithin := True;
    end
    else IsWithin := False;
{ Added 2005.08.30 to support regexp file operations }
    if DoRemove and (FileRegExp = nil) and
      (CompUCString(PrevDir(FromDir), PrevDir(ToDir)) = Equal) and
      (Length(ToDir) > 3) and (ToDir[1] <> '\') then
    begin
      if DirPresent(ToDir) and (CompUCString(FromDir, ToDir) <> Equal) then
      begin
        if (MessageBox(^C'Replace the existing directory'#13^C'|' +
            ToDir + '| ?', nil, mfConfirmation + mfOkCancel) <> cmOk) or
           (MessageBox(^C'The contents of the old directory'#13^C'|' +
            ToDir + '|'#13^C'will be erased. Continue ?',
            nil, mfConfirmation + mfOkCancel) <> cmOk) then
        begin
          CopyStatus := dsCancel;
          DeleteStatus := dsCancel;
          Exit;
        end;
        DirDeletePrim(ToDir, nil, True, False);
      end;
      LogEvent := lcDiskWrite;
      DrawStatusLine('Renaming the directory ' +
        TrimmedName(FromDir, 25) + ' to ' + TrimmedName(ToDir, 25) + '.');
      GetMem(F, SizeOf(lFile));
      lAssignFile(F^, FromDir);
      if FMOptions and foForceUpperDirs <> 0 then
        lRenameFile(F^, StUpcase(ToDir))
      else lRenameFile(F^, ToDir);
      if IOResult <> 0 then
      begin
        MkDirPrim(PrevDir(ToDir), nil);
Retry2:
        if FMOptions and foForceUpperDirs <> 0 then
          lRenameFile(F^, StUpcase(ToDir))
        else lRenameFile(F^, ToDir);
        if IOResult <> 0 then
        begin
          if CopyErrorStatus <> deIgnoreAll then
            CopyErrorStatus := DiskErrorDialog('Rename',
              ^C'Could not rename the directory'#13^C + TrimmedName(FromDir, 62) + '.');
          if CopyErrorStatus in [deIgnore, deIgnoreAll] then DrawSkipStatus(FromDir)
          else if CopyErrorStatus = deCancel then
          begin
            CopyStatus := dsCancel;
            DeleteStatus := dsCancel;
          end
          else goto Retry2;
          FreeMem(F, SizeOf(lFile));
          Exit;
        end;
      end;
      FreeMem(F, SizeOf(lFile));
      SendChangeMsg(FromDir);
      SendChangeMsg(FromDir + '\1');
      RenameDirInTree(FromDir, ToDir);
    end
    else
    begin
      SaveOpt := FMOptions;
      FMOptions := FMOptions and not foForceUpperDirs;
      if SaveOpt and foForceUpperDirs <> 0 then
        RenMovDirFiles(FromDir, OptUpcaseDir(FromDir, ToDir),
          AddedSlash(FromDir), AFilter, AMask, ACRCList)
      else RenMovDirFiles(FromDir, ToDir, AddedSlash(FromDir),
        AFilter, AMask, ACRCList);
      FMOptions := SaveOpt;
      if (CopyStatus <> dsCancel) and
         (DeleteStatus <> dsCancel) then
        RenMovDirs(FromDir, ToDir, AddedSlash(FromDir),
          AFilter, AMask, ACRCList)
      else Exit;
      if (CopyStatus = dsCancel) or (DeleteStatus = dsCancel) then Exit;
      SaveOpt := FMOptions;
      FMOptions := FMOptions and not foDirDelPrompt;
{ Added 04.17.03 to support directory recursive copy/move }
      if DoRemove and not IsWithin then
        DirDeletePrim(FromDir, ACRCList, False, False)
      else ClearDirs(AddedSlash(FromDir), ACRCList, False, False);
      FMOptions := SaveOpt;
    end;
  end;
  Skipped := False;
end;

function GetDirInfo(const ADir: FNameStr;
  var NumFiles, NumTagged, NumSubDirs: Longint;
  var FilesSize, NumBytes, TaggedSize, TaggedBytes,
  Compressed, TaggedCompressed: Real;
  CalcTagged, AllowTree, KeyAbort: Boolean): Boolean;
var
  Abort, Store, OutOfMem: Boolean;
  I, DirIndex: Integer;
  ClusterSize, CFileSizeLo, CFileSizeHi: Longint;
  RealSize, R: Real;
  T: PTreeCollection;
  S, StartDir: FNameStr;

procedure UpdateTree(const ADir: FNameStr; ASize: Longint);
var
  AD: FNameStr;
begin
  AD := ClearedSlash(ADir);
  I := T^.GetDirNum(AD, DirIndex, MaxInt);
  if (I >= T^.Count) and AllowTree then
  begin
    if not AddDirToTreePrim(ShortFileName(AD), AD, T, OutOfMem) then Exit;
    I := T^.GetDirNum(AD, DirIndex, MaxInt);
  end;
  if I < T^.Count then
  begin
    PTreeRec(T^.At(I))^.Size := ASize;
    Store := True;
  end;
end;

procedure SetTaggedName(const DirS, NameS: FNameStr);
begin
  AddNameAndSlash(DirS, NameS, False, S);
end;

procedure ScanDirs(ADir: PString);
var
  SaveSize: Real;
  SR: ^lSearchRec;
  Dir: PString;
begin
  if StackOverflow then
  begin
    Abort := True;
    Exit;
  end;
  Dir := NewStr(ADir^);
  GetMem(SR, SizeOf(lSearchRec));
  DrawStatus(Dir^);
  GiveTicks;
  if Clock <> nil then Clock^.Update;
  if TheSpooler <> nil then TheSpooler^.ProcessItems;
  UpdateRoller;
  SaveSize := FilesSize;
  AddNameAndSlash(Dir^, '*.*', False, S);
  lFindFirst(S, AnyFile and not VolumeID, SR^);
  while (DosError = 0) and not Abort do
  begin
    if SR^.SR.Attr and Directory = 0 then
    begin
      Inc(NumFiles);
      RealSize := lGetFileRealSize(SR^.SR.Attr, SR^.SR.Size);
      FilesSize := FilesSize + RealSize;
      R := lGetFileRealSpace(SR^.SR.Attr, SR^.SR.Size, ClusterSize);
      NumBytes := NumBytes + R;
      if CN_NT then
      begin
        NT_GetCompFileSize(Dir^ + SR^.SR.Name, CFileSizeLo, CFileSizeHi);
        if CFileSizeLo < 0 then Compressed := Compressed + RealSize
        else Compressed := Compressed + CFileSizeLo;
      end;
      if CalcTagged then
      begin
        if SR^.FullName <> '' then SetTaggedName(Dir^, SR^.FullName)
        else SetTaggedName(Dir^, SR^.SR.Name);
        repeat
          if TagList^.NameFound(S) then
          begin
            Inc(NumTagged);
            TaggedSize := TaggedSize + RealSize;
            TaggedBytes := TaggedBytes + R;
            if CN_NT then
              if CFileSizeLo < 0 then
                TaggedCompressed := TaggedCompressed + RealSize
              else TaggedCompressed := TaggedCompressed + CFileSizeLo;
            Break;
          end;
          S := PrevDir(S);
        until Length(S) <= 2;
      end;
    end
    else if SR^.SR.Name[1] <> '.' then
    begin
      Inc(NumSubDirs);
      if SR^.FullName <> '' then
        AddNameAndSlash(Dir^, SR^.FullName, True, S)
      else AddNameAndSlash(Dir^, SR^.SR.Name, True, S);
      ScanDirs(@S);
    end;
    lFindNext(SR^);
    if ((KbdStatus = 1) and FMAbortAction) or
       (KeyAbort and KeyPressed) then Abort := True;
  end;
  lFindClose(SR^);
  if not Abort and (T <> nil) and (FilesSize - SaveSize < MaxLongint) then
    UpdateTree(Dir^, Trunc(FilesSize - SaveSize));
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  NumFiles := 0;
  FilesSize := 0;
  NumBytes := 0;
  NumTagged := 0;
  NumSubDirs := 0;
  TaggedSize := 0;
  TaggedBytes := 0;
  Compressed := 0;
  TaggedCompressed := 0;
  CancelSysErrors := False;
{  ClusterSize := GetClusterSize(Byte(ADir[1]) - $40);}
  ClusterSize := GetClusterSize(ADir);
  Abort := CancelSysErrors;
  if not Abort then
  begin
    Store := False;
    LoadTree(RootName(ADir), T);
    if T <> nil then DirIndex := T^.GetDirNum(ADir, 0, 0);
    StartDir := AddedSlash(ADir);
    InitRoller;
    ScanDirs(@StartDir);
    DoneRoller;
    if T <> nil then
    begin
      if not Abort and Store then StoreTree(RootName(ADir), T);
      Dispose(T, Done);
    end;
  end;
  GetDirInfo := not Abort;
end;

end.