{$I-,F+,O+,X+}
unit EditDraw;

interface

uses FEditor, Swaps;

function FindWord(var x; count: Word; value: Word): Integer;

procedure DrawEditorPrim(Editor: PFileEditor);
procedure DrawEditorErrorPrim(Editor: PFileEditor;
  const ALine: String; ACode: Byte);

procedure GetPosPrim(Editor: PFileEditor;
  AnArea: PArea; AnIndex: Integer; var APos: TPos);
procedure GetSelectedStringPrim(Editor: PFileEditor;
  AnIndex: Integer; var ALine: String);

implementation

uses Objects, Drivers, Views, App, Compiler, CmntList, RegExp, RevPos,
  TPString, Defaults;

function FindWord(var x; count: Word; value: Word): Integer;
begin
  asm
    cld
    les di,x
    mov cx,Count
    shr cx,1
    mov ax,Value
    repne scasw
    mov ax,-1
    jnz @L1
    mov ax,count
    shr ax,1
    sub ax,cx
    dec ax
@L1: mov @Result,ax
  end;
end;

procedure DrawEditorPrim(Editor: PFileEditor);
var
  What, XC: Byte;
  DoSyntax, Go: Boolean;
  CurStr, BP, Count, I: Integer;
  C, SelC: Word;
  Pos: TPos;
  B: TDrawBuffer;
  S, US: String;

