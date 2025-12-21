{$I-,F+,O-,X+}
unit Swaps;

interface

uses Dos, Objects;

type
  PSwapLinesCollection = ^TSwapLinesCollection;
  TSwapLinesCollection = object(TCollection)
    Status: Integer;
    ExtraItems: PItemList;
    ExtraCount: Integer;
    ExtraLimit: Integer;
    constructor Init(ALimit, ADelta: Integer);
    constructor Load(var S: TStream);
    destructor Done; virtual;
    procedure Error(Code, Info: Integer); virtual;
    function ExtraAt(Index: Integer): Pointer;
    procedure ExtraAtFree(Index: Integer);
    procedure ExtraAtInsert(Index: Integer; Item: Pointer);
    procedure FreeItem(P: Pointer); virtual;
    function GetItem(var S: TStream): Pointer; virtual;
    procedure Insert(Item: Pointer); virtual;
    procedure PutItem(var S: TStream; Item: Pointer); virtual;
    procedure SetLimit(ALimit: Integer); virtual;
    procedure Store(var S: TStream);
  end;

  PArea = ^TArea;
  TArea = record
    KB: Integer;
    PB: Byte;
    KK: Integer;
    PK: Byte;
  end;

const
  DiskSwapStream: PStream = nil;
  DiskClipStream: PStream = nil;
  ClipLines: PCollection = nil;

  ClipAreaSelected: Boolean = False;
  ExpandClipArea: Boolean = False;

var
  ClipArea: PArea;
  TempName: String[8];
  SwapName, ClipName: String[12];
  SwapDir, DiskSwapName, DiskClipName: FNameStr;

procedure SetCNConfigName(var AName: FNameStr; const AExt: ExtStr);
procedure GetValidSwapDir(var ADir: FNameStr; ShowError: Boolean);
procedure InitDiskSwapStream(const AName: FNameStr; UseEMS: Boolean);
procedure DoneDiskSwapStream;
procedure InitDiskClipStream(const AName: FNameStr);
procedure DoneDiskClipStream(DoErase: Boolean);
procedure SetArea(Area: PArea; AKB, APB, AKK, APK: Integer);

implementation

uses Memory, App, Overlay, ConOvr, Streams, EditMsg, ClipPrim, DirPrim,
  TPString, Defaults;

const
  MaxExtraItems = 32632;

constructor TSwapLinesCollection.Init(ALimit, ADelta: Integer);
var
  SaveLimit: Integer;
  SaveItems: Pointer;
begin
  TCollection.Init(ALimit, ADelta);
  SaveItems := Items;
  Items := ExtraItems;
  SaveLimit := Limit;
  Limit := 0;
  SetLimit(ALimit);
  ExtraItems := Items;
  Items := SaveItems;
  ExtraLimit := Limit;
  Limit := SaveLimit;
end;

constructor TSwapLinesCollection.Load(var S: TStream);
var
  SaveCount, SaveLimit: Integer;
  SaveItems: Pointer;
begin
  TCollection.Load(S);
  SaveItems := Items;
  Items := ExtraItems;
  SaveCount := Count;
  Count := 0;
  SaveLimit := Limit;
  Limit := 0;
  SetLimit(Delta);
  ExtraItems := Items;
  Items := SaveItems;
  Count := SaveCount;
  ExtraLimit := Limit;
  Limit := SaveLimit;
end;

destructor TSwapLinesCollection.Done;
var
  SaveCount, SaveLimit: Integer;
  SaveItems: Pointer;
begin
  Dec(Count, ExtraCount);
  SaveItems := Items;
  Items := ExtraItems;
  SaveCount := Count;
  Count := ExtraCount;
  SaveLimit := Limit;
  Limit := ExtraLimit;
  FreeAll;
  SetLimit(0);
  Items := SaveItems;
  Count := SaveCount;
  Limit := SaveLimit;
  TCollection.Done;
end;

procedure TSwapLinesCollection.Error(Code, Info: Integer);
begin
  Status := Code;
end;

function TSwapLinesCollection.ExtraAt(Index: Integer): Pointer;
var
  SaveItems: Pointer;
begin
  if Index < MaxCollectionSize then ExtraAt := At(Index)
  else
  begin
    SaveItems := Items;
    Items := ExtraItems;
    Dec(Index, MaxCollectionSize);
    ExtraAt := At(Index);
    Items := SaveItems;
  end;
end;

procedure TSwapLinesCollection.ExtraAtFree(Index: Integer);
var
  SaveCount: Integer;
  SaveItems: Pointer;
