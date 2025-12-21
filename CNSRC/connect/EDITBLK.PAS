{$I-,F+,O+,X+}
unit EditBlk;

interface

uses Swaps, FEditor;

procedure CutBlockPrim(Editor: PFileEditor; AnArea: PArea);
procedure DeleteBlockPrim(Editor: PFileEditor; AnArea: PArea);
procedure InsertBlockPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
procedure MoveBlockPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
procedure TransferBlockPrim(Editor: PFileEditor;
  AnIndex: Integer; APos: Byte; JustCopy: Boolean);

implementation

uses Dos, Objects, Memory, App, EditMsg, Keyboard, TPString, Defaults;

procedure CutBlockPrim(Editor: PFileEditor; AnArea: PArea);
var
  I, N, Ind: Integer;
  Pos: TPos;
  SB, SE: String;

procedure CutColumns;
begin
  with Editor^ do
  begin
    I := AnArea^.KB;
    FastGetLine := True;
    while (I <= Area^.KK) and
      (PSwapLinesCollection(FileLines)^.Status <> coOverflow) do
    begin
      GetValidLine(I, SB);
      GetPos(AnArea, I, Pos);
      Delete(SB, Pos.AStart, Pos.AnEnd - Pos.AStart);
      ReplaceLine(I, SB);
      Inc(I);
      if (KbdStatus = 1) and AbortAction then Break;
    end;
    if PSwapLinesCollection(FileLines)^.Status = coOverflow then
      PSwapLinesCollection(FileLines)^.Status := 0;
    IsModified := True;
    DebugModified := True;
  end;
end;

begin
  with Editor^ do
  begin
    if IsSelected then
    begin
      if MarkColumns then
      begin
	CutColumns;
	Exit;
      end;
      N := 0;
      GetValidLine(AnArea^.KB, SB);
      GetPos(AnArea, AnArea^.KB, Pos);
      Delete(SB, Pos.AStart, Pos.AnEnd - Pos.AStart);
      ReplaceLine(AnArea^.KB, SB);
      if AnArea^.KK > AnArea^.KB then
      begin
	GetValidLine(AnArea^.KK, SE);
	GetPos(AnArea, AnArea^.KK, Pos);
	Delete(SE, 1, Pos.AnEnd - 1);
	if Length(SB) + Length(SE) > 255 then
	begin
	  ReplaceLine(AnArea^.KB, SB);
	  ReplaceLine(AnArea^.KK, SE);
	  N := 1;
	end
	else ReplaceLine(AnArea^.KB, SB + SE);
      end;
      if AnArea^.KK > AnArea^.KB then
      begin
	for I := AnArea^.KB + 1 to AnArea^.KK - N do
	begin
	  ClearLine(AnArea^.KB + 1);
	  if (KbdStatus = 1) and AbortAction then Break;
	end;
	DrawFlag := True;
	SetLimit(Limit.X, FileLines^.Count + Size.Y);
	DrawFlag := False;
      end;
      IsModified := True;
      DebugModified := True;
    end;
  end;
end;

procedure DeleteBlockPrim(Editor: PFileEditor; AnArea: PArea);
var
  I: Integer;
  Count: Word;
  Pos: TPos;
  Line: String;
begin
  with Editor^ do
  begin
    if IsSelected then
    begin
      I := AnArea^.KB;
      FastGetLine := True;
      while (I <= Area^.KK) and
	(PSwapLinesCollection(FileLines)^.Status <> coOverflow) do
      begin
	GetValidLine(I, Line);
	GetPos(AnArea, I, Pos);
	Count := Pos.AnEnd - Pos.AStart;
	if Pos.AStart > Length(Line) then Count := 0
	else if Pos.AnEnd > Length(Line) then
	  Count := Length(Line) - Pos.AStart + 1;
	if Count > 0 then
	begin
	  FillChar(Line[Pos.AStart], Count, ' ');
	  ReplaceLine(I, Line);
	end;
	Inc(I);
	if (KbdStatus = 1) and AbortAction then Break;
      end;
      if PSwapLinesCollection(FileLines)^.Status = coOverflow then
	PSwapLinesCollection(FileLines)^.Status := 0;
      IsModified := True;
      DebugModified := True;
    end;
  end;
end;

procedure InsertBlockPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
var
  InsPos: Byte;
  I, K, M, N, EPos: Integer;
  P: Pointer;
  R: PUndoRec;
  StartLine, EndLine, InsLine, SplitLine: String;

