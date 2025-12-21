{$I-,F+,O+,X+}
unit EditWrap;

interface

uses Objects, Drivers, FEditor, CNInputs;

type
  PWidthInput = ^TWidthInput;
  TWidthInput = object(TCInputLine)
    Width: String[3];
    constructor Init(var Bounds: TRect; AMaxLen: Integer;
      AMin, AMax: Longint; const AWidth: String);
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure WrapLinePrim(Editor: PFileEditor; AnIndex: Integer);
procedure ReformatBlockPrim(Editor: PFileEditor; FromCursor: Boolean);
procedure UnformatBlockPrim(Editor: PFileEditor);

implementation

uses Views, Dialogs, MsgBox, App, EditMsg, Keyboard,
  Swaps, StrWrap, TPString, Consts, Defaults;

const
  Paragraphs = 1;
  WordDivision = 2;
  ExpandLines = 4;

  LineWidth: Byte = 0;
  MarginWidth: Byte = 0;
  WidthStr: String[3] = '';
  MarginStr: String[3] = '';
  SelOnly: Word = 1;
  Layout: Word = Paragraphs + WordDivision + ExpandLines;

  Letters = ['A'..'Z', 'a'..'z', '€'..'Ÿ', ' '..'¯', 'à'..'ï', #240, #241];

constructor TWidthInput.Init(var Bounds: TRect; AMaxLen: Integer;
  AMin, AMax: Longint; const AWidth: String);
begin
  Inherited Init(Bounds, AMaxLen, AMin, AMax);
  Width := AWidth;
end;

procedure TWidthInput.HandleEvent(var Event: TEvent);
begin
  Inherited HandleEvent(Event);
  if (Event.What = evKeyDown) and (Event.KeyCode = kbDown) then
  begin
    SetData(Width);
    Event.What := evNothing;
  end;
end;

procedure WrapLinePrim(Editor: PFileEditor; AnIndex: Integer);
var
  Ins, Cont: Boolean;
  B, C, X, NX: Byte;
  I: Integer;
  S, NS, PS: String;

procedure CompressLine;
begin
  C := 1;
  while (C < Length(S)) and (S[C] = ' ') do Inc(C);
  if C < Length(S) then
  repeat
    while (C < Length(S)) and (S[C] <> ' ') do Inc(C);
    if C = Length(S) then Break;
    Inc(C);
    while (C < Length(S)) and (S[C] = ' ') do with Editor^ do
    begin
      System.Delete(S, C, 1);
      if Delta.X + Cursor.X >= C then Dec(Cursor.X);
      if IsSelected and not MarkColumns then
      begin
	if (AnIndex = Area^.KB) and (C < Area^.PB) then Dec(Area^.PB);
	if (AnIndex = Area^.KK) and (C < Area^.PK) then Dec(Area^.PK);
      end;
    end;
  until False;
end;

procedure AddMargin;
begin
  C := 1;
  if Editor^.LocalEditOptions and eoAutoIndentMode <> 0 then
    while (C < Editor^.LocalMaxLineWidth) and (S[C] = ' ') do Inc(C);
  NX := (Editor^.LocalEditOptions and not EditOptMask) shr 26 + 1;
  if C < NX then C := NX;
  if C = 1 then Exit;
  FillChar(PS, SizeOf(String), ' ');
  PS[0] := Char(C - 1);
  NS := PS + NS;
end;

procedure ExpandLine;
begin
  C := 1;
  while (C < Length(S)) and (S[C] = ' ') do Inc(C);
  if C = Length(S) then Exit;
  C := 1;
  Ins := False;
  repeat
    if Length(S) >= Editor^.LocalMaxLineWidth then Exit;
    while (C < Length(S)) and (S[C] = ' ') do Inc(C);
    while (C < Length(S)) and (S[C] <> ' ') do Inc(C);
    if C = Length(S) then
      if not Ins then Exit else C := 1
    else with Editor^ do
    begin
      System.Insert(' ', S, C);
      if (Delta.Y + Cursor.Y = AnIndex) and
	 (Delta.X + Cursor.X >= C) then Inc(Cursor.X);
      if IsSelected and not MarkColumns then
      begin
	if (AnIndex = Area^.KB) and (C < Area^.PB) then
	  SetArea(Area, Area^.KB, Area^.PB + 1, Area^.KK, Area^.PK);
	if (AnIndex = Area^.KK) and (C < Area^.PK) then
	  SetArea(Area, Area^.KB, Area^.PB, Area^.KK, Area^.PK + 1);
      end;
      Ins := True;
    end;
  until False;
end;

begin
  with Editor^ do
  begin
    SaveLastLine;
    NewUndoChain(2);
    GetValidLine(AnIndex, S);
    TrailTrim(S);
    if LocalEditOptions and eoExpandLine <> 0 then CompressLine;
    Cont := Delta.X + Cursor.X = Length(S);
    DrawFlag := True;
    if (Length(S) > LocalMaxLineWidth) and Cont then
    begin
      if LocalEditOptions and eoWordDivision <> 0 then
      begin
	I := Length(S);
	WrapStr(S, LocalWordDelims, LocalMaxLineWidth);
	SetCursor(Cursor.X + Length(S) - I, Cursor.Y);
      end;
      B := LocalMaxLineWidth + 1;
      while (B > 0) and (S[B] <> ' ') do
      begin
	Dec(B);
	if S[B] = '-' then Break;
      end;
      while (B > 0) and (S[B] = ' ') do Dec(B);
      if B = 0 then B := LocalMaxLineWidth;
      NS := Trim(System.Copy(S, B + 1, 255));
      X := Delta.X + Cursor.X;
      if X >= B then X := Length(S) - X else X := 255;
      AddMargin;
      NewLine(AnIndex + 1, NS);
      if X <> 255 then
      begin
	if X > Length(NS) then X := Length(NS);
	GoDown;
	GoToPos(Length(NS) - X, Delta.Y + Cursor.Y);
      end;
      if IsSelected then
      begin
	if AnIndex < Area^.KB then
	begin
	  Inc(Area^.KB);
	  Inc(Area^.KK);
	end
	else if not MarkColumns and
	  (AnIndex = Area^.KB) and (B < Area^.PB) then
	begin
	  IsSelected := False;
	  if Area^.KB = Area^.KK then
	    Highlight(AnIndex + 1, Length(NS) - Length(S) + Area^.PB,
	      AnIndex + 1, Length(NS) - Length(S) + Area^.PK)
	  else Highlight(AnIndex + 1, Length(NS) - Length(S) + Area^.PB,
	    Area^.KK + 1, Area^.PK);
	end
	else if AnIndex < Area^.KK then Inc(Area^.KK)
	else if not MarkColumns and
	  (AnIndex = Area^.KK) and (B < Area^.PK) then
	begin
	  IsSelected := False;
	  Highlight(Area^.KB, Area^.PB, AnIndex + 1,
	    Length(NS) - Length(S) + Area^.PK);
	end;
      end;
      S[0] := Char(B);
    end;
    if LocalEditOptions and eoExpandLine <> 0 then ExpandLine;
    ReplaceLine(AnIndex, S);
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    if not Cont and (Length(S) > LocalMaxLineWidth) then
      ReformatBlockPrim(Editor, True);
    AddUndoChain;
    DrawFlag := False;
  end;
end;

function UnformatLine(var S: String;
  Editor: PFileEditor; Index: Integer;
  UpdateArea, UpdateCursor: Boolean): Boolean;
var
  B: Byte;
  Result: Boolean;
begin
  Result := False;
  B := 1;
  while (B < Length(S)) and (S[B] = ' ') do Inc(B);
  if B < Length(S) then
  repeat
    while (B < Length(S)) and (S[B] <> ' ') do Inc(B);
    if B = Length(S) then Break;
    Inc(B);
    while (B < Length(S)) and (S[B] = ' ') do
    begin
      System.Delete(S, B, 1);
      if UpdateArea then with Editor^ do
	if IsSelected and not MarkColumns then
	begin
	  if (Index = Area^.KB) and (B < Area^.PB) then Dec(Area^.PB);
	  if (Index = Area^.KK) and (B < Area^.PK) then Dec(Area^.PK);
	end;
      if UpdateCursor then with Editor^ do
	if (Index = Delta.Y + Cursor.Y) and (B <= Delta.X + Cursor.X) then
	  Dec(Cursor.X);
    end;
    Result := True;
  until False;
  UnformatLine := Result;
end;

procedure ReformatBlockPrim(Editor: PFileEditor; FromCursor: Boolean);
var
  B, C: Byte;
  Ins: Boolean;
  SaveSelOnly, SaveLayout: Word;
  I, IB, IE: Integer;
  Percent, OldPercent: Longint;
  DefWidth, DefMargin: String[3];
  S, NS: String;

procedure GetDefStrings;
begin
  with Editor^ do GetValidLine(Delta.Y + Cursor.Y, S);
  TrailTrim(S);
  C := Length(S);
  Str(C, DefWidth);
  B := 1;
  C := 0;
  while B <= Length(S) do
  begin
    if S[B] = ' ' then Inc(C) else Break;
    Inc(B);
  end;
  Str(C, DefMargin);
end;

function SetupOk: Boolean;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 28, 18);
  D := New(PDialog, Init(R, 'Reformat options'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcCtrlQR;

    R.Assign(15, 2, 20, 3);
    Control := New(PWidthInput, Init(R, 3, 16, 255, DefWidth));
    Insert(Control);
    R.Assign(2, 2, 15, 3);
    Insert(New(PLabel, Init(R, '~L~ine width', Control)));

    R.Assign(15, 4, 20, 5);
    Control := New(PWidthInput, Init(R, 3, 0, 30, DefMargin));
    Insert(Control);
    R.Assign(2, 4, 15, 5);
    Insert(New(PLabel, Init(R, 'Left ~m~argin', Control)));

    R.Assign(3, 7, Size.X - 3, 9);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~G~lobal', NewSItem('~S~elected text', nil))));
    Insert(Control);
    R.Assign(2, 6, Size.X - 3, 7);
    Insert(New(PLabel, Init(R, 'Scope', Control)));

    R.Assign(3, 11, Size.X - 3, 14);
    Control := New(PCheckBoxes, Init(R,
      NewSItem('~P~aragraphs',
      NewSItem('~W~ord hyphenation',
      NewSItem('~E~xpand lines', nil)))));
    Insert(Control);
    R.Assign(2, 10, Size.X - 3, 11);
    Insert(New(PLabel, Init(R, 'Layout', Control)));

    R.Assign(2, 15, 12, 17);
    StandardOkButton(R, D);
    R.Assign(16, 15, 26, 17);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  SetupOk := Application^.ExecuteDialog(D, @WidthStr, False) <> cmCancel;
end;

procedure AddMargin;
var
  SS: String;
begin
  FillChar(SS, SizeOf(SS), ' ');
  SS[0] := Char(MarginWidth);
  NS := SS + NS;
end;

procedure SplitLine;
begin
  if Layout and WordDivision <> 0 then
    WrapStr(S, Editor^.LocalWordDelims, LineWidth);
  B := LineWidth + 1;
  while (B > 0) and (S[B] <> ' ') do
  begin
    Dec(B);
    if S[B] = '-' then Break;
  end;
  while (B > 0) and (S[B] = ' ') do Dec(B);
  if B = 0 then Exit;
  NS := Trim(System.Copy(S, B + 1, 255));
  AddMargin;
  Editor^.NewLine(I + 1, NS);
  with Editor^ do
  begin
    if FromCursor and (Delta.Y + Cursor.Y = I) and
      (Delta.X + Cursor.X > B - Byte(S[B] = '-')) then
    begin
      Inc(Cursor.Y);
      Inc(Cursor.X, MarginWidth - B);
      if S[B] = '-' then Inc(Cursor.X) else Dec(Cursor.X);
    end;
    if IsSelected then
    begin
      if I < Area^.KB then
      begin
	Inc(Area^.KB);
	Inc(Area^.KK);
      end
      else if not MarkColumns and
	(I = Area^.KB) and (B < Area^.PB) then
      begin
	IsSelected := False;
	if Area^.KB = Area^.KK then
	  Highlight(I + 1, Length(NS) - Length(S) + Area^.PB,
	    I + 1, Length(NS) - Length(S) + Area^.PK)
	else Highlight(I + 1, Length(NS) - Length(S) + Area^.PB,
	  Area^.KK + 1, Area^.PK);
      end
      else if I < Area^.KK then Inc(Area^.KK)
      else if not MarkColumns and
	(I = Area^.KK) and (B < Area^.PK) then
      begin
	IsSelected := False;
	Highlight(Area^.KB, Area^.PB, I + 1,
	  Length(NS) - Length(S) + Area^.PK);
      end;
    end;
  end;
  S[0] := Char(B);
  Inc(IE);
end;

function NewParagraph(const NL: String): Boolean;
begin
  B := 1;
  while (B < Length(NL)) and (NL[B] = ' ') do Inc(B);
  Dec(B);
  NewParagraph := B > MarginWidth;
end;

procedure ConcatLine;
var
  WasDiv: Boolean;
  Len, LenDiff, PBDiff, PKDiff: Byte;
  SaveArea: TArea;
begin
  with Editor^ do
  repeat
    if I = IE then Exit;
    GetValidLine(I + 1, NS);
    TrailTrim(NS);
    if (Layout and Paragraphs <> 0) and NewParagraph(NS) then Exit;
    Len := Length(NS);
    TrimSt(NS);
    LenDiff := Len - Length(NS);
    SaveArea := Area^;
    UnformatLine(NS, Editor, I + 1, True, False);
    PBDiff := SaveArea.PB - Area^.PB;
    PKDiff := SaveArea.PK - Area^.PK;
    Area^ := SaveArea;
    if NS = '' then Exit;
    if (Length(S) > 1) and (S[Length(S)] = '-') and
       (S[Length(S) - 1] in Letters) then
    begin
      Dec(S[0]);
      WasDiv := True;
    end
    else WasDiv := False;
    B := LineWidth - Length(S) + Byte(WasDiv);
    if B > Length(NS) then
    begin
      if not WasDiv then
      begin
	Inc(S[0]);
	S[Length(S)] := ' ';
      end;
      Len := Length(S);
      S := S + NS;
      ClearLine(I + 1);
      Dec(IE);
      if IsSelected then
      begin
	if I + 1 < Area^.KB then
	begin
	  Dec(Area^.KB);
	  Dec(Area^.KK);
	end
	else if (I + 1 = Area^.KB) and (Area^.KB = Area^.KK) then
	  SetArea(Area, Area^.KB - 1, Area^.PB + Len - LenDiff - PBDiff,
	    Area^.KK - 1, Area^.PK + Len - LenDiff - PKDiff)
	else if I + 1 = Area^.KB then
	begin
	  Dec(Area^.KK);
	  if not MarkColumns then
	    SetArea(Area, Area^.KB - 1, Area^.PB + Len - LenDiff - PBDiff,
	    Area^.KK, Area^.PK);
	end
	else if I + 1 < Area^.KK then Dec(Area^.KK)
	else if I + 1 = Area^.KK then
	  if MarkColumns then Dec(Area^.KK)
	  else SetArea(Area, Area^.KB, Area^.PB,
	    Area^.KK - 1, Area^.PK + Len - LenDiff - PKDiff);
      end;
    end
    else
    begin
      if (Layout and WordDivision <> 0) and (B > 2) then
	WrapStr(NS, LocalWordDelims, B - 1);
      while (B > 0) and (NS[B] <> ' ') do
      begin
	Dec(B);
	if NS[B] = '-' then Break;
      end;
      while (B > 0) and (NS[B] = ' ') do Dec(B);
      if B = 0 then
      begin
	if WasDiv then Inc(S[0]);
	Exit;
      end;
      if not WasDiv then
      begin
	Inc(S[0]);
	S[Length(S)] := ' ';
      end;
      Len := Length(S);
      if IsSelected and not MarkColumns then
      begin
	if I + 1 = Area^.KB then
	  if Area^.PB - LenDiff - PBDiff <= B then
	    SetArea(Area, Area^.KB - 1, Area^.PB + Len - LenDiff - PBDiff,
	      Area^.KK, Area^.PK)
	  else SetArea(Area, Area^.KB,
	    Area^.PB - LenDiff - PBDiff - B - 1 + MarginWidth +
	    2 * Byte(NS[B] = '-'), Area^.KK, Area^.PK);
	if I + 1 = Area^.KK then
	  if Area^.PK - LenDiff - PKDiff <= B + 1 then
	    SetArea(Area, Area^.KB, Area^.PB,
	      Area^.KK - 1, Area^.PK + Len - LenDiff - PKDiff)
	  else SetArea(Area, Area^.KB, Area^.PB, Area^.KK,
	    Area^.PK - LenDiff - PKDiff - B - 1 + MarginWidth +
	    2 * Byte(NS[B] = '-'));
      end;
      S := S + Trim(System.Copy(NS, 1, B));
      NS := Trim(System.Copy(NS, B + 1, 255));
      AddMargin;
      ReplaceLine(I + 1, NS);
      Exit;
    end;
  until False;
end;

procedure ExpandLine;
begin
  if I = IE then Exit;
  Editor^.GetValidLine(I + 1, NS);
  TrailTrim(NS);
  if NS = '' then Exit;
  if (Layout and Paragraphs <> 0) and NewParagraph(NS) then Exit;
  B := 1;
  Ins := False;
  repeat
    if Length(S) >= LineWidth then Exit;
    while (B < Length(S)) and (S[B] = ' ') do Inc(B);
    while (B < Length(S)) and (S[B] <> ' ') do Inc(B);
    if B = Length(S) then
      if not Ins then Exit else B := 1
    else with Editor^ do
    begin
      System.Insert(' ', S, B);
      if IsSelected and not MarkColumns then
      begin
	if (I = Area^.KB) and (B < Area^.PB) then
	  SetArea(Area, Area^.KB, Area^.PB + 1, Area^.KK, Area^.PK);
	if (I = Area^.KK) and (B < Area^.PK) then
	  SetArea(Area, Area^.KB, Area^.PB, Area^.KK, Area^.PK + 1);
      end;
      if FromCursor and (Delta.Y + Cursor.Y = I) and
	(Delta.X + Cursor.X >= B) then Inc(Cursor.X);
    end;
    Ins := True;
  until False;
end;

label
  Change;
begin
  with Editor^ do
  begin
    if FromCursor then
    begin
      LineWidth := LocalMaxLineWidth;
      MarginWidth := (LocalEditOptions and not EditOptMask) shr 26;
      SaveSelOnly := SelOnly;
      SelOnly := 0;
      SaveLayout := Layout;
      Layout := Paragraphs;
      if LocalEditOptions and eoWordDivision <> 0 then
	Layout := Layout + WordDivision;
      if LocalEditOptions and eoExpandLine <> 0 then
	Layout := Layout + ExpandLines;
    end
    else
    begin
      if LineWidth = 0 then LineWidth := LocalMaxLineWidth;
      Str(LineWidth, WidthStr);
      if MarginWidth = 0 then
	MarginWidth := (LocalEditOptions and not EditOptMask) shr 26;
      if MarginWidth = 0 then MarginStr := 'No'
      else Str(MarginWidth, MarginStr);
      GetDefStrings;
      if LocalEditOptions and eoWordDivision <> 0 then
	Layout := Layout or WordDivision
      else Layout := Layout and not WordDivision;
      if LocalEditOptions and eoExpandLine <> 0 then
	Layout := Layout or ExpandLines
      else Layout := Layout and not ExpandLines;
      if not SetupOk then Exit;
      Val(WidthStr, LineWidth, I);
      Val(MarginStr, MarginWidth, I);
      if MarginWidth >= LineWidth then MarginWidth := LineWidth - 1;
      if not IsSelected and Boolean(SelOnly) then Exit;
    end;
    SaveLastLine;
    if Boolean(SelOnly) then
    begin
      IB := Area^.KB;
      if Area^.PK = 1 then IE := Area^.KK - 1
      else IE := Area^.KK;
    end
    else
    begin
      if FromCursor then IB := Delta.Y + Cursor.Y
      else IB := 0;
      IE := FileLines^.Count - 1;
    end;
    NewUndoChain(IE - IB + 8);
    OldPercent := -1;
    I := IB - 1;
    FastGetLine := True;
    repeat
      Inc(I);
      if I > IE then Break;
      if IE = IB then Percent := 100
      else Percent := Trunc(((I - IB) / (IE - IB)) * 100);
      if Percent <> OldPercent then
      begin
	OldPercent := Percent;
	FormatStr(S, ' %d  done', Percent);
	S[Length(S) - 5] := '%';
	LogEvent := 0;
	DrawStatusLine('Reformatting text lines:' + S);
      end;
      GetValidLine(I, S);
      TrailTrim(S);
      if FromCursor and (I <> Delta.Y + Cursor.Y) and
	((S = '') or NewParagraph(S)) then Break;
      if Layout and ExpandLines <> 0 then
	Ins := UnformatLine(S, Editor, I, True, FromCursor)
      else Ins := False;
      if (S = '') or (Length(S) = LineWidth) then
	if Ins then Goto Change else Continue;
      if Length(S) > LineWidth then SplitLine
      else ConcatLine;
      if Layout and ExpandLines <> 0 then ExpandLine;
Change:
      if PSwapLinesCollection(FileLines)^.Status <> coOverflow then
	ReplaceLine(I, S);
      if PSwapLinesCollection(FileLines)^.Status = coOverflow then
      begin
	PSwapLinesCollection(FileLines)^.Status := 0;
	Break;
      end;
      if (KbdStatus = 1) and AbortAction then Break;
    until False;
    AddUndoChain;
    if IsSelected and not MarkColumns and Boolean(SelOnly) then
      if Area^.PK > 1 then
      begin
	GetValidLine(Area^.KK, S);
	TrailTrim(S);
	SetArea(Area, Area^.KB, 1, Area^.KK, Length(S) + 1);
      end
      else Area^.PB := 1;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    if FromCursor then
    begin
      SelOnly := SaveSelOnly;
      Layout := SaveLayout;
      GoToPos(Delta.X + Cursor.X, Delta.Y + Cursor.Y);
    end
    else GoToPos(0, I);
    DrawFlag := False;
    IsModified := True;
    DebugModified := True;
  end;
end;

procedure UnformatBlockPrim(Editor: PFileEditor);
var
  B: Byte;
  Ins: Boolean;
  I, IB, IE: Integer;
  Percent, OldPercent: Longint;
  S, NS: String;

function SetupOk: Boolean;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 27, 9);
  D := New(PDialog, Init(R, 'Unformat options'));
  with D^ do
  begin
    Options := Options or ofCentered;
    HelpCtx := hcCtrlQO;

    R.Assign(3, 3, Size.X - 3, 5);
    Control := New(PRadioButtons, Init(R,
      NewSItem('~G~lobal', NewSItem('~S~elected text', nil))));
    Insert(Control);
    R.Assign(2, 2, Size.X - 3, 3);
    Insert(New(PLabel, Init(R, 'Scope', Control)));

    R.Assign(2, 6, 12, 8);
    StandardOkButton(R, D);
    R.Assign(15, 6, 25, 8);
    StandardCancelButton(R, D);
    SelectNext(False);
  end;
  SetupOk := Application^.ExecuteDialog(D, @SelOnly, False) <> cmCancel;
end;

begin
  with Editor^ do
  begin
    if not SetupOk then Exit;
    if not IsSelected and Boolean(SelOnly) then Exit;
    SaveLastLine;
    if Boolean(SelOnly) then
    begin
      IB := Area^.KB;
      if Area^.PK = 1 then IE := Area^.KK - 1
      else IE := Area^.KK;
    end
    else
    begin
      IB := 0;
      IE := FileLines^.Count - 1;
    end;
    NewUndoChain(IE - IB + 1);
    OldPercent := -1;
    FastGetLine := True;
    for I := IB to IE do
    begin
      if IE = IB then Percent := 100
      else Percent := Trunc(((I - IB) / (IE - IB)) * 100);
      if Percent <> OldPercent then
      begin
	OldPercent := Percent;
	FormatStr(S, ' %d  done', Percent);
	S[Length(S) - 5] := '%';
	LogEvent := 0;
	DrawStatusLine('Removing extra blanks:' + S);
      end;
      GetValidLine(I, S);
      TrailTrim(S);
      if UnformatLine(S, Editor, I, True, True) then ReplaceLine(I, S);
      if PSwapLinesCollection(FileLines)^.Status = coOverflow then
      begin
	PSwapLinesCollection(FileLines)^.Status := 0;
	Break;
      end;
      if (KbdStatus = 1) and AbortAction then Break;
    end;
    AddUndoChain;
    if IsSelected and not MarkColumns and Boolean(SelOnly) then
      if Area^.PK > 1 then
      begin
	GetValidLine(Area^.KK, S);
	TrailTrim(S);
	SetArea(Area, Area^.KB, 1, Area^.KK, Length(S) + 1);
      end
      else Area^.PB := 1;
    IsModified := True;
    DebugModified := True;
    DrawFlag := True;
    GoToPos(0, I + 1);
    DrawFlag := False;
  end;
end;

end.