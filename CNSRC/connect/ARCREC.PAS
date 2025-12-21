{$F+,O+,X+}
unit ArcRec;

interface

uses Objects;

type
  PArchiveRec = ^TArchiveRec;
  TArchiveRec = record
    PackerName: PString;
    UnpackerName: PString;
    Extension: PString;
    Extract: PString;
    ExWithDirs: PString;
    Add: PString;
    AddWithDirs: PString;
    Move: PString;
    MoveWithDirs: PString;
    Del: PString;
    Test: PString;
    Password: PString;
    ListChar: Char;
    Main: Word;
  end;

  PUserArchiveRec = ^TUserArchiveRec;
  TUserArchiveRec = record
    ArchiveRec: PArchiveRec;
    Mask: PString;
    TradeMark: PString;
    ViewCommand: PString;
    DirViewCommand: PString;
    EnvCondition: PString;
    Reserved: PString;
  end;

const
  NumArchives = 13;
  ArchiverName = 'CONNECT.ASP';
  UserArchiverName = 'CONNECT.ASU';

  amSwapMainBody = $0001;
  amUserScreen   = $0002;
  amLoadCOMMAND  = $0004;
  amEnableLFN    = $0008;
  amPrompt       = $0010;
  amOldLFNBit    = $8000;

function NewArchiveRec: PArchiveRec;
procedure DisposeArchiveRec(P: PArchiveRec);
procedure ReadArchiveRec(S: PStream; P: PArchiveRec);
procedure WriteArchiveRec(S: PStream; P: PArchiveRec);

function NewUserArchiveRec: PUserArchiveRec;
procedure DisposeUserArchiveRec(P: PUserArchiveRec);
procedure ReadUserArchiveRec(S: PStream; P: PUserArchiveRec);
procedure WriteUserArchiveRec(S: PStream; P: PUserArchiveRec);

implementation

uses HeapUMB;

function NewArchiveRec: PArchiveRec;
var
  P: PArchiveRec;
begin
{  GetMem(P, SizeOf(TArchiveRec));}
  GetMemUMB(P, SizeOf(TArchiveRec));
  FillChar(P^, SizeOf(TArchiveRec), 0);
  NewArchiveRec := P;
end;

procedure DisposeArchiveRec(P: PArchiveRec);
begin
  if P = nil then Exit;
  with P^ do
  begin
{
    DisposeStr(Password);
    DisposeStr(Test);
    DisposeStr(Del);
    DisposeStr(MoveWithDirs);
    DisposeStr(Move);
    DisposeStr(AddWithDirs);
    DisposeStr(Add);
    DisposeStr(ExWithDirs);
    DisposeStr(Extract);
    DisposeStr(Extension);
    DisposeStr(UnpackerName);
    DisposeStr(PackerName);
}
    DisposeStrUMB(Password);
    DisposeStrUMB(Test);
    DisposeStrUMB(Del);
    DisposeStrUMB(MoveWithDirs);
    DisposeStrUMB(Move);
    DisposeStrUMB(AddWithDirs);
    DisposeStrUMB(Add);
    DisposeStrUMB(ExWithDirs);
    DisposeStrUMB(Extract);
    DisposeStrUMB(Extension);
    DisposeStrUMB(UnpackerName);
    DisposeStrUMB(PackerName);
  end;
{  FreeMem(P, SizeOf(TArchiveRec));}
  FreeMemUMB(P, SizeOf(TArchiveRec));
end;