procedure OverwriteBlock;
begin
  with Editor^ do
  begin
    I := AnIndex;
    K := Area^.KB;
    InsLine[0] := #0;
    InsPos := APos;
    NewUndoChain(Area^.KK - Area^.KB + 1);
    FastGetLine := True;
    while (K <= Area^.KK) and
      (PSwapLinesCollection(FileLines)^.Status <> coOverflow) do
    begin
      GetValidLine(I, StartLine);
      GetSelectedString(K, InsLine);
      if MarkColumns then PadSt(InsLine, Area^.PK - Area^.PB);
      if InsPos > Length(StartLine) then PadSt(StartLine, InsPos)
      else if not IsInsert then
	System.Delete(StartLine, InsPos, Length(InsLine));
      System.Insert(InsLine, StartLine, InsPos);
      ReplaceLine(I, StartLine);
      Inc(I);
      Inc(K);
      if not MarkColumns then InsPos := 1;
      if (KbdStatus = 1) and AbortAction then Break;
    end;
    AddUndoChain;
    if PSwapLinesCollection(FileLines)^.Status = coOverflow then
      PSwapLinesCollection(FileLines)^.Status := 0;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    DrawFlag := False;
    if I > AnIndex + 1 then TopLine := MaxInt;
    if Area^.KB = Area^.KK then
    begin
      EPos := APos + Length(InsLine);
      if EPos > 255 then EPos := 255;
    end
    else EPos := InsPos + Length(InsLine);
    IsSelected := False;
    Highlight(AnIndex, APos, AnIndex + (Area^.KK - Area^.KB), EPos);
    IsModified := True;
    DebugModified := True;
  end;
end;

begin
  with Editor^ do
  begin
    SaveLastLine;
    if not IsInsert or MarkColumns then
      DrawStatusLine('Overwriting text with the selected block.')
    else DrawStatusLine('Inserting the selected block.');
    if (AnIndex > Area^.KB) and
       ((AnIndex < Area^.KK) or
	((AnIndex = Area^.KK) and (Area^.KB < Area^.KK))) then
    begin
      TransferBlockPrim(Editor, AnIndex, APos, True);
      Exit;
    end;
    if not IsInsert or MarkColumns then
    begin
      OverwriteBlock;
      Exit;
    end;
    GetSelectedString(Area^.KB, StartLine);
    GetSelectedString(Area^.KK, EndLine);
    GetValidLine(AnIndex, InsLine);
    if APos > Byte(InsLine[0]) then PadSt(InsLine, APos - 1);
    SplitLine := System.Copy(InsLine, APos, 255);
    InsLine[0] := Char(APos - 1);
    if Area^.KB = Area^.KK then
      InsLine := Concat(InsLine, StartLine, SplitLine)
    else InsLine := Concat(InsLine, StartLine);
    NewUndoChain(Area^.KK - Area^.KB + 1);
    ReplaceLine(AnIndex, InsLine);
    EPos := APos + Byte(StartLine[0]);
    I := 0;
    K := AnIndex + 1;
    M := Area^.KB + 1;
    N := 0;
    while M < Area^.KK do
    begin
      with PSwapLinesCollection(FileLines)^ do
      begin
	if Status = coOverflow then
	begin
	  Application^.OutOfMemory;
	  Break;
	end;
	P := ExtraAt(M + N);
	ExtraAtInsert(K, P);
	UpdatePlaces(K, unIns);
      end;
      if UndoChain <> nil then
      begin
	R := MemAlloc(SizeOf(TUndoRec));
	if R <> nil then
	begin
	  R^.Address := Longint(P);
	  R^.Index := K;
	  R^.Action := unDel;
	  UndoChain^.Insert(R);
	end
	else
	begin
	  Application^.OutOfMemory;
	  Break;
	end;
      end;
      Inc(I);
      Inc(K);
      Inc(M);
      if M >= K then Inc(N);
      if (KbdStatus = 1) and AbortAction then Break;
    end;
    if PSwapLinesCollection(FileLines)^.Status = coOverflow then
      PSwapLinesCollection(FileLines)^.Status := 0
    else if Area^.KB <> Area^.KK then
    begin
      Inc(I);
      InsLine := Concat(EndLine, SplitLine);
      NewLine(AnIndex + I, InsLine);
      EPos := Byte(EndLine[0]) + 1;
    end;
    AddUndoChain;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    DrawFlag := False;
    if I > 1 then TopLine := MaxInt;
    IsSelected := False;
    Highlight(AnIndex, APos, AnIndex + I, EPos);
    IsModified := True;
    DebugModified := True;
  end;
