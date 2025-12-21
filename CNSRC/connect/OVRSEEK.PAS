uses Objects, TPString;

procedure SeekSign(S: PDosStream; Buffer: PByteArray; BufSize: Word;
  const Sign: String; var Pos: Longint);
var
  BT: BTable;
  FoundPos: Word;
begin
  BMMakeTable(Sign, BT);
  Pos := 0;
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

var
  Size: Word;
  L, N, P: Longint;
  S: PDosStream;
  B: PByteArray;
begin
  S := New(PDosStream, Init(ParamStr(1), stOpen));
  if S^.Status <> stOk then Halt(1);
  Size := $8000;
  GetMem(B, Size);
  SeekSign(S, B, Size, 'OVOP', L);
  if L <> 0 then
  begin
    S^.Seek(L);
    S^.Read(N, SizeOf(Longint));
    if N = $504F564F then
    begin
      Writeln('OVOP - found at address ', HexL(L), '.');
      SeekSign(S, B, Size, 'OVPS', P);
      if P <> 0 then
      begin
	S^.Seek(P);
	S^.Read(N, SizeOf(Longint));
	if N = $5350564F then
	begin
	  S^.Write(L, SizeOf(Longint));
	  Writeln('OVPS written at address ', HexL(P + SizeOf(Longint)), '.');
	end;
      end;
    end;
  end;
  FreeMem(B, Size);
  Dispose(S, Done);
end.
