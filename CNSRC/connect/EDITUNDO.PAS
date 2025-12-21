{$I-,F+,O+,X+}
unit EditUndo;

interface

uses Objects, FEDitor;

procedure SwapWritePrim(var S: PStream; APos: Longint; var Buf; Count: Word);
procedure UndoPrim(Editor: PFileEditor);
procedure RedoPrim(Editor: PFileEditor);
procedure UndoErrorPrim(Editor: PFileEditor);
procedure AddUndoChainPrim(Editor: PFileEditor);
procedure AddRedoChainPrim(Editor: PFileEditor);

implementation

uses Dos, Drivers, Views, Memory, MsgBox, App, Swaps, Disks, EditMsg,
  Keyboard, Commands, Defaults;

procedure SwapWritePrim(var S: PStream; APos: Longint; var Buf; Count: Word);
var
  SaveStatus: Integer;
  Size: Longint;
  SaveMsg: FNameStr;
begin
  SaveStatus := S^.Status;
  S^.Reset;
  Size := S^.GetSize;
{  if Size + $8000 > FreeDiskSpace(Byte(Upcase(DiskSwapName[1])) - $40) then}
  if Size + $8000 > FreeDiskSpace(DiskSwapName) then
  begin
    S^.Status := SaveStatus;
    Exit;
  end;
  InitDiskSwapStream(DiskSwapName, False);
  if DiskSwapStream = nil then
  begin
    S^.Status := SaveStatus;
    DiskSwapStream := S;
    Exit;
  end;
  SaveMsg := StatusLine^.StatusMsg;
  LogEvent := lcDiskWrite;
  DrawStatusLine('Swapping memory to disk.');
  S^.Seek(0);
  DiskSwapStream^.Seek(0);
  DiskSwapStream^.CopyFrom(S^, Size);
  if APos <> -1 then DiskSwapStream^.Seek(APos);
  DiskSwapStream^.Write(Buf, Count);
  DrawStatusLine(SaveMsg);
  if (S^.Status <> stOk) or (DiskSwapStream^.Status <> stOk) then
  begin
    DoneDiskSwapStream;
    S^.Status := SaveStatus;
    DiskSwapStream := S;
    Exit;
  end;
  Dispose(S, Done);
  S := DiskSwapStream;
  Message(Desktop, evBroadcast, cmNewSwapStream, S);
end;

procedure UndoPrim(Editor: PFileEditor);
var
  Aborted: Boolean;
  I, RCount: Integer;
  U: PUndoChain;
  UR, RR: PUndoRec;
begin
  with Editor^ do
  begin
    SaveLastLine;
    U := GetUndoChain;
    if U = nil then Exit;
    if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
       ((Delta.X + Cursor.X <> U^.SavePos.X) or
	(Delta.Y + Cursor.Y <> U^.SavePos.Y)) then
      GoToPos(U^.SavePos.X, U^.SavePos.Y)
    else NewUndoChain(U^.Count);
    if UndoChain = nil then
    begin
      Dispose(U, Done);
      Exit;
    end;
    DrawStatusLine('Undoing the previous editor operation.');
    Aborted := False;
    for I := U^.Count - 1 downto 0 do
    begin
      RR := MemAlloc(SizeOf(TUndoRec));
      if RR = nil then
      begin
	Dispose(U, Done);
	UndoError;
	Exit;
      end;
      UR := U^.At(I);
      if UR = nil then
      begin
	FreeMem(RR, SizeOf(TUndoRec));
	Dispose(U, Done);
	UndoError;
	Exit;
      end;
      RR^.Address :=
	Longint(PSwapLinesCollection(FileLines)^.ExtraAt(UR^.Index));
      RR^.Index := UR^.Index;
      if UR^.Action = unDel then RR^.Action := unIns
      else if UR^.Action = unIns then RR^.Action := unDel
      else RR^.Action := unRep;
      RCount := UndoChain^.Count;
      UndoChain^.Insert(RR);
      if RCount = UndoChain^.Count then
      begin
	FreeMem(RR, SizeOf(TUndoRec));
	Dispose(U, Done);
	UndoError;
	Exit;
      end;
      if UR^.Action <> unIns then
      begin
	PSwapLinesCollection(FileLines)^.ExtraAtFree(UR^.Index);
	UpdatePlaces(UR^.Index, unDel);
      end;
      if UR^.Action <> unDel then
      begin
	PSwapLinesCollection(FileLines)^.ExtraAtInsert(
	  UR^.Index, Pointer(UR^.Address));
	UpdatePlaces(UR^.Index, unIns);
      end;
      U^.AtFree(I);
      if (KbdStatus = 1) and AbortAction then
      begin
	Aborted := True;
	Break;
      end;
    end;
    UndoList^.AtFree(UndoList^.Count - 1);
    AddRedoChain;
    if UndoList^.Count = 0 then DisableCommands(UndoCommands);
    IsModified := Aborted or (UndoCount <> 0);
    DebugModified := IsModified;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    GoToPos(U^.SavePos.X, U^.SavePos.Y);
    DrawFlag := False;
    if U^.SaveSel then Highlight(
      U^.SaveArea.KB, U^.SaveArea.PB, U^.SaveArea.KK, U^.SaveArea.PK)
    else
    begin
      Unselect;
      Area^ := U^.SaveArea;
    end;
    Dispose(U, Done);
    TopLine := MaxInt;
    DrawView;
    Indicator^.DrawView;
    ClearKbd;
  end;
end;

