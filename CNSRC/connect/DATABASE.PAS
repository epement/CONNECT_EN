{$I-,F+,O+,X+}
unit DataBase;

interface

uses Objects, EditFile;

type
  PDBFHeader = ^TDBFHeader;
  TDBFHeader = record
    Iden: Byte;
    Year: Byte;
    Month: Byte;
    Day: Byte;
    NumRecords: Longint;
    HeaderLen: Word;
    RecordLen: Word;
    Reserved: Array[1..20] of Byte;
  end;

  PFieldRec = ^TFieldRec;
  TFieldRec = record
    Name: Array[1..11] of Char;
    Iden: Char;
    Address: Longint;
    Len: Byte;
    Dec: Byte;
    Reserved: Array[1..14] of Char;
  end;

  PFieldList = ^TFieldList;
  TFieldList = object(TCollection)
    procedure FreeItem(Item: Pointer); virtual;
  end;

  PDataBase = ^TDataBase;
  TDataBase = object(TObject)
    Name: PString;
    DBF: PStream;
    Header: PDBFHeader;
    Fields: PFieldList;
    ExtraRecordLen: Word;
    OpenMode: Word;
    Time: Longint;
    InXLATTable: ConvertTable;
    OutXLATTable: ConvertTable;
    Options: Byte;
    constructor Init(const AName: FNameStr);
    destructor Done; virtual;
    procedure AddRecord(var Rec);
    procedure ConvertDates(AMode: Byte; var Rec);
    procedure ConvertFields(AMode: Byte);
    procedure ConvertRecord(AMode: Byte; var Rec);
    procedure DeleteRecord(APos: Longint);
    procedure DoneDBF;
    function GetFieldLen(P: PFieldRec): Word;
    function GetFieldNum(AOffset: Word): Byte;
    function GetFieldOfs(AField: Byte): Word;
    function GetFieldStr(AField: Byte; var Rec): String;
    procedure InitDBF(AMode: Word);
    procedure InsertRecord(APos: Longint; var Rec);
    procedure ReadFields;
    procedure ReadHeader;
    procedure ReadRecord(APos: Longint; var Rec);
    procedure SetCurTime;
    procedure SetXLATTable(const AName: FNameStr; AMode: Byte);
    procedure TruncateToLast;
    procedure UpdateHeader;
    function Valid: Boolean;
    function ValidChar(C: Char; AField: Byte): Boolean;
    function ValidRecord(var Field: Byte; var Code: Integer;
      RawDate: Boolean; var Rec): Boolean;
    procedure WriteEndingChar;
    procedure WriteRecord(APos: Longint; var Rec);
    procedure Zap;
  end;

const
  dbXLATIN   = $01;
  dbXLATOUT  = $02;
  dbHasDates = $04;

  dcXLATIN   = 0;
  dcXLATOUT  = 1;

  dcDATEIN   = 0;
  dcDATEOUT  = 1;

procedure DeleteBlock(S: PStream; APos: Longint; ASize: Word);
procedure InsertBlock(S: PStream; APos: Longint; ASize: Word; var Rec);

implementation

uses Dos, Drivers, Memory, FMDialog, Gauges, HeapUMB, LFN, Disks,
  TPString, Defaults;

procedure AllocBuffer(var Buffer: PByteArray; var Size: Word);
begin
  Size := $FFF0;
  repeat
    if Size < $2000 then GetMem(Buffer, Size)
    else Buffer := MemAlloc(Size);
    if Buffer <> nil then Exit;
    Size := Size shr 1;
  until False;
end;

procedure DeleteBlock(S: PStream; APos: Longint; ASize: Word);
var
  BufSize, Bytes: Word;
  Size, ReadPos, WritePos: Longint;
  Buffer: PByteArray;
begin
  Size := S^.GetSize;
  ReadPos := APos + ASize;
  if ReadPos >= Size then S^.Seek(APos)
  else
  begin
    WritePos := APos;
    AllocBuffer(Buffer, BufSize);
    repeat
      S^.Seek(ReadPos);
      if ReadPos + BufSize >= Size then Bytes := Size - ReadPos
      else Bytes := BufSize;
      S^.Read(Buffer^, Bytes);
      S^.Seek(WritePos);
      S^.Write(Buffer^, Bytes);
      Inc(ReadPos, Bytes);
      Inc(WritePos, Bytes);
    until (ReadPos >= Size) or (S^.Status <> stOk);
    FreeMem(Buffer, BufSize);
  end;
  S^.Truncate;
