{$I-,F+,O+,X+}
unit FMAction;

interface

uses Objects, Drivers, ProgList, FileMngr;

const
  SelListIncludeEmptyDirs: Boolean = True;

procedure GetExecRecPrim(FManager: PPanel; var Rec: TExecRec);
procedure TreeItemSelectedPrim(FManager: PPanel; Item: Integer);
procedure ItemSelectedPrim(FManager: PPanel; Item: Integer);
procedure FMOpenPrim(FManager: PPanel; ACommand: Word);
procedure GetDirViewLines(FManager: PPanel; AWidth: Integer;
  const S: FNameStr; NumFiles, NumTagged, NumSubDirs: Longint;
  FilesSize, NumBytes, TaggedSize, TaggedBytes,
  Compressed, TaggedCompressed: Real; var DirS, NumFilesS, FilesS,
  NumTaggedS, TaggedS, CmprS, TaggedCmprS, NumSubDirsS: FNameStr);
procedure FMViewPrim(FManager: PPanel; ACommand: Word);
procedure FMViewNextPrim(FManager: PPanel; var Event: TEvent);
function AreDirs(FManager: PPanel; Single: Boolean): Boolean;
procedure AppendSelListPrim(FManager: PPanel;
  const Name, Mask, Fmt: FNameStr; Long, Full, SelOnly: Boolean);

implementation

uses Dos, Views, Dialogs, Memory, App, MsgBox, PanelRec, Disks, DirPrim,
  DiskPrim, ExecPrim, Archives, History, FMAbort, FMBBS, FMDialog, FMInfo,
  FMList, FMSecond, Tags, EditMsg, LFN, Keyboard, DosTools, Gauges, TPString,
  TPDate, Consts, Commands, Defaults;

procedure GetExecRecPrim(FManager: PPanel; var Rec: TExecRec);
var
  Key: Word;
  SR: PPanelRec;
  Ext: String[3];
  Name: FNameStr;
begin
  with FManager^ do
  begin
    SR := PPanelRec(List^.At(Focused));
    AddNameExt('', SR, Name);
    Key := GetShiftState;
    if Key and kbAltShift <> 0 then
      if Key and kbCtrlShift <> 0 then Key := 0
      else Key := 1
    else if Key and (kbLeftShift + kbRightShift) <> 0 then Key := 2
    else Key := 0;
    if ExtractExecRec(Rec, Name, Key, False) then Exit;
    FillChar(Rec, SizeOf(TExecRec), 0);
    Ext := StUpcase(SR^.Ext);
    if (Ext <> 'BAT') and (Ext <> 'COM') and (Ext <> 'EXE') then Exit;
    GetSource(Rec.Path);
    if Pos(' ', Rec.Path) <> 0 then
    begin
{ Added 2005.10.21 to avoid quoted "long name with space" exec problems under WinNT }
      lGetShortFileName(Rec.Path, Rec.Path);
      if Pos(' ', Rec.Path) <> 0 then
      begin
        Rec.Path := '"' + Rec.Path + '"';
        Opt := Opt or opLoadCOMMANDCOM;
      end;
    end;
    Move(Main, Rec.Main, SizeOf(Word) * 3);
  end;
end;

procedure TreeItemSelectedPrim(FManager: PPanel; Item: Integer);
var
  SameArchive: Boolean;
  SaveState: Word;
  S: FNameStr;
