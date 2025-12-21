{$I-,F+,O+,X+}
unit FMBBS;

interface

uses Objects, FileMngr;

const
  MaskTemplateName = 'CONNECT.MSK';

procedure EditFilesBBSPrim(FManager: PPanel);
procedure ReadFilesBBSPrim(FManager: PPanel;
  const APath: FNameStr; UnfoldSel: Boolean);

implementation

uses Dos, Drivers, Views, Memory, App, MsgBox, FEditor, EditPrim, PanelRec,
  DirPrim, BBSStuff, FMAbort, FMDialog, StrCol, HeapUMB, Keyboard, Tags,
  LFN, DosTools, ProgPath, TPString, Commands, Defaults;

procedure EditFilesBBSPrim(FManager: PPanel);
var
  SaveExplode: Boolean;
  I: Integer;
  L: Longint;
  P: PFilesBBSRec;
  R: TFilesBBSRec;
  SR: PPanelRec;
  E: PFileEditor;
  S: String;

procedure FindNameIndex;
var
  LongAndShort: Boolean;
  I, J: Integer;
  LName, SName: FNameStr;
  SS: String;
  F: lText;
begin
  R.Num := -1;
  I := 0;
  lAssignText(F, S);
  FailSysErrors := True;
  Reset(F.T);
  FailSysErrors := False;
  if IOResult <> 0 then Exit;
  if IsDevice(TextRec(F.T).Handle) then
  begin
    Close(F.T);
    InOutRes := 0;
    Exit;
  end;
  with FManager^ do
  begin
    SR := List^.At(Focused);
    AddNameExt('', SR, LName);
    if PanelRecHasPath(SR) and (SR^.ThePath^[1] = #0) then
    begin
      lGetShortFileName(LName, SName);
      SName := JustFileName(SName);
      LongAndShort := True;
    end
    else LongAndShort := False;
  end;
  LogEvent := lcDiskRead;
  DrawStatusLine('Searching for ' +
    TrimmedName(SName, 40) + ' description.');
  if not Eof(F.T) then
  begin
    SetUNIXTextMode;
    ReadLn(F.T, SS);
    if SS[Length(SS)] = #13 then SetDOSTextMode;
    TextSeek(F.T, 0);
  end;
  while not Eof(F.T) do
  begin
    if (KbdStatus = 1) and FMAbortAction then Break;
    Readln(F.T, SS);
    SS := Detab(SS, 8);
    J := Pos(' ', SS);
    if J <> 0 then SS[0] := Char(J - 1);
    if (SS <> '') and
       ((CompUCString(SS, LName) = Equal) or
	(LongAndShort and (CompUCString(SS, SName) = Equal))) then
    begin
      R.Num := I;
      Break;
    end;
    Inc(I);
  end;
  SetDOSTextMode;
  Close(F.T);
  InOutRes := 0;
end;

begin
  with FManager^ do
  begin
    if (List^.Count = 0) or (Status > stFull) or
       (Options and ofValidate <> 0) or InArchive then Exit;
    GetItemStr(Focused, S);
    if S[Length(S)] = ':' then Exit;
    if (ListDir^[0] > #2) and (Focused = 0) then S := S + '\1';
    S := AddedSlash(JustPathName(S));
    SetFirstFoundName(BBSNames, S);
    if S = '' then Exit;
    if FilesBBS^.Count = 0 then	FindNameIndex;
    SaveExplode := DoExplode;
    DoExplode := False;
    Desktop^.Lock;
    Message(Application, evCommand, cmOpenASCII, @S);
    E := Message(Desktop, evBroadcast, cmASCIIOpened, @S);
    if E <> nil then
    begin
      if FilesBBS^.Count = 0 then P := @R
      else P := FilesBBS^.At(Focused);
      if (P = nil) or (P^.Num = -1) or (P^.Num = MaxInt) then
      begin
	LongRec(L).Lo := 0;
	LongRec(L).Hi := MaxInt;
      end
      else
      begin
	E^.GetValidLine(P^.Num, S);
	I := Pos(' ', S);
	if I = 0 then
	  if (BBSSpaces = 0) or (Length(S) > 12) then I := Length(S) + 1
	  else I := BBSWrapPos
	else while (I < Length(S)) and (S[I + 1] = ' ') do Inc(I);
	LongRec(L).Lo := I;
	LongRec(L).Hi := P^.Num;
      end;
      Message(E, evBroadcast, cmGoToLine, Pointer(L));
      if LongRec(L).Lo = 0 then
      begin
	SR := List^.At(Focused);
	AddNameExt('', SR, S);
	if Settings and seLongNames = 0 then
	begin
	  lGetShortFileName(S, S);
	  S := JustFileName(S);
	end;
	if (BBSSpaces = 0) or (Length(S) > 12) then I := Length(S) + 1
	else I := BBSWrapPos;
	PadSt(S, I);
	PutStrPrim(E, S);
      end;
    end;
    Desktop^.Unlock;
    DoExplode := SaveExplode;
  end;
end;

procedure ReadFilesBBSPrim(FManager: PPanel;
  const APath: FNameStr; UnfoldSel: Boolean);
var
  Abort: Boolean;
  I, N, Num, SaveCount: Integer;
  P: PPanelRec;
  R: PFilesBBSRec;
  MaskList: PStringsCollection;
  FindPath, CurPath: FNameStr;
  F: lText;
  S, SS, C: String;

procedure NewLine;
begin
  with FManager^ do
  begin
    if N = -1 then Exit;
    FilesBBS^.AtFree(N);
{
    GetMem(R, SizeOf(TFilesBBSRec));
    R^.Text := NewStr(S);
}
    GetMemUMB(R, SizeOf(TFilesBBSRec));
    R^.Text := NewStrUMB(S);
    R^.Num := Num;
    FilesBBS^.AtInsert(N, R);
    if Length(S) > DirinfoWidth then DirinfoWidth := Length(S);
    S := '';
    N := -1;
    Num := -1;
    if {(I mod 16 = 0) and} (MaxAvail < 10000) then
    begin
      Abort := True;
      Application^.OutOfMemory;
    end;
  end;
end;

procedure ReadDescriptions(const ADir: FNameStr; Unfold: Boolean);
var
  II, J: Integer;
begin
  with FManager^ do
  begin
    if (List^.Count = 0) or (Status >= stTree) then Exit;
    if InArchive then
    begin
      if Archiver^.UserListName = nil then Exit;
      S := Archiver^.UserListName^;
    end
    else
    begin
      S := AddedSlash(ADir);
      SetFirstFoundName(BBSNames, S);
      if S = '' then Exit;
    end;
    lAssignText(F, S);
    FailSysErrors := True;
    Reset(F.T);
    FailSysErrors := False;
    if IOResult <> 0 then Exit;
    if IsDevice(TextRec(F.T).Handle) then
    begin
      Close(F.T);
      InOutRes := 0;
      Exit;
    end;
    LogEvent := lcDiskRead;
    DrawStatusLine('Reading descriptions from ' + TrimmedName(S, 41) + '.');
    if FilesBBS^.Count = 0 then
      for II := 0 to List^.Count - 1 do FilesBBS^.Insert(nil);
    if FilesBBS^.Count < List^.Count then
    begin
      Close(F.T);
      InOutRes := 0;
      Abort := True;
      Application^.OutOfMemory;
      Exit;
    end;
    S := '';
    N := -1;
    I := 0;
    Num := -1;
    if not Eof(F.T) then
    begin
      SetUNIXTextMode;
      ReadLn(F.T, SS);
      if SS[Length(SS)] = #13 then SetDOSTextMode;
      TextSeek(F.T, 0);
    end;
    while not Eof(F.T) and not Abort do
    begin
      if (KbdStatus = 1) and FMAbortAction then
      begin
	Abort := True;
	Break;
      end;
      Readln(F.T, SS);
      Inc(I);
      SS := Detab(SS, 8);
      TrailTrim(SS);
      if (SS = '') or (SS[1] <> ' ') then
      begin
	NewLine;
	if SS = '' then Continue;
	J := Pos(' ', SS);
	if J = 0 then C := SS
	else C := Copy(SS, 1, J - 1);
	if (C = '..') and (Length(ADir) > 3) then N := 0
	else if Unfold then FindFullName(AddedSlash(ADir) + C, N)
	else
	begin
	  N := 0;
	  FindByName(C, N);
	end;
	if N <> -1 then
	begin
	  if J = 0 then S := ''
	  else S := Trim(Copy(SS, J + 1, 255));
	  Num := I - 1;
	end;
      end
      else if N <> -1 then
      begin
	TrimSt(SS);
	if S = '' then S := SS
	else S := Concat(S, ' ', SS);
      end;
    end;
    SetDOSTextMode;
    Close(F.T);
    InOutRes := 0;
    if not Abort then NewLine;
  end;
end;

procedure FillMaskList;
var
  Name: FNameStr;
begin
  if LocalAssocs and (FManager^.Settings and seUnfold = 0) then
  begin
    Name := AddedSlash(APath) + MaskTemplateName;
    if not ThisFileExists(Name) then
      Name := ConfigPath + MaskTemplateName;
  end
  else Name := ConfigPath + MaskTemplateName;
  lAssignText(F, Name);
  FailSysErrors := True;
  Reset(F.T);
  FailSysErrors := False;
  if IOResult <> 0 then Exit;
  LogEvent := lcDiskRead;
  DrawStatusLine('Reading description templates from ' +
    TrimmedName(Name, 33) + '.');
  S := '';
  if not Eof(F.T) then
  begin
    SetUNIXTextMode;
    ReadLn(F.T, SS);
    if SS[Length(SS)] = #13 then SetDOSTextMode;
    TextSeek(F.T, 0);
  end;
  while not Eof(F.T) do
  begin
    if (KbdStatus = 1) and FMAbortAction then
    begin
      Abort := True;
      Break;
    end;
    Readln(F.T, SS);
    SS := Detab(SS, 8);
    TrailTrim(SS);
    if (SS = '') or (SS[1] <> ' ') then
    begin
      if S <> '' then
      begin
	SaveCount := MaskList^.Count;
{	MaskList^.Insert(NewStr(S));}
	MaskList^.Insert(NewStrUMB(S));
	S := '';
	if SaveCount = MaskList^.Count then
	begin
	  Abort := MessageBox(^C'List file |' + Name +
	    '|'#13^C'contains too many mask templates.'#13^C'Abort processing ?',
	    nil, mfConfirmation + mfYesNo) = cmYes;
	  Break;
	end;
      end;
      if SS = '' then Continue;
      if Pos(' ', SS) = 0 then S := ''
      else S := SS;
    end
    else if S <> '' then S := S + ' ' + Trim(SS);
  end;
  SetDOSTextMode;
  Close(F.T);
  InOutRes := 0;
{  if not Abort and (S <> '') then MaskList^.Insert(NewStr(S));}
  if not Abort and (S <> '') then MaskList^.Insert(NewStrUMB(S));
end;

procedure ScanMaskList;
var
  J, M, K: Integer;
begin
  LogEvent := 0;
  DrawStatusLine('Searching for appropriate description templates.');
  for M := 0 to MaskList^.Count - 1 do
  begin
    S := PString(MaskList^.At(M))^;
    J := Pos(' ', S);
    if WildCardMatch(C, Copy(S, 1, J - 1)) then
    begin
      with FManager^ do
	if FilesBBS^.Count = 0 then
	begin
	  for K := 0 to List^.Count - 1 do FilesBBS^.Insert(nil);
	  if FilesBBS^.Count < List^.Count then
	  begin
	    Abort := True;
	    Application^.OutOfMemory;
	    Exit;
	  end;
	end;
      S := Trim(Copy(S, J + 1, 255));
      Num := MaxInt;
      NewLine;
      Exit;
    end;
  end;
end;

procedure ReadMaskTemplates;
var
  II: Integer;
begin
  with FManager^ do
  begin
    MaskList := nil;
    for II := 0 to List^.Count - 1 do
    begin
      if (KbdStatus = 1) and FMAbortAction then
      begin
	Abort := True;
	Break;
      end;
      N := II;
      P := List^.At(N);
      if P^.Attr and Directory = 0 then
      begin
	if (FilesBBS^.Count = 0) or (FilesBBS^.At(N) = nil) then
	begin
	  if MaskList = nil then
	  begin
	    MaskList := New(PStringsCollection, Init(16, 16));
	    FillMaskList;
	    if Abort or (MaskList^.Count = 0) then Break;
	  end;
	  AddNameExt('', P, C);
	  ScanMaskList;
	  if Abort then Break;
	end;
      end;
    end;
    if MaskList <> nil then Dispose(MaskList, Done);
  end;
end;

procedure SetFindPath(const ADir: FNameStr);
begin
  FindPath := Concat(ADir, '\*.*');
end;

procedure SetCurPath(const ADir, AName: FNameStr);
begin
  CurPath := Concat(ADir, '\', AName);
end;

procedure UpdateStatusLine;
begin
  LogEvent := lcDiskRead;
  DrawStatusLine(
    'Searching for description file in ' + TrimmedName(CurPath, 32) + '.');
end;

procedure UnfoldDir(ADir: PString);
var
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
  FailSysErrors := True;
  lFindFirst(FindPath, $17, SR^);
  FailSysErrors := False;
  while (DosError = 0) and not Abort do
  begin
    if (SR^.SR.Name[1] <> '.') and (SR^.SR.Attr and Directory <> 0) then
    begin
      if SR^.FullName <> '' then SetCurPath(Dir^, SR^.FullName)
      else SetCurPath(Dir^, SR^.SR.Name);
      if UnfoldSel and (TagList^.Count <> 0) and
	not TagList^.NameFound(CurPath) then {}
      else
      begin
	UpdateStatusLine;
	ReadDescriptions(CurPath, True);
	UnfoldDir(@CurPath);
      end;
    end;
    lFindNext(SR^);
    if (KbdStatus = 1) and FMAbortAction then Abort := True;
  end;
  lFindClose(SR^);
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

begin
  Abort := False;
  FManager^.DirinfoWidth := 0;
  ReadDescriptions(APath, False);
  with FManager^ do
  begin
    if Settings and seUnfold <> 0 then UnfoldDir(@APath);
    if not Abort and (FMOptions and foNoMaskDescriptions = 0) then
      ReadMaskTemplates;
    if SortMode in [smDescr, smFilesBBS] then Files^.Sort;
  end;
end;

end.