end;

procedure InsertBlock(S: PStream; APos: Longint; ASize: Word; var Rec);
var
  BufSize, Bytes: Word;
  Size, ReadPos, WritePos: Longint;
  Buffer: PByteArray;
begin
  Size := S^.GetSize;
  if APos < Size then
  begin
    AllocBuffer(Buffer, BufSize);
    ReadPos := Size;
    repeat
      if ReadPos - BufSize <= APos then Bytes := ReadPos - APos
      else Bytes := BufSize;
      Dec(ReadPos, Bytes);
      WritePos := ReadPos + ASize;
      S^.Seek(ReadPos);
      S^.Read(Buffer^, Bytes);
      S^.Seek(WritePos);
      S^.Write(Buffer^, Bytes);
    until (ReadPos = APos) or (S^.Status <> stOk);
    FreeMem(Buffer, BufSize);
    WritePos := APos;
  end
  else WritePos := Size;
  S^.Seek(WritePos);
  S^.Write(Rec, ASize);
end;

function FormatDateStr2000(Y, M, D: Word): String;
var
  Params: Array[0..4] of Longint;
  FS: String;
begin
  case CountryDate of
    csMMDDYY:
      begin
	Params[0] := M;
	Params[2] := D;
	Params[4] := Y;
      end;
    csDDMMYY:
      begin
	Params[0] := D;
	Params[2] := M;
	Params[4] := Y;
      end;
    csYYMMDD:
      begin
	Params[0] := Y;
	Params[2] := M;
	Params[4] := D;
      end;
    else
      begin
	Params[0] := Y;
	Params[2] := D;
	Params[4] := M;
      end;
  end;
  Params[1] := Byte(DateSeparator);
  Params[3] := Byte(DateSeparator);
  FormatStr(FS, '%02d%c%02d%c%04d', Params);
  FormatDateStr2000 := FS;
end;

function ConvertDateStr(var S: String; AMode: Byte): Boolean;
var
  Code: Integer;
  Month, Day, Year: Word;
  Params: Array[0..2] of Longint;
  SS: String[10];
  FS: String;
begin
  ConvertDateStr := False;
  SS := S;
  if AMode = dcDATEIN then
  begin
    S := '          ';
    Val(Copy(SS, 1, 4), Year, Code);
    if (Code <> 0) or (Year > 9999) then Exit;
    Val(Copy(SS, 5, 2), Month, Code);
    if (Code <> 0) or (Month < 1) or (Month > 12) then Exit;
    Val(Copy(SS, 7, 2), Day, Code);
    if (Code <> 0) or (Day < 1) or (Day > 31) then Exit;
    S := FormatDateStr2000(Year, Month, Day);
  end
  else
  begin
    S := '        ';
    GetMDY(SS, Month, Day, Year);
    if (Month = $FFFF) or (Day = $FFFF) or (Year = $FFFF) then Exit;
    Params[0] := Year;
    Params[1] := Month;
    Params[2] := Day;
    FormatStr(FS, '%04d%02d%02d', Params);
    S := FS;
  end;
  ConvertDateStr := True;
end;

procedure TFieldList.FreeItem(Item: Pointer);
begin
  if Item <> nil then
{    FreeMem(Item, SizeOf(TFieldRec));}
    FreeMemUMB(Item, SizeOf(TFieldRec));
end;

constructor TDataBase.Init(const AName: FNameStr);
begin
  Inherited Init;
{
  Name := NewStr(AName);
  GetMem(Header, SizeOf(TDBFHeader));
}
  Name := NewStrUMB(AName);
  GetMemUMB(Header, SizeOf(TDBFHeader));
  Fields := New(PFieldList, Init(8, 8));
  InitDBF(stOpenRead);
  ReadFields;
end;

destructor TDataBase.Done;
begin
  DoneDBF;
  Dispose(Fields, Done);
{
  FreeMem(Header, SizeOf(TDBFHeader));
  DisposeStr(Name);
}
  FreeMemUMB(Header, SizeOf(TDBFHeader));
  DisposeStrUMB(Name);
end;

