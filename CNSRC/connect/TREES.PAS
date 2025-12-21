{$I-,F+,O+,X+}
unit Trees;

interface

uses Objects, DirTree;

procedure LoadTree(const ADir: FNameStr; var T: PTreeCollection);
function AddDirToTreePrim(const ADir, ALongName: FNameStr;
  T: PTreeCollection; var OutOfMem: Boolean): Boolean;
procedure AddDirToTree(const ADir, ALongName: FNameStr);
procedure DelDirFromTree(const ADir: FNameStr);
procedure RenameDirInTree(const FromDir, ToDir: FNameStr);

implementation

uses Dos, Memory, App, DirPrim, Disks, DosTools, HeapUMB, LFN,
  TPString, Defaults;

procedure LoadTree(const ADir: FNameStr; var T: PTreeCollection);
var
  Stream: TDosStream;
  Name: FNameStr;

function ValidStream: Boolean;
var
  Signature: Array[1..Length(TreeSignature)] of Char;
begin
  Stream.Read(Signature, Length(TreeSignature));
  ValidStream := (Stream.Status = stOk) and (Signature = TreeSignature);
end;

begin
  T := nil;
  if FMOptions and foNoAutoUpdateTree <> 0 then Exit;
  if (FMOptions and foAltTreeinfo = 0) and
     (ADir[1] <> '\') and IsRemovable(ADir[1]) then Exit;
  SetTreeInfoName(ADir, Name);
  Stream.Init(Name, stOpenRead);
  if ValidStream then
  begin
    DrawReadingTreeStatus(Name);
    T := PTreeCollection(Stream.Get);
    if T <> nil then
    begin
      if T^.At(T^.Count - 1) = nil then
      begin
	Dispose(T, Done);
	T := nil;
      end
      else
      begin
	if ADir[1] = '\' then
	begin
	  T^.BaseName := ADir;
	  PTreeRec(T^.At(0))^.Name := '';
	end
	else
	begin
	  PTreeRec(T^.At(0))^.Name := ADir[1] + ':\';
	  T^.BaseName := '';
	end;
      end;
    end;
  end;
  Stream.Done;
end;

function AddDirToTreePrim(const ADir, ALongName: FNameStr;
  T: PTreeCollection; var OutOfMem: Boolean): Boolean;
var
  Ins, Long, ScanLong: Boolean;
  Level, Info: Byte;
  B, LB, E, LE, I, II: Integer;
  Image: Longint;
  R: PTreeRec;
  SR, FR: SearchRec;
  S, LS: FNameStr;
label
  DoIns;
begin
  OutOfMem := False;
  ScanLong := (ALongName <> '') and
    (CompString(ADir, ALongName) <> Equal);
  Ins := False;
  Level := $FF;
  if T^.BaseName = '' then B := 4
  else B := Length(T^.BaseName) + 2;
  E := B;
  LB := B;
  LE := LB;
  I := 0;
  repeat
    Inc(Level);
    while (E <= Length(ADir)) and (ADir[E] <> '\') do Inc(E);
    SetSearchRecName(Copy(ADir, B, E - B), FR, Long);
    S := FR.Name;
    while (E <= Length(ADir)) and (ADir[E] = '\') do Inc(E);
    B := E;
    if ScanLong then
    begin
      while (LE <= Length(ALongName)) and (ALongName[LE] <> '\') do Inc(LE);
      LS := Copy(ALongName, LB, LE - LB);
      while (LE <= Length(ALongName)) and (ALongName[LE] = '\') do Inc(LE);
      LB := LE;
    end
    else LS := '';
DoIns:
    Inc(I);
    II := I;
    if Ins then
    begin
      Info := Level;
      R := T^.At(I);
      if (R <> nil) and (R^.Info and $7F = Level) then Image := R^.Time
      else
      begin
	Info := Info or $80;
	if I = 1 then Image := 1
	else
	begin
	  R := T^.At(I - 1);
	  Image := R^.Time shl 1;
	  if R^.Info and $80 = 0 then Image := Image or 1;
	end;
      end;
      if S = '' then Continue;
      SR.Name := S;
      SR.Attr := Directory;
      SR.Size := 0;
      R := NewTreeRec(SR);
      R^.ThePath := nil;
      R^.Time := Image;
      R^.Info := Info;
      if (T^.Count < T^.Limit) or
	 (MaxAvail > LongMul(T^.Limit + T^.Delta, 4) + $2000) then
      begin
	if LS <> '' then
{        R^.ThePath := NewStr(#0 + LS);}
	  R^.ThePath := NewStrUMB(#0 + LS);
	T^.AtInsert(I, R);
	if R^.Info and $7F > T^.BranchLevel then
	begin
	  T^.BranchLevel := R^.Info and $7F;
	  if T^.BranchLevel > T^.MaxBranchLevel then
	    T^.MaxBranchLevel := T^.BranchLevel;
	end;
      end
      else
      begin
	T^.FreeItem(R);
	Application^.OutOfMemory;
	OutOfMem := True;
	AddDirToTreePrim := False;
	Exit;
      end;
    end
    else
    repeat
      R := T^.At(I);
      if (R = nil) or (R^.Info and $7F < Level) then
      begin
	I := II - 1;
	Ins := True;
	Goto DoIns;
      end;
      SR.Name := R^.Name;
      if R^.Ext <> '' then SR.Name := SR.Name + '.' + R^.Ext;
      if (R^.Info and $7F = Level) and (SR.Name = S) then Break;
      Inc(I);
    until False;
  until E > Length(ADir);
  AddDirToTreePrim := Ins;
end;

procedure AddDirToTree(const ADir, ALongName: FNameStr);
var
  OutOfMem: Boolean;
  T: PTreeCollection;
begin
  LoadTree(RootName(ADir), T);
  if T = nil then Exit;
  if AddDirToTreePrim(ADir, ALongName, T, OutOfMem) then
    StoreTree(RootName(ADir), T);
  Dispose(T, Done);
end;

procedure DelDirFromTree(const ADir: FNameStr);
var
  Info: Byte;
  I: Integer;
  L: Longint;
  T: PTreeCollection;
  R: PTreeRec;
begin
  LoadTree(RootName(ADir), T);
  if T = nil then Exit;
  I := T^.GetDirNum(ADir, 0, MaxInt);
  if I < T^.Count then
  begin
    R := T^.At(I);
    Info := R^.Info;
    repeat
      T^.AtFree(I);
      R := T^.At(I);
      if (R = nil) or ((R^.Info and $7F) <= (Info and $7F)) then Break;
    until False;
    if Info and $80 <> 0 then
    repeat
      Dec(I);
      if I = 0 then Break;
      R := T^.At(I);
      if (R^.Info and $7F) < (Info and $7F) then Break;
      if (R^.Info and $7F) = (Info and $7F) then
      begin
	R^.Info := R^.Info or $80;
	Break;
      end;
      if (R^.Info and $7F) > (Info and $7F) then
      begin
	L := 1;
	L := L shl ((R^.Info and $7F) - (Info and $7F) - 1);
	R^.Time := R^.Time and not L;
      end;
    until False;
    T^.CalcBranchLevels;
    StoreTree(RootName(ADir), T);
  end;
  Dispose(T, Done);
end;

procedure RenameDirInTree(const FromDir, ToDir: FNameStr);
var
  I: Integer;
  T: PTreeCollection;
  R: PTreeRec;
  S: String;
begin
  LoadTree(RootName(FromDir), T);
  if T = nil then Exit;
  I := T^.GetDirNum(FromDir, 0, MaxInt);
  if I < T^.Count then
  begin
    lGetShortFileName(ToDir, S);
    R := T^.At(I);
{    DisposeStr(R^.ThePath);}
    DisposeStrUMB(R^.ThePath);
    R^.ThePath := nil;
    R^.Name := JustName(S);
    R^.Ext := JustExtension(S);
    if CompString(ToDir, S) <> Equal then
{      R^.ThePath := NewStr(#0 + JustFileName(ToDir));}
      R^.ThePath := NewStrUMB(#0 + JustFileName(ToDir));
    StoreTree(RootName(FromDir), T);
  end;
  Dispose(T, Done);
end;

end.