{$F+,O+,X+}
unit EditTabl;

interface

uses FEditor;

const
  tlNo = 0;
  tlTop = 1;
  tlInside = 2;
  tlBottom = 3;

const
  TopCornerChars =
    ['Ú','¿',
     'Õ','¸',
     'Ö','·',
     'É','»'];
  InsideChars =
    ['³','Ã','Å','´','Â','Á',
	 'Æ','Ø','µ','Ñ','Ï',
     'º','Ç','×','¶','Ò','Ð',
	 'Ì','Î','¹','Ë','Ê'];
  BottomCornerChars =
    ['À','Ù',
     'Ô','¾',
     'Ó','½',
     'È','¼'];
  HorizChars = [' ','Ä','Í'];
  SingleHorizChars =
    ['Ä','Ú','Ö','Ã','Å','Â','Á','Ç','×','Ò','Ð','À','Ó'];
  DoubleHorizChars =
    ['Í','Õ','É','Æ','Ø','Ñ','Ï','Ì','Î','Ë','Ê','Ô','È'];
  SingleVertChars =
    ['Ú','¿','Õ','¸','³','Ã','Å','´','Â','Æ','Ø','µ','Ñ'];
  DoubleVertChars =
    ['Ö','·','É','»','º','Ç','×','¶','Ò','Ì','Î','¹','Ë'];
  SingleBottomChars =
    ['Á','Ï','À','Ù','Ô','¾'];
  DoubleBottomChars =
    ['Ð','Ê','Ó','½','È','¼'];
  AnyTableChars = TopCornerChars + InsideChars + BottomCornerChars;

function TableLine(const S: String): Byte;
function GetNextVertPos(Editor: PFileEditor;
  Index: Integer; APos: Byte; Back: Boolean): Byte;
procedure ExpandTableColumnPrim(Editor: PFileEditor;
  Index: Integer; APos: Byte; LineType: Byte);
procedure ShrinkTableColumnPrim(Editor: PFileEditor;
  Index: Integer; APos: Byte; LineType: Byte);
procedure ExpandTableRowPrim(Editor: PFileEditor;
  Index: Integer; APos: Byte; LineType: Byte; Force: Boolean;
  const Line: String; var Indent: Byte);

implementation

uses App, EditMsg, Swaps, Keyboard, Defaults;

function TableLine(const S: String): Byte;
var
  B, C: Byte;
begin
  B := tlNo;
  for C := 1 to Length(S) do
  begin
    if S[C] in TopCornerChars then B := tlTop
    else if S[C] in InsideChars then B := tlInside
    else if S[C] in BottomCornerChars then B := tlBottom;
    if B <> tlNo then Break;
  end;
  TableLine := B;
end;

procedure ExpandArea(Editor: PFileEditor; Index: Integer; APos: Byte);
begin
  with Editor^ do
    if IsSelected and not MarkColumns then
      if Selected(Index) then
      begin
	if Index = Area^.KB then
	  if APos < Area^.PB then
	    SetArea(Area, Area^.KB, Area^.PB + 1, Area^.KK, Area^.PK);
	if Index = Area^.KK then
	  if APos < Area^.PK then
	    SetArea(Area, Area^.KB, Area^.PB, Area^.KK, Area^.PK + 1);
      end;
end;

procedure ShrinkArea(Editor: PFileEditor; Index: Integer; APos: Byte);
begin
  with Editor^ do
    if IsSelected and not MarkColumns then
      if Selected(Index) then
      begin
	if Index = Area^.KB then
	  if APos < Area^.PB then Dec(Area^.PB);
	if Index = Area^.KK then
	  if APos < Area^.PK then Dec(Area^.PK);
      end;
end;

function GetNextVertPos(Editor: PFileEditor;
  Index: Integer; APos: Byte; Back: Boolean): Byte;
var
  B: Byte;
  S: String;
