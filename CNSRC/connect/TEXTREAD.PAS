{$I-,F+,O+,X+}
unit TextRead;

interface

uses Objects, LFN;

type
  PPosBuffer = ^TPosBuffer;
  TPosBuffer = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PTextReader = ^TTextReader;
  TTextReader = object(TObject)
    Source: Text;
    FullName: TNameZ;
    AssignTextMode: lAPIType;
    SourceName: PString;
    SourceSize: Longint;
    Buffer: PCollection;
    BufOrg: Longint;
    BufEnd: Longint;
    PosBuffer: PCollection;
    UnixMode: Boolean;
    Open: Boolean;
    constructor Init;
    destructor Done; virtual;
    procedure NewBuffer(ABuffer: PCollection);
    procedure NewSourceName(const Name: FNameStr);
    procedure InitSource;
    procedure DoneSource;
    procedure OpenSource;
    procedure CloseSource;
    procedure ReadLine(var S: String; var Pos: Longint);
    function InsertLine(Index: Integer;
      var S: String; Pos: Longint): Boolean;
    procedure FillBuffer(Pos: Longint);
    procedure ReadDown(var Count: Integer);
    procedure ReadUp(var Count: Integer);
    procedure ReadLastPortion;
  end;

implementation

uses Dos, HeapUMB, DosTools, TPString, Defaults;

const
  MaxBufLines = 128;
  SourceDelta = $1000;

procedure TPosBuffer.FreeItem(Item: Pointer);
begin
end;

constructor TTextReader.Init;
begin
  Inherited Init;
  PosBuffer := New(PPosBuffer, Init(MaxBufLines, 16));
  SourceSize := -1;
end;

destructor TTextReader.Done;
begin
  DoneSource;
{  DisposeStr(SourceName);}
  DisposeStrUMB(SourceName);
  Dispose(PosBuffer, Done);
  Inherited Done;
end;

procedure TTextReader.NewBuffer(ABuffer: PCollection);
begin
  Buffer := ABuffer;
end;

procedure TTextReader.NewSourceName(const Name: FNameStr);
begin
{
  DisposeStr(SourceName);
  SourceName := NewStr(Name);
}
  DisposeStrUMB(SourceName);
  SourceName := NewStrUMB(Name);
end;

procedure TTextReader.InitSource;
var
  S: String;
begin
  if SourceName = nil then Exit;
  lAssignText(lText(Addr(Source)^), SourceName^);
  OpenSource;
  if (IOResult <> 0) or IsDevice(TextRec(Source).Handle) then Exit;
  if (TextReadMode = trAuto) and not Eof(Source) then
  begin
    SetUNIXTextMode;
    Readln(Source, S);
    SetDOSTextMode;
    UnixMode := S[Length(S)] <> #13;
  end
  else UnixMode := TextReadMode = trUNIX;
  SourceSize := TextFileSize(Source);
  if SourceSize < 0 then SourceSize := MaxLongint;
  FillBuffer(0);
end;

procedure TTextReader.DoneSource;
begin
  CloseSource;
  BufOrg := 0;
  BufEnd := 0;
  SourceSize := -1;
end;

procedure TTextReader.OpenSource;
begin
  if not Open then
  begin
    Reset(Source);
    Open := True;
  end;
end;

procedure TTextReader.CloseSource;
begin
  if Open then
  begin
    Close(Source);
    InOutRes := 0;
    Open := False;
  end;
end;

procedure TTextReader.ReadLine(var S: String; var Pos: Longint);
begin
  if UnixMode then SetUNIXTextMode;
  Pos := TextPos(Source);
  Readln(Source, S);
  SetDOSTextMode;
end;

function TTextReader.InsertLine(Index: Integer;
  var S: String; Pos: Longint): Boolean;
var
  SaveCount: Integer;
begin
  S := Detab(S, 8);
  TrailTrim(S);
  SaveCount := Buffer^.Count;
{  Buffer^.AtInsert(Index, NewStr(S));}
  Buffer^.AtInsert(Index, NewStrUMB(S));
  PosBuffer^.AtInsert(Index, Pointer(Pos));
  InsertLine := SaveCount <> Buffer^.Count;
end;

procedure TTextReader.FillBuffer(Pos: Longint);
var
  S: String;
begin
  Buffer^.FreeAll;
  PosBuffer^.FreeAll;
  BufOrg := Pos;
  OpenSource;
  TextSeek(Source, BufOrg);
  repeat
    if Eof(Source) then Break;
    ReadLine(S, Pos);
    if (IOResult <> 0) or not InsertLine(Buffer^.Count, S, Pos) or
       (Buffer^.Count >= MaxBufLines) then Break;
  until False;
  BufEnd := TextPos(Source);
  CloseSource;
end;

procedure TTextReader.ReadDown(var Count: Integer);
var
  Pos: Longint;
  S: String;
begin
  while Count > 0 do
  begin
    Buffer^.AtFree(0);
    PosBuffer^.AtFree(0);
    Dec(Count);
  end;
  OpenSource;
  TextSeek(Source, BufEnd);
  repeat
    if Eof(Source) then Break;
    ReadLine(S, Pos);
    if (IOResult <> 0) or not InsertLine(Buffer^.Count, S, Pos) or
       (Buffer^.Count >= MaxBufLines) then Break;
  until False;
  BufOrg := Longint(PosBuffer^.At(0));
  BufEnd := TextPos(Source);
  CloseSource;
end;

procedure TTextReader.ReadUp(var Count: Integer);
var
  Pos: Longint;
  S: String;
begin
  while Buffer^.Count > Count do
  begin
    BufEnd := Longint(PosBuffer^.At(PosBuffer^.Count - 1));
    Buffer^.AtFree(Buffer^.Count - 1);
    PosBuffer^.AtFree(PosBuffer^.Count - 1);
  end;
  Pos := BufOrg - SourceDelta;
  if Pos < 0 then Pos := 0;
  OpenSource;
  TextSeek(Source, Pos);
  if Pos <> 0 then ReadLine(S, Pos);
  Count := 0;
  repeat
    if Eof(Source) then Break;
    ReadLine(S, Pos);
    if (IOResult <> 0) or (Pos >= BufOrg) then Break;
    if Buffer^.Count >= MaxBufLines then
    begin
      Buffer^.AtFree(0);
      PosBuffer^.AtFree(0);
      Dec(Count);
    end;
    if not InsertLine(Count, S, Pos) then Break;
    Inc(Count);
  until False;
  BufOrg := Longint(PosBuffer^.At(0));
  CloseSource;
end;

procedure TTextReader.ReadLastPortion;
var
  Count: Integer;
  Pos: Longint;
  S: String;
begin
  Buffer^.FreeAll;
  PosBuffer^.FreeAll;
  Pos := SourceSize - SourceDelta;
  if Pos < 0 then Pos := 0;
  OpenSource;
  TextSeek(Source, Pos);
  if Pos <> 0 then ReadLine(S, Pos);
  Count := 0;
  repeat
    if Eof(Source) then Break;
    ReadLine(S, Pos);
    if IOResult <> 0 then Break;
    if Buffer^.Count >= MaxBufLines then
    begin
      Buffer^.AtFree(0);
      PosBuffer^.AtFree(0);
      Dec(Count);
    end;
    if not InsertLine(Count, S, Pos) then Break;
    Inc(Count);
  until False;
  BufOrg := Longint(PosBuffer^.At(0));
  BufEnd := SourceSize;
  CloseSource;
end;

end.