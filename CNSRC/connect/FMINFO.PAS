{$I-,F+,O+,X+}
unit FMInfo;

interface

uses FileMngr;

procedure ReadInfoPrim(FManager: PPanel; NextDirinfo: Boolean);
{ Added 04.29.03 to support directory size display on Space pressed }
procedure SpaceSelectFocusedPrim(FManager: PPanel);
{ Added 04.03.07 to support decoders }
procedure DecodePanelPrim(FManager: PPanelWindow; const FileName: String);

implementation

uses Dos, Objects, Drivers, Views, PanelRec, FMAbort, ArcV, {Archives,}
  EditFile, DirPrim, DiskPrim, Disks, HeapUMB, LFN, DosTools, Keyboard,
  SysInfo, TPString, Commands, Defaults;

(*
type
  PArcDirInfo = ^TArcDirInfo;
  TArcDirInfo = record
    Name: PString;
    Dir: PString;
    Panel: PPanel;
  end;

procedure ArchiveLineInfo(ALine: FNameStr; Time, OrgSize, Size: Longint);
begin
  if (KbdStatus = 1) and FMAbortAction then ArcEnd := True;
  if (ALine = '') or (TPString.Upcase(ALine[1]) in ['D', 'U']) then Exit;
  if ALine[Length(ALine)] = '\' then Dec(ALine[0]);
  ALine[1] := '\';
  if (Length(ALine) >= 3) and (ALine[2] = '.') and (ALine[3] = '\') then
    Delete(ALine, 2, 2);
  with PArcDirInfo(ArchiveInfoPtr)^ do
    if JustPathName(Name^ + ALine) = Dir^ then
    begin
      Panel^.ByteCount := Panel^.ByteCount + Size;
      Inc(Panel^.FileCount);
    end;
end;

procedure ArchiveReadInfoPrim(FManager: PPanel;
  const DosName, ArcName, Dir: FNameStr);
var
  Id, Status: Byte;
  P: PArcDirInfo;
  SR: SearchRec;
begin
  ArchiveLineProc := ArchiveLineInfo;
  ArchiveCommentList := FManager^.Dirinfo;
  GetMem(P, SizeOf(TArcDirInfo));
  P^.Name := @ArcName;
  P^.Dir := @Dir;
  P^.Panel := FManager;
  ArchiveInfoPtr := P;
  ReadArchive(DosName, Id, SR, Status);
  if (Status = arcNotIdentified) and FManager^.Opposite^.InArchive then
  begin
    TheArchiver := FManager^.Opposite^.Archiver;
    ReadUserArchive(DosName, Id, False, True, False, Status);
  end;
  FreeMem(P, SizeOf(TArcDirInfo));
end;
*)

procedure ReadInfoPrim(FManager: PPanel; NextDirinfo: Boolean);
var
  I: Integer;
  DiskType: DiskClass;
  ClusterSize: Longint;
  SR: ^lSearchRec;
  F: ^lText;
  Rec: ^TSysinfoRec;
  R: TExtDiskInfoRec;
  DN: String[63];
  S, SS: String;

function XMStrToLong(const XS: String): Longint;
var
  I: Integer;
  L: Longint;
begin
  L := 0;
  I := Pos(' ', XS);
  if I <> 0 then Val(Copy(XS, 1, I - 1), L, I);
  XMStrToLong := L;
end;

begin
  with FManager^ do
  begin
    Opposite^.GetListDir(S);
    FailSysErrors := True;
{
    TotalBytes := FDiskSize(Byte(S[1]) - $40);
    BytesFree := FDiskFree(Byte(S[1]) - $40);
    ClusterSize := GetClusterSize(Byte(S[1]) - $40);
}
    TotalBytes := FDiskSize(S);
    BytesFree := FDiskFree(S);
    ClusterSize := GetClusterSize(S);

    SS := RootName(S);
    ExtDiskInfo := '~' + SS + '~';
    if not DisableSysInfo then
    begin
      GetMem(SR, SizeOf(lSearchRec));
      FindFirst(SS + '\*.*', VolumeID, SR^.SR);
      if DosError = 0 then
      begin
	SS := Trim(SR^.SR.Name);
	I := Pos('.', SS);
	if I <> 0 then Delete(SS, I, 1);
	if SS <> '' then ExtDiskInfo := ExtDiskInfo + ' ' + SS;
      end;
      FreeMem(SR, SizeOf(lSearchRec));
    end;
    if S[1] = '\' then ExtDiskInfo := 'Network resource: ' + ExtDiskInfo
    else
    begin
      if GetExtDiskInfo(S[1], R) then
      begin
	if Trim(R.FileSystem) <> '' then ExtDiskInfo := ExtDiskInfo +
	  ' (' + Trim(R.FileSystem) + ')';
	{if R.SerialNumber <> 0 then} ExtDiskInfo := ExtDiskInfo + ' s/n ~' +
	  HexW(LongRec(R.SerialNumber).Hi) + '-' +
	  HexW(LongRec(R.SerialNumber).Lo) + '~';
      end
      else
      begin
	ClassifyDrive(S[1], DiskType);
	ExtDiskInfo := ExtDiskInfo + ' ' + GetDiskDescription(DiskType);
      end;
    end;
    LongVolumeLabel := NT_GetVolumeLabel(AddedSlash(RootName(S)));
    FillChar(FileCount, SizeOf(Longint) * 2 + SizeOf(Real), 0);
    DN := DirinfoName;
    DirinfoName := '';
(*
    if Opposite^.InArchive then ArchiveReadInfoPrim(FManager,
      Opposite^.Archiver^.DosName^, Opposite^.Archiver^.ArcName^, S)
*)
    if Opposite^.InArchive then
    begin
      Opposite^.GetDirCounts;
      Move(Opposite^.FileCount, FileCount,
	SizeOf(Longint) * 2 + SizeOf(Real));
    end
    else
    begin
      GetMem(SR, SizeOf(lSearchRec));
      lFindFirst(S + '\*.*', AnyFile and not VolumeID, SR^);
      FailSysErrors := False;
      while DosError = 0 do
      begin
	if SR^.SR.Attr and Directory = 0 then
	begin
	  Inc(FileCount);
	  ByteCount := ByteCount + lGetFileRealSpace(
	    SR^.SR.Attr, SR^.SR.Size, ClusterSize);
	end
	else if SR^.SR.Name[1] <> '.' then Inc(DirCount);
	lFindNext(SR^);
      end;
      lFindClose(SR^);
      FreeMem(SR, SizeOf(lSearchRec));
      Inc(S[0]);
      S[Length(S)] := '\';
      if NextDirinfo and (DN <> '') then
      begin
	SS := S;
	SetNextFoundName(DirinfoNames, DN, S);
	if (S = '') or not ThisFileExists(S) then
	begin
	  S := SS;
	  SetFirstFoundName(DirinfoNames, S);
        end;
      end
      else SetFirstFoundName(DirinfoNames, S);
      if S <> '' then
      begin
	GetMem(F, SizeOf(lText));
	lAssignText(F^, S);
	FailSysErrors := True;
	Reset(F^.T);
	FailSysErrors := False;
	if IOResult = 0 then
	begin
	  if not IsDevice(TextRec(F^.T).Handle) then
	    while not Eof(F^.T) and (Dirinfo^.Count < 255) do
	    begin
	      Readln(F^.T, SS);
	      SS := Detab(SS, 8);
	      TrailTrim(SS);
{             Dirinfo^.Insert(NewStr(SS));}
	      Dirinfo^.Insert(NewStrUMB(SS));
	    end;
	  Close(F^.T);
	  InOutRes := 0;
	end;
	FreeMem(F, SizeOf(lText));
	if Dirinfo^.Count <> 0 then
	begin
          lGetLongFileName(S, S);
          DirinfoName := JustFileName(S);
        end;
      end;
    end;
    UpdateDirinfoRanges;

    FillChar(EMSTotal, SizeOf(Longint) * 4, 0);
    if not DisableSysInfo then
    begin
      GetMem(Rec, SizeOf(TSysinfoRec));
      Rec^.InfoCount := $FF;
      GetSysInfo(Rec^);
      with Rec^ do
      begin
	EMSTotal := XMStrToLong(EMS_Total);
	EMSAvail := XMStrToLong(EMS_Available);
	XMSTotal := XMStrToLong(XMS_Total);
	XMSAvail := XMStrToLong(XMS_Available);
      end;
      FreeMem(Rec, SizeOf(TSysinfoRec));
    end;

{
    PPanelWindow(Owner)^.GetCurrentPanel;
    if (State and (sfSelected + sfActive) = (sfSelected + sfActive)) or
       (PPanelWindow(Owner)^.CurrentPanel = FManager) then
      Message(Owner, evBroadcast, cmNewPrompt, @S)
    else
}

    PWindow(Owner)^.Frame^.DrawView;
  end;
end;

{ Added 04.29.03 to support directory size display on Space pressed }
procedure SpaceSelectFocusedPrim(FManager: PPanel);
var
  All, Sel: Boolean;
  W: Word;
  I, ILo, IHi: Integer;
  NumF, NumSel, NumSD, NumS_, NumB_, SelS_, SelB_, SaveOpt: Longint;
  NumS, NumB, SelS, SelB, Cmpr, SelC: Real;
  SR: PPanelRec;
  S: FNameStr;
begin
  W := GetShiftState;
  All := W and (kbLeftShift + kbRightShift + kbCtrlShift) <> 0;
  Sel := W and (kbLeftShift + kbRightShift) <> 0;
  with FManager^ do
  begin
    if (Status <= stTree) and (FMOptions and foSpaceSizes <> 0) and
       (List^.Count <> 0) then
    begin
      if All then
      begin
        ILo := 0;
        IHi := List^.Count - 1;
      end
      else
      begin
        ILo := Focused;
        IHi := Focused;
      end;
      for I := ILo to IHi do
      begin
        SR := List^.At(I);
        if (SR^.Attr and Directory <> 0) and (SR^.Attr and VolumeID = 0) and
          not (SR^.Name[1] in [':', '.']) then
        begin
          GetItemStr(I, S);
          if InArchive then
            if Archiver^.GetDirInfo(S, NumF, NumS_, NumB_,
              NumSel, SelS_, SelB_, NumSD, False) then SR^.Size := NumB_ else Break
          else if GetDirInfo(S, NumF, NumSel, NumSD, NumS, NumB, SelS, SelB, Cmpr, SelC,
            False, Settings and seList = 0, False) then
{ Added 04.30.03 to support size in KB }
              if NumS >= SizeInKB then
              begin
                SR^.Size := Trunc(NumS / OneKB);
                SR^.Attr := SR^.Attr or faSizeInKB;
              end
              else SR^.Size := Trunc(NumS)
          else Break;
          if SR^.Attr and faDisplaySize = 0 then
          begin
            SR^.Attr := SR^.Attr or faDisplaySize;
            ByteCount := ByteCount + lGetFileRealSize(SR^.Attr, SR^.Size);
            if SR^.Selected then SelByteCount := SelByteCount +
              lGetFileRealSize(SR^.Attr, SR^.Size);
          end;
          if Sel then SetSelect(SR, True);
        end;
      end;
    end;
    SaveOpt := FMOptions;
    if FMOptions and foSpaceMovesDown = 0 then
      FMOptions := FMOptions and not foInsMovesDown;
    if FMOptions and foSpaceSelects <> 0 then SelectFocused
    else FocusItem(Focused);
    FMOptions := SaveOpt;
  end;
end;

{ Added 04.03.07 to support decoders }
procedure DecodePanelPrim(FManager: PPanelWindow; const FileName: String);
var
  B, C: Boolean;
  I, J: Integer;
  P: PString;
  SR: PPanelRec;
  PS: PFilesBBSRec;
  XLATTable: ConvertTable;
begin
  B := ReadConvertTable(XLATTable, FileName, C);
  FManager^.GetCurrentPanel;
  with FManager^.CurrentPanel^ do if not B then ReReadPrim(False)
  else
  begin
    if Dirinfo^.Count <> 0 then
      for I := 0 to Dirinfo^.Count - 1 do
      begin
        P := Dirinfo^.At(I);
        if (P <> nil) and (P^ <> '') then
          for J := 1 to Length(P^) do
            P^[J] := XLATTable[P^[J]];
      end
    else
    begin
      for I := 0 to List^.Count - 1 do
      begin
        SR := List^.At(I);
        for J := 1 to Length(SR^.Name) do
          SR^.Name[J] := XLATTable[SR^.Name[J]];
        for J := 1 to Length(SR^.Ext) do
          SR^.Ext[J] := XLATTable[SR^.Ext[J]];
        if PanelRecHasPath(SR) then
          for J := 1 to Length(SR^.ThePath^) do
            SR^.ThePath^[J] := XLATTable[SR^.ThePath^[J]];
      end;
      for I := 0 to FilesBBS^.Count - 1 do
      begin
        PS := FilesBBS^.At(I);
        if (PS <> nil) and (PS^.Text <> nil) then
          for J := 1 to Length(PS^.Text^) do
            PS^.Text^[J] := XLATTable[PS^.Text^[J]];
      end;
    end;
    FocusItem(Focused);
  end;
end;

end.