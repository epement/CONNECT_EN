{$I-,F+,O+,X+}
unit FMPrim;

interface

uses Objects, PanelRec, FileMngr;

type
  POptList = ^TOptList;
  TOptList = object(TPanelCollection)
    procedure FreeItem(Item: Pointer); virtual;
    procedure Insert(Item: Pointer); virtual;
  end;

procedure FMDeleteItemsPrim(FManager: PPanel);
procedure FMDeletePrim(FManager: PPanel; One: Boolean);
procedure FMMkDirPrim(FManager: PPanel; Shift: Boolean);
procedure CalcSelBytes(AList: PCollection; ClusterSize: Longint;
  BytesFree: Real; var SelBytes: Real; var AtLeastOne: Boolean);
procedure Optimize(AList: PCollection; ClusterSize: Longint;
  BytesFree: Real; var Optimized: Boolean);
procedure OptimalFill(AList: PCollection;
  const DestStr, ActionStr: String; var Optimized, Aborted: Boolean;
{ Added 05-26-03 to support optimal fill by size }
  FillSize: Longint; NoPrompt: Boolean);
{ Added 05-12-03 to support file splitting }
procedure SplitFixToName(var FromName, ToName: FNameStr);
procedure FMCopyPrim(FManager: PPanel; const ADest: FNameStr;
  One: Boolean);
procedure FMRenMovPrim(FManager: PPanel; const ADest: FNameStr;
  One: Boolean);

implementation

uses Dos, Drivers, Views, Memory, Dialogs, HistList, App, MsgBox, DirPrim,
  Disks, DiskBase, DiskPrim, FMAction, FMInfo, EditFile, EditMsg, Archives,
  History, HeapUMB, LFN, DosTools, ExecPrim, ClipPrim, Swaps, RevPos, RegExp,
  TPString, Consts, Commands, Defaults;

procedure DirExpectedMsgBox;
begin
  MessageBox(^C'Valid directory name expected.',
    nil, mfError + mfOkButton);
end;

procedure TOptList.FreeItem(Item: Pointer);
begin
end;

procedure TOptList.Insert(Item: Pointer);
var
  I: Integer;
begin
  if not Search(Item, I) then AtInsert(I, Item);
end;

procedure FMDeleteItemsPrim(FManager: PPanel);
var
  I: Integer;
  SR: PPanelRec;
  S: FNameStr;
begin
  with FManager^ do
  begin
    if Status = stInfo then
    begin
      Dirinfo^.FreeAll;
      ReadInfoPrim(FManager, True);
      FocusItem(Focused);
    end;
    if (List^.Count = 0) or (Status >= stTree) then Exit;
    if (SelCount > 0) and (Settings and seIgnoreSelection = 0) then
    begin
      GetItemStr(Focused, S);
      I := 0;
      while I < List^.Count do
      begin
        SR := List^.At(I);
        if SR^.Selected and not (SR^.Name[1] in [':', '.']) and
          (SR^.Attr and VolumeID = 0) then
        begin
          SetSelect(SR, False);
          if SR^.Attr and Directory <> 0 then Dec(DirCount)
          else Dec(FileCount);
          ByteCount := ByteCount - lGetFileRealSize(SR^.Attr, SR^.Size);
          List^.AtFree(I);
          if FilesBBS^.Count > I then FilesBBS^.AtFree(I);
        end
        else Inc(I);
      end;
      GetItemNum(S, I);
    end
    else
    begin
      I := Focused;
      SR := List^.At(I);
      if not (SR^.Name[1] in [':', '.']) and
        (SR^.Attr and VolumeID = 0) then
      begin
        SetSelect(SR, False);
        if SR^.Attr and Directory <> 0 then Dec(DirCount)
        else Dec(FileCount);
        ByteCount := ByteCount - lGetFileRealSize(SR^.Attr, SR^.Size);
        List^.AtFree(I);
        if FilesBBS^.Count > I then FilesBBS^.AtFree(I);
      end;
    end;
    SetRange(List^.Count);
    FocusItem(I);
  end;
end;

function ConfirmDeleteMessageBox(const Msg: String;
  const S: FNameStr; Params: Pointer): Word;
var
  CS: String[2];
begin
  if Length(S) > 2 then CS := #13^C else CS := ' ';
  ConfirmDeleteMessageBox := MessageBox(Msg + CS + '|' + S + '| ?',
    Params, mfDelTrashConf + mfOkCancel);
end;

procedure FMDeletePrim(FManager: PPanel; One: Boolean);
var
  I: Integer;
  SR: PPanelRec;
  L: Longint;
  S, SS: String;