begin
  Dec(Count, ExtraCount);
  if Index < MaxCollectionSize then
  begin
    AtFree(Index);
    if ExtraCount > 0 then
    begin
      Items^[Count] := ExtraItems^[0];
      Inc(Count);
      Dec(ExtraCount);
      Move(ExtraItems^[1], ExtraItems^[0], ExtraCount * SizeOf(Pointer));
    end;
  end
  else
  begin
    SaveItems := Items;
    Items := ExtraItems;
    SaveCount := Count;
    Count := ExtraCount;
    Dec(Index, MaxCollectionSize);
    AtFree(Index);
    Items := SaveItems;
    ExtraCount := Count;
    Count := SaveCount;
  end;
  Count := Count + ExtraCount;
end;

procedure TSwapLinesCollection.ExtraAtInsert(Index: Integer; Item: Pointer);
var
  SaveCount, SaveLimit: Integer;
  SaveItems, P: Pointer;
begin
  if Count = MaxExtraItems then
  begin
    Error(coOverflow, 0);
    Exit;
  end;
  Dec(Count, ExtraCount);
  if Index < MaxCollectionSize then
  begin
    if Count < MaxCollectionSize then AtInsert(Index, Item)
    else
    begin
      P := At(Count - 1);
      AtFree(Count - 1);
      SaveItems := Items;
      Items := ExtraItems;
      SaveCount := Count;
      Count := ExtraCount;
      SaveLimit := Limit;
      Limit := ExtraLimit;
      AtInsert(0, P);
      ExtraItems := Items;
      Items := SaveItems;
      ExtraCount := Count;
      Count := SaveCount;
      ExtraLimit := Limit;
      Limit := SaveLimit;
      AtInsert(Index, Item);
    end;
  end
  else
  begin
    SaveItems := Items;
    Items := ExtraItems;
    SaveCount := Count;
    Count := ExtraCount;
    SaveLimit := Limit;
    Limit := ExtraLimit;
    Dec(Index, MaxCollectionSize);
    AtInsert(Index, Item);
    ExtraItems := Items;
    Items := SaveItems;
    ExtraCount := Count;
    Count := SaveCount;
    ExtraLimit := Limit;
    Limit := SaveLimit;
  end;
  Count := Count + ExtraCount;
end;

procedure TSwapLinesCollection.FreeItem(P: Pointer);
begin
end;

function TSwapLinesCollection.GetItem(var S: TStream): Pointer;
var
  Item: Pointer;
begin
  S.Read(Item, SizeOf(Pointer));
  GetItem := Item;
end;

procedure TSwapLinesCollection.Insert(Item: Pointer);
begin
  ExtraAtInsert(Count, Item);
end;

procedure TSwapLinesCollection.SetLimit(ALimit: Integer);
const
  MaxStore = 256;
var
  Success: Boolean;
  W: Word;
  Storage: Array[0..MaxStore - 1] of Pointer;
begin
  if ALimit < Count then ALimit := Count;
  if ALimit > MaxCollectionSize then ALimit := MaxCollectionSize;
  if ALimit <> Limit then
  begin
    if (Limit <> 0) and (ALimit <> 0) then GiveTicks;
    W := Limit * SizeOf(Pointer);
    if ALimit = 0 then
      if Items <> nil then FreeMem(Items, W) else
    else
    begin
      if Count <> 0 then
      begin
        if Limit < MaxStore then Move(Items^, Storage, W)
        else
        begin
          OvrClearBuf;
          Move(Items^, Ptr(OvrHeapOrg, 0)^, W);
        end;
        FreeMem(Items, W);
      end;
      Items := MemAlloc(ALimit * SizeOf(Pointer));
      Success := Items <> nil;
      if Count <> 0 then
      begin
        if not Success then GetMem(Items, W);
        if Limit < MaxStore then Move(Storage, Items^, W)
        else Move(Ptr(OvrHeapOrg, 0)^, Items^, W);
      end;
      if not Success then Exit;
    end;
    Limit := ALimit;
  end;
end;

procedure TSwapLinesCollection.PutItem(var S: TStream; Item: Pointer);
begin
  S.Write(Item, SizeOf(Pointer));
end;

procedure TSwapLinesCollection.Store(var S: TStream);
var
  SaveCount, SaveLimit: Integer;
  SaveItems: Pointer;
