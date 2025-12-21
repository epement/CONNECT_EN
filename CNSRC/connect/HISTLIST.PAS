{$I-,F+,O+,X+}
unit HistList;

interface

uses Objects;

type
  PHistoryRec = ^THistoryRec;
  THistoryRec = record
    StrPtr: PString;
    Id: Byte;
    Lock: Boolean;
  end;

  PHistoryList = ^THistoryList;
  THistoryList = object(TSortedCollection)
    Locked: Boolean;
    IndexMode: Byte;
    SortId: Byte;
    SortMode: Byte;
    function Compare(Key1, Key2: Pointer): Integer; virtual;
    procedure FreeItem(Item: Pointer); virtual;
    procedure Insert(Item: Pointer); virtual;
  end;

  THistoryStrProc = procedure(Id: Byte; Index: Integer;
    var S: String; var Offset: Byte);

const
  HistoryList: PHistoryList = nil;
  HistoryDepth: Word = 10;
  LastWasEmpty: Boolean = False;

  hlExact = 1;
  hlRelat = 2;

  hsNone = 0;
  hsLockedFirst = 1;
  hsLockedLast = 2;

procedure InitHistory;
procedure DoneHistory;
procedure ClearHistory;
procedure ClearUnlockedHistory;
procedure ClearHistoryId(Id: Byte);
procedure StoreHistory(var S: TStream);
procedure LoadHistory(var S: TStream);

function HistoryCount(Id: Byte): Word;
procedure HistoryAdd(Id: Byte; Str: String; Trim: Boolean);
procedure HistoryDelete(Id: Byte; Index: Integer);
procedure HistoryToggleLock(Id: Byte; Index: Integer);
procedure HistorySetLock(Id: Byte; Index: Integer; Lock: Byte);
function HistoryLockIndex(Id: Byte; Lock: Byte): Integer;
function HistoryStr(Id: Byte; Index: Integer): String;
function HistoryRec(Id: Byte; Index: Integer): PHistoryRec;
function HistoryIndex(Id: Byte; const S: String): Integer;
function HistoryWidth(Id: Byte): Integer;
procedure GetHistoryStr(Id: Byte; Index: Integer;
  var S: String; var Offset: Byte);
procedure HistorySort(Id: Byte; Mode: Byte);

const
  HistoryStrProc: THistoryStrProc = GetHistoryStr;

implementation

uses Drivers, HeapUMB, TPString;

const
  SafetyPool = 8192;

function THistoryList.Compare(Key1, Key2: Pointer): Integer;
var
  B1, B2: Byte;
begin
  if (SortMode <> hsNone) and
     (PHistoryRec(Key1)^.Id = PHistoryRec(Key2)^.Id) and
     (PHistoryRec(Key1)^.Id = SortId) then
  begin
    B1 := Byte(PHistoryRec(Key1)^.Lock);
    B2 := Byte(PHistoryRec(Key2)^.Lock);
    if SortMode = hsLockedLast then
      if ((B1 = 0) and (B2 <> 0)) or
	 ((B1 > 1) and (B2 = 1)) or
	 ((B1 > 1) and (B2 > 1) and (B1 < B2)) then
	Compare := 1
      else Compare := -1
    else
      if ((B1 <> 0) and (B2 = 0)) or
	 ((B1 > 1) and (B2 = 1)) or
	 ((B1 > 1) and (B2 > 1) and (B1 < B2)) then
	Compare := 1
      else Compare := -1
  end
  else if PHistoryRec(Key1)^.Id < PHistoryRec(Key2)^.Id then
    Compare := 1
  else Compare := -1
end;

procedure THistoryList.FreeItem(Item: Pointer);
begin
  if Item <> nil then
  begin
{
    DisposeStr(PHistoryRec(Item)^.StrPtr);
    FreeMem(Item, SizeOf(THistoryRec));
}
    DisposeStrUMB(PHistoryRec(Item)^.StrPtr);
    FreeMemUMB(Item, SizeOf(THistoryRec));
  end;
end;

procedure THistoryList.Insert(Item: Pointer);
var
  Can: Boolean;
begin
  if Count < Limit then Can := MaxAvail > SafetyPool
  else Can := MaxAvail > LongMul(Limit + Delta, 4) + SafetyPool;
  if Can then Inherited Insert(Item)
  else FreeItem(Item);
end;

procedure InitHistory;
begin
  New(HistoryList, Init(64, 64));
end;

procedure DoneHistory;
begin
  Dispose(HistoryList, Done);
end;

procedure ClearHistory;
begin
  DoneHistory;
  InitHistory;
end;

procedure ClearUnlockedHistory;
var
  I: Integer;
begin
  I := HistoryList^.Count - 1;
  while I >= 0 do
  begin
    if not PHistoryRec(HistoryList^.At(I))^.Lock then
      HistoryList^.AtFree(I);
    Dec(I);
  end;
