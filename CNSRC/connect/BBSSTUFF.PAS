{$I-,F+,O+,X+}
unit BBSStuff;

interface

uses Objects, LFN;

const
  DescrDataSize = $1000;

type
  PDescrData = ^TDescrData;
  TDescrData = record
    Len: Word;
    Data: Array[1..DescrDataSize] of Char;
  end;

function BBSWrapPos: Byte;
procedure FindDescription(var F: File; const Name: FNameStr;
  Data: PDescrData; var Pos: Longint; var Len: Word; var CRLF: Word);
function OpenBBSFile(const AName: FNameStr;
  var F: lFile; ReadOnly: Boolean): Boolean;
procedure CopyDescription(const FromName, ShortName, ToName: FNameStr);
procedure RenameDescription(const FromName, ShortName, ToName: FNameStr);
procedure DeleteDescription(const FromName, ShortName: FNameStr);

implementation

uses Dos, Drivers, Memory, App, DirPrim, DosTools, TPString, Defaults;

function BBSWrapPos: Byte;
var
  B: Byte;
begin
  if BBSSpaces <> 0 then B := BBSSpaces
  else B := DefBBSSpaces;
  Inc(B, 12);
  BBSWrapPos := B;
end;

procedure AllocBuffer(var Buffer: PByteArray; var BufSize: Word);
begin
  BufSize := $4000;
  repeat
    if BufSize <= $400 then GetMem(Buffer, BufSize)
    else Buffer := MemAlloc(BufSize);
    if Buffer <> nil then Exit;
    BufSize := BufSize shr 1;
  until False;
end;

procedure FindDescription(var F: File; const Name: FNameStr;
  Data: PDescrData; var Pos: Longint; var Len: Word; var CRLF: Word);
var
  BufSize, BufPos, BytesRead, BytesSearched: Word;
  FPos: Longint;
  Buffer: PByteArray;
  S: FNameStr;
  BT: BTable;

procedure DetabBuffer;
begin
  BufPos := 0;
  repeat
    if BufPos >= BytesRead then Exit;
    if Buffer^[BufPos] = 9 then Buffer^[BufPos] := 32;
    Inc(BufPos);
  until False;
end;

procedure SearchForEmptyLine;
var
  Eol: Boolean;
  SpacePos: Word;
begin
  BufPos := 0;
  SpacePos := 0;
  Eol := False;
  repeat
    if BufPos >= BytesRead then Exit;
    if Buffer^[BufPos] = 9 then Buffer^[BufPos] := 32;
    if Buffer^[BufPos] in [10, 13] then
    begin
      Eol := True;
      if SpacePos <> 0 then
      begin
	Buffer^[SpacePos] := $FF;
	Exit;
      end;
    end
    else if Buffer^[BufPos] = 32 then
      if Eol and (SpacePos = 0) then SpacePos := BufPos else
    else if Eol then
    begin
      SpacePos := 0;
      Eol := False;
    end;
    Inc(BufPos);
  until False;
end;

procedure ScanBuffer;
begin
  if FPos = 0 then
  begin
    BufPos := 0;
    while (BufPos < BytesRead) and (Buffer^[BufPos] <> 10) do Inc(BufPos);
    if (BufPos < BytesRead) and (Buffer^[BufPos] = 10) and
       (Buffer^[BufPos - 1] <> 13) then CRLF := $0A;
  end;
  BufPos := 0;
  repeat
    BytesSearched :=
      BMSearchUC(Buffer^[BufPos], BytesRead - BufPos, BT, S);
    if (BytesSearched = 0) or (BytesSearched = $FFFF) or
       (Buffer^[BufPos + BytesSearched - 1] in [10, 13]) then Exit;
    Inc(BufPos, BytesSearched + 1);
    BytesSearched := $FFFF;
  until BufPos >= BytesRead;
end;

procedure FormatData;
const
  WrapLen = 255;
