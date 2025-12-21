uses Dos, Objects, TPString;

const
  hkSeq = $FFFF;
  MaxHotKeys = $40;

type
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
    constructor Load(var S: TStream);
    destructor Done; virtual;
  end;

const
  RExecItem: TStreamRec = (
    ObjType: 1170;
    VmtLink: Ofs(TypeOf(TExecItem)^);
    Load:    @TExecItem.Load;
    Store:   nil
  );

constructor TExecItem.Load(var S: TStream);
begin
  TObject.Init;
  Title := S.ReadStr;
  Path := S.ReadStr;
  Params := S.ReadStr;
  FileMask := S.ReadStr;
  LineMask := S.ReadStr;
  S.Read(Main, SizeOf(Main) + SizeOf(Setup) +
    SizeOf(Options) + SizeOf(HotKey));
  if HotKey = hkSeq then
  begin
    S.Read(HotKeyCount, SizeOf(Word));
    GetMem(HotKeySequence, HotKeyCount * SizeOf(Word));
    S.Read(HotKeySequence^, HotKeyCount * SizeOf(Word));
    S.Read(HotKeyOpt, SizeOf(Word));
    S.Read(HotKeyReserved, SizeOf(Pointer));
  end;
end;

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

var
  C: Word;
  Stream: PDosStream;
  Item: PExecItem;
  F: Text;
  InName, OutName: FNameStr;
  S: String;

procedure Stop(const Msg: String; CloseInput, CloseOutput: Boolean);
begin
  if CloseInput then Dispose(Stream, Done);
  if CloseOutput then Close(F);
  Writeln(Msg);
  Halt(1);
end;

begin
  InName := ParamStr(1);
  if InName = '' then Stop('Source file not specified.', False, False);
  OutName := ParamStr(2);
  if OutName = '' then OutName := ForceExtension(InName, 'TXT');
  if FExpand(InName) = FExpand(OutName) then
    Stop('Source file and output file must differ.', False, False);

  Stream := New(PDosStream, Init(InName, stOpenRead));
  if Stream^.Status <> stOk then
    Stop('Could not open source file.', False, False);
  Assign(F, OutName);
  Rewrite(F);
  if IOResult <> 0 then Stop('Could not create output file.', True, False);

  RegisterType(RExecItem);
  repeat
    Item := PExecItem(Stream^.Get);
    if Stream^.Status <> stOk then
      Stop('Error reading source file.', True, True);
    if Item = nil then Break;
    S := 'TITLE';
    if Item^.Title <> nil then S := S + ' ' + Item^.Title^;
    Writeln(F, S);
    S := 'PATH';
    if Item^.Path <> nil then S := S + ' ' + Item^.Path^;
    Writeln(F, S);
    S := 'PARAMS';
    if Item^.Params <> nil then S := S + ' ' + Item^.Params^;
    Writeln(F, S);
    S := 'FILEMASK';
    if Item^.FileMask <> nil then S := S + ' ' + Item^.FileMask^;
    Writeln(F, S);
    S := 'LINEMASK';
    if Item^.LineMask <> nil then S := S + ' ' + Item^.LineMask^;
    Writeln(F, S);
    Str(Item^.Main, S);
    S := 'MAIN ' + S;
    Writeln(F, S);
    Str(Item^.Setup, S);
    S := 'SETUP ' + S;
    Writeln(F, S);
    Str(Item^.Options, S);
    S := 'OPTIONS ' + S;
    Writeln(F, S);
    if Item^.HotKey = hkSeq then
    begin
      S := 'SEQUENCE:';
      for C := 0 to Item^.HotKeyCount - 1 do
	S := S + ' $' + HexW(Item^.HotKeySequence^[C]);
    end
    else S := '$' + HexW(Item^.HotKey);
    Writeln(F, 'KEY ' + S);
    Writeln(F);
    if IOResult <> 0 then Stop('Error writing to output file.', True, True);
  until False;
  Close(F);
  Dispose(Stream, Done);
end.