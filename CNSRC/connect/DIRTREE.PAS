{$I-,X+,O+,F+}
unit DirTree;

interface

uses Dos, Objects;

type
  PTreeRec = ^TTreeRec;
  TTreeRec = record
    Attr: Byte;
    Time: Longint;
    Size: Longint;
    Name: String[8];
    Ext: String[3];
    Selected: Boolean;
    Info: Byte;
    ThePath: PString;
    Color: Byte;
  end;

  PTreeCollection = ^TTreeCollection;
  TTreeCollection = object(TCollection)
    BaseName: FNameStr;
    MaxBranchLevel: Byte;
    BranchLevel: Byte;
    ForceLong: Boolean;
    constructor Load(var S: TStream);
    procedure FreeItem(Item: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
    procedure Store(var S: TStream);
    function GetItemStr(Item: Integer; const CurDir: FNameStr;
      WithPipes: Boolean): String;
    function GetBaseName: FNameStr;
    function GetDirStr(Item: Integer): FNameStr;
    function GetRecStr(P: Pointer): FNameStr;
    function GetDirNum(const ADir: FNameStr;
      StartIndex, Index: Integer): Integer;
    procedure CalcBranchLevels;
    procedure ClearExtraBranches;
  end;

const
  TreeInfoName = 'TREEINFO.CN';
  TreeSignature = 'CONNECT Tree Info File'#26#0;

procedure TreeAddNameExt(const Path: FNameStr; P: PTreeRec;
  var S: FNameStr; ForceLong: Boolean);
procedure SetTreeInfoName(const ADir: FNameStr; var Name: FNameStr);
procedure DrawReadingTreeStatus(const Name: FNameStr);
function NewTreeRec(SR: SearchRec): PTreeRec;
procedure NewTree(const ADir: FNameStr; var T: PTreeCollection);
procedure EraseTreeInfo(const ADir: FNameStr);
procedure StoreTree(const ADir: FNameStr; var T: PTreeCollection);
function SetTreeBranchLevel(const ADir: FNameStr; Level: Byte): Boolean;

implementation

uses Drivers, Memory, App, MsgBox, EditMsg, DirPrim, PanelRec, Gauges,
  Spooler, Disks, FMAbort, HeapUMB, Keyboard, DosTools, Timer, LFN,
  TPString, Defaults;

procedure SetTreeInfoName(const ADir: FNameStr; var Name: FNameStr);
begin
  if (FMOptions and foAltTreeinfo <> 0) and (ADir[1] <> '\') then
    Name := ConfigPath + TreeInfoName + ADir[1]
  else Name := AddedSlash(ADir) + TreeInfoName;
end;

procedure DrawReadingTreeStatus(const Name: FNameStr);
begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Reading the Tree Info file ' +
    TrimmedName(Name, 40) + '.');
end;

function UnpackImage(L: Longint; B: Byte): String;
var
  S: String;
  i, j: Byte;
begin
  j := (B and $7f) * 3;
  S[0] := Char(j);
  if j > 0 then
  begin
    FillChar(S[1], j, ' ');
    j := j - 2;
    for i := 0 to B and $7f - 1 do
    begin
      if L and 1 <> 0 then S[j] := '³';
      L := L shr 1;
      j := j - 3;
    end;
  end;
  if B and $80 <> 0 then UnpackImage := Concat(' ', S, 'ÀÄÄ')
  else UnpackImage := Concat(' ', S, 'ÃÄÄ');
end;

procedure SetTreeRecColor(P: PTreeRec);
var
  I: Byte;
begin
  P^.Color := Byte(Application^.GetPalette^[141]);
  if TempGroups <> nil then
    GetGroupInfo(P^.Name, P^.Ext, True, P^.Color, I);
end;

function NewTreeRec(SR: SearchRec): PTreeRec;
var
  I: Integer;
  P: PTreeRec;
begin
{  GetMem(P, SizeOf(TTreeRec));}
  GetMemUMB(P, SizeOf(TTreeRec));
  P^.Attr := SR.Attr;
  P^.Time := 0;
  P^.Size := SR.Size;
  P^.Selected := False;
  P^.Info := 0;
  I := Pos('.', SR.Name);
  if (I <> 0) and (SR.Name[1] <> '.') then
  begin
    P^.Name := System.Copy(SR.Name, 1, I - 1);
    P^.Ext  := System.Copy(SR.Name, I + 1, 3);
  end
  else
  begin
    P^.Name := SR.Name;
    P^.Ext  := '';
  end;
  P^.ThePath := nil;
  SetTreeRecColor(P);
  NewTreeRec := P;
end;

procedure TreeAddNameExt(const Path: FNameStr; P: PTreeRec;
  var S: FNameStr; ForceLong: Boolean);
var
  SavePath: PString;
begin
  SavePath := P^.ThePath;
  if not ForceLong and (lAPI = lDOS) then P^.ThePath := nil;
  AddNameExt(Path, PPanelRec(P), S);
  P^.ThePath := SavePath;
end;

constructor TTreeCollection.Load(var S: TStream);
begin
  TCollection.Load(S);
  S.Read(MaxBranchLevel, SizeOf(Byte) * 2);
end;

procedure TTreeCollection.FreeItem(Item: Pointer);
begin
{
  if Item <> nil then
  begin
    DisposeStr(PTreeRec(Item)^.ThePath);
    FreeMem(Item, SizeOf(TTreeRec));
  end;
}
  if Item <> nil then
  begin
    DisposeStrUMB(PTreeRec(Item)^.ThePath);
    FreeMemUMB(Item, SizeOf(TTreeRec));
  end;
end;

function TTreeCollection.GetItem(var S: TStream): Pointer;
var
  Item: PTreeRec;
begin
{  GetMem(Item, SizeOf(TTreeRec));}
  GetMemUMB(Item, SizeOf(TTreeRec));
  S.Read(Item^, SizeOf(TTreeRec) - SizeOf(PString) - SizeOf(Byte));
{  Item^.ThePath := S.ReadStr;}
  Item^.ThePath := ReadStrUMB(@S);
  if LowMemory then
  begin
    FreeItem(Item);
    Item := nil;
  end
  else SetTreeRecColor(Item);
  GetItem := Item;
end;

procedure TTreeCollection.PutItem(var S: TStream; Item: Pointer);
begin
  S.Write(Item^, SizeOf(TTreeRec) - SizeOf(PString) - SizeOf(Byte));
  S.WriteStr(PTreeRec(Item)^.ThePath);
end;

procedure TTreeCollection.Store(var S: TStream);
begin
  TCollection.Store(S);
  S.Write(MaxBranchLevel, SizeOf(Byte) * 2);
end;

function TTreeCollection.GetItemStr(Item: Integer;
  const CurDir: FNameStr; WithPipes: Boolean): String;
var
  I: Integer;
  SR: PTreeRec;
  PS: String[1];
  S, Name: String;
begin
  if (Item < 0) or (Item >= Count) then GetItemStr := ''
  else
  begin
    if WithPipes then PS := '|' else PS := '';
    if Item = 0 then S := ' ' + PS + GetBaseName + PS
    else
    begin
      SR := At(Item);
      TreeAddNameExt('', SR, Name, ForceLong);
      S := UnpackImage(SR^.Time, SR^.Info) + PS + Name + PS;
      if SR^.Attr and Hidden <> 0 then S := S + ' °';
    end;
    if BaseName = '' then
      if (((Item = 0) and (Length(CurDir) = 2)) or
	  ((Item <> 0) and
	   (CompUCString(Name, JustFileName(CurDir)) = Equal))) and
	 (CompUCString(GetDirStr(Item), CurDir) = Equal) then S[1] := '';
    GetItemStr := S + ' ';
  end;
end;

function TTreeCollection.GetBaseName: FNameStr;
begin
  if BaseName <> '' then GetBaseName := BaseName
  else if Count = 0 then GetBaseName := ''
  else GetBaseName := PTreeRec(At(0))^.Name;
end;

function TTreeCollection.GetDirStr(Item: Integer): FNameStr;
var
  Level: Byte;
  P: PTreeRec;
  S, C: FNameStr;
begin
  if (Item < 0) or (Item >= Count) then GetDirStr := ''
  else if Item = 0 then GetDirStr := ClearedSlash(GetBaseName)
  else
  begin
    S := '';
    Level := $FF;
    repeat
      P := At(Item);
      if P^.Info and $7F < Level then
      begin
	TreeAddNameExt('', P, C, ForceLong);
	S := Concat(C, '\', S);
	Level := P^.Info and $7F;
      end;
      Dec(Item);
    until (Item = 0) or (Level = 0);
    if S <> '' then Dec(S[0]);
    GetDirStr := AddedSlash(GetBaseName) + S;
  end;
end;

function TTreeCollection.GetRecStr(P: Pointer): FNameStr;
var
  I: Integer;
begin
  I := IndexOf(P);
  GetRecStr := GetDirStr(I);
end;

function TTreeCollection.GetDirNum(const ADir: FNameStr;
  StartIndex, Index: Integer): Integer;
var
  Level, B: Byte;
  I: Integer;
  P: PTreeRec;
  S: FNameStr;
begin
  I := StartIndex;
  if I = 0 then
  begin
    if ADir = GetDirStr(0) then
    begin
      GetDirNum := 0;
      Exit;
    end;
    Inc(I);
  end;
  Level := 0;
  for B := Length(BaseName) + 1 to Length(ADir) do
    if ADir[B] = '\' then Inc(Level);
  Dec(Level);
  while I < Count do
  begin
    P := At(I);
    B := P^.Info and $7F;
    if B = Level then
    begin
      TreeAddNameExt('', P, S, ForceLong);
      if (UCPos('\' + S + '\', AddedSlash(ADir)) <> 0) and
	 (CompUCString(ADir, GetDirStr(I)) = Equal) then
      begin
	GetDirNum := I;
	Exit;
      end;
    end;
    Inc(I);
  end;
  GetDirNum := Index;
end;

procedure TTreeCollection.CalcBranchLevels;
var
  B: Byte;
  I: Integer;
begin
  MaxBranchLevel := 0;
  I := 0;
  repeat
    if I = Count then Break;
    B := PTreeRec(At(I))^.Info and $7F;
    if B > MaxBranchLevel then MaxBranchLevel := B;
    Inc(I);
  until False;
  if BranchLevel > MaxBranchLevel then BranchLevel := MaxBranchLevel;
end;

procedure TTreeCollection.ClearExtraBranches;
var
  I: Integer;
  P: PTreeRec;
begin
  if MaxBranchLevel = BranchLevel then Exit;
  I := 0;
  repeat
    P := At(I);
    if P = nil then Exit;
    if P^.Info and $7F > BranchLevel then AtFree(I)
    else Inc(I);
  until False;
end;

procedure NewTree(const ADir: FNameStr; var T: PTreeCollection);
var
  IsLast, B, Cancel, OutOfMem, Abort: Boolean;
  Ch: Char;
  TotalBytes: Longint;
  P: PTreeRec;
  Stream: TDosStream;
  F: File;
  NR: SearchRec;
  Name: FNameStr;
  S: String;

procedure DrawStatus;
var
  L: Longint;
begin
  GiveTicks;
  L := T^.Count;
  if ADir[1] = '\' then FormatStr(S,
    'Scanning the directory structure on network resource: %d', L)
  else FormatStr(S,
    'Scanning the directory structure on drive ' + ADir[1] + ': %d', L);
  LogEvent := lcDiskRead;
  DrawStatusLine(S);
end;

procedure AddNameAndSlash(const ADir, AName: FNameStr; DoAddSlash: Boolean;
  var S: FNameStr);
begin
  S := Concat(ADir, AName);
  if DoAddSlash then S := Concat(S, '\');
end;

function GetLastDirNum(const ADir: FNameStr): Word;
var
  W: Word;
  I: Integer;
  L: Longint;
  SR: lSearchRec;
begin
  W := 0;
  FailSysErrors := True;
  lFindFirst(ADir, $17, SR);
  FailSysErrors := False;
  while DosError = 0 do
  begin
    if SR.SR.Attr and Directory = 0 then Inc(TotalBytes, SR.SR.Size)
    else if SR.SR.Name[1] <> '.' then Inc(W);
    lFindNext(SR);
  end;
  lFindClose(SR);
  GetLastDirNum := W;
end;

procedure SetLongName(const Name: String);
begin
{  P^.ThePath := NewStr(#0 + Name);}
  P^.ThePath := NewStrUMB(#0 + Name);
end;

procedure SearchDir(ADir: PString; ALong: Longint; AByte: Byte);
var
  LastNum, CurNum: Word;
  SaveCount: Integer;
  CurLong, SaveBytes: Longint;
  SR: ^lSearchRec;
  Dir: PString;
label
  Quit;
begin
  if AByte > 32 then Exit;
  if StackOverflow then
  begin
    Abort := True;
    Exit;
  end;
  Dir := NewStr(ADir^);
  GetMem(SR, SizeOf(lSearchRec));
  DrawStatus;
  if Clock <> nil then Clock^.Update;
  if TheSpooler <> nil then TheSpooler^.ProcessItems;
  UpdateRoller;
  AddNameAndSlash(Dir^, '*.*', False, S);
  LastNum := GetLastDirNum(S);
  if LastNum = 0 then Goto Quit;
  FailSysErrors := True;
  lFindFirst(S, $17, SR^);
  FailSysErrors := False;
  CurNum := 0;
  while (DosError = 0) and not OutOfMem and not Abort do
  begin
    if (SR^.SR.Attr and Directory <> 0) and (SR^.SR.Name[1] <> '.') then
    begin
      P := NewTreeRec(SR^.SR);
      if LowMemory or
	((T^.Count = T^.Limit) and
	 (MaxAvail <= LongMul(T^.Limit + T^.Delta, 4) + $2000)) then
      begin
{	FreeMem(P, SizeOf(TTreeRec));}
	FreeMemUMB(P, SizeOf(TTreeRec));
	OutOfMem := True;
      end
      else
      begin
	P^.Info := AByte;
	P^.Time := ALong;
	Inc(CurNum);
	CurLong := ALong shl 1;
	IsLast := CurNum = LastNum;
	if IsLast then P^.Info := P^.Info or $80
	else CurLong := CurLong or 1;
	if SR^.FullName <> '' then SetLongName(SR^.FullName);
	T^.Insert(P);
	if P^.Info and $7F > T^.MaxBranchLevel then
	  T^.MaxBranchLevel := P^.Info and $7F;
	if SR^.FullName <> '' then
	  AddNameAndSlash(Dir^, SR^.FullName, True, S)
	else AddNameAndSlash(Dir^, SR^.SR.Name, True, S);
	SaveCount := T^.Count - 1;
	SaveBytes := TotalBytes;
	SearchDir(@S, CurLong, AByte + 1);
	PTreeRec(T^.At(SaveCount))^.Size := TotalBytes - SaveBytes;
      end;
    end;
    lFindNext(SR^);
    if (KbdStatus = 1) and FMAbortAction then Abort := True;
  end;
  lFindClose(SR^);
Quit:
  FreeMem(SR, SizeOf(lSearchRec));
  DisposeStr(Dir);
end;

procedure OutOfMemMsg;
begin
  MessageBox(^C'Too many directories.', nil, mfError + mfOkButton);
end;

function ValidStream: Boolean;
var
  Signature: Array[1..Length(TreeSignature)] of Char;
begin
  Stream.Read(Signature, Length(TreeSignature));
  ValidStream := (Stream.Status = stOk) and (Signature = TreeSignature);
end;

begin
  B := False;
  T^.FreeAll;
  SetTreeInfoName(ADir, Name);
  CancelSysErrors := False;
  Stream.Init(Name, stOpenRead);
  Cancel := CancelSysErrors;
  if ValidStream then
  begin
    DrawReadingTreeStatus(Name);
    Dispose(T, Done);
    T := PTreeCollection(Stream.Get);
    if T = nil then T := New(PTreeCollection, Init(64, 64))
    else if ((T^.Count <> 0) and (T^.At(T^.Count - 1) = nil)) or
      LowMemory then
    begin
      T^.Pack;
      OutOfMemMsg;
      B := True;
    end
    else if Stream.Status <> stOk then
    begin
      CouldNotReadMsgBox(Name);
      Dispose(T, Done);
      T := New(PTreeCollection, Init(64, 64));
    end
    else
    begin
      T^.AtFree(0);
      T^.ClearExtraBranches;
      B := True;
    end;
  end;
  Stream.Done;
  if ADir[1] = '\' then
  begin
    NR.Name := '';
    T^.BaseName := ADir;
  end
  else
  begin
    NR.Name := ADir[1] + ':\';
    T^.BaseName := '';
  end;
  NR.Attr := Directory;
  NR.Time := 0;
  NR.Size := 0;
  T^.AtInsert(0, NewTreeRec(NR));
  if B or Cancel then Exit;
  Abort := False;
  OutOfMem := False;
  TotalBytes := 0;
  S := AddedSlash(ADir);
  InitRoller;
  SearchDir(@S, 0, 0);
  DoneRoller;
  T^.BranchLevel := T^.MaxBranchLevel;
  PTreeRec(T^.At(0))^.Size := TotalBytes;
  if Abort then Exit;
  if OutOfMem then OutOfMemMsg
  else if (FMOptions and foAltTreeinfo <> 0) or
    (ADir[1] = '\') or not IsRemovable(ADir[1]) then
      StoreTree(ADir, T);
end;

procedure EraseTreeInfo(const ADir: FNameStr);
var
  Name: FNameStr;
  F: File;
begin
  SetTreeInfoName(ADir, Name);
  Assign(F, Name);
  Erase(F);
  InOutRes := 0;
end;

procedure StoreTree(const ADir: FNameStr; var T: PTreeCollection);
var
  Stream: TDosStream;
  Name: FNameStr;
  F: File;
begin
  EraseTreeInfo(ADir);
  SetTreeInfoName(ADir, Name);
  Stream.Init(Name, stCreate);
  if Stream.Status = stOk then
  begin
    LogEvent := lcDiskWrite;
    DrawStatusLine('Updating the Tree Info file ' +
      TrimmedName(Name, 39) + '.');
    Stream.Write(TByteArray(GetStrAddr(TreeSignature)^)[1],
      Length(TreeSignature));
    Stream.Put(T);
  end;
  Stream.Done;
  Assign(F, Name);
  SetFAttr(F, Hidden);
end;

function SetTreeBranchLevel(const ADir: FNameStr; Level: Byte): Boolean;
var
  Stream: TDosStream;
  Name: FNameStr;
begin
  SetTreeInfoName(ADir, Name);
  Stream.Init(Name, stOpenWrite);
  if Stream.Status = stOk then
  begin
    Stream.Seek(Stream.GetSize - SizeOf(Byte));
    Stream.Write(Level, SizeOf(Byte));
  end;
  SetTreeBranchLevel := Stream.Status = stOk;
  Stream.Done;
end;

end.