procedure TDataBase.AddRecord(var Rec);
begin
  TruncateToLast;
  if Options and dbXLATOUT <> 0 then ConvertRecord(dcXLATOUT, Rec);
  if (DBImpExpOptions and dbConvertDates <> 0) and
     (Options and dbHasDates <> 0) then ConvertDates(dcDATEOUT, Rec);
  DBF^.Write(Rec, Header^.RecordLen - ExtraRecordLen);
  WriteEndingChar;
  Inc(Header^.NumRecords);
end;

procedure TDataBase.ConvertDates(AMode: Byte; var Rec);
var
  R: Array[0..1] of Char absolute Rec;
  I: Integer;
  Offset, Shift: Word;
  P: PFieldRec;
  S: String[10];
begin
  Shift := 0;
  for I := 0 to Fields^.Count - 1 do
  begin
    P := Fields^.At(I);
    if (P <> nil) and (P^.Iden = 'D') and (P^.Len in [8, 10]) then
    begin
      Offset := GetFieldOfs(I);
      if AMode = dcDATEIN then
      begin
	S[0] := #8;
	Move(R[Offset], S[1], 8);
	Move(R[Offset], R[Offset + 2], Header^.RecordLen - Offset - 2);
      end
      else
      begin
	Dec(Offset, Shift);
	Inc(Shift, 2);
	S[0] := #10;
	Move(R[Offset], S[1], 10);
	Move(R[Offset + 2], R[Offset], Header^.RecordLen - Offset - 2);
      end;
      ConvertDateStr(S, AMode);
      Move(S[1], R[Offset], Length(S));
    end;
  end;
end;

procedure TDataBase.ConvertFields(AMode: Byte);
var
  B: Byte;
  I: Integer;
  P: PFieldRec;
begin
  for I := 0 to Fields^.Count - 1 do
  begin
    P := Fields^.At(I);
    for B := 1 to SizeOf(P^.Name) do
      if AMode = dcXLATIN then P^.Name[B] := InXLATTable[P^.Name[B]]
      else P^.Name[B] := OutXLATTable[P^.Name[B]];
  end;
end;

procedure TDataBase.ConvertRecord(AMode: Byte; var Rec);
var
  W: Word;
  R: Array[0..1] of Char absolute Rec;
begin
  for W := 1 to Header^.RecordLen - 1 do
    if AMode = dcXLATIN then R[W] := InXLATTable[R[W]]
    else R[W] := OutXLATTable[R[W]];
end;

procedure TDataBase.DeleteRecord(APos: Longint);
begin
  TruncateToLast;
  DeleteBlock(DBF, APos, Header^.RecordLen - ExtraRecordLen);
  WriteEndingChar;
  Dec(Header^.NumRecords);
end;

procedure TDataBase.DoneDBF;
{
var
  F: lFile;
}
begin
  if DBF = nil then Exit;
  if OpenMode <> stOpenRead then UpdateHeader;
  Dispose(DBF, Done);
  DBF := nil;
  if OpenMode <> stOpenRead then GetFileTime(Name^, Time);
{
  begin
    lAssignFile(F, Name^);
    lResetReadOnly(F, 1);
    GetFTime(F.F, Time);
    Close(F.F);
    InOutRes := 0;
  end;
}
end;

function TDataBase.GetFieldLen(P: PFieldRec): Word;
var
  W: Word;
begin
  if (TPString.Upcase(P^.Iden) = 'C') and (P^.Dec <> 0) then
    Move(P^.Len, W, SizeOf(Word))
  else W := P^.Len;
  GetFieldLen := W;
end;

function TDataBase.GetFieldNum(AOffset: Word): Byte;
var
  Offset: Word;
  I: Integer;
  P: PFieldRec;
begin
  Offset := 1;
  I := 0;
  while I < Fields^.Count do
  begin
    P := Fields^.At(I);
    Inc(Offset, GetFieldLen(P));
    if Offset > AOffset then
    begin
      GetFieldNum := I;
      Exit;
    end;
    Inc(I);
  end;
  GetFieldNum := 0;
end;

function TDataBase.GetFieldOfs(AField: Byte): Word;
var
  Offset: Word;
  I: Integer;
  P: PFieldRec;
