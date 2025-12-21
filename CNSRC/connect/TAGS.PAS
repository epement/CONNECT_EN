{$I-,F-,O-,X+}
unit Tags;

interface

uses Objects;

type
  PTagList = ^TTagList;
  TTagList = object(TSortedCollection)
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    procedure DeleteName(const Name: String);
    procedure FreeItem(Item: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure InsertName(const Name: String);
    function NameFound(const Name: String): Boolean;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
  end;

const
  TagList: PTagList = nil;

procedure InitTagList;
procedure DoneTagList;

implementation

uses CRC32;

const
  SafetyPool = 8192;

function TTagList.Compare(Key1, Key2: Pointer): Integer;
begin
  if Longint(Key1) = Longint(Key2) then Compare := 0
  else if Longint(Key1) > Longint(Key2) then Compare := 1
  else Compare := -1;
end;

procedure TTagList.DeleteName(const Name: String);
var
  I: Integer;
  CRC: Longint;
begin
  CRC := GetStringCRC32UC(Name);
  if Search(Pointer(CRC), I) then AtFree(I);
end;

procedure TTagList.FreeItem(Item: Pointer);
begin
end;

function TTagList.GetItem(var S: TStream): Pointer;
var
  L: Longint;
begin
  S.Read(L, SizeOf(Longint));
  GetItem := Pointer(L);
end;

procedure TTagList.InsertName(const Name: String);
var
  CanInsert: Boolean;
  I: Integer;
  CRC: Longint;
begin
  if Count < Limit then CanInsert := MaxAvail > SafetyPool
  else CanInsert := MaxAvail > LongMul(Limit + Delta, 4) + SafetyPool;
  if not CanInsert then Exit;
  CRC := GetStringCRC32UC(Name);
  if not Search(Pointer(CRC), I) then AtInsert(I, Pointer(CRC));
end;

function TTagList.NameFound(const Name: String): Boolean;
var
  I: Integer;
  CRC: Longint;
begin
  CRC := GetStringCRC32UC(Name);
  NameFound := Search(Pointer(CRC), I);
end;

procedure TTagList.PutItem(var S: TStream; Item: Pointer);
begin
  S.Write(Item, SizeOf(Longint));
end;

procedure InitTagList;
begin
  TagList := New(PTagList, Init(16, 16));
end;

procedure DoneTagList;
begin
  if TagList <> nil then Dispose(TagList, Done);
end;

end.