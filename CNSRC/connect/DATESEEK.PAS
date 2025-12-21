uses Dos, Objects, Drivers, TPString;

procedure SeekSign(S: PDosStream; Buffer: PByteArray; BufSize: Word;
  const Sign: String; var Pos: Longint);
var
  BT: BTable;
  FoundPos: Word;
begin
  BMMakeTable(Sign, BT);
  Pos := 0; {S^.GetSize - $FFFF;}
  with S^ do
  repeat
    Seek(Pos);
    Read(Buffer^, BufSize);
    if Status <> stOk then Exit; { Do not search last portion of the stream }
    FoundPos := BMSearch(Buffer^, BufSize, BT, Sign);
    if FoundPos <> $FFFF then
    begin
      Inc(Pos, FoundPos);
      Exit;
    end;
    Inc(Pos, BufSize);
  until False;
end;

const
  DateStr = 'Compiled on ';
var
  Size: Word;
  DW, Hund: Word;
  L, T: Longint;
  S: PDosStream;
  B: PByteArray;
  DT: DateTime;
  SS: String;
begin
  S := New(PDosStream, Init(ParamStr(1), stOpen));
  if S^.Status <> stOk then Halt(1);
  Size := $8000;
  GetMem(B, Size);
  SeekSign(S, B, Size, DateStr, L);
  if L <> 0 then
  begin
    S^.Seek(L);
    SS[0] := Char(Length(DateStr));
    S^.Read(SS[1], Length(DateStr));
    if SS = DateStr then
    begin
      Writeln('Compilation date - found at address ', HexL(L), '.');
      with DT do
      begin
	GetDate(Year, Month, Day, DW);
	GetTime(Hour, Min, Sec, Hund);
      end;
      PackTime(DT, T);
      S^.Write(T, SizeOf(Longint));
      Writeln('Compilation date written at address ',
	HexL(L + Length(DateStr)), '.');
    end;
  end;
  FreeMem(B, Size);
  Dispose(S, Done);
end.
