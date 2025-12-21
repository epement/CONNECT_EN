{$I-,X+,O+,F+}
unit CNMacros;

interface

uses Objects, Drivers, Views;

const
  MacroJustRecorded: Boolean = False;

procedure NewMacroEvent(const Event: TEvent; DoStore: Boolean);
procedure GetMacroEvent(var Event: TEvent);
procedure ClearMacroEvents;

procedure SetMacroFileName(P: PString; var Name: FNameStr);
procedure SetMacroLocalName(var Name: FNameStr);
procedure ReadMacros(Name: FNameStr; var Macros: PCollection);
procedure MacroHotKey(var Event: TEvent);
procedure PreprocessKeyEvent(Macros: PCollection; var Event: TEvent);
procedure WaitForMacro;
procedure StartRecordingMacro;
procedure AddMacroKey(Key: Word);
procedure BreakRecordingMacro;
procedure StopRecordingMacro;

implementation

uses Dos, Memory, App, AppCmnd, Macros, MacroDlg, EditMsg, HotKeys,
  KeyDlg, DirPrim, Swaps, LFN, TPString, Commands, Defaults;

const
  RecordedMacro: PMacro = nil;

  MacroCollection: PCollection = nil;
  MacroColIndex: Integer = 0;
  MacroColPos: Word = 0;
  FreeMacroCol: Boolean = True;

procedure NewMacroEvent(const Event: TEvent; DoStore: Boolean);
var
  E, S: PEvent;
begin
  E := MemAlloc(SizeOf(TEvent));
  if E <> nil then
  begin
    if DoStore then
    begin
      S := MemAlloc(SizeOf(TEvent));
      if S = nil then Exit;
    end;
    E^ := Event;
    MacroEvents^.AtInsert(MacroEvents^.Index, E);
    Inc(MacroEvents^.Index);
    if DoStore then
    begin
      if MacroStorage = nil then
	MacroStorage := New(PEventCollection, Init(8, 8));
      S^ := Event;
      MacroStorage^.Insert(S);
    end;
  end;
end;

procedure GetMacroEvent(var Event: TEvent);
var
  I: Integer;
  Item: PEvent;
begin
  Item := MacroEvents^.At(0);
  if Item <> nil then
  begin
    Event := Item^;
    if (Item^.InfoWord > 0) and not
       ((Item^.What = evCommand) and (Item^.Command = cmPause)) then
      Dec(Item^.InfoWord)
    else MacroEvents^.AtFree(0);
  end
  else
  begin
    Event.What := evNothing;
    if (MacroRepeat > 0) and (MacroStorage <> nil) then
    begin
      MacroEvents^.Index := 0;
      for I := 0 to MacroStorage^.Count - 1 do
	NewMacroEvent(PEvent(MacroStorage^.At(I))^, False);
      Dec(MacroRepeat);
    end
    else ClearMacroEvents;
  end;
end;

procedure ClearMacroEvents;
begin
  if MacroStorage <> nil then Dispose(MacroStorage, Done);
  MacroStorage := nil;
  MacroRepeat := 0;
  DoneMacroEvents;
  InitMacroEvents;
  MacroRunning := False;
end;

procedure SetMacroFileName(P: PString; var Name: FNameStr);
begin
  if P <> nil then Name := lFExpand(P^)
  else SetCNConfigName(Name, 'MAC');
end;

procedure SetMacroLocalName(var Name: FNameStr);
var
  P: PString;
begin
  P := Message(Application, evBroadcast, cmGetMacroName, nil);
  if P <> nil then Name := CNFileName(P^)
  else SetMacroFileName(nil, Name);
end;

procedure ReadMacros(Name: FNameStr; var Macros: PCollection);
var
  Item: PMacro;
  S: TDosStream;
begin
  Name := CNFileName(Name);
  Macros := New(PCollection, Init(16, 16));
  LogEvent := lcDiskRead;
  DrawStatusLine('Loading macros from ' + TrimmedName(Name, 47) + '.');
  S.Init(Name, stOpenRead);
  if S.Status = stOk then
  begin
    while not LowMemory do
    begin
      Item := PMacro(S.Get);
      if S.Status <> stOk then
      begin
	CouldNotReadMsgBox(Name);
	Break;
      end
      else if Item = nil then Break;
      Macros^.Insert(Item);
    end;
  end;
  S.Done;
end;

procedure MacroHotKey(var Event: TEvent);
var
  Found: Boolean;
  KbdState: Byte;
  Key: Word;
  I: Integer;
  M: PMacro;
