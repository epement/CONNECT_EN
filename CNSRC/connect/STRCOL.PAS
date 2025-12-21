{$I-,X+,O+,F+}
unit StrCol;

interface

uses Objects;

type
  PStringsCollection = ^TStringsCollection;
  TStringsCollection = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure Insert(Item: Pointer); virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
  private
    function CanInsert: Boolean;
  end;

implementation

uses HeapUMB;

const
  SafetyPool = 8192;

function TStringsCollection.CanInsert: Boolean;
begin
  if Count < Limit then CanInsert := MaxAvail > SafetyPool
  else CanInsert := MaxAvail > LongMul(Limit + Delta, 4) + SafetyPool;
end;

procedure TStringsCollection.FreeItem(Item: Pointer);
begin
{  DisposeStr(Item);}
  DisposeStrUMB(Item);
end;

function TStringsCollection.GetItem(var S: TStream): Pointer;
var
  P: PString;
begin
{  P := S.ReadStr;}
  P := ReadStrUMB(@S);
  if not CanInsert then
  begin
{    DisposeStr(P);}
    DisposeStrUMB(P);
    P := nil;
  end;
  GetItem := P;
end;

procedure TStringsCollection.Insert(Item: Pointer);
begin
  if CanInsert then TCollection.Insert(Item)
  else FreeItem(Item);
end;

procedure TStringsCollection.PutItem(var S: TStream; Item: Pointer);
begin
  S.WriteStr(PString(Item));
end;

end.