procedure FillBuf(AColor: Word);
begin
  with Editor^ do
  begin
    BP := Pos.AStart - Delta.X - 1;
    if BP < Size.X then
    begin
      if BP < 0 then BP := 0;
      Count := Pos.AnEnd - Delta.X - 1 - BP;
      if Count > Size.X - BP then Count := Size.X - BP;
      if Count > 0 then MoveChar(B[BP], #0, AColor, Count);
    end;
  end;
end;

procedure ScanLine(const S: String; QuoteChar: Char; Double: Boolean;
  var LoPos, HiPos: Integer);
var
  Flag: Boolean;
  I: Integer;
begin
  with Editor^ do
  begin
    LoPos := 0;
    Flag := False;
    for I := 1 to Length(S) do
    begin
      if S[I] = QuoteChar then Flag := not Flag
      else if (S[I] = Comment[1]) and not Flag and
        (not Double or ((I < Length(S)) and (S[I + 1] = Comment[1]))) then
      begin
        LoPos := I;
	HiPos := Length(S) + 1;
        Exit;
      end;
    end;
  end;
end;

procedure ScanAnyLine;
var
  PC, PE, PL, PS: Integer;
  CS: CommentStr;
begin
  with Editor^ do
  begin
    Pos.AStart := 0;
    US := StUpcase(S);
    if (LocalEditOptions and eoRegExpComment <> 0) and
       (CommentRegExp <> nil) then
    begin
      CS := RegSearch(CommentRegExp, US);
      if CS <> '' then
      begin
        Pos.AStart := System.Pos(CS, US);
        Pos.AnEnd := Length(US) + 1;
      end;
      Exit;
    end;
    PS := 1;
    PL := 1;
    repeat
      PS := FIPos(' ', Comment, PS);
      if PS = 0 then CS := System.Copy(Comment, PL, 127)
      else CS := System.Copy(Comment, PL, PS - PL);
      PL := PS + 1;
      PC := System.Pos(CS, US);
      if PC <> 0 then
      begin
        PE := PC + Length(CS);
        if ((PC = 1) or (US[PC - 1] = ' ')) and
           ((PE > Length(US)) or (US[PE] = ' ') or
	    (CS[Length(CS)] in LocalWordDelims)) then
        begin
          Pos.AStart := PC;
          Pos.AnEnd := Length(US) + 1;
          Exit;
        end;
      end;
    until PS = 0;
  end;
end;

function ReservedWord: Byte;
var
  W: Word;
  Index: Integer;
begin
  W := 0;
  for Index := 0 to Count - 1 do
    W := (W shl 2) xor Byte(US[Pos.AStart + Index]);
  W := FindWord(KeyCodes, SizeOf(KeyCodes), W);
  if W <> $FFFF then
  begin
    Inc(W, 17);
    if KeyWords[W][0] <> Char(Count) then
    begin
      ReservedWord := 0;
      Exit;
    end;
    for Index := 0 to Count - 1 do
      if KeyWords[W][Index + 1] <> US[Pos.AStart + Index] then
      begin
        ReservedWord := 0;
        Exit;
      end;
  end;
  ReservedWord := Byte(W);
end;

function GetNextWord: Boolean;
const
  WordChars = ['0'..'9', 'A'..'Z'];
  Functions = ['&', '@'];
  Operators = ['*', '+', '-', '/', '<', '=', '>'];
  Symbols   = ['(', ')', ';', '|'];
  wOp       = [17, 59, 61, 95]; { AND, NOT, OR, XOR }
  wSt       = [34, 41, 42, 45, 75, 85]; { ELSE, GOSUB, GOTO, IF, RET, THEN }
  wGo       = [41, 42]; { GOSUB, GOTO }
  wRem      = 73; { REM }
label
  Loop;
begin
  GetNextWord := False;
Loop:
  Pos.AStart := Pos.AnEnd;
  repeat
    if Pos.AStart > Length(US) then Exit;
    if US[Pos.AStart] in WordChars then Break;
    Inc(Pos.AnEnd);
    if US[Pos.AStart] = ':' then
    begin
      Pos.AStart := 1;
      What := cCBSLabels;
      GetNextWord := True;
      Exit;
    end;
    if US[Pos.AStart] = '"' then
    begin
      while (Pos.AnEnd < Length(US)) and
        (US[Pos.AnEnd] <> '"') do Inc(Pos.AnEnd);
      Inc(Pos.AnEnd);
      What := cCBSStrings;
      GetNextWord := True;
      Exit;
    end;
    if (US[Pos.AStart] = '{') and
       (Pos.AStart < Length(US)) and
       (US[Pos.AStart + 1] = 'L') then
    begin
      while (Pos.AnEnd < Length(US)) and
        (US[Pos.AnEnd] <> '}') do Inc(Pos.AnEnd);
      Inc(Pos.AnEnd);
      What := cCBSFunctions;
      GetNextWord := True;
      Exit;
    end;
    if US[Pos.AStart] in Functions then
    begin
      What := cCBSFunctions;
      GetNextWord := True;
      Exit;
    end;
    if US[Pos.AStart] in Operators then
    begin
      What := cCBSOperators;
      GetNextWord := True;
      Exit;
    end;
    if US[Pos.AStart] in Symbols then
    begin
      What := cCBSSymbols;
      GetNextWord := True;
      Exit;
    end;
    Inc(Pos.AStart);
  until False;
  repeat
    Inc(Pos.AnEnd);
    if (Pos.AnEnd > Length(US)) or
      not (US[Pos.AnEnd] in WordChars) then
    begin
      if Go then
      begin
        Go := False;
        What := cCBSLabels;
        GetNextWord := True;
        Exit;
      end;
      Count := Pos.AnEnd - Pos.AStart;
      if Count > 6 then What := 0
      else What := ReservedWord;
      if What in [17..MaxKeyWords - 2] then
      begin
        Go := What in wGo;
        if What = wRem then
        begin
          What := cCBSRemarks;
          Pos.AnEnd := Length(US) + 1;
        end
        else if What in wOp then What := cCBSOperators
        else if What in wSt then What := cCBSStatements
        else What := cCBSFunctions;
        GetNextWord := True;
        Exit;
      end
      else if Pos.AnEnd > Length(US) then Exit
      else Goto Loop;
    end;
  until False;
end;

{ Added 25.09.2002 to support 'primitive' syntax highlight }

function FoundInSyntaxList(const SS: String; var Color: Byte): Boolean;
var
  P: Byte;
  CT: CompareType;
  L, H, I: Integer;
  K: String;
begin
  FoundInSyntaxList := False;
  with Editor^.SyntaxList^ do
  begin
    L := 0;
    H := Count - 1;
    while L <= H do
    begin
      I := (L + H) shr 1;
      K := PString(Items^[I])^;
      P := System.Pos(' ', K);
      if P = 0 then P := Length(K) + 1;
      CT := CompString(System.Copy(K, 1, P - 1), SS);
      if CT = Less then L := I + 1
      else
      begin
        if CT = Equal then
        begin
          Val(Trim(System.Copy(K, P + 1, 255)), Color, I);
          FoundInSyntaxList := True;
          Exit;
        end;
        H := I - 1;
      end;
    end;
  end;
end;

function IsNumber(SS: String): Boolean;
var
  C: Char;
  I, E: Byte;
begin
  IsNumber := False;
{ 0F, 0L, 0U }
  if (Length(SS) > 1) and (SS[Length(SS)] in ['F', 'L', 'U']) then
  begin
    C := SS[Length(SS)];
    Dec(SS[0]);
    if (Length(SS) > 1) and
       ((SS[Length(SS)] = 'U') and (C = 'L')) then Dec(SS[0]);
  end;
{ 0b0, 0o0, 0x0 }
  if (Length(SS) > 2) and (SS[1] = '0') and
     (SS[2] in ['B', 'O', 'X']) then
  begin
    for I := 3 to Length(SS) do
      if ((SS[2] = 'B') and not (SS[I] in ['0'..'1'])) or
         ((SS[2] = 'O') and not (SS[I] in ['0'..'7'])) or
         ((SS[2] = 'X') and not (SS[I] in ['0'..'9', 'A'..'F'])) then Exit;
    IsNumber := True;
    Exit;
  end;
{ 0b, 0h, 0o }
  if (Length(SS) > 1) and (SS[Length(SS)] in ['B', 'H', 'O']) then
  begin
    for I := 1 to Length(SS) - 1 do
      if ((SS[Length(SS)] = 'B') and not (SS[I] in ['0'..'1'])) or
	 ((SS[Length(SS)] = 'H') and not (SS[I] in ['0'..'9', 'A'..'F'])) or
	 ((SS[Length(SS)] = 'O') and not (SS[I] in ['0'..'7'])) then Exit;
    IsNumber := True;
    Exit;
  end;
{ 1e- }
  if (Length(SS) > 1) and (SS[Length(SS)] = 'E') then
  begin
    for I := 1 to Length(SS) - 1 do
      if not (SS[I] in ['0'..'9']) then Exit;
    IsNumber := (Pos.AnEnd < Length(US)) and
      (US[Pos.AnEnd] = '-') and (US[Pos.AnEnd + 1] in ['0'..'9']);
    Exit;
  end;
{ $0 }
  if (Pos.AStart > 1) and (US[Pos.AStart - 1] = '$') then
  begin
    for I := 1 to Length(SS) do
      if not (SS[I] in ['0'..'9', 'A'..'F']) then Exit;
    IsNumber := True;
    Exit;
  end;
{ 0, 1e1 }
  E := 0;
  for I := 1 to Length(SS) do
    if not (SS[I] in ['0'..'9']) then
      if (SS[I] = 'E') and (E = 0) then E := I else Exit;
  IsNumber := (E = 0) or (E <> 1);
end;

function CharMatches(C1, C2: Char): Boolean;
var
  CC: Char;
begin
  case C1 of
    '(': CC := ')';
    ')': CC := '(';
    '[': CC := ']';
    ']': CC := '[';
    '{': CC := '}';
    '}': CC := '{';
    '<': CC := '>';
    '>': CC := '<';
    else CC := C1;
  end;
  CharMatches := CC = C2;
end;

function GetNextSyntaxWord(var Color: Byte): Boolean;
const
  WordChars = ['0'..'9', 'A'..'Z', '_'];
label
  Loop;
var
  B: Byte;
  I: Integer;
  E: Extended;
  K: String;
begin
  GetNextSyntaxWord := False;
  B := 0;
Loop:
  Pos.AStart := Pos.AnEnd;
  repeat
    if Pos.AStart > Length(US) then Exit;
    if US[Pos.AStart] in WordChars then Break;
    Inc(Pos.AnEnd);
    if US[Pos.AStart] in Editor^.SyntaxList^.Quotes then
    begin
      while (Pos.AnEnd < Length(US)) and not
	CharMatches(US[Pos.AStart], US[Pos.AnEnd]) do Inc(Pos.AnEnd);
      Inc(Pos.AnEnd);
      Color := Editor^.SyntaxList^.QuoteColors[US[Pos.AStart]];
      GetNextSyntaxWord := True;
      Exit;
    end;
    if US[Pos.AStart] in Editor^.SyntaxList^.Symbols then
    begin
      if B = 0 then
      begin
	B := 1;
	Pos.AnEnd := Pos.AStart;
	Break;
      end;
      if FoundInSyntaxList(US[Pos.AStart], Color) then
      begin
	GetNextSyntaxWord := True;
	Exit;
      end;
      B := 0;
    end;
    Inc(Pos.AStart);
  until False;
  repeat
    Inc(Pos.AnEnd);
    if (Pos.AnEnd > Length(US)) or
      not (US[Pos.AnEnd] in WordChars) then
    begin
      K := System.Copy(US, Pos.AStart, Pos.AnEnd - Pos.AStart);
      if (Editor^.SyntaxList^.NumberColor <> 0) and IsNumber(K) then
      begin
	Color := Editor^.SyntaxList^.NumberColor;
	GetNextSyntaxWord := True;
	Exit;
      end;
      if FoundInSyntaxList(K, Color) then
      begin
	GetNextSyntaxWord := True;
	Exit;
      end;
      if B <> 0 then
      begin
	Pos.AnEnd := Pos.AStart;
	goto Loop;
      end;
      if Pos.AnEnd > Length(US) then Exit;
      goto Loop;
    end;
  until False;
end;

label
  SkipSyntax;
begin
  with Editor^ do
  begin
    if DrawFlag then Exit;
    FastGetLine := False;
    ErrorCode := 0;
    C := GetColor(1);
    SelC := GetColor(2);
    DoSyntax := (LocalEditOptions and eoSyntax <> 0) and
      ((SyntaxWord <> swNothing) or
      ((SyntaxList <> nil) and (SyntaxList^.Count <> 0)));
    if DrawFromTop then I := 0 else I := Size.Y - 1;
    repeat
      MoveChar(B, ' ', C, Size.X);
      CurStr := Delta.Y + I;
      if CurStr < FileLines^.Count then
      begin
        GetValidLine(CurStr, S);
        MoveStr(B, System.Copy(S, Succ(Delta.X), Size.X), C);

        if (I = Cursor.Y) and (LocalEditOptions and eoHilitCurLine <> 0) then
          MoveChar(B, #0, Byte(Application^.GetPalette^[cCurLine]), Size.X);

        if DoSyntax then
        begin
{ Added 25.09.2002 to support 'primitive' syntax highlight }
          if (SyntaxList <> nil) and (SyntaxList^.Count <> 0) then
          begin
            US := StUpcase(S);
            Pos.AnEnd := 1;
            repeat
              if not GetNextSyntaxWord(XC) then Break;
              FillBuf(Byte(XC));
            until False;
            Pos.AStart := 0;
          end;
          case SyntaxWord of
            swASM: ScanLine(S, '''', False, Pos.AStart, Pos.AnEnd);
            swCPP: ScanLine(S, '"', True, Pos.AStart, Pos.AnEnd);
            swBAS: ScanLine(S, '"', False, Pos.AStart, Pos.AnEnd);
            swAny: ScanAnyLine;
            swCBS:
              begin
                US := StUpcase(S);
                Pos.AnEnd := 1;
                Go := False;
                repeat
                  if not GetNextWord then Break;
                  FillBuf(Byte(Application^.GetPalette^[What]));
                until False;
                Goto SkipSyntax;
              end;
            else Goto SkipSyntax;
          end;
          if Pos.AStart <> 0 then
            FillBuf(Byte(Application^.GetPalette^[cASM]));
        end;

SkipSyntax:
        Pos.AStart := 0;
        if (LinesPerPage <> 0) and ((CurStr + 1) mod LinesPerPage = 0) then
          MoveChar(B, #0, Byte(Application^.GetPalette^[cPageBreak]), Size.X)
        else if IsDebug and (CurStr = SourceLine) then
          MoveChar(B, #0, GetColor(4), Size.X)
        else if (BreakPoints[0] <> -1) and
          (FindWord(BreakPoints, SizeOf(BreakPoints), CurStr) <> -1) then
            MoveChar(B, #0, GetColor(3), Size.X)
        else if IsSelected and Selected(CurStr) then
        begin
          GetPos(Area, CurStr, Pos);
          FillBuf(SelC);
        end;
      end
      else
      begin
        Pos.AStart := 0;
        if (I = Cursor.Y) and (LocalEditOptions and eoHilitCurLine <> 0) then
          MoveChar(B, #0, Byte(Application^.GetPalette^[cCurLine]), Size.X);
      end;
      if (LocalEditOptions and eoHilitCurColumn <> 0) and
         (Cursor.X >= 0) and (Cursor.X < MaxViewWidth) and
         ((Pos.AStart = 0) or (Delta.X + Cursor.X + 1 < Pos.AStart) or
          (Delta.X + Cursor.X + 1 >= Pos.AnEnd)) then
        MoveChar(B[Cursor.X], #0, Byte(Application^.GetPalette^[cCurCol]), 1);
      if LocalEditOptions and eoHilitBounds <> 0 then
      begin
        Pos.AStart := (LocalEditOptions and not EditOptMask) shr 26 -
          Delta.X - 1;
        Pos.AnEnd := LocalMaxLineWidth - Delta.X;
        if (Pos.AStart >= 0) and (Pos.AStart < MaxViewWidth) then
          MoveChar(B[Pos.AStart], #0,
            Byte(Application^.GetPalette^[cBoundaries]), 1);
        if (Pos.AnEnd >= 0) and (Pos.AnEnd < MaxViewWidth) then
          MoveChar(B[Pos.AnEnd], #0,
            Byte(Application^.GetPalette^[cBoundaries]), 1);
      end;
      WriteLine(0, I, Size.X, 1, B);
      if DrawFromTop then
      begin
        Inc(I);
        if I >= Size.Y then Break;
      end
      else
      begin
        Dec(I);
        if I < 0 then Break;
      end;
    until False;
    if (State and sfFocused = 0) and not IsDebug and not MultiScrolling then
    begin
      NewLines^.FreeAll;
      TopLine := MaxInt;
    end;
  end;
end;

procedure DrawEditorErrorPrim(Editor: PFileEditor;
  const ALine: String; ACode: Byte);
var
  C: Word;
  B: TDrawBuffer;
begin
  with Editor^ do
  begin
    if Lo(ScreenMode) = smMono then C := SysMonoAttr
    else C := SysColorAttr;
    MoveChar(B, ' ', C, Size.X);
    MoveStr(B[1], ALine, C);
    if Cursor.Y = 0 then WriteLine(0, Size.Y - 1, Size.X, 1, B)
    else WriteLine(0, 0, Size.X, 1, B);
    DoRedraw := True;
    IsDebug := False;
    if ACode > 23 then ErrorCode := 24
    else ErrorCode := ACode + 1;
  end;
end;

procedure GetPosPrim(Editor: PFileEditor;
  AnArea: PArea; AnIndex: Integer; var APos: TPos);
begin
  with Editor^ do
    if MarkColumns then
    begin
      if AnArea^.PB > AnArea^.PK then
      begin
        APos.AStart := AnArea^.PK;
        APos.AnEnd := AnArea^.PB;
      end
      else
      begin
        APos.AStart := AnArea^.PB;
        APos.AnEnd := AnArea^.PK;
      end;
    end
    else
    begin
      if AnIndex = AnArea^.KB then APos.AStart := AnArea^.PB
      else APos.AStart := 1;
      if AnIndex = AnArea^.KK then APos.AnEnd := AnArea^.PK
      else APos.AnEnd := SizeOf(String);
    end;
end;

procedure GetSelectedStringPrim(Editor: PFileEditor;
  AnIndex: Integer; var ALine: String);
var
  Pos: TPos;
begin
  with Editor^ do
  begin
    GetValidLine(AnIndex, ALine);
    GetPos(Area, AnIndex, Pos);
    ALine := System.Copy(ALine, Pos.AStart, Pos.AnEnd - Pos.AStart);
  end;
end;

end.