begin
  KbdState := GetShiftState;
  Key := Event.KeyCode;
  GlobalSequence[MacroColPos] := Key;
  Found := False;
  while MacroColIndex < MacroCollection^.Count do
  begin
    M := MacroCollection^.At(MacroColIndex);
    if M = nil then Break;
    if (MacroColPos = 0) and SameKey(Key, M^.HotKey) then
    begin
      Found := True;
      Break;
    end;
    if (M^.HotKey = hkSeq) and (MacroColPos < M^.HotKeyCount) and
      SameSequence(GlobalSequence, M^.HotKeySequence^, MacroColPos + 1) and
      HotKeyOptMatch(KbdState, M^.HotKeyOpt, MacroColPos) then
    begin
      if MacroColPos = M^.HotKeyCount - 1 then
      begin
	Found := True;
	Break;
      end;
      DrawSequenceStatusLine(MacroColPos);
      Inc(MacroColPos);
      Event.What := evNothing;
      Exit;
    end;
    Inc(MacroColIndex);
  end;
  if Found then with M^.Events^ do
  begin
    if MacroWaiting then MacroEvents^.Index := MacroEvents^.Count
    else MacroEvents^.Index := 0;
    for I := 0 to Count - 1 do
      NewMacroEvent(PEvent(At(I))^, False);
    MacroRunning := True;
    Event.What := evNothing;
  end
  else if not FreeMacroCol and
    (MacroColIndex >= MacroCollection^.Count) and
    (MacroColPos <> 0) then
  begin
    for I := 0 to MacroColPos do
    begin
      Event.What := evKeyDown;
      Event.KeyCode := GlobalSequence[I];
      Event.InfoPtr := nil;
      NewMacroEvent(Event, False);
    end;
    MacroRunning := True;
    Event.What := evNothing;
  end;
  if FreeMacroCol then Dispose(MacroCollection, Done);
  MacroCollection := nil;
  MacroColIndex := 0;
  MacroColPos := 0;
  FreeMacroCol := True;
  MacroCalled := False;
end;

procedure PreprocessKeyEvent(Macros: PCollection; var Event: TEvent);
begin
  if MacroRunning or MacroWaiting then Exit;
  MacroCalled := True;
  MacroCollection := Macros;
  FreeMacroCol := False;
  IdleSeconds := 0;
  MacroHotKey(Event);
end;

procedure WaitForMacro;
var
  S: FNameStr;
begin
  if MacroCollection = nil then
  begin
    SetMacroFileName(nil, S);
    ReadMacros(S, MacroCollection);
  end;
  if not MacroRunning or MacroWaiting then
  begin
    StatusLine^.Update;
    DrawStatusLine('Waiting for user macro hotkey.');
  end;
  MacroCalled := True;
end;

procedure StartRecordingMacro;
begin
  if MacroRecording then Exit;
  RecordedMacro := New(PMacro, Init);
  RecordKeys := True;
  RecordKeyProc := AddMacroKey;
  CtrlBreakHit := False;
  MacroRecording := True;
  StatusLine^.DrawView;
end;

procedure AddMacroKey(Key: Word);
var
  E: PEvent;
begin
  if (RecordedMacro = nil) or (Key= 0) or (Key = kbAltMinus) then Exit;
  E := RecordedMacro^.Events^.At(RecordedMacro^.Events^.Count - 1);
  if (E <> nil) and (E^.KeyCode = Key) and (E^.InfoLong < 65534) then
    Inc(E^.InfoWord)
  else
  begin
    E := MemAlloc(SizeOf(TEvent));
    if E <> nil then
    begin
      E^.What := evKeyDown;
      E^.KeyCode := Key;
      E^.InfoLong := 0;
      RecordedMacro^.Events^.Insert(E);
    end
    else
    begin
      BreakRecordingMacro;
      Application^.OutOfMemory;
    end;
  end;
end;

procedure BreakRecordingMacro;
begin
  RecordKeys := False;
  RecordKeyProc := DefRecordKeyProc;
  if RecordedMacro <> nil then Dispose(RecordedMacro, Done);
  RecordedMacro := nil;
  CtrlBreakHit := False;
  MacroRecording := False;
  StatusLine^.DrawView;
end;

procedure StopRecordingMacro;
var
  W: Word;
  L: Longint;
  S: TDosStream;
  F: File;
  Name: FNameStr;
begin
  if RecordedMacro = nil then Exit;
  if RecordedMacro^.Events^.Count <> 0 then
  begin
    RecordedMacro^.SetData('Untitled', 0);
    SetMacroLocalName(Name);
    Assign(F, Name);
    GetFAttr(F, W);
    if DosError = 0 then W := stOpenWrite else W := stCreate;
    S.Init(Name, W);
    L := S.GetSize;
    if L > 1 then Dec(L, 2);
    S.Seek(L);
    S.Put(RecordedMacro);
    S.Put(nil);
    if S.Status <> stOk then CouldNotWriteMsgBox(Name)
    else
    begin
      MacroJustRecorded := True;
      Pending.What := evCommand;
      Pending.Command := cmUserMacros;
    end;
    S.Done;
  end;
  BreakRecordingMacro;
end;

end.