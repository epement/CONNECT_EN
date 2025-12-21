{$I-,F+,O+,X+}
unit EditClip;

interface

uses FEditor;

procedure CopyPrim(Editor: PFileEditor);
procedure ClearPrim(Editor: PFileEditor; DoMove, DoDraw: Boolean);
procedure PastePrim(Editor: PFileEditor);

implementation

uses Objects, Drivers, Views, App, Swaps, ClipPrim, Keyboard,
  Clipbrd, EditMsg, EditPrim, EditTabl, TPString, Commands, Defaults;

procedure CopyPrim(Editor: PFileEditor);
var
  I, SaveCount: Integer;
  SaveArea: TArea;
  S: String;
begin
  with Editor^ do
  begin
    if DiskClipStream = nil then Exit;
    SaveLastLine;
    DrawClipCopyStatus;
    SetExpandClipAreaFlag;
    SaveCount := ClipLines^.Count;
    SaveArea := Area^;
    if not IsSelected then
    begin
      I := Delta.Y + Cursor.Y;
      GetValidLine(I, S);
      Area^.KB := I;
      Area^.KK := I;
      Area^.PB := 1;
      I := Length(S);
      if I < 255 then Inc(I);
      Area^.PK := I;
    end;
    I := Area^.KB;
    FastGetLine := True;
    while I <= Area^.KK do
    begin
      GetSelectedString(I, S);
      PutClipLine(S);
      if ClipOverflow or ((KbdStatus = 1) and AbortAction) then Break;
      Inc(I);
    end;
    SetOrExpandClipArea(SaveCount, Length(S) + 1);
    if MarkColumns then SetArea(ClipArea, ClipArea^.KB, ClipArea^.PB,
      ClipArea^.KK, Area^.PK - Area^.PB + 1);
    Area^ := SaveArea;
    Message(Desktop, evBroadcast, cmUpdateViews, nil);
    EnableCommands(PasteCommands);
  end;
end;

procedure ClearPrim(Editor: PFileEditor; DoMove, DoDraw: Boolean);
begin
  with Editor^ do
  begin
    if Options and ofHex = 0 then
    begin
      SaveLastLine;
      NewUndoChain(Area^.KK - Area^.KB + 1);
    end;
    DrawStatusLine('Deleting the selected block.');
    if DoMove then CutBlock(Area) else DeleteBlock(Area);
    AddUndoChain;
    DrawFlag := True;
    GoToPos(Area^.PB - Byte(Options and ofHex = 0), Area^.KB);
    DrawFlag := False;
    Unselect;
    if DoDraw then DrawView;
  end;
end;

procedure PastePrim(Editor: PFileEditor);
var
  APos, InsPos: Byte;
  AnIndex, I, K, Count, EPos: Integer;
  StartLine, EndLine, InsLine, SplitLine: String;

procedure PasteToTable;
var
  B: Byte;
  SaveSel: Boolean;
  SavePos: TPoint;
  SaveArea: TArea;
label
  Quit;
begin
  with Editor^ do
  begin
    NewUndoChain(16);
    SavePos := UndoChain^.SavePos;
    SaveArea := UndoChain^.SaveArea;
    SaveSel := UndoChain^.SaveSel;
    K := ClipArea^.KB;
    EditorAborted := False;
    while (K <= ClipArea^.KK) and
      (PSwapLinesCollection(FileLines)^.Status <> coOverflow) do
    begin
      GetClipLine(K, InsLine);
      for B := 1 to Length(InsLine) do
      begin
	InsertCharPrim(
	  Editor, InsLine[B], Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1);
	if EditorAborted then Goto Quit;
      end;
      if K < ClipArea^.KK then EnterPrim(
	Editor, Delta.Y + Cursor.Y, Delta.X + Cursor.X + 1)
      else SaveLastLine;
      Inc(K);
    end;
Quit:
    UndoChain^.SavePos := SavePos;
    UndoChain^.SaveArea := SaveArea;
    UndoChain^.SaveSel := SaveSel;
  end;
end;

