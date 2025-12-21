{$F+,O+,X+}
unit CNHist;

interface

procedure CNHistoryStr(Id: Byte; Index: Integer;
  var S: String; var Offset: Byte);

implementation

uses HistList, History, TPString;

procedure CNHistoryStr(Id: Byte; Index: Integer;
  var S: String; var Offset: Byte);
var
  I: Integer;
begin
  S := HistoryStr(Id, Index);
  Offset := 1;
  case Id of
    SearchDirHistoryID, HistoryID, DirHistoryID, OptionsHistoryID,
    PathHistoryID, FPromptHistoryID, ReopenHistoryID, LogHistoryID,
    TermcapNameHistoryID, XLATNameHistoryID, PaletteHistoryID,
    PrnDeviceHistoryID, FontFileHistoryID, RedirHistoryID:
      begin
	Offset := Length(S);
	if Id = FPromptHistoryID then
	begin
	  I := Pos(' ', S);
	  if I <> 0 then Offset := I - 1;
	end;
	while (Offset > 0) and (S[Offset] <> '\') do Dec(Offset);
	Inc(Offset);
	if Offset > 1 then S := Copy(S, Offset, 255);
      end;
    FNameHistoryID:
      begin
	Offset := Length(S);
	while (Offset > 0) and (S[Offset] <> '\') do Dec(Offset);
	Inc(Offset);
	if Offset > 1 then
	begin
	  Dec(Offset);
	  I := Offset;
	  while (Offset > 0) and (S[Offset] = '\') do Dec(Offset);
	  while (Offset > 0) and (S[Offset] <> '\') do Dec(Offset);
	  Inc(Offset);
	  if Offset > 1 then S := Copy(S, Offset, I - Offset);
	end;
      end;
  end;
  UpcaseSt(S);
end;

end.