end;

procedure ClearHistoryId(Id: Byte);
var
  I: Integer;
begin
  I := HistoryCount(Id);
  while I > 0 do
  begin
    HistoryDelete(Id, 0);
    Dec(I);
  end;
end;

procedure LoadHistory(var S: TStream);
var
  I, Count: Integer;
  P: PHistoryRec;
  Sign: String;
begin
  Sign[0] := #9;
  S.Read(Sign[1], 9);
  S.Read(Count, SizeOf(Integer));
  if Sign <> 'HISTORIES' then Count := MaxInt
  else for I := 0 to Count - 1 do
  begin
    if S.Status <> stOk then
    begin
      ClearHistory;
      Exit;
    end;
{
    GetMem(P, SizeOf(THistoryRec));
    P^.StrPtr := S.ReadStr;
}
    GetMemUMB(P, SizeOf(THistoryRec));
    P^.StrPtr := ReadStrUMB(@S);
    S.Read(P^.Id, SizeOf(Byte) + SizeOf(Boolean));
    HistoryList^.Insert(P);
  end;
  if HistoryList^.Count <> Count then S.Error(stReadError, 0);
end;

procedure StoreHistory(var S: TStream);
var
  I: Integer;
  P: PHistoryRec;
  Sign: String;
begin
  Sign := 'HISTORIES';
  S.Write(Sign[1], 9);
  S.Write(HistoryList^.Count, SizeOf(Integer));
  for I := 0 to HistoryList^.Count - 1 do
  begin
    if S.Status <> stOk then Exit;
    P := HistoryList^.At(I);
    S.WriteStr(P^.StrPtr);
    S.Write(P^.Id, SizeOf(Byte) + SizeOf(Boolean));
  end;
end;

procedure GetListIndex(Id: Byte; Index: Integer; var I: Integer);
var
  Count: Integer;
  P: PHistoryRec;
  R: THistoryRec;
begin
  R.Id := Id;
  HistoryList^.Search(@R, I);
  Count := 0;
  while I > 0 do
  begin
    Dec(I);
    P := HistoryList^.At(I);
    if P^.Id <> Id then Break;
    if Count = Index then Exit;
    Inc(Count);
  end;
  I := -1;
end;

function HistoryCount(Id: Byte): Word;
var
  I, Count: Integer;
  P: PHistoryRec;
begin
  Count := 0;
  GetListIndex(Id, 0, I);
  while I >= 0 do
  begin
    P := HistoryList^.At(I);
    if P^.Id <> Id then Break;
    Inc(Count);
    Dec(I);
  end;
  HistoryCount := Count;
end;

{ Added 02.03.99 }
function SameStrings(S1, S2: String): Boolean;
var
  I: Integer;
