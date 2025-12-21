{$I-,F+,O+,X+}
unit EditFile;

interface

uses Objects, FEditor;

type
  ConvertTable = Array[#0..#255] of Char;

function AppendMessageBox(const Name: FNameStr): Word;
procedure UpdateFiles(const Name: FNameStr);
function ReadBlockPrim(Editor: PFileEditor;
  const FName: FNameStr; ConcatLast: Boolean): Boolean;
function WriteBlockPrim(Editor: PFileEditor; const FName: FNameStr;
  Append: Boolean): Boolean;
function WriteBlockToFilePrim(Editor: PFileEditor; const AName: FNameStr;
  Prompt: Boolean; Append: Boolean): Boolean;
function ReadBlockFromFilePrim(Editor: PFileEditor; const AName: FNameStr;
  Prompt: Boolean): Boolean;
function SaveAsPrim(Editor: PFileEditor): Boolean;
function SavePrim(Editor: PFileEditor; const AName: FNameStr;
  Append: Boolean): Boolean;
function ReadConvertTable(var T: ConvertTable;
  const Name: FNameStr; var Changed: Boolean): Boolean;
function ReadLocalConvertTable(var T: ConvertTable;
  var Changed: Boolean): Boolean;
function GetConvertTable(var T: ConvertTable; Prompt: Boolean;
  var Changed: Boolean): Boolean;
procedure InitMacroListPrim(Editor: PFileEditor);
procedure DoneMacroListPrim(Editor: PFileEditor);
procedure InitSyntaxListPrim(Editor: PFileEditor);
procedure DoneSyntaxListPrim(Editor: PFileEditor);

implementation

uses Dos, Views, Drivers, Memory, Menus, Dialogs, MsgBox, App, Swaps,
  StdDlg, HistList, History, Keyboard, EditMsg, FindDlg, DragDrop,
  CNMacros, Popups, RegExp, DirPrim, DosTools, RevPos, StrCalc, LFN,
  Disks, StrCol, HeapUMB, TPString, Consts, Commands, Defaults;

function AppendMessageBox(const Name: FNameStr): Word;
var
  R: TRect;
  D: PDialog;
  Control: PView;
begin
  R.Assign(0, 0, 42, 9);
  D := New(PDialog, Init(R, 'Warning'));
  with D^ do
  begin
    Options := Options or ofCentered;
    R.Assign(3, 2, Size.X - 2, Size.Y - 3);
    Control := New(PStaticText, Init(R, ^C'File ' + TrimmedName(Name, 31) +
      #13^C'already exists. Overwrite or append ?'));
    Insert(Control);
    R.Assign(3, Size.Y - 3, 16, Size.Y - 1);
    Control := New(PMsgBoxButton, Init(R, '~O~verwrite', cmOk, bfDefault));
    Control^.HelpCtx := hcOkButton;
    Insert(Control);
    R.Assign(17, Size.Y - 3, 27, Size.Y - 1);
    Control := New(PMsgBoxButton, Init(R, '~A~ppend', cmYes, bfNormal));
    Control^.HelpCtx := hcYesButton;
    Insert(Control);
    R.Assign(28, Size.Y - 3, 38, Size.Y - 1);
    Control := New(PMsgBoxButton, Init(R, 'Cancel', cmCancel, bfNormal));
    Control^.HelpCtx := hcCancelButton;
    Insert(Control);
    SelectNext(False);
  end;
  AppendMessageBox := Application^.ExecView(D);
  Dispose(D, Done);
end;

procedure UpdateFiles(const Name: FNameStr);
var
  S: FNameStr;
begin
  S := lFExpand(Name);
  Message(Desktop, evBroadcast, cmUpdateTime, @S);
  while (S <> '') and (S[Length(S)] <> '\') do Dec(S[0]);
  if S <> '' then Dec(S[0]);
  Message(Desktop, evBroadcast, cmReRead, @S);
end;

function ReadBlockPrim(Editor: PFileEditor;
  const FName: FNameStr; ConcatLast: Boolean): Boolean;
var
  Result: Boolean;
  L, Pos, InsPos, EPos, MaxLen: Byte;
  SaveOpt: Word;
  Count, Index, I: Integer;
  F: lText;
  S, NS, Sel: String;

procedure OverwriteBlock;
begin
  with Editor^ do
  begin
    I := Index;
    InsPos := Pos;
    MaxLen := 0;
    FastGetLine := True;
    while not Eof(F.T) and
      (PSwapLinesCollection(FileLines)^.Status <> coOverflow) do
    begin
      GetValidLine(I, S);
      Readln(F.T, NS);
      NS := Detab(NS, LocalTabSize);
{      if not MarkColumns then TrailTrim(NS);}
      if InsPos > Length(S) then PadSt(S, InsPos)
      else if not IsInsert then System.Delete(S, InsPos, Length(NS));
      System.Insert(NS, S, InsPos);
      ReplaceLine(I, S);
      if not MarkColumns then InsPos := 1;
      if Length(NS) > MaxLen then Maxlen := Length(NS);
      Inc(I);
      if (KbdStatus = 1) and AbortAction then
      begin
	Result := False;
	Break;
      end;
    end;
    Close(F.T);
    InOutRes := 0;
    if PSwapLinesCollection(FileLines)^.Status = coOverflow then
    begin
      PSwapLinesCollection(FileLines)^.Status := 0;
      Result := False;
    end;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    DrawFlag := False;
    if I > Index + 1 then
    begin
      TopLine := MaxInt;
      if MarkColumns then EPos := InsPos + MaxLen
      else EPos := InsPos + Length(NS);
    end
    else EPos := Pos + Length(NS);
    IsSelected := False;
    Highlight(Index, Pos, I - 1, EPos);
  end;
end;

label
  Quit;
begin
  ReadBlockPrim := False;
  Result := True;
  with Editor^ do
  begin
    lAssignText(F, FName);
    Reset(F.T);
    if IOResult <> 0 then
    begin
      CouldNotOpenMsgBox(FName);
      Exit;
    end;
    if IsDevice(TextRec(F.T).Handle) then
    begin
      Close(F.T);
      InOutRes := 0;
      FileIsDeviceMsgBox(FName);
      Exit;
    end;
    if (TextReadMode = trAuto) and not Eof(F.T) then
    begin
      SetUNIXTextMode;
      Readln(F.T, S);
      if S[Length(S)] = #13 then SetDOSTextMode;
      TextSeek(F.T, 0);
    end
    else if TextReadMode = trUNIX then SetUNIXTextMode;
    if IsSelected and (LocalEditOptions and eoOverwriteBlocks <> 0) then
      Clear(True, False);
    Index := Delta.Y + Cursor.Y;
    Pos := Delta.X + Cursor.X + 1;
    SaveLastLine;
    SaveOpt := NewLocalOptions;
    NewLocalOptions := NewLocalOptions or neoTrailingBlanks;
    if not IsInsert or MarkColumns then
    begin
      OverwriteBlock;
      SetDOSTextMode;
      Goto Quit;
    end;
    Count := 0;
    GetValidLine(Index, S);
    if Pos > Length(S) then PadSt(S, Pos - 1);
    NS := System.Copy(S, Pos, 255);
    S[0] := Char(Pos - 1);
    Readln(F.T, Sel);
    Inc(Count);
    Sel := Detab(Sel, LocalTabSize);
{    TrailTrim(Sel);}
    if Length(Sel) + Length(S) > 255 then
    begin
      Inc(Index);
      NewLine(Index, Sel);
      L := Length(Sel) + 1;
    end
    else
    begin
      S := S + Sel;
      L := Length(S) + 1;
    end;
    ReplaceLine(Delta.Y + Cursor.Y, Detab(S, LocalTabSize));
    while not Eof(F.T) and
      (PSwapLinesCollection(FileLines)^.Status <> coOverflow) do
    begin
      Inc(Index);
      Readln(F.T, Sel);
      Inc(Count);
      Sel := Detab(Sel, LocalTabSize);
{      TrailTrim(Sel);}
      NewLine(Index, Sel);
      L := Length(Sel) + 1;
      if (KbdStatus = 1) and AbortAction then
      begin
	Result := False;
	Break;
      end;
    end;
    SetDOSTextMode;
    Close(F.T);
    InOutRes := 0;
    if PSwapLinesCollection(FileLines)^.Status = coOverflow then
    begin
      PSwapLinesCollection(FileLines)^.Status := 0;
      Result := False;
    end
    else if NS <> '' then
    begin
      GetValidLine(Index, S);
      if Count <= 1 then ConcatLast := True;
      if ConcatLast and (Length(S) + Length(NS) <= 255) then
	ReplaceLine(Index, S + NS)
      else NewLine(Index + 1, NS);
    end;
    DrawFlag := True;
    SetLimit(Limit.X, FileLines^.Count + Size.Y);
    Unselect;
    Highlight(Delta.Y + Cursor.Y, Pos, Index, L);
Quit:
    IsModified := True;
    DebugModified := True;
    NewLocalOptions := SaveOpt;
    if (NewLocalOptions and neoPasteGoesToEnd <> 0) and
      IsSelected then GoToPos(Area^.PK - 1, Area^.KK);
    DrawFlag := False;
  end;
  ReadBlockPrim := Result;
end;

function WriteBlockPrim(Editor: PFileEditor; const FName: FNameStr;
  Append: Boolean): Boolean;
var
  Result: Boolean;
  Index: Integer;
  F: lText;
  S: String;
begin
  WriteBlockPrim := False;
  Result := True;
  with Editor^ do
  begin
    if IsSelected then
    begin
      lAssignText(F, FName);
      if Append then
      begin
	System.Append(F.T);
	if IOResult <> 0 then Rewrite(F.T);
      end
      else Rewrite(F.T);
      if IOResult <> 0 then
      begin
	CouldNotCreateMsgBox(FName);
	Exit;
      end;
      if NotAccessible(TextRec(F.T).Handle) then
      begin
	Close(F.T);
	InOutRes := 0;
	FileIsDeviceMsgBox(FName);
	Exit;
      end;
      Index := Area^.KB;
      FastGetLine := True;
      if UnixMode then SetUNIXTextMode;
      while Index <= Area^.KK do
      begin
	GetSelectedString(Index, S);
	if LocalEditOptions and eoUseTabs <> 0 then
	  S := Entab(S, LocalTabSize);
	if MarkColumns then PadSt(S, Area^.PK - Area^.PB);
	Writeln(F.T, S);
	if IOResult <> 0 then
	begin
	  CouldNotWriteMsgBox(FName);
	  Result := False;
	  Break;
	end;
	if (KbdStatus = 1) and AbortAction then
	begin
	  Result := False;
	  Break;
	end;
	Inc(Index);
      end;
      SetDOSTextMode;
      Close(F.T);
      InOutRes := 0;
    end;
  end;
  WriteBlockPrim := Result;
end;

function WriteBlockToFilePrim(Editor: PFileEditor; const AName: FNameStr;
  Prompt: Boolean; Append: Boolean): Boolean;
var
  C: Word;
  S: String[7];
  FName: FNameStr;
begin
  WriteBlockToFilePrim := False;
  with Editor^ do
  begin
    if not IsSelected then Exit;
    FName := AName;
    if Prompt then
    begin
      if Append then S := 'Append' else S := 'Write';
      if Application^.ExecuteDialog(
        New(PFileDialog, Init('*.*', S + ' block to file',
          '~W~rite block to', fdOkButton + fdHelpButton, HistoryID)),
          @FName, False) = cmCancel then Exit;
      if not Append and ThisFileExists(FName) then
      begin
        C := AppendMessageBox(FName);
        case C of
          cmYes: Append := True;
          cmCancel: Exit;
        end;
      end;
    end;
    DrawWriteDataStatus(FName);
    WriteBlockToFilePrim := WriteBlock(FName, Append);
    UpdateFiles(FName);
  end;
end;

function ReadBlockFromFilePrim(Editor: PFileEditor; const AName: FNameStr;
  Prompt: Boolean): Boolean;
var
  FName: FNameStr;
begin
  FName := AName;
  if Prompt and (Application^.ExecuteDialog(
    New(PFileDialog, Init('*.*', 'Read block from file',
      '~R~ead block from', fdOkButton + fdHelpButton, HistoryID)),
      @FName, False) = cmCancel) then ReadBlockFromFilePrim := False
  else with Editor^ do
  begin
    if Options and ofHex = 0 then NewUndoChain(8);
    DrawReadDataStatus(FName);
    ReadBlockFromFilePrim := Editor^.ReadBlock(FName, False);
    if Options and ofHex = 0 then AddUndoChain;
  end;
end;

function SaveAsPrim(Editor: PFileEditor): Boolean;
var
  Append: Boolean;
  C: Word;
  P: Pointer;
  FName: FNameStr;
begin
  SaveAsPrim := False;
  Append := False;
  with Editor^ do
  begin
    FName := HistoryStr(HistoryID, 0);
    if Application^.ExecuteDialog(
      New(PFileDialog, Init('*.*', 'Save file as',
      '~S~ave file as', fdOkButton + fdHelpButton, HistoryID)),
      @FName, State and sfNoname <> 0) <> cmCancel then
    begin
      if ThisFileExists(FName) then
      begin
        C := AppendMessageBox(FName);
        case C of
          cmYes: Append := True;
          cmCancel: Exit;
        end;
      end;
      if Options and ofHex <> 0 then C := cmHexOpened
      else C := cmASCIIOpened;
      if not IsClip then
      begin
        P := Message(Desktop, evBroadcast, C, @FName);
        if (P <> nil) and (P <> Editor) then
          Message(Desktop, evCommand, cmClose, nil);
      end;
      State := State and not sfNoname;
      SaveAsPrim := Save(FName, Append);
    end;
  end;
end;

function SavePrim(Editor: PFileEditor; const AName: FNameStr;
  Append: Boolean): Boolean;
type
  PSaveBuffer = ^TSaveBuffer;
  TSaveBuffer = Array[0..8191] of Char;
var
  Aborted, Success, Ins, XLAT, C: Boolean;
  I, IHi: Integer;
  W, Len: Word;
  Buffer: PSaveBuffer;
  BackupName, Name: FNameStr;
  F: lText;
  S, D, N, E: String;
  T: ConvertTable;
begin
  with Editor^ do
  begin
    if State and sfNoname <> 0 then
    begin
      SavePrim := SaveAsPrim(Editor);
      Exit;
    end;
    SavePrim := False;
    Aborted := False;
    if AName = '' then Name := FileName^
    else Name := AName;
    LogEvent := lcDiskWrite;
    DrawStatusLine('Saving ' + TrimmedName(Name, 62) + '.');
    if LocalEditOptions and eoBackupFiles <> 0 then
    begin
      lFSplit(Name, D, N, E);
      if DirPresent(D + 'BAK') then BackupName := D + 'BAK\' + N + E
      else if E <> '.BAK' then BackupName := D + N + '.BAK'
      else BackupName := '';
      if BackupName <> '' then
      begin
	lAssignText(F, BackupName);
	lEraseText(F);
	InOutRes := 0;
	lAssignText(F, Name);
	lRenameText(F, BackupName);
	InOutRes := 0;
      end;
    end;
    lAssignText(F, Name);
    if FileAttr and (ReadOnly + Hidden + SysFile) <> 0 then
      if OverwriteReadOnlyMsgBox(Name) = cmCancel then Exit
      else
      begin
	DrawStatusLine('');
	lSetTAttr(F, Archive);
      end;
    Buffer := MemAlloc(SizeOf(Buffer^));
    if Buffer <> nil then SetTextBuf(F.T, Buffer^);
    if Append then
    begin
      System.Append(F.T);
      if IOResult <> 0 then Rewrite(F.T);
    end
    else Rewrite(F.T);
    if IOResult <> 0 then
    begin
      if Buffer <> nil then FreeMem(Buffer, SizeOf(Buffer^));
      CouldNotCreateMsgBox(Name);
      Exit;
    end;
    if NotAccessible(TextRec(F.T).Handle) then
    begin
      Close(F.T);
      InOutRes := 0;
      if Buffer <> nil then FreeMem(Buffer, SizeOf(Buffer^));
      FileIsDeviceMsgBox(Name);
      Exit;
    end;
    if not IsClip then NewTitle(Name);
    W := SyntaxWord;
    Ins := IsInsert;
    if AName <> '' then GetLocalFields;
    if Ins <> IsInsert then ToggleInsert;
    if W <> SyntaxWord then DrawView;
    SaveLastLine;
    FastGetLine := True;
    if UnixMode then SetUNIXTextMode;
    if OUTXLATName <> nil then
    begin
      XLAT := ReadConvertTable(T, OUTXLATName^, C);
      if not XLAT then DrawStatusLine('');
    end
    else XLAT := False;
    Success := True;
    S := '';
    IHi := FileLines^.Count - 1;
    for I := 0 to IHi do
    begin
      GetValidLine(I, S);
      if LocalEditOptions and eoUseTabs <> 0 then
	S := Entab(S, LocalTabSize);
      if XLAT then
	for Len := 1 to Length(S) do S[Len] := T[S[Len]];
      if LocalEditOptions and eoUnwrapLinesOnSave <> 0 then
	if S = '' then Writeln(F.T) else Write(F.T, S, ' ')
      else if ((I = IHi) and (NewLocalOptions and neoWriteCRLF = 0)) or
	(Length(S) = 255) then Write(F.T, S)
      else Writeln(F.T, S);
      if IOResult <> 0 then
      begin
	CouldNotWriteMsgBox(Name);
	Success := False;
	Break;
      end;
      if (KbdStatus = 1) and AbortAction then
      begin
	Aborted := True;
	Break;
      end;
    end;
    if (NewLocalOptions and neoWriteEOF <> 0) and
       (S[Length(S)] <> #26) then Write(F.T, #26);
    SetDOSTextMode;
    Close(F.T);
    if FileAttr <> Archive then lSetTAttr(F, FileAttr);
    InOutRes := 0;
    GetFileTime(Name, LastTime);
{
    lFindFirst(Name, AnyFile and not (VolumeID + Directory), SR);
    lFindClose(SR);
    if DosError = 0 then LastTime := SR.SR.Time;
    InOutRes := 0;
}
    if Buffer <> nil then FreeMem(Buffer, SizeOf(Buffer^));
    IsModified := Aborted;
    DebugModified := IsModified;
    Indicator^.DrawView;
    UndoCount := 0;
    SavePrim := Success;
    UpdateFiles(Name);
    if Append then UpdateLines(Name);
  end;
end;

function ReadConvertTable(var T: ConvertTable;
  const Name: FNameStr; var Changed: Boolean): Boolean;
var
  C: Char;
  S: FNameStr;
  F: lFile;
begin
  ReadConvertTable := False;
  Changed := True;
  for C := #0 to #255 do T[C] := C;
  if Name = '' then Exit;
  S := CNFileName(Name);
  lAssignFile(F, S);
  lResetReadOnly(F, 1);
  if IOResult <> 0 then
  begin
    CouldNotOpenMsgBox(S);
    Exit;
  end;
  if IsDevice(FileRec(F.F).Handle) then
  begin
    Close(F.F);
    InOutRes := 0;
    FileIsDeviceMsgBox(S);
    Exit;
  end;
  BlockRead(F.F, T, SizeOf(ConvertTable));
  Close(F.F);
  InOutRes := 0;
  ReadConvertTable := True;
end;

function ReadLocalConvertTable(var T: ConvertTable;
  var Changed: Boolean): Boolean;
const
  DecodeName = 'DECODE.TBL';
var
  B: Boolean;
  S: FNameStr;
begin
  if LocalAssocs then
  begin
    GetCurDir(0, S);
    repeat
      S := AddedSlash(S) + DecodeName;
      LogEvent := lcDiskRead;
      DrawStatusLine('Searching for local XLAT file ' +
	TrimmedName(S, 37) + '.');
      if ThisFileExists(S) then
      begin
	ReadLocalConvertTable := ReadConvertTable(T, S, Changed);
	Exit;
      end;
      if Length(S) < 15 then Break;
      S := PrevDir(JustPathName(S));
    until False;
  end;
  ReadLocalConvertTable := False;
end;

function GetConvertTable(var T: ConvertTable; Prompt: Boolean;
  var Changed: Boolean): Boolean;
var
  S: FNameStr;
begin
  GetConvertTable := False;
  Changed := False;
  if Prompt then
  begin
    S := HistoryStr(XLATNameHistoryID, 0);
    if Application^.ExecuteDialog(New(PFileDialog, Init('*.XLT',
      'Conversion table file', '~N~ame', fdOkButton + fdHelpButton,
      XLATNameHistoryID)), @S, False) = cmCancel then Exit;
  end
  else if ReadLocalConvertTable(T, Changed) then
  begin
    GetConvertTable := True;
    Exit;
  end
  else SetCNConfigName(S, 'TBL');
  GetConvertTable := ReadConvertTable(T, S, Changed);
end;

procedure InitMacroListPrim(Editor: PFileEditor);
begin
  DoneMacroListPrim(Editor);
  with Editor^ do
    if MacroName <> nil then
    begin
      ReadMacros(MacroName^, MacroList);
      Owner^.EventMask := Owner^.EventMask and not emHiBit;
    end;
end;

procedure DoneMacroListPrim(Editor: PFileEditor);
begin
  with Editor^ do
  begin
    Owner^.EventMask := Owner^.EventMask or emHiBit;
    if MacroList <> nil then
    begin
      Dispose(MacroList, Done);
      MacroList := nil;
    end;
  end;
end;

procedure SyntaxListInsert(SyntaxList: PSyntaxList; const S: String);
var
  C: CompareType;
  L, H, I: Integer;
  P: PString;
begin
  with SyntaxList^ do
  begin
    if (Length(S) > 1) and (S[2] = ' ') then
    begin
      if S[1] = '0' then
      begin
	Val(Trim(System.Copy(S, 3, 255)), NumberColor, I);
	Exit;
      end;
      Include(Symbols, S[1]);
    end;
    if (Length(S) > 2) and (S[1] = '2') and (S[3] = ' ') then
    begin
      Include(Quotes, S[2]);
      Val(Trim(System.Copy(S, 4, 255)), QuoteColors[S[2]], I);
      Exit;
    end;
    L := 0;
    H := Count - 1;
    while L <= H do
    begin
      I := (L + H) shr 1;
      C := CompString(PString(Items^[I])^, S);
      if C = Less then L := I + 1
      else
      begin
	H := I - 1;
	if C = Equal then L := I;
      end;
    end;
{    P := NewStr(S);}
    P := NewStrUMB(S);
    AtInsert(L, P);
  end;
end;

procedure ReadSyntaxList(Name: FNameStr;
  var SyntaxList: PSyntaxList);
var
  F: lText;
  S: String;
begin
  Name := CNFileName(Name);
  if not ThisFileExists(Name) then Exit;
  SyntaxList := New(PSyntaxList, Init(16, 16));
{  SyntaxList^.FileName := NewStr(Name);}
  SyntaxList^.FileName := NewStrUMB(Name);
  LogEvent := lcDiskRead;
  DrawStatusLine('Loading keywords from ' + TrimmedName(Name, 45) + '.');
  lAssignText(F, Name);
  Reset(F.T);
  if IOResult <> 0 then Exit;
  if IsDevice(TextRec(F.T).Handle) then
  begin
    Close(F.T);
    InOutRes := 0;
    Exit;
  end;
  while not Eof(F.T) do
  begin
    Readln(F.T, S);
    TrimSt(S);
    if S <> '' then
    begin
      UpcaseSt(S);
      SyntaxListInsert(SyntaxList, S);
    end;
  end;
  Close(F.T);
  InOutRes := 0;
end;

procedure InitSyntaxListPrim(Editor: PFileEditor);
begin
  DoneSyntaxListPrim(Editor);
  with Editor^ do
    if SyntaxName <> nil then
      ReadSyntaxList(SyntaxName^, SyntaxList);
end;

procedure DoneSyntaxListPrim(Editor: PFileEditor);
begin
  with Editor^ do
    if SyntaxList <> nil then
    begin
{      DisposeStr(SyntaxList^.FileName);}
      DisposeStrUMB(SyntaxList^.FileName);
      Dispose(SyntaxList, Done);
      SyntaxList := nil;
    end;
end;

end.