procedure RedoPrim(Editor: PFileEditor);
var
  Aborted: Boolean;
  I, UCount: Integer;
  R: PUndoChain;
  UR, RR: PUndoRec;
begin
  with Editor^ do
  begin
    SaveLastLine;
    R := GetRedoChain;
    if R = nil then Exit;
    if (GetShiftState and (kbLeftShift + kbRightShift) <> 0) and
       ((Delta.X + Cursor.X <> R^.SavePos.X) or
	(Delta.Y + Cursor.Y <> R^.SavePos.Y)) then
      GoToPos(R^.SavePos.X, R^.SavePos.Y)
    else NewUndoChain(R^.Count);
    if UndoChain = nil then
    begin
      Dispose(R, Done);
      Exit;
    end;
    DrawStatusLine('Redoing the previously undone editor operation.');
    Aborted := False;
    for I := R^.Count - 1 downto 0 do
    begin
      UR := MemAlloc(SizeOf(TUndoRec));
      if UR = nil then
      begin
	Dispose(R, Done);
	UndoError;
	Exit;
      end;
      RR := R^.At(I);
      if RR = nil then
      begin
	FreeMem(UR, SizeOf(TUndoRec));
	Dispose(R, Done);
	UndoError;
	Exit;
      end;
      UR^.Address :=
	Longint(PSwapLinesCollection(FileLines)^.ExtraAt(RR^.Index));
      UR^.Index := RR^.Index;
      if RR^.Action = unDel then UR^.Action := unIns
      else if RR^.Action = unIns then UR^.Action := unDel
      else UR^.Action := unRep;
      UCount := UndoChain^.Count;
      UndoChain^.Insert(UR);
      if UCount = UndoChain^.Count then
      begin
	FreeMem(UR, SizeOf(TUndoRec));
	Dispose(R, Done);
	UndoError;
	Exit;
      end;
      if RR^.Action <> unIns then
      begin
	PSwapLinesCollection(FileLines)^.ExtraAtFree(RR^.Index);
	UpdatePlaces(RR^.Index, unDel);
      end;
      if RR^.Action <> unDel then
      begin
	PSwapLinesCollection(FileLines)^.ExtraAtInsert(
	  RR^.Index, Pointer(RR^.Address));
	UpdatePlaces(RR^.Index, unIns);
      end;
      R^.AtFree(I);
      if (KbdStatus = 1) and AbortAction then
      begin
	Aborted := True;
	Break;
      end;
    end;
    RedoList^.AtFree(RedoList^.Count - 1);
    AddUndoChain;
    if RedoList^.Count = 0 then DisableCommands(RedoCommands);
    IsModified := Aborted or (UndoCount <> 0);
    DebugModified := IsModified;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    GoToPos(R^.SavePos.X, R^.SavePos.Y);
    DrawFlag := False;
    if R^.SaveSel then Highlight(
      R^.SaveArea.KB, R^.SaveArea.PB, R^.SaveArea.KK, R^.SaveArea.PK)
    else
    begin
      Unselect;
      Area^ := R^.SaveArea;
    end;
    Dispose(R, Done);
    TopLine := MaxInt;
    DrawView;
    Indicator^.DrawView;
    ClearKbd;
  end;
end;

procedure UndoErrorPrim(Editor: PFileEditor);
begin
  with Editor^ do
  begin
    if UndoChain <> nil then Dispose(UndoChain, Done);
    UndoChain := nil;
    UndoList^.FreeAll;
    RedoList^.FreeAll;
    DisableCommands(UndoCommands + RedoCommands);
    MessageBox(^C'Undo/Redo buffer is full.', nil, mfWarning + mfOkButton);
    DrawStatusLine('Trying to complete operation.');
  end;
end;

procedure AddUndoChainPrim(Editor: PFileEditor);
var
  L: Longint;
begin
  with Editor^ do if UndoChain <> nil then
  begin
    if UndoChain^.NestedCount <> 0 then
    begin
      Dec(UndoChain^.NestedCount);
      Exit;
    end;
    with SwapStream^ do
    begin
      L := GetSize;
      Seek(L);
      Put(UndoChain);
      if Status <> stOk then
      begin
	Reset;
	UndoError;
	Exit;
      end;
    end;
    Dispose(UndoChain, Done);
    UndoChain := nil;
    UndoList^.Insert(Pointer(L));
    if PSwapLinesCollection(UndoList)^.Status = coOverflow then
    begin
      PSwapLinesCollection(UndoList)^.Status := 0;
      UndoError;
    end
    else
    begin
      if State and sfFocused <> 0 then EnableCommands(UndoCommands);
      Inc(UndoCount);
    end;
  end;
end;

procedure AddRedoChainPrim(Editor: PFileEditor);
var
  L: Longint;
begin
  with Editor^ do
  begin
    if UndoChain = nil then Exit;
    with SwapStream^ do
    begin
      L := GetSize;
      Seek(L);
      Put(UndoChain);
      if Status <> stOk then
      begin
	Reset;
	UndoError;
	Exit;
      end;
    end;
    Dispose(UndoChain, Done);
    UndoChain := nil;
    RedoList^.Insert(Pointer(L));
    if PSwapLinesCollection(RedoList)^.Status = coOverflow then
    begin
      PSwapLinesCollection(RedoList)^.Status := 0;
      UndoError;
    end
    else
    begin
      if State and sfFocused <> 0 then EnableCommands(RedoCommands);
      Dec(UndoCount);
    end;
  end;
end;

end.