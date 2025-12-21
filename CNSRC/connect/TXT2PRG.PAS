uses Dos, Objects, TPString;

const
  hkSeq = $FFFF;
  MaxHotKeys = $40;

type
  TExecStr = String[255];

  PExecRec = ^TExecRec;
  TExecRec = record
    Path, Params, FileMask, LineMask: TExecStr;
    Main, Setup, Options: Word;
  end;

  PHotKeySequence = ^THotKeySequence;
  THotKeySequence = Array[0..MaxHotKeys - 1] of Word;

  PExecItem = ^TExecItem;
  TExecItem = object(TObject)
    Title, Path, Params, FileMask, LineMask: PString;
    Main, Setup, Options, HotKey: Word;
    HotKeyCount: Word;
    HotKeySequence: PHotKeySequence;
    HotKeyOpt: Word;
    HotKeyReserved: Pointer;
    destructor Done; virtual;
    procedure Store(var S: TStream); virtual;
    procedure SetData(const ATitle: String;
      AData: TExecRec; AHotKey: Word);
  end;

const
  RExecItem: TStreamRec = (
    ObjType: 1170;
    VmtLink: Ofs(TypeOf(TExecItem)^);
    Load:    nil;
    Store:   @TExecItem.Store
  );

destructor TExecItem.Done;
begin
  if HotKey = hkSeq then
    FreeMem(HotKeySequence, HotKeyCount * SizeOf(Word));
  DisposeStr(LineMask);
  DisposeStr(FileMask);
  DisposeStr(Params);
  DisposeStr(Path);
  DisposeStr(Title);
  TObject.Done;
end;

procedure TExecItem.Store(var S: TStream);
begin
  S.WriteStr(Title);
  S.WriteStr(Path);
  S.WriteStr(Params);
  S.WriteStr(FileMask);
  S.WriteStr(LineMask);
  S.Write(Main, SizeOf(Main) + SizeOf(Setup) +
    SizeOf(Options) + SizeOf(HotKey));
  if HotKey = hkSeq then
  begin
    S.Write(HotKeyCount, SizeOf(Word));
    S.Write(HotKeySequence^, HotKeyCount * SizeOf(Word));
    S.Write(HotKeyOpt, SizeOf(Word));
    S.Write(HotKeyReserved, SizeOf(Pointer));
  end;
end;

procedure TExecItem.SetData(const ATitle: String;
  AData: TExecRec; AHotKey: Word);
begin
  DisposeStr(LineMask);
  DisposeStr(FileMask);
  DisposeStr(Params);
  DisposeStr(Path);
  DisposeStr(Title);
  Title := NewStr(ATitle);
  Path := NewStr(AData.Path);
  Params := NewStr(AData.Params);
  FileMask := NewStr(AData.FileMask);
  LineMask := NewStr(AData.LineMask);
  Main := AData.Main;
  Setup := AData.Setup;
  Options := AData.Options;
  HotKey := AHotkey;
end;

var
  C, Count, Key: Word;
  Code: Integer;
  Stream: PDosStream;
  Item: PExecItem;
  F: Text;
  InName, OutName: FNameStr;
  S, Title: String;
  Sequence: THotKeySequence;
  R: TExecRec;

procedure Stop(const Msg: String; CloseInput, CloseOutput: Boolean);
begin
  if CloseInput then Dispose(Stream, Done);
  if CloseOutput then Close(F);
  Writeln(Msg);
  Halt(1);
end;

const
  UnexpectedMsg: String[30] = 'Unexpected end of source file.';
begin
  InName := ParamStr(1);
  if InName = '' then Stop('Source file not specified.', False, False);
  OutName := ParamStr(2);
  if OutName = '' then OutName := ForceExtension(InName, 'PRG');
  if FExpand(InName) = FExpand(OutName) then
    Stop('Source file and output file must differ.', False, False);
  Assign(F, InName);
  Reset(F);
  if IOResult <> 0 then Stop('Could not open source file.', False, False);
  Stream := New(PDosStream, Init(OutName, stCreate));
  if Stream^.Status <> stOk then
    Stop('Could not create output file.', True, False);

  RegisterType(RExecItem);
  New(Item, Init);
  repeat
    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 5)) = 'TITLE' then Break;
    until Eof(F);
    if Eof(F) then Break;
    Title := Copy(S, 7, 255);
    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 4)) = 'PATH' then Break;
    until Eof(F);
    if Eof(F) then Stop(UnexpectedMsg, True, True);
    R.Path := Copy(S, 6, 255);
    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 6)) = 'PARAMS' then Break;
    until Eof(F);
    if Eof(F) then Stop(UnexpectedMsg, True, True);
    R.Params := Copy(S, 8, 255);
    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 8)) = 'FILEMASK' then Break;
    until Eof(F);
    if Eof(F) then Stop(UnexpectedMsg, True, True);
    R.FileMask := Copy(S, 10, 255);
    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 8)) = 'LINEMASK' then Break;
    until Eof(F);
    if Eof(F) then Stop(UnexpectedMsg, True, True);
    R.LineMask := Copy(S, 10, 255);
    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 4)) = 'MAIN' then Break;
    until Eof(F);
    if Eof(F) then Stop(UnexpectedMsg, True, True);
    Val(Copy(S, 6, 255), R.Main, Code);
    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 5)) = 'SETUP' then Break;
    until Eof(F);
    if Eof(F) then Stop(UnexpectedMsg, True, True);
    Val(Copy(S, 7, 255), R.Setup, Code);
    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 7)) = 'OPTIONS' then Break;
    until Eof(F);
    if Eof(F) then Stop(UnexpectedMsg, True, True);
    Val(Copy(S, 9, 255), R.Options, Code);
    repeat
      Readln(F, S);
      if StUpcase(Copy(S, 1, 3)) = 'KEY' then Break;
    until Eof(F);
    if Eof(F) then Stop(UnexpectedMsg, True, True);
    if Pos('SEQUENCE:', StUpcase(S)) = 5 then
    begin
      Key := 0;
      Count := 0;
      C := 15;
      while C < Length(S) do
      begin
	Val(Copy(S, C, 5), Sequence[Count], Code);
	if Sequence[Count] = 0 then Break;
	Inc(C, 6);
	Inc(Count);
      end;
      if Count <> 0 then
      begin
	Key := hkSeq;
	Item^.HotKeyCount := Count;
	GetMem(Item^.HotKeySequence, Count * SizeOf(Word));
	Move(Sequence, Item^.HotKeySequence^, Count * SizeOf(Word));
      end;
    end
    else Val(Copy(S, 5, 255), Key, Code);
    Item^.SetData(Title, R, Key);
    Stream^.Put(Item);
    if Stream^.Status <> stOk then
      Stop('Error writing to output file.', True, True);
  until False;
  Close(F);
  Stream^.Put(nil);
  Dispose(Stream, Done);
end.