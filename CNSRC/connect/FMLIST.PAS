{$I-,F+,O+,X+}
unit FMList;

interface

uses Objects, FileMngr, DirPrim;

procedure ReadListPrim(FManager: PPanel; const Name: FNameStr;
  UnfoldSel: Boolean);
procedure ReadFileListPrim(FManager: PPanel; const Name: FNameStr);
procedure OutOfFileListPrim(FManager: PPanel);
procedure ReadListTreePrim(FManager: PPanel; const Name: FNameStr);
procedure GetListDrivesPrim(const Name: FNameStr; ADrive: Char;
  var Num: Byte; var Drives: TDrivesArray);

implementation

uses Dos, Drivers, Views, App, PanelRec, FMAbort, DirTree, Trees, Tags,
  HeapUMB, LFN, DosTools, Keyboard, TPString, Commands, Defaults;

const
  ListIllegalChars =
    [':', ';', ',', '=', '+', '<', '>',
     '*', '?', '|', '"', '[', ']', '\'];

procedure PreprocessLine(var S: String; var Size, Time: Longint);
var
  B: Byte;
  I, Code: Integer;
  DT: DateTime;
  SS: String;

procedure GetValue(var V: Word);
begin
  B := 1;
  while (B <= Length(SS)) and not (SS[B] in ['0'..'9']) do Inc(B);
  System.Delete(SS, 1, B - 1);
  B := 1;
  while (B <= Length(SS)) and (SS[B] in ['0'..'9']) do Inc(B);
  Val(System.Copy(SS, 1, B - 1), V, Code);
  System.Delete(SS, 1, B);
end;

procedure GetSizeAndTime;
begin
  B := 1;
  while (B <= Length(SS)) and not (SS[B] in ['0'..'9']) do Inc(B);
  System.Delete(SS, 1, B - 1);
  B := 1;
  while (B <= Length(SS)) and (SS[B] in ['0'..'9']) do Inc(B);
  Val(System.Copy(SS, 1, B - 1), Size, Code);
  System.Delete(SS, 1, B);

  GetValue(DT.Year);
  if DT.Year < 80 then Inc(DT.Year, 2000)
  else if DT.Year <= 99 then Inc(DT.Year, 1900);
  if (DT.Year < 1980) or (DT.Year > 2099) then Exit;
  GetValue(DT.Month);
  if (DT.Month < 1) or (DT.Month > 12) then Exit;
  GetValue(DT.Day);
  if (DT.Day < 1) or (DT.Day > 31) then Exit;
  GetValue(DT.Hour);
  if DT.Hour > 24 then Exit;
  GetValue(DT.Min);
  if DT.Min >= 60 then Exit;
  GetValue(DT.Sec);
  if DT.Sec >= 60 then Exit;

  PackTime(DT, Time);
end;

begin
  if S[Length(S)] in ['\', '/'] then SS := ''
  else if (S <> '') and (S[1] = '"') then
  begin
    I := 2;
    while (I <= Length(S)) and (S[I] <> '"') do Inc(I);
    SS := Copy(S, I + 1, 255);
    S := Copy(S, 2, I - 2);
  end
  else
  begin
    I := Pos(#9, S);
    if I = 0 then I := Pos(' ', S);
    if I <> 0 then
    begin
      SS := Copy(S, I + 1, 255);
      S[0] := Char(I - 1);
    end
    else SS := '';
  end;
  Size := 0;
  Time := $210000;
  if SS <> '' then GetSizeAndTime;
end;

procedure AddOutOfListItem(FManager: PPanel; const S: String;
  var SR: lSearchRec);
begin
  lFindFirst(S, AnyFile and not (Directory + VolumeID), SR);
  lFindClose(SR);
  if DosError <> 0 then
  begin
    SR.SR.Time := $210000;
    SR.SR.Size := 0;
  end;
  SR.SR.Name := '';
  SR.SR.Attr := VolumeID + Directory;
  FManager^.List^.Insert(NewPanelRec(SR, FManager));
end;

procedure ReadListPrim(FManager: PPanel; const Name: FNameStr;
  UnfoldSel: Boolean);
var
  Long, Found: Boolean;
  B, E: Byte;
  I: Integer;
  Size, Time: Longint;
  P: PPanelRec;
  SR: lSearchRec;
  F: lText;
  S, DS, SS, Path: FNameStr;
  Line: String;

procedure CheckIllegalChars;
begin
  B := 1;
  while B <= Length(SR.SR.Name) do
  begin
    if SR.SR.Name[B] in ListIllegalChars then SR.SR.Name := '';
    Inc(B);
  end;
end;

procedure NameFilter;
begin
  if not WildCardMatch(SR.SR.Name, FManager^.Filter) then SR.SR.Name := '';
end;

procedure ExecFilter;
var
  I: Integer;
begin
  I := Pos('.', SR.SR.Name);
  if I <> 0 then S := StUpcase(Copy(SR.SR.Name, I + 1, 3));
  if (I = 0) or
    not ((S = 'BAT') or (S = 'COM') or (S = 'EXE')) then SR.SR.Name := '';
end;

procedure PrepareSearchRec;
begin
  SR.SR.Name := '';
  if UCPos(SS, S) = 0 then Exit;
  SR.SR.Time := Time;
  SR.SR.Size := Size;
  SR.SR.Attr := Archive;
{ Added 2006.01.03 }
  SR.HiAttr := 0;
  B := Length(SS) + 1;
  if FManager^.Settings and seUnfold <> 0 then
  begin
    if UnfoldSel and (TagList^.Count <> 0) then
    begin
      E := B;
      while (E <= Length(S)) and (S[E] <> '\') do Inc(E);
      if E > Length(S) then Exit;
      Path := System.Copy(S, 1, E - 1);
      if not TagList^.NameFound(Path) then Exit;
    end;

    E := Length(S);
    while (E > B) and (S[E] <> '\') do Dec(E);
    if S[E] = '\' then Inc(E);
    SetSearchRecName(System.Copy(S, E, 255), SR.SR, Long);
    if Long then Path := #0 + System.Copy(S, B, 255)
    else Path := System.Copy(S, B, E - B - Byte(E <> B));
  end
  else
  begin
    E := B;
    while (E <= Length(S)) and (S[E] <> '\') do Inc(E);
    if E <= Length(S) then SR.SR.Attr := SR.SR.Attr or Directory;
    SetSearchRecName(System.Copy(S, B, E - B), SR.SR, Long);
    if Long then Path := #0 + System.Copy(S, B, E - B)
    else Path := '';
  end;
  CheckIllegalChars;
  if SR.SR.Name = '' then Exit;
  if SR.SR.Attr and Directory <> 0 then
    if FManager^.UseFilter and
       FManager^.AdvancedFilter.UseForLists and
      (FManager^.AdvancedFilter.Attr <> AnyFile) and
      (FManager^.AdvancedFilter.Attr and Directory = 0) then
        SR.SR.Name := '' else
  else if FManager^.State and sfExOnly <> 0 then ExecFilter
  else if FManager^.Filter <> '*.*' then NameFilter;
end;

procedure ProcessLine;
begin
  PreprocessLine(Line, Size, Time);
  if Line = '' then Exit;
  S := Line;
  InvertSlashes(S);
  if (Length(S) > 1) and (S[2] = ':') then { S[1] := SS[1] }
  else if S[1] = '\' then S := SS[1] + ':' + S
  else S := DS + S;
  if S[Length(S)] = '\' then DS := S;
  FManager^.CRCList^.InsertName(S);
  PrepareSearchRec;
  if SR.SR.Name = '' then Exit;
  P := NewPanelRec(SR, FManager);
{  if Path <> '' then P^.ThePath := NewStr(Path);}
  if Path <> '' then P^.ThePath := NewStrUMB(Path);
  FManager^.List^.Insert(P);
end;

procedure UpdateSearchRecs;
begin
  I := FManager^.List^.Count - 1;
  while I >= 0 do
  begin
    P := FManager^.List^.At(I);
    S := SS;
    if PanelRecHasPath(P) then S := AddedSlash(S + PanelRecPath(P));
    AddNameExt(S, P, S);
    lFindFirst(S, AnyFile and not VolumeID, SR);
    lFindClose(SR);
    Found := (DosError = 0) and
      ((SR.SR.Attr and Directory) = (P^.Attr and Directory));
    if Found then
    begin
      P^.Time := SR.SR.Time;
      P^.Size := SR.SR.Size;
      P^.Attr := SR.SR.Attr;
{ Added 2006.01.03 }
      P^.HiAttr := SR.HiAttr;
    end;
    if FManager^.UseFilter and FManager^.AdvancedFilter.UseForLists and
      (P^.Attr and Directory = 0) then
    begin
      if not Found then
      begin
	SR.SR.Name := P^.Name;
	SR.FullName := '';
	if P^.Ext <> '' then SR.SR.Name := SR.SR.Name + '.' + P^.Ext;
	SR.SR.Time := P^.Time;
	SR.SR.Size := P^.Size;
	SR.SR.Attr := P^.Attr;
{ Added 2006.01.03 }
	SR.HiAttr := P^.HiAttr;
      end;
      if not AdvancedFilterPassed(@FManager^.AdvancedFilter,
	FManager^.UnixStates, SR.SR, SR.FullName) then
	  FManager^.List^.AtFree(I);
    end;
    Dec(I);
  end;
end;

begin
  with FManager^ do
    if CRCList = nil then InitCRCList else CRCList^.FreeAll;
  LogEvent := lcDiskRead;
  DrawStatusLine('Reading the file list ' + TrimmedName(Name, 45) + '.');
  lAssignText(F, Name);
  Reset(F.T);
  if IOResult <> 0 then Exit;
  if IsDevice(TextRec(F.T).Handle) then
  begin
    Close(F.T);
    InOutRes := 0;
    Exit;
  end;
  DS := FManager^.SaveListDir^ + '\';
  SS := FManager^.ListDir^ + '\';
  FailSysErrors := True;
  DriveValid(SS[1], FManager^.BytesFree);
  while not Eof(F.T) do
  begin
    Readln(F.T, Line);
    ProcessLine;
    if (KbdStatus = 1) and FMAbortAction then Break;
  end;
  Close(F.T);
  InOutRes := 0;
  UpdateSearchRecs;
  AddOutOfListItem(FManager, Name, SR);
  FailSysErrors := False;
end;

procedure ReadFileListPrim(FManager: PPanel; const Name: FNameStr);
var
  SR: PPanelRec;
  S: FNameStr;
begin
  with FManager^ do
  begin
    if (Status = stTree) or InArchive then Exit;
    if Name = '' then
    begin
      SR := List^.At(Focused);
      if SR^.Attr and Directory <> 0 then Exit;
      GetRecStr(SR, S);
    end
    else S := Name;
{
    DisposeStr(FileListName);
    FileListName := NewStr(lFExpand(S));
    if SaveListDir = nil then SaveListDir := NewStr(ListDir^);
}
    DisposeStrUMB(FileListName);
    FileListName := NewStrUMB(lFExpand(S));
    if SaveListDir = nil then SaveListDir := NewStrUMB(ListDir^);
    Settings := Settings or seList;
    SwitchToDir(ListDir^, True);
  end;
end;

procedure OutOfFileListPrim(FManager: PPanel);
var
  ShiftDown: Boolean;
  I: Integer;
  S, SS: FNameStr;
begin
  with FManager^ do
  begin
    if InArchive or (Status > stTree) or
       (Settings and seList = 0) then Exit;
    Settings := Settings and not seList;
    ShiftDown := GetShiftState and (kbLeftShift + kbRightShift) <> 0;
    if ShiftDown then
    begin
      GetItemStr(Focused, S);
      if (Focused = 0) and (Length(S) > 3) then S := AddedSlash(S);
    end
    else S := FileListName^;
{    DisposeStr(FileListName);}
    DisposeStrUMB(FileListName);
    FileListName := nil;
    if ShiftDown then SS := ClearedSlash(JustPathName(S))
    else SS := SaveListDir^;
{    DisposeStr(SaveListDir);}
    DisposeStrUMB(SaveListDir);
    SaveListDir := nil;
    DoneCRCList;
    IgnoreListSpaces := False;
    if Status = stTree then Status := stBrief;
    NewDir(SS, True);
    if ClearedSlash(JustPathName(S)) = ListDir^ then
      GetItemNum(S, I) else I := 0;
    FocusItem(I);
  end;
end;

procedure ReadListTreePrim(FManager: PPanel; const Name: FNameStr);
const
  IllegalChars =
    [':', '.', ';', ',', '=', '+', '<', '>', '*', '?', '|', '"', '[', ']'];
var
  OutOfMem: Boolean;
  B: Byte;
  Drive: Char;
  Size, Time: Longint;
  SR: SearchRec;
  F: lText;
  S, DS: String;
begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Building the Tree for the currently viewed file list.');
  with FManager^ do
  begin
    Drive := ListDir^[1];
    DS := ListDir^ + '\';
    SR.Name := Drive + ':\';
    SR.Attr := Directory;
    SR.Time := 0;
    SR.Size := 0;
    TheTree^.FreeAll;
    TheTree^.Insert(NewTreeRec(SR));
    TheTree^.BaseName := '';
    TheTree^.ForceLong := True;
  end;
  lAssignText(F, Name);
  Reset(F.T);
  if IOResult <> 0 then Exit;
  if not IsDevice(TextRec(F.T).Handle) then while not Eof(F.T) do
  begin
    Readln(F.T, S);
    PreprocessLine(S, Size, Time);
    if (S = '') or (S[1] in ListIllegalChars) then Continue;
    InvertSlashes(S);
    if S[1] = '\' then S := Drive + ':' + S;
    if S[Length(S)] = '\' then
    begin
      DS := S;
      S := S + '1';
    end;
    if (Length(S) <= 1) or (S[2] <> ':') then S := DS + S
    else if S[1] <> Drive then Continue;
    if Length(S) > 3 then
    begin
      AddDirToTreePrim(JustPathName(CRCShortName(S)), JustPathName(S),
        FManager^.TheTree, OutOfMem);
      if OutOfMem or ((KbdStatus = 1) and FMAbortAction) then Break;
    end;
  end;
  Close(F.T);
  InOutRes := 0;
end;

procedure GetListDrivesPrim(const Name: FNameStr; ADrive: Char;
  var Num: Byte; var Drives: TDrivesArray);
var
  Size, Time: Longint;
  F: lText;
  S: String;
begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Reading drive names from ' + TrimmedName(Name, 42) + '.');
  FillChar(Drives, SizeOf(TDrivesArray), 0);
  Drives[ADrive] := 1;
  Num := 1;
  lAssignText(F, Name);
  Reset(F.T);
  if IOResult <> 0 then Exit;
  if not IsDevice(TextRec(F.T).Handle) then while not Eof(F.T) do
  begin
    Readln(F.T, S);
    PreprocessLine(S, Size, Time);
    if (Length(S) > 1) and (S[2] = ':') then
    begin
      S[1] := Upcase(S[1]);
      if S[1] in ['A'..'Z'] then
      begin
        if Drives[S[1]] = 0 then Inc(Num);
        Drives[S[1]] := 1;
      end;
    end;
    if (KbdStatus = 1) and FMAbortAction then Break;
  end;
  Close(F.T);
  InOutRes := 0;
end;

end.