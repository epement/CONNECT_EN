{$I-,F+,O+,X+}
unit EditConv;

interface

uses FEditor;

const
  cvUpcase = 0;
  cvLocase = 1;
  cvLatin  = 2;
  cvRus    = 3;
  cvTable  = 4;
  cvFTable = 5;
  cvCaps   = 6;
  cvShort  = 7;
  cvLong   = 8;

procedure ConvertBlockPrim(Editor: PFileEditor; Action: Byte);
procedure ConvertToVolapyukPrim(Editor: PFileEditor; Back: Boolean);

implementation

uses Objects, Drivers, Dialogs, App, Swaps, Keyboard, EditFile, EditMsg, LFN,
  TPString, Defaults;

procedure ConvertBlockPrim(Editor: PFileEditor; Action: Byte);
var
  B: Byte;
  Changed, UseLineSel: Boolean;
  C: Char;
  I, IB, IE: Integer;
  Pos: TPos;
  F: File;
  S, SubS: String;
  T: ConvertTable;
begin
  if (Action in [cvTable, cvFTable]) and
    not GetConvertTable(T, Action = cvFTable, Changed) then Exit;
  if Action in [cvLatin, cvRus] then
  begin
    for C := #0 to #255 do T[C] := C;
    if Action = cvLatin then
    begin
      Move(TByteArray(GetStrAddr(LoChars)^)[1], T[#128], Length(LoChars));
      Move(TByteArray(GetStrAddr(HiChars)^)[1], T[#224], Length(HiChars));
    end
    else Move(TByteArray(GetStrAddr(RuChars)^)[1], T[#34], Length(RuChars));
  end;
  Changed := False;
  UseLineSel := not (Action in [cvShort, cvLong]);
  with Editor^ do
  begin
    SaveLastLine;
    if IsSelected then
    begin
      IB := Area^.KB;
      if Area^.PK = 1 then IE := Area^.KK - 1
      else IE := Area^.KK;
    end
    else
    begin
      IB := Delta.Y + Cursor.Y;
      IE := IB;
    end;
    FastGetLine := True;
    for I := IB to IE do
    begin
      GetValidLine(I, S);
      if IsSelected and UseLineSel then
      begin
	GetPos(Area, I, Pos);
	SubS := System.Copy(S, Pos.AStart, Pos.AnEnd - Pos.AStart);
      end
      else SubS := S;
      if SubS <> '' then
      begin
	case Action of
	  cvUpcase: UpcaseSt(SubS);
	  cvLocase: LocaseSt(SubS);
	  cvCaps: for B := 1 to Length(SubS) do
	    begin
	      if B = 1 then
		if not IsSelected or (Pos.AStart = 1) then C := #0
		else C := S[Pos.AStart - 1]
	      else C := SubS[B - 1];
	      if (C = #0) or (C in LocalWordDelims) then
		SubS[B] := TPString.Upcase(SubS[B]);
	    end;
	  cvShort: lGetShortFileName(SubS, SubS);
	  cvLong: lGetLongFileName(SubS, SubS);
	  else for B := 1 to Length(SubS) do SubS[B] := T[SubS[B]];
	end;
	if IsSelected and UseLineSel then
	  Move(SubS[1], S[Pos.AStart], Length(SubS))
	else S := SubS;
	if not Changed and (UndoChain = nil) then
	begin
	  NewUndoChain(IE - IB + 1);
	  DrawStatusLine('Converting text characters.');
	end;
	ReplaceLine(I, S);
	Changed := True;
	if IsSelected and not MarkColumns and (I = Area^.KK) and
	  not UseLineSel then SetArea(
	    Area, Area^.KB, Area^.PB, Area^.KK, Length(S) + 1);
	if PSwapLinesCollection(FileLines)^.Status = coOverflow then
	begin
	  PSwapLinesCollection(FileLines)^.Status := 0;
	  Break;
	end;
      end;
      if (KbdStatus = 1) and AbortAction then Break;
    end;
    if not Changed then Exit;
    AddUndoChain;
    IsModified := True;
    DebugModified := True;
  end;
end;

procedure ConvertToVolapyukPrim(Editor: PFileEditor; Back: Boolean);
var
  Changed, X: Boolean;
  B, L: Byte;
  C, PC, NC, NNC: Char;
  I, IB, IE: Integer;
  Pos: TPos;
  SS: String[3];
  S: String;
begin
  Changed := False;
  X := GetShiftState and (kbLeftShift + kbRightShift) <> 0;
  with Editor^ do
  begin
    SaveLastLine;
    if IsSelected then
    begin
      IB := Area^.KB;
      if Area^.PK = 1 then IE := Area^.KK - 1
      else IE := Area^.KK;
    end
    else
    begin
      IB := Delta.Y + Cursor.Y;
      IE := IB;
    end;
    FastGetLine := True;
    for I := IB to IE do
    begin
      GetValidLine(I, S);
      L := Length(S);
      if IsSelected then GetPos(Area, I, Pos)
      else
      begin
	Pos.AStart := 1;
	Pos.AnEnd := L + 1;
      end;
      if Pos.AStart <= Length(S) then
      begin
	while (Pos.AStart <= Length(S)) and (Pos.AStart < Pos.AnEnd) do
	begin
	  C := S[Pos.AStart];
	  if Pos.AStart < Length(S) then NC := S[Pos.AStart + 1]
	  else NC := ' ';
	  if Pos.AStart > 1 then PC := S[Pos.AStart - 1]
	  else PC := ' ';
	  if Pos.AStart < Length(S) - 1 then NNC := S[Pos.AStart + 2]
	  else NNC := ' ';
	  if Back then SS := VolapyukStrToStr(C, PC, NC, NNC, B, X)
	  else SS := StrToVolapyukStr(C, PC, NC, NNC, B, X);
	  System.Delete(S, Pos.AStart, B);
	  System.Insert(SS, S, Pos.AStart);
	  Inc(Pos.AStart, Length(SS));
	  if Length(SS) > B then Inc(Pos.AnEnd, Length(SS) - B)
	  else if B > Length(SS) then Inc(Pos.AnEnd, B - Length(SS));
	end;
	if not Changed and (UndoChain = nil) then
	begin
	  NewUndoChain(IE - IB + 1);
	  if Back then DrawStatusLine('Restoring text from Volapyuk.')
	  else DrawStatusLine('Converting text to Volapyuk.');
	end;
	ReplaceLine(I, S);
	Changed := True;
	if IsSelected and not MarkColumns and (I = Area^.KK) then
	  SetArea(Area, Area^.KB, Area^.PB, Area^.KK,
	    Area^.PK + Length(S) - L);
	if PSwapLinesCollection(FileLines)^.Status = coOverflow then
	begin
	  PSwapLinesCollection(FileLines)^.Status := 0;
	  Break;
	end;
      end;
      if (KbdStatus = 1) and AbortAction then Break;
    end;
    if not Changed then Exit;
    AddUndoChain;
    IsModified := True;
    DebugModified := True;
  end;
end;

end.