begin
  with FManager^ do
  begin
    S := TheTree^.GetDirStr(Item);
    if not InArchive then Message(Owner, evBroadcast, cmNewPrompt, @S);
    if Opposite^.Status <> stTree then
    begin
      Opposite^.Options := Opposite^.Options and not ofValidate;
      if Opposite^.InArchive then
      begin
        SameArchive := InArchive and
          (Archiver^.ArcName^ = Opposite^.Archiver^.ArcName^);
        if not SameArchive then
        begin
          Dispose(Opposite^.Archiver, Done);
          Opposite^.InArchive := False;
        end;
      end
      else SameArchive := False;
      SaveState := Owner^.State;
      Owner^.State := Owner^.State and not sfSearching;
      if InArchive and not SameArchive then IntoArchive(
        Opposite, AddedSlash(S), Length(Archiver^.ArcName^))
      else
      begin
        if SameArchive then
        begin
          Opposite^.Archiver^.NewArcDir(S);
          Opposite^.NewDir(Opposite^.ListDir^, True);
        end
        else Opposite^.NewDir(S, True);
        Opposite^.FocusItem(0);
      end;
      Owner^.State := SaveState;
      if Opposite^.State and sfVisible = 0 then
        TogglePanelPrim(PPanelWindow(Owner), Opposite, tmByF);
    end;
    DrawView;
  end;
end;

procedure ItemSelectedPrim(FManager: PPanel; Item: Integer);
var
  I: Integer;
  SR: PPanelRec;
  S, NS: String;

procedure MoveAroundInArchive;
var
  A: Pointer;
