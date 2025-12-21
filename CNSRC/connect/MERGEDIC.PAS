{$A+,B-,D-,E+,F+,G-,I-,L-,N+,O+,P-,Q-,R-,S-,T-,V-,X+,Y-}
{$M 16384,0,655360}

uses Dos, Crt, Objects, BigColl, TPString;

type
  PCRCList = ^TCRCList;
  TCRCList = object(TBigCollection)
    Overflow: Boolean;
    function Compare(Item1, Item2: Pointer): Integer; virtual;
    procedure Error(Code: Integer); virtual;
    procedure FreeItem(Item: Pointer); virtual;
  end;

function TCRCList.Compare(Item1, Item2: Pointer): Integer;
begin
  if Item1 = Item2 then Compare := 0
  else if (LongRec(Item1).Hi < LongRec(Item2).Hi) or
    ((LongRec(Item1).Hi = LongRec(Item2).Hi) and
     (LongRec(Item1).Lo < LongRec(Item2).Lo)) then Compare := -1
  else Compare := 1;
end;

procedure TCRCList.Error(Code: Integer);
begin
  if Code = bcErrOutOfMemory then Overflow := True;
end;

procedure TCRCList.FreeItem(Item: Pointer);
begin
end;

const
  Header = 'CONNECT Spell Checker CRC32 Dictionary'#26#0;

procedure InitCRCStream(const AName: FNameStr; var Stream: PBufStream);
var
  S: String[40];
begin
  Stream := New(PBufStream, Init(AName, stOpenRead, $4000));
  S[0] := #40;
  Stream^.Read(S[1], 40);
  if S <> Header then Stream^.Status := stError;
end;

procedure CreateCRCStream(const AName: FNameStr; var Stream: PBufStream);
var
  S: String[40];
begin
  Stream := New(PBufStream, Init(AName, stCreate, $4000));
  S := Header;
  Stream^.Write(S[1], 40);
end;

var
  Abort: Boolean;
  Percent, OldPercent: Byte;
  I: Integer;
  L, P: Longint;
  Stream: PBufStream;
  R, RSize: Real;
  List: TCRCList;
  Name: String[12];
  S: String[79];
begin
  Write(
    'Utility for merging CONNECT Spell Checker CRC32 Dictionaries'#13#10);
  Write('Copyright (c) 1996 KHEMZ Inc.');
  Write('  Portions copyright (c) TurboPower Software.'#13#10);
  Write(#13#10);
  if ParamCount = 0 then
  begin
    Write(
      '  Syntax:  MERGEDIC <DIC file 1> <DIC file 2> ... <DIC file n>'#13#10);
    Write(#13#10);
    Write('This program reads CRC32s from all input files into'#13#10);
    Write('a Sorted Big Collection (c) TurboPower Software.'#13#10);
    Write('Finally it creates a new CONNECT.DIC file'#13#10);
    Write('containing all CRC32s in sorted order.'#13#10);
    Write(#13#10);
    Halt(0);
  end;
  List.Init(True, False);
  Abort := False;
  for I := 1 to ParamCount do
  begin
    S := FExpand(ParamStr(I));
    Name := Pad(JustFileName(S), 12);
    Write(Name);
    InitCRCStream(S, Stream);
    if Stream^.Status <> stOk then Write(
      ' - not a CONNECT Spell Checker CRC32 Dictionary. Skipping...'#13#10)
    else
    begin
      Write(#13);
      RSize := Stream^.GetSize;
      P := 41;
      OldPercent := $FF;
      repeat
	Stream^.Read(L, SizeOf(Longint));
	if Stream^.Status <> stOk then Break;
	List.Insert(Pointer(L));
	if List.Overflow then
	begin
	  Write(#13#10'Big Collection overflow error. Reading aborted.');
	  Write('MemAvail: ', MemAvail, ', MaxAvail: ', MaxAvail);
	  I := ParamCount;
	  Break;
	end;
	Inc(P, SizeOf(Longint));
	R := P;
	R := (R / RSize) * 100;
	Percent := Trunc(R);
	if Percent > 100 then Percent := 100;
	if Percent <> OldPercent then
	begin
	  OldPercent := Percent;
	  Write(Name, ' : ', Percent, '%'#13);
	  if KeyPressed and (ReadKey = #27) then
	  begin
	    Abort := True;
	    I := ParamCount;
	    Break;
	  end;
	end;
      until False;
      Write(#13#10);
    end;
    Dispose(Stream, Done);
  end;
  if not Abort then
  begin
    Write(#13#10);
    Write('Writing sorted CRC32 list to CONNECT.DIC.'#13#10);
    S := FExpand('CONNECT.DIC');
    CreateCRCStream(S, Stream);
    for L := 0 to List.bcCount - 1 do
    begin
      P := Longint(List.At(L));
      Stream^.Write(P, SizeOf(Longint));
      if Stream^.Status <> stOk then
      begin
	Write('Error writing CRC32s to CONNECT.DIC.'#13#10);
      end;
    end;
    Dispose(Stream, Done);
  end;
  List.Done;
end.