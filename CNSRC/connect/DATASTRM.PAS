{$I-,F+,O+,X+}
unit DataStrm;

interface

uses Objects, Streams;

type
  PDataBuffer = ^TDataBuffer;
  TDataBuffer = object(TCollection)
    DataSize: Word;
    constructor Init(ALimit, ADelta: Integer; ADataSize: Word);
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PDataStream = ^TDataStream;
  TDataStream = object(TDosStream)
    Buffer: PCollection;
    BufSize: Integer;
    DataSize: Word;
    Count: Integer;
    TopItem: Integer;
    constructor Init(FileName: FNameStr; InitMode: Word;
      ABufSize: Integer; ADataSize: Word);
    destructor Done; virtual;
    procedure DeleteItem(Index: Integer);
    function GetItem(Index: Integer): Pointer;
    procedure InsertItem(Index: Integer; Item: Pointer);
    procedure NewItem(Item: Pointer);
    procedure ReplaceItem(Index: Integer; Item: Pointer);
  end;

implementation

uses Memory;

constructor TDataBuffer.Init(ALimit, ADelta: Integer; ADataSize: Word);
begin
  TCollection.Init(ALimit, ADelta);
  DataSize := ADataSize;
end;

procedure TDataBuffer.FreeItem(Item: Pointer);
begin
  if Item <> nil then FreeMem(Item, DataSize);
end;

constructor TDataStream.Init(FileName: FNameStr; InitMode: Word;
  ABufSize: Integer; ADataSize: Word);
begin
  Inherited Init(FileName, InitMode);
  Buffer := New(PDataBuffer, Init(ABufSize, 1, ADataSize));
  BufSize := ABufSize;
  DataSize := ADataSize;
  TopItem := MaxInt;
  if (Status = stOk) and (InitMode <> stCreate) then
    Count := GetSize div DataSize;
end;

destructor TDataStream.Done;
begin
  if Buffer <> nil then Dispose(Buffer, Done);
  Inherited Done;
end;

procedure TDataStream.DeleteItem(Index: Integer);
var
  Item: Pointer;
  I: Integer;
begin
  if Index >= Count then Exit;
  Item := MemAlloc(DataSize);
  if Item = nil then Exit;
  TopItem := MaxInt;
  I := Index + 1;
  while (Status = stOk) and (I < Count) do
  begin
    Seek(I * DataSize);
    Read(Item^, DataSize);
    Seek((I - 1) * DataSize);
    Write(Item^, DataSize);
    Inc(I);
  end;
  FreeMem(Item, DataSize);
  if Status <> stOk then Exit;
  Seek((Count - 1) * DataSize);
  Truncate;
  if Status = stOk then Dec(Count);
end;

function TDataStream.GetItem(Index: Integer): Pointer;
var
  Item: Pointer;
  I: Integer;
begin
  if Index >= Count then GetItem := nil
  else
  begin
    if (Index < TopItem) or
       (Index >= TopItem + Buffer^.Count) then
    begin
      Buffer^.FreeAll;
      TopItem := Index - BufSize div 2;
      if TopItem + BufSize > Count then TopItem := Count - BufSize;
      if TopItem < 0 then TopItem := 0;
      I := TopItem;
      while (I < TopItem + BufSize) and (I < Count) do
      begin
	Item := MemAlloc(DataSize);
	if Item = nil then Break;
	Seek(I * DataSize);
	Read(Item^, DataSize);
	if Status <> stOk then Break;
	Buffer^.Insert(Item);
	Inc(I);
      end;
    end;
    I := Index - TopItem;
    GetItem := Buffer^.At(I);
  end;
end;

procedure TDataStream.InsertItem(Index: Integer; Item: Pointer);
var
  P: Pointer;
  I: Integer;
begin
  if Index >= Count then Exit;
  P := MemAlloc(DataSize);
  if P = nil then Exit;
  TopItem := MaxInt;
  I := Count - 1;
  while (Status = stOk) and (I >= Index) do
  begin
    Seek(I * DataSize);
    Read(P^, DataSize);
    Seek((I + 1) * DataSize);
    Write(P^, DataSize);
    Dec(I);
  end;
  FreeMem(P, DataSize);
  if Status <> stOk then Exit;
  Seek(Index * DataSize);
  Write(Item^, DataSize);
  if Status = stOk then Inc(Count);
end;

procedure TDataStream.NewItem(Item: Pointer);
begin
  TopItem := MaxInt;
  Seek(GetSize);
  Write(Item^, DataSize);
  if Status = stOk then Inc(Count);
end;

procedure TDataStream.ReplaceItem(Index: Integer; Item: Pointer);
begin
  if Index >= Count then Exit;
  TopItem := MaxInt;
  Seek(Index * DataSize);
  Write(Item^, DataSize);
end;

end.