var
  WrapPos, EolLen: Byte;
  W, MovePos, Limit, SpacePos: Word;
begin
  if (Data^.Len <> 0) and (Data^.Data[Data^.Len] = #32) then Dec(Data^.Len);
  WrapPos := BBSWrapPos;
  Limit := WrapLen - WrapPos;
  if Data^.Len <= Limit then Exit;
  EolLen := Byte(CRLF = $0A0D) + 1;
  W := 1;
  repeat
    SpacePos := 0;
    while W <= Limit do
    begin
      if Data^.Data[W] = #32 then SpacePos := W;
      Inc(W);
    end;
    if SpacePos = 0 then Exit;
    MovePos := SpacePos + EolLen;
    Move(Data^.Data[SpacePos], Data^.Data[MovePos],
      DescrDataSize - MovePos + 1);
    Move(CRLF, Data^.Data[SpacePos], EolLen);
    Inc(Data^.Len, EolLen);
    if Data^.Len > DescrDataSize then Data^.Len := DescrDataSize;
    Limit := MovePos + WrapLen;
    W := MovePos + 1;
  until Limit >= Data^.Len;
end;

procedure ScanToEnd;
var
  C: Char;
begin
  if Data <> nil then Data^.Len := 0;
  BufPos := 0;
  while (BufPos < BytesRead) and (Buffer^[BufPos] <> 32) do Inc(BufPos);
  while (BufPos < BytesRead) and (Buffer^[BufPos] =  32) do Inc(BufPos);
  if BufPos < BytesRead then
  repeat
    if (Data <> nil) and (Data^.Len < DescrDataSize) then
    begin
      C := Char(Buffer^[BufPos]);
      if (BBSOptions and bbFormatData <> 0) and
	 (C in [#10, #13]) then C := #32;
      if (BBSOptions and bbFormatData = 0) or
	 (C <> #32) or (Data^.Len = 0) or
	 (Data^.Data[Data^.Len] <> #32) then
      begin
	Inc(Data^.Len);
	Data^.Data[Data^.Len] := C;
      end;
    end;
    Inc(BufPos);
    if BufPos >= BytesRead then Break;
    if (CRLF = $0A0D) and
       (Buffer^[BufPos] = 10) and
       (Buffer^[BufPos - 1] <> 13) then CRLF := $0A;
    if (Buffer^[BufPos] in [10, 13]) and
       (Buffer^[BufPos - 1] = 10) then Break;
    if not (Buffer^[BufPos] in [10, 13, 32]) and
      (Buffer^[BufPos - 1] in [10, 13]) then Break;
  until False;
  if (Data <> nil) and (BBSOptions and bbFormatData <> 0) then FormatData;
  Len := BufPos;
end;

begin
  Pos := -1;
  CRLF := $0A0D;
  if Name = '' then Exit;
  AllocBuffer(Buffer, BufSize);
  S := Name + ' ';
  BMMakeTable(S, BT);
  FPos := 0;
  repeat
    Seek(F, FPos);
    BlockRead(F, Buffer^, BufSize, BytesRead);
    InOutRes := 0;
    if BytesRead <> 0 then
    begin
      DetabBuffer;
      ScanBuffer;
      if BytesSearched <> $FFFF then
      begin
	Pos := FPos + BufPos + BytesSearched;
	Seek(F, Pos);
	BlockRead(F, Buffer^, BufSize, BytesRead);
	InOutRes := 0;
	SearchForEmptyLine;
	ScanToEnd;
	Break;
      end;
      Inc(FPos, BytesRead - 255);
    end;
  until BytesRead <> BufSize;
  FreeMem(Buffer, BufSize);
end;

procedure UpdateStatusLine(const AName: FNameStr);
begin
  DrawStatusLine(Concat(
    'Updating the description file ', TrimmedName(AName, 38), '.'));
end;

function OpenBBSFile(const AName: FNameStr;
  var F: lFile; ReadOnly: Boolean): Boolean;
begin
  CancelSysErrors := False;
  lAssignFile(F, AName);
  if ReadOnly then lResetReadOnly(F, 1)
  else lResetFile(F, 1);
  if IOResult <> 0 then OpenBBSFile := False
  else if IsDevice(FileRec(F.F).Handle) then
  begin
    Close(F.F);
    InOutRes := 0;
    OpenBBSFile := False;
  end
  else OpenBBSFile := not CancelSysErrors;
end;

procedure ResizeFile(var F: File; From, Count: Longint);
var
  BufSize, BytesRead: Word;
  FromPos, ToPos: Longint;
  Buffer: PByteArray;
begin
  if Count = 0 then Exit;
  AllocBuffer(Buffer, BufSize);
  if Count < 0 then
  begin
    FromPos := From - Count;
    ToPos := From;
    repeat
      Seek(F, FromPos);
      BlockRead(F, Buffer^, BufSize, BytesRead);
      Inc(FromPos, BytesRead);
      Seek(F, ToPos);
      BlockWrite(F, Buffer^, BytesRead);
      Inc(ToPos, BytesRead);
    until BytesRead <> BufSize;
    Truncate(F);
  end
  else
  begin
    FromPos := FileSize(F);
    repeat
      if FromPos - BufSize <= From then
	BytesRead := FromPos - From
      else BytesRead := BufSize;
      Dec(FromPos, BytesRead);
      ToPos := FromPos + Count;
      Seek(F, FromPos);
      BlockRead(F, Buffer^, BytesRead);
      Seek(F, ToPos);
      BlockWrite(F, Buffer^, BytesRead);
    until (FromPos <= From) or (IOResult <> 0);
  end;
  FreeMem(Buffer, BufSize);
end;

procedure CopyDescription(const FromName, ShortName, ToName: FNameStr);
var
  Long: Boolean;
  B: Byte;
  Len, CRLF: Word;
  Pos: Longint;
  Data: PDescrData;
  DName, LName: FNameStr;
  F: lFile;
label
  FClose, Quit;
begin
  if MaxAvail < $2000 then
  begin
    Application^.OutOfMemory;
    Exit;
  end;
  DName := AddedSlash(JustPathName(FromName));
  SetFirstFoundName(BBSNames, DName);
  if (DName = '') or not OpenBBSFile(DName, F, True) then Exit;
  GetMem(Data, SizeOf(TDescrData));
  if ShortName = '' then LName := FromName
  else LName := ShortName;
  Long := False;
  FindDescription(F.F, StUpcase(JustFileName(LName)),
    Data, Pos, Len, CRLF);
  if (Pos = -1) and (CompUCString(FromName, LName) <> Equal) then
  begin
    FindDescription(F.F, StUpcase(JustFileName(FromName)),
      Data, Pos, Len, CRLF);
    Long := True;
  end;
  if Pos = -1 then Goto FClose;
  Close(F.F);
  InOutRes := 0;
  DName := AddedSlash(JustPathName(ToName));
  SetFirstFoundName(BBSNames, DName);
  if DName = '' then Exit;
  UpdateStatusLine(DName);
  if OpenBBSFile(DName, F, False) then
  begin
    lGetShortFileName(ToName, LName);
    FindDescription(F.F, StUpcase(JustFileName(LName)),
      nil, Pos, Len, CRLF);
    if Pos <> -1 then Goto FClose;
    if CompUCString(ToName, LName) <> Equal then
    begin
      FindDescription(F.F, StUpcase(JustFileName(ToName)),
	nil, Pos, Len, CRLF);
      if Pos <> -1 then Goto FClose;
    end;
    Pos := FileSize(F.F);
    if Pos <> 0 then
    begin
      Seek(F.F, Pos - 1);
      BlockRead(F.F, B, 1);
      if not (B in [$0A, $0D]) then
	BlockWrite(F.F, CRLF, SizeOf(Word) - Byte(CRLF = $0A));
    end;
  end
  else if CancelSysErrors then Goto Quit
  else
  begin
    lRewriteFile(F, 1);
    if IOResult <> 0 then Goto Quit
  end;
  if Long then DName := ToName
  else lGetShortFileName(ToName, DName);
  DName := JustFileName(ToName);
  if BBSSpaces = 0 then B := 0
  else B := BBSWrapPos;
  if B <= Length(DName) then B := Length(DName) + 1;
  PadSt(DName, B);
  BlockWrite(F.F, DName[1], Length(DName));
  BlockWrite(F.F, Data^.Data, Data^.Len);
  BlockWrite(F.F, CRLF, SizeOf(Word) - Byte(CRLF = $0A));
FClose:
  Close(F.F);
  InOutRes := 0;
Quit:
  FreeMem(Data, SizeOf(TDescrData));
end;

procedure RenameDescription(const FromName, ShortName, ToName: FNameStr);
var
  Long: Boolean;
  C: Char;
  Len, CRLF: Word;
  Pos, Count: Longint;
  DName, LName: FNameStr;
  F: lFile;
begin
  DName := AddedSlash(JustPathName(FromName));
  SetFirstFoundName(BBSNames, DName);
  if (DName = '') or not OpenBBSFile(DName, F, False) then Exit;
  UpdateStatusLine(DName);
  if ShortName = '' then LName := FromName
  else LName := ShortName;
  DName := StUpcase(JustFileName(LName));
  Long := False;
  FindDescription(F.F, DName, nil, Pos, Len, CRLF);
  if (Pos = -1) and (CompUCString(FromName, LName) <> Equal) then
  begin
    DName := StUpcase(JustFileName(FromName));
    FindDescription(F.F, DName, nil, Pos, Len, CRLF);
    Long := True;
  end;
  if Pos <> -1 then
  begin
    if Long then LName := ToName
    else lGetShortFileName(ToName, LName);
    LName := JustFileName(LName);
    if (BBSSpaces = 0) or (Length(LName) > 12) then
      Count := Length(LName) - Length(DName)
    else
    begin
      Seek(F.F, Pos + Length(DName));
      Len := 0;
      repeat
	C := #0;
	BlockRead(F.F, C, SizeOf(Char));
	if C in [#9, #32] then Inc(Len)
	else Break;
      until False;
      PadSt(LName, 12 + BBSSpaces);
      Count := 12 + BBSSpaces - Longint(Length(DName) + Len);
    end;
    InOutRes := 0;
    ResizeFile(F.F, Pos, Count);
    Seek(F.F, Pos);
    BlockWrite(F.F, LName[1], Length(LName));
  end;
  Close(F.F);
  InOutRes := 0;
end;

procedure DeleteDescription(const FromName, ShortName: FNameStr);
var
  Len, CRLF: Word;
  Pos: Longint;
  DName, LName: FNameStr;
  F: lFile;
begin
  DName := AddedSlash(JustPathName(FromName));
  SetFirstFoundName(BBSNames, DName);
  if (DName = '') or not OpenBBSFile(DName, F, False) then Exit;
  UpdateStatusLine(DName);
  if ShortName = '' then LName := FromName
  else LName := ShortName;
  FindDescription(F.F, StUpcase(JustFileName(LName)),
    nil, Pos, Len, CRLF);
  if (Pos = -1) and (CompUCString(FromName, LName) <> Equal) then
    FindDescription(F.F, StUpcase(JustFileName(FromName)),
      nil, Pos, Len, CRLF);
  if Pos <> -1 then
  begin
    ResizeFile(F.F, Pos, -Longint(Len));
    Pos := FileSize(F.F);
    Close(F.F);
    if Pos <= 2 then lEraseFile(F);
  end
  else Close(F.F);
  InOutRes := 0;
end;

end.