begin
  with FManager^ do
  begin
    if (List^.Count = 0) or (Status >= stInfo) then Exit;
    DeleteStatus := dsDelete;
    DeleteErrorStatus := deRetry;
    if not One and (SelCount > 0) and
      (Settings and seIgnoreSelection = 0) then
    begin
      L := SelCount;
      if Options and ofValidate <> 0 then
      begin
	if L = 1 then S := 'drive' else S := 'drives';
	if MessageBox(^C'Delete the contents of'#13^C +
	  '%d selected ' + S + ' ?', @L,
	  mfDelTrashConf + mfOkCancel) = cmCancel then Exit;
      end
      else if Status = stTree then
      begin
	S := ^C'Delete %d selected director';
	if L = 1 then S := S + 'y' else S := S + 'ies';
	S := S + ' ?';
	if L <> 1 then System.Insert(#13^C, S, 14);
	if MessageBox(S, @L, mfDelTrashConf + mfOkCancel) = cmCancel then
	  Exit;
      end
      else
      begin
	if L = 1 then S := 'file' else S := 'files';
	GetListDir(SS);
	if ConfirmDeleteMessageBox(^C'Delete %d selected ' +
	  S + ' from', SS, @L) <> cmOk then Exit;
      end;
      DoneSelList;
      InitSelList;
      I := 0;
      if InArchive then Archiver^.DeletePrim(False)
      else while (I < List^.Count) and (DeleteStatus <> dsCancel) do
      begin
	SR := List^.At(I);
	if SR^.Selected then
	begin
	  GetRecStr(SR, S);
	  if SR^.Attr and Directory <> 0 then
	    DirDeletePrim(S, CRCList, True, False)
	  else FDeletePrim(S);
	  if not (DeleteStatus in [dsSkip, dsSkipAll, dsCancel]) then
	  begin
	    SetSelect(SR, False);
	    if FMOptions and foUnsel <> 0 then FocusItem(Focused);
	  end;
	end;
	Inc(I);
      end;
    end
    else
    begin
      SR := List^.At(Focused);
      if SR^.Attr and Directory <> 0 then
      begin
	if (SR^.Attr and VolumeID <> 0) and (SR^.Name[1] <> '.') then Exit;
	GetRecStr(SR, S);
        if (S[1] = '\') and (S = RootName(S)) then
	  SS := 'contents of the network resource'
	else if S[0] < #4 then SS := 'contents of the'#13^C'drive'
	else if SR^.Name[1] = '.' then
	  if InArchive and (SR^.Attr and VolumeID <> 0) then
	    SS := 'contents of the archive'
	  else SS := 'contents of the current directory'
	else SS := 'directory';
	if ConfirmDeleteMessageBox(
	  ^C'Delete the ' + SS, S, nil) <> cmOk then Exit;
	if InArchive then Archiver^.DeletePrim(True)
	else if SR^.Name[1] = '.' then
	  ClearDirs(AddedSlash(S), CRCList, True, False)
	else DirDeletePrim(S, CRCList, True, False);
      end
      else if Status < stTree then
      begin
	GetRecStr(SR, S);
	if ConfirmDeleteMessageBox(^C'Delete the file',
	  S, nil) <> cmOk then Exit;
	if InArchive then Archiver^.DeletePrim(True)
	else FDeletePrim(S);
      end;
    end;
    Message(Desktop, evBroadcast, cmUpdateDisk, nil);
  end;
end;

procedure FetchFileName(var S, R: FNameStr);
var
  P: Byte;
begin
  R := '';
  TrimSt(S);
  if S = '' then Exit;
  if S[1] = '"' then
  begin
    P := 2;
    while (P <= Length(S)) and (S[P] <> '"') do Inc(P);
    if P <= Length(S) then
    begin
      R := System.Copy(S, 2, P - 2);
      Delete(S, 1, P);
      Exit;
    end;
  end;
  P := Pos(' ', S);
  if P = 0 then
  begin
    R := S;
    S := '';
  end
  else
  begin
    R := System.Copy(S, 1, P - 1);
    System.Delete(S, 1, P);
  end;
end;

procedure FMMkDirPrim(FManager: PPanel; Shift: Boolean);
var
  Clip: Boolean;
  C: Word;
  I, J: Integer;
  D: PDialog;
  R: TRect;
  Control: PView;
  CS, DS, S, SS: FNameStr;
begin
  if Shift then
  begin
    Pending.What := evCommand;
    Pending.Command := cmDecoders;
    Exit;
  end;
  with FManager^ do
  begin
    R.Assign(0, 0, 70, 8);
    D := InitSimpleDialog(R, 'Make directory', hcMkDirDialog);
    with D^ do
    begin
      Options := Options or ofCentered;
      R.Assign(3, 3, Size.X - 6, 4);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      StandardHistory(Control, FNameHistoryId);
      R.Assign(2, 2, Size.X - 3, 3);
      Insert(New(PLabel, Init(R, '~C~reate the directory', Control)));
    end;
    DS := '';
    C := Application^.ExecuteDialog(D, @DS, False);
    TrimSt(DS);
{ Added 2005.08.30 to support regexp file operations }
    PreprocessFileRegExp(DS);
    if C <> cmCancel then
    begin
      if DS = '' then
      begin
        if DiskClipStream = nil then Exit;
        if MessageBox(^C'Create directories ' +
          'using selected text in the Clipboard ?',
          nil, mfConfirmation + mfOkCancel) = cmCancel then Exit;
        Message(Desktop, evBroadcast, cmUpdateViews, nil);
        I := ClipArea^.KK;
        Clip := True;
      end
      else Clip := False;

      CS := '';
      repeat
        if Clip then
        begin
          if CS = '' then
          begin
            if I < ClipArea^.KB then Break;
            GetClipLine(I, CS);
            Dec(I);
          end;
          FetchFileName(CS, DS);
          if DS = '' then Continue;
        end;
        repeat
          J := RPos('|', DS);
          S := Copy(DS, J + 1, 255);
          if J = 0 then DS := '' else DS[0] := Char(J - 1);
          TrimSt(S);
          if S <> '' then
          begin
            if not (S[1] in ['.', '\']) and
               not ((S[0] >= #2) and (S[2] = ':')) then
            begin
              if Status = stTree then GetItemStr(Focused, SS)
              else SS := ListDir^;
              S := AddedSlash(SS) + S;
            end;
            S := ClearedSlash(lFExpand(S));
            CopyStatus := dsOverwrite;
            CopyErrorStatus := deRetry;
            CancelSysErrors := False;
            MkDirPrim(S, nil);
            if CancelSysErrors then Exit;
          end;
        until DS = '';
      until not Clip;
      Message(Desktop, evBroadcast, cmUpdateDisk, nil);
      GetItemNum(S, I);
      GetItemStr(I, SS);
      if CompUCString(S, SS) = Equal then FocusItem(I);
    end;
  end;
end;

procedure GetCopyDirData(Panel: PPanel; D: PDialog;
  var Data: TCopyNameData; var ToName: FNameStr;
  var Command: Word);
begin
  Data.ToName := ToName;
  Data.Options := Byte(FileCopyOptions and fsNT_SysCopy <> 0);
  if Panel^.Filter = '*.*' then Data.DirFilter := DirFilter
  else Data.DirFilter := Panel^.Filter;
  Data.NewMask := NewMask;
  Command := Application^.ExecuteDialog(D, @Data, False);
  if Command = cmCancel then Exit;
  ToName := Data.ToName;
  if Data.Options and 1 <> 0 then
    FileCopyOptions := FileCopyOptions or fsNT_SysCopy
  else FileCopyOptions := FileCopyOptions and not fsNT_SysCopy;
  DirFilter := Data.DirFilter;
  NewMask := Data.NewMask;
end;

procedure CalcSelBytes(AList: PCollection; ClusterSize: Longint;
  BytesFree: Real; var SelBytes: Real; var AtLeastOne: Boolean);
var
  I: Integer;
  R: Real;
  SR: PPanelRec;
begin
  SelBytes := 0;
  AtLeastOne := False;
  for I := 0 to AList^.Count - 1 do
  begin
    SR := AList^.At(I);
    if SR^.Selected then
    begin
      R := lGetFileRealSpace(SR^.Attr, SR^.Size, ClusterSize);
      SelBytes := SelBytes + R;
      if R <= BytesFree then AtLeastOne := True;
    end;
  end;
end;

procedure Optimize(AList: PCollection; ClusterSize: Longint;
  BytesFree: Real; var Optimized: Boolean);
var
  I: Integer;
  LocSelBytes, R: Real;
  SR: PPanelRec;
  OptList: POptList;
begin
  OptList := New(POptList, Init(32, 32, nil));
  for I := 0 to AList^.Count - 1 do
  begin
    SR := AList^.At(I);
    if SR^.Selected then OptList^.Insert(SR);
  end;
  LocSelBytes := 0;
  for I := 0 to OptList^.Count - 1 do
  begin
    SR := OptList^.At(I);
    R := lGetFileRealSpace(SR^.Attr, SR^.Size, ClusterSize);
    if LocSelBytes + R <= BytesFree then
    begin
      Byte(SR^.Selected) := 255;
      LocSelBytes := LocSelBytes + R;
    end
    else Byte(SR^.Selected) := 1;
  end;
  Dispose(OptList, Done);
  Optimized := True;
end;

procedure OptimalFill(AList: PCollection;
  const DestStr, ActionStr: String; var Optimized, Aborted: Boolean;
{ Added 05-26-03 to support optimal fill by size }
  FillSize: Longint; NoPrompt: Boolean);
var
  AtLeastOne: Boolean;
  C: Word;
  ClusterSize: Longint;
  BytesFree, SelBytes: Real;
  R: TRect;
  S, S1, S2: String;
begin
  Optimized := False;
  Aborted := True;
{ Added 05-26-03 to support optimal fill by size }
  if FillSize = 0 then
  begin
    MessageBox(^C'Fill size incorrectly specified.',
      nil, mfError + mfOkButton);
    Exit;
  end;
  CancelSysErrors := False;
{ Added 05-26-03 to support optimal fill by size }
  if FillSize > 0 then BytesFree := FillSize
{    else BytesFree := FDiskFree(Byte(ADrive) - $40);}
  else BytesFree := FDiskFree(DestStr);
  if CancelSysErrors then Exit;
  if BytesFree < 0 then BytesFree := MaxLongint;
{    ClusterSize := GetClusterSize(Byte(ADrive) - $40);}
  ClusterSize := GetClusterSize(DestStr);
  if CancelSysErrors then Exit;
  CalcSelBytes(AList, ClusterSize, BytesFree, SelBytes, AtLeastOne);
  if (SelBytes > BytesFree) and AtLeastOne then
  begin
{ Added 05-26-03 to support optimal fill by size }
    if FillSize > 0 then
      if NoPrompt then C := cmYes
      else C := MessageBox(
        ^C'Use Optimal Fill method to ' + ActionStr + #13^C +
        'the selected files by filling up'#13^C +
        Long2Str(SplitSize) + ' bytes of destination ?',
        nil, mfConfirmation + mfYesNoCancel)
    else
    begin
      S := RootName(DestStr);
      if DestStr[1] in ['A'..'Z', 'a'..'z'] then S := 'drive ' + S
      else S := 'resource ' + S;
      FormatFloatBytes(S1, SelBytes,  1000000000000.0);
      FormatFloatBytes(S2, BytesFree, 1000000000000.0);
      R.Assign(ScreenWidth div 2 - 20, ScreenHeight div 2 - 7,
        ScreenWidth div 2 + 20, ScreenHeight div 2 + 7);
      C := MessageBoxRect(R,
        ^C'There is not enough free space on ' +
        S + ' to ' + ActionStr + ' all selected files:'#13#13 +
        'Space required:  ' + S1 + #13 +
        'Space available: ' + S2 + #13#13^C'Use Optimal Fill method ?',
        nil, mfConfirmation + mfYesNoCancel);
    end;
    if C = cmCancel then Exit;
    if C = cmYes then Optimize(AList, ClusterSize, BytesFree, Optimized);
  end;
  Aborted := False;
end;

procedure CountSelTotals(FManager: PPanel; Optimized: Boolean);
var
  I: Integer;
  SR: PPanelRec;
  Name: FNameStr;
begin
  with FManager^ do
  begin
    I := 0;
    while (I < List^.Count) and (CopyStatus <> dsCancel) do
    begin
      SR := List^.At(I);
      if (not Optimized and SR^.Selected) or
         (Optimized and (Byte(SR^.Selected) = 255)) then
      begin
        if SR^.Attr and Directory <> 0 then
        begin
          GetRecStr(SR, Name);
          DirCountPrim(Name, DirFilter, CRCList);
        end
        else
        begin
          BytesTotal := BytesTotal + lGetFileRealSize(SR^.Attr, SR^.Size);
          Inc(FilesTotal);
        end;
      end;
      Inc(I);
    end;
  end;
end;

procedure FixToName(const FromName: FNameStr; var ToName: FNameStr);
begin
  if not (ToName[1] in ['.', '\']) and
     not ((ToName[0] >= #2) and (ToName[2] = ':')) then
    ToName := AddedSlash(PrevDir(FromName)) + ToName;
end;

procedure SelFixToName(IsDir, Wild: Boolean;
  const ADest, ToData: FNameStr; var ToName: FNameStr);
begin
  if (IsDir and (ADest = '') and
    not (ToData[Length(ToData)] in [':', '\']) and
    (ToData[1] <> '.') and not Wild) and
    (DeviceDest(ToName) = '') then ToName := PrevDir(ToName);
end;

procedure SingleFixToName(IsDir, Wild, Drives, CompPrev: Boolean;
  SR: PPanelRec; const FromName, ADest, ToData: FNameStr;
  var ToName: FNameStr);
begin
  if ((SR^.Name[1] = '.') or (IsDir and (ADest = '') and
      (not CompPrev or (CompUCString(
        PrevDir(FromName), PrevDir(ToName)) <> Equal)) and not
      (ToData[Length(ToData)] in [':', '\']) and
      (ToData[1] <> '.') and not Wild and
      (SR^.Name[1] <> ':') and Drives)) and
      (DeviceDest(ToName) = '') then ToName := PrevDir(ToName);
end;

{ Added 05-12-03 to support file splitting }
procedure SplitFixToName(var FromName, ToName: FNameStr);
const
  OneMB = OneKB * OneKB;
  OneGB = OneMB * OneKB;
var
  B: Boolean;
  I, J: Integer;
  R: Real;
begin
  SplitSize := 0;
  SplitNumber := 0;
  TrimSt(ToName);
  if (ToName <> '') and (ToName[1] = '#') then
  begin
    B := True;
    Delete(ToName, 1, 1);
    TrimSt(ToName);
  end
  else B := False;
  I := 1;
  while (I <= Length(ToName)) and (ToName[I] in ['.', '0'..'9']) do Inc(I);
  Val(Copy(ToName, 1, I - 1), R, J);
  if (R > $7FFFFFFF) or (R < $80000000) then R := 0
  else if I <= Length(ToName) then
    if Upcase(ToName[I]) = 'K' then R := R * OneKB
    else if Upcase(ToName[I]) = 'M' then R := R * OneMB
    else if Upcase(ToName[I]) = 'G' then R := R * OneGB;
  if B then SplitNumber := Trunc(R)
  else SplitSize := Trunc(R);
  Delete(ToName, 1, I);
  TrimSt(ToName);
  if ToName = '' then ToName := FromName;
end;

procedure SetDirLabel(const ActionStr: String;
  const FromName: FNameStr; SR: PPanelRec; InArchive: Boolean;
  var ALabel: String);
var
  S: String;
begin
  if FromName[1] = '\' then
    S := 'network resource'
  else if (FromName[0] = #2) and (FromName[2] = ':') then
    S := 'drive ' + FromName
  else if FromName[1] = '.' then
    if InArchive and (SR^.Attr and VolumeID <> 0) then
      S := 'archive'
    else S := 'current directory'
  else
  begin
    if ActionStr[1] = 'C' then ALabel := ActionStr
    else ALabel := 'Rename or move';
    ALabel := ALabel + ' the directory "' +
      TrimmedName(FromName, 43 - Length(ALabel)) + '"';
    S := '';
  end;
  if S <> '' then ALabel := ActionStr + ' the contents of the ' + S;
  ALabel := ALabel + ' to';
end;

procedure SetCopyRenFilter(Panel: PPanel);
begin
{  DisposeStr(CopyRenameFilter.Text);}
  DisposeStrUMB(CopyRenameFilter.Text);
  Move(Panel^.AdvancedFilter, CopyRenameFilter, SizeOf(TFilterRec));
  if Panel^.AdvancedFilter.Text <> nil then
{   CopyRenameFilter.Text := NewStr(Panel^.AdvancedFilter.Text^);}
    CopyRenameFilter.Text := NewStrUMB(Panel^.AdvancedFilter.Text^);
  CopyRenameFilter.UseForLists := False;
end;

procedure CopyToListPrim(FManager: PPanel; const Name, Mask: FNameStr);
var
  B: Byte;
  T: lText;
begin
  if not ThisFileExists(Name) then
  begin
    LogEvent := lcDiskWrite;
    DrawStatusLine('Creating list file ' + TrimmedName(Name, 48) + '.');
    lAssignText(T, Name);
    Rewrite(T.T);
    if IOResult <> 0 then
    begin
      CouldNotCreateMsgBox(Name);
      Exit;
    end;
    Close(T.T);
    InOutRes := 0;
  end;
  B := SelListOptions;
  SelListOptions := SelListOptions or slLQuotes;
  AppendSelListPrim(FManager, Name, Mask, '', True, True, False);
  SelListOptions := B;
  with FManager^ do
    if (SelCount <> 0) and (Settings and seIgnoreSelection = 0) then
      UnselectAll;
  UpdateFiles(Name);
end;

procedure FMCopyPrim(FManager: PPanel; const ADest: FNameStr; One: Boolean);
var
{ Added 05-12-03 to support file splitting }
  Splitting: Boolean;
{ Added 05-26-03 to support optimal fill by size }
  FillBySize, FormatToName: Boolean;
  IsDir, Wild, Optimized, Aborted, AppendSel, FocusName: Boolean;
  C: Word;
  I: Integer;
  L: Longint;
{ Added 05-26-03 to support optimal fill by size }
  FillCount: Longint;
  D: PDialog;
  SR: PPanelRec;
  R: TRect;
  CopyDirData: TCopyNameData;
  S, FromName, ToName: FNameStr;
label
  Start, NoPrompt, Quit;
begin
  Optimized := False;
  AppendSel := False;
{ Added 05-12-03 to support file splitting }
  Splitting := False;
{ Added 05-26-03 to support optimal fill by size }
  FillBySize := False;
  FillCount := 0;
  SplitSize := -1;
  with FManager^ do
  begin
Start:
    if (Status >= stInfo) or (List^.Count = 0) then Exit;
    FocusName := False;
    CopyStatus := dsOverwrite;
    CopyErrorStatus := deRetry;
    TryAll := False;
    if not One and (SelCount > 0) and
      (Settings and seIgnoreSelection = 0) then
    begin
      L := SelCount;
      if Options and ofValidate <> 0 then
        FromName := 'Copy the contents of %d selected drives to'
      else FromName := 'Copy %d selected files to';
      if L = 1 then System.Delete(FromName, Length(FromName) - 3, 1);
      FormatStr(S, FromName, L);
      IsDir := (Options and ofValidate <> 0) or (SelDirCount <> 0);
    end
    else
    begin
      SR := List^.At(Focused);
      if (SR^.Attr and VolumeID <> 0) and (SR^.Name[1] <> '.') then Exit;
      if SR^.Name[1] = ':' then FromName := RootName(ListDir^)
      else if SR^.Name[1] = '\' then GetRecStr(SR, FromName)
      else AddNameExt('', SR, FromName);
      IsDir := SR^.Attr and Directory <> 0;
      if IsDir then SetDirLabel('Copy', FromName, SR, InArchive, S)
      else S := 'Copy "' + TrimmedName(FromName, 53) + '" to'
    end;

    if ADest <> '' then ToName := ADest
    else if (One and (GetShiftState and (kbLeftShift + kbRightShift) = 0)) or
      (Opposite^.State and sfVisible = 0) or
      (Opposite^.Status >= stInfo) then
        if One or (SelCount = 0) then ToName := FromName
        else ToName := ''
    else if Opposite^.InArchive and not InArchive then
    with Opposite^.Archiver^ do
    begin
      ToName := GetTopName;
      if ArchiveRec^.Extension <> nil then
        ToName := ArchiveRec^.Extension^ + ':' + ToName;
    end
    else if (Opposite^.Settings and seList <> 0) and not InArchive then
      ToName := 'LIST:' + Opposite^.FileListName^
    else
    begin
      if Opposite^.InArchive then ToName := Opposite^.ListDir^
      else Opposite^.GetListDir(ToName);
      ToName := AddedSlash(ToName);
    end;
    if (One or (SelCount = 0) or (Settings and seIgnoreSelection <> 0)) and
       (ToName <> '') and (ToName[Length(ToName)] = '\') and
       (Options and ofValidate = 0) and not (SR^.Name[1] in [':', '.']) and
       not InArchive and not Opposite^.InArchive then
    begin
      HistoryAdd(FNameHistoryId,
        AddedSlash(ListDir^) + JustFileName(FromName), True);
      ToName := ToName + JustFileName(FromName);
    end;
    if (ADest <> '') and (FMOptions and foDragPrompt = 0) and
       not Optimized then Goto NoPrompt;
    R.Assign(0, 0, 70, 8 + 4 * Byte(IsDir));
    if IsDir then D := InitDirCopyDialog(R, S, InArchive)
    else D := InitCopyDialog(R, S, False, False);
    if IsDir then GetCopyDirData(FManager, D, CopyDirData, ToName, C)
    else
    begin
      CopyDirData.ToName := ToName;
      CopyDirData.Options := Byte(FileCopyOptions and fsNT_SysCopy <> 0);
      C := Application^.ExecuteDialog(D, @CopyDirData, False);
      ToName := CopyDirData.ToName;
      if CopyDirData.Options and 1 <> 0 then
	FileCopyOptions := FileCopyOptions or fsNT_SysCopy
      else FileCopyOptions := FileCopyOptions and not fsNT_SysCopy;
    end;
    TrimSt(ToName);
{ Added 2005.08.30 to support regexp file operations }
    PreprocessFileRegExp(ToName);
    FileRegExpInitDirLen := Length(ListDir^) + 1;
    if (C <> cmCancel) and (ToName <> '') then
    begin
NoPrompt:
      Wild := IsWild(ToName);
      if (Pos(':', ToName) > 2) and not InArchive and
{ Added 05-12-03 to support file splitting }
        not (ToName[1] in ['+', '/']) then
      begin
        if IsDir then FromName := DirFilter
        else FromName := '';
        if UCPos('LIST:', ToName) = 1 then CopyToListPrim(FManager,
          Trim(System.Copy(ToName, 6, 255)), FromName)
        else CopyToArchive(FManager, One, False, ToName, FromName, nil);
        goto Quit;
      end;

      if (FManager^.Settings and seAdvancedFilter <> 0) and
         (CopyRenameFilter.Text = nil) then SetCopyRenFilter(FManager);

      if not One and (SelCount > 0) and
        (Settings and seIgnoreSelection = 0) then
      begin
{ Added 05-26-03 to support optimal fill by size }
        if (Length(ToName) > 1) and (ToName[1] = '/') then
        begin
          System.Delete(ToName, 1, 1);
          SplitFixToName(FromName, ToName);
          FillBySize := True;
          FormatStr(S, ToName, FillCount);
          FormatToName := S <> ToName;
        end
        else if (Length(ToName) > 1) and (ToName[1] = '+') then
        begin
          System.Delete(ToName, 1, 1);
          TrimSt(ToName);
          AppendSel := True;
        end
        else if not ((ToName[0] = #2) and (ToName[2] = ':')) and
          not Wild then ToName := AddedSlash(ToName);

{ Added 05-26-03 to support optimal fill by size }
        if (FillBySize or
           (FMOptions and foCheckFreeSpace <> 0) and not AppendSel) then
        begin
          S := lFExpand(ToName);
          if DeviceDest(S) = '' then
          begin
            OptimalFill(List, S, 'copy', Optimized, Aborted,
              SplitSize, FormatToName and (FillCount > 0));
            if Aborted then goto Quit;
          end;
        end;

        DoneSelList;
        InitSelList;
        if InArchive then
        begin
          if IsDir then FromName := DirFilter
          else FromName := '';
          Archiver^.CopyPrim(ToName, FromName, False);
        end
        else
        begin
          ResetTotals;
          if FileCopyOptions and fsDisableCopyStat = 0 then
          begin
            CountSelTotals(FManager, Optimized);
            if CopyStatus = dsCancel then goto Quit;
          end;
          S := ToName;
          I := 0;
          while (I < List^.Count) and (CopyStatus <> dsCancel) do
          begin
            if AppendSel then CopyStatus := dsAppendAll;
            SR := List^.At(I);
            if (not Optimized and SR^.Selected) or
               (Optimized and (Byte(SR^.Selected) = 255)) then
            begin
              IsDir := SR^.Attr and Directory <> 0;
              GetRecStr(SR, FromName);
              ToName := S;
              FixToName(FromName, ToName);
              CancelSysErrors := False;
              ValidNames(FromName, ToName);
              if CancelSysErrors then Break;
	      SelFixToName(IsDir, Wild, ADest, CopyDirData.ToName, ToName);
{ Added 05-26-03 to support optimal fill by size }
              if FillBySize and FormatToName then
                FormatStr(ToName, ToName, FillCount);
              if IsDir then DirCopyPrim(FromName, ToName,
                DirFilter, NewMask, CRCList)
              else FCopyPrim(FromName, ToName);
              if (CopyStatus <> dsCancel) and (not Skipped or
                 (FileCopyOptions and fsUnselectSkipped <> 0)) then
              begin
                SetSelect(SR, False);
                if FMOptions and foUnsel <> 0 then FocusItem(Focused);
              end;
            end;
            Inc(I);
          end;
          if Optimized and (CopyStatus <> dsCancel) then
          begin
{ Added 05-26-03 to support optimal fill by size }
            if FillBySize and FormatToName then
            begin
              Inc(FillCount);
              ToName := S;
              goto NoPrompt;
            end;
            Message(Desktop, evBroadcast, cmUpdateDisk, nil);
            Goto Start;
          end;
        end;
      end
      else if InArchive then
      begin
        if IsDir then Archiver^.CopyPrim(ToName, DirFilter, True)
        else Archiver^.CopyPrim(ToName, '', True);
        ToName := AddedSlash(ToName) + JustFileName(FromName);
        FocusName := True;
      end
      else
      begin
{ Added 05-12-03 to support file splitting }
        if not IsDir and (Length(ToName) > 1) and (ToName[1] = '/') then
        begin
          System.Delete(ToName, 1, 1);
          SplitFixToName(FromName, ToName);
          Splitting := True;
        end
        else if (Length(ToName) > 1) and (ToName[1] = '+') then
        begin
          System.Delete(ToName, 1, 1);
          TrimSt(ToName);
          CopyStatus := dsAppendAll;
        end;
        GetRecStr(SR, FromName);
        FixToName(FromName, ToName);
        CancelSysErrors := False;
        ValidNames(FromName, ToName);
        if CancelSysErrors then goto Quit;
        SingleFixToName(IsDir, Wild, Options and ofValidate <> 0, False,
	  SR, FromName, ADest, CopyDirData.ToName, ToName);
        ResetTotals;
        if IsDir then
        begin
          if Wild and (SR^.Name[1] = '.') then
          begin
            DirExpectedMsgBox;
            goto Quit;
          end;
          if FileCopyOptions and fsDisableCopyStat = 0 then
          begin
            DirCountPrim(FromName, DirFilter, CRCList);
            if CopyStatus = dsCancel then goto Quit;
          end;
          if (Settings and seUnfold <> 0) and
             (SR^.Name[1] = '.') then CopyFilesByMask(
               AddedSlash(FromName), ToName, DirFilter, NewMask, CRCList)
          else DirCopyPrim(FromName, ToName, DirFilter, NewMask, CRCList);
        end
        else
        begin
          if FileCopyOptions and fsDisableCopyStat = 0 then
          begin
            BytesTotal := lGetFileRealSize(SR^.Attr, SR^.Size);
            FilesTotal := 1;
          end;
{ Added 05-12-03 to support file splitting }
          SplitCopy := Splitting;
          ToName := FCopyPrim(FromName, ToName);
          SplitCopy := False;
        end;
        FocusName := (DeleteStatus = dsResume) or (CopyStatus <> dsCancel);
      end;
      Message(Desktop, evBroadcast, cmUpdateDisk, nil);
      if FocusName then
      begin
        FocusFileName(ToName);
        Opposite^.FocusFileName(ToName);
      end;
    end;
  end;

{ Added 2005.08.30 to support regexp file operations }
Quit:
  DisposeFileRegExp;
end;

procedure FMRenMovPrim(FManager: PPanel; const ADest: FNameStr;
  One: Boolean);
var
{ Added 05-12-03 to support file splitting }
  Splitting: Boolean;
{ Added 05-26-03 to support optimal fill by size }
  FillBySize, FormatToName: Boolean;
  IsDir, Wild, Optimized, Aborted, AppendSel, FocusName: Boolean;
  C: Word;
  I: Integer;
  L: Longint;
{ Added 05-26-03 to support optimal fill by size }
  FillCount: Longint;
  D: PDialog;
  SR: PPanelRec;
  R: TRect;
  RenMovDirData: TCopyNameData;
  S, FromName, ToName: FNameStr;
label
  Start, NoPrompt, Quit;
begin
  Optimized := False;
  AppendSel := False;
{ Added 05-12-03 to support file splitting }
  Splitting := False;
{ Added 05-26-03 to support optimal fill by size }
  FillBySize := False;
  FillCount := 0;
  SplitSize := -1;
  with FManager^ do
  begin
Start:
    if One and (Status >= stInfo) then
    begin
      Pending.What := evCommand;
      Pending.Command := cmDecoders;
    end;
    if (Status >= stInfo) or (List^.Count = 0) then Exit;
    FocusName := False;
    CopyStatus := dsOverwrite;
    DeleteStatus := dsDelete;
    CopyErrorStatus := deRetry;
    DeleteErrorStatus := deRetry;
    TryAll := False;
    if not One and (SelCount > 0) and
      (Settings and seIgnoreSelection = 0) then
    begin
      L := SelCount;
      if Options and ofValidate <> 0 then
      begin
        FromName := 'Move the contents of %d selected drives to';
        if L = 1 then System.Delete(FromName, Length(FromName) - 3, 1);
        FormatStr(S, FromName, L);
        IsDir := True;
      end
      else
      begin
        FromName := 'Rename or move %d selected files to';
        if L = 1 then System.Delete(FromName, Length(FromName) - 3, 1);
        FormatStr(S, FromName, L);
        IsDir := SelDirCount <> 0;
      end;
    end
    else
    begin
      SR := List^.At(Focused);
      if SR^.Name[1] = ':' then FromName := RootName(ListDir^)
      else if SR^.Name[1] = '\' then GetRecStr(SR, FromName)
      else AddNameExt('', SR, FromName);
      IsDir := SR^.Attr and Directory <> 0;
      if IsDir then SetDirLabel('Move', FromName, SR, False, S)
      else S := 'Rename or move "' + TrimmedName(FromName, 43) + '" to';
    end;

    if ADest <> '' then ToName := ADest
    else if (One and (GetShiftState and (kbLeftShift + kbRightShift) = 0)) or
      (Opposite^.State and sfVisible = 0) or
      (Opposite^.Status >= stInfo) then
        if One or (SelCount = 0) then ToName := FromName
        else ToName := ''
    else if Opposite^.InArchive and not InArchive then
    with Opposite^.Archiver^ do
    begin
      ToName := GetTopName;
      if ArchiveRec^.Extension <> nil then
        ToName := ArchiveRec^.Extension^ + ':' + ToName;
    end
    else
    begin
      if Opposite^.InArchive then ToName := Opposite^.ListDir^
      else Opposite^.GetListDir(ToName);
      ToName := AddedSlash(ToName);
    end;
    if (One or (SelCount = 0) or (Settings and seIgnoreSelection <> 0)) and
       (ToName <> '') and (ToName[Length(ToName)] = '\') and
       (Options and ofValidate = 0) and not (SR^.Name[1] in [':', '.']) and
       not InArchive and not Opposite^.InArchive then
    begin
      HistoryAdd(FNameHistoryId,
        AddedSlash(ListDir^) + JustFileName(FromName), True);
      ToName := ToName + JustFileName(FromName);
    end;
    if (ADest <> '') and (FMOptions and foDragPrompt = 0) and
       not Optimized then Goto NoPrompt;
    R.Assign(0, 0, 70, 8 + 4 * Byte(IsDir));
    if IsDir then D := InitDirRenMovDialog(R, S, InArchive)
    else D := InitRenMovDialog(R, S, False, False);
    if IsDir then GetCopyDirData(FManager, D, RenMovDirData, ToName, C)
    else
    begin
      RenMovDirData.ToName := ToName;
      RenMovDirData.Options := Byte(FileCopyOptions and fsNT_SysCopy <> 0);
      C := Application^.ExecuteDialog(D, @RenMovDirData, False);
      ToName := RenMovDirData.ToName;
      if RenMovDirData.Options and 1 <> 0 then
	FileCopyOptions := FileCopyOptions or fsNT_SysCopy
      else FileCopyOptions := FileCopyOptions and not fsNT_SysCopy;
    end;
    TrimSt(ToName);
{ Added 2005.08.30 to support regexp file operations }
    PreprocessFileRegExp(ToName);
    FileRegExpInitDirLen := Length(ListDir^) + 1;
    if (C <> cmCancel) and (ToName <> '') then
    begin
NoPrompt:
      Wild := IsWild(ToName);
      if (Pos(':', ToName) > 2) and not InArchive and
{ Added 05-12-03 to support file splitting }
        not (ToName[1] in ['+', '/']) then
      begin
        if IsDir then FromName := DirFilter
        else FromName := '';
        CopyToArchive(FManager, One, True, ToName, FromName, nil);
        goto Quit;
      end;
      if (FManager^.Settings and seAdvancedFilter <> 0) and
         (CopyRenameFilter.Text = nil) then SetCopyRenFilter(FManager);
      if not One and (SelCount > 0) and
        (Settings and seIgnoreSelection = 0) then
      begin
        { Added 05-26-03 to support optimal fill by size }
        if (Length(ToName) > 1) and (ToName[1] = '/') then
        begin
          System.Delete(ToName, 1, 1);
          SplitFixToName(FromName, ToName);
          FillBySize := True;
          FormatStr(S, ToName, FillCount);
          FormatToName := S <> ToName;
        end
        else if (Length(ToName) > 1) and (ToName[1] = '+') then
        begin
          System.Delete(ToName, 1, 1);
          TrimSt(ToName);
          AppendSel := True;
        end
        else if not ((ToName[0] = #2) and (ToName[2] = ':')) and
          not Wild then ToName := AddedSlash(ToName);

{ Added 05-26-03 to support optimal fill by size }
        if (FillBySize or
           (FMOptions and foCheckFreeSpace <> 0) and not AppendSel) then
        begin
          S := lFExpand(ToName);
          if (FillBySize or (ListDir^[1] <> S[1])) and
             (DeviceDest(S) = '') then
          begin
            OptimalFill(List, S, 'move', Optimized, Aborted,
              SplitSize, FormatToName and (FillCount > 0));
            if Aborted then goto Quit;
          end;
        end;

        DoneSelList;
        InitSelList;
        ResetTotals;
        if FileCopyOptions and fsDisableCopyStat = 0 then
        begin
          CountSelTotals(FManager, Optimized);
          if CopyStatus = dsCancel then goto Quit;
        end;
        S := ToName;
        I := 0;
        while (I < List^.Count) and
          (CopyStatus <> dsCancel) and (DeleteStatus <> dsCancel) do
        begin
          if AppendSel then CopyStatus := dsAppendAll;
          SR := List^.At(I);
          if (not Optimized and SR^.Selected) or
             (Optimized and (Byte(SR^.Selected) = 255)) then
          begin
            IsDir := SR^.Attr and Directory <> 0;
            GetRecStr(SR, FromName);
            ToName := S;
            FixToName(FromName, ToName);
            CancelSysErrors := False;
            ValidNames(FromName, ToName);
            if CancelSysErrors then Break;
	    SelFixToName(IsDir, Wild, ADest, RenMovDirData.ToName, ToName);
{ Added 05-26-03 to support optimal fill by size }
            if FillBySize and FormatToName then
              FormatStr(ToName, ToName, FillCount);
            if IsDir then DirRenMovPrim(FromName, ToName, DirFilter,
              NewMask, CRCList, True)
            else FRenMovPrim(FromName, ToName);
            if (CopyStatus <> dsCancel) and (not Skipped or
               (FileCopyOptions and fsUnselectSkipped <> 0)) then
            begin
              SetSelect(SR, False);
              if FMOptions and foUnsel <> 0 then FocusItem(Focused);
            end;
          end;
          Inc(I);
        end;
        if Optimized and (CopyStatus <> dsCancel) and
           (DeleteStatus <> dsCancel) then
        begin
{ Added 05-26-03 to support optimal fill by size }
          if FillBySize and FormatToName then
          begin
            Inc(FillCount);
            ToName := S;
            goto NoPrompt;
          end;
          Message(Desktop, evBroadcast, cmUpdateDisk, nil);
          Goto Start;
        end;
      end
      else
      begin
{ Added 05-12-03 to support file splitting }
        if not IsDir and (Length(ToName) > 1) and (ToName[1] = '/') then
        begin
          System.Delete(ToName, 1, 1);
          SplitFixToName(FromName, ToName);
          Splitting := True;
        end
        else if (Length(ToName) > 1) and (ToName[1] = '+') then
        begin
          System.Delete(ToName, 1, 1);
          TrimSt(ToName);
          CopyStatus := dsAppendAll;
        end;
        GetRecStr(SR, FromName);
        FixToName(FromName, ToName);
        CancelSysErrors := False;
        ValidNames(FromName, ToName);
        if CancelSysErrors then goto Quit;
        SingleFixToName(IsDir, Wild, Options and ofValidate <> 0, True,
	  SR, FromName, ADest, RenMovDirData.ToName, ToName);
        ResetTotals;
        if IsDir then
        begin
          if Wild and (SR^.Name[1] = '.') then
          begin
            DirExpectedMsgBox;
            goto Quit;
	  end;
	  if (FileCopyOptions and fsDisableCopyStat = 0) and
	     (CompUCString(PrevDir(FromName), PrevDir(ToName)) <> Equal) then
          begin
            DirCountPrim(FromName, DirFilter, CRCList);
            if CopyStatus = dsCancel then goto Quit;
          end;
          if (Settings and seUnfold <> 0) and (SR^.Name[1] = '.') then
            MoveFilesByMask(AddedSlash(FromName), ClearedSlash(ToName),
              DirFilter, NewMask, CRCList)
          else DirRenMovPrim(FromName, ToName, DirFilter, NewMask,
            CRCList, SR^.Name[1] <> '.');
        end
        else
        begin
          if FileCopyOptions and fsDisableCopyStat = 0 then
          begin
            BytesTotal := lGetFileRealSize(SR^.Attr, SR^.Size);
            FilesTotal := 1;
          end;
{ Added 05-12-03 to support file splitting }
          SplitCopy := Splitting;
          ToName := FRenMovPrim(FromName, ToName);
          SplitCopy := False;
        end;
        FocusName := (DeleteStatus = dsResume) or
          ((CopyStatus <> dsCancel) and (DeleteStatus <> dsCancel));
      end;
      Message(Desktop, evBroadcast, cmUpdateDisk, nil);
      if FocusName then
      begin
        FocusFileName(ToName);
        Opposite^.FocusFileName(ToName);
      end;
    end;
  end;

{ Added 2005.08.30 to support regexp file operations }
Quit:
  DisposeFileRegExp;
end;

end.