begin
  with Editor^ do
  begin
    GetValidLine(Index, S);
    B := APos;
    if Back then
    begin
      if B > Length(S) then B := Length(S) + 1;
      if B > 1 then Dec(B);
    end;
    repeat
      if Back then
      begin
	Dec(B);
	if B = 0 then Break;
      end
      else
      begin
	Inc(B);
	if (B = 0) or (B > Length(S)) then
	begin
	  B := Length(S) + 1;
	  Break;
	end;
      end;
      if S[B] in AnyTableChars then Break;
    until False;
  end;
  if not Back and (B > 0) then Dec(B);
  GetNextVertPos := B;
end;

procedure ExpandTableColumnPrim(Editor: PFileEditor;
  Index: Integer; APos: Byte; LineType: Byte);
var
  Abort: Boolean;
  B, T: Byte;
  I: Integer;
  S: String;

function NoExpanding: Boolean;
begin
  with Editor^.LastLine do
  begin
    B := APos + 1;
    while (B <> 0) and (B <= Length(Line)) and
      not (Line[B] in AnyTableChars) do Inc(B);
    if B <> 0 then Dec(B);
    if (B < Length(Line)) and (B > APos) and (Line[B] = ' ') then
    begin
      System.Delete(Line, B, 1);
      ShrinkArea(Editor, Index, B);
      NoExpanding := True;
    end
    else NoExpanding := False;
  end;
end;

function ExpandLine: Boolean;
var
  C: Char;
begin
  with Editor^ do
  begin
    GetValidLine(I, S);
    T := TableLine(S);
    if T = tlNo then
    begin
      ExpandLine := False;
      Exit;
    end;
    B := APos;
    while (B <> 0) and (B <= Length(S)) and
      not (S[B] in AnyTableChars) do Inc(B);
    if (B <> 0) and (B <= Length(S)) then
    begin
      if B = 1 then C := ' '
      else
      begin
	C := S[B - 1];
	if C in SingleHorizChars then C := 'Ä'
	else if C in DoubleHorizChars then C := 'Í'
	else C := ' ';
      end;
      System.Insert(C, S, B);
      ReplaceLine(I, S);
      ExpandArea(Editor, I, B);
    end;
  end;
  if (KbdStatus = 1) and AbortAction then Abort := True;
  ExpandLine := not Abort and (T = tlInside);
end;

begin
  with Editor^ do
  begin
    if NoExpanding then Exit;
    DrawStatusLine('Expanding the table column.');
    NewUndoChain(16);
    SaveLastLine;
    FastGetLine := True;
    Abort := False;
    if LineType <> tlTop then
    begin
      I := Index - 1;
      while (I >= 0) and ExpandLine do Dec(I);
    end;
    if not Abort and (LineType <> tlBottom) then
    begin
      I := Index + 1;
      while (I < FileLines^.Count) and ExpandLine do Inc(I);
    end;
    AddUndoChain;
  end;
end;

procedure ShrinkTableColumnPrim(Editor: PFileEditor;
  Index: Integer; APos: Byte; LineType: Byte);
var
  Abort: Boolean;
  B, T: Byte;
  I: Integer;
  S: String;

function CanShrinkLine: Boolean;
begin
  with Editor^ do
  begin
    GetValidLine(I, S);
    T := TableLine(S);
    if T <> tlNo then
    begin
      B := APos;
      while (B <> 0) and (B <= Length(S)) and
	not (S[B] in AnyTableChars) do Inc(B);
      if (B <> 0) and
	 ((B = 1) or (B > Length(S)) or not (S[B - 1] in HorizChars)) then
      begin
	CanShrinkLine := False;
	Exit;
      end;
    end;
  end;
  CanShrinkLine := True;
end;

function CanShrinkColumn: Boolean;
begin
  CanShrinkColumn := False;
  if LineType <> tlTop then
  begin
    T := LineType;
    I := Index - 1;
    while (I >= 0) and (T = tlInside) do
    begin
      if not CanShrinkLine or
	((KbdStatus = 1) and AbortAction) then Exit;
      Dec(I);
    end;
  end;
  if LineType <> tlBottom then
  begin
    T := LineType;
    I := Index + 1;
    while (I < Editor^.FileLines^.Count) and (T = tlInside) do
    begin
      if not CanShrinkLine or
	((KbdStatus = 1) and AbortAction) then Exit;
      Inc(I);
    end;
  end;
  CanShrinkColumn := True;
