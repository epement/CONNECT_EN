{$I-,F+,O+,X+}
unit ClipPrim;

interface

procedure DrawClipCopyStatus;
procedure DrawFMClipCopyStatus;
procedure DrawFindAllClipCopyStatus;
procedure DrawDBClipCopyStatus;
procedure DrawEnvClipCopyStatus;
procedure ExpandClipAreaTo(Len: Integer);
procedure SetOrExpandClipArea(Index, Len: Integer);
procedure GetClipLine(Index: Integer; var Line: String);
procedure PutClipLine(var Line: String);
procedure SetExpandClipAreaFlag;
function ClipOverflow: Boolean;
procedure PutLineToClipboard(P: Pointer);

implementation

uses Objects, Drivers, Views, App, EditMsg, Swaps, Commands, Defaults;

procedure DrawCopyToClipStatus(const S: String);
begin
  DrawStatusLine('Copying ' + S + ' into the Clipboard.');
end;

procedure DrawClipCopyStatus;
begin
  DrawCopyToClipStatus('the selected text');
end;

procedure DrawFMClipCopyStatus;
begin
  DrawCopyToClipStatus('the selected file names');
end;

procedure DrawFindAllClipCopyStatus;
begin
  DrawCopyToClipStatus('all found occurences');
end;

procedure DrawDBClipCopyStatus;
begin
  DrawCopyToClipStatus('database records text');
end;

procedure DrawEnvClipCopyStatus;
begin
  DrawCopyToClipStatus('the Environment variables');
end;

procedure ExpandClipAreaTo(Len: Integer);
begin
  if MarkColumns then
  begin
    if Len < ClipArea^.PK then Len := ClipArea^.PK;
    SetArea(ClipArea, ClipArea^.KB, 1, ClipLines^.Count - 1, Len);
  end
  else SetArea(
    ClipArea, ClipArea^.KB, ClipArea^.PB, ClipLines^.Count - 1, Len);
end;

procedure SetOrExpandClipArea(Index, Len: Integer);
begin
  if ExpandClipArea then
  begin
    ExpandClipAreaTo(Len);
    ExpandClipArea := False;
  end
  else SetArea(ClipArea, Index, 1, ClipLines^.Count - 1, Len);
end;

procedure GetClipLine(Index: Integer; var Line: String);
var
  MinX, MaxX: Integer;
  L: Longint;
begin
  if (DiskClipStream = nil) or not ClipAreaSelected or
     (Index >= ClipLines^.Count) then Line := ''
  else
  begin
    L := Longint(PSwapLinesCollection(ClipLines)^.ExtraAt(Index));
    if L = 0 then Line := ''
    else with DiskClipStream^ do
    begin
      Seek(L);
      Read(Line[0], 1);
      Read(Line[1], Byte(Line[0]));
    end;
    if MarkColumns then
    begin
      if ClipArea^.PB > ClipArea^.PK then
      begin
	MinX := ClipArea^.PK;
	MaxX := ClipArea^.PB;
      end
      else
      begin
	MinX := ClipArea^.PB;
	MaxX := ClipArea^.PK;
      end;
    end
    else
    begin
      if Index = ClipArea^.KB then MinX := ClipArea^.PB
      else MinX := 1;
      if Index = ClipArea^.KK then MaxX := ClipArea^.PK
      else MaxX := SizeOf(String);
    end;
    Line := Copy(Line, MinX, MaxX - MinX);
  end;
end;

procedure PutClipLine(var Line: String);
var
  L: Longint;
begin
  if DiskClipStream <> nil then
  begin
    if Line = '' then L := 0
    else with DiskClipStream^ do
    begin
      L := GetSize;
      Seek(L);
      Write(Line, Byte(Line[0]) + 1);
      if Status <> stOk then Exit;
    end;
    with ClipLines^ do
    begin
      Insert(Pointer(L));
      if ClipAreaSelected and ExpandClipArea then
	ExpandClipAreaTo(Length(Line) + 1)
      else SetArea(ClipArea, Count - 1, 1, Count - 1, Length(Line) + 1);
      ClipAreaSelected := True;
    end;
  end;
end;

procedure SetExpandClipAreaFlag;
var
  B: Byte;
begin
  B := GetShiftState;
  ExpandClipArea := (B and kbCtrlShift <> 0) and
    (B and (kbLeftShift + kbRightShift) <> 0);
end;

function ClipOverflow: Boolean;
begin
  if DiskClipStream^.Status <> stOk then
  begin
    DiskClipStream^.Reset;
    SwapWriteErrorMsgBox;
    ClipOverflow := True;
    Exit;
  end;
  if PSwapLinesCollection(ClipLines)^.Status = coOverflow then
  begin
    PSwapLinesCollection(ClipLines)^.Status := 0;
    Application^.OutOfMemory;
    ClipOverflow := True;
    Exit;
  end;
  ClipOverflow := False;
end;

procedure PutLineToClipboard(P: Pointer);
var
  S: String;
begin
  if DiskClipStream <> nil then
  begin
    S := PString(P)^;
    SetExpandClipAreaFlag;
    PutClipLine(S);
    ExpandClipArea := False;
    ClipOverflow;
    Message(Application, evBroadcast, cmUpdateViews, nil);
  end;
end;

end.