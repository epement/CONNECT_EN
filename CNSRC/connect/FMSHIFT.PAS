{$I-,F+,O+,X+}
unit FMShift;

interface

uses FileMngr;

procedure ShiftDeletePrim(FManager: PPanel);
procedure ShiftCopyPrim(FManager: PPanel);
procedure ShiftRenMovPrim(FManager: PPanel);

implementation

uses Dos, Objects, Drivers, Views, Memory, Dialogs, HistList, App, MsgBox,
  Swaps, ClipPrim, PanelRec, DirPrim, DiskBase, DiskPrim, Archives, FMPrim,
  History, LFN, TPString, Consts, Commands, Defaults;

function ClipActionMsgBox(const ActionStr, DestStr: String): Word;
var
  W: Word;
begin
  if ActionStr[1] = 'D' then W := mfDelTrashConf else W := mfConfirmation;
  ClipActionMsgBox := MessageBox(
    ^C + ActionStr + ' all selected files in the Clipboard ' +
    DestStr, nil, W + mfOkCancel);
end;

function DirActionMsgBox(const ActionStr, NameStr, DestStr: String): Word;
var
  W: Word;
  S: String;
begin
  if ActionStr[1] = 'D' then W := mfDelTrashConf else W := mfConfirmation;
  if (NameStr[1] = '\') and (NameStr = RootName(NameStr)) then
    S := 'contents of the'#13^C'network resource '
  else if (NameStr[0] = #2) and (NameStr[2] = ':') then
    S := 'contents of the'#13^C'drive '
  else S := 'directory'#13^C;
  S := ^C + ActionStr + ' the ' + S +
    TrimmedName(NameStr, 32);
  if DestStr <> '' then S := S + #13^C'to ' +
    TrimmedName(DestStr, 29);
  S := S + ' ?';
  DirActionMsgBox := MessageBox(S, nil, W + mfOkCancel);
end;

function FilterActionMsgBox(const ActionStr,
  SourceStr, DestStr, FilterStr: String): Word;
var
  W: Word;
  N: Integer;
  S, SS: String;
begin
  if ActionStr[1] = 'D' then W := mfDelTrashConf else W := mfConfirmation;
  if DestStr = '' then N := 27
  else if Length(DestStr) < 12 then N := 24 - Length(DestStr)
  else N := 12;
  S := TrimmedName(SourceStr, N);
  if DestStr <> '' then
  begin
    if Length(S) < 12 then N := 24 - Length(S)
    else N := 12;
    SS := TrimmedName(DestStr, N);
  end;
  S := ^C + ActionStr + ' all files matching'#13^C'"' +
    TrimmedName(FilterStr, 34) + '"'#13^C'from ' + S;
  if DestStr <> '' then S := S + ' to ' + SS;
  S := S + ' ?';
  FilterActionMsgBox := MessageBox(S, nil, W + mfOkCancel);
end;

procedure ValidDirName(var S: FNameStr; ClearSlash: Boolean);
begin
  if (S <> '') and (S[1] in ['\', '.']) then S := lFExpand(S);
  if ClearSlash then S := ClearedSlash(S);
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

procedure ShiftDeletePrim(FManager: PPanel);
var
  Clip: Boolean;
  P: Byte;
  I: Integer;
  D: PDialog;
  R: TRect;
  Control: PView;
  ActionStr: String[7];
  Dir, Name, Ext: String;
  S, SS: FNameStr;
  CS: String;
begin
  with FManager^ do
  begin
    R.Assign(0, 0, 70, 8);
    D := InitSimpleDialog(R, 'Delete', hcShiftDeleteDialog);
    with D^ do
    begin
      Options := Options or ofCentered;
      R.Assign(3, 3, Size.X - 6, 4);
      Control := New(PInputLine, Init(R, 255));
      Insert(Control);
      StandardHistory(Control, FNameHistoryId);
      R.Assign(2, 2, Size.X - 3, 3);
      Insert(New(PLabel, Init(R, '~D~elete', Control)));
    end;
    S := '';
    if Application^.ExecuteDialog(D, @S, False) = cmCancel then Exit;
{ Added 2005.08.30 to support regexp file operations }
    PreprocessFileRegExp(S);
{ Added 04.26.03 to support empty dir deletion }
    if S = '[]' then
    begin
      GetCurDir(0, S);
      if MessageBox(^C'Delete all empty directories'#13^C'from |' +
	S + '| ?', nil, mfDelTrashConf + mfOkCancel) = cmOk then
      begin
	ClearDirs(AddedSlash(S), nil, False, True);
	Message(Desktop, evBroadcast, cmUpdateDisk, nil);
      end;
      Exit;
    end;
    ActionStr := 'Delete';
    TrimSt(S);
    if S = '' then
    begin
      if DiskClipStream = nil then Exit;
      if ClipActionMsgBox(ActionStr, '?') = cmCancel then Exit;
      Message(Desktop, evBroadcast, cmUpdateViews, nil);
      I := ClipArea^.KB;
      Clip := True;
    end
    else Clip := False;

    CS := '';
    repeat
      if Clip then
      begin
        if CS = '' then
        begin
          if I > ClipArea^.KK then Break;
          GetClipLine(I, CS);
          Inc(I);
        end;
	FetchFileName(CS, S);
        if S = '' then Continue;
      end;
      DeleteStatus := dsDelete;
      DeleteErrorStatus := deRetry;
      ValidDirName(S, True);
      CancelSysErrors := False;
      if DirPresent(S) then
      begin
        if not Clip and
          (DirActionMsgBox(ActionStr, S, '') = cmCancel) then Exit;
	DirDeletePrim(lFExpand(S), nil, True, False);
      end
      else if CancelSysErrors then Break
      else
      begin
        GetListDir(SS);
        lFSplit(S, Dir, Name, Ext);
        if IsWild(S) then
	begin
          if Dir = '' then Dir := SS[1] + ':\';
          if not Clip and
            (FilterActionMsgBox(ActionStr, ClearedSlash(Dir), '',
              Name + Ext) = cmCancel) then Exit;
          DeleteFilesByMask(AddedSlash(Dir), Name + Ext, nil);
        end
        else
        begin
          if Dir = '' then Dir := SS + '\';
          if DeviceDest(S) = '' then S := Dir + Name + Ext;
	  if not Clip and (MessageBox(^C'Delete the file'#13^C'|' +
	    S + '| ?', nil, mfDelTrashConf + mfOkCancel) = cmCancel) then Exit;
	  FDeletePrim(S);
	end;
      end;
      if not Clip or (DeleteStatus = dsCancel) then Break;
    until False;
    Message(Desktop, evBroadcast, cmUpdateDisk, nil);
  end;
end;

function GetShiftData(FManager: PPanel;
  var Data: TShiftCopyNameData;
  var FromName, ToName, DD: FNameStr; RenMov: Boolean): Word;
var
  C: Word;
  D: PDialog;
  R: TRect;
begin
  with FManager^ do
  begin
    R.Assign(0, 0, 70, 12);
    if RenMov then D := InitShiftRenMovDialog(R)
    else D := InitShiftCopyDialog(R);
    Data.FromName := '';
    if (Opposite^.State and sfVisible <> 0) and
       (Opposite^.Status < stInfo) then
    begin
      Opposite^.GetListDir(Data.ToName);
      Data.ToName := AddedSlash(Data.ToName);
    end
    else Data.ToName := '';
    Data.Options := Byte(FileCopyOptions and fsNT_SysCopy <> 0);
    C := Application^.ExecuteDialog(D, @Data, False);
    if C <> cmCancel then
    begin
      FromName := Data.FromName;
      ToName := Data.ToName;
      TrimSt(FromName);
      TrimSt(ToName);
      if ToName = '' then GetCurDir(0, ToName);
      DD := DeviceDest(ToName);
      if Data.Options and 1 <> 0 then
	FileCopyOptions := FileCopyOptions or fsNT_SysCopy
      else FileCopyOptions := FileCopyOptions and not fsNT_SysCopy;
    end;
    GetShiftData := C;
  end;
end;

procedure CountClipTotals;
var
  Wild: Boolean;
  I, P: Integer;
  S, Dir, Name: String;
  SR: lSearchRec;
begin
  I := ClipArea^.KB;
  S := '';
  repeat
    if S = '' then
    begin
      if I > ClipArea^.KK then Break;
      GetClipLine(I, S);
      Inc(I);
    end;
    FetchFileName(S, Name);
    if Name = '' then Continue;

    ValidDirName(Name, True);
    Wild := IsWild(Name);
    if Wild then
    begin
      Dir := JustPathName(Name);
      if Dir = '' then
      begin
        GetCurDir(0, Dir);
        Dir := Dir[1] + ':\';
      end;
      DirCountPrim(Dir, JustFileName(Name), nil);
    end
    else
    begin
      CancelSysErrors := False;
      lFindFirst(Name, AnyFile and not VolumeId, SR);
      lFindClose(SR);
      if CancelSysErrors then Break;
      if DosError = 0 then
        if SR.SR.Attr and Directory <> 0 then
          DirCountPrim(Name, '*.*', nil)
        else
        begin
          BytesTotal := BytesTotal + SR.SR.Size;
          Inc(FilesTotal);
        end;
    end;
  until CopyStatus = dsCancel;
end;

procedure SplitFromName(var FromName, FrDr, FrNm, FrEx, AFilter: FNameStr;
  IsDir, FromWild: Boolean);
begin
  if IsDir and not ((FromName[0] = #2) and (FromName[2] = ':')) then
    FromName := AddedSlash(lFExpand(FromName))
  else if (FromName[0] > #2) and (FromName[2] = ':') and
    (FromName[3] <> '\') then FromName := lFExpand(FromName);
  lFSplit(FromName, FrDr, FrNm, FrEx);
  if FromWild then
  begin
    AFilter := FrNm + FrEx;
    if FrDr = '' then
    begin
      GetCurDir(0, FrDr);
      FrDr := FrDr[1] + ':\';
    end
    else if Pos(':', FrDr) = 0 then
      FrDr := AddedSlash(lFExpand(FrDr));
  end
  else AFilter := '*.*';
end;

procedure SplitToName(var ToName, ToDr, ToNm, ToEx, AMask: FNameStr;
  const DD: FNameStr; IsDir, FromWild, ToWild: Boolean);
begin
  if DD <> '' then ToName := DD
  else
  begin
    ValidDirName(ToName, False);
    if ((IsDir or FromWild) and not ToWild) or
       ((ToName[0] = #2) and (ToName[2] = ':')) then
      ToName := AddedSlash(lFExpand(ToName))
    else if (ToName[0] > #2) and (ToName[2] = ':') and
      (ToName[3] <> '\') then ToName := lFExpand(ToName);
  end;
  lFSplit(ToName, ToDr, ToNm, ToEx);
  if ToWild then
  begin
    AMask := ToNm + ToEx;
    ToNm := '';
    ToEx := '';
  end
  else AMask := '';
end;

procedure ShiftCopyPrim(FManager: PPanel);
var
  IsDir, FromWild, ToWild, Clip: Boolean;
  P: Byte;
  I: Integer;
  ActionStr: String[7];
  CopyDirData: TShiftCopyNameData;
  AFilter, AMask: String;
  FrDr, ToDr, FrNm, ToNm, FrEx, ToEx: String;
  S, DD, FromName, ToName: FNameStr;
  CS: String;
label
  Quit;
begin
  with FManager^ do
  begin
    CopyStatus := dsOverwrite;
    CopyErrorStatus := deRetry;
    TryAll := False;
    if GetShiftData(FManager,
      CopyDirData, FromName, ToName, DD, False) = cmCancel then Exit;
    ActionStr := 'Copy';

{ Added 2005.08.30 to support regexp file operations }
    PreprocessFileRegExp(ToName);

    if FromName = '' then
    begin
      if DiskClipStream = nil then goto Quit;
      if DD <> '' then S := DD
      else
      begin
        S := ToName;
        ValidDirName(S, False);
      end;
      if ClipActionMsgBox(ActionStr,
        'to'#13^C'|' + S + '| ?') = cmCancel then goto Quit;
      Message(Desktop, evBroadcast, cmUpdateViews, nil);
      if Pos(':', ToName) > 2 then
      begin
        ClipboardToArchive(False, ToName);
        goto Quit;
      end;
      I := ClipArea^.KB;
      Clip := True;
    end
    else Clip := False;

    ResetTotals;
    if Clip and (FileCopyOptions and fsDisableCopyStat = 0) then
    begin
      CountClipTotals;
      if CopyStatus = dsCancel then goto Quit;
    end;

    CS := '';
    repeat
      if Clip then
      begin
        if CS = '' then
        begin
          if I > ClipArea^.KK then Break;
          GetClipLine(I, CS);
          Inc(I);
        end;
        FetchFileName(CS, FromName);
        if FromName = '' then Continue;
	ToName := CopyDirData.ToName;
        TrimSt(ToName);
      end;

      FromWild := IsWild(FromName);
      ToWild := IsWild(ToName);

      ValidDirName(FromName, True);
      CancelSysErrors := False;
      IsDir := DirPresent(FromName);
      if CancelSysErrors then Break;
      SplitFromName(FromName, FrDr, FrNm, FrEx, AFilter, IsDir, FromWild);
      SplitToName(ToName, ToDr, ToNm, ToEx, AMask, DD,
        IsDir, FromWild, ToWild);

      if IsDir then
      begin
        FromName := ClearedSlash(FrDr);
        if DD = '' then ToName := AddedSlash(ToDr + ToNm + ToEx);
	IsDir := not (CopyDirData.ToName[Length(CopyDirData.ToName)] in
	  [':', '\']) and (CopyDirData.ToName[1] <> '.');
        S := ToDr + ToNm + ToEx + AMask;
        if IsDir then S := ClearedSlash(S);
        if not Clip and
          (DirActionMsgBox(ActionStr, FromName, S) = cmCancel) then goto Quit;
        if DD = '' then
        begin
          CancelSysErrors := False;
          ValidNames(FromName, ToName);
          if CancelSysErrors then Break;
          if IsDir then ToName := PrevDir(ToName);
        end;
        if not Clip and (FileCopyOptions and fsDisableCopyStat = 0) then
        begin
          DirCountPrim(FromName, AFilter, nil);
          if CopyStatus = dsCancel then goto Quit;
        end;
        DirCopyPrim(FromName, ToName, AFilter, AMask, nil);
      end
      else if FromWild then
      begin
        if not Clip and
          (FilterActionMsgBox(ActionStr, ClearedSlash(FrDr),
            ToDr + ToNm + ToEx + AMask, AFilter) = cmCancel) then goto Quit;
        if not Clip and (FileCopyOptions and fsDisableCopyStat = 0) then
        begin
          DirCountPrim(FrDr, AFilter, nil);
          if CopyStatus = dsCancel then goto Quit;
        end;
        if DD = '' then
          CopyFilesByMask(AddedSlash(FrDr), ToDr, AFilter, AMask, nil)
        else CopyFilesByMask(AddedSlash(FrDr), ToName, AFilter, AMask, nil);
      end
      else
      begin
        CancelSysErrors := False;
        FromName := lFExpand(FromName);
        if DD = '' then ValidNames(FromName, ToName);
        if CancelSysErrors then Break;
        FCopyPrim(FromName, ToName);
      end;
      if not Clip or (CopyStatus = dsCancel) then Break;
    until False;
    Message(Desktop, evBroadcast, cmUpdateDisk, nil);
  end;

{ Added 2005.08.30 to support regexp file operations }
Quit:
  DisposeFileRegExp;
end;

procedure ShiftRenMovPrim(FManager: PPanel);
var
  IsDir, FromWild, ToWild, DoRename, DoSearch, Clip: Boolean;
  P: Byte;
  I: Integer;
  ActionStr: String[7];
  CopyDirData: TShiftCopyNameData;
  AFilter, AMask: String;
  FrDr, ToDr, FrNm, ToNm, FrEx, ToEx: String;
  S, DD, FromName, ToName: FNameStr;
  CS: String;
label
  Quit;
begin
  with FManager^ do
  begin
    CopyStatus := dsOverwrite;
    DeleteStatus := dsDelete;
    CopyErrorStatus := deRetry;
    DeleteErrorStatus := deRetry;
    TryAll := False;
    DoSearch := False;
    if GetShiftData(FManager,
      CopyDirData, FromName, ToName, DD, True) = cmCancel then Exit;

{ Added 2005.08.30 to support regexp file operations }
    PreprocessFileRegExp(ToName);

    if FromName = '' then
    begin
      if DiskClipStream = nil then goto Quit;
      if DD <> '' then S := DD
      else
      begin
        S := ToName;
        ValidDirName(S, False);
      end;
      if ClipActionMsgBox('Move',
        'to'#13^C'|' + S + '| ?') = cmCancel then goto Quit;
      Message(Desktop, evBroadcast, cmUpdateViews, nil);
      if Pos(':', ToName) > 2 then
      begin
        ClipboardToArchive(True, ToName);
        goto Quit;
      end;
      I := ClipArea^.KB;
      Clip := True;
    end
    else Clip := False;

    ResetTotals;
    if Clip and (FileCopyOptions and fsDisableCopyStat = 0) then
    begin
      CountClipTotals;
      if CopyStatus = dsCancel then goto Quit;
    end;

    CS := '';
    repeat
      if Clip then
      begin
        if CS = '' then
        begin
          if I > ClipArea^.KK then Break;
          GetClipLine(I, CS);
          Inc(I);
        end;
        FetchFileName(CS, FromName);
        if FromName = '' then Continue;
	ToName := CopyDirData.ToName;
        TrimSt(ToName);
      end;

      FromWild := IsWild(FromName);
      ToWild := IsWild(ToName);

      ValidDirName(FromName, True);
      CancelSysErrors := False;
      IsDir := DirPresent(FromName);
      if CancelSysErrors then Break;
      SplitFromName(FromName, FrDr, FrNm, FrEx, AFilter, IsDir, FromWild);
      SplitToName(ToName, ToDr, ToNm, ToEx, AMask, DD,
        IsDir, FromWild, ToWild);

      if IsDir then
      begin
        FromName := ClearedSlash(FrDr);
        if DD = '' then ToName := AddedSlash(ToDr + ToNm + ToEx);
	DoRename := (CompUCString(PrevDir(FromName), PrevDir(ToName)) = Equal);
	if not DoRename then ToName := AddedSlash(ToName);
        if DoRename then ActionStr := 'Rename'
        else ActionStr := 'Move';
        IsDir := not DoRename and not
	  (CopyDirData.ToName[Length(CopyDirData.ToName)] in [':', '\']) and
	  (CopyDirData.ToName[1] <> '.');
        S := ToDr + ToNm + ToEx + AMask;
        if IsDir or DoRename then S := ClearedSlash(S);
        if not Clip and
          (DirActionMsgBox(ActionStr, FromName, S) = cmCancel) then goto Quit;
        if DD = '' then
        begin
          CancelSysErrors := False;
          if not DoRename then ValidNames(FromName, ToName);
          if CancelSysErrors then Break;
          if IsDir then ToName := PrevDir(ToName);
        end;
        if not Clip and not DoRename and
          (FileCopyOptions and fsDisableCopyStat = 0) then
        begin
          DirCountPrim(FromName, AFilter, nil);
          if CopyStatus = dsCancel then goto Quit;
        end;
        DirRenMovPrim(FromName, ToName, AFilter, AMask, nil, True);
      end
      else if FromWild then
      begin
        DoRename := (ToDr + ToNm + ToEx = '') or (FrDr = ToDr);
        if DoRename then
        begin
          ToDr := FrDr;
          ActionStr := 'Rename';
        end
        else
        begin
          if Pos(':', ToDr) = 0 then
            ToDr := AddedSlash(lFExpand(ToDr));
          ActionStr := 'Move';
        end;
        if not Clip and
          (FilterActionMsgBox(ActionStr, ClearedSlash(FrDr),
            ToDr + ToNm + ToEx + AMask, AFilter) = cmCancel) then goto Quit;
        if not Clip and not DoRename and
          (FileCopyOptions and fsDisableCopyStat = 0) then
        begin
          DirCountPrim(FrDr, AFilter, nil);
          if CopyStatus = dsCancel then goto Quit;
        end;
        if DD <> '' then MoveFilesByMask(AddedSlash(FrDr), ToName,
          AFilter, AMask, nil)
        else if FrDr = ToDr then
          RenameFilesByMask(AddedSlash(FrDr), AFilter, AMask, nil)
        else MoveFilesByMask(AddedSlash(FrDr), ClearedSlash(ToDr),
          AFilter, AMask, nil);
      end
      else
      begin
        CancelSysErrors := False;
        FromName := lFExpand(FromName);
        if DD = '' then ValidNames(FromName, ToName);
        if CancelSysErrors then Break;
        FRenMovPrim(FromName, ToName);
        DoSearch := not Clip and (CopyStatus <> dsCancel) and
          (DeleteStatus <> dsCancel) and (UCPos(ListDir^, ToName) <> 0);
      end;
      if not Clip or (CopyStatus = dsCancel) or
        (DeleteStatus = dsCancel) then Break;
    until False;
    Message(Desktop, evBroadcast, cmUpdateDisk, nil);
    if DoSearch then
    begin
      GetItemNum(ClearedSlash(ToName), I);
      FocusItem(I);
    end;
  end;

{ Added 2005.08.30 to support regexp file operations }
Quit:
  DisposeFileRegExp;
end;

end.