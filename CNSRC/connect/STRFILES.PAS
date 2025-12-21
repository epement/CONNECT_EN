{$F+,I-,O+,X+}
unit StrFiles;

interface

uses Objects, LFN;

type
  PStrFile = ^TStrFile;
  TStrFile = object(TObject)
    Name: FNameStr;
    F: lText;
    constructor Init(const AName: FNameStr);
    procedure GetStr(const AKey: String; var S: String);
    procedure PutStr(const AKey, S: String);
  end;

implementation

uses Dos, App, MsgBox, EditMsg, StrCol, HeapUMB, LogFile, DosTools,
  TPString, Defaults;

constructor TStrFile.Init(const AName: FNameStr);
begin
  Inherited Init;
  Name := AName;
  lAssignText(F, Name);
end;

procedure TStrFile.GetStr(const AKey: String; var S: String);
var
  I: Integer;
  K: String;
begin
  LogEvent := lcDiskRead;
  DrawStatusLine('Reading strings from ' +
    TrimmedName(Name, 46) + '.');
  Reset(F.T);
  if IOResult <> 0 then CouldNotOpenMsgBox(Name)
  else if IsDevice(TextRec(F.T).Handle) then
  begin
    Close(F.T);
    InOutRes := 0;
    FileIsDeviceMsgBox(Name);
  end
  else
  begin
    K := Trim(AKey);
    while not Eof(F.T) do
    begin
      Readln(F.T, S);
      LeadTrim(S);
      if (S = '') or (S[1] = ';') then Continue;
      I := Pos('=', S);
      if I = 0 then Continue;
      if CompUCString(TrimTrail(Copy(S, 1, I - 1)), K) = Equal then
      begin
	Delete(S, 1, I);
	Close(F.T);
	InOutRes := 0;
	Exit;
      end;
    end;
    Close(F.T);
    InOutRes := 0;
  end;
  S := '';
end;

procedure TStrFile.PutStr(const AKey, S: String);
var
  I, Index, SaveCount: Integer;
  P: PString;
  List: PCollection;
  K, SS: String;
begin
  LogEvent := lcDiskWrite;
  DrawStatusLine('Writing strings to ' +
    TrimmedName(Name, 48) + '.');
  Reset(F.T);
  if IOResult <> 0 then Rewrite(F.T);
  if IOResult <> 0 then
  begin
    CouldNotCreateMsgBox(Name);
    Exit;
  end;
  if NotAccessible(TextRec(F.T).Handle) then
  begin
    Close(F.T);
    InOutRes := 0;
    FileIsDeviceMsgBox(Name);
    Exit;
  end;
  K := Trim(AKey);
  List := New(PStringsCollection, Init(16, 16));
  Index := -1;
  while not Eof(F.T) do
  begin
    Readln(F.T, SS);
    SaveCount := List^.Count;
{    List^.Insert(NewStr(SS));}
    List^.Insert(NewStrUMB(SS));
    if SaveCount = List^.Count then
    begin
      Close(F.T);
      InOutRes := 0;
      Dispose(List, Done);
      Application^.OutOfMemory;
      Exit;
    end;
    LeadTrim(SS);
    if (SS = '') or (SS[1] = ';') then Continue;
    I := Pos('=', SS);
    if I = 0 then Continue;
    if CompUCString(TrimTrail(Copy(SS, 1, I - 1)), K) = Equal then
      Index := List^.Count - 1;
  end;
  Close(F.T);
  InOutRes := 0;
  SS := AKey + '=' + S;
  if Index <> -1 then List^.AtFree(Index)
  else Index := List^.Count;
{  List^.AtInsert(Index, NewStr(SS));}
  List^.AtInsert(Index, NewStrUMB(SS));
  Rewrite(F.T);
  if IOResult = 0 then
  begin
    for Index := 0 to List^.Count - 1 do
    begin
      P := List^.At(Index);
      if P = nil then Writeln(F.T)
      else Writeln(F.T, P^);
      if IOResult <> 0 then
      begin
	CouldNotWriteMsgBox(Name);
	Break;
      end;
    end;
    Close(F.T);
    InOutRes := 0;
  end
  else CouldNotCreateMsgBox(Name);
  Dispose(List, Done);
end;

end.