begin
  Offset := 1;
  I := 0;
  while I <= AField do
  begin
    P := Fields^.At(I);
    if P = nil then
    begin
      GetFieldOfs := 1;
      Exit;
    end;
    if I = AField then
    begin
      GetFieldOfs := Offset;
      Exit;
    end;
    Inc(I);
    Inc(Offset, GetFieldLen(P));
  end;
end;

function TDataBase.GetFieldStr(AField: Byte; var Rec): String;
var
  Offset, Len: Word;
  P: PFieldRec;
  S: String;
begin
  Offset := GetFieldOfs(AField);
  P := Fields^.At(AField);
  if P = nil then S := ''
  else
  begin
    Len := GetFieldLen(P);
    if Len > $FF then Len := $FF;
    Move(TByteArray(Rec)[Offset], S[1], Len);
    S[0] := Char(Len);
  end;
  GetFieldStr := S;
end;

procedure TDataBase.InitDBF(AMode: Word);
begin
  DoneDBF;
  OpenMode := AMode;
  DBF := New(PDosStream, Init(Name^, OpenMode));
{  GetFTime(PDosStream(DBF)^.Handle, Time);}
  GetFileTime(Name^, Time);
  ReadHeader;
end;

procedure TDataBase.InsertRecord(APos: Longint; var Rec);
begin
  TruncateToLast;
  if Options and dbXLATOUT <> 0 then ConvertRecord(dcXLATOUT, Rec);
  if (DBImpExpOptions and dbConvertDates <> 0) and
     (Options and dbHasDates <> 0) then ConvertDates(dcDATEOUT, Rec);
  InsertBlock(DBF, APos, Header^.RecordLen - ExtraRecordLen, Rec);
  WriteEndingChar;
  Inc(Header^.NumRecords);
end;

procedure TDataBase.ReadFields;
var
  B, Z: Byte;
  Len: Word;
  I, NumFields: Integer;
  P: PFieldRec;