end;

procedure SetTempFileName(var S: FNameStr);
begin
  GetValidSwapDir(S, False);
  S := S + TempName + '.!!!';
end;

procedure EraseTempFile(const S: FNameStr);
var
  F: File;
begin
  Assign(F, S);
  Erase(F);
  InOutRes := 0;
end;

procedure MoveBlockPrim(Editor: PFileEditor; AnIndex: Integer; APos: Byte);
var
  WriteError: Boolean;
  SaveCount, EndPos, NewY: Integer;
  SaveOpt: Longint;
  S: FNameStr;
  Line: String;
begin
  with Editor^ do
  begin
    DrawStatusLine('Moving the selected block and deleting the gap.');
    SaveLastLine;
    SetTempFileName(S);
    SaveOpt := LocalEditOptions;
    LocalEditOptions := LocalEditOptions and not eoUseTabs;
    WriteError := not WriteBlock(S, False);
    LocalEditOptions := SaveOpt;
    if WriteError then Exit;
    SaveCount := FileLines^.Count;
    GetValidLine(Delta.Y + Cursor.Y, Line);
    EndPos := Length(Line) - (Delta.X + Cursor.X);
    NewUndoChain(Area^.KK - Area^.KB + 1);
    CutBlock(Area);
    DrawFlag := True;
    if (Delta.Y + Cursor.Y > Area^.KB) or
       ((Delta.Y + Cursor.Y = Area^.KB) and
       (Delta.X + Cursor.X >= Area^.PB)) then
    begin
      if MarkColumns then
      begin
	if Delta.Y + Cursor.Y <= Area^.KK then
	  if Delta.X + Cursor.X >= Area^.PK then
	    Dec(Cursor.X, Area^.PK - Area^.PB)
	  else if Delta.X + Cursor.X >= Area^.PB then
	    Cursor.X := Area^.PB - Delta.X - 1;
      end
      else
      begin
	if (Delta.Y + Cursor.Y < Area^.KK) or
	   ((Delta.Y + Cursor.Y = Area^.KK) and
	   (Delta.X + Cursor.X < Area^.PK)) then
	 GoToPos(Area^.PB - 1, Area^.KB)
	 else
	 begin
	   NewY := Delta.Y + Cursor.Y - (SaveCount - FileLines^.Count);
	   GetValidLine(NewY, Line);
	   if (Delta.Y + Cursor.Y = Area^.KK) and
	      (Delta.X + Cursor.X >= Area^.PK) then
	     GoToPos(Length(Line) - EndPos, NewY)
	   else GoToPos(Delta.X + Cursor.X, NewY)
	 end;
      end;
    end;
    DrawFlag := False;
    SaveOpt := NewLocalOptions;
    NewLocalOptions := NewLocalOptions and not neoPasteGoesToEnd;
    ReadBlock(S, True);
    NewLocalOptions := SaveOpt;
    AddUndoChain;
    EraseTempFile(S);
  end;
end;

procedure TransferBlockPrim(Editor: PFileEditor;
  AnIndex: Integer; APos: Byte; JustCopy: Boolean);
var
  WriteError: Boolean;
  SaveOpt: Longint;
  S: FNameStr;
begin
  with Editor^ do
  begin
    if not JustCopy then DrawStatusLine(
      'Moving the selected block and clearing the space.');
    SaveLastLine;
    SetTempFileName(S);
    SaveOpt := LocalEditOptions;
    LocalEditOptions := LocalEditOptions and not eoUseTabs;
    WriteError := not WriteBlock(S, False);
    LocalEditOptions := SaveOpt;
    if WriteError then Exit;
    NewUndoChain(Area^.KK - Area^.KB + 1);
    if not JustCopy then DeleteBlock(Area);
    SaveOpt := NewLocalOptions;
    NewLocalOptions := NewLocalOptions and not neoPasteGoesToEnd;
    ReadBlock(S, True);
    NewLocalOptions := SaveOpt;
    AddUndoChain;
    EraseTempFile(S);
  end;
end;

end.