end;

procedure InsertJustChar;
var
  C: Char;
begin
  B := APos;
  with Editor^.LastLine do
  begin
    while (B <> 0) and (B <= Length(Line)) and
      not (Line[B] in AnyTableChars) do Inc(B);
    if (B <> 0) and (B <= Length(Line)) then
    begin
      if B = 1 then C := ' '
      else
      begin
	C := Line[B - 1];
	if not (C in HorizChars) then C := ' ';
      end;
      System.Insert(C, Line, B);
      ExpandArea(Editor, Index, B);
    end;
  end;
end;

function ShrinkLine: Boolean;
var
  C: Char;
begin
  with Editor^ do
  begin
    GetValidLine(I, S);
    T := TableLine(S);
    if T = tlNo then
    begin
      ShrinkLine := False;
      Exit;
    end;
    B := APos;
    while (B <> 0) and (B <= Length(S)) and
      not (S[B] in AnyTableChars) do Inc(B);
    if (B <> APos) and (B <= Length(S)) then Dec(B);
    System.Delete(S, B, 1);
    ReplaceLine(I, S);
    ShrinkArea(Editor, I, B);
  end;
  if (KbdStatus = 1) and AbortAction then Abort := True;
  ShrinkLine := not Abort and (T = tlInside);
end;

begin
  with Editor^ do
  begin
    FastGetLine := True;
    if not CanShrinkColumn then
    begin
      InsertJustChar;
      Exit;
    end;
    DrawStatusLine('Shrinking the table column.');
    NewUndoChain(16);
    SaveLastLine;
    Abort := False;
    if LineType <> tlTop then
    begin
      I := Index - 1;
      while (I >= 0) and ShrinkLine do Dec(I);
    end;
    if not Abort and (LineType <> tlBottom) then
    begin
      I := Index + 1;
      while (I < FileLines^.Count) and ShrinkLine do Inc(I);
    end;
    AddUndoChain;
  end;
end;

procedure ExpandTableRowPrim(Editor: PFileEditor;
  Index: Integer; APos: Byte; LineType: Byte; Force: Boolean;
  const Line: String; var Indent: Byte);
var
  B: Byte;
  S: String;

function NoExpanding: Boolean;
var
  L: Byte;
begin
  NoExpanding := False;
  B := APos - 1;
  while (B > 0) and not (Line[B] in SingleVertChars) and
    not (Line[B] in DoubleVertChars) do Dec(B);
  if B = 0 then Exit;
  L := B + 1;
  B := APos;
  while (B <> 0) and (B <= Length(Line)) and
    not (Line[B] in SingleVertChars) and
    not (Line[B] in DoubleVertChars) do Inc(B);
  if (B = 0) or (B > Length(Line)) then Exit;
  Editor^.GetValidLine(Index, S);
  if (L <= Length(S)) and not (S[L] in [#179..#218]) then
  begin
    Indent := L - 1;
    NoExpanding := True;
  end;
end;

begin
  if not Force and (LineType <> tlBottom) and NoExpanding then Exit;
  S[0] := Line[0];
  FillChar(S[1], Length(Line), ' ');
  Indent := 0;
  for B := 1 to Length(Line) do
  begin
    if ((LineType = tlBottom) and (Line[B] in SingleBottomChars)) or
       ((LineType <> tlBottom) and (Line[B] in SingleVertChars)) then
      S[B] := '³'
    else if ((LineType = tlBottom) and (Line[B] in DoubleBottomChars)) or
      ((LineType <> tlBottom) and (Line[B] in DoubleVertChars)) then
      S[B] := 'º'
    else Continue;
    if B < APos then Indent := B;
  end;
  Editor^.NewLine(Index, S);
end;

end.