begin
  if ExtraCount = 0 then TCollection.Store(S)
  else
  begin
    SaveItems := Items;
    Items := ExtraItems;
    SaveCount := Count;
    Count := ExtraCount;
    SaveLimit := Limit;
    Limit := ExtraLimit;
    TCollection.Store(S);
    Items := SaveItems;
    Count := SaveCount;
    Limit := SaveLimit;
  end;
end;

procedure SetCNConfigName(var AName: FNameStr; const AExt: ExtStr);
begin
  AName := ConfigPath + 'CONNECT.' + AExt;
end;

procedure GetValidSwapDir(var ADir: FNameStr; ShowError: Boolean);
var
  I: Integer;
begin
  if SwapDir = '' then ADir := ConfigPath
  else if SwapDir[1] = '$' then
  begin
    I := Pos('\', SwapDir);
    if I = 0 then I := Length(SwapDir) + 1;
    ADir := AddBackSlash(
      GetEnv(System.Copy(SwapDir, 2, I - 2)) +
      System.Copy(SwapDir, I, 255));
  end
  else ADir := AddBackSlash(SwapDir);
  if (ADir = '') or not DirPresent(ADir) then
  begin
    if ShowError then InvalidSwapDirMsgBox;
    ADir := ConfigPath;
  end;
end;

procedure InitDiskSwapStream(const AName: FNameStr; UseEMS: Boolean);
const
  Header: String[10] = 'Swap file ';
  Min = $1000;
  Max = $FFFF;
label
  DOSStream;
begin
  DiskSwapName := AName;
  if not UseEMS then Goto DOSStream;
  case ovPref of
    ovEMSOnly, ovEMSOver: DiskSwapStream := New(PEMSStream, Init(Min, Max));
    ovXMSOnly, ovXMSOver: DiskSwapStream := New(PXMSStream, Init(Min, Max));
  end;
  if DiskSwapStream^.Status <> stOk then
  begin
    Dispose(DiskSwapStream, Done);
    case ovPref of
      ovEMSOver: DiskSwapStream := New(PXMSStream, Init(Min, Max));
      ovXMSOver: DiskSwapStream := New(PEMSStream, Init(Min, Max));
      else Goto DOSStream;
    end;
    if DiskSwapStream^.Status <> stOk then
    begin
      Dispose(DiskSwapStream, Done);
DOSStream:
      DiskSwapStream := New(PDosStream, Init(DiskSwapName, stCreate));
    end;
  end;
  DiskSwapStream^.Write(Header[1], Length(Header));
  if TypeOf(DiskSwapStream^) = TypeOf(TDosStream) then
  begin
    PDosStream(DiskSwapStream)^.Close;
    PDosStream(DiskSwapStream)^.Open(DiskSwapName, stOpen);
  end;
  if (DiskSwapStream^.Status <> stOk) or
     (DiskSwapStream^.GetSize = 0) then DoneDiskSwapStream;
end;

procedure DoneDiskSwapStream;
var
  F: File;
begin
  if DiskSwapStream <> nil then Dispose(DiskSwapStream, Done);
  DiskSwapStream := nil;
  Assign(F, DiskSwapName);
  Erase(F);
  InOutRes := 0;
end;

procedure InitDiskClipStream(const AName: FNameStr);
const
  Header: String[10] = 'Clip file ';
var
  W: Word;
  F: File;
begin
  Assign(F, AName);
  GetFAttr(F, W);
  if DosError <> 0 then
  begin
    Rewrite(F, 1);
    BlockWrite(F, Header[1], Length(Header));
    Close(F);
    InOutRes := 0;
  end;
  DiskClipName := AName;
  DiskClipStream := New(PDosStream, Init(DiskClipName, stOpen));
  if (DiskClipStream^.Status <> stOk) or
     (DiskClipStream^.GetSize = 0) then DoneDiskClipStream(False);
end;

procedure DoneDiskClipStream(DoErase: Boolean);
var
  F: File;
begin
  if DiskClipStream <> nil then Dispose(DiskClipStream, Done);
  DiskClipStream := nil;
  if DoErase then
  begin
    Assign(F, DiskClipName);
    Erase(F);
    InOutRes := 0;
  end;
end;

procedure SetArea(Area: PArea; AKB, APB, AKK, APK: Integer);
begin
  if APB > $FF then
  begin
    Inc(AKB);
    Dec(APB, $FF);
  end;
  if APK > $FF then
  begin
    Inc(AKK);
    Dec(APK, $FF);
  end;
  with Area^ do
  begin
    KB := AKB;
    PB := APB;
    KK := AKK;
    PK := APK;
  end;
end;

end.