begin
  I := Pos(#$FF, S1);
  if I <> 0 then S1[0] := Char(I - 1);
  I := Pos(#$FF, S2);
  if I <> 0 then S2[0] := Char(I - 1);
  SameStrings := S1 = S2;
end;

procedure HistoryAdd(Id: Byte; Str: String; Trim: Boolean);
var
  Added: Boolean;
  I, Count: Integer;
  P: PHistoryRec;
begin
  if HistoryList^.Locked or
     (GetShiftState and (kbAltShift + kbCtrlShift) =
       kbAltShift + kbCtrlShift) then Exit;
  LastWasEmpty := False;
  if Trim then
    while (Length(Str) > 0) and
      (Str[Length(Str)] in [#0, #32]) do Dec(Str[0]);
  LastWasEmpty := Str = '';
  if LastWasEmpty then Exit;

  Count := 0;
  Added := False; { Added 02.03.99 }
  GetListIndex(Id, 0, I);
  while I >= 0 do
  begin
    P := HistoryList^.At(I);
    if P^.Id <> Id then Break;
    if SameStrings(P^.StrPtr^, Str) then
      if Added then HistoryList^.AtFree(I)
      else
      begin
{
	DisposeStr(P^.StrPtr);
	P^.StrPtr := NewStr(Str);
}
	DisposeStrUMB(P^.StrPtr);
	P^.StrPtr := NewStrUMB(Str);
	HistoryList^.AtDelete(I);
	HistoryList^.Insert(P);
	Added := True;
      end;
    Inc(Count);
    Dec(I);
  end;

  if Added then Exit;

  if Count >= HistoryDepth then
  begin
    repeat
      Inc(I);
      if I >= HistoryList^.Count then Break;
      P := HistoryList^.At(I);
      if P^.Id <> Id then Break;
      if not P^.Lock then
      begin
	HistoryList^.AtFree(I);
	Dec(Count);
	if Count < HistoryDepth then Break;
      end;
    until False;
    if Count >= HistoryDepth then Exit;
  end;

{
  GetMem(P, SizeOf(THistoryRec));
  P^.StrPtr := NewStr(Str);
}
  GetMemUMB(P, SizeOf(THistoryRec));
  P^.StrPtr := NewStrUMB(Str);
  P^.Id := Id;
  P^.Lock := False;
  HistoryList^.Insert(P);
end;

procedure HistoryDelete(Id: Byte; Index: Integer);
var
  I: Integer;
begin
  GetListIndex(Id, Index, I);
  if I <> -1 then HistoryList^.AtFree(I);
end;

procedure HistoryToggleLock(Id: Byte; Index: Integer);
var
  I: Integer;
  P: PHistoryRec;
begin
  GetListIndex(Id, Index, I);
  if I <> -1 then
  begin
    P := HistoryList^.At(I);
    P^.Lock := not P^.Lock;
  end;
end;

procedure HistorySetLock(Id: Byte; Index: Integer; Lock: Byte);
var
  I: Integer;
  P: PHistoryRec;
begin
  GetListIndex(Id, Index, I);
  if I <> -1 then
  begin
    P := HistoryList^.At(I);
    Byte(P^.Lock) := Lock;
  end;
end;

function HistoryLockIndex(Id: Byte; Lock: Byte): Integer;
var
  I, Count: Integer;
  P: PHistoryRec;
begin
  GetListIndex(Id, 0, I);
  Count := 0;
  while I >= 0 do
  begin
    P := HistoryList^.At(I);
    if P^.Id <> Id then Break;
    if Byte(P^.Lock) = Lock then
    begin
      HistoryLockIndex := Count;
      Exit;
    end;
    Dec(I);
    Inc(Count);
  end;
  HistoryLockIndex := -1;
end;

function HistoryStr(Id: Byte; Index: Integer): String;
var
  I: Integer;
begin
  GetListIndex(Id, Index, I);
  if I <> -1 then
    HistoryStr := PHistoryRec(HistoryList^.At(I))^.StrPtr^
  else HistoryStr := '';
end;

function HistoryRec(Id: Byte; Index: Integer): PHistoryRec;
var
  I: Integer;
begin
  GetListIndex(Id, Index, I);
  if I <> -1 then HistoryRec := HistoryList^.At(I)
  else HistoryRec := nil;
end;

function HistoryIndex(Id: Byte; const S: String): Integer;
var
  I, Count: Integer;
  P: PHistoryRec;
begin
  GetListIndex(Id, 0, I);
  Count := 0;
  while I >= 0 do
  begin
    P := HistoryList^.At(I);
    if P^.Id <> Id then Break;
    if ((HistoryList^.IndexMode and hlExact <> 0) and
	(S = P^.StrPtr^)) or
       ((HistoryList^.IndexMode and hlExact = 0) and
	(S[Length(S)] = #$FF) and
	(Pos(StUpcase(S), StUpcase(P^.StrPtr^)) <> 0)) or
       ((HistoryList^.IndexMode and hlExact = 0) and
	(Pos(S, P^.StrPtr^) <> 0)) then
    begin
      if HistoryList^.IndexMode and hlRelat <> 0 then
	HistoryIndex := Count
      else HistoryIndex := I;
      Exit;
    end;
    Dec(I);
    Inc(Count);
  end;
  HistoryIndex := -1;
end;

function HistoryWidth(Id: Byte): Integer;
var
  Width, I, L: Integer;
  P: PHistoryRec;
begin
  Width := 0;
  GetListIndex(Id, 0, I);
  while I >= 0 do
  begin
    P := HistoryList^.At(I);
    if P^.Id <> Id then Break;
    L := Length(P^.StrPtr^);
    if L > Width then Width := L;
    Dec(I);
  end;
  HistoryWidth := Width + 2;
end;

procedure GetHistoryStr(Id: Byte; Index: Integer;
  var S: String; var Offset: Byte);
begin
  S := HistoryStr(Id, Index);
  UpcaseSt(S);
  Offset := 1;
end;

procedure HistorySort(Id: Byte; Mode: Byte);
var
  I: Integer;
  L: PCollection;
  P: PHistoryRec;
begin
  GetListIndex(Id, 0, I);
  if I = -1 then Exit;
  L := New(PCollection, Init(HistoryDepth, 4));
  while I >= 0 do
  begin
    P := HistoryList^.At(I);
    if P^.Id <> Id then Break;
    HistoryList^.AtDelete(I);
    L^.Insert(P);
    Dec(I);
  end;
  HistoryList^.SortId := Id;
  HistoryList^.SortMode := Mode;
  I := L^.Count;
  while I > 0 do
  begin
    Dec(I);
    P := L^.At(I);
    L^.AtDelete(I);
    HistoryList^.Insert(P);
  end;
  Dispose(L, Done);
  HistoryList^.SortId := 0;
  HistoryList^.SortMode := hsNone;
end;

end.