procedure OverwriteBlock;
begin
  with Editor^ do
  begin
    I := AnIndex;
    K := ClipArea^.KB;
    InsLine[0] := #0;
    InsPos := APos;
    NewUndoChain(ClipArea^.KK - ClipArea^.KB + 1);
    DrawStatusLine('Pasting the selected text from the Clipboard.');
    FastGetLine := True;
    while (K <= ClipArea^.KK) and
      (PSwapLinesCollection(FileLines)^.Status <> coOverflow) do
    begin
      GetValidLine(I, StartLine);
      GetClipLine(K, InsLine);
      if MarkColumns then PadSt(InsLine, ClipArea^.PK - ClipArea^.PB);
      if APos > Length(StartLine) then PadSt(StartLine, InsPos)
      else if not IsInsert then
	System.Delete(StartLine, InsPos, Length(InsLine));
      System.Insert(InsLine, StartLine, InsPos);
      ReplaceLine(I, StartLine);
      Inc(I);
      Inc(K);
      if not MarkColumns then InsPos := 1;
      if (KbdStatus = 1) and AbortAction then Break;
    end;
    if PSwapLinesCollection(FileLines)^.Status = coOverflow then
      PSwapLinesCollection(FileLines)^.Status := 0;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    if I > AnIndex + 1 then TopLine := MaxInt;
    if ClipArea^.KB = ClipArea^.KK then
    begin
      EPos := APos + Length(InsLine);
      if EPos > 255 then EPos := 255;
    end
    else EPos := InsPos + Length(InsLine);
    Highlight(AnIndex, APos,
      AnIndex + (ClipArea^.KK - ClipArea^.KB), EPos);
  end;
end;

label
  Quit;
begin
  with Editor^ do
  begin
    if (DiskClipStream = nil) or not ClipAreaSelected then Exit;

    if IncSearch then
    begin
      IncSearchFromClipboard(Editor);
      Exit;
    end;

    if IsSelected and (LocalEditOptions and eoOverwriteBlocks <> 0) then
      Clear(True, False);

    SaveLastLine;
    Message(Desktop, evBroadcast, cmUpdateViews, nil);
    AnIndex := Delta.Y + Cursor.Y;
    APos := Succ(Delta.X + Cursor.X);

    if IsInsert and (State and sfDrawing <> 0) then
    begin
      GetValidLine(AnIndex, StartLine);
      if TableLine(StartLine) <> tlNo then
      begin
	PasteToTable;
	Goto Quit;
      end;
    end;

    if not IsInsert or MarkColumns then
    begin
      OverwriteBlock;
      Goto Quit;
    end;

    GetClipLine(ClipArea^.KB, StartLine);
    GetClipLine(ClipArea^.KK, EndLine);
    I := 0;
    GetValidLine(AnIndex, InsLine);
    if APos > Byte(InsLine[0]) then PadSt(InsLine, APos - 1);
    SplitLine := System.Copy(InsLine, APos, 255);
    InsLine[0] := Char(APos - 1);
    if ClipArea^.KB = ClipArea^.KK then
      InsLine := Concat(InsLine, StartLine, SplitLine)
    else InsLine := Concat(InsLine, StartLine);
    NewUndoChain(ClipArea^.KK - ClipArea^.KB + 1);
    DrawStatusLine('Pasting the selected text from the Clipboard.');
    ReplaceLine(AnIndex, InsLine);
    EPos := APos + Byte(StartLine[0]);
    Count := ClipArea^.KK - ClipArea^.KB - 1;
    if Count > 0 then
    begin
      while (I < Count) and
	(PSwapLinesCollection(FileLines)^.Status <> coOverflow) do
      begin
	Inc(I);
	GetClipLine(ClipArea^.KB + I, InsLine);
	NewLine(AnIndex + I, InsLine);
	if (KbdStatus = 1) and AbortAction then Break;
      end;
    end;
    if PSwapLinesCollection(FileLines)^.Status = coOverflow then
      PSwapLinesCollection(FileLines)^.Status := 0
    else if ClipArea^.KB <> ClipArea^.KK then
    begin
      Inc(I);
      InsLine := Concat(EndLine, SplitLine);
      NewLine(AnIndex + I, InsLine);
      EPos := Byte(EndLine[0]) + 1;
    end;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    Unselect;
    Highlight(AnIndex, APos, AnIndex + I, EPos);
Quit:
    AddUndoChain;
    IsModified := True;
    DebugModified := True;
    if (NewLocalOptions and neoPasteGoesToEnd <> 0) and
      IsSelected then GoToPos(Area^.PK - 1, Area^.KK);
    DrawFlag := False;
    Indicator^.DrawView;
    DrawView;
  end;
end;

end.