{$I-,X+}
unit FMGroups;

interface

uses Objects;

type
  PGroupRec = ^TGroupRec;
  TGroupRec = record
    Mask: String[12];
    Color: Byte;
    Index: Byte;
  end;

  PGroupList = ^TGroupList;
  TGroupList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

procedure InitGroups(const Name: FNameStr);
procedure DoneGroups;

const
  Groups: PGroupList = nil;

implementation

uses HeapUMB;

procedure TGroupList.FreeItem(Item: Pointer);
begin
  if Item <> nil then
{    FreeMem(Item, SizeOf(TGroupRec));}
    FreeMemUMB(Item, SizeOf(TGroupRec));
end;

procedure InitGroups(const Name: FNameStr);
var
  P: PGroupRec;
  S: TDosStream;
begin
  Groups := New(PGroupList, Init(8, 8));
  S.Init(Name, stOpenRead);
  while S.Status = stOk do
  begin
{    GetMem(P, SizeOf(TGroupRec));}
    GetMemUMB(P, SizeOf(TGroupRec));
    S.Read(P^, SizeOf(TGroupRec));
    if S.Status <> stOk then
{      FreeMem(P, SizeOf(TGroupRec))}
      FreeMemUMB(P, SizeOf(TGroupRec))
    else Groups^.Insert(P);
  end;
  S.Done;
  Groups^.Insert(nil);
end;

procedure DoneGroups;
begin
  if Groups <> nil then Dispose(Groups, Done);
end;

end.