begin
  NumFields := (Header^.HeaderLen - SizeOf(TDBFHeader) - 1) div
    SizeOf(TFieldRec);
  if (NumFields < 1) or (NumFields >= $FF) then Exit;
  Len := 1;
  ExtraRecordLen := 0;
  for I := 0 to NumFields - 1 do
  begin
{    GetMem(P, SizeOf(TFieldRec));}
    GetMemUMB(P, SizeOf(TFieldRec));
    DBF^.Read(P^, SizeOf(TFieldRec));
    Z := 0;
    for B := 1 to SizeOf(P^.Name) do
      if (Z <> 0) or (P^.Name[B] = #0) then
      begin
        Z := B;
        P^.Name[B] := #0;
      end;
    if (P^.Iden = 'D') and (P^.Len = 8) then
    begin
      Options := Options or dbHasDates;
      if DBImpExpOptions and dbConvertDates <> 0 then
      begin
	P^.Len := 10;
	Inc(Header^.RecordLen, 2);
        Inc(ExtraRecordLen, 2);
      end;
    end;
    Fields^.Insert(P);
    Inc(Len, GetFieldLen(P));
  end;
  if DBF^.Status <> stOk then Fields^.FreeAll
  else if Len <> Header^.RecordLen then
  begin
    Len := 1;
    for I := 0 to NumFields - 1 do
    begin
      P := Fields^.At(I);
      if (TPString.Upcase(P^.Iden) = 'C') and (P^.Dec <> 0) then
        P^.Dec := 0;
      Inc(Len, GetFieldLen(P));
    end;
    if Len <> Header^.RecordLen then Fields^.FreeAll;
  end;
end;

procedure TDataBase.ReadHeader;
begin
  DBF^.Read(Header^, SizeOf(TDBFHeader));
  if (Header^.RecordLen <= 1) or (Header^.RecordLen > $2000) then
    DBF^.Status := stReadError
  else Inc(Header^.RecordLen, ExtraRecordLen);
end;

procedure TDataBase.ReadRecord(APos: Longint; var Rec);
begin
  DBF^.Seek(APos);
  DBF^.Read(Rec, Header^.RecordLen - ExtraRecordLen);
  if Options and dbXLATIN <> 0 then ConvertRecord(dcXLATIN, Rec);
  if (DBImpExpOptions and dbConvertDates <> 0) and
     (Options and dbHasDates <> 0) then ConvertDates(dcDATEIN, Rec);
end;

procedure TDataBase.SetCurTime;
var
  Y, M, D, W: Word;
begin
  GetDate(Y, M, D, W);
  if Y >= 2000 then Dec(Y, 2000) else Dec(Y, 1900);
  with Header^ do
  begin
    Year := Y;
    Month := M;
    Day := D;
  end;
end;

procedure TDataBase.SetXLATTable(const AName: FNameStr; AMode: Byte);
var
  C: Boolean;
begin
  if AName = '' then Exit;
  if AMode = dcXLATIN then
    if ReadConvertTable(InXLATTable, AName, C) then
      Options := Options or dbXLATIN
    else Options := Options and not dbXLATIN
  else
    if ReadConvertTable(OutXLATTable, AName, C) then
      Options := Options or dbXLATOUT
    else Options := Options and not dbXLATOUT;
end;

procedure TDataBase.TruncateToLast;
begin
  DBF^.Seek(Header^.HeaderLen +
    Header^.NumRecords * (Header^.RecordLen - ExtraRecordLen));
  DBF^.Truncate;
end;

procedure TDataBase.UpdateHeader;
begin
  SetCurTime;
  DBF^.Seek(0);
  Dec(Header^.RecordLen, ExtraRecordLen);
  DBF^.Write(Header^, SizeOf(TDBFHeader));
  Inc(Header^.RecordLen, ExtraRecordLen);
end;

function TDataBase.Valid: Boolean;
begin
  Valid := (DBF^.Status = stOk) and (Fields^.Count <> 0) and
    (DBF^.GetSize >= Header^.HeaderLen +
      Header^.NumRecords * (Header^.RecordLen - ExtraRecordLen));
end;

function TDataBase.ValidChar(C: Char; AField: Byte): Boolean;
var
  P: PFieldRec;
begin
  P := Fields^.At(AField);
  if P = nil then ValidChar := False
  else if C in ['0'..'9'] then ValidChar := True
  else if P^.Iden = 'D' then ValidChar :=
    (DBImpExpOptions and dbConvertDates <> 0) and
    (C = DateSeparator)
  else if P^.Iden in ['F', 'N'] then ValidChar :=
    C in ['-', '.', 'E', 'e']
  else ValidChar := True;
end;

function TDataBase.ValidRecord(var Field: Byte; var Code: Integer;
  RawDate: Boolean; var Rec): Boolean;
var
  Mode: Byte;
  I, Len: Integer;
  P: PFieldRec;
  E: Extended;
  S: String;
begin
  for I := 0 to Fields^.Count - 1 do
  begin
    Field := I;
    P := Fields^.At(I);
    if P^.Iden in ['D', 'F', 'N'] then
    begin
      S := GetFieldStr(I, Rec);
      Len := Length(S);
      LeadTrim(S);
      Len := Len - Length(S);
      TrailTrim(S);
      if S <> '' then
      begin
	if P^.Iden = 'D' then
	begin
	  if not RawDate and
	    (DBImpExpOptions and dbConvertDates <> 0) then
	      Mode := dcDATEOUT
	  else Mode := dcDATEIN;
	  if not ConvertDateStr(S, Mode) then
	  begin
	    Code := 1;
	    ValidRecord := False;
	    Exit;
	  end;
	end
	else
	begin
	  Val(S, E, Code);
	  if Code <> 0 then
	  begin
            Inc(Code, Len);
            ValidRecord := False;
            Exit;
          end;
        end;
      end;
    end;
  end;
  ValidRecord := True;
end;

procedure TDataBase.WriteEndingChar;
var
  B: Byte;
begin
  DBF^.Seek(DBF^.GetSize);
  B := $1A;
  DBF^.Write(B, SizeOf(Byte));
end;

procedure TDataBase.WriteRecord(APos: Longint; var Rec);
begin
  if Options and dbXLATOUT <> 0 then ConvertRecord(dcXLATOUT, Rec);
  if (DBImpExpOptions and dbConvertDates <> 0) and
     (Options and dbHasDates <> 0) then ConvertDates(dcDATEOUT, Rec);
  DBF^.Seek(APos);
  DBF^.Write(Rec, Header^.RecordLen - ExtraRecordLen);
end;

procedure TDataBase.Zap;
begin
  DBF^.Seek(Header^.HeaderLen);
  DBF^.Truncate;
  WriteEndingChar;
  Header^.NumRecords := 0;
end;

end.