procedure ReadArchiveRec(S: PStream; P: PArchiveRec);
begin
{
  with S^, P^ do
  begin
    PackerName := ReadStr;
    UnpackerName := ReadStr;
    Extension := ReadStr;
    Extract := ReadStr;
    ExWithDirs := ReadStr;
    Add := ReadStr;
    AddWithDirs := ReadStr;
    Move := ReadStr;
    MoveWithDirs := ReadStr;
    Del := ReadStr;
    Test := ReadStr;
    Password := ReadStr;
    Read(ListChar, SizeOf(Char));
    Read(Main, SizeOf(Word));
  end;
}
  with P^ do
  begin
    PackerName := ReadStrUMB(S);
    UnpackerName := ReadStrUMB(S);
    Extension := ReadStrUMB(S);
    Extract := ReadStrUMB(S);
    ExWithDirs := ReadStrUMB(S);
    Add := ReadStrUMB(S);
    AddWithDirs := ReadStrUMB(S);
    Move := ReadStrUMB(S);
    MoveWithDirs := ReadStrUMB(S);
    Del := ReadStrUMB(S);
    Test := ReadStrUMB(S);
    Password := ReadStrUMB(S);
    S^.Read(ListChar, SizeOf(Char));
    S^.Read(Main, SizeOf(Word));
    if Main and amOldLFNBit <> 0 then
      Main := (Main and not amOldLFNBit) or amEnableLFN;
  end;
end;

procedure WriteArchiveRec(S: PStream; P: PArchiveRec);
begin
  with S^, P^ do
  begin
    WriteStr(PackerName);
    WriteStr(UnpackerName);
    WriteStr(Extension);
    WriteStr(Extract);
    WriteStr(ExWithDirs);
    WriteStr(Add);
    WriteStr(AddWithDirs);
    WriteStr(Move);
    WriteStr(MoveWithDirs);
    WriteStr(Del);
    WriteStr(Test);
    WriteStr(Password);
    Write(ListChar, SizeOf(Char));
    Write(Main, SizeOf(Word));
  end;
end;

function NewUserArchiveRec: PUserArchiveRec;
var
  P: PUserArchiveRec;
begin
{  GetMem(P, SizeOf(TUserArchiveRec));}
  GetMemUMB(P, SizeOf(TUserArchiveRec));
  FillChar(P^, SizeOf(TUserArchiveRec), 0);
  P^.ArchiveRec := NewArchiveRec;
  NewUserArchiveRec := P;
end;

procedure DisposeUserArchiveRec(P: PUserArchiveRec);
begin
  if P = nil then Exit;
  DisposeArchiveRec(P^.ArchiveRec);
  with P^ do
  begin
{
    DisposeStr(Reserved);
    DisposeStr(EnvCondition);
    DisposeStr(DirViewCommand);
    DisposeStr(ViewCommand);
    DisposeStr(TradeMark);
    DisposeStr(Mask);
}
    DisposeStrUMB(Reserved);
    DisposeStrUMB(EnvCondition);
    DisposeStrUMB(DirViewCommand);
    DisposeStrUMB(ViewCommand);
    DisposeStrUMB(TradeMark);
    DisposeStrUMB(Mask);
  end;
{  FreeMem(P, SizeOf(TUserArchiveRec));}
  FreeMemUMB(P, SizeOf(TUserArchiveRec));
end;

procedure ReadUserArchiveRec(S: PStream; P: PUserArchiveRec);
begin
  ReadArchiveRec(S, P^.ArchiveRec);
{
  with S^, P^ do
  begin
    Mask := ReadStr;
    TradeMark := ReadStr;
    ViewCommand := ReadStr;
    DirViewCommand := ReadStr;
    Reserved := ReadStr;
  end;
}
  with P^ do
  begin
    Mask := ReadStrUMB(S);
    TradeMark := ReadStrUMB(S);
    ViewCommand := ReadStrUMB(S);
    DirViewCommand := ReadStrUMB(S);
    EnvCondition := ReadStrUMB(S);
    if EnvCondition <> nil then Reserved := ReadStrUMB(S);
  end;
end;

procedure WriteUserArchiveRec(S: PStream; P: PUserArchiveRec);
begin
  WriteArchiveRec(S, P^.ArchiveRec);
  with S^, P^ do
  begin
    WriteStr(Mask);
    WriteStr(TradeMark);
    WriteStr(ViewCommand);
    WriteStr(DirViewCommand);
    WriteStr(EnvCondition);
    if EnvCondition <> nil then WriteStr(Reserved);
  end;
end;

end.