begin
  with FManager^ do
  begin
    if SR^.Name[1] <> '.' then
      if SR^.Attr and VolumeID <> 0 then
      begin
        Archiver^.GetDownOrUpName(SR^.Name[1] = 'N', NS);
        if NS <> '' then Archiver^.NewArchive(NS, '');
      end
      else
      begin
        AddNameExt(S + '\', SR, NS);
        Archiver^.NewArcDir(NS);
      end
    else if CompUCString(Archiver^.ArcName^, S) = Equal then
    begin
      A := Archiver^.Prev;
      Archiver^.Prev := nil;
      Dispose(Archiver, Done);
      Archiver := A;
      InArchive := A <> nil;
    end
    else Archiver^.NewArcDir(PrevDir(S));
    NewDir(ListDir^, True);
    GetItemNum(S, I);
    FocusItem(I);
  end;
end;

begin
  with FManager^ do
  begin
    if (List^.Count = 0) or (Status >= stInfo) then Exit;
    if Status = stTree then
    begin
      TreeItemSelectedPrim(FManager, Item);
      Exit;
    end;
    SR := List^.At(Item);
    if SR^.Attr and Directory <> 0 then
    begin
      if not InArchive and
        (SR^.Attr and VolumeID <> 0) and
        (Settings and seList <> 0) then
      begin
        OutOfFileListPrim(FManager);
        Exit;
      end;
      if Options and ofValidate <> 0 then
      begin
        if (SR^.Name[0] = #2) and (SR^.Name[2] = ':') then
          SelectDrivePrim(FManager, SR^.Name[1], False)
	else if PanelRecHasPath(SR) then
	begin
          Options := Options and not ofValidate;
          NewDir(PanelRecPath(SR), True);
          FocusItem(0);
        end;
        Exit;
      end;
      if SR^.Name[1] = ':' then
      begin
        DrivePanel;
        Exit;
      end;
      GetListDir(S);
      if InArchive then
      begin
        MoveAroundInArchive;
        Exit;
      end;
      if SR^.Name[1] <> '.' then AddNameExt(S + '\', SR, NS)
      else NS := PrevDir(S);
      NewDir(NS, True);
      if UCPos(NS, S) <> 0 then GetItemNum(S, I)
      else I := 0;
      FocusItem(I);
    end
    else
    begin
      GetExecRecPrim(FManager, ExecRec);
      if ExecRec.Path <> '' then
      begin
        PPanelWindow(Owner)^.PromptLine^.HistCount := $FF;
        HistoryOpened := True;
        PrepareExecEvent;
      end;
    end;
  end;
end;

procedure FMOpenPrim(FManager: PPanel; ACommand: Word);
var
  Command, SaveSet: Word;
  I: Integer;
  SR: PPanelRec;
  S: String;

function FileSelected: Boolean;
var
  I: Integer;
begin
  with FManager^ do
  begin
    FileSelected := False;
    if (List^.Count = 0) or (SelCount = 0) or (Status >= stTree) then Exit;
    for I := 0 to List^.Count - 1 do
    begin
      SR := List^.At(I);
      if (SR^.Attr and Directory = 0) and SR^.Selected then
      begin
        FileSelected := True;
        Exit;
      end;
    end;
  end;
end;

begin
  with FManager^ do
  begin
    if Status = stQuickView then
    begin
      if Opposite^.Status in [stQuickView, stQuickDescr] then Exit;
      FMOpenPrim(Opposite, ACommand);
      Exit;
    end;
    if Status = stQuickDescr then
    begin
      if Opposite^.Status in [stQuickView, stQuickDescr] then Exit;
      EditFilesBBSPrim(Opposite);
      Exit;
    end;
    if InArchive or ((List^.Count = 0) and (Status < stInfo)) or
       (Status = stTree) then Exit;
    if ACommand = cmIsHex then Command := cmOpenHex
    else Command := cmOpenASCII;
    if Status = stInfo then
    begin
      Opposite^.GetListDir(S);
      Inc(S[0]);
      S[Length(S)] := '\';
      if DirinfoName <> '' then S := S + DirinfoName
      else SetFirstFoundName(DirinfoNames, S);
      if S <> '' then Message(Application, evCommand, Command, @S);
    end
    else if (SelCount > 0) and (Settings and seIgnoreSelection = 0) and
      (FMOptions and foOpenFocused = 0) and FileSelected then
    begin
      DoneSelList;
      InitSelList;
      I := 0;
      CancelSysErrors := False;
      EditorAborted := False;
      while (I < List^.Count) and not CancelSysErrors
        and not EditorAborted and not LowMemory do
      begin
        SR := List^.At(I);
        if (SR^.Attr and Directory = 0) and SR^.Selected then
        begin
          GetRecStr(SR, S);
          Message(Application, evCommand, Command, @S);
          SetSelect(SR, False);
          if FMOptions and foUnsel <> 0 then FocusItem(Focused);
        end;
        Inc(I);
      end;
    end
    else
    begin
      SR := List^.At(Focused);
{ added 05-13-03 to support directory attribute change on F4 }
      if SR^.Attr and Directory <> 0 then
      begin
        SaveSet := Settings;
        Settings := Settings or seIgnoreSelection;
        FileAttributesPrim(FManager);
        Settings := SaveSet;
      end
      else
      begin
        GetRecStr(SR, S);
        Message(Application, evCommand, Command, @S);
      end;
    end;
  end;
end;

procedure AddByteStr(var S: String);
begin
  if S[Length(S)] = 'K' then S := S + 'B'
  else S := S + ' bytes';
end;

procedure GetDirViewLines(FManager: PPanel; AWidth: Integer;
  const S: FNameStr; NumFiles, NumTagged, NumSubDirs: Longint;
  FilesSize, NumBytes, TaggedSize, TaggedBytes,
  Compressed, TaggedCompressed: Real; var DirS, NumFilesS, FilesS,
  NumTaggedS, TaggedS, CmprS, TaggedCmprS, NumSubDirsS: FNameStr);
var
  SS: FNameStr;
begin
  with FManager^ do
    if InArchive and (Archiver^.ArcName^ = S) then
      SS := 'Archive:      ' else SS := 'Directory:    ';
  if AWidth < 22 then AWidth := 22;
  if AWidth > 54 then AWidth := 54;
  DirS := SS + TrimmedName(S, AWidth);
  FormatBytes(NumFilesS, NumFiles, MaxLongint);
  FormatFloatBytes(SS, FilesSize, 10000000);
  FormatFloatBytes(FilesS, NumBytes, 10000000);
  AddByteStr(SS);
  SS := ' (' + SS + ')';
  if FilesSize = 1 then Delete(SS, Length(SS) - 1, 1);
  NumFilesS := 'Files:        ' + NumFilesS + SS;
  AddByteStr(FilesS);
  FilesS := 'Total size:   ' + FilesS;

  FormatBytes(NumTaggedS, NumTagged, MaxLongint);
  FormatFloatBytes(SS, TaggedSize, 10000000);
  FormatFloatBytes(TaggedS, TaggedBytes, 10000000);
  AddByteStr(SS);
  SS := ' (' + SS + ')';
  if TaggedSize = 1 then Delete(SS, Length(SS) - 1, 1);
  NumTaggedS := 'Selected:     ' + NumTaggedS + SS;
  AddByteStr(TaggedS);
  TaggedS := 'Total size:   ' + TaggedS;

  FormatBytes(NumSubDirsS, NumSubDirs, MaxLongint);
  NumSubDirsS := 'Subdirs:      ' + NumSubDirsS;

  if Compressed = 0 then CmprS := ''
  else
  begin
    FormatFloatBytes(CmprS, Compressed, 10000000);
    AddByteStr(CmprS);
    CmprS := 'Size on disk: ' + CmprS;
  end;
  if TaggedCompressed = 0 then TaggedCmprS := ''
  else
  begin
    FormatFloatBytes(TaggedCmprS, TaggedCompressed, 10000000);
    AddByteStr(TaggedCmprS);
    TaggedCmprS := 'Size on disk: ' + TaggedCmprS;
  end;
end;

procedure FMViewPrim(FManager: PPanel; ACommand: Word);
var
  DoExec: Boolean;
  Key: Word;
  X, Z, LoY, HiY: Integer;
  SaveOpt: Longint;
  SR: PPanelRec;
  NumF, NumSel, NumSD: Longint;
  NumS_, NumB_, SelS_, SelB_: Longint;
  NumS, NumB, SelS, SelB, Cmpr, SelC: Real;
  R: TRect;
  D: PDialog;
  S, DS, FS, BS, TS, TB, BF, SDS, CmprS, TaggedCmprS: FNameStr;

procedure AddDlgLbl(var ALblStr: String; Tilde: Boolean);
begin
  if ALblStr = '' then Exit;
  if Tilde then
  begin
    Insert('~', ALblStr, 15);
    Inc(ALblStr[0]);
    ALblStr[Length(ALblStr)] := '~';
  end;
  D^.Insert(New(PLabel, Init(R, ALblStr, nil)));
  R.Move(0, 1);
end;

begin
  with FManager^ do
  begin
    if Status in [stQuickView, stQuickDescr] then
    begin
      if Opposite^.Status in [stQuickView, stQuickDescr] then Exit;
      FMViewPrim(Opposite, ACommand);
      Exit;
    end;
    if Status = stInfo then
    begin
      Opposite^.GetListDir(S);
      Inc(S[0]);
      S[Length(S)] := '\';
      if DirinfoName <> '' then S := S + DirinfoName
      else SetFirstFoundName(DirinfoNames, S);
      if S <> '' then
      begin
	if ACommand = cmFCtrlView then ACommand := cmOpenHexViewer
	else ACommand := cmOpenTextViewer;
	Message(Application, evCommand, ACommand, @S);
      end;
      Exit;
    end;
    if List^.Count = 0 then Exit;
    SR := PPanelRec(List^.At(Focused));
    if SR^.Attr and Directory <> 0 then
    begin
{ added 05-13-03 to support Alt+F3 on directory }
      if ACommand = cmFAltView then
      begin
        SaveOpt := FMOptions;
	FMOptions := FMOptions and not foSpaceSelects;
        SpaceSelectFocusedPrim(FManager);
        FMOptions := SaveOpt;
        if FMOptions and foAltF3MovesDown <> 0 then FocusItem(Focused + 1);
        Exit;
      end;

      GetRecStr(SR, S);
      if InArchive then
      begin
        if (SR^.Attr and VolumeID <> 0) and
	   (SR^.Name[1] <> '.') then Exit;
        if not Archiver^.GetDirInfo(S, NumF, NumS_, NumB_,
          NumSel, SelS_, SelB_, NumSD, TagList^.Count <> 0) then Exit;
        NumS := NumS_;
        NumB := NumB_;
        SelS := SelS_;
	SelB := SelB_;
	Cmpr := 0;
	SelC := 0;
      end
      else if not GetDirInfo(S, NumF, NumSel, NumSD, NumS, NumB, SelS, SelB, Cmpr, SelC,
	TagList^.Count <> 0, Settings and seList = 0, False) then Exit;
      if (Settings and seCalcDirSize <> 0) and not InArchive then
	ReReadPrim(True);
      GetDirViewLines(FManager, 52, S, NumF, NumSel, NumSD, NumS, NumB,
	SelS, SelB, Cmpr, SelC, DS, FS, BS, TS, TB, CmprS, TaggedCmprS, SDS);

      if InArchive {or (S[1] = '\')} then BF := ''
      else
      begin
{	BytesFree := FDiskFree(Byte(S[1]) - $40);}
	BytesFree := FDiskFree(S);
	FormatFloatBytes(BF, BytesFree, 1000000000);
	AddByteStr(BF);
	BF := 'Free space:   ' + BF;
      end;

(*
      S := Concat(DS, #13, FS, #13, BS);
      if CmprS <> '' then S := Concat(S, #13, CmprS);
      S := Concat(S, #13, SDS);

      if TagList^.Count <> 0 then
      begin
	S := Concat(S, #13#13, TS, #13, TB);
	if TaggedCmprS <> '' then S := Concat(S, #13, TaggedCmprS);
      end;

      if BF <> '' then S := Concat(S, #13#13, BF);
*)

      LoY := ScreenHeight div 2 - 5;
      HiY := ScreenHeight div 2 + 5;
      if TagList^.Count <> 0 then
      begin
	Dec(LoY);
	Inc(HiY, 2);
      end;
      if BF <> '' then
      begin
	Dec(LoY);
	Inc(HiY);
      end;
      if CmprS <> '' then Dec(LoY);
      if TaggedCmprS <> '' then Inc(HiY);

      X := Length(DS) + 6;
      if X < 42 then X := 42;
      if Odd(X) then Z := 1 else Z := 0;
      X := X shr 1;
      R.Assign(ScreenWidth div 2 - X - Z, LoY, ScreenWidth div 2 + X, HiY);
{      CtxMessageBoxRect(R, S, nil, mfInformation + mfOkButton, hcDirSizes);}
      D := New(PDialog, Init(R, 'Directory information'));
      D^.HelpCtx := hcDirSizes;
      R.Assign(2, 2, D^.Size.X - 1, 3);
      AddDlgLbl(DS, False);
      AddDlgLbl(FS, False);
      AddDlgLbl(BS, False);
      AddDlgLbl(CmprS, False);
      AddDlgLbl(SDS, False);
      if TagList^.Count <> 0 then
      begin
	R.Move(0, 1);
	AddDlgLbl(TS, True);
	AddDlgLbl(TB, True);
	AddDlgLbl(TaggedCmprS, True);
      end;
      R.Move(0, 1);
      AddDlgLbl(BF, False);
      with D^ do R.Assign(
	Size.X div 2 - 5, Size.Y - 3, Size.X div 2 + 5, Size.Y - 1);
      StandardOkButton(R, D);
      Application^.ExecuteDialog(D, nil, False);
    end
    else with ExecRec do
    begin
      Params := '';
      Options := 0;
      if ACommand = cmFCtrlView then Path := '$XVIEW'
      else
      begin
	Key := ACommand - cmFView;
	AddNameExt('', SR, S);
	if not ExtractExecRec(ExecRec, S, Key, True) then
	begin
	  if Path = #0 then Exit;
	  Path := '$VIEW';
	end;
      end;
      PrepareExecEvent;
    end;
  end;
end;

procedure FMViewNextPrim(FManager: PPanel; var Event: TEvent);
var
  ShiftDown: Boolean;
  I, J: Integer;
  SR: PPanelRec;
  S: String;
begin
  Event.What := evNothing;
  ShiftDown := GetShiftState and (kbLeftShift + kbRightShift) <> 0;
  with FManager^ do
  begin
    if InArchive then
    begin
      I := 0;
      FindByName(PString(Event.InfoPtr)^, I);
      if I = -1 then Exit;
    end
    else
    begin
      GetItemNum(PString(Event.InfoPtr)^, I);
      GetItemStr(I, S);
      if CompUCString(PString(Event.InfoPtr)^, S) <> Equal then Exit;
    end;
    J := I;
    if Event.Command = cmFMViewPrev then while I <> 0 do
    begin
      Dec(I);
      SR := List^.At(I);
      if (SR = nil) or (SR^.Attr and Directory = 0) then Break;
    end
    else while I < List^.Count do
    begin
      Inc(I);
      SR := List^.At(I);
      if (SR = nil) or (SR^.Attr and Directory = 0) then Break;
    end;
    if I = J then Exit;
    SR := List^.At(I);
    if (SR <> nil) and (SR^.Attr and Directory = 0) then
    begin
      FocusItem(I);
      GlobalRedrawLock := True;
      GlobalQuietExec := True;
      GetSource(S);
      GlobalRedrawLock := False;
      GlobalQuietExec := False;
      ExecRec.Path := '$VIEW(' + S + ')';
      if ShiftDown then ExecRec.Params := ''
      else ExecRec.Params := '$SAMEWIN';
      ExecRec.Options := 0;
      PrepareExecEvent;
    end;
  end;
end;

function AreDirs(FManager: PPanel; Single: Boolean): Boolean;
var
  I: Integer;
  SR: PPanelRec;
begin
  with FManager^ do
  begin
    if (SelCount <> 0) and not Single and
       (Settings and seIgnoreSelection = 0) then
      AreDirs := SelDirCount <> 0
    else
    begin
      SR := List^.At(Focused);
      if SR^.Name = '..' then
      begin
        if Settings and seUnfold = 0 then
          for I := 0 to List^.Count - 1 do
          begin
            SR := List^.At(I);
            if (SR^.Name[1] <> '.') and
               (SR^.Attr and Directory <> 0) then
            begin
              AreDirs := True;
              Exit;
            end;
          end;
        AreDirs := False;
      end
      else AreDirs := SR^.Attr and Directory <> 0;
    end;
  end;
end;

procedure AppendSelListPrim(FManager: PPanel;
  const Name, Mask, Fmt: FNameStr; Long, Full, SelOnly: Boolean);
var
  Abort: Boolean;
  SaveStatus: Byte;
  I, ILo, IHi: Integer;
  P: PPanelRec;
  PName: PString;
  CurDir, FindPath, S: FNameStr;
  F: lText;

procedure WriteName(Size, Time: Longint; Attr: Byte);
var
  DT: DateTime;
  T: TPDate.Time;
begin
  if (FManager^.Settings and seList = 0) and not Long then
    lGetShortFileName(S, S);
  if not Full and (SelListOptions and slAddPath = 0) and
    (UCPos(CurDir, S) = 1) then System.Delete(S, 1, Length(CurDir));
  if (SelListOptions and slLQuotes <> 0) and (Pos(' ', S) <> 0) then
    S := '"' + S + '"';
  if SelListOptions and slAddSize <> 0 then S := S + #9 + Long2Str(Size);
  if SelListOptions and slAddTime <> 0 then
  begin
    UnpackTime(Time, DT);
    if SelListDateMask <> '' then S := S + #9 +
      DMYtoDateString(SelListDateMask, DT.Day, DT.Month, DT.Year)
    else S := S + #9 + FormatDateStr(DT.Year, DT.Month, DT.Day);
    if SelListTimeMask <> '' then
    begin
      T := HMStoTime(DT.Hour, DT.Min, DT.Sec);
      S := S + #9 + TimeToTimeString(SelListTimeMask, T);
    end
    else
    begin
      S := S + #9 + FormatTimeStr(DT.Hour, DT.Min, DT.Sec);
      if S[Length(S)] = ' ' then Dec(S[0]);
    end;
  end;
  if SelListOptions and slAddAttr <> 0 then
  begin
    S := S + #9;
    if Attr and ReadOnly <> 0 then S := S + 'R'
    else S := S + '-';
    if Attr and Hidden <> 0 then S := S + 'H'
    else S := S + '-';
    if Attr and SysFile <> 0 then S := S + 'S'
    else S := S + '-';
    if Attr and VolumeID <> 0 then S := S + 'V'
    else S := S + '-';
    if Attr and Directory <> 0 then S := S + 'D'
    else S := S + '-';
    if Attr and Archive <> 0 then S := S + 'A'
    else S := S + '-';
  end;
  ProcessFmt(Fmt, S);
  Writeln(F.T, SelListPrefixStr, S, SelListSuffixStr);
  Abort := IOResult <> 0;
end;

procedure SetFindPath(const ADir: FNameStr);
begin
  FindPath := Concat(ADir, '\*.*');
end;

procedure SetCurPath(const ADir, AName: FNameStr);
begin
  FindPath := Concat(ADir, '\', AName);
end;

procedure SetNameStr(const ADir, AName: FNameStr);
begin
  S := Concat(ADir, '\', AName);
end;

procedure ScanDir(ADir: PString);
var
  Found: Boolean;
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
  GiveTicks;
  SetFindPath(Dir^);
  Found := False;
  FailSysErrors := True;
  lFindFirst(FindPath, $17, SR^);
  FailSysErrors := False;
  while (DosError = 0) and not Abort do
  begin
    if SR^.SR.Attr and Directory = 0 then
    begin
      Found := True;
      if SR^.FullName <> '' then PName := @SR^.FullName
      else PName := @SR^.SR.Name;
      if (Mask = '') or WildCardMatch(PName^, Mask) then
      begin
        SetNameStr(Dir^, PName^);
        if FoundInCRCList(S, FManager^.CRCList) then
          WriteName(SR^.SR.Size, SR^.SR.Time, SR^.SR.Attr);
      end;
    end
    else if SR^.SR.Name[1] <> '.' then
    begin
      Found := True;
      if SR^.FullName <> '' then SetCurPath(Dir^, SR^.FullName)
      else SetCurPath(Dir^, SR^.SR.Name);
      ScanDir(@FindPath);
    end;
    lFindNext(SR^);
    if (KbdStatus = 1) and FMAbortAction then Abort := True;
  end;
  if not Found and SelListIncludeEmptyDirs and
    (SelListOptions and slSkipDir = 0) then
  begin
    if SelListOptions and slBkSlash <> 0 then SetNameStr(Dir^, '')
    else S := Dir^;
    WriteName(SR^.SR.Size, SR^.SR.Time, SR^.SR.Attr);
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  with FManager^ do
  begin
    LogEvent := lcDiskWrite;
    DrawStatusLine('Adding selected file names to ' +
      TrimmedName(Name, 37) + '.');
    lAssignText(F, Name);
    Append(F.T);
    if IOResult <> 0 then Exit;
    GetCurDir(0, CurDir);
    CurDir := AddedSlash(CurDir);
    if not Long then lGetShortFileName(CurDir, CurDir);
    SaveStatus := Status;
    if Status = stTree then Status := stBrief;
    Abort := False;
    if InArchive then Archiver^.SaveSelected(@F, Mask, '', Abort)
    else
    begin
      if not SelOnly and ((SelCount = 0) or
        (Settings and seIgnoreSelection <> 0)) then
      begin
        ILo := Focused;
        IHi := Focused;
      end
      else
      begin
        ILo := 0;
        IHi := List^.Count - 1;
        SelOnly := True;
      end;
      for I := ILo to IHi do
      begin
        P := List^.At(I);
        if not SelOnly or P^.Selected then
        begin
          GetRecStr(P, S);
          if P^.Attr and Directory <> 0 then ScanDir(@S)
          else if (Mask = '') or WildCardMatch(JustFileName(S), Mask) then
            WriteName(P^.Size, P^.Time, P^.Attr);
        end;
        if Abort then Break;
      end;
    end;
    Status := SaveStatus;
    Close(F.T);
    InOutRes := 0;
  end;
end;

end.