{$A+,B-,D-,E+,F+,G-,I-,L-,N+,O+,P-,Q-,R-,S-,T-,V-,X+,Y-}
{$M 4096,0,655360}

uses Dos, Objects, HelpFile, TPString;

type
  PDeHelpFile = ^TDeHelpFile;
  TDeHelpFile = object(TObject)
    Name: PString;
    Stream: PStream;
    Index: PHelpIndex;
    IndexPos: Longint;
    constructor	Init(const AName: FNameStr);
    destructor Done; virtual;
    procedure InitHelpFile(const AName: FNameStr);
    procedure DoneHelpFile;
    function GetTopic(I: Integer): PHelpTopic;
  end;

const
  RHelpTopic: TStreamRec = (
    ObjType: 10000;
    VmtLink: Ofs(TypeOf(THelpTopic)^);
    Load:    Addr(THelpTopic.Load);
    Store:   nil
  );
  RHelpIndex: TStreamRec = (
    ObjType: 10001;
    VmtLink: Ofs(TypeOf(THelpIndex)^);
    Load:    Addr(THelpIndex.Load);
    Store:   nil
  );

constructor TDeHelpFile.Init(const AName: FNameStr);
begin
  TObject.Init;
  InitHelpFile(AName);
end;

destructor TDeHelpFile.Done;
begin
  DoneHelpFile;
  TObject.Done;
end;

procedure TDeHelpFile.InitHelpFile(const AName: FNameStr);
const
  MagicHeader =	$46484246; {'FBHF'}
var
  Magic: Longint;
begin
  Name := NewStr(AName);
  Stream := New(PDosStream, Init(Name^, stOpenRead));
  Stream^.Read(Magic, SizeOf(Longint));
  if Magic <> MagicHeader then Stream^.Status := stReadError
  else with Stream^ do
  begin
    Seek(8);
    Read(IndexPos, SizeOf(IndexPos));
    Seek(IndexPos);
    Index := PHelpIndex(Get);
  end;
end;

procedure TDeHelpFile.DoneHelpFile;
begin
  if Index <> nil then
  begin
    Dispose(Index, Done);
    Index := nil;
  end;
  Dispose(Stream, Done);
  DisposeStr(Name);
end;

function TDeHelpFile.GetTopic(I: Integer): PHelpTopic;
var
  Code: Integer;
  Pos: Longint;
  P: PHelpTopic;
begin
  Pos := Index^.Position(I);
  if Pos <= 0 then P := nil
  else
  begin
    Stream^.Seek(Pos);
    P := PHelpTopic(Stream^.Get);
    Code := Stream^.Status;
    Stream^.Reset;
  end;
  if Code <> stOk then P := nil;
  GetTopic := P;
end;

procedure DecompileHelp(const InName, OutName: FNameStr; Width: Word);
var
  W, Count: Word;
  L: Longint;
  H: PDeHelpFile;
  P: PHelpTopic;
  TS: String[7];
  F: Text;

procedure ProcessTopic;
var
  I, Offset: Integer;
  SP: PParagraph;
  S: String;

function GetTopicNumStr(Num: Word): String;
const
  hcRefFile  = $F700;
  hcColor1   = $F800;
  hcColor2   = $F801;
  hcColor3   = $F802;
  hcColor4   = $F803;
  hcColor5   = $F804;
  hcColorX   = $F805;
  hcColor0   = $F900;
  hcColorFF  = $F9FF;
var
  S: String;
begin
  if Num = hcRefFile then S := 'OtherHelpFile'
  else if (Num >= hcColor1) and (Num <= hcColor5) then
    S := 'Color_' + Char(Num - hcColor1 + $31)
  else if Num = hcColorX then S := 'Color_X'
  else if (Num >= hcColor1) and (Num <= hcColor5) then
    S := 'Color_' + Char(Num - hcColor1 + $31)
  else if (Num >= hcColor0) and (Num <= hcColorFF) then
    S := 'AbsColor_$' + HexB(Num - hcColor0)
  else if Num and $8000 <> 0 then
  begin
    Num := Num and not $8000;
    Str(Num, S);
    S := 'T' + S;
  end
  else
  begin
    Str(Num, S);
    S := 'T' + S;
  end;
  GetTopicNumStr := S;
end;

procedure ProcessLine;
var
  B, LoPos, HiPos: Byte;
  N, Ofs: Integer;
  PR: PParagraph;
  C: String[15];
begin
  for B := 1 to Length(S) do
    if S[B] in [#0, #$FF] then S[B] := ' '
    else if S[B] = '{' then S[B] := 'ó'
    else if S[B] = '}' then S[B] := 'ò';
  P^.GetOffset(I, 1, PR, Ofs);
  if SP <> PR then
  begin
    if SP <> nil then Inc(Offset, SP^.Size);
    SP := PR;
  end;
  Inc(Ofs, Offset);
  N := P^.NumRefs;
  while N > 0 do
  begin
    if Ofs > P^.CrossRefs^[N].Offset then Break;
    if (Ofs <= P^.CrossRefs^[N].Offset) and
       (Ofs + Length(S) > P^.CrossRefs^[N].Offset) then
    begin
      LoPos := P^.CrossRefs^[N].Offset - Ofs + Byte(S[1] = ' ');
      HiPos := P^.CrossRefs^[N].Offset - Ofs +
	P^.CrossRefs^[N].Length + Byte(S[1] = ' ');
      for B := LoPos to HiPos do
	if (B <= Length(S)) and (S[B] = ':') then S[B] := '÷';
      C := GetTopicNumStr(Word(P^.CrossRefs^[N].Ref));
      Insert(':' + C + '}', S, HiPos);
      Insert('{', S, LoPos);
    end;
    Dec(N);
  end;
end;

begin
  if W <> 0 then Writeln(F);
  S := GetTopicNumStr(W);
  Write(F, '.topic ', S);
  repeat
    Inc(W);
    Inc(Count);
    if H^.Index^.Position(W) <> L then Break;
    S := GetTopicNumStr(W);
    Write(F, ',', S);
  until W >= H^.Index^.Size;
  Writeln(F);
  Offset := 0;
  SP := nil;
  for I := 1 to P^.NumLines do
  begin
    Write(W, '/', I, #13);
    P^.GetLine(I, S);
    if (S <> '') and (P^.NumRefs <> 0) then ProcessLine;
    Writeln(F, S);
  end;
end;

begin
  H := New(PDeHelpFile, Init(InName));
  Assign(F, OutName);
  Rewrite(F);
  if IOResult <> 0 then
    Writeln('Could not create text file ', OutName, '.')
  else
  begin
    W := 0;
    Count := 0;
    while (H^.Stream^.Status = stOk) and (W < H^.Index^.Size) do
    begin
      L := H^.Index^.Position(W);
      if L <> -1 then
      begin
	H^.Stream^.Seek(L);
	P := PHelpTopic(H^.Stream^.Get);
	if (H^.Stream^.Status <> stOk) or (P = nil) then W := $EEEE
	else
	begin
	  P^.SetWidth(Width);
	  P^.CalcNumLines;
	  ProcessTopic;
	  if P <> nil then Dispose(P, Done);
	  if IOResult <> 0 then W := $FFFF;
	end;
      end
      else Inc(W);
    end;
    if W = $EEEE then Writeln(
      'Error ', H^.Stream^.Status, ' reading help file.')
    else if W = $FFFF then Writeln(
      'Error writing to text file.')
    else
    begin
      TS := 'topics';
      if Count = 1 then Dec(TS[0]);
      Writeln(Count, ' ', TS, ' decompiled.');
    end;
    Close(F);
  end;
  Dispose(H, Done);
end;

var
  Code: Integer;
  Width: Word;
  WidthStr: String[3];
  InName, OutName: FNameStr;
begin
  Writeln('CONNECT Help Decompiler  Copyright (c) 1996 KHEMZ Inc.');
  InName := ParamStr(1);
  if InName = '' then
  begin
    Writeln;
    Writeln('  Syntax:  DISHELP <Help file>[.HLP] [<Help text>[.TXT]] [MaxLineWidth]');
    Writeln;
    Writeln('    Help file    = Compiled help file');
    Writeln('    Help text    = Decompiled help file source');
    Writeln('    MaxLineWidth = Number of characters in line (16..255, default width is 64)');
    Halt(0);
  end;
  if Pos('.', InName) = 0 then InName := ForceExtension(InName, 'HLP');
  InName := FExpand(InName);
  OutName := ParamStr(2);
  if Pos('.', OutName) = 0 then OutName := ForceExtension(OutName, 'TXT');
  OutName := FExpand(OutName);
  if InName = OutName then
  begin
    Writeln;
    Writeln('Source file and output file must differ.');
    Halt(1);
  end;
  WidthStr := ParamStr(3);
  Val(WidthStr, Width, Code);
  if (Width < 16) or (Width > 255) then Width := 64;
  RegisterType(RHelpTopic);
  RegisterType(RHelpIndex);
  DecompileHelp(